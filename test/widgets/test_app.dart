import 'package:flutter/material.dart';

import 'package:zulip/generated/l10n/zulip_localizations.dart';
import 'package:zulip/widgets/store.dart';
import 'package:zulip/widgets/theme.dart';

/// A lightweight mock of [ZulipApp], suitable for most widget tests.
class TestZulipApp extends StatelessWidget {
  const TestZulipApp({
    super.key,
    this.accountId,
    this.navigatorObservers,
    this.child = const Placeholder(),
  });

  final int? accountId;

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
    return GlobalStoreWidget(
      child: MaterialApp(
        title: 'Zulip',
        localizationsDelegates: ZulipLocalizations.localizationsDelegates,
        supportedLocales: ZulipLocalizations.supportedLocales,
        theme: zulipThemeData(context),

        navigatorObservers: navigatorObservers ?? const [],

        home: accountId != null
          ? PerAccountStoreWidget(accountId: accountId!, child: child)
          : child,
      ));
  }
}
