import 'package:flutter/widgets.dart';

import 'store.dart';
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
    required this.channelIdForBackground,
    this.bold = false,
  });

  final int count;
  final bool bold;

  /// An optional [Subscription.streamId], for a channel-colorized background.
  ///
  /// Useful when this badge represents messages in one specific channel.
  ///
  /// If null, the default neutral background will be used.
  final int? channelIdForBackground;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);

    final Color textColor;
    final Color backgroundColor;
    if (channelIdForBackground != null) {
      textColor = designVariables.unreadCountBadgeTextForChannel;

      final subscription = store.subscriptions[channelIdForBackground!];
      final swatch = colorSwatchFor(context, subscription);
      backgroundColor = swatch.unreadCountBadgeBackground;
    } else {
      textColor = designVariables.labelCounterUnread;
      backgroundColor = designVariables.bgCounterUnread;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: backgroundColor,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 1),
        child: Text(
          style: TextStyle(
            fontSize: 16,
            height: (18 / 16),
            fontFeatures: const [FontFeature.enable('smcp')], // small caps
            color: textColor,
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
