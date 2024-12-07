import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/narrow.dart';
import 'app_bar.dart';
import 'inbox.dart';
import 'message_list.dart';
import 'page.dart';
import 'recent_dm_conversations.dart';
import 'store.dart';
import 'subscription_list.dart';
import 'text.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static Route<void> buildRoute({required int accountId}) {
    return MaterialAccountWidgetRoute(accountId: accountId,
        page: const HomePage());
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    InlineSpan bold(String text) => TextSpan(
      style: const TextStyle().merge(weightVariableTextStyle(context, wght: 700)),
      text: text);

    int? testStreamId;
    if (store.connection.realmUrl.origin == 'https://chat.zulip.org') {
      testStreamId = 7; // i.e. `#test here`; TODO cut this scaffolding hack
    }

    return Scaffold(
      appBar: ZulipAppBar(title: const Text("Home")),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          DefaultTextStyle.merge(
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
            child: Column(children: [
              Text.rich(TextSpan(
                text: 'Connected to: ',
                children: [bold(store.realmUrl.toString())])),
            ])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
              MessageListPage.buildRoute(context: context,
                narrow: const CombinedFeedNarrow())),
            child: Text(zulipLocalizations.combinedFeedPageTitle)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
              MessageListPage.buildRoute(context: context,
                narrow: const MentionsNarrow())),
            child: Text(zulipLocalizations.mentionsPageTitle)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
              MessageListPage.buildRoute(context: context,
                narrow: const StarredMessagesNarrow())),
            child: Text(zulipLocalizations.starredMessagesPageTitle)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
              InboxPage.buildRoute(context: context)),
            child: const Text("Inbox")), // TODO(i18n)
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
              SubscriptionListPage.buildRoute(context: context)),
            child: const Text("Subscribed channels")),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
              RecentDmConversationsPage.buildRoute(context: context)),
            child: Text(zulipLocalizations.recentDmConversationsPageTitle)),
          if (testStreamId != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                MessageListPage.buildRoute(context: context,
                  narrow: ChannelNarrow(testStreamId!))),
              child: const Text("#test here")), // scaffolding hack, see above
          ],
        ])));
  }
}
