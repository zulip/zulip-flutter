import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import 'algorithms.dart';
import 'channel.dart';

/// Tracks the latest messages sent by each user, in each stream and topic.
///
/// Use [latestMessageIdOfSenderInStream] and [latestMessageIdOfSenderInTopic]
/// for queries.
class RecentSenders {
  // streamSenders[streamId][senderId] = MessageIdTracker
  @visibleForTesting
  final Map<int, Map<int, MessageIdTracker>> streamSenders = {};

  // topicSenders[streamId][topic][senderId] = MessageIdTracker
  @visibleForTesting
  final Map<int, TopicKeyedMap<Map<int, MessageIdTracker>>> topicSenders = {};

  /// The latest message the given user sent to the given stream,
  /// or null if no such message is known.
  int? latestMessageIdOfSenderInStream({
    required int streamId,
    required int senderId,
  }) => streamSenders[streamId]?[senderId]?.maxId;

  /// The latest message the given user sent to the given topic,
  /// or null if no such message is known.
  ///
  /// Topics are treated case-insensitively; see [TopicName.isSameAs].
  int? latestMessageIdOfSenderInTopic({
    required int streamId,
    required TopicName topic,
    required int senderId,
  }) => topicSenders[streamId]?[topic]?[senderId]?.maxId;

  /// Records the necessary data from a batch of just-fetched messages.
  ///
  /// The messages must be sorted by [Message.id] ascending.
  void handleMessages(List<Message> messages) {
    final messagesByUserInStream = <(int, int), QueueList<int>>{};
    final messagesByUserInTopic = <(int, TopicName, int), QueueList<int>>{};
    for (final message in messages) {
      if (message is! StreamMessage) continue;
      final StreamMessage(:streamId, :topic, :senderId, id: int messageId) = message;
      (messagesByUserInStream[(streamId, senderId)] ??= QueueList()).add(messageId);
      (messagesByUserInTopic[(streamId, topic, senderId)] ??= QueueList()).add(messageId);
    }

    for (final entry in messagesByUserInStream.entries) {
      final (streamId, senderId) = entry.key;
      ((streamSenders[streamId] ??= {})
        [senderId] ??= MessageIdTracker()).addAll(entry.value);
    }
    for (final entry in messagesByUserInTopic.entries) {
      final (streamId, topic, senderId) = entry.key;
      (((topicSenders[streamId] ??= makeTopicKeyedMap())[topic] ??= {})
        [senderId] ??= MessageIdTracker()).addAll(entry.value);
    }
  }

  /// Records the necessary data from a new message.
  void handleMessage(Message message) {
    if (message is! StreamMessage) return;
    final StreamMessage(:streamId, :topic, :senderId, id: int messageId) = message;
    ((streamSenders[streamId] ??= {})
      [senderId] ??= MessageIdTracker()).add(messageId);
    (((topicSenders[streamId] ??= makeTopicKeyedMap())[topic] ??= {})
      [senderId] ??= MessageIdTracker()).add(messageId);
  }

  void handleDeleteMessageEvent(DeleteMessageEvent event, Map<int, Message> cachedMessages) {
    if (event.messageType != MessageType.stream) return;

    final messagesByUser = <int, List<int>>{};
    for (final id in event.messageIds) {
      final message = cachedMessages[id] as StreamMessage?;
      if (message == null) continue;
      (messagesByUser[message.senderId] ??= []).add(id);
    }

    final DeleteMessageEvent(:streamId!, :topic!) = event;
    final sendersInStream = streamSenders[streamId];
    final topicsInStream = topicSenders[streamId];
    final sendersInTopic = topicsInStream?[topic];
    for (final entry in messagesByUser.entries) {
      final MapEntry(key: senderId, value: messages) = entry;

      final streamTracker = sendersInStream?[senderId];
      streamTracker?.removeAll(messages);
      if (streamTracker?.maxId == null) sendersInStream?.remove(senderId);

      final topicTracker = sendersInTopic?[senderId];
      topicTracker?.removeAll(messages);
      if (topicTracker?.maxId == null) sendersInTopic?.remove(senderId);
    }
    if (sendersInStream?.isEmpty ?? false) streamSenders.remove(streamId);
    if (sendersInTopic?.isEmpty ?? false) topicsInStream?.remove(topic);
    if (topicsInStream?.isEmpty ?? false) topicSenders.remove(streamId);
  }
}

@visibleForTesting
class MessageIdTracker {
  /// A list of distinct message IDs, sorted ascending.
  @visibleForTesting
  QueueList<int> ids = QueueList();

  /// The maximum id in the tracker list, or `null` if the list is empty.
  int? get maxId => ids.lastOrNull;

  /// Add the message ID to the tracker list at the proper place, if not present.
  ///
  /// Optimized, taking O(1) time for the case where that place is the end,
  /// because that's the common case for a message that is received through
  /// [PerAccountStore.handleEvent]. May take O(n) time in some rare cases.
  void add(int id) {
    if (ids.isEmpty || id > ids.last) {
      ids.addLast(id);
      return;
    }
    final i = lowerBound(ids, id);
    if (i < ids.length && ids[i] == id) {
      // The ID is already present. Nothing to do.
      return;
    }
    ids.insert(i, id);
  }

  /// Add the messages IDs to the tracker list at the proper place, if not present.
  ///
  /// [newIds] should be sorted ascending.
  void addAll(QueueList<int> newIds) {
    if (ids.isEmpty) {
      ids = newIds;
      return;
    }
    ids = setUnion(ids, newIds);
  }

  void removeAll(List<int> idsToRemove) {
    ids.removeWhere((id) {
      final i = lowerBound(idsToRemove, id);
      return i < idsToRemove.length && idsToRemove[i] == id;
    });
  }

  @override
  String toString() => ids.toString();
}
