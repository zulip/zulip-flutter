import 'package:flutter/material.dart';

import 'app.dart';
import 'inbox.dart';
import 'recent_dm_conversations.dart';
import 'store.dart';
import 'subscription_list.dart';

class ZulipNavigationBar extends StatelessWidget {
  final int testStreamId = 7;
  final Type selectedPage;
  final Map<Type, int> pageToIndex = {
    InboxPage: 0,
    SubscriptionListPage: 1,
    RecentDmConversationsPage: 2,
  };

  ZulipNavigationBar({super.key, required this.selectedPage});

  @override
  Widget build(BuildContext context) {
    final accountId = PerAccountStoreWidget.accountIdOf(context);
    return NavigationBar(
        selectedIndex: pageToIndex[selectedPage] ?? 0,
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.inbox),
            icon: Icon(Icons.inbox_outlined),
            label: 'Inbox'),
          NavigationDestination(
            selectedIcon: Icon(Icons.tag),
            icon: Icon(Icons.tag_outlined),
            label: 'Streams'),
          NavigationDestination(
            selectedIcon: Icon(Icons.group),
            icon: Icon(Icons.group_outlined),
            label: 'Direct Messages'),
          // TODO enable this when the profile page is available
          // NavigationDestination(
          //   selectedIcon: Icon(Icons.account_circle),
          //   icon: Icon(Icons.account_circle_outlined),
          //   label: 'Profile'),
          NavigationDestination(
            selectedIcon: Icon(Icons.bug_report_outlined),
            icon: Icon(Icons.bug_report_outlined),
            label: 'Test Page'),
        ],
        onDestinationSelected: (int index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(context, InboxPage.buildRoute(context: context));
              break;
            case 1:
              Navigator.pushReplacement(context, SubscriptionListPage.buildRoute(context: context));
              break;
            case 2:
              Navigator.pushReplacement(context, RecentDmConversationsPage.buildRoute(context: context));
              break;
            case 3:
              Navigator.pushReplacement(context,
                HomePage.buildRoute(accountId: accountId));
              break;
          }
        },
      );
  }
}