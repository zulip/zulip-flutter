import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../log.dart';
import '../model/actions.dart';
import '../model/localizations.dart';
import '../model/store.dart';
import '../notifications/open.dart';
import 'about_zulip.dart';
import 'dialog.dart';
import 'home.dart';
import 'login.dart';
import 'page.dart';
import 'store.dart';
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

  /// The [ScaffoldMessengerState] for the app.
  ///
  /// This is null during the app's early startup, while [ready] is still false.
  ///
  /// For code that exists entirely outside the widget tree and has no natural
  /// [BuildContext] of its own, this enables controlling snack bars.
  /// Where a relevant [BuildContext] does exist, prefer using that instead,
  /// with [ScaffoldMessenger.of].
  static ScaffoldMessengerState? get scaffoldMessenger {
    final context = navigatorKey.currentContext;
    if (context == null) return null;
    // Not maybeOf; we use MaterialApp, which provides ScaffoldMessenger,
    // so it's a bug if navigatorKey is mounted somewhere lacking that.
    return ScaffoldMessenger.of(context);
  }

  /// Reset the state of [ZulipApp] statics, for testing.
  ///
  /// TODO refactor this better, perhaps unify with ZulipBinding
  @visibleForTesting
  static void debugReset() {
    _snackBarCount = 0;
    reportErrorToUserBriefly = defaultReportErrorToUserBriefly;
    reportErrorToUserModally = defaultReportErrorToUserModally;
    _ready.dispose();
    _ready = ValueNotifier(false);
  }

  /// A list to pass through to [MaterialApp.navigatorObservers].
  /// Useful in tests.
  final List<NavigatorObserver>? navigatorObservers;

  static int _snackBarCount = 0;

  /// The callback we normally use as [reportErrorToUserBriefly].
  static void _reportErrorToUserBriefly(String? message, {String? details}) {
    assert(_ready.value);

    if (message == null) {
      if (_snackBarCount == 0) return;
      assert(_snackBarCount > 0);
      // The [SnackBar] API only exposes ways to hide ether the current snack
      // bar or all of them.
      //
      // To reduce the possibility of hiding snack bars not created by this
      // helper, only clear when there are known active snack bars.
      scaffoldMessenger!.clearSnackBars();
      return;
    }

    final zulipLocalizations = ZulipLocalizations.of(navigatorKey.currentContext!);
    final newSnackBar = scaffoldMessenger!.showSnackBar(
      snackBarAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 200),
        reverseDuration: const Duration(milliseconds: 50)),
      SnackBar(
        content: Text(message),
        action: (details == null) ? null : SnackBarAction(
          label: zulipLocalizations.snackBarDetails,
          onPressed: () => showErrorDialog(context: navigatorKey.currentContext!,
            title: zulipLocalizations.errorDialogTitle,
            message: details))));

    _snackBarCount++;
    newSnackBar.closed.whenComplete(() => _snackBarCount--);
  }

  /// The callback we normally use as [reportErrorToUserModally].
  static void _reportErrorToUserModally(
    String title, {
    String? message,
    Uri? learnMoreButtonUrl,
  }) {
    assert(_ready.value);

    showErrorDialog(
      context: navigatorKey.currentContext!,
      title: title,
      message: message,
      learnMoreButtonUrl: learnMoreButtonUrl);
  }

  void _declareReady() {
    assert(navigatorKey.currentContext != null);
    _ready.value = true;
    reportErrorToUserBriefly = _reportErrorToUserBriefly;
    reportErrorToUserModally = _reportErrorToUserModally;
  }

  @override
  State<ZulipApp> createState() => _ZulipAppState();
}

class _ZulipAppState extends State<ZulipApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    UpgradeWelcomeDialog.maybeShow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  AccountRoute<void>? _initialRouteIos(BuildContext context) {
    return NotificationOpenService.instance
        .routeForNotificationFromLaunch(context: context);
  }

  // TODO migrate Android's notification navigation to use the new Pigeon API.
  AccountRoute<void>? _initialRouteAndroid(
    BuildContext context,
    String initialRoute,
  ) {
    final initialRouteUrl = Uri.tryParse(initialRoute);
    if (initialRouteUrl case Uri(scheme: 'zulip', host: 'notification')) {
      assert(debugLog('got notif: url: $initialRouteUrl'));
      final data = NotificationOpenService.tryParseAndroidNotificationUrl(
        context: context,
        url: initialRouteUrl);
      if (data == null) return null; // TODO(log)
      return NotificationOpenService.routeForNotification(
        context: context,
        data: data);
    }

    return null;
  }

  List<Route<dynamic>> _handleGenerateInitialRoutes(String initialRoute) {
    // The `_ZulipAppState.context` lacks the required ancestors. Instead
    // we use the Navigator which should be available when this callback is
    // called and its context should have the required ancestors.
    final context = ZulipApp.navigatorKey.currentContext!;

    final route = defaultTargetPlatform == TargetPlatform.iOS
        ? _initialRouteIos(context)
        : _initialRouteAndroid(context, initialRoute);
    if (route != null) {
      return [
        HomePage.buildRoute(accountId: route.accountId),
        route,
      ];
    }

    final globalStore = GlobalStoreWidget.of(context);
    // TODO(#524) choose initial account as last one used
    final initialAccountId = globalStore.accounts.firstOrNull?.id;
    return [
      if (initialAccountId == null)
        MaterialWidgetRoute(page: const ChooseAccountPage())
      else
        HomePage.buildRoute(accountId: initialAccountId),
    ];
  }

  @override
  Future<bool> didPushRouteInformation(routeInformation) async {
    switch (routeInformation.uri) {
      case Uri(scheme: 'zulip', host: 'login') && var url:
        await LoginPage.handleWebAuthUrl(url);
        return true;
      case Uri(scheme: 'zulip', host: 'notification') && var url:
        await NotificationOpenService.navigateForAndroidNotificationUrl(url);
        return true;
    }
    return super.didPushRouteInformation(routeInformation);
  }

  @override
  Widget build(BuildContext context) {
    return GlobalStoreWidget(
      blockingFuture: NotificationOpenService.instance.initialized,
      child: Builder(builder: (context) {
        return MaterialApp(
          onGenerateTitle: (BuildContext context) {
            return ZulipLocalizations.of(context).zulipAppTitle;
          },
          localizationsDelegates: ZulipLocalizations.localizationsDelegates,
          supportedLocales: ZulipLocalizations.supportedLocales,
          // The context has to be taken from the [Builder] because
          // [zulipThemeData] requires access to [GlobalStoreWidget] in the tree.
          theme: zulipThemeData(context),

          navigatorKey: ZulipApp.navigatorKey,
          navigatorObservers: [
            if (widget.navigatorObservers != null)
              ...widget.navigatorObservers!,
            _PreventEmptyStack(),
            _UpdateLastVisitedAccount(GlobalStoreWidget.of(context)),
          ],
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

          onGenerateInitialRoutes: _handleGenerateInitialRoutes);
      }));
  }
}

