import 'dart:core';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/model/events.dart';
import '../log.dart';
import 'algorithms.dart';
import 'narrow.dart';
import 'channel.dart';
import 'store.dart';

/// The view-model for unread messages.
///
/// Implemented to track actual unread state as faithfully as possible
/// given incomplete information in [UnreadMessagesSnapshot].
///
/// In [streams], [dms], and [mentions], if a message is not represented,
/// its status is either read or unknown. A message's status will be unknown if
/// it was very old at /register time; see [oldUnreadsMissing].
/// In [mentions], there's another more complex reason
/// the state might be unknown; see there.
///
/// Messages in unsubscribed streams, and messages sent by muted users,
/// are generally deemed read by the server and shouldn't be expected to appear.
/// They may still appear temporarily when the server hasn't finished processing
/// the message's transition to the muted or unsubscribed-stream state;
/// the mark-as-read is done asynchronously and comes with a mark-as-read event:
///   https://chat.zulip.org/#narrow/stream/412-api-documentation/topic/unreads.3A.20messages.20from.20muted.20users.3F/near/1660912
/// For that reason, consumers of this model may wish to filter out messages in
/// unsubscribed streams and messages sent by muted users.
// TODO When [oldUnreadsMissing], if you load a message list with very old unreads,
//   sync to those unreads, because the user has shown an interest in them.
// TODO When loading a message list with stream messages, check all the stream
//   messages and refresh [mentions] (see [mentions] dartdoc).
class Unreads extends PerAccountStoreBase with ChangeNotifier {
  factory Unreads({
    required CorePerAccountStore core,
    required ChannelStore channelStore,
    required UnreadMessagesSnapshot initial,
  }) {
    final locatorMap = <int, SendableNarrow>{};
    final streams = <int, TopicKeyedMap<QueueList<int>>>{};
    final dms = <DmNarrow, QueueList<int>>{};
    final mentions = Set.of(initial.mentions);

    for (final unreadChannelSnapshot in initial.channels) {
      final streamId = unreadChannelSnapshot.streamId;
      final topic = unreadChannelSnapshot.topic;
      final topics = (streams[streamId] ??= makeTopicKeyedMap());
      topics.update(topic,
        // Older servers differentiate topics case-sensitively, but shouldn't:
        //   https://github.com/zulip/zulip/pull/31869
        // Our topic-keyed map is case-insensitive. When we've seen this
        // topic before, modulo case, aggregate instead of clobbering.
        // TODO(server-10) simplify away
        (value) => setUnion(value, unreadChannelSnapshot.unreadMessageIds),
        ifAbsent: () => QueueList.from(unreadChannelSnapshot.unreadMessageIds));
      final narrow = TopicNarrow(streamId, topic);
      for (final messageId in unreadChannelSnapshot.unreadMessageIds) {
        locatorMap[messageId] = narrow;
      }
    }

    for (final unreadDmSnapshot in initial.dms) {
      final otherUserId = unreadDmSnapshot.otherUserId;
      final narrow = DmNarrow.withUser(otherUserId, selfUserId: core.selfUserId);
      dms[narrow] = QueueList.from(unreadDmSnapshot.unreadMessageIds);
      for (final messageId in dms[narrow]!) {
        locatorMap[messageId] = narrow;
      }
    }

    for (final unreadHuddleSnapshot in initial.huddles) {
      final narrow = DmNarrow.ofUnreadHuddleSnapshot(unreadHuddleSnapshot,
          selfUserId: core.selfUserId);
      dms[narrow] = QueueList.from(unreadHuddleSnapshot.unreadMessageIds);
      for (final messageId in dms[narrow]!) {
        locatorMap[messageId] = narrow;
      }
    }

    return Unreads._(
      core: core,
      channelStore: channelStore,
      locatorMap: locatorMap,
      streams: streams,
      dms: dms,
      mentions: mentions,
      oldUnreadsMissing: initial.oldUnreadsMissing,
    );
  }

  Unreads._({
    required super.core,
    required this.channelStore,
    required this.locatorMap,
    required this.streams,
    required this.dms,
    required this.mentions,
    required this.oldUnreadsMissing,
  });

