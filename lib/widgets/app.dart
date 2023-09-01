import 'package:flutter/material.dart';

import '../model/narrow.dart';
import 'about_zulip.dart';
import 'login.dart';
import 'login/browser_login.dart';
import 'message_list.dart';
import 'page.dart';
import 'recent_dm_conversations.dart';
import 'store.dart';

class ZulipApp extends StatelessWidget {
  const ZulipApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: false, // TODO(#225) fix things and switch to true
      // This applies Material 3's color system to produce a palette of
      // appropriately matching and contrasting colors for use in a UI.
      // The Zulip brand color is a starting point, but doesn't end up as
      // one that's directly used.  (After all, we didn't design it for that
      // purpose; we designed a logo.)  See docs:
      //   https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html
      // Or try this tool to see the whole palette:
      //   https://m3.material.io/theme-builder#/custom
      colorScheme: ColorScheme.fromSeed(seedColor: kZulipBrandColor));
    return GlobalStoreWidget(
      child: BrowserLoginWidget(
        child: Builder(
          builder: (context) => MaterialApp(
            title: 'Zulip',
            theme: theme,
            home: const ChooseAccountPage(),
            navigatorKey: BrowserLoginWidget.of(context).navigatorKey,
            // TODO: Migrate to `MaterialApp.router` & `Router`, so that we can receive
            //       a full Uri instead of just path+query components and also maybe
            //       remove the InheritedWidget + navigatorKey hack.
            // See docs:
            //   https://api.flutter.dev/flutter/widgets/Router-class.html
            onGenerateRoute: (settings) {
              if (settings.name == null) return null;
              final uri = Uri.parse(settings.name!);
              if (uri.queryParameters.containsKey('otp_encrypted_api_key')) {
                BrowserLoginWidget.of(context).loginFromExternalRoute(context, uri);
                return null;
              }
              return null;
            })),
      ),
    );
  }
}

/// The Zulip "brand color", a purplish blue.
///
/// This is chosen as the sRGB midpoint of the Zulip logo's gradient.
// As computed by Anders: https://github.com/zulip/zulip-mobile/pull/4467
const kZulipBrandColor = Color.fromRGBO(0x64, 0x92, 0xfe, 1);

class ChooseAccountPage extends StatelessWidget {
  const ChooseAccountPage({super.key});

  Widget _buildAccountItem(
    BuildContext context, {
    required int accountId,
    required Widget title,
    Widget? subtitle,
  }) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: ListTile(
        title: title,
        subtitle: subtitle,
        onTap: () => Navigator.push(context,
          HomePage.buildRoute(accountId: accountId))));
  }

  @override
  Widget build(BuildContext context) {
    assert(!PerAccountStoreWidget.debugExistsOf(context));
    final globalStore = GlobalStoreWidget.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose account'),
        actions: const [ChooseAccountPageOverflowButton()]),
      body: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final (:accountId, :account) in globalStore.accountEntries)
                _buildAccountItem(context,
                  accountId: accountId,
                  title: Text(account.realmUrl.toString()),
                  subtitle: Text(account.email)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.push(context,
                  AddAccountPage.buildRoute()),
                child: const Text('Add an account')),
            ]))),
      ));
  }
}

enum ChooseAccountPageOverflowMenuItem { aboutZulip }

class ChooseAccountPageOverflowButton extends StatelessWidget {
  const ChooseAccountPageOverflowButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ChooseAccountPageOverflowMenuItem>(
      itemBuilder: (BuildContext context) => const [
        PopupMenuItem(
          value: ChooseAccountPageOverflowMenuItem.aboutZulip,
          child: Text('About Zulip')),
      ],
      onSelected: (item) {
        switch (item) {
          case ChooseAccountPageOverflowMenuItem.aboutZulip:
            Navigator.push(context, AboutZulipPage.buildRoute(context));
        }
      });
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static Route<void> buildRoute({required int accountId}) {
    return MaterialWidgetRoute(
      page: PerAccountStoreWidget(accountId: accountId,
        child: const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);

    InlineSpan bold(String text) => TextSpan(
      text: text, style: const TextStyle(fontWeight: FontWeight.bold));

    int? testStreamId;
    if (store.connection.realmUrl.origin == 'https://chat.zulip.org') {
      testStreamId = 7; // i.e. `#test here`; TODO cut this scaffolding hack
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 18),
            child: Column(children: [
              const Text('🚧 Under construction 🚧'),
              const SizedBox(height: 12),
              Text.rich(TextSpan(
                text: 'Connected to: ',
                children: [bold(store.account.realmUrl.toString())])),
              Text.rich(TextSpan(
                text: 'Zulip server version: ',
                children: [bold(store.zulipVersion)])),
              Text.rich(TextSpan(text: 'Subscribed to ', children: [
                bold(store.subscriptions.length.toString()),
                const TextSpan(text: ' streams'),
              ])),
            ])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
              MessageListPage.buildRoute(context: context,
                narrow: const AllMessagesNarrow())),
            child: const Text("All messages")),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
              RecentDmConversationsPage.buildRoute(context: context)),
            child: const Text("Direct messages")),
          if (testStreamId != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                MessageListPage.buildRoute(context: context,
                  narrow: StreamNarrow(testStreamId!))),
              child: const Text("#test here")), // scaffolding hack, see above
          ],
        ])));
  }
}
