import 'dart:core';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/model/events.dart';
import '../log.dart';
import 'algorithms.dart';
import 'narrow.dart';

/// The view-model for unread messages.
///
/// Implemented to track actual unread state as faithfully as possible
/// given incomplete information in [UnreadMessagesSnapshot].
/// Callers should do their own filtering based on other state, like muting,
/// as desired.
///
/// In each component of this model ([_totalCount], [streams], [dms], [mentions]),
/// if a message is not represented, its status is either read
/// or unknown to the component. In all components,
/// a message's status will be unknown if, at /register time,
/// it was very old by the server's reckoning. See [oldUnreadsMissing].
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
// TODO handle moved messages
// TODO When [oldUnreadsMissing], if you load a message list with very old unreads,
//   sync to those unreads, because the user has shown an interest in them.
// TODO When loading a message list with stream messages, check all the stream
//   messages and refresh [mentions] (see [mentions] dartdoc).
class Unreads extends ChangeNotifier {
  factory Unreads({required UnreadMessagesSnapshot initial, required selfUserId}) {
    int totalCount = 0;
    final streams = <int, Map<String, QueueList<int>>>{};
    final dms = <DmNarrow, QueueList<int>>{};
    final mentions = Set.of(initial.mentions);

    for (final unreadStreamSnapshot in initial.streams) {
      final streamId = unreadStreamSnapshot.streamId;
      final topic = unreadStreamSnapshot.topic;
      (streams[streamId] ??= {})[topic] = QueueList.from(unreadStreamSnapshot.unreadMessageIds);
      totalCount += unreadStreamSnapshot.unreadMessageIds.length;
    }

    for (final unreadDmSnapshot in initial.dms) {
      final otherUserId = unreadDmSnapshot.otherUserId;
      final narrow = DmNarrow.withUser(otherUserId, selfUserId: selfUserId);
      dms[narrow] = QueueList.from(unreadDmSnapshot.unreadMessageIds);
      totalCount += unreadDmSnapshot.unreadMessageIds.length;
    }

    for (final unreadHuddleSnapshot in initial.huddles) {
      final narrow = DmNarrow.ofUnreadHuddleSnapshot(unreadHuddleSnapshot, selfUserId: selfUserId);
      dms[narrow] = QueueList.from(unreadHuddleSnapshot.unreadMessageIds);
      totalCount += unreadHuddleSnapshot.unreadMessageIds.length;
    }

    return Unreads._(
      totalCount: totalCount,
      streams: streams,
      dms: dms,
      mentions: mentions,
      oldUnreadsMissing: initial.oldUnreadsMissing,
      selfUserId: selfUserId,
    );
  }

  Unreads._({
    required totalCount,
    required this.streams,
    required this.dms,
    required this.mentions,
    required this.oldUnreadsMissing,
    required this.selfUserId,
  }) : _totalCount = totalCount;

  /// Total unread messages.
  ///
  /// Prefer this when possible over traversing the model to make a sum.
  ///
  /// We initialize and maintain this ourselves,
  /// ignoring [UnreadMessagesSnapshot.count] because it has information gaps
  /// beyond the ones explained in [oldUnreadsMissing]:
  ///   https://chat.zulip.org/#narrow/stream/378-api-design/topic/register.3A.20maintaining.20.60unread_msgs.2Ementions.60.20correctly/near/1668449
  int get totalCount => _totalCount;
  int _totalCount;

  /// Unread stream messages, as: stream ID → topic → message ID.
  final Map<int, Map<String, QueueList<int>>> streams;

  /// Unread DM messages, as: DM narrow → message ID.
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
  /// Is set to false when the user clears out all unreads at once.
  bool oldUnreadsMissing;

  final int selfUserId;

