import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../utils/store.dart';
import '../../../values/icons.dart';
import '../../../values/theme.dart';
import '../../../widgets/button.dart';
import '../home.dart';
import 'main_menu.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.tabNotifier});

  final ValueNotifier<HomePageTab> tabNotifier;

  _NavigationBarButton _button({
    required HomePageTab tab,
    required IconData icon,
    required String label,
  }) {
    return _NavigationBarButton(
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
      _NavigationBarButton(
        icon: ZulipIcons.menu,
        label: zulipLocalizations.navBarMenuLabel,
        selected: false,
        onPressed: () => _showMainMenu(context, tabNotifier: tabNotifier),
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
            constraints: const BoxConstraints(maxWidth: 600, minHeight: 48),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final navigationBarButton in navigationBarButtons)
                  Expanded(child: navigationBarButton),
              ],
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

class _NavigationBarButton extends StatelessWidget {
  const _NavigationBarButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final color = selected
        ? designVariables.iconSelected
        : designVariables.icon;

    Widget result = AnimatedScaleOnPress(
      scaleEnd: 0.875,
      duration: const Duration(milliseconds: 100),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          // TODO(#417): Disable splash effects for all buttons globally.
          splashFactory: NoSplash.splashFactory,
          highlightColor: designVariables.navigationButtonBg,
          onTap: onPressed,
          child: Padding(
            // (Added 3px horizontal padding not present in Figma, to make the
            // text wrap before getting too close to the button's edge, which is
            // visible on tap-down.)
            padding: const EdgeInsets.fromLTRB(3, 6, 3, 3),
            child: Column(
              spacing: 3,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: color),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      height: 12 / 12,
                    ),
                    textAlign: TextAlign.center,
                    textScaler: MediaQuery.textScalerOf(
                      context,
                    ).clamp(maxScaleFactor: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    result = MergeSemantics(
      child: Semantics(
        role: SemanticsRole.tab,
        controlsNodes: {
          HomePage.contentSemanticsIdentifier,
          HomePage.titleSemanticsIdentifier,
        },
        selected: selected,
        onTap: onPressed,
        child: result,
      ),
    );

    return result;
  }
}

void _showMainMenu(
  BuildContext context, {
  required ValueNotifier<HomePageTab> tabNotifier,
}) {
  final designVariables = DesignVariables.of(context);
  final accountId = PerAccountStoreWidget.accountIdOf(context);
  showModalBottomSheet<void>(
    context: context,
    // Clip.hardEdge looks bad; Clip.antiAliasWithSaveLayer looks pixel-perfect
    // on my iPhone 13 Pro but is marked as "much slower":
    //   https://api.flutter.dev/flutter/dart-ui/Clip.html
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    isScrollControlled: true,
    // TODO: Fix the issue that the color does not respond when the theme
    //   changes, because `designVariables` was retrieved from a gesture handler,
    //   not a build method.  Discussion and screenshots:
    //     https://github.com/zulip/zulip-flutter/pull/1076/files#r1872659043
    backgroundColor: designVariables.bgBotBar,
    builder: (BuildContext _) {
      return PerAccountStoreWidget(
        accountId: accountId,
        child: MainMenu(tabNotifier: tabNotifier),
      );
    },
  );
}
