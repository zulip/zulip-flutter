import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';

import '../model/localizations.dart';
import '../model/narrow.dart';
import 'about_zulip.dart';
import 'inbox.dart';
import 'login.dart';
import 'message_list.dart';
import 'page.dart';
import 'recent_dm_conversations.dart';
import 'store.dart';
import 'subscription_list.dart';

class ZulipApp extends StatelessWidget {
  const ZulipApp({super.key, this.navigatorObservers});

  /// Whether the app's widget tree is ready.
  ///
  /// This begins as false.  It transitions to true when the
  /// [GlobalStore] has been loaded and the [MaterialApp] has been mounted,
  /// and then remains true.
  static ValueListenable<bool> get ready => _ready;
  static ValueNotifier<bool> _ready = ValueNotifier(false);

  /// The navigator for the whole app.
  ///
  /// This is always the [GlobalKey.currentState] of [navigatorKey].
  /// If [navigatorKey] is already mounted, this future completes immediately.
  /// Otherwise, it waits for [ready] to become true and then completes.
  static Future<NavigatorState> get navigator {
    final state = navigatorKey.currentState;
    if (state != null) return Future.value(state);

    assert(!ready.value);
    final completer = Completer<NavigatorState>();
    ready.addListener(() {
      assert(ready.value);
      completer.complete(navigatorKey.currentState!);
    });
    return completer.future;
  }

  /// A key for the navigator for the whole app.
  ///
  /// For code that exists entirely outside the widget tree and has no natural
  /// [BuildContext] of its own, this enables interacting with the app's
  /// navigation, by calling [GlobalKey.currentState] to get a [NavigatorState].
  ///
  /// During the app's early startup, this key will not yet be mounted.
  /// It will always be mounted before [ready] becomes true,
  /// and naturally before any widgets are mounted which are part of the
  /// app's main UI managed by the navigator.
  ///
  /// See also [navigator], to asynchronously wait for the navigator
  /// to be mounted.
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Reset the state of [ZulipApp] statics, for testing.
  ///
  /// TODO refactor this better, perhaps unify with ZulipBinding
  @visibleForTesting
  static void debugReset() {
    _ready.dispose();
    _ready = ValueNotifier(false);
  }

  /// A list to pass through to [MaterialApp.navigatorObservers].
  /// Useful in tests.
  final List<NavigatorObserver>? navigatorObservers;

  void _declareReady() {
    assert(navigatorKey.currentContext != null);
    _ready.value = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      appBarTheme: const AppBarTheme(
        // This prevents an elevation change in [AppBar]s so they stop turning
        // darker if there is something scrolled underneath it. See docs:
        //   https://api.flutter.dev/flutter/material/AppBar/elevation.html
        scrolledUnderElevation: 0,
      ),
      // This applies Material 3's color system to produce a palette of
      // appropriately matching and contrasting colors for use in a UI.
      // The Zulip brand color is a starting point, but doesn't end up as
      // one that's directly used.  (After all, we didn't design it for that
      // purpose; we designed a logo.)  See docs:
      //   https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html
      // Or try this tool to see the whole palette:
      //   https://m3.material.io/theme-builder#/custom
      colorScheme: ColorScheme.fromSeed(
        seedColor: kZulipBrandColor,

        // Used in the Figma for surfaces underneath scrollable content, e.g.:
        //   <https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=341%3A12362&mode=dev>
        background: const Color(0xfff6f6f6),
      ),
      // `preferBelow: false` seems like a better default for mobile;
      // the area below a long-press target seems more likely to be hidden by
      // a finger or thumb than the area above.
      tooltipTheme: const TooltipThemeData(preferBelow: false),
    );
    return GlobalStoreWidget(
      child: MaterialApp(
        title: 'Zulip',
        localizationsDelegates: ZulipLocalizations.localizationsDelegates,
        supportedLocales: ZulipLocalizations.supportedLocales,
        theme: theme,
        navigatorKey: navigatorKey,
        navigatorObservers: navigatorObservers ?? const [],
        builder: (BuildContext context, Widget? child) {
          if (!ready.value) {
            SchedulerBinding.instance.addPostFrameCallback(
              (_) => _declareReady());
          }
          GlobalLocalizations.zulipLocalizations = ZulipLocalizations.of(context);
          return child!;
        },
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
      child: ListTile(
        title: title,
        subtitle: subtitle,
        onTap: () => Navigator.push(context,
          HomePage.buildRoute(accountId: accountId))));
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    assert(!PerAccountStoreWidget.debugExistsOf(context));
    final globalStore = GlobalStoreWidget.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(zulipLocalizations.chooseAccountPageTitle),
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
                child: Text(zulipLocalizations.chooseAccountButtonAddAnAccount)),
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
    final zulipLocalizations = ZulipLocalizations.of(context);

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
              Text(zulipLocalizations.subscribedToNStreams(store.subscriptions.length)),
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
              InboxPage.buildRoute(context: context)),
            child: const Text("Inbox")), // TODO(i18n)
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
              SubscriptionListPage.buildRoute(context: context)),
            child: const Text("Subscribed streams")),
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
