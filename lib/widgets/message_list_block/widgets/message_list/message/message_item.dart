import 'package:flutter/material.dart';

import '../../../../../api/model/model.dart';
import '../../../../../model/message_list.dart';
import '../../../../../model/narrow.dart';
import '../../../../sticky_header.dart';
import '../../../../theme.dart';
import 'common_message/message_with_possible_sender.dart';
import 'outbox_message/outbox_message_with_possible_sender.dart';
import 'unread_marker.dart';

class MessageItem extends StatelessWidget {
  const MessageItem({
    super.key,
    required this.narrow,
    required this.item,
    required this.header,
    required this.isLastInFeed,
  });

  final Narrow narrow;
  final MessageListMessageBaseItem item;
  final Widget header;
  final bool isLastInFeed;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final item = this.item;
    Widget child = ColoredBox(
      color: designVariables.bgMessageRegular,
      child: Column(
        children: [
          switch (item) {
            MessageListMessageItem() => MessageWithPossibleSender(
              narrow: narrow,
              item: item,
            ),
            MessageListOutboxMessageItem() => OutboxMessageWithPossibleSender(
              item: item,
            ),
          },
          // TODO write tests for this padding logic
          if (isLastInFeed)
            const SizedBox(height: 5)
          else if (item.isLastInBlock)
            const SizedBox(height: 11),
        ],
      ),
    );
    if (item case MessageListMessageItem(:final message)) {
      child = UnreadMarker(
        isRead: message.flags.contains(MessageFlag.read),
        child: child,
      );
    }
    return StickyHeaderItem(
      allowOverflow: !item.isLastInBlock,
      header: header,
      child: child,
    );
  }
}
