import 'package:flutter/widgets.dart';

import 'store.dart';
import 'text.dart';
import 'theme.dart';

/// A widget to display a given number (e.g. of unread messages or of users).
///
/// See Figma's "counter-menu" component, which this is based on:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=2037-186671&m=dev
/// It looks like that component was created for the main menu,
/// then adapted for various other contexts, like the Inbox page.
/// See [CounterStyle] and [CounterKind] for the possible variants.
class Counter extends StatelessWidget {
  const Counter({
    super.key,
    this.style = CounterStyle.other,
    required this.kind,
    required this.count,
    required this.channelIdForBackground,
  }) : assert(!(kind == CounterKind.quantity && channelIdForBackground != null));

  final CounterStyle style;
  final CounterKind kind;
  final int count;

  /// An optional [Subscription.streamId], for a channel-colorized background.
  ///
  /// Useful when this counter represents unreads in one specific channel.
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
      textColor = switch (kind) {
        CounterKind.unread => designVariables.labelCounterUnread,
        CounterKind.quantity => designVariables.labelCounterQuantity,
      };
      backgroundColor = designVariables.bgCounterUnread;
    }

    final padding = switch (style) {
      CounterStyle.mainMenu =>
        const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      CounterStyle.other =>
        const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    };

    final double wght = switch ((style, kind)) {
      (CounterStyle.mainMenu, CounterKind.unread  ) => 600,
      (CounterStyle.mainMenu, CounterKind.quantity) => 500,
      (CounterStyle.other,    CounterKind.unread  ) => 500,
      (CounterStyle.other,    CounterKind.quantity) => 500,
    };

    Widget result = Padding(
      padding: padding,
      child: Text(
        style: TextStyle(
          fontSize: 16,
          height: (16 / 16),
          color: textColor,
        ).merge(weightVariableTextStyle(context, wght: wght)),
        count.toString()));

    switch (kind) {
      case CounterKind.unread:
        result = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: backgroundColor,
          ),
          child: result);
      case CounterKind.quantity:
        // no decoration
    }

    return result;
  }
}

enum CounterStyle {
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

enum CounterKind {
  /// The counter counts unread messages.
  ///
  /// Figma:
  ///   Main-menu style: https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=2037-185125&m=dev
  ///   Other style: https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=6205-26001&m=dev
  unread,

  /// The counter counts something else, like users or starred messages.
  ///
  /// Figma:
  ///   Main-menu style: https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=2037-186672&m=dev
  ///   Other style: https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=6025-293468&m=dev
  quantity,
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