  final ChannelStore channelStore;

  /// All unread messages, as: message ID → narrow ([TopicNarrow] or [DmNarrow]).
  ///
  /// Enables efficient [isUnread] and efficient lookups in [streams] and [dms].
  @visibleForTesting
  final Map<int, SendableNarrow> locatorMap;

  // TODO excluded for now; would need to handle nuances around muting etc.
  // int count;

  /// Unread stream messages, as: stream ID → topic → message IDs (sorted).
  ///
  /// The topic-keyed map is case-insensitive and case-preserving;
  /// it comes from [makeTopicKeyedMap].
  final Map<int, TopicKeyedMap<QueueList<int>>> streams;

  /// Unread DM messages, as: DM narrow → message IDs (sorted).
  final Map<DmNarrow, QueueList<int>> dms;

  /// Unread messages with the self-user @-mentioned, directly or by wildcard.
  ///
  /// At initialization, if a message is:
  ///   1) muted because of the user's stream- and topic-level choices [1], and
  ///   2) wildcard mentioned but not directly mentioned
  /// then it will be absent, and its unread state will be unknown to [mentions]
  /// because the message is absent in [UnreadMessagesSnapshot]:
  ///   https://chat.zulip.org/#narrow/stream/378-api-design/topic/register.3A.20maintaining.20.60unread_msgs.2Ementions.60.20correctly/near/1649584
  /// If its state is actually unread, [mentions] recovers that knowledge when:
  ///   a) the message is edited at all ([UpdateMessageEvent]),
  ///      assuming it still has a direct or wildcard mention after the edit, or
  ///   b) the message gains a direct @-mention ([UpdateMessageFlagsEvent]), or
  ///   c) TODO unimplemented: the user loads the message in the message list
  /// But otherwise, assume its unread state remains unknown to [mentions].
  ///
  /// [1] This item applies verbatim at Server 8.0+. For older servers, the
  ///     item would say "in a muted stream" because the "unmute topic"
  ///     feature was not considered:
  ///       https://chat.zulip.org/#narrow/stream/412-api-documentation/topic/register.3A.20.60unread_msgs.2Ementions.60/near/1645622
  // If a message's unread state is unknown, it's likely the user doesn't
  // care about it anyway -- it's really old, or it's in a muted conversation.
  // Still, good to recover the knowledge when possible. In the rare case
  // that a user shows they are interested, like by unmuting or loading messages
  // in the message list, it's important to display as much known state as we can.
  //
  // TODO(server-8) Remove [1].
  final Set<int> mentions;

  /// Whether the model is missing data on old unread messages.
  ///
  /// Initialized to the value of [UnreadMessagesSnapshot.oldUnreadsMissing].
  /// Is set to false when the user clears out all unreads.
  bool oldUnreadsMissing;

  // TODO(#370): maintain this count incrementally, rather than recomputing from scratch
  int countInCombinedFeedNarrow() {
    int c = 0;
    for (final messageIds in dms.values) {
      c = c + messageIds.length;
    }
    for (final MapEntry(key: streamId, value: topics) in streams.entries) {
      for (final MapEntry(key: topic, value: messageIds) in topics.entries) {
        if (channelStore.isTopicVisible(streamId, topic)) {
          c = c + messageIds.length;
        }
      }
    }
    return c;
  }

  /// The "strict" unread count for this channel,
  /// using [ChannelStore.isTopicVisible].
  ///
  /// If the channel is muted, this will count only topics that are
  /// actively unmuted.
  ///
  /// For a count that's appropriate in UI contexts that are focused
  /// specifically on this channel, see [countInChannelNarrow].
  // TODO(#370): maintain this count incrementally, rather than recomputing from scratch
  int countInChannel(int streamId) {
    final topics = streams[streamId];
    if (topics == null) return 0;
    int c = 0;
    for (final entry in topics.entries) {
      if (channelStore.isTopicVisible(streamId, entry.key)) {
        c = c + entry.value.length;
      }
    }
    return c;
  }

