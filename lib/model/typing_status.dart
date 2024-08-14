import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import 'narrow.dart';

/// The model for tracking the typing status organized by narrows.
///
/// Listeners are notified when a typist is added or removed from any narrow.
class TypingStatus extends ChangeNotifier {
  TypingStatus({
    required this.selfUserId,
    required this.typingStartedExpiryPeriod,
  });

  final int selfUserId;
  final Duration typingStartedExpiryPeriod;

  Iterable<SendableNarrow> get debugActiveNarrows => _timerMapsByNarrow.keys;

  Iterable<int> typistIdsInNarrow(SendableNarrow narrow) =>
    _timerMapsByNarrow[narrow]?.keys ?? [];

  // Using SendableNarrow as the key covers the narrows
  // where typing notifications are supported (topics and DMs).
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
    narrowTimerMap[typistUserId] = Timer(typingStartedExpiryPeriod, () {
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