  void handleMessageEvent(MessageEvent event) {
    final message = event.message;
    if (message.flags.contains(MessageFlag.read)) {
      return;
    }

    switch (message) {
      case StreamMessage():
        _addLastInStreamTopic(message.id, message.streamId, message.subject);
      case DmMessage():
        final narrow = DmNarrow.ofMessage(message, selfUserId: selfUserId);
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

    // We assume this event can't signal a change in a message's 'read' flag.
    // TODO can it actually though, when it's about messages being moved into an
    //   unsubscribed stream?
    //   https://chat.zulip.org/#narrow/stream/378-api-design/topic/mark-as-read.20events.20with.20message.20moves.3F/near/1639957
    final bool isRead = event.flags.contains(MessageFlag.read);
    assert(() {
      if (!oldUnreadsMissing && !event.messageIds.every((messageId) {
        final isUnreadLocally = _slowIsPresentInDms(messageId) || _slowIsPresentInStreams(messageId);
        return isUnreadLocally == !isRead;
      })) {
        // If this happens, then either:
        // - the server and client have been out of sync about a message's
        //   unread state since before this event, or
        // - this event was unexpectedly used to announce a change in a
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

    // (Moved messages will be handled here;
    // the TODO for that is just above the class declaration.)

    if (madeAnyUpdate) {
      notifyListeners();
    }
  }

  void handleDeleteMessageEvent(DeleteMessageEvent event) {
    mentions.removeAll(event.messageIds);
    final messageIdsSet = Set.of(event.messageIds);
    switch (event.messageType) {
      case MessageType.stream:
        final streamId = event.streamId!;
        final topic = event.topic!;
        _removeAllInStreamTopic(messageIdsSet, streamId, topic);
      case MessageType.private:
        _slowRemoveAllInDms(messageIdsSet);
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
              event.messages.where(
                (messageId) => _slowIsPresentInStreams(messageId) || _slowIsPresentInDms(messageId),
              ),
            );

          case UpdateMessageFlagsRemoveEvent():
            mentions.removeAll(event.messages);
        }

      case MessageFlag.read:
        switch (event) {
          case UpdateMessageFlagsAddEvent():
            if (event.all) {
              _totalCount = 0;
              streams.clear();
              dms.clear();
              mentions.clear();
              oldUnreadsMissing = false;
            } else {
              final messageIdsSet = Set.of(event.messages);
              mentions.removeAll(messageIdsSet);
              _slowRemoveAllInStreams(messageIdsSet);
              _slowRemoveAllInDms(messageIdsSet);
            }
          case UpdateMessageFlagsRemoveEvent():
            final newlyUnreadInStreams = <int, Map<String, QueueList<int>>>{};
            final newlyUnreadInDms = <DmNarrow, QueueList<int>>{};
            for (final messageId in event.messages) {
              final detail = event.messageDetails![messageId];
              if (detail == null) { // TODO(log) if on Zulip 6.0+
                // Happens as a bug in some cases before fixed in Zulip 6.0:
                //   https://chat.zulip.org/#narrow/stream/378-api-design/topic/unreads.20in.20unsubscribed.20streams/near/1458467
                // TODO(server-6) remove Zulip 6.0 comment
                continue;
              }
              if (detail.mentioned == true) {
                mentions.add(messageId);
              }
              switch (detail.type) {
                case MessageType.stream:
                  final topics = (newlyUnreadInStreams[detail.streamId!] ??= {});
                  final messageIds = (topics[detail.topic!] ??= QueueList());
                  messageIds.add(messageId);
                case MessageType.private:
                  final narrow = DmNarrow.ofUpdateMessageFlagsMessageDetail(selfUserId: selfUserId,
                    detail);
                  (newlyUnreadInDms[narrow] ??= QueueList())
                    .add(messageId);
              }
            }
            for (
              final MapEntry(key: incomingStreamId, value: incomingTopics)
              in newlyUnreadInStreams.entries
            ) {
              for (
                final MapEntry(key: incomingTopic, value: incomingMessageIds)
                in incomingTopics.entries
              ) {
                _addAllInStreamTopic(incomingMessageIds..sort(), incomingStreamId, incomingTopic);
              }
            }
            for (
              final MapEntry(key: incomingDmNarrow, value: incomingMessageIds)
              in newlyUnreadInDms.entries
            ) {
              _addAllInDm(incomingMessageIds..sort(), incomingDmNarrow);
            }
        }
    }
    notifyListeners();
  }

  // TODO use efficient lookups
  bool _slowIsPresentInStreams(int messageId) {
    return streams.values.any(
      (topics) => topics.values.any(
        (messageIds) => messageIds.contains(messageId),
      ),
    );
  }

  void _addLastInStreamTopic(int messageId, int streamId, String topic) {
    ((streams[streamId] ??= {})[topic] ??= QueueList()).addLast(messageId);
    _totalCount += 1;
  }

  // [messageIds] must be sorted ascending and without duplicates.
  void _addAllInStreamTopic(QueueList<int> messageIds, int streamId, String topic) {
    int numAdded = 0;
    final topics = streams[streamId] ??= {};
    topics.update(topic,
      ifAbsent: () {
        numAdded = messageIds.length;
        return messageIds;
      },
      // setUnion dedupes existing and incoming unread IDs,
      // so we tolerate zulip/zulip#22164, fixed in 6.0
      // TODO(server-6) remove 6.0 comment
      (existing) {
        final result = setUnion(existing, messageIds);
        numAdded = result.length - messageIds.length;
        return result;
      },
    );
    _totalCount += numAdded;
  }

  // TODO use efficient model lookups
  void _slowRemoveAllInStreams(Set<int> idsToRemove) {
    int numRemoved = 0;
    final newlyEmptyStreams = [];
    for (final MapEntry(key: streamId, value: topics) in streams.entries) {
      final newlyEmptyTopics = [];
      for (final MapEntry(key: topic, value: messageIds) in topics.entries) {
        final lengthBefore = messageIds.length;
        messageIds.removeWhere((id) => idsToRemove.contains(id));
        numRemoved += lengthBefore - messageIds.length;
        if (messageIds.isEmpty) {
          newlyEmptyTopics.add(topic);
        }
      }
      for (final topic in newlyEmptyTopics) {
        topics.remove(topic);
      }
      if (topics.isEmpty) {
        newlyEmptyStreams.add(streamId);
      }
    }
    for (final streamId in newlyEmptyStreams) {
      streams.remove(streamId);
    }
    _totalCount -= numRemoved;
  }

  void _removeAllInStreamTopic(Set<int> incomingMessageIds, int streamId, String topic) {
    final topics = streams[streamId];
    if (topics == null) return;
    final messageIds = topics[topic];
    if (messageIds == null) return;

    // ([QueueList] doesn't have a `removeAll`)
    final lengthBefore = messageIds.length;
    messageIds.removeWhere((id) => incomingMessageIds.contains(id));
    _totalCount -= lengthBefore - messageIds.length;
    if (messageIds.isEmpty) {
      topics.remove(topic);
      if (topics.isEmpty) {
        streams.remove(streamId);
      }
    }
  }

  // TODO use efficient model lookups
  bool _slowIsPresentInDms(int messageId) {
    return dms.values.any((ids) => ids.contains(messageId));
  }

  void _addLastInDm(int messageId, DmNarrow narrow) {
    (dms[narrow] ??= QueueList()).addLast(messageId);
    _totalCount += 1;
  }

  // [messageIds] must be sorted ascending and without duplicates.
  void _addAllInDm(QueueList<int> messageIds, DmNarrow dmNarrow) {
    int numAdded = 0;
    dms.update(dmNarrow,
      ifAbsent: () {
        numAdded = messageIds.length;
        return messageIds;
      },
      // setUnion dedupes existing and incoming unread IDs,
      // so we tolerate zulip/zulip#22164, fixed in 6.0
      // TODO(server-6) remove 6.0 comment
      (existing) {
        final result = setUnion(existing, messageIds);
        numAdded = result.length - messageIds.length;
        return result;
      },
    );
    _totalCount += numAdded;
  }

  // TODO use efficient model lookups
  void _slowRemoveAllInDms(Set<int> idsToRemove) {
    int numRemoved = 0;
    final newlyEmptyDms = [];
    for (final MapEntry(key: dmNarrow, value: messageIds) in dms.entries) {
      final lengthBefore = messageIds.length;
      messageIds.removeWhere((id) => idsToRemove.contains(id));
      numRemoved += lengthBefore - messageIds.length;
      if (messageIds.isEmpty) {
        newlyEmptyDms.add(dmNarrow);
      }
    }
    for (final dmNarrow in newlyEmptyDms) {
      dms.remove(dmNarrow);
    }
    _totalCount -= numRemoved;
  }
}
