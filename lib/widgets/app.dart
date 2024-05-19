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
import 'theme.dart';

class ZulipApp extends StatefulWidget {
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
  State<ZulipApp> createState() => _ZulipAppState();
}

class _ZulipAppState extends State<ZulipApp> with WidgetsBindingObserver {
  @override
  Future<bool> didPushRouteInformation(routeInformation) async {
    if (routeInformation case RouteInformation(
      uri: Uri(scheme: 'zulip', host: 'login') && var url)
    ) {
      await LoginPage.handleWebAuthUrl(url);
      return true;
    }
    return super.didPushRouteInformation(routeInformation);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = zulipThemeData(context);
    return GlobalStoreWidget(
      child: Builder(builder: (context) {
        final globalStore = GlobalStoreWidget.of(context);
        // TODO(#524) choose initial account as last one used
        final initialAccountId = globalStore.accounts.firstOrNull?.id;
        return MaterialApp(
          title: 'Zulip',
          localizationsDelegates: ZulipLocalizations.localizationsDelegates,
          supportedLocales: ZulipLocalizations.supportedLocales,
          theme: themeData,

          navigatorKey: ZulipApp.navigatorKey,
          navigatorObservers: widget.navigatorObservers ?? const [],
          builder: (BuildContext context, Widget? child) {
            if (!ZulipApp.ready.value) {
              SchedulerBinding.instance.addPostFrameCallback(
                (_) => widget._declareReady());
            }
            GlobalLocalizations.zulipLocalizations = ZulipLocalizations.of(context);
            return child!;
          },

          // We use onGenerateInitialRoutes for the real work of specifying the
          // initial nav state.  To do that we need [MaterialApp] to decide to
          // build a [Navigator]... which means specifying either `home`, `routes`,
          // `onGenerateRoute`, or `onUnknownRoute`.  Make it `onGenerateRoute`.
          // It never actually gets called, though: `onGenerateInitialRoutes`
          // handles startup, and then we always push whole routes with methods
          // like [Navigator.push], never mere names as with [Navigator.pushNamed].
          onGenerateRoute: (_) => null,

          onGenerateInitialRoutes: (_) {
            return [
              MaterialWidgetRoute(page: const ChooseAccountPage()),
              if (initialAccountId != null) ...[
                HomePage.buildRoute(accountId: initialAccountId),
                InboxPage.buildRoute(accountId: initialAccountId),
              ],
            ];
          });
        }));
  }
}

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
        minimum: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Flexible(child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 8),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  for (final (:accountId, :account) in globalStore.accountEntries)
                    _buildAccountItem(context,
                      accountId: accountId,
                      title: Text(account.realmUrl.toString()),
                      subtitle: Text(account.email)),
                ]))),
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
    return MaterialAccountWidgetRoute(accountId: accountId,
      page: const HomePage());
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
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
            child: Column(children: [
              const Text('🚧 Under construction 🚧'),
              const SizedBox(height: 12),
              Text.rich(TextSpan(
                text: 'Connected to: ',
                children: [bold(store.realmUrl.toString())])),
              Text.rich(TextSpan(
                text: 'Zulip server version: ',
                children: [bold(store.zulipVersion)])),
              Text(zulipLocalizations.subscribedToNStreams(store.subscriptions.length)),
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
            child: Text(zulipLocalizations.recentDmConversationsPageTitle)),
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
