import 'package:flutter/material.dart';

import '../../../../api/exception.dart';
import '../../../../api/model/model.dart';
import '../../../../api/route/messages.dart';
import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../button.dart';
import '../../../compose_box.dart';
import '../../../dialog.dart';
import '../../../message_list_block/message_list_block.dart';
import '../../../page.dart';
import '../../../store.dart';
import '../../compose_box_block.dart';

class EditMessageBannerTrailing extends StatelessWidget {
  const EditMessageBannerTrailing({super.key, required this.composeBoxState});

  final ComposeBoxBlockState composeBoxState;

  void _handleTapSave(BuildContext context) async {
    // (A BuildContext that's expected to remain mounted until the whole page
    // disappears, which may be long after the banner disappears.)
    final pageContext = PageRoot.contextOf(context);

    final controller = composeBoxState.controller;
    if (controller is! EditMessageComposeBoxController) return; // TODO(log)
    final zulipLocalizations = ZulipLocalizations.of(pageContext);

    if (controller.content.hasValidationErrors.value) {
      final validationErrorMessages = controller.content.validationErrors.map(
        (error) => error.message(zulipLocalizations),
      );
      showErrorDialog(
        context: pageContext,
        title: zulipLocalizations.errorMessageEditNotSaved,
        message: validationErrorMessages.join('\n\n'),
      );
      return;
    }

    final originalRawContent = controller.originalRawContent;
    if (originalRawContent == null) {
      // Fetch-raw-content request hasn't finished; try again later.
      // TODO show error dialog?
      return;
    }

    final messageId = controller.messageId;
    final newContent = controller.content.textNormalized;
    composeBoxState.endEditInteraction();

    try {
      final store = PerAccountStoreWidget.of(pageContext);
      await store.editMessage(
        messageId: messageId,
        originalRawContent: originalRawContent,
        newContent: newContent,
      );
      if (!pageContext.mounted) return;
    } on ApiRequestException catch (e) {
      if (!pageContext.mounted) return;
      final zulipLocalizations = ZulipLocalizations.of(pageContext);
      final message = switch (e) {
        ZulipApiException() => zulipLocalizations.errorServerMessage(e.message),
        _ => e.message,
      };
      showErrorDialog(
        context: pageContext,
        title: zulipLocalizations.errorMessageEditNotSaved,
        message: message,
      );
      return;
    }

    final store = PerAccountStoreWidget.of(pageContext);
    final messageListPageState = MessageListBlockPage.ancestorOf(pageContext);
    final narrow = messageListPageState.narrow;
    final message = store.messages[messageId];
    if (message !=
            null // (the message wasn't deleted during the edit request)
            &&
        narrow.containsMessage(message) ==
            true // (or moved out of the view)
            &&
        message is StreamMessage &&
        store.subscriptions[message.conversation.streamId] == null) {
      // The message is in an unsubscribed channel.
      // We don't get edit-message events for unsubscribed channels,
      // but we can refresh the view when an edit-message request succeeds,
      // so the user will at least see their updated message without having to
      // exit and re-enter. See the "first buggy behavior" in
      //   https://github.com/zulip/zulip-flutter/issues/1798 .
      messageListPageState.refresh(NumericAnchor(messageId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        ZulipWebUiKitButton(
          label: zulipLocalizations.composeBoxBannerButtonCancel,
          onPressed: composeBoxState.endEditInteraction,
        ),
        // TODO(#1481) disabled appearance when there are validation errors
        //   or the original raw content hasn't loaded yet
        ZulipWebUiKitButton(
          label: zulipLocalizations.composeBoxBannerButtonSave,
          attention: ZulipWebUiKitButtonAttention.high,
          onPressed: () => _handleTapSave(context),
        ),
      ],
    );
  }
}
