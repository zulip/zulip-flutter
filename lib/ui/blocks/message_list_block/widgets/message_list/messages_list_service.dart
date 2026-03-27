import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../../api/model/model.dart';
import '../../../../../generated/l10n/zulip_localizations.dart';
import '../../../../../get/services/store_service.dart';
import '../../../../../model/binding.dart';
import '../../../../../model/internal_link.dart';
import '../../../../../model/message_list.dart';
import '../../../../../model/narrow.dart';
import '../../../../utils/actions.dart';
import '../../../compose_box_block/compose_box.dart';
import '../../message_list_block.dart';

class MessagesListService {
  static late BuildContext pageContext;
  static Future<void> answerMessage(
    MessageListMessageItem item,
  ) async {
    final zulipLocalizations = ZulipLocalizations.of(pageContext);
    final message = item.message;

    var composeBoxController = MessageListBlockPage.ancestorOf(
      pageContext,
    ).composeBoxState?.controller;
    // The compose box doesn't null out its controller; it's either always null
    // (e.g. in Combined Feed) or always non-null; it can't have been nulled out
    // after the action sheet opened.
    composeBoxController!;
    if (composeBoxController is StreamComposeBoxController &&
        composeBoxController.topic.isTopicVacuous &&
        message is StreamMessage) {
      composeBoxController.topic.setTopic(message.topic);
    }

    // This inserts a "[Quoting…]" placeholder into the content input,
    // giving the user a form of progress feedback.
    final tag = composeBoxController.content.registerQuoteAndReplyStart(
      zulipLocalizations,
      requirePerAccountStore(),
      message: message,
    );

    final rawContent = await ZulipAction.fetchRawContentWithFeedback(
      context: pageContext,
      messageId: message.id,
      errorDialogTitle: zulipLocalizations.errorQuotationFailed,
    );

    if (!pageContext.mounted) return;

    composeBoxController = MessageListBlockPage.ancestorOf(
      pageContext,
    ).composeBoxState?.controller;
    // The compose box doesn't null out its controller; it's either always null
    // (e.g. in Combined Feed) or always non-null; it can't have been nulled out
    // during the raw-content request.
    composeBoxController!.content.registerQuoteAndReplyEnd(
      requirePerAccountStore(),
      tag,
      message: message,
      rawContent: rawContent,
    );
    if (!composeBoxController.contentFocusNode.hasFocus) {
      composeBoxController.contentFocusNode.requestFocus();
    }
  }

  static Future<void> copyMessage(
    MessageListMessageItem item,
  ) async {
    final zulipLocalizations = ZulipLocalizations.of(pageContext);
    final message = item.message;

    final rawContent = await ZulipAction.fetchRawContentWithFeedback(
      context: pageContext,
      messageId: message.id,
      errorDialogTitle: zulipLocalizations.errorCopyingFailed,
    );

    if (rawContent == null) return;

    if (!pageContext.mounted) return;

    PlatformActions.copyWithPopup(
      context: pageContext,
      successContent: Text(zulipLocalizations.successMessageTextCopied),
      data: ClipboardData(text: rawContent),
    );
  }

  static Future<void> copyMessageLink(
    MessageListMessageItem item,
  ) async {
    final zulipLocalizations = ZulipLocalizations.of(pageContext);
    final message = item.message;

    final store = requirePerAccountStore();
    final messageLink = narrowLink(
      store,
      SendableNarrow.ofMessage(message, selfUserId: store.selfUserId),
      nearMessageId: message.id,
    );

    PlatformActions.copyWithPopup(
      context: pageContext,
      successContent: Text(zulipLocalizations.successMessageLinkCopied),
      data: ClipboardData(text: messageLink.toString()),
    );
  }

  static Future<void> editMessage(
    MessageListMessageItem item,
  ) async {
    final message = item.message;
    final composeBoxState = MessageListBlockPage.ancestorOf(
      pageContext,
    ).composeBoxState;
    if (composeBoxState == null) {
      throw StateError(
        'Compose box unexpectedly absent when edit-message button pressed',
      );
    }
    composeBoxState.startEditInteraction(message.id);
  }

  static bool getShouldShowEditButton(
    MessageListMessageItem item,
  ) {
    final message = item.message;
    final store = requirePerAccountStore();

    final messageListPage = MessageListBlockPage.ancestorOf(pageContext);
    final composeBoxState = messageListPage.composeBoxState;
    final isComposeBoxOffered = composeBoxState != null;
    final composeBoxController = composeBoxState?.controller;

    final editMessageErrorStatus = store.getEditMessageErrorStatus(message.id);
    final editMessageInProgress =
        // The compose box is in edit-message mode, with Cancel/Save instead of Send.
        composeBoxController is EditMessageComposeBoxController
        // An edit request is in progress or the error state.
        ||
        editMessageErrorStatus != null;

    final now = ZulipBinding.instance.utcNow().millisecondsSinceEpoch ~/ 1000;
    final editLimit = store.realmMessageContentEditLimitSeconds;
    final outsideEditLimit =
        editLimit != null && now - message.timestamp > editLimit;

    return message.senderId == store.selfUserId &&
        isComposeBoxOffered &&
        store.realmAllowMessageEditing &&
        !outsideEditLimit &&
        !editMessageInProgress &&
        message.poll == null; // messages with polls cannot be edited
  }
}
