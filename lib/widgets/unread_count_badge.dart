
import 'package:flutter/material.dart';

import 'stream_colors.dart';
import 'text.dart';

/// A widget to display a given number of unreads in a conversation.
///
/// Implements the design for these in Figma:
///   <https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=341%3A12387&mode=dev>
class UnreadCountBadge extends StatelessWidget {
  const UnreadCountBadge({
    super.key,
    required this.count,
    required this.backgroundColor,
    this.bold = false,
  });

  final int count;
  final bool bold;

  /// The badge's background color.
  ///
  /// Pass a [StreamColorSwatch] if this badge represents messages in one
  /// specific stream. The appropriate color from the swatch will be used.
  ///
  /// If null, the default neutral background will be used.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = switch (backgroundColor) {
      StreamColorSwatch(unreadCountBadgeBackground: var color) => color,
      Color() => backgroundColor,
      // TODO(#95) need dark-theme color
      null => const Color.fromRGBO(102, 102, 153, 0.15),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: effectiveBackgroundColor,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 1),
        child: Text(
          style: const TextStyle(
            fontSize: 16,
            height: (18 / 16),
            fontFeatures: [FontFeature.enable('smcp')], // small caps

            // From the Figma:
            //   https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?type=design&node-id=171-12359&mode=design&t=JKrw76SGUF51nSJG-0
            // TODO or, when background is stream-colored, follow Vlad's replit?
            //     https://replit.com/@VladKorobov/zulip-sidebar#script.js
            //   which would mean:
            //   - in light mode use `Color.fromRGBO(0, 0, 0, 0.9)`
            //   - in dark mode use `Color.fromRGBO(255, 255, 255, 0.9)`
            //   The web app doesn't (yet?) use stream-colored unread markers
            //   so we can't take direction from there.
            // TODO(#95) need dark-theme color
            color: Color(0xFF222222),
          ).merge(weightVariableTextStyle(context,
              wght: bold ? 600 : null)),
          count.toString())));
  }
}
