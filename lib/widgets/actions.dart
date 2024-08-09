/// Methods that act through the Zulip API and show feedback in the UI.
///
/// The methods in this file can be thought of as higher-level wrappers for
/// some of the Zulip API endpoint binding methods in `lib/api/route/`.
/// But they don't belong in `lib/api/`, because they also interact with widgets
/// in order to present success or error feedback to the user through the UI.
library;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';

import '../api/model/model.dart';
import '../api/model/narrow.dart';
import '../api/route/messages.dart';
import '../model/narrow.dart';
import 'dialog.dart';
import 'store.dart';

/// Returns true if mark as read process is completed successfully.
Future<bool> markNarrowAsRead(
  BuildContext context,
  Narrow narrow,
  bool useLegacy, // TODO(server-6)
) async {
  final store = PerAccountStoreWidget.of(context);
  final connection = store.connection;
  if (useLegacy) {
    await _legacyMarkNarrowAsRead(context, narrow);
    return true;
  }

  // Compare web's `mark_all_as_read` in web/src/unread_ops.js
  // and zulip-mobile's `markAsUnreadFromMessage` in src/action-sheets/index.js .
  final zulipLocalizations = ZulipLocalizations.of(context);
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  // Use [AnchorCode.oldest], because [AnchorCode.firstUnread]
  // will be the oldest non-muted unread message, which would
  // result in muted unreads older than the first unread not
  // being processed.
  Anchor anchor = AnchorCode.oldest;
  int responseCount = 0;
  int updatedCount = 0;

  // Include `is:unread` in the narrow.  That has a database index, so
  // this can be an important optimization in narrows with a lot of history.
  // The server applies the same optimization within the (deprecated)
  // specialized endpoints for marking messages as read; see
  // `do_mark_stream_messages_as_read` in `zulip:zerver/actions/message_flags.py`.
  final apiNarrow = narrow.apiEncode()..add(ApiNarrowIsUnread());

  while (true) {
    final result = await updateMessageFlagsForNarrow(connection,
      anchor: anchor,
      // [AnchorCode.oldest] is an anchor ID lower than any valid
      // message ID; and follow-up requests will have already
      // processed the anchor ID, so we just want this to be
      // unconditionally false.
      includeAnchor: false,
      // There is an upper limit of 5000 messages per batch
      // (numBefore + numAfter <= 5000) enforced on the server.
      // See `update_message_flags_in_narrow` in zerver/views/message_flags.py .
      // zulip-mobile uses `numAfter` of 5000, but web uses 1000
      // for more responsive feedback. See zulip@f0d87fcf6.
      numBefore: 0,
      numAfter: 1000,
      narrow: apiNarrow,
      op: UpdateMessageFlagsOp.add,
      flag: MessageFlag.read);
    if (!context.mounted) {
      scaffoldMessenger.clearSnackBars();
      return false;
    }
    responseCount++;
    updatedCount += result.updatedCount;

    if (result.foundNewest) {
      if (responseCount > 1) {
        // We previously showed an in-progress [SnackBar], so say we're done.
        // There may be a backlog of [SnackBar]s accumulated in the queue
        // so be sure to clear them out here.
        scaffoldMessenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(behavior: SnackBarBehavior.floating,
              content: Text(zulipLocalizations.markAsReadComplete(updatedCount))));
      }
      return true;
    }

    if (result.lastProcessedId == null) {
      // No messages were in the range of the request.
      // This should be impossible given that `foundNewest` was false
      // (and that our `numAfter` was positive.)
      await showErrorDialog(context: context,
        title: zulipLocalizations.errorMarkAsReadFailedTitle,
        message: zulipLocalizations.errorInvalidResponse);
      return false;
    }
    anchor = NumericAnchor(result.lastProcessedId!);

    // The task is taking a while, so tell the user we're working on it.
    // No need to say how many messages, as the [MarkAsUnread] widget
    // should follow along.
    // TODO: Ideally we'd have a progress widget here that showed up based
    //   on actual time elapsed -- so it could appear before the first
    //   batch returns, if that takes a while -- and that then stuck
    //   around continuously until the task ends. For now we use a
    //   series of [SnackBar]s, which may feel a bit janky.
    //   There is complexity in tracking the status of each [SnackBar],
    //   due to having no way to determine which is currently active,
    //   or if there is an active one at all.  Resetting the [SnackBar] here
    //   results in the same message popping in and out and the user experience
    //   is better for now if we allow them to run their timer through
    //   and clear the backlog later.
    scaffoldMessenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating,
      content: Text(zulipLocalizations.markAsReadInProgress)));
  }
}

Future<void> _legacyMarkNarrowAsRead(BuildContext context, Narrow narrow) async {
  final store = PerAccountStoreWidget.of(context);
  final connection = store.connection;
  switch (narrow) {
    case CombinedFeedNarrow():
      await markAllAsRead(connection);
    case ChannelNarrow(:final streamId):
      await markStreamAsRead(connection, streamId: streamId);
    case TopicNarrow(:final streamId, :final topic):
      await markTopicAsRead(connection, streamId: streamId, topicName: topic);
    case DmNarrow():
      final unreadDms = store.unreads.dms[narrow];
      // Silently ignore this race-condition as the outcome
      // (no unreads in this narrow) was the desired end-state
      // of pushing the button.
      if (unreadDms == null) return;
      await updateMessageFlags(connection,
        messages: unreadDms,
        op: UpdateMessageFlagsOp.add,
        flag: MessageFlag.read);
    case MentionsNarrow():
      final unreadMentions = store.unreads.mentions.toList();
      if (unreadMentions.isEmpty) return;
      await updateMessageFlags(connection,
        messages: unreadMentions,
        op: UpdateMessageFlagsOp.add,
        flag: MessageFlag.read);
  }
}
