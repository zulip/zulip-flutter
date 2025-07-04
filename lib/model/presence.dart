import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import '../api/route/users.dart';
import 'realm.dart';

/// The model for tracking which users are online, idle, and offline.
///
/// Use [presenceStatusForUser]. If that returns null, the user is offline.
///
/// This substore is its own [ChangeNotifier],
/// so callers need to remember to add a listener (and remove it on dispose).
/// In particular, [PerAccountStoreWidget] doesn't subscribe a widget subtree
/// to updates.
class Presence extends HasRealmStore with ChangeNotifier {
  Presence({
    required super.realm,
    required Map<int, PerUserPresence> initial,
  }) : _map = initial;

  Map<int, PerUserPresence> _map;

  AppLifecycleListener? _appLifecycleListener;

  void _handleLifecycleStateChange(AppLifecycleState newState) {
    assert(!_disposed); // We remove the listener in [dispose].

    // Since this handler can cause multiple requests within a
    // serverPresencePingInterval period, we pass `pingOnly: true`, for now, because:
    // - This makes the request cheap for the server.
    // - We don't want to record stale presence data when responses arrive out
    //   of order. This handler would increase the risk of that by potentially
    //   sending requests more frequently than serverPresencePingInterval.
    //   (`pingOnly: true` causes presence data to be omitted in the response.)
    // TODO(#1611) Both of these reasons can be easily addressed by passing
    //   lastUpdateId. Do that, and stop sending `pingOnly: true`.
    //   (For the latter point, we'd ignore responses with a stale lastUpdateId.)
    _maybePingAndRecordResponse(newState, pingOnly: true);
  }

  bool _hasStarted = false;

  void start() async {
    if (!debugEnable) return;
    if (_hasStarted) {
      throw StateError('Presence.start should only be called once.');
    }
    _hasStarted = true;

    _appLifecycleListener = AppLifecycleListener(
      onStateChange: _handleLifecycleStateChange);

    _poll();
  }

  Future<void> _maybePingAndRecordResponse(AppLifecycleState? appLifecycleState, {
    required bool pingOnly,
  }) async {
    if (realmPresenceDisabled) return;

    final UpdatePresenceResult result;
    switch (appLifecycleState) {
      case null:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        // No presence update.
        return;
      case AppLifecycleState.detached:
        // > The application is still hosted by a Flutter engine but is
        // > detached from any host views.
        // TODO see if this actually works as a way to send an "idle" update
        //   when the user closes the app completely.
        result = await updatePresence(connection,
          pingOnly: pingOnly,
          status: PresenceStatus.idle,
          newUserInput: false);
      case AppLifecycleState.resumed:
        // > […] the default running mode for a running application that has
        // > input focus and is visible.
        result = await updatePresence(connection,
          pingOnly: pingOnly,
          status: PresenceStatus.active,
          newUserInput: true);
      case AppLifecycleState.inactive:
        // > At least one view of the application is visible, but none have
        // > input focus. The application is otherwise running normally.
        // For example, we expect this state when the user is selecting a file
        // to upload.
        result = await updatePresence(connection,
          pingOnly: pingOnly,
          status: PresenceStatus.active,
          newUserInput: false);
    }
    if (!pingOnly) {
      _map = result.presences!;
      notifyListeners();
    }
  }

  void _poll() async {
    assert(!_disposed);
    while (true) {
      // We put the wait upfront because we already have data when [start] is
      // called; it comes from /register.
      await Future<void>.delayed(serverPresencePingInterval);
      if (_disposed) return;

      await _maybePingAndRecordResponse(
        SchedulerBinding.instance.lifecycleState, pingOnly: false);
      if (_disposed) return;
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _appLifecycleListener?.dispose();
    _disposed = true;
    super.dispose();
  }

  /// The [PresenceStatus] for [userId], or null if the user is offline.
  PresenceStatus? presenceStatusForUser(int userId, {required DateTime utcNow}) {
    final now = utcNow.millisecondsSinceEpoch ~/ 1000;
    final perUserPresence = _map[userId];
    if (perUserPresence == null) return null;
    final PerUserPresence(:activeTimestamp, :idleTimestamp) = perUserPresence;

    if (now - activeTimestamp <= serverPresenceOfflineThresholdSeconds) {
      return PresenceStatus.active;
    } else if (now - idleTimestamp <= serverPresenceOfflineThresholdSeconds) {
      // The API doc is kind of confusing, but this seems correct:
      //   https://chat.zulip.org/#narrow/channel/378-api-design/topic/presence.3A.20.22potentially.20present.22.3F/near/2202431
      // TODO clarify that API doc
      return PresenceStatus.idle;
    } else {
      return null;
    }
  }

  void handlePresenceEvent(PresenceEvent event) {
    // TODO(#1618)
  }

  /// In debug mode, controls whether presence requests are made.
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
    debugEnable = true;
  }
}
