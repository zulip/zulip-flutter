import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/route/typing.dart';
import 'binding.dart';
import 'narrow.dart';
import 'realm.dart';

/// The model for tracking the typing status organized by narrows.
///
/// Listeners are notified when a typist is added or removed from any narrow.
class TypingStatus extends HasRealmStore with ChangeNotifier {
  TypingStatus({required super.realm});

  Iterable<SendableNarrow> get debugActiveNarrows => _timerMapsByNarrow.keys;

  Iterable<int> typistIdsInNarrow(SendableNarrow narrow) =>
    _timerMapsByNarrow[narrow]?.keys ?? const [];

  // Using SendableNarrow as the key covers the narrows
  // where typing notices are supported (topics and DMs).
  final Map<SendableNarrow, Map<int, Timer>> _timerMapsByNarrow = {};

  @override
  void dispose() {
    for (final timersByTypistId in _timerMapsByNarrow.values) {
      for (final timer in timersByTypistId.values) {
        timer.cancel();
      }
    }
    _timerMapsByNarrow.clear();
    super.dispose();
  }

  bool _addTypist(SendableNarrow narrow, int typistUserId) {
    if (typistUserId == selfUserId) {
      return false;
    }
    final narrowTimerMap = _timerMapsByNarrow[narrow] ??= {};
    final typistTimer = narrowTimerMap[typistUserId];
    final isNewTypist = typistTimer == null;
    typistTimer?.cancel();
    narrowTimerMap[typistUserId] = Timer(serverTypingStartedExpiryPeriod, () {
      if (_removeTypist(narrow, typistUserId)) {
        notifyListeners();
      }
    });
    return isNewTypist;
  }

  bool _removeTypist(SendableNarrow narrow, int typistUserId) {
    final narrowTimerMap = _timerMapsByNarrow[narrow];
    final typistTimer = narrowTimerMap?.remove(typistUserId);
    if (typistTimer == null) {
      return false;
    }
    typistTimer.cancel();
    if (narrowTimerMap!.isEmpty) _timerMapsByNarrow.remove(narrow);
    return true;
  }

  void handleTypingEvent(TypingEvent event) {
    SendableNarrow narrow = switch (event.messageType) {
      MessageType.direct => DmNarrow(
        allRecipientIds: event.recipientIds!, selfUserId: selfUserId),
      MessageType.stream => TopicNarrow(event.streamId!, event.topic!),
    };

    bool hasUpdate = false;
    switch (event.op) {
      case TypingOp.start:
        hasUpdate = _addTypist(narrow, event.senderId);
      case TypingOp.stop:
        hasUpdate = _removeTypist(narrow, event.senderId);
    }

    if (hasUpdate) {
      notifyListeners();
    }
  }
}

/// Sends the self-user's typing-status updates.
///
/// See also:
///  * https://github.com/zulip/zulip/blob/52a9846cdf4abfbe937a94559690d508e95f4065/web/shared/src/typing_status.ts
///  * https://zulip.readthedocs.io/en/latest/subsystems/typing-indicators.html
class TypingNotifier extends HasRealmStore {
  TypingNotifier({required super.realm});

  SendableNarrow? _currentDestination;

  /// Records time elapsed since the last time we notify the server;
  /// this is `null` when the user is not actively typing.
  Stopwatch? _sinceLastPing;

  /// A timer that resets on every [keystroke].
  ///
  /// Upon its expiry, the user is considered idle and
  /// a "typing stopped" notice will be sent.
  Timer? _idleTimer;

  void dispose() {
    _idleTimer?.cancel();
  }

  /// Updates the server, if needed, that a keystroke was made when
  /// composing a new message to [destination].
  ///
  /// To be called on all keystrokes in the composing session.
  /// Sends "typing started" notices, throttled appropriately,
  /// for repeated calls to the same [destination].
  ///
  /// If [destination] differs from the previous call, such as after a topic
  /// input change, sends a "typing stopped" notice for the old destination.
  ///
  /// Keeps a timer to send a "typing stopped" notice when this and
  /// [stoppedComposing] haven't been called in some time.
  void keystroke(SendableNarrow destination) {
    if (!debugEnable) return;

    if (_currentDestination != null) {
      if (destination == _currentDestination) {
        // Nothing has really changed, except we may need
        // to send a ping to the server and extend out our idle time.
        if (_sinceLastPing!.elapsed > serverTypingStartedWaitPeriod) {
          _actuallyPingServer();
        }
        _startOrExtendIdleTimer();
        return;
      }

      _stopLastNotification();
    }

    // We just started typing to this destination, so notify the server.
    _currentDestination = destination;
    _startOrExtendIdleTimer();
    _actuallyPingServer();
  }

  /// Sends the server a "typing stopped" notice for the destination of
  /// the current composing session, if there is one.
  ///
  /// To be called on cues that the user has exited a new-message composing session,
  /// e.g., send button tapped, compose box unfocused, nav changed, app quit.
  ///
  /// If [keystroke] hasn't been called in some time, does nothing.
  ///
  /// Otherwise:
  /// - Users will see our user's typing indicator disappear immediately
  ///   instead of after [keystroke]'s timer.
  /// - [keystroke]'s timer is canceled.
  ///
  /// (This has no "destination" param because the user can really only compose
  /// to one destination at a time. This function acts on the current session
  /// regardless of its destination.)
  void stoppedComposing() {
    if (!debugEnable) return;

    if (_currentDestination != null) {
      _stopLastNotification();
    }
  }

  void _startOrExtendIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(serverTypingStoppedWaitPeriod, _stopLastNotification);
  }

  void _actuallyPingServer() {
    // This allows us to use [clock.stopwatch] only when testing.
    _sinceLastPing = ZulipBinding.instance.stopwatch()..start();

    unawaited(setTypingStatus(
      connection,
      op: TypingOp.start,
      destination: _currentDestination!.destination));
  }

  void _stopLastNotification() {
    assert(_currentDestination != null);
    final destination = _currentDestination!;

    _idleTimer!.cancel();
    _currentDestination = null;
    _sinceLastPing = null;

    unawaited(setTypingStatus(
      connection,
      op: TypingOp.stop,
      destination: destination.destination));
  }

  /// In debug mode, controls whether typing notices should be sent.
  ///
  /// Outside of debug mode, this is always true and the setter has no effect.
  static bool get debugEnable {
    bool result = true;
    assert(() {
      result = _debugEnable;
      return true;
    }());
    return result;
  }
  static bool _debugEnable = true;
  static set debugEnable(bool value) {
    assert(() {
      _debugEnable = value;
      return true;
    }());
  }

  @visibleForTesting
  static void debugReset() {
    _debugEnable = true;
  }
}
