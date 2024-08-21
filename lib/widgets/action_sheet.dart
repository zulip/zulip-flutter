import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../api/exception.dart';
import '../api/model/model.dart';
import '../api/route/messages.dart';
import '../model/internal_link.dart';
import '../model/narrow.dart';
import 'actions.dart';
import 'clipboard.dart';
import 'compose_box.dart';
import 'dialog.dart';
import 'draggable_scrollable_modal_bottom_sheet.dart';
import 'icons.dart';
import 'message_list.dart';
import 'store.dart';

/// Show a sheet of actions you can take on a message in the message list.
///
/// Must have a [MessageListPage] ancestor.
void showMessageActionSheet({required BuildContext context, required Message message}) {
  final store = PerAccountStoreWidget.of(context);

  // The UI that's conditioned on this won't live-update during this appearance
  // of the action sheet (we avoid calling composeBoxControllerOf in a build
  // method; see its doc). But currently it will be constant through the life of
  // any message list, so that's fine.
  final messageListPage = MessageListPage.ancestorOf(context);
  final isComposeBoxOffered = messageListPage.composeBoxController != null;
  final narrow = messageListPage.narrow;
  final isMessageRead = message.flags.contains(MessageFlag.read);
  final markAsUnreadSupported = store.connection.zulipFeatureLevel! >= 155; // TODO(server-6)
  final showMarkAsUnreadButton = markAsUnreadSupported && isMessageRead;

  final hasThumbsUpReactionVote = message.reactions
    ?.aggregated.any((reactionWithVotes) =>
      reactionWithVotes.reactionType == ReactionType.unicodeEmoji
      && reactionWithVotes.emojiCode == '1f44d'
      && reactionWithVotes.userIds.contains(store.selfUserId))
    ?? false;

  showDraggableScrollableModalBottomSheet<void>(
    context: context,
    builder: (BuildContext _) {
      return Column(children: [
        if (!hasThumbsUpReactionVote)
          AddThumbsUpButton(message: message, messageListContext: context),
        StarButton(message: message, messageListContext: context),
        if (isComposeBoxOffered)
          QuoteAndReplyButton(message: message, messageListContext: context),
        if (showMarkAsUnreadButton)
          MarkAsUnreadButton(message: message, messageListContext: context, narrow: narrow),
        CopyMessageTextButton(message: message, messageListContext: context),
        CopyMessageLinkButton(message: message, messageListContext: context),
        ShareButton(message: message, messageListContext: context),
      ]);
    });
}

abstract class MessageActionSheetMenuItemButton extends StatelessWidget {
  MessageActionSheetMenuItemButton({
    super.key,
    required this.message,
    required this.messageListContext,
  }) : assert(messageListContext.findAncestorWidgetOfExactType<MessageListPage>() != null);

  IconData get icon;
  String label(ZulipLocalizations zulipLocalizations);
  void onPressed(BuildContext context);

  final Message message;
  final BuildContext messageListContext;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return MenuItemButton(
      leadingIcon: Icon(icon),
      onPressed: () => onPressed(context),
      child: Text(label(zulipLocalizations)));
  }
}

// This button is very temporary, to complete #125 before we have a way to
// choose an arbitrary reaction (#388). So, skipping i18n.
class AddThumbsUpButton extends MessageActionSheetMenuItemButton {
  AddThumbsUpButton({
    super.key,
    required super.message,
    required super.messageListContext,
  });

  @override IconData get icon => Icons.add_reaction_outlined;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return 'React with 👍'; // TODO(i18n) skip translation for now
  }

  @override void onPressed(BuildContext context) async {
    Navigator.of(context).pop();
    String? errorMessage;
    try {
      await addReaction(PerAccountStoreWidget.of(messageListContext).connection,
        messageId: message.id,
        reactionType: ReactionType.unicodeEmoji,
        emojiCode: '1f44d',
        emojiName: '+1',
      );
    } catch (e) {
      if (!messageListContext.mounted) return;

      switch (e) {
        case ZulipApiException():
          errorMessage = e.message;
          // TODO(#741) specific messages for common errors, like network errors
          //   (support with reusable code)
        default:
      }

      await showErrorDialog(context: context,
        title: 'Adding reaction failed', message: errorMessage);
    }
  }
}

class StarButton extends MessageActionSheetMenuItemButton {
  StarButton({
    super.key,
    required super.message,
    required super.messageListContext,
  });

