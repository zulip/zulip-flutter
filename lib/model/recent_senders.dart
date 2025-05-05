import 'package:collection/collection.dart' hide binarySearch;
import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import 'algorithms.dart';

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
  final Map<int, Map<TopicName, Map<int, MessageIdTracker>>> topicSenders = {};

  /// The latest message the given user sent to the given stream,
  /// or null if no such message is known.
  int? latestMessageIdOfSenderInStream({
    required int streamId,
    required int senderId,
  }) => streamSenders[streamId]?[senderId]?.maxId;

  /// The latest message the given user sent to the given topic,
  /// or null if no such message is known.
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
      (((topicSenders[streamId] ??= {})[topic] ??= {})
        [senderId] ??= MessageIdTracker()).addAll(entry.value);
    }
  }

  /// Records the necessary data from a new message.
  void handleMessage(Message message) {
    if (message is! StreamMessage) return;
    final StreamMessage(:streamId, :topic, :senderId, id: int messageId) = message;
    ((streamSenders[streamId] ??= {})
      [senderId] ??= MessageIdTracker()).add(messageId);
    (((topicSenders[streamId] ??= {})[topic] ??= {})
      [senderId] ??= MessageIdTracker()).add(messageId);
  }

  /// Handles channel/topic updates when messages are moved.
  ///
  /// [cachedMessages] should just be a map of messages we know about, i.e.
  /// [MessageStore.messages].  It doesn't matter whether the same
  /// [UpdateMessageEvent] has been handled by the [MessageStore],
  /// since only the sender IDs, which do not change, are looked at.
  ///
  /// This is a no-op if no message move happened.
  void handleUpdateMessageEvent(UpdateMessageEvent event, Map<int, Message> cachedMessages) {
    if (event.moveData == null) {
      return;
    }
    final UpdateMessageMoveData(
      :origStreamId, :newStreamId, :origTopic, :newTopic) = event.moveData!;

    final messagesBySender = _groupStreamMessageIdsBySender(event.messageIds, cachedMessages);
    final sendersInStream = streamSenders[origStreamId];
    final topicsInStream = topicSenders[origStreamId];
    final sendersInTopic = topicsInStream?[origTopic];
    for (final MapEntry(key: senderId, value: messages) in messagesBySender.entries) {
      // The later `popAll` calls require the message IDs to be sorted in
      // ascending order.  Only sort as many as we need: the message IDs
      // with the same sender, instead of all of them in `event.messageIds`.
      // TOOD(server) make this an API guarantee.  CZO discussion:
      //   https://chat.zulip.org/#narrow/channel/412-api-documentation/topic/Make.20message_ids.20from.20message.20update.20event.20sorted/near/2143785
      messages.sort();

      if (newStreamId != origStreamId) {
        final streamTracker = sendersInStream?[senderId];
        // All messages from both `messages` and `streamTracker` are from the
        // same sender and the same channel.  `messages` contain only messages
        // known to `store.messages`; all of them should have made there way
        // to the recent senders data structure as well.
        assert(messages.every((id) => streamTracker!.ids.contains(id)));
        streamTracker?.removeAll(messages);
        if (streamTracker?.maxId == null) sendersInStream?.remove(senderId);
        if (messages.isNotEmpty) {
          ((streamSenders[newStreamId] ??= {})
            [senderId] ??= MessageIdTracker()).addAll(messages);
        }
      }

      // This does not need a check like the stream trackers one above,
      // because the conversation is guaranteed to have moved.  This is an
      // invariant [UpdateMessageMoveData] offers.
      final topicTracker = sendersInTopic?[senderId];
      final movedMessagesInTopicTracker = topicTracker?.popAll(messages);
      if (topicTracker?.maxId == null) sendersInTopic?.remove(senderId);
      if (movedMessagesInTopicTracker != null) {
        (((topicSenders[newStreamId] ??= {})[newTopic] ??= {})
          [senderId] ??= MessageIdTracker()).addAll(movedMessagesInTopicTracker);
      }
    }
    if (sendersInStream?.isEmpty ?? false) streamSenders.remove(origStreamId);
    if (sendersInTopic?.isEmpty ?? false) topicsInStream?.remove(origTopic);
    if (topicsInStream?.isEmpty ?? false) topicSenders.remove(origStreamId);
  }

  void handleDeleteMessageEvent(DeleteMessageEvent event, Map<int, Message> cachedMessages) {
    if (event.messageType != MessageType.stream) return;

    final messagesBySender = _groupStreamMessageIdsBySender(event.messageIds, cachedMessages);
    final DeleteMessageEvent(:streamId!, :topic!) = event;
    final sendersInStream = streamSenders[streamId];
    final topicsInStream = topicSenders[streamId];
    final sendersInTopic = topicsInStream?[topic];
    for (final entry in messagesBySender.entries) {
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

  Map<int, QueueList<int>> _groupStreamMessageIdsBySender(
    Iterable<int> messageIds,
    Map<int, Message> cachedMessages,
  ) {
    final messagesBySender = <int, QueueList<int>>{};
    for (final id in messageIds) {
      final message = cachedMessages[id] as StreamMessage?;
      if (message == null) continue;
      (messagesBySender[message.senderId] ??= QueueList()).add(id);
    }
    return messagesBySender;
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
    assert(isSortedWithoutDuplicates(newIds));
    if (ids.isEmpty) {
      ids = newIds;
      return;
    }
    ids = setUnion(ids, newIds);
  }

  /// Remove message IDs found in [idsToRemove] from the tracker list.
  ///
  /// [idsToRemove] should be sorted ascending.
  void removeAll(List<int> idsToRemove) {
    assert(isSortedWithoutDuplicates(idsToRemove));
    ids.removeWhere((id) => binarySearch(idsToRemove, id) != -1);
  }

  /// Remove message IDs found in [idsToRemove] from the tracker list.
  ///
  /// Returns the removed message IDs sorted in ascending order, or `null` if
  /// nothing is removed.
  ///
  /// [idsToRemove] should be sorted ascending.
  ///
  /// Consider using [removeAll] if the returned message IDs are not needed.
  // Part of this is adapted from [ListBase.removeWhere].
  QueueList<int>? popAll(List<int> idsToRemove) {
    assert(isSortedWithoutDuplicates(idsToRemove));
    final retainedMessageIds =
      ids.where((id) => binarySearch(idsToRemove, id) == -1).toList();

    if (retainedMessageIds.isEmpty) {
      // All message IDs in this tracker are removed; this is an optimization
      // to clear all ids and return the removed ones without making a new copy.
      final result = ids;
      ids = QueueList();
      return result;
    }

    QueueList<int>? poppedMessageIds;
    if (retainedMessageIds.length != ids.length) {
      poppedMessageIds = QueueList.from(
        ids.where((id) => binarySearch(idsToRemove, id) != -1));
      ids.setRange(0, retainedMessageIds.length, retainedMessageIds);
      ids.length = retainedMessageIds.length;
      assert(isSortedWithoutDuplicates(poppedMessageIds));
    }
    return poppedMessageIds;
  }

  @override
  String toString() => ids.toString();
}
