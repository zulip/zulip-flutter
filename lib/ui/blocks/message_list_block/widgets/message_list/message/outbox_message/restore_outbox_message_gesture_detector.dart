import 'package:flutter/material.dart';

import '../../../../message_list_block.dart';

class RestoreOutboxMessageGestureDetector extends StatelessWidget {
  const RestoreOutboxMessageGestureDetector({
    super.key,
    required this.localMessageId,
    required this.child,
  });

  final int localMessageId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final composeBoxState = MessageListBlockPage.ancestorOf(
          context,
        ).composeBoxState;
        // TODO(#1518) allow restore-outbox-message from any message-list page
        if (composeBoxState == null) return;
        composeBoxState.restoreMessageNotSent(localMessageId);
      },
      child: child,
    );
  }
}