  /// The "broad" unread count for this channel,
  /// using [ChannelStore.isTopicVisibleInStream].
  ///
  /// This includes topics that have no visibility policy of their own,
  /// even if the channel itself is muted.
  ///
  /// For a count that's appropriate in UI contexts that are not already
  /// focused on this channel, see [countInChannel].
  // TODO(#370): maintain this count incrementally, rather than recomputing from scratch
  int countInChannelNarrow(int streamId) {
    final topics = streams[streamId];
    if (topics == null) return 0;
    int c = 0;
    for (final entry in topics.entries) {
      if (channelStore.isTopicVisibleInStream(streamId, entry.key)) {
        c = c + entry.value.length;
      }
    }
    return c;
  }

  int countInTopicNarrow(int streamId, TopicName topic) {
    final topics = streams[streamId];
    return topics?[topic]?.length ?? 0;
  }

  int countInDmNarrow(DmNarrow narrow) => dms[narrow]?.length ?? 0;

  int countInMentionsNarrow() => mentions.length;

  // TODO: Implement unreads handling.
  int countInStarredMessagesNarrow() => 0;

  // TODO: Implement unreads handling?
  int countInKeywordSearchNarrow() => 0;

  int countInNarrow(Narrow narrow) {
    switch (narrow) {
      case CombinedFeedNarrow():
        return countInCombinedFeedNarrow();
      case ChannelNarrow():
        return countInChannelNarrow(narrow.streamId);
      case TopicNarrow():
        return countInTopicNarrow(narrow.streamId, narrow.topic);
      case DmNarrow():
        return countInDmNarrow(narrow);
      case MentionsNarrow():
        return countInMentionsNarrow();
      case StarredMessagesNarrow():
        return countInStarredMessagesNarrow();
      case KeywordSearchNarrow():
        return countInKeywordSearchNarrow();
    }
  }

  /// The unread state for [messageId], or null if unknown.
  ///
  /// May be unknown only if [oldUnreadsMissing].
  bool? isUnread(int messageId) {
    final isPresent = locatorMap.containsKey(messageId);
    if (oldUnreadsMissing && !isPresent) return null;
    return isPresent;
  }

  void handleMessageEvent(MessageEvent event) {
    final message = event.message;
    if (message.flags.contains(MessageFlag.read)) {
      return;
    }

    switch (message) {
      case StreamMessage():
        final narrow = TopicNarrow.ofMessage(message);
        locatorMap[event.message.id] = narrow;
        _addLastInStreamTopic(message.id, message.streamId, message.topic);
      case DmMessage():
        final narrow = DmNarrow.ofMessage(message, selfUserId: selfUserId);
        locatorMap[event.message.id] = narrow;
        _addLastInDm(message.id, narrow);
    }
    if (
      message.flags.contains(MessageFlag.mentioned)
      || message.flags.contains(MessageFlag.wildcardMentioned)
    ) {
      mentions.add(message.id);
    }
    notifyListeners();
  }

  void handleUpdateMessageEvent(UpdateMessageEvent event) {
    final messageId = event.messageId;

    // This event might signal mentions being added or removed in the
    // [messageId] message when its content is edited; so, handle that.
    // (As of writing, we don't expect such changes to be signaled by
    // an [UpdateMessageFlagsEvent].)
    final bool isMentioned = event.flags.any(
      (f) => f == MessageFlag.mentioned || f == MessageFlag.wildcardMentioned,
    );

    // We expect the event's 'read' flag to be boring,
    // matching the message's local unread state.
    final bool isRead = event.flags.contains(MessageFlag.read);
    assert(() {
      final isUnreadLocally = isUnread(messageId);
      final isUnreadInEvent = !isRead;

      // Unread state unknown because of [oldUnreadsMissing].
      // We were going to check something but can't; shrug.
      if (isUnreadLocally == null) return true;

      final newChannelId = event.moveData?.newStreamId;
      if (newChannelId != null && !channelStore.subscriptions.containsKey(newChannelId)) {
        // When unread messages are moved to an unsubscribed channel, the server
        // marks them as read without sending a mark-as-read event. Clients are
        // asked to special-case this by marking them as read, which we do in
        // _handleMessageMove. That contract is clear enough and doesn't involve
        // this event's 'read' flag, so don't bother logging about the flag;
        // its behavior seems like an implementation detail that could change.
        return true;
      }

      if (isUnreadLocally != isUnreadInEvent) {
        // If this happens, then either:
        // - the server and client have been out of sync about the message's
        //   unread state since before this event, or
        // - this event was unexpectedly used to announce a change in the
        //   message's 'read' flag.
        debugLog('Unreads warning: got surprising UpdateMessageEvent');
      }
      return true;
    }());

    bool madeAnyUpdate = false;

    switch ((isRead, isMentioned)) {
      case (true,  _    ):
        // A mention (even if new with this event) makes no difference
        // for a message that's already read.
        break;
      case (false, false):
        madeAnyUpdate |= mentions.remove(messageId);
      case (false, true ):
        madeAnyUpdate |= mentions.add(messageId);
    }

    madeAnyUpdate |= _handleMessageMove(event);

    if (madeAnyUpdate) {
      notifyListeners();
    }
  }

