import 'package:flutter/material.dart';

import '../../../api/model/model.dart';
import '../../../model/content.dart';
import '../../themes/content_theme.dart';
import '../../widgets/poll.dart';
import 'widgets/block_content_list.dart';

/// The entire content of a message, aka its body.
///
/// This does not include metadata like the sender's name and avatar, the time,
/// or the message's status as starred or edited.
class MessageContent extends StatelessWidget {
  const MessageContent({
    super.key,
    required this.message,
    required this.content,
  });

  final Message message;
  final ZulipMessageContent content;

  @override
  Widget build(BuildContext context) {
    final content = this.content;
    return InheritedMessage(
      message: message,
      child: DefaultTextStyle(
        style: ContentTheme.of(context).textStylePlainParagraph,
        child: switch (content) {
          ZulipContent() => BlockContentList(nodes: content.nodes),
          PollContent() => PollWidget(
            messageId: message.id,
            poll: content.poll,
          ),
        },
      ),
    );
  }
}

class InheritedMessage extends InheritedWidget {
  const InheritedMessage({
    super.key,
    required this.message,
    required super.child,
  });

  final Message message;

  @override
  bool updateShouldNotify(covariant InheritedMessage oldWidget) =>
      !identical(oldWidget.message, message);

  static Message of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<InheritedMessage>();
    assert(widget != null, 'No InheritedMessage ancestor');
    return widget!.message;
  }
}
