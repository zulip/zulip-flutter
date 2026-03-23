import 'package:flutter/material.dart';

import '../../../../../../model/message.dart';
import '../../../../../../model/message_list.dart';
import '../../../../../content_block/content.dart';
import '../../../../message_list.dart';
import '../../../sender_row.dart';
import 'outbox_message_status_row.dart';
import 'restore_outbox_message_gesture_detector.dart';

/// A "local echo" placeholder for a Zulip message to be sent by the self-user.
///
/// See also [OutboxMessage].
class OutboxMessageWithPossibleSender extends StatelessWidget {
  const OutboxMessageWithPossibleSender({super.key, required this.item});

  final MessageListOutboxMessageItem item;

  @override
  Widget build(BuildContext context) {
    final message = item.message;
    final localMessageId = message.localMessageId;

    // This is adapted from [MessageContent].
    // TODO(#576): Offer InheritedMessage ancestor once we are ready
    //   to support local echoing images and lightbox.
    Widget content = DefaultTextStyle(
      style: ContentTheme.of(context).textStylePlainParagraph,
      child: BlockContentList(nodes: item.content.nodes),
    );

    switch (message.state) {
      case OutboxMessageState.hidden:
        throw StateError(
          'Hidden OutboxMessage messages should not appear in message lists',
        );
      case OutboxMessageState.waiting:
        break;
      case OutboxMessageState.failed:
      case OutboxMessageState.waitPeriodExpired:
        // TODO(#576): When we support rendered-content local echo,
        //   use IgnorePointer along with this faded appearance,
        //   like we do for the failed-message-edit state
        content = RestoreOutboxMessageGestureDetector(
          localMessageId: localMessageId,
          child: Opacity(opacity: 0.6, child: content),
        );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          if (item.showSender)
            SenderRow(
              message: message,
              timestampStyle: MessageTimestampStyle.none,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                content,
                OutboxMessageStatusRow(
                  localMessageId: localMessageId,
                  outboxMessageState: message.state,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
