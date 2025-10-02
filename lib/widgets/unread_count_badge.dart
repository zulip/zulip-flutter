import 'package:flutter/widgets.dart';

import 'channel_colors.dart';
import 'text.dart';
import 'theme.dart';

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

  /// An optional [ChannelColorSwatch], to override the default color scheme
  /// with a channel-colorized one.
  ///
  /// Pass this if the badge represents messages in one specific stream.
  /// The appropriate color from the swatch will be used.
  final ChannelColorSwatch? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final effectiveBackgroundColor = switch (backgroundColor) {
      ChannelColorSwatch(unreadCountBadgeBackground: var color) => color,
      null => designVariables.bgCounterUnread,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: effectiveBackgroundColor,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 1),
        child: Text(
          style: TextStyle(
            fontSize: 16,
            height: (18 / 16),
            fontFeatures: const [FontFeature.enable('smcp')], // small caps
            color: backgroundColor is ChannelColorSwatch
              ? designVariables.unreadCountBadgeTextForChannel
              : designVariables.labelCounterUnread,
          ).merge(weightVariableTextStyle(context,
              wght: bold ? 600 : null)),
          count.toString())));
  }
}

class MutedUnreadBadge extends StatelessWidget {
  const MutedUnreadBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsetsDirectional.only(end: 3),
      decoration: BoxDecoration(
        color: designVariables.mutedUnreadBadge,
        shape: BoxShape.circle));
  }
}
