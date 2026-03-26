import 'package:flutter/material.dart' hide Banner;
import 'package:flutter/scheduler.dart';

import '../../../api/model/model.dart';
import '../../../generated/l10n/zulip_localizations.dart';
import '../../../get/services/store_service.dart';
import '../../../model/narrow.dart';
import '../../../model/store.dart';
import '../../utils/actions.dart';
import 'compose_box.dart';
import '../../widgets/dialog.dart';
import '../../utils/store.dart';
import 'compose_box_container.dart';
import 'widgets/banner.dart';
import 'widgets/banner_trailings/edit_message_banner_trailing.dart';
import 'widgets/banner_trailings/unsubscribed_channel_banner_trailing.dart';
import 'widgets/box_body/edit_message_compose_box_body.dart';
import 'widgets/box_body/fixed_destination_compose_box_body.dart';
import 'widgets/box_body/stream_compose_box_body.dart';

/// The compose box.
///
/// Takes the full screen width, covering the horizontal insets with its surface.
/// Also covers the bottom inset with its surface.
class ComposeBoxBlock extends StatefulWidget {
  ComposeBoxBlock({super.key, required this.narrow})
    : assert(ComposeBoxBlock.hasComposeBox(narrow));

  final Narrow narrow;

  static bool hasComposeBox(Narrow narrow) {
    switch (narrow) {
      case ChannelNarrow():
      case TopicNarrow():
      case DmNarrow():
        return true;

      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
      case KeywordSearchNarrow():
        return false;
    }
  }

  @override
  State<ComposeBoxBlock> createState() => ComposeBoxState();
}

/// The interface for the state of a [ComposeBox].
abstract class ComposeBoxBlockState extends State<ComposeBoxBlock> {
  ComposeBoxController get controller;

  /// Fills the compose box with the content of an [OutboxMessage]
  /// for a failed [sendMessage] request.
  ///
  /// If there is already text in the compose box, gives a confirmation dialog
  /// to confirm that it is OK to discard that text.
  ///
  /// [localMessageId], as in [OutboxMessage.localMessageId], must be present
  /// in the message store.
  void restoreMessageNotSent(int localMessageId);

  /// Switch the compose box to editing mode.
  ///
  /// If there is already text in the compose box, gives a confirmation dialog
  /// to confirm that it is OK to discard that text.
  ///
  /// If called from the message action sheet, fetches the raw message content
  /// to fill in the edit-message compose box.
  ///
  /// If called by tapping a message in the message list with 'EDIT NOT SAVED',
  /// fills the edit-message compose box with the content the user wanted
  /// in the edit request that failed.
  void startEditInteraction(int messageId);

  /// Switch the compose box back to regular non-edit mode, with no content.
  void endEditInteraction();
}

