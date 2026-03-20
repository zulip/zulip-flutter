import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../../api/model/model.dart';
import '../../../../../../generated/l10n/zulip_localizations.dart';
import '../../../../../../model/message_list.dart';
import '../../../../../../model/narrow.dart';
import '../../../../../action_sheet.dart';
import '../../../../../button.dart';
import '../../../../../content.dart';
import '../../../../../emoji_reaction.dart';
import '../../../../../icons.dart';
import '../../../../../message_list.dart';
import '../../../../../store.dart';
import '../../../../../text.dart';
import '../../../../../theme.dart';
import '../../../../message_list_block.dart';
import '../../../sender_row.dart';
import 'edit_message_status_row.dart';
import 'restore_edit_message_gesture_detector.dart';

/// A Zulip message, showing the sender's name and avatar if specified.
// Design referenced from:
//   - https://github.com/zulip/zulip-mobile/issues/5511
//   - https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=538%3A20849&mode=dev
class MessageWithPossibleSender extends StatelessWidget {
  const MessageWithPossibleSender({
    super.key,
    required this.narrow,
    required this.item,
  });

  final Narrow narrow;
  final MessageListMessageItem item;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);
    final message = item.message;

    final zulipLocalizations = ZulipLocalizations.of(context);
    String? editStateText;
    switch (message.editState) {
      case MessageEditState.edited:
        editStateText = zulipLocalizations.messageIsEditedLabel;
      case MessageEditState.moved:
        editStateText = zulipLocalizations.messageIsMovedLabel;
      case MessageEditState.none:
    }

    Widget? star;
    if (message.flags.contains(MessageFlag.starred)) {
      final starOffset = switch (Directionality.of(context)) {
        TextDirection.ltr => -2.0,
        TextDirection.rtl => 2.0,
      };
      star = Transform.translate(
        offset: Offset(starOffset, 0),
        child: Icon(
          ZulipIcons.star_filled,
          size: 16,
          color: designVariables.star,
        ),
      );
    }

    Widget content = MessageContent(message: message, content: item.content);

    final editMessageErrorStatus = store.getEditMessageErrorStatus(message.id);
    if (editMessageErrorStatus != null) {
      // The Figma also fades the sender row:
      //   https://github.com/zulip/zulip-flutter/pull/1498#discussion_r2076574000
      // We've decided to just fade the message content because that's the only
      // thing that's changing.
      content = Opacity(opacity: 0.6, child: content);
      if (!editMessageErrorStatus) {
        // IgnorePointer neutralizes interactable message content like links;
        // this seemed appropriate along with the faded appearance.
        content = IgnorePointer(child: content);
      } else {
        content = RestoreEditMessageGestureDetector(
          messageId: message.id,
          child: content,
        );
      }
    }

    final tapOpensConversation = switch (narrow) {
      CombinedFeedNarrow() ||
      ChannelNarrow() ||
      TopicNarrow() ||
      DmNarrow() => false,
      MentionsNarrow() ||
      StarredMessagesNarrow() ||
      KeywordSearchNarrow() => true,
    };

    final showAsMuted =
        store.isUserMuted(message.senderId) &&
        !MessageListBlockPage.maybeRevealedMutedMessagesOf(
          context,
        )!.isMutedMessageRevealed(message.id);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: tapOpensConversation
          ? () => unawaited(
              Navigator.push(
                context,
                MessageListBlockPage.buildRoute(
                  context: context,
                  narrow: SendableNarrow.ofMessage(
                    message,
                    selfUserId: store.selfUserId,
                  ),
                  // TODO(#1655) "this view does not mark messages as read on scroll"
                  initAnchorMessageId: message.id,
                ),
              ),
            )
          : null,
      onLongPress: showAsMuted
          ? null // TODO write a test for this
          : () => showMessageActionSheet(context: context, message: message),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          children: [
            if (item.showSender)
              SenderRow(
                message: message,
                timestampStyle: MessageTimestampStyle.timeOnly,
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: localizedTextBaseline(context),
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: showAsMuted
                      ? Align(
                          alignment: AlignmentDirectional.topStart,
                          child: ZulipWebUiKitButton(
                            label: zulipLocalizations.revealButtonLabel,
                            icon: ZulipIcons.eye,
                            size: ZulipWebUiKitButtonSize.small,
                            intent: ZulipWebUiKitButtonIntent.neutral,
                            attention: ZulipWebUiKitButtonAttention.minimal,
                            onPressed: () {
                              MessageListBlockPage.ancestorOf(
                                context,
                              ).revealMutedMessage(message.id);
                            },
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            content,
                            if ((message.reactions?.total ?? 0) > 0)
                              ReactionChipsList(
                                messageId: message.id,
                                reactions: message.reactions!,
                              ),
                            if (editMessageErrorStatus != null)
                              EditMessageStatusRow(
                                messageId: message.id,
                                status: editMessageErrorStatus,
                              )
                            else if (editStateText != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  editStateText,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: designVariables.labelEdited,
                                    fontSize: 12,
                                    height: (12 / 12),
                                    letterSpacing: proportionalLetterSpacing(
                                      context,
                                      0.05,
                                      baseFontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                              ),
                          ],
                        ),
                ),
                SizedBox(width: 16, child: star),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
