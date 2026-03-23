import 'package:flutter/material.dart';

import '../../../message_list.dart';

/// Widget responsible for showing the read status of a message.
class UnreadMarker extends StatelessWidget {
  const UnreadMarker({super.key, required this.isRead, required this.child});

  final bool isRead;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final messageListTheme = MessageListTheme.of(context);
    return Stack(
      children: [
        child,
        PositionedDirectional(
          top: 0,
          start: 0,
          bottom: 0,
          width: 4,
          child: AnimatedOpacity(
            opacity: isRead ? 0 : 1,
            // Web uses 2s and 0.3s durations, and a CSS ease-out curve.
            // See zulip:web/styles/message_row.css .
            duration: Duration(milliseconds: isRead ? 2000 : 300),
            curve: Curves.easeOut,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: messageListTheme.unreadMarker,
                border: BorderDirectional(
                  start: BorderSide(
                    width: 1,
                    color: messageListTheme.unreadMarkerGap,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
