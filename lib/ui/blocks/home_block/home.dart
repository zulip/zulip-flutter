import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

import '../../../generated/l10n/zulip_localizations.dart';
import '../../../model/narrow.dart';
import '../../widgets/app_bar.dart';
import '../../values/icons.dart';
import '../../widgets/new_dm_sheet.dart';
import '../inbox_block/inbox.dart';
import '../message_list_block/message_list_block.dart';
import '../../utils/page.dart';
import '../recent_dm_conversations_block/recent_dm_conversations.dart';
import '../subscription_list_block/subscription_list_block.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/home_loading_placeholder_page.dart';
import 'widgets/side_navigation_rail.dart';
import 'home_controller.dart';

enum HomePageTab { inbox, channels, directMessages }

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  static AccountRoute<void> buildRoute({required int accountId}) {
    return MaterialAccountWidgetRoute(
      accountId: accountId,
      loadingPlaceholderPage: HomeLoadingPlaceholderPage(accountId: accountId),
      page: const HomePage(),
    );
  }

  static void navigate(BuildContext context, {required int accountId}) {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    unawaited(
      navigator.pushReplacement(HomePage.buildRoute(accountId: accountId)),
    );
  }

  static String contentSemanticsIdentifier = 'home-page-content';
  static String titleSemanticsIdentifier = 'home-page-title';

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);

    return Obx(() {
      final currentTab = controller.currentTab.value;

      String getTitle() {
        switch (currentTab) {
          case HomePageTab.inbox:
            return zulipLocalizations.inboxPageTitle;
          case HomePageTab.channels:
            return zulipLocalizations.channelsPageTitle;
          case HomePageTab.directMessages:
            return zulipLocalizations.recentDmConversationsPageTitle;
        }
      }

      List<Widget>? getActions() {
        switch (currentTab) {
          case HomePageTab.inbox:
            return [
              IconButton(
                icon: const Icon(ZulipIcons.search),
                tooltip: zulipLocalizations.searchMessagesPageTitle,
                onPressed: () => controller.navigateToInboxSearch(),
              ),
            ];
          case HomePageTab.channels:
            return [
              IconButton(
                icon: const Icon(ZulipIcons.message_feed),
                tooltip: zulipLocalizations.navButtonAllChannels,
                onPressed: () => controller.navigateToAllChannels(),
              ),
              const SizedBox(width: 16),
            ];
          case HomePageTab.directMessages:
            return [
              IconButton(
                icon: const Icon(ZulipIcons.plus),
                tooltip: zulipLocalizations.newDmFabButtonLabel,
                onPressed: () {
                  showNewDmSheet(context, (DmNarrow narrow) {
                    Navigator.pushReplacement(
                      context,
                      MessageListBlockPage.buildRoute(
                        context: context,
                        narrow: narrow,
                      ),
                    );
                  });
                },
              ),
              const SizedBox(width: 16),
            ];
        }
      }

      final pageBodies = [
        (HomePageTab.inbox, const InboxPageBody()),
        (HomePageTab.channels, const SubscriptionListPageBody()),
        (HomePageTab.directMessages, const RecentDmConversationsPageBody()),
      ];

      final bottomNavBar = controller.isMobile
          ? BottomNavBar(tabNotifier: controller.currentTab)
          : null;

      final homeBody = Stack(
        children: [
          for (final (tab, body) in pageBodies)
            Offstage(offstage: tab != currentTab, child: body),
        ],
      );

      return Scaffold(
        appBar: ZulipAppBar(
          titleSpacing: 16,
          title: Semantics(
            identifier: HomePage.titleSemanticsIdentifier,
            namesRoute: true,
            child: Text(getTitle()),
          ),
          actions: getActions(),
        ),
        body: Semantics(
          role: SemanticsRole.tabPanel,
          identifier: HomePage.contentSemanticsIdentifier,
          container: true,
          explicitChildNodes: true,
          child: controller.isMobile
              ? homeBody
              : Row(
                  children: [
                    SideNavigationRail(tabNotifier: controller.currentTab),
                    Expanded(child: homeBody),
                  ],
                ),
        ),
        bottomNavigationBar: bottomNavBar,
      );
    });
  }
}
