import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../api/exception.dart';
import '../api/model/model.dart';
import '../api/route/messages.dart';
import 'compose_box.dart';
import 'dialog.dart';
import 'draggable_scrollable_modal_bottom_sheet.dart';
import 'message_list.dart';
import 'store.dart';

/// Show a sheet of actions you can take on a message in the message list.
///
/// Must have a [MessageListPage] ancestor.
void showMessageActionSheet({required BuildContext context, required Message message}) {
  // The UI that's conditioned on this won't live-update during this appearance
  // of the action sheet (we avoid calling composeBoxControllerOf in a build
  // method; see its doc). But currently it will be constant through the life of
  // any message list, so that's fine.
  final isComposeBoxOffered = MessageListPage.composeBoxControllerOf(context) != null;
  showDraggableScrollableModalBottomSheet(
    context: context,
    builder: (BuildContext _) {
      return Column(children: [
        ShareButton(message: message, messageListContext: context),
        if (isComposeBoxOffered) QuoteAndReplyButton(
          message: message,
          messageListContext: context,
        ),
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
  String get label;
  void Function(BuildContext) get onPressed;

  final Message message;
  final BuildContext messageListContext;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      leadingIcon: Icon(icon),
      onPressed: () => onPressed(context),
      child: Text(label));
  }
}

class ShareButton extends MessageActionSheetMenuItemButton {
  ShareButton({
    super.key,
    required super.message,
    required super.messageListContext,
  });

  @override get icon => Icons.adaptive.share;

  @override get label => 'Share';

  @override get onPressed => (BuildContext context) async {
    // Close the message action sheet; we're about to show the share
    // sheet. (We could do this after the sharing Future settles, but
    // on iOS I get impatient with how slowly our action sheet
    // dismisses in that case.)
    // TODO(#24): Fix iOS bug where this call causes the keyboard to
    //   reopen (if it was open at the time of this
    //   `showMessageActionSheet` call) and cover a large part of the
    //   share sheet.
    Navigator.of(context).pop();

    // TODO: to support iPads, we're asked to give a
    //   `sharePositionOrigin` param, or risk crashing / hanging:
    //     https://pub.dev/packages/share_plus#ipad
    //   Perhaps a wart in the API; discussion:
    //     https://github.com/zulip/zulip-flutter/pull/12#discussion_r1130146231
    // TODO: Share raw Markdown, not HTML
    await Share.shareWithResult(message.content);
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
    try {
      fetchedMessage = await getMessageCompat(PerAccountStoreWidget.of(context).connection,
        messageId: messageId,
        applyMarkdown: false,
      );
      if (fetchedMessage == null) {
        errorMessage = 'That message does not seem to exist.';
      }
    } catch (e) {
      switch (e) {
        case ZulipApiException():
          errorMessage = e.message;
        // TODO specific messages for common errors, like network errors
        //   (support with reusable code)
        default:
          errorMessage = 'Could not fetch message source.';
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

  @override get label => 'Quote and reply';

  @override get onPressed => (BuildContext bottomSheetContext) async {
    // Close the message action sheet. We'll show the request progress
    // in the compose-box content input with a "[Quoting…]" placeholder.
    Navigator.of(bottomSheetContext).pop();

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
      errorDialogTitle: 'Quotation failed',
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