class ComposeBoxState extends State<ComposeBoxBlock>
    with PerAccountStoreAwareStateMixin<ComposeBoxBlock>
    implements ComposeBoxBlockState {
  @override
  ComposeBoxController get controller => _controller!;
  ComposeBoxController? _controller;

  static ComposeBoxState ancestorOf(BuildContext context) {
    final state = context.findAncestorStateOfType<ComposeBoxState>();
    assert(state != null, 'No ComposeBoxBlockState ancestor');
    return state!;
  }

  @override
  void restoreMessageNotSent(int localMessageId) async {
    final zulipLocalizations = ZulipLocalizations.of(context);

    final abort = await _abortBecauseContentInputNotEmpty(
      dialogMessage:
          zulipLocalizations.discardDraftForOutboxConfirmationDialogMessage,
    );
    if (abort || !mounted) return;

    final store = requirePerAccountStore();
    final outboxMessage = store.takeOutboxMessage(localMessageId);
    setState(() {
      _setNewController(store);
      final controller = this.controller;
      controller
        ..content.value = TextEditingValue(text: outboxMessage.contentMarkdown)
        ..contentFocusNode.requestFocus();
      if (controller is StreamComposeBoxController) {
        controller.topic.setTopic(
          (outboxMessage.conversation as StreamConversation).topic,
        );
      }
    });
  }

  @override
  void startEditInteraction(int messageId) async {
    final zulipLocalizations = ZulipLocalizations.of(context);

    final abort = await _abortBecauseContentInputNotEmpty(
      dialogMessage:
          zulipLocalizations.discardDraftForEditConfirmationDialogMessage,
    );
    if (abort || !mounted) return;

    final store = requirePerAccountStore();

    switch (store.getEditMessageErrorStatus(messageId)) {
      case null:
        _editFromRawContentFetch(messageId);
      case true:
        _editByRestoringFailedEdit(messageId);
      case false:
        // This can happen if you start an edit interaction on one
        // MessageListPage and then do an edit on a different MessageListPage,
        // and the second edit is still saving when you return to the first.
        //
        // Abort rather than sending a request with a prevContentSha256
        // that the server might not accept, and don't clear the compose
        // box, so the user can try again after the request settles.
        // TODO could write a test for this
        showErrorDialog(
          context: context,
          title: zulipLocalizations.editAlreadyInProgressTitle,
          message: zulipLocalizations.editAlreadyInProgressMessage,
        );
        return;
    }
  }

  /// If there's text in the compose box, give a confirmation dialog
  /// asking if it can be discarded and await the result.
  Future<bool> _abortBecauseContentInputNotEmpty({
    required String dialogMessage,
  }) async {
    final zulipLocalizations = ZulipLocalizations.of(context);
    if (controller.content.textNormalized.isNotEmpty) {
      final dialog = showSuggestedActionDialog(
        context: context,
        title: zulipLocalizations.discardDraftConfirmationDialogTitle,
        message: dialogMessage,
        destructiveActionButton: true,
        actionButtonText:
            zulipLocalizations.discardDraftConfirmationDialogConfirmButton,
      );
      if (await dialog.result != true) return true;
    }
    return false;
  }

  void _editByRestoringFailedEdit(int messageId) {
    final store = requirePerAccountStore();
    // Fill the content input with the content the user wanted in the failed
    // edit attempt, not the original content.
    // Side effect: Clears the "EDIT NOT SAVED" text in the message list.
    final failedEdit = store.takeFailedMessageEdit(messageId);
    setState(() {
      controller.dispose();
      _controller = EditMessageComposeBoxController(
        store: store,
        messageId: messageId,
        originalRawContent: failedEdit.originalRawContent,
        initialText: failedEdit.newContent,
      )..contentFocusNode.requestFocus();
    });
  }

  void _editFromRawContentFetch(int messageId) async {
    final store = requirePerAccountStore();
    final zulipLocalizations = ZulipLocalizations.of(context);
    final emptyEditController = EditMessageComposeBoxController.empty(
      store,
      messageId,
    );
    setState(() {
      controller.dispose();
      _controller = emptyEditController;
    });
    final fetchedRawContent = await ZulipAction.fetchRawContentWithFeedback(
      context: context,
      messageId: messageId,
      errorDialogTitle: zulipLocalizations.errorCouldNotEditMessageTitle,
    );
    // TODO timeout this request?
    if (!mounted) return;
    if (!identical(controller, emptyEditController)) {
      // During the fetch-raw-content request, the user tapped Cancel
      // or tapped a failed message edit or failed outbox message to restore.
      // TODO in this case we don't want the error dialog caused by
      //   ZulipAction.fetchRawContentWithFeedback; suppress that
      return;
    }
    if (fetchedRawContent == null) {
      // Fetch-raw-content failed; abort the edit session.
      // An error dialog was already shown, by fetchRawContentWithFeedback.
      setState(() {
        _setNewController(requirePerAccountStore());
      });
      return;
    }
    // TODO scroll message list to ensure the message is still in view;
    //   highlight it?
    assert(controller is EditMessageComposeBoxController);
    final editMessageController = controller as EditMessageComposeBoxController;
    setState(() {
      // setState to refresh the input, upload buttons, etc.
      // out of the disabled "Preparing…" state.
      editMessageController.originalRawContent = fetchedRawContent;
    });
    editMessageController.content.value = TextEditingValue(
      text: fetchedRawContent,
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // post-frame callback so this happens after the input is enabled
      editMessageController.contentFocusNode.requestFocus();
    });
  }

  @override
  void endEditInteraction() {
    assert(controller is EditMessageComposeBoxController);
    if (controller is! EditMessageComposeBoxController) return; // TODO(log)

    final store = requirePerAccountStore();
    setState(() {
      _setNewController(store);
    });
  }

  @override
  void onNewStore() {
    final newStore = requirePerAccountStore();

    final controller = _controller;
    if (controller == null) {
      _setNewController(newStore);
      return;
    }

    switch (controller) {
      case StreamComposeBoxController():
        controller.content.store = newStore;
        controller.topic.store = newStore;
      case FixedDestinationComposeBoxController():
      case EditMessageComposeBoxController():
        controller.content.store = newStore;
    }
  }

  void _setNewController(PerAccountStore store) {
    _controller?.dispose(); // `?.` because this might be the first call
    switch (widget.narrow) {
      case ChannelNarrow():
        _controller = StreamComposeBoxController(store: store);
      case TopicNarrow():
      case DmNarrow():
        _controller = FixedDestinationComposeBoxController(store: store);
      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
      case KeywordSearchNarrow():
        assert(false);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// A [_Banner] that replaces the compose box's text inputs.
  Widget? _bannerComposingNotAllowed(BuildContext context) {
    final store = requirePerAccountStore();
    final zulipLocalizations = ZulipLocalizations.of(context);
    switch (widget.narrow) {
      case ChannelNarrow(:final streamId):
      case TopicNarrow(:final streamId):
        final channel = store.streams[streamId];
        if (channel == null || !store.selfHasContentAccess(channel)) {
          return Banner(
            intent: BannerIntent.info,
            // This message is redundant with a message-list placeholder
            // we'll show following a doomed-empty message fetch (from #1947):
            // "This channel doesn’t exist, or you are not allowed to view it."
            // Or: "You don’t have content access to this channel."
            // TODO(#2085) Actually, I tried reproducing the case where a channel
            //   doesn't exist, with a very high number for the channel ID,
            //   and got an infinite loading spinner instead; we should fix that.
            // TODO So, support replacing the compose box with nothing,
            //   not even a banner, in narrows that can offer a compose box.
            //   (We'll need to handle the bottom device inset carefully.)
            label: zulipLocalizations
                .composeBoxBannerLabelCannotSendUnspecifiedReason,
          );
        }

        if (!store.selfCanSendMessage(
          inChannel: channel,
          byDate: DateTime.now(),
        )) {
          return (channel is Subscription)
              ? Banner(
                  intent: BannerIntent.info,
                  label: zulipLocalizations
                      .composeBoxBannerLabelCannotSendInChannel,
                )
              : Banner(
                  intent: BannerIntent.warning,
                  label: zulipLocalizations
                      .composeBoxBannerLabelUnsubscribedWhenCannotSend,
                  useSmallerText: true,
                  trailing: UnsubscribedChannelBannerTrailing(
                    channelId: streamId,
                  ),
                );
        }

      case DmNarrow(:final otherRecipientIds):
        final hasDeactivatedUser = otherRecipientIds.any(
          (id) => !(store.getUser(id)?.isActive ?? true),
        );
        if (hasDeactivatedUser) {
          return Banner(
            intent: BannerIntent.info,
            label:
                zulipLocalizations.composeBoxBannerLabelDeactivatedDmRecipient,
          );
        }
        final hasUnknownUser = otherRecipientIds.any(
          (id) => store.getUser(id) == null,
        );
        if (hasUnknownUser) {
          return Banner(
            intent: BannerIntent.info,
            label: zulipLocalizations.composeBoxBannerLabelUnknownDmRecipient,
          );
        }

      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
      case KeywordSearchNarrow():
        return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final store = requirePerAccountStore();
    final zulipLocalizations = ZulipLocalizations.of(context);

    final bannerComposingNotAllowed = _bannerComposingNotAllowed(context);
    if (bannerComposingNotAllowed != null) {
      return ComposeBoxInheritedWidget.fromComposeBoxState(
        this,
        child: ComposeBoxContainer(
          body: null,
          banner: bannerComposingNotAllowed,
        ),
      );
    }

    final Widget? body;
    Widget? banner;

    final narrow = widget.narrow;
    switch (narrow) {
      case ChannelNarrow(:final streamId):
      case TopicNarrow(:final streamId):
        final channel = store.streams[streamId];
        // (If the channel is unknown, we should have already decided
        // what to show.)
        assert(channel != null);
        final subscription = store.subscriptions[streamId];
        if (channel != null && subscription == null) {
          banner = Banner(
            intent: BannerIntent.warning,
            label: zulipLocalizations.composeBoxBannerLabelUnsubscribed,
            useSmallerText: true,
            trailing: UnsubscribedChannelBannerTrailing(channelId: streamId),
          );
        }

      case DmNarrow():
      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
      case KeywordSearchNarrow():
    }

    final controller = this.controller;
    switch (controller) {
      case StreamComposeBoxController():
        {
          narrow as ChannelNarrow;
          body = StreamComposeBoxBody(controller: controller, narrow: narrow);
        }
      case FixedDestinationComposeBoxController():
        {
          narrow as SendableNarrow;
          body = FixedDestinationComposeBoxBody(
            controller: controller,
            narrow: narrow,
          );
        }
      case EditMessageComposeBoxController():
        {
          body = EditMessageComposeBoxBody(
            controller: controller,
            narrow: narrow,
          );
          banner = Banner(
            intent: BannerIntent.info,
            label: zulipLocalizations.composeBoxBannerLabelEditMessage,
            trailing: EditMessageBannerTrailing(composeBoxState: this),
          );
        }
    }

    return ComposeBoxInheritedWidget.fromComposeBoxState(
      this,
      child: ComposeBoxContainer(body: body, banner: banner),
    );
  }
}
