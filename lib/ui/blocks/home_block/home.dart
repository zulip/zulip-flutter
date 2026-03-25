import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../generated/l10n/zulip_localizations.dart';
import '../../../model/narrow.dart';
import '../../widgets/app_bar.dart';
import '../../values/icons.dart';
import '../inbox_block/inbox.dart';
import '../message_list_block/message_list_block.dart';
import '../../utils/page.dart';
import '../recent_dm_conversations_block/recent_dm_conversations.dart';
import '../subscription_list_block/subscription_list_block.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/home_loading_placeholder_page.dart';
import 'widgets/side_navigation_rail.dart';

enum HomePageTab { inbox, channels, directMessages }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static AccountRoute<void> buildRoute({required int accountId}) {
    return MaterialAccountWidgetRoute(
      accountId: accountId,
      loadingPlaceholderPage: HomeLoadingPlaceholderPage(accountId: accountId),
      page: const HomePage(),
    );
  }

  /// Navigate to [HomePage], ensuring that its route is at the root level.
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
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final _tab = ValueNotifier(HomePageTab.channels);

  @override
  void initState() {
    super.initState();
    _tab.addListener(_tabChanged);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _tabChanged() {
    setState(() {
      // The actual state lives in [_tab].
    });
  }

  String get _currentTabTitle {
    final zulipLocalizations = ZulipLocalizations.of(context);
    switch (_tab.value) {
      case HomePageTab.inbox:
        return zulipLocalizations.inboxPageTitle;
      case HomePageTab.channels:
        return zulipLocalizations.channelsPageTitle;
      case HomePageTab.directMessages:
        return zulipLocalizations.recentDmConversationsPageTitle;
    }
  }

  List<Widget>? get _currentTabAppBarActions {
    switch (_tab.value) {
      case .inbox:
        return [
          IconButton(
            icon: const Icon(ZulipIcons.search),
            tooltip: ZulipLocalizations.of(context).searchMessagesPageTitle,
            onPressed: () => Navigator.push(
              context,
              MessageListBlockPage.buildRoute(
                context: context,
                narrow: KeywordSearchNarrow(''),
              ),
            ),
          ),
        ];
      case .channels:
      case .directMessages:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const pageBodies = [
      (HomePageTab.inbox, InboxPageBody()),
      (HomePageTab.channels, SubscriptionListPageBody()),
      // TODO(#1094): Users
      (HomePageTab.directMessages, RecentDmConversationsPageBody()),
    ];

    final bottomNavBar = Platform.isAndroid || Platform.isIOS
        ? BottomNavBar(tabNotifier: _tab)
        : null;

    final homeBody = Stack(
      children: [
        for (final (tab, body) in pageBodies)
          Offstage(offstage: tab != _tab.value, child: body),
      ],
    );

    return Scaffold(
      appBar: ZulipAppBar(
        titleSpacing: 16,
        title: Semantics(
          identifier: HomePage.titleSemanticsIdentifier,
          namesRoute: true,
          child: Text(_currentTabTitle),
        ),
        actions: _currentTabAppBarActions,
      ),
      body: Semantics(
        role: SemanticsRole.tabPanel,
        identifier: HomePage.contentSemanticsIdentifier,
        container: true,
        explicitChildNodes: true,
        child: Platform.isAndroid || Platform.isIOS
            ? homeBody
            : Row(
                children: [
                  SideNavigationRail(tabNotifier: _tab),
                  Expanded(child: homeBody),
                ],
              ),
      ),
      bottomNavigationBar: bottomNavBar,
    );
  }
}
