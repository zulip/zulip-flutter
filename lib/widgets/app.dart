import 'package:flutter/material.dart';

import '../model/store.dart';
import 'compose_box.dart';
import 'message_list.dart';
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
      child: PerAccountStoreWidget(
        // Just one account for now.
        accountId: GlobalStore.fixtureAccountId,
        child: MaterialApp(
          title: 'Zulip',
          theme: theme,
          home: const HomePage())));
  }
}

/// The Zulip "brand color", a purplish blue.
///
/// This is chosen as the sRGB midpoint of the Zulip logo's gradient.
// As computed by Anders: https://github.com/zulip/zulip-mobile/pull/4467
const kZulipBrandColor = Color.fromRGBO(0x64, 0x92, 0xfe, 1);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);

    InlineSpan bold(String text) => TextSpan(
        text: text, style: const TextStyle(fontWeight: FontWeight.bold));

    return Scaffold(
        appBar: AppBar(title: const Text("Home")),
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 18),
              child: Column(children: [
                const Text('🚧 Under construction 🚧'),
                const SizedBox(height: 12),
                Text.rich(TextSpan(
                    text: 'Connected to: ',
                    children: [bold(store.account.realmUrl)])),
                Text.rich(TextSpan(
                    text: 'Zulip server version: ',
                    children: [bold(store.zulip_version)])),
                Text.rich(TextSpan(text: 'Subscribed to ', children: [
                  bold(store.subscriptions.length.toString()),
                  const TextSpan(text: ' streams'),
                ])),
              ])),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MessageListPage())),
              child: const Text("All messages"))
        ])));
  }
}

class MessageListPage extends StatelessWidget {
  const MessageListPage({super.key});

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
                  const StreamComposeBox()]))));
  }
}
