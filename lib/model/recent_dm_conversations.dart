import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/model/events.dart';
import 'narrow.dart';
import 'store.dart';

/// A view-model for the recent-DM-conversations UI.
///
/// This maintains the list of recent DM conversations,
/// plus additional data in order to efficiently maintain the list.
class RecentDmConversationsView extends PerAccountStoreBase with ChangeNotifier {
  factory RecentDmConversationsView({
    required CorePerAccountStore core,
    required List<RecentDmConversation> initial,
  }) {
    final entries = initial.map((conversation) => MapEntry(
        DmNarrow.ofRecentDmConversation(conversation, selfUserId: core.selfUserId),
        conversation.maxMessageId,
      )).toList()..sort((a, b) => -a.value.compareTo(b.value));

    final latestMessagesByRecipient = <int, int>{};
    for (final entry in entries) {
      final dmNarrow = entry.key;
      final maxMessageId = entry.value;
      for (final userId in dmNarrow.otherRecipientIds) {
        // Only take the latest message of a user across all the conversations.
        latestMessagesByRecipient.putIfAbsent(userId, () => maxMessageId);
      }
    }

    return RecentDmConversationsView._(
      core: core,
      map: Map.fromEntries(entries),
      sorted: QueueList.from(entries.map((e) => e.key)),
      latestMessagesByRecipient: latestMessagesByRecipient,
    );
  }

  RecentDmConversationsView._({
    required super.core,
    required this.map,
    required this.sorted,
    required this.latestMessagesByRecipient,
  });

  /// The latest message ID in each conversation.
  final Map<DmNarrow, int> map;

  /// The [DmNarrow] keys of [map], sorted by latest message descending.
  final QueueList<DmNarrow> sorted;

  /// Map from user ID to the latest message ID in any conversation with the user.
  ///
  /// Both 1:1 and group DM conversations are considered.
  /// The self-user ID is excluded even if there is a self-DM conversation.
  ///
  /// (The identified message was not necessarily sent by the identified user;
  /// it might have been sent by anyone in its conversation.)
  final Map<int, int> latestMessagesByRecipient;

  /// Insert the key at the proper place in [sorted].
  ///
  /// Optimized, taking O(1) time, for the case where that place is the start,
  /// because that's the common case for a new message.
  /// May take O(n) time in general.
  void _insertSorted(DmNarrow key, int msgId) {
    final i = sorted.indexWhere((k) => map[k]! < msgId);
    // QueueList is a deque, with O(1) to add at start or end.
    switch (i) {
      case == 0:
        sorted.addFirst(key);
      case < 0:
        sorted.addLast(key);
      default:
        sorted.insert(i, key);
    }
  }

  /// Handle [MessageEvent], updating [map], [sorted], and [latestMessagesByRecipient].
  ///
  /// Can take linear time in general.  That sounds inefficient...
  /// but it's what the webapp does, so must not be catastrophic. 🤷
  /// (In fact the webapp calls `Array#sort`,
  /// which takes at *least* linear time, and may be 𝛳(N log N).)
  ///
  /// The point of the event is that we're learning about the message
  /// in real time immediately after it was sent --
  /// so the overwhelmingly common case is that the message
  /// is newer than any existing message we know about. (*)
  /// That's therefore the case we optimize for,
  /// particularly in the helper _insertSorted.
  ///
  /// (*) In fact at present that's the only possible case.
  /// The alternative will become possible when we have the analogue of
  /// zulip-mobile's FETCH_MESSAGES_COMPLETE, with fetches done for a
  /// [MessageListView] reporting their messages back via the [PerAccountStore]
  /// to all our central data structures.
  /// Then that can race with a new-message event: for example,
  /// say we get a fetch-messages result that includes the just-sent
  /// message 1002, and only after that get the event about message 1001,
  /// sent moments earlier.  The event queue always delivers events in order, so
  /// even the race is possible only because we fetch messages outside of the
  /// event queue.
  void handleMessageEvent(MessageEvent event) {
    final message = event.message;
    if (message is! DmMessage) {
      return;
    }
    final key = DmNarrow.ofMessage(message, selfUserId: selfUserId);

    // Update [map] and [sorted].
    final prev = map[key];
    if (prev == null) {
      // The conversation is new.  Add to both `map` and `sorted`.
      map[key] = message.id;
      _insertSorted(key, message.id);
    } else if (prev >= message.id) {
      // The conversation already has a newer message.
      // This should be impossible as long as we only listen for messages coming
      // through the event system, which sends events in order.
      // Anyway, do nothing.
    } else {
      // The conversation needs to be (a) updated in `map`...
      map[key] = message.id;

      // ... and (b) possibly moved around in `sorted` to keep the list sorted.
      final i = sorted.indexOf(key);
      assert(i >= 0, 'key in map should be in sorted');
      if (i == 0) {
        // The conversation was already the latest, so no reordering needed.
        // (This is likely a common case in practice -- happens every time
        // the user gets several DMs in a row in the same thread -- so good to
        // optimize.)
      } else {
        // It wasn't the latest.  Just handle the general case.
        sorted.removeAt(i); // linear time, ouch
        _insertSorted(key, message.id);
      }
    }

    // Update [latestMessagesByRecipient].
    for (final recipient in key.otherRecipientIds) {
      latestMessagesByRecipient.update(
        recipient,
        (latestMessageId) => max(message.id, latestMessageId),
        ifAbsent: () => message.id,
      );
    }

    notifyListeners();
  }

  // TODO update from messages loaded in message lists. When doing so,
  //   review handleMessageEvent so it acknowledges the subtle races that can
  //   happen when taking data from outside the event system.
}
