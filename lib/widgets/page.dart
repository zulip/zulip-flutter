
import 'package:flutter/material.dart';

import 'store.dart';

/// A page route that always builds the same widget.
///
/// This is useful for making the route more transparent for a test to inspect.
abstract class WidgetRoute<T> extends PageRoute<T> {
  /// The widget that this page route always builds.
  Widget get page;
}

/// A [MaterialPageRoute] that always builds the same widget.
///
/// This is useful for making the route more transparent for a test to inspect.
///
/// See also:
///  * [MaterialAccountWidgetRoute], a subclass which automates reusing a
///    per-account store on the new route.
class MaterialWidgetRoute<T> extends MaterialPageRoute<T> implements WidgetRoute<T> {
  MaterialWidgetRoute({
    required this.page,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
  }) : super(builder: (context) => page);

  @override
  final Widget page;
}

/// A mixin for providing a given account's per-account store on a page route.
mixin AccountPageRouteMixin<T> on PageRoute<T> {
  int get accountId;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return PerAccountStoreWidget(
      accountId: accountId,
      placeholder: const LoadingPlaceholderPage(),
      child: super.buildPage(context, animation, secondaryAnimation));
  }
}

/// A [MaterialPageRoute] that reuses the given context's per-account store.
///
/// This reuse is the desired behavior for any navigation that's meant to stay
/// within a given account.
///
/// See also:
///  * [MaterialAccountWidgetRoute], a subclass which is more transparent
///    for tests.
///  * [AccountPageRouteBuilder], for defining one-off page routes
///    in terms of callbacks.
class MaterialAccountPageRoute<T> extends MaterialPageRoute<T> with AccountPageRouteMixin<T> {
  MaterialAccountPageRoute({
    required BuildContext context,
    required super.builder,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
  }) : accountId = PerAccountStoreWidget.accountIdOf(context);

  @override
  final int accountId;
}

/// A [MaterialPageRoute] that reuses the given context's per-account store
/// and always builds the same widget.
///
/// This is the [PageRoute] subclass to use for most navigation in the app.
///
/// The reuse of the per-account store is the desired behavior for any
/// navigation that's meant to stay within a given account.
///
/// Always building the same widget is useful for making the route
/// more transparent for a test to inspect.
///
/// See also:
///  * [MaterialWidgetRoute], for routes that need no per-account store
///    or a different per-account store.
class MaterialAccountWidgetRoute<T> extends MaterialAccountPageRoute<T> implements WidgetRoute<T> {
  MaterialAccountWidgetRoute({
    required super.context,
    required this.page,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
  }) : super(builder: (context) => page);

  @override
  final Widget page;
}

/// A [PageRouteBuilder] that reuses the given context's per-account store.
///
/// This is the [PageRouteBuilder] analogue of [MaterialAccountPageRoute].
class AccountPageRouteBuilder<T> extends PageRouteBuilder<T> with AccountPageRouteMixin<T> {
  AccountPageRouteBuilder({
    required BuildContext context,
    super.settings,
    required super.pageBuilder,
    super.transitionsBuilder,
    super.transitionDuration,
    super.reverseTransitionDuration,
    super.opaque,
    super.barrierDismissible,
    super.barrierColor,
    super.barrierLabel,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
  }) : accountId = PerAccountStoreWidget.accountIdOf(context);

  @override
  final int accountId;
}

class LoadingPlaceholderPage extends StatelessWidget {
  const LoadingPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const LoadingPlaceholder(),
    );
  }
}