  bool _handleMessageMove(UpdateMessageEvent event) {
    if (event.moveData == null) {
      // No moved messages.
      return false;
    }
    final UpdateMessageMoveData(
      :origStreamId, :newStreamId, :origTopic, :newTopic) = event.moveData!;

    final messageToMoveIds = _popAllInStreamTopic(
      event.messageIds.toSet(), origStreamId, origTopic)?..sort();

    if (messageToMoveIds == null || messageToMoveIds.isEmpty) return false;
    assert(event.messageIds.toSet().containsAll(messageToMoveIds));

    if (!channelStore.subscriptions.containsKey(newStreamId)) {
      // Unreads moved to an unsubscribed channel; just drop them.
      // See also:
      //   https://chat.zulip.org/#narrow/channel/378-api-design/topic/mark-as-read.20events.20with.20message.20moves.3F/near/2101926
      for (final messageId in messageToMoveIds) {
        locatorMap.remove(messageId);
      }
      return true;
    }

    final narrow = TopicNarrow(newStreamId, newTopic);
    for (final messageId in messageToMoveIds) {
      locatorMap[messageId] = narrow;
    }
    _addAllInStreamTopic(messageToMoveIds, newStreamId, newTopic);

    return true;
  }

  void handleDeleteMessageEvent(DeleteMessageEvent event) {
    mentions.removeAll(event.messageIds);
    switch (event.messageType) {
      case MessageType.stream:
        // All the messages are in [event.streamId] and [event.topic],
        // so we can be more efficient than _removeAllInStreamsAndDms.
        final streamId = event.streamId!;
        final topic = event.topic!;
        _removeAllInStreamTopic(Set.of(event.messageIds), streamId, topic);
      case MessageType.direct:
        _removeAllInStreamsAndDms(event.messageIds, expectOnlyDms: true);
    }
    for (final messageId in event.messageIds) {
      locatorMap.remove(messageId);
    }

    // TODO skip notifyListeners if unchanged?
    notifyListeners();
  }

