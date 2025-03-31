import 'package:flutter/material.dart';

import 'package:zulip/generated/l10n/zulip_localizations.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/store.dart';
import 'package:zulip/widgets/theme.dart';

/// A lightweight mock of [ZulipApp], suitable for most widget tests.
class TestZulipApp extends StatelessWidget {
  const TestZulipApp({
    super.key,
    this.accountId,
    this.skipAssertAccountExists = false,
    this.navigatorObservers,
    this.child = const Placeholder(),
  }) : assert(!skipAssertAccountExists || accountId != null);

  final int? accountId;

  /// Whether to proceed if [accountId] doesn't have an [Account] in the store.
  ///
  /// If this widget's [GlobalStoreWidget] loads
  /// with no [Account] for [accountId],
  /// [build] will error unless this param is true.
  ///
  /// Usually, this case is just a mistake;
  /// the caller either forgot to add the account to the store
  /// or they didn't want to simulate a per-account context in the first place.
  ///
  /// Sometimes we want to simulate an account's UI
  /// just after the account is logged out (so is absent in the store)
  /// but before we tear down that UI.
  /// Pass true to silence the assertion in that case.
  final bool skipAssertAccountExists;

  /// A list to pass through to [MaterialApp.navigatorObservers].
  final List<NavigatorObserver>? navigatorObservers;

  /// A [Widget] to render on the home page.
  ///
  /// If [accountId] is provided, this is wrapped in a [PerAccountStoreWidget].
  ///
  /// Defaults to `Placeholder()`.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlobalStoreWidget(child: Builder(builder: (context) {
      assert(() {
        if (accountId != null && !skipAssertAccountExists) {
          final account = GlobalStoreWidget.of(context).getAccount(accountId!);
          if (account == null) {
            throw FlutterError.fromParts([
              ErrorSummary(
                'TestZulipApp() was called with [accountId] but a corresponding '
                'Account was not found in the GlobalStore.'),
              ErrorHint(
                'If [child] needs per-account data, consider calling '
                '`testBinding.globalStore.add` before pumping `TestZulipApp`.'),
              ErrorHint(
                'If [child] is not specific to an account, omit [accountId].'),
              ErrorHint(
                'If you are testing behavior when an account is logged out, '
                'consider building ZulipApp instead of TestZulipApp, '
                'or pass `skipAssertAccountExists: true`.'),
            ]);
          }
        }
        return true;
      }());

      return MaterialApp(
        title: 'Zulip',
        localizationsDelegates: ZulipLocalizations.localizationsDelegates,
        supportedLocales: ZulipLocalizations.supportedLocales,
        // The context has to be taken from the [Builder] because
        // [zulipThemeData] requires access to [GlobalStoreWidget] in the tree.
        theme: zulipThemeData(context),

        navigatorObservers: navigatorObservers ?? const [],

        home: accountId != null
          ? PerAccountStoreWidget(accountId: accountId!,
              child: PageRoot(child: child))
          : PageRoot(child: child));
    }));
  }
}
