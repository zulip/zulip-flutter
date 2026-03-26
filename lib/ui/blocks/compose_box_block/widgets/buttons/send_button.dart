import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../api/exception.dart';
import '../../../../../api/route/messages.dart';
import '../../../../../generated/l10n/zulip_localizations.dart';
import '../../../../../get/services/store_service.dart';
import '../../../../values/constants.dart';
import '../../../../extensions/color.dart';
import '../../compose_box.dart';
import '../../../../widgets/dialog.dart';
import '../../../../values/icons.dart';
import '../../../message_list_block/message_list_block.dart';
import '../../../../values/theme.dart';

class SendButton extends StatefulWidget {
  const SendButton({
    super.key,
    required this.controller,
    required this.getDestination,
  });

  final ComposeBoxController controller;
  final MessageDestination Function() getDestination;

  @override
  State<SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<SendButton> {
  Worker? _topicWorker;
  Worker? _contentWorker;

  void _hasErrorsChanged() {
    setState(() {
      // Update disabled/non-disabled state
    });
  }

  @override
  void initState() {
    super.initState();
    final controller = widget.controller;
    if (controller is StreamComposeBoxController) {
      _topicWorker = ever(
        controller.topic.hasValidationErrors,
        (_) => _hasErrorsChanged(),
      );
    }
    _contentWorker = ever(
      controller.content.hasValidationErrors,
      (_) => _hasErrorsChanged(),
    );
  }

  @override
  void didUpdateWidget(covariant SendButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    final controller = widget.controller;
    final oldController = oldWidget.controller;
    if (controller == oldController) return;

    if (oldController is StreamComposeBoxController) {
      _topicWorker?.dispose();
    }
    if (controller is StreamComposeBoxController) {
      _topicWorker = ever(
        controller.topic.hasValidationErrors,
        (_) => _hasErrorsChanged(),
      );
    }
    _contentWorker?.dispose();
    _contentWorker = ever(
      controller.content.hasValidationErrors,
      (_) => _hasErrorsChanged(),
    );
  }

  @override
  void dispose() {
    _topicWorker?.dispose();
    _contentWorker?.dispose();
    super.dispose();
  }

  bool get _hasValidationErrors {
    bool result = false;
    final controller = widget.controller;
    if (controller is StreamComposeBoxController) {
      result = controller.topic.hasValidationErrors.value;
    }
    result |= controller.content.hasValidationErrors.value;
    return result;
  }

  void _send() async {
    final controller = widget.controller;

    if (_hasValidationErrors) {
      final zulipLocalizations = ZulipLocalizations.of(context);
      final store = requirePerAccountStore();
      List<String> validationErrorMessages = [
        for (final error
            in (controller is StreamComposeBoxController
                ? controller.topic.validationErrors
                : const <TopicValidationError>[]))
          error.message(zulipLocalizations, maxLength: store.maxTopicLength),
        for (final error in controller.content.validationErrors)
          error.message(zulipLocalizations),
      ];
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorMessageNotSent,
        message: validationErrorMessages.join('\n\n'),
      );
      return;
    }

    final destination = widget.getDestination();
    final content = controller.content.textNormalized;

    controller.content.clear();

    try {
      final store = requirePerAccountStore();
      await store.sendMessage(destination: destination, content: content);
      if (!mounted) return;
    } on ApiRequestException catch (e) {
      if (!mounted) return;
      final zulipLocalizations = ZulipLocalizations.of(context);
      final message = switch (e) {
        ZulipApiException() => zulipLocalizations.errorServerMessage(e.message),
        _ => e.message,
      };
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorMessageNotSent,
        message: message,
      );
      return;
    }

    final store = requirePerAccountStore();
    if (destination is StreamDestination &&
        store.subscriptions[destination.streamId] == null) {
      // The message was sent to an unsubscribed channel.
      // We don't get new-message events for unsubscribed channels,
      // but we can refresh the view when a send-message request succeeds,
      // so the user will at least see their own messages without having to
      // exit and re-enter. See the "first buggy behavior" in
      //   https://github.com/zulip/zulip-flutter/issues/1798 .
      MessageListBlockPage.ancestorOf(context).refresh(AnchorCode.newest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final iconColor = _hasValidationErrors
        ? designVariables.icon.withFadedAlpha(0.5)
        : designVariables.icon;

    return SizedBox(
      width: composeButtonSize,
      child: IconButton(
        tooltip: zulipLocalizations.composeBoxSendTooltip,
        icon: Icon(ZulipIcons.send, color: iconColor),
        onPressed: _send,
      ),
    );
  }
}