  void handleUpdateMessageFlagsEvent(UpdateMessageFlagsEvent event) {
    switch (event.flag) {
      case MessageFlag.starred:
      case MessageFlag.collapsed:
      case MessageFlag.hasAlertWord:
      case MessageFlag.historical:
      case MessageFlag.unknown:
        // These are irrelevant.
        return;

      case MessageFlag.mentioned:
      case MessageFlag.wildcardMentioned:
        // Empirically, we don't seem to get these events when a message is edited
        // to add/remove an @-mention, even though @-mention state is represented
        // as flags. Instead, we just get the [UpdateMessageEvent], and that
        // contains the new set of flags, which we'll use to update [mentions].
        // (See our handling of [UpdateMessageEvent].)
        //
        // Handle the event anyway, using the meaning on the tin.
        // It might be used in a valid case we haven't thought of yet.

        // TODO skip notifyListeners if unchanged?
        switch (event) {
          case UpdateMessageFlagsAddEvent():
            mentions.addAll(
              event.messages.where((messageId) => isUnread(messageId) == true));

          case UpdateMessageFlagsRemoveEvent():
            mentions.removeAll(event.messages);
        }

      case MessageFlag.read:
        switch (event) {
          case UpdateMessageFlagsAddEvent():
            if (event.all) {
              locatorMap.clear();
              streams.clear();
              dms.clear();
              mentions.clear();
              oldUnreadsMissing = false;
            } else {
              final messageIds = event.messages;
              mentions.removeAll(messageIds);
              _removeAllInStreamsAndDms(messageIds);
              for (final messageId in messageIds) {
                locatorMap.remove(messageId);
              }
            }
          case UpdateMessageFlagsRemoveEvent():
            final newlyUnreadInStreams = <int, TopicKeyedMap<QueueList<int>>>{};
            final newlyUnreadInDms = <DmNarrow, QueueList<int>>{};
            for (final messageId in event.messages) {
              final detail = event.messageDetails![messageId];
              if (detail == null) continue; // TODO(log)

              if (detail.mentioned == true) {
                mentions.add(messageId);
              }
              switch (detail.type) {
                case MessageType.stream:
                  final UpdateMessageFlagsMessageDetail(:streamId, :topic) = detail;
                  locatorMap[messageId] = TopicNarrow(streamId!, topic!);
                  final topics = (newlyUnreadInStreams[streamId] ??= makeTopicKeyedMap());
                  final messageIds = (topics[topic] ??= QueueList());
                  messageIds.add(messageId);
                case MessageType.direct:
                  final narrow = DmNarrow.ofUpdateMessageFlagsMessageDetail(selfUserId: selfUserId,
                    detail);
                  locatorMap[messageId] = narrow;
                  (newlyUnreadInDms[narrow] ??= QueueList())
                    .add(messageId);
              }
            }
            for (final MapEntry(key: incomingStreamId, value: incomingTopics)
                 in newlyUnreadInStreams.entries) {
              for (final MapEntry(key: incomingTopic, value: incomingMessageIds)
                   in incomingTopics.entries) {
                _addAllInStreamTopic(incomingMessageIds..sort(), incomingStreamId, incomingTopic);
              }
            }
            for (final MapEntry(key: incomingDmNarrow, value: incomingMessageIds)
                 in newlyUnreadInDms.entries) {
              _addAllInDm(incomingMessageIds..sort(), incomingDmNarrow);
            }
        }
    }
    notifyListeners();
  }

  /// To be called on success of a mark-all-as-read task.
  ///
  /// When the user successfully marks all messages as read,
  /// there can't possibly be ancient unreads we don't know about.
  /// So this updates [oldUnreadsMissing] to false and calls [notifyListeners].
  ///
  /// We don't expect to get a mark-as-read event with `all: true`,
  /// even on completion of the last batch of unreads.
  /// If we did get an event with `all: true` (as we did in a legacy mark-all-
  /// as-read protocol), this would be handled naturally, in
  /// [handleUpdateMessageFlagsEvent].
  ///
  /// Discussion:
  ///   <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20Mark-as-read/near/1680275>
  void handleAllMessagesReadSuccess() {
    oldUnreadsMissing = false;

    // Best not to actually clear any unreads out of the model.
    // That'll be handled naturally when the event comes in, with a list of which
    // messages were marked as read. When a mark-all-as-read task is complete,
    // I don't think the server will always have zero unreads in its state.
    // For example, I assume a new unread message could arrive while the work is
    // in progress, and not get caught and marked as read. We should faithfully
    // match that state. (This point seems especially relevant when the
    // mark-as-read work is done in batches.)
    //
    // Even considering races like that, it does seem basically impossible for
    // `oldUnreadsMissing: false` to be the wrong state at this point.

    notifyListeners();
  }

  void _addLastInStreamTopic(int messageId, int streamId, TopicName topic) {
    ((streams[streamId] ??= makeTopicKeyedMap())[topic] ??= QueueList())
      .addLast(messageId);
  }

