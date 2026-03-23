import 'package:flutter/material.dart';

import '../../../../message_list_block.dart';

class RestoreEditMessageGestureDetector extends StatelessWidget {
  const RestoreEditMessageGestureDetector({
    super.key,
    required this.messageId,
    required this.child,
  });

  final int messageId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final composeBoxState = MessageListBlockPage.ancestorOf(
          context,
        ).composeBoxState;
        // TODO(#1518) allow restore-edit-message from any message-list page
        if (composeBoxState == null) return;
        composeBoxState.startEditInteraction(messageId);
      },
      child: child,
    );
  }
}
