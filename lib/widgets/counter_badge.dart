import 'package:flutter/widgets.dart';

import 'store.dart';
import 'text.dart';
import 'theme.dart';

/// A widget to display a given number of unreads in a conversation.
///
/// See Figma's "counter-menu" component, which this is based on:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=2037-186671&m=dev
/// It looks like that component was created for the main menu,
/// then adapted for various other contexts, like the Inbox page.
/// See [CounterBadgeStyle].
///
/// Currently this widget supports only the component's "kind=unread" variant,
/// not "kind=quantity".
// TODO support the "kind=quantity" variant, update dartdoc
class CounterBadge extends StatelessWidget {
  const CounterBadge({
    super.key,
    this.style = CounterBadgeStyle.other,
    required this.count,
    required this.channelIdForBackground,
  });

  final CounterBadgeStyle style;
  final int count;

  /// An optional [Subscription.streamId], for a channel-colorized background.
  ///
  /// Useful when this badge represents messages in one specific channel.
  ///
  /// If null, the default neutral background will be used.
  // TODO remove; the Figma doesn't use this anymore.
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

    final padding = switch (style) {
      CounterBadgeStyle.mainMenu =>
        const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      CounterBadgeStyle.other =>
        const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    };

    final double wght = switch (style) {
      CounterBadgeStyle.mainMenu => 600,
      CounterBadgeStyle.other => 500,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: backgroundColor,
      ),
      child: Padding(
        padding: padding,
        child: Text(
          style: TextStyle(
            fontSize: 16,
            height: (16 / 16),
            color: textColor,
          ).merge(weightVariableTextStyle(context, wght: wght)),
          count.toString())));
  }
}

enum CounterBadgeStyle {
  /// The style to use in the main menu.
  ///
  /// Figma:
  ///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=2037-185126&m=dev
  mainMenu,

  /// The style to use in other contexts besides the main menu.
  ///
  /// Other contexts include the "Channels" page and the topic-list page:
  ///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=6205-26001&m=dev
  ///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=6823-37113&m=dev
  /// (We use this for the topic-list page even though the Figma makes it a bit
  /// more compact there…the inconsistency seems worse and might be accidental.)
  other,
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
