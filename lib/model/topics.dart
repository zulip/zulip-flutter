import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import '../api/route/channels.dart';
import 'channel.dart';
import 'store.dart';

// similar to _apiSendMessage in lib/model/message.dart
final _apiGetChannelTopics = getChannelTopics;

/// The view-model for tracking channel topics.
///
/// Use [fetchChannelTopics] to first fetch the topics for a channel from the
/// server and then use [getChannelTopics] to get those topics, affected
/// by the relevant events.
class Topics extends PerAccountStoreBase with ChangeNotifier {
  Topics({required super.core});

  /// Maps indexed by channel IDs, of the known latest message IDs in each topic.
  ///
  /// For example: `_latestMessageIdsByChannelTopic[channel.streamId][topic] = maxId`
  ///
  /// Occasionally, the latest message ID of a topic will refer to a message
  /// that doesn't exist or is no longer in the topic.
  /// This happens when the topic's latest message is deleted or moved
  /// and we don't have enough information to replace it accurately.
  /// (We don't keep a snapshot of all messages.)
  // TODO(#2004): handle more cases where this can change
  final Map<int, TopicKeyedMap<int>> _latestMessageIdsByChannelTopic = {};

  final Map<int, Future<GetChannelTopicsResult>> _channelTopicsFetching = {};

  /// Fetch topics in a channel from the server, only if they're not fetched yet.
  ///
  /// Once fetched, the data will be updated by events;
  /// use [getChannelTopics] to consume the data.
  Future<void> fetchChannelTopics(int channelId) async {
    if (_latestMessageIdsByChannelTopic[channelId] != null) return;

    Future<GetChannelTopicsResult>? future = _channelTopicsFetching[channelId];
    // If another call has already started fetching topics for this channel,
    // ignore this call.
    if (future != null) return;

    future = _apiGetChannelTopics(connection, channelId: channelId,
      allowEmptyTopicName: true);
    _channelTopicsFetching[channelId] = future;

    try {
      final result = await future;
      assert(_latestMessageIdsByChannelTopic[channelId] == null);
      (_latestMessageIdsByChannelTopic[channelId] = makeTopicKeyedMap())
        .addEntries(result.topics.map((entry) => MapEntry(entry.name, entry.maxId)));
    } finally {
      unawaited(_channelTopicsFetching.remove(channelId));
    }
  }

  /// Map of topics per channel, sorted by latest message IDs descending.
  ///
  /// Derived from [_latestMessageIdsByChannelTopic];
  /// used for optimized topics sorting.
  ///
  /// A channel entry should be discarded when there is a change to
  /// the ordering of its topics or the channel is no longer present
  /// in [_latestMessageIdsByChannelTopic], allowing [getChannelTopics]
  /// to recalculate the sorted topics on demand.
  // TODO(#2004): handle more cases where this can change
  final Map<int, List<GetChannelTopicsEntry>> _sortedTopicsByChannel = {};

  /// The topics the user can access, along with their latest message ID,
  /// reflecting updates from events that arrived since the data was fetched.
  ///
  /// Returns null if the data has not been fetched yet.
  /// To fetch it from the server, use [fetchChannelTopics].
  ///
  /// The result is sorted by [GetChannelTopicsEntry.maxId] descending,
  /// and the topics are distinct.
  ///
  /// Occasionally, [GetChannelTopicsEntry.maxId] will refer to a message
  /// that doesn't exist or is no longer in the topic.
  /// This happens when a topic's latest message is deleted or moved
  /// and we don't have enough information
  /// to replace [GetChannelTopicsEntry.maxId] accurately.
  /// (We don't keep a snapshot of all messages.)
  /// Use [PerAccountStore.messages] to check a message's topic accurately.
  List<GetChannelTopicsEntry>? getChannelTopics(int channelId) {
    final latestMessageIdsByTopic = _latestMessageIdsByChannelTopic[channelId];
    if (latestMessageIdsByTopic == null) return null;
    return _sortedTopicsByChannel[channelId] ??= latestMessageIdsByTopic.entries
      .map((e) => GetChannelTopicsEntry(maxId: e.value, name: e.key))
      .sortedBy((value) => -value.maxId);
  }

  void handleMessageEvent(MessageEvent event) {
    if (event.message is! StreamMessage) return;
    final StreamMessage(:id, streamId: channelId, :topic) = event.message as StreamMessage;

    final latestMessageIdsByTopic = _latestMessageIdsByChannelTopic[channelId];
    if (latestMessageIdsByTopic == null) {
      // We're not tracking this channel's topics yet.
      // We'll start doing that when we get the full topic list;
      // see [fetchChannelTopics].
      return;
    }

    final currentLatestMessageId = latestMessageIdsByTopic[topic];
    if (currentLatestMessageId != null && currentLatestMessageId >= id) {
      // The event raced with a topic-list fetch.
      return;
    }
    latestMessageIdsByTopic[topic] = id;
    _sortedTopicsByChannel.remove(channelId);
    notifyListeners();
  }

  void handleUpdateMessageEvent(UpdateMessageEvent event) {
    if (event.moveData == null) return;
    final UpdateMessageMoveData(
      :origStreamId, :origTopic, :newStreamId, :newTopic, :propagateMode,
    ) = event.moveData!;
    bool shouldNotify = false;

    final origLatestMessageIdsByTopic = _latestMessageIdsByChannelTopic[origStreamId];
    if (origLatestMessageIdsByTopic != null) {
      switch (propagateMode) {
        case .changeOne:
        case .changeLater:
          // We can't know the new `maxId` for the original topic.
          // Shrug; leave it unchanged. (See dartdoc of [getChannelTopics],
          // where we call out this possibility that `maxId` is incorrect.)
          break;
        case .changeAll:
          origLatestMessageIdsByTopic.remove(origTopic);
          _sortedTopicsByChannel.remove(origStreamId);
          shouldNotify = true;
      }
    }

    final newLatestMessageIdsByTopic = _latestMessageIdsByChannelTopic[newStreamId];
    if (newLatestMessageIdsByTopic != null) {
      // TODO(server-11): rely on `event.messageIds` being sorted, to avoid this linear scan
      final movedMaxId = event.messageIds.max;
      final currentMaxId = newLatestMessageIdsByTopic[newTopic];
      if (currentMaxId == null || currentMaxId < movedMaxId) {
        newLatestMessageIdsByTopic[newTopic] = movedMaxId;
        _sortedTopicsByChannel.remove(newStreamId);
        shouldNotify = true;
      }
    }

    if (shouldNotify) notifyListeners();
  }
}
