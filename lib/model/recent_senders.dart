import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../api/model/model.dart';

/// A data structure to keep track of stream and topic messages of users (senders).
///
/// Use [latestMessageIdOfSenderInStream] and [latestMessageIdOfSenderInTopic]
/// to get the relevant data.
///
/// The owner should call [clear] in order to free resources.
class RecentSenders {
  // streamSenders[streamId][senderId] = IdTracker
  final Map<int, Map<int, MessageIdTracker>> _streamSenders = {};

  // topicSenders[streamId][topic][senderId] = IdTracker
  final Map<int, Map<String, Map<int, MessageIdTracker>>> _topicSenders = {};

  @visibleForTesting
  Map<int, Map<int, MessageIdTracker>> get debugStreamSenders => _streamSenders;

  @visibleForTesting
  Map<int, Map<String, Map<int, MessageIdTracker>>> get debugTopicSenders => _topicSenders;

  /// Whether stream senders and topic senders are both empty.
  @visibleForTesting
  bool get debugIsEmpty => _streamSenders.isEmpty && _topicSenders.isEmpty;

  void clear() {
    _streamSenders.clear();
    _topicSenders.clear();
  }

  int? latestMessageIdOfSenderInStream({
    required int streamId,
    required int senderId,
  }) => _streamSenders[streamId]?[senderId]?.maxId;

  int? latestMessageIdOfSenderInTopic({
    required int streamId,
    required String topic,
    required int senderId,
  }) => _topicSenders[streamId]?[topic]?[senderId]?.maxId;

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

  /// Records the necessary data from [message] if it is a [StreamMessage].
  ///
  /// If [message] is not a [StreamMessage], this is a no-op.
  void handleMessage(Message message) {
    if (message is! StreamMessage) {
      return;
    }

    final streamId = message.streamId;
    final topic = message.topic;
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
}

class MessageIdTracker {
  MessageIdTracker();

  @visibleForTesting
  MessageIdTracker.fromIds(List<int> ids) {
    _ids.addAll([...{...ids}]..sort());
  }

  /// A list of distinct message IDs, sorted ascendingly.
  final List<int> _ids = [];

  /// Add the given message ID to the list, if not already present.
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
  /// Returns `null` if the tracker list is empty.
  int? get maxId => _ids.lastOrNull;

  @visibleForTesting
  List<int> get debugIds => _ids;

  @override
  bool operator ==(covariant MessageIdTracker other) {
    if (identical(this, other)) return true;

    return _ids.equals(other._ids);
  }

  @override
  int get hashCode => Object.hashAll(_ids);

  @override
  String toString() => _ids.toString();
}
