import 'package:flutter/material.dart';

import 'about_zulip.dart';
import 'compose_box.dart';
import 'login.dart';
import 'message_list.dart';
import 'page.dart';
import 'store.dart';

class ZulipApp extends StatelessWidget {
  const ZulipApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
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
      child: MaterialApp(
        title: 'Zulip',
        theme: theme,
        home: const ChooseAccountPage()));
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
      child: InkWell(
        onTap: () => Navigator.push(context,
          HomePage.buildRoute(accountId: accountId)),
        child: ListTile(title: title, subtitle: subtitle)));
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
    return MaterialPageRoute(builder: (context) =>
      PerAccountStoreWidget(accountId: accountId,
        child: const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);

    InlineSpan bold(String text) => TextSpan(
      text: text, style: const TextStyle(fontWeight: FontWeight.bold));

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
              MessageListPage.buildRoute(context)),
            child: const Text("All messages")),
        ])));
  }
}

class MessageListPage extends StatelessWidget {
  const MessageListPage({super.key});

  static Route<void> buildRoute(BuildContext context) {
    return MaterialAccountPageRoute(context: context,
      builder: (context) => const MessageListPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All messages")),
      body: Builder(
        builder: (BuildContext context) => Center(
          child: Column(children: [
            MediaQuery.removePadding(
              // Scaffold knows about the app bar, and so has run this
              // BuildContext, which is under `body`, through
              // MediaQuery.removePadding with `removeTop: true`.
              context: context,

              // The compose box pads the bottom inset.
              removeBottom: true,

              child: const Expanded(
                child: MessageList())),
            const StreamComposeBox(),
          ]))));
  }
}