  // [messageIds] must be sorted ascending and without duplicates.
  void _addAllInStreamTopic(QueueList<int> messageIds, int streamId, TopicName topic) {
    assert(messageIds.isNotEmpty);
    assert(isSortedWithoutDuplicates(messageIds));
    final topics = streams[streamId] ??= makeTopicKeyedMap();
    topics.update(topic,
      ifAbsent: () => messageIds,
      // setUnion dedupes existing and incoming unread IDs,
      // so we tolerate zulip/zulip#22164, fixed in 6.0
      // TODO(server-6) remove 6.0 comment
      (existing) => setUnion(existing, messageIds),
    );
  }

  /// Remove [idsToRemove] from [streams] and [dms].
  void _removeAllInStreamsAndDms(Iterable<int> idsToRemove, {bool expectOnlyDms = false}) {
    final idsPresentByNarrow = <SendableNarrow, Set<int>>{};
    for (final id in idsToRemove) {
      final narrow = locatorMap[id];
      if (narrow == null) continue;
      (idsPresentByNarrow[narrow] ??= {}).add(id);
    }

    for (final MapEntry(key: narrow, value: ids) in idsPresentByNarrow.entries) {
      switch (narrow) {
        case TopicNarrow():
          if (expectOnlyDms) {
            // TODO(log)?
          }
          _removeAllInStreamTopic(ids, narrow.streamId, narrow.topic);
        case DmNarrow():
          final messageIds = dms[narrow];
          if (messageIds == null) return;

          // ([QueueList] doesn't have a `removeAll`)
          messageIds.removeWhere((id) => ids.contains(id));
          if (messageIds.isEmpty) {
            dms.remove(narrow);
          }
      }
    }
  }

  void _removeAllInStreamTopic(Set<int> incomingMessageIds, int streamId, TopicName topic) {
    final topics = streams[streamId];
    if (topics == null) return;
    final messageIds = topics[topic];
    if (messageIds == null) return;

    // ([QueueList] doesn't have a `removeAll`)
    messageIds.removeWhere((id) => incomingMessageIds.contains(id));
    if (messageIds.isEmpty) {
      topics.remove(topic);
      if (topics.isEmpty) {
        streams.remove(streamId);
      }
    }
  }

  /// Remove unread stream messages contained in `incomingMessageIds`, with
  /// the matching `streamId` and `topic`.
  ///
  /// Returns the removed message IDs, or `null` if no messages are affected.
  ///
  /// Use [_removeAllInStreamTopic] if the removed message IDs are not needed.
  // Part of this is adapted from [ListBase.removeWhere].
  QueueList<int>? _popAllInStreamTopic(Set<int> incomingMessageIds, int streamId, TopicName topic) {
    final topics = streams[streamId];
    if (topics == null) return null;
    final messageIds = topics[topic];
    if (messageIds == null) return null;

    final retainedMessageIds = messageIds.whereNot(
      (id) => incomingMessageIds.contains(id)).toList();

    if (retainedMessageIds.isEmpty) {
      // This is an optimization for the case when all messages in the
      // conversation are removed, which avoids making a copy of `messageIds`
      // unnecessarily.
      topics.remove(topic);
      if (topics.isEmpty) {
        streams.remove(streamId);
      }
      return messageIds;
    }

    QueueList<int>? poppedMessageIds;
    if (retainedMessageIds.length != messageIds.length) {
      poppedMessageIds = QueueList.from(
        messageIds.where((id) => incomingMessageIds.contains(id)));
      messageIds.setRange(0, retainedMessageIds.length, retainedMessageIds);
      messageIds.length = retainedMessageIds.length;
    }
    if (messageIds.isEmpty) {
      topics.remove(topic);
      if (topics.isEmpty) {
        streams.remove(streamId);
      }
    }
    return poppedMessageIds;
  }

  void _addLastInDm(int messageId, DmNarrow narrow) {
    (dms[narrow] ??= QueueList()).addLast(messageId);
  }

  // [messageIds] must be sorted ascending and without duplicates.
  void _addAllInDm(QueueList<int> messageIds, DmNarrow dmNarrow) {
    dms.update(dmNarrow,
      ifAbsent: () => messageIds,
      // setUnion dedupes existing and incoming unread IDs,
      // so we tolerate zulip/zulip#22164, fixed in 6.0
      // TODO(server-6) remove 6.0 comment
      (existing) => setUnion(existing, messageIds),
    );
  }
}
