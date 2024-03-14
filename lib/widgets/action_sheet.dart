import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../api/exception.dart';
import '../api/model/model.dart';
import '../api/route/messages.dart';
import '../emoji.dart';
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
  final isComposeBoxOffered = MessageListPage.composeBoxControllerOf(context) != null;

  // TODO filter away reactions by current user
  // final hasThumbsUpReactionVote = message.reactions
  //   ?.aggregated.any((reactionWithVotes) =>
  //     reactionWithVotes.reactionType == ReactionType.unicodeEmoji
  //     && reactionWithVotes.emojiCode == '1f44d'
  //     && reactionWithVotes.userIds.contains(store.selfUserId))
  //   ?? false;

  showDraggableScrollableModalBottomSheet(
    context: context,
    builder: (BuildContext _) {
      return Column(children: [
        AddReactionButton(message: message, messageListContext: context),
        StarButton(message: message, messageListContext: context),
        ShareButton(message: message, messageListContext: context),
        if (isComposeBoxOffered) QuoteAndReplyButton(
          message: message,
          messageListContext: context,
        ),
        CopyButton(message: message, messageListContext: context),
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
  void Function(BuildContext) get onPressed;

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

class AddReactionButton extends MessageActionSheetMenuItemButton {
  AddReactionButton({
    super.key,
    required super.message,
    required super.messageListContext,
  });

  @override get icon => Icons.add_reaction_outlined;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return 'Add reaction'; // TODO(i18n) skip translation for now
  }

  @override get onPressed => (BuildContext context) async {
    // dismiss action sheet
    Navigator.of(context).pop();

    await showModalBottomSheet(
      context: context,
      clipBehavior: Clip.hardEdge,
      builder: (BuildContext emojiPickerContext) {
        return Padding(
          // apply bottom padding to handle keyboard opening via https://github.com/flutter/flutter/issues/71418
          padding: EdgeInsets.only(bottom: MediaQuery.of(emojiPickerContext).viewInsets.bottom),
          child: EmojiPicker(
          config: Config(emojiSet: emojiSet),
          onEmojiSelected: (_, Emoji? emoji) async {
            if (emoji == null) {
              // dismiss emoji picker
              Navigator.of(emojiPickerContext).pop();
              return;
            }
            final emojiName = emoji.name;
            final emojiCode = getEmojiCode(emoji);
            String? errorMessage;
            try {
              await addReaction(PerAccountStoreWidget.of(messageListContext).connection,
                messageId: message.id,
                reactionType: ReactionType.unicodeEmoji,
                emojiCode: emojiCode,
                emojiName: emojiName,
              );
              if (!emojiPickerContext.mounted) return;
              Navigator.of(emojiPickerContext).pop();
            } catch (e) {
              debugPrint('Error adding reaction: $e');
              if (!emojiPickerContext.mounted) return;

              switch (e) {
                case ZulipApiException():
                  errorMessage = e.message;
                  // TODO specific messages for common errors, like network errors
                  //   (support with reusable code)
                default:
              }

              await showErrorDialog(context: emojiPickerContext,
                title: 'Adding reaction failed', message: errorMessage);
            }
          }));
      });
  };
}

class StarButton extends MessageActionSheetMenuItemButton {
  StarButton({
    super.key,
    required super.message,
    required super.messageListContext,
  });

  @override get icon => ZulipIcons.star_filled;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return message.flags.contains(MessageFlag.starred)
      ? zulipLocalizations.actionSheetOptionUnstarMessage
      : zulipLocalizations.actionSheetOptionStarMessage;
  }

  @override get onPressed => (BuildContext context) async {
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
  };
}

class ShareButton extends MessageActionSheetMenuItemButton {
  ShareButton({
    super.key,
    required super.message,
    required super.messageListContext,
  });

  @override get icon => Icons.adaptive.share;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionShare;
  }

  @override get onPressed => (BuildContext context) async {
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
    final result = await Share.shareWithResult(rawContent);

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
  };
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

  @override get icon => Icons.format_quote_outlined;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionQuoteAndReply;
  }

  @override get onPressed => (BuildContext bottomSheetContext) async {
    // Close the message action sheet. We'll show the request progress
    // in the compose-box content input with a "[Quoting…]" placeholder.
    Navigator.of(bottomSheetContext).pop();
    final zulipLocalizations = ZulipLocalizations.of(messageListContext);

    // This will be null only if the compose box disappeared after the
    // message action sheet opened, and before "Quote and reply" was pressed.
    // Currently a compose box can't ever disappear, so this is impossible.
    ComposeBoxController composeBoxController =
      MessageListPage.composeBoxControllerOf(messageListContext)!;
    final topicController = composeBoxController.topicController;
    if (
      topicController != null
      && topicController.textNormalized == kNoTopicTopic
      && message is StreamMessage
    ) {
      topicController.value = TextEditingValue(text: message.subject);
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
    composeBoxController = MessageListPage.composeBoxControllerOf(messageListContext)!;
    composeBoxController.contentController
      .registerQuoteAndReplyEnd(PerAccountStoreWidget.of(messageListContext), tag,
        message: message,
        rawContent: rawContent,
      );
    if (!composeBoxController.contentFocusNode.hasFocus) {
      composeBoxController.contentFocusNode.requestFocus();
    }
  };
}

class CopyButton extends MessageActionSheetMenuItemButton {
  CopyButton({
    super.key,
    required super.message,
    required super.messageListContext,
  });

  @override get icon => Icons.copy;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionCopy;
  }

  @override get onPressed => (BuildContext context) async {
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

    copyWithPopup(context: context,
      successContent: Text(zulipLocalizations.successMessageCopied),
      data: ClipboardData(text: rawContent));
  };
}