  @override IconData get icon => ZulipIcons.star_filled;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return message.flags.contains(MessageFlag.starred)
      ? zulipLocalizations.actionSheetOptionUnstarMessage
      : zulipLocalizations.actionSheetOptionStarMessage;
  }

  @override void onPressed(BuildContext context) async {
    Navigator.of(context).pop();
    final zulipLocalizations = ZulipLocalizations.of(messageListContext);
    final op = message.flags.contains(MessageFlag.starred)
      ? UpdateMessageFlagsOp.remove
      : UpdateMessageFlagsOp.add;

    try {
      final connection = PerAccountStoreWidget.of(messageListContext).connection;
      await updateMessageFlags(connection, messages: [message.id],
        op: op, flag: MessageFlag.starred);
    } catch (e) {
      if (!messageListContext.mounted) return;

      String? errorMessage;
      switch (e) {
        case ZulipApiException():
          errorMessage = e.message;
          // TODO specific messages for common errors, like network errors
          //   (support with reusable code)
        default:
      }

      await showErrorDialog(context: messageListContext,
        title: switch(op) {
          UpdateMessageFlagsOp.remove => zulipLocalizations.errorUnstarMessageFailedTitle,
          UpdateMessageFlagsOp.add    => zulipLocalizations.errorStarMessageFailedTitle,
        }, message: errorMessage);
    }
  }
}

/// Fetch and return the raw Markdown content for [messageId],
/// showing an error dialog on failure.
Future<String?> fetchRawContentWithFeedback({
  required BuildContext context,
  required int messageId,
  required String errorDialogTitle,
}) async {
    Message? fetchedMessage;
    String? errorMessage;
    // TODO, supported by reusable code:
    // - (?) Retry with backoff on plausibly transient errors.
    // - If request(s) take(s) a long time, show snackbar with cancel
    //   button, like "Still working on quote-and-reply…".
    //   On final failure or success, auto-dismiss the snackbar.
    final zulipLocalizations = ZulipLocalizations.of(context);
    try {
      fetchedMessage = await getMessageCompat(PerAccountStoreWidget.of(context).connection,
        messageId: messageId,
        applyMarkdown: false,
      );
      if (fetchedMessage == null) {
        errorMessage = zulipLocalizations.errorMessageDoesNotSeemToExist;
      }
    } catch (e) {
      switch (e) {
        case ZulipApiException():
          errorMessage = e.message;
        // TODO specific messages for common errors, like network errors
        //   (support with reusable code)
        default:
          errorMessage = zulipLocalizations.errorCouldNotFetchMessageSource;
      }
    }

    if (!context.mounted) return null;

    if (fetchedMessage == null) {
      assert(errorMessage != null);
      // TODO(?) give no feedback on error conditions we expect to
      //   flag centrally in event polling, like invalid auth,
      //   user/realm deactivated. (Support with reusable code.)
      await showErrorDialog(context: context,
        title: errorDialogTitle, message: errorMessage);
    }

    return fetchedMessage?.content;
}

class QuoteAndReplyButton extends MessageActionSheetMenuItemButton {
  QuoteAndReplyButton({
    super.key,
    required super.message,
    required super.messageListContext,
  });

  @override IconData get icon => Icons.format_quote_outlined;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionQuoteAndReply;
  }

  @override void onPressed(BuildContext context) async {
    // Close the message action sheet. We'll show the request progress
    // in the compose-box content input with a "[Quoting…]" placeholder.
    Navigator.of(context).pop();
    final zulipLocalizations = ZulipLocalizations.of(messageListContext);

    // This will be null only if the compose box disappeared after the
    // message action sheet opened, and before "Quote and reply" was pressed.
    // Currently a compose box can't ever disappear, so this is impossible.
    ComposeBoxController composeBoxController =
      MessageListPage.ancestorOf(messageListContext).composeBoxController!;
    final topicController = composeBoxController.topicController;
    if (
      topicController != null
      && topicController.textNormalized == kNoTopicTopic
      && message is StreamMessage
    ) {
      topicController.value = TextEditingValue(text: message.topic);
    }
    final tag = composeBoxController.contentController
      .registerQuoteAndReplyStart(PerAccountStoreWidget.of(messageListContext),
        message: message,
      );

    final rawContent = await fetchRawContentWithFeedback(
      context: messageListContext,
      messageId: message.id,
      errorDialogTitle: zulipLocalizations.errorQuotationFailed,
    );

    if (!messageListContext.mounted) return;

    // This will be null only if the compose box disappeared during the
    // quotation request. Currently a compose box can't ever disappear,
    // so this is impossible.
    composeBoxController =
      MessageListPage.ancestorOf(messageListContext).composeBoxController!;
    composeBoxController.contentController
      .registerQuoteAndReplyEnd(PerAccountStoreWidget.of(messageListContext), tag,
        message: message,
        rawContent: rawContent,
      );
    if (!composeBoxController.contentFocusNode.hasFocus) {
      composeBoxController.contentFocusNode.requestFocus();
    }
  }
}

class MarkAsUnreadButton extends MessageActionSheetMenuItemButton {
  MarkAsUnreadButton({
    super.key,
    required super.message,
    required super.messageListContext,
    required this.narrow,
  });

  final Narrow narrow;

  @override IconData get icon => Icons.mark_chat_unread_outlined;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionMarkAsUnread;
  }

  @override void onPressed(BuildContext context) async {
    Navigator.of(context).pop();
    markNarrowAsUnreadFromMessage(messageListContext, message, narrow);
  }
}

class CopyMessageTextButton extends MessageActionSheetMenuItemButton {
  CopyMessageTextButton({
    super.key,
    required super.message,
    required super.messageListContext,
  });

  @override IconData get icon => Icons.copy;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionCopyMessageText;
  }

  @override void onPressed(BuildContext context) async {
    // Close the message action sheet. We won't be showing request progress,
    // but hopefully it won't take long at all, and
    // fetchRawContentWithFeedback has a TODO for giving feedback if it does.
    Navigator.of(context).pop();
    final zulipLocalizations = ZulipLocalizations.of(messageListContext);

    final rawContent = await fetchRawContentWithFeedback(
      context: messageListContext,
      messageId: message.id,
      errorDialogTitle: zulipLocalizations.errorCopyingFailed,
    );

    if (rawContent == null) return;

    if (!messageListContext.mounted) return;

    copyWithPopup(context: messageListContext,
      successContent: Text(zulipLocalizations.successMessageTextCopied),
      data: ClipboardData(text: rawContent));
  }
}

class CopyMessageLinkButton extends MessageActionSheetMenuItemButton {
  CopyMessageLinkButton({
    super.key,
    required super.message,
    required super.messageListContext,
  });

  @override IconData get icon => Icons.link;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionCopyMessageLink;
  }

  @override void onPressed(BuildContext context) {
    Navigator.of(context).pop();
    final zulipLocalizations = ZulipLocalizations.of(messageListContext);

    final store = PerAccountStoreWidget.of(messageListContext);
    final messageLink = narrowLink(
      store,
      SendableNarrow.ofMessage(message, selfUserId: store.selfUserId),
      nearMessageId: message.id,
    );

    copyWithPopup(context: messageListContext,
      successContent: Text(zulipLocalizations.successMessageLinkCopied),
      data: ClipboardData(text: messageLink.toString()));
  }
}

class ShareButton extends MessageActionSheetMenuItemButton {
  ShareButton({
    super.key,
    required super.message,
    required super.messageListContext,
  });

  @override IconData get icon => Icons.adaptive.share;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionShare;
  }

  @override void onPressed(BuildContext context) async {
    // Close the message action sheet; we're about to show the share
    // sheet. (We could do this after the sharing Future settles
    // with [ShareResultStatus.success], but on iOS I get impatient with
    // how slowly our action sheet dismisses in that case.)
    // TODO(#24): Fix iOS bug where this call causes the keyboard to
    //   reopen (if it was open at the time of this
    //   `showMessageActionSheet` call) and cover a large part of the
    //   share sheet.
    Navigator.of(context).pop();
    final zulipLocalizations = ZulipLocalizations.of(messageListContext);

    final rawContent = await fetchRawContentWithFeedback(
      context: messageListContext,
      messageId: message.id,
      errorDialogTitle: zulipLocalizations.errorSharingFailed,
    );

    if (rawContent == null) return;

    if (!messageListContext.mounted) return;

    // TODO: to support iPads, we're asked to give a
    //   `sharePositionOrigin` param, or risk crashing / hanging:
    //     https://pub.dev/packages/share_plus#ipad
    //   Perhaps a wart in the API; discussion:
    //     https://github.com/zulip/zulip-flutter/pull/12#discussion_r1130146231
    final result = await Share.share(rawContent);

    switch (result.status) {
      // The plugin isn't very helpful: "The status can not be determined".
      // Until we learn otherwise, assume something wrong happened.
      case ShareResultStatus.unavailable:
        if (!messageListContext.mounted) return;
        await showErrorDialog(context: messageListContext,
          title: zulipLocalizations.errorSharingFailed);
      case ShareResultStatus.success:
      case ShareResultStatus.dismissed:
        // nothing to do
    }
  }
}