/// Pushes a route whenever the observed navigator stack becomes empty.
class _PreventEmptyStack extends NavigatorObserver {
  void _pushRouteIfEmptyStack() async {
    final navigator = await ZulipApp.navigator;
    bool isEmptyStack = true;
    // TODO: find a better way to inspect the navigator stack
    navigator.popUntil((route) {
      isEmptyStack = false;
      return true; // never actually pops
    });
    if (isEmptyStack) {
      unawaited(navigator.push(
        MaterialWidgetRoute(page: const ChooseAccountPage())));
    }
  }

  @override
  void didRemove(Route<void> route, Route<void>? previousRoute) async {
    _pushRouteIfEmptyStack();
  }

  @override
  void didPop(Route<void> route, Route<void>? previousRoute) async {
    _pushRouteIfEmptyStack();
  }
}

class _UpdateLastVisitedAccount extends NavigatorObserver {
  _UpdateLastVisitedAccount(this.globalStore);

  final GlobalStore globalStore;

  @override
  void didChangeTop(Route<void> topRoute, _) {
    if (topRoute case AccountPageRouteMixin(:var accountId)) {
      globalStore.setLastVisitedAccount(accountId);
    }
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
    final colorScheme = ColorScheme.of(context);
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final materialLocalizations = MaterialLocalizations.of(context);
    return Card(
      clipBehavior: Clip.hardEdge,
      child: ListTile(
        title: title,
        subtitle: subtitle,
        tileColor: colorScheme.secondaryContainer,
        textColor: colorScheme.onSecondaryContainer,
        trailing: MenuAnchor(
          menuChildren: [
            MenuItemButton(
              onPressed: () async {
                final dialog = showSuggestedActionDialog(context: context,
                  title: zulipLocalizations.logOutConfirmationDialogTitle,
                  message: zulipLocalizations.logOutConfirmationDialogMessage,
                  // TODO(#1032) "destructive" style for action button
                  actionButtonText: zulipLocalizations.logOutConfirmationDialogConfirmButton);
                if (await dialog.result == true) {
                  if (!context.mounted) return;
                  // TODO error handling if db write fails?
                  unawaited(logOutAccount(GlobalStoreWidget.of(context), accountId));
                }
              },
              child: Text(zulipLocalizations.chooseAccountPageLogOutButton)),
          ],
          builder: (BuildContext context, MenuController controller, Widget? child) {
            return IconButton(
              tooltip: materialLocalizations.showMenuTooltip, // "Show menu"
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: Icon(Icons.adaptive.more, color: designVariables.icon));
          }),
        // The default trailing padding with M3 is 24px. Decrease by 12 because
        // IconButton (the "…" button) comes with 12px padding on all sides.
        contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 12),
        onTap: () => HomePage.navigate(context, accountId: accountId)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    assert(!PerAccountStoreWidget.debugExistsOf(context));
    final globalStore = GlobalStoreWidget.of(context);

    // Borrowed from [AppBar.build].
    // See documentation on [ModalRoute.impliesAppBarDismissal]:
    // > Whether an [AppBar] in the route should automatically add a back button or
    // > close button.
    final hasBackButton = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;

    return MenuButtonTheme(
      data: MenuButtonThemeData(style: MenuItemButton.styleFrom(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer)),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: hasBackButton ? null : 16,
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
              ]))))));
  }
}

class ChooseAccountPageOverflowButton extends StatelessWidget {
  const ChooseAccountPageOverflowButton({super.key});

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final materialLocalizations = MaterialLocalizations.of(context);
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            Navigator.push(context, AboutZulipPage.buildRoute(context));
          },
          child: Text(zulipLocalizations.aboutPageTitle)),
      ],
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          tooltip: materialLocalizations.showMenuTooltip, // "Show menu"
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: Icon(Icons.adaptive.more));
      });
  }
}
