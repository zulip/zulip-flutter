import 'package:flutter/material.dart';

import '../model/narrow.dart';
import 'inbox.dart';
import 'message_list.dart';
import 'recent_dm_conversations.dart';
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
    return NavigationBar(
        selectedIndex: pageToIndex[selectedPage] ?? 0,
        destinations: [
          const NavigationDestination(
            selectedIcon: Icon(Icons.inbox),
            icon: Icon(Icons.inbox_outlined),
            label: 'Inbox'),
          const NavigationDestination(
            selectedIcon: Icon(Icons.tag),
            icon: Icon(Icons.tag_outlined),
            label: 'Streams'),
          const NavigationDestination(
            selectedIcon: Icon(Icons.group),
            icon: Icon(Icons.group_outlined),
            label: 'Direct Messages'),
          // TODO enable this when it's available
          // NavigationDestination(
          //   selectedIcon: Icon(Icons.account_circle),
          //   icon: Icon(Icons.account_circle_outlined),
          //   label: 'Profile'),
          if (testStreamId != null) ...[
            const NavigationDestination(
              selectedIcon: Icon(Icons.bug_report),
              icon: Icon(Icons.bug_report_outlined),
              label: 'Test Stream'),
          ],
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
                MessageListPage.buildRoute(context: context,
                  narrow: StreamNarrow(testStreamId!)));
              break;
          }
        },
      );
  }
}