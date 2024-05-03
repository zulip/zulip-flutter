
import 'package:flutter/material.dart';

import '../api/model/model.dart';
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
  /// Pass a [ColorSwatch<StreamColorVariant>] if this badge represents messages
  /// in one specific stream. The appropriate color from the swatch will be used.
  ///
  /// If null, the default neutral background will be used.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = this.backgroundColor;
    final effectiveBackgroundColor = switch (backgroundColor) {
      ColorSwatch<StreamColorVariant>() =>
        backgroundColor[StreamColorVariant.unreadCountBadgeBackground]!,
      Color() => backgroundColor,
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
            color: Color(0xFF222222),
          ).merge(weightVariableTextStyle(context,
              wght: bold ? 600 : null)),
          count.toString())));
  }
}
