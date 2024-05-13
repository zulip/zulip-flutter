import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../api/model/model.dart';

class MessageIdTracker {
  final List<int> _ids = [];

  void add(int id) {
    if (_ids.isEmpty) {
      _ids.add(id);
    } else {
      int i = lowerBound(_ids, id);
      if (i < _ids.length && _ids[i] == id) return; // the [id] already exists, so do not add it.
      _ids.insert(i, id);
    }
  }

  // TODO: remove

  /// The maximum id in the tracker list.
  ///
  /// Returns -1 if the tracker list is empty.
  int get maxId => _ids.isNotEmpty ? _ids.last : -1;

  /// Getter for the tracked message IDs.
  ///
  /// This is intended for testing purposes only.
  List<int> get idsForTesting => _ids;

  @override
  bool operator == (covariant MessageIdTracker other) {
    if (identical(this, other)) return true;

    return _ids.equals(other._ids);
  }

  @override
  int get hashCode => Object.hashAll(_ids);
}

/// A data structure to keep track of stream and topic messages.
///
/// The owner should call [clear] in order to free resources.
class RecentSenders {
  // streamSenders[streamId][senderId] = IdTracker
  final Map<int, Map<int, MessageIdTracker>> _streamSenders = {};

  // topicSenders[streamId][topic][senderId] = IdTracker
  final Map<int, Map<String, Map<int, MessageIdTracker>>> _topicSenders = {};

  /// Whether stream senders and topic senders are both empty.
  @visibleForTesting
  bool get debugIsEmpty => _streamSenders.isEmpty && _topicSenders.isEmpty;

  /// Whether stream senders and topic senders are both not empty.
  @visibleForTesting
  bool get debugIsNotEmpty => _streamSenders.isNotEmpty && _topicSenders.isNotEmpty;

  void clear() {
    _streamSenders.clear();
    _topicSenders.clear();
  }

  int _latestMessageIdOfSenderInStream({required int streamId, required int senderId}) {
    return _streamSenders[streamId]?[senderId]?.maxId ?? -1;
  }

  int _latestMessageIdOfSenderInTopic({
    required int streamId,
    required String topic,
    required int senderId,
  }) {
    return _topicSenders[streamId]?[topic]?[senderId]?.maxId ?? -1;
  }

  void _addMessageInStream({
    required int streamId,
    required int senderId,
    required int messageId,
  }) {
    final sendersMap = _streamSenders[streamId] ??= {};
    final idTracker = sendersMap[senderId] ??= MessageIdTracker();
    idTracker.add(messageId);
  }

  void _addMessageInTopic({
    required int streamId,
    required String topic,
    required int senderId,
    required int messageId,
  }) {
    final topicsMap = _topicSenders[streamId] ??= {};
    final sendersMap = topicsMap[topic] ??= {};
    final idTracker = sendersMap[senderId] ??= MessageIdTracker();
    idTracker.add(messageId);
  }

  /// Extracts and keeps track of the necessary data from a [message] only
  /// if it is a stream message.
  void handleMessage(Message message) {
    if (message is! StreamMessage) {
      return;
    }

    final streamId = message.streamId;
    final topic = message.subject;
    final senderId = message.senderId;
    final messageId = message.id;

    _addMessageInStream(
      streamId: streamId, senderId: senderId, messageId: messageId);
    _addMessageInTopic(
      streamId: streamId,
      topic: topic,
      senderId: senderId,
      messageId: messageId);
  }

  // TODO: removeMessageInTopic

  /// Determines which of the two users has more recent activity.
  ///
  /// First checks for the activity in [topic] if provided.
  ///
  /// If no [topic] is provided, or the activity in the topic is the same (which
  /// is extremely rare) or there is no activity in the topic at all, then
  /// checks for the activity in the stream with [streamId].
  ///
  /// Returns a negative number if [userA] has more recent activity than [userB],
  /// returns a positive number if [userB] has more recent activity than [userA],
  /// and returns `0` if both [userA] and [userB] have the same recent activity
  /// (which is extremely rare) or has no activity at all.
  int compareByRecency(
    User userA,
    User userB, {
    required int streamId,
    required String? topic,
  }) {
    if (topic != null) {
      final aMessageId = _latestMessageIdOfSenderInTopic(
          streamId: streamId, topic: topic, senderId: userA.userId);
      final bMessageId = _latestMessageIdOfSenderInTopic(
          streamId: streamId, topic: topic, senderId: userB.userId);

      final result = bMessageId.compareTo(aMessageId);
      if (result != 0) return result;
    }

    final aMessageId =
      _latestMessageIdOfSenderInStream(streamId: streamId, senderId: userA.userId);
    final bMessageId =
      _latestMessageIdOfSenderInStream(streamId: streamId, senderId: userB.userId);
    return bMessageId.compareTo(aMessageId);
  }
}
