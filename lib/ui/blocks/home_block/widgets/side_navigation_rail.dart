import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../values/icons.dart';
import '../../../values/theme.dart';
import '../home.dart';
import 'bottom_nav_bar.dart';
import 'navigation_bar_button.dart';

class SideNavigationRail extends StatelessWidget {
  const SideNavigationRail({super.key, required this.tabNotifier});

  final ValueNotifier<HomePageTab> tabNotifier;

  NavigationBarButton _button({
    required HomePageTab tab,
    required IconData icon,
    required String label,
  }) {
    return NavigationBarButton(
      icon: icon,
      label: label,
      selected: tabNotifier.value == tab,
      onPressed: () {
        tabNotifier.value = tab;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    // TODO(a11y): add tooltips for these buttons
    final navigationBarButtons = [
      // _button(
      //   tab: HomePageTab.inbox,
      //   icon: ZulipIcons.inbox,
      //   label: zulipLocalizations.inboxPageTitle,
      // ),
      // _NavigationBarButton(
      //   icon: ZulipIcons.message_feed,
      //   label: zulipLocalizations.navBarFeedLabel,
      //   selected: false,
      //   onPressed: () => Navigator.push(
      //     context,
      //     MessageListBlockPage.buildRoute(
      //       context: context,
      //       narrow: const CombinedFeedNarrow(),
      //     ),
      //   ),
      // ),
      _button(
        tab: HomePageTab.channels,
        icon: ZulipIcons.hash_italic,
        label: zulipLocalizations.channelsPageTitle,
      ),
      // TODO(#1094): Users
      _button(
        tab: HomePageTab.directMessages,
        icon: ZulipIcons.two_person,
        label: zulipLocalizations.recentDmConversationsPageShortLabel,
      ),
      NavigationBarButton(
        icon: ZulipIcons.menu,
        label: zulipLocalizations.navBarMenuLabel,
        selected: false,
        onPressed: () => showMainMenu(context, tabNotifier: tabNotifier),
      ),
    ];

    Widget result = DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: designVariables.borderBar)),
        color: designVariables.bgBotBar,
      ),
      child: SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            // TODO(design): determine a suitable max width for bottom nav bar
            constraints: const BoxConstraints(minWidth: 64),
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 24,
                children: [
                  for (final navigationBarButton in navigationBarButtons)
                    navigationBarButton,
                ],
              ),
            ),
          ),
        ),
      ),
    );

    result = Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.tabBar,
      child: result,
    );

    return result;
  }
}
