
import 'package:flutter/material.dart';

import 'store.dart';

/// An [InheritedWidget] for near the root of a page's widget subtree,
/// providing its [BuildContext].
///
/// Useful when needing a context that persists through the page's lifespan,
/// e.g. for a show-action-sheet function
/// whose buttons use a context to close the sheet
/// or show an error dialog / snackbar asynchronously.
///
/// (In this scenario, it would be buggy to use the context of the element
/// that was long-pressed,
/// if the element can unmount as part of handling a Zulip event.)
class PageRoot extends InheritedWidget {
  const PageRoot({super.key, required super.child});

  @override
  bool updateShouldNotify(covariant PageRoot oldWidget) => false;

  static BuildContext contextOf(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<PageRoot>();
    assert(element != null, 'No PageRoot ancestor');
    return element!;
  }
}

/// A page route that always builds the same widget.
///
/// This is useful for making the route more transparent for a test to inspect.
abstract class WidgetRoute<T extends Object?> extends PageRoute<T> {
  /// The widget that this page route always builds.
  Widget get page;
}

/// A page route that specifies a particular Zulip account to use, by ID.
abstract class AccountRoute<T extends Object?> extends PageRoute<T> {
  /// The [Account.id] of the account to use for this page.
  int get accountId;
}

/// A [MaterialPageRoute] that always builds the same widget.
///
/// This is useful for making the route more transparent for a test to inspect.
///
/// See also:
///  * [MaterialAccountWidgetRoute], a subclass which automates providing a
///    per-account store on the new route.
class MaterialWidgetRoute<T extends Object?> extends MaterialPageRoute<T> implements WidgetRoute<T> {
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
mixin AccountPageRouteMixin<T extends Object?> on PageRoute<T> implements AccountRoute<T> {
  @override
  int get accountId;

  Widget? get loadingPlaceholderPage;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return PerAccountStoreWidget(
      accountId: accountId,
      placeholder: loadingPlaceholderPage ?? const LoadingPlaceholderPage(),
      routeToRemoveOnLogout: this,
      // PageRoot goes under PerAccountStoreWidget, so the provided context
      // can be used for PerAccountStoreWidget.of.
      child: PageRoot(
        child: super.buildPage(context, animation, secondaryAnimation)));
  }
}

/// A [MaterialPageRoute] providing a per-account store for a given account.
///
/// See also:
///  * [MaterialAccountWidgetRoute], a subclass which is more transparent
///    for tests.
///  * [AccountPageRouteBuilder], for defining one-off page routes
///    in terms of callbacks.
class MaterialAccountPageRoute<T extends Object?> extends MaterialPageRoute<T> with AccountPageRouteMixin<T> {
  /// Construct a [MaterialAccountPageRoute] using either the given account ID,
  /// or the ambient one from the given context.
  ///
  /// The account ID used is [accountId] if specified,
  /// else the ambient account ID from [context].
  /// One of those parameters must be specified, and not both.
  ///
  /// Generally most navigation in the app is within a given account,
  /// and should use [context].  Using [accountId] is appropriate for
  /// navigating across accounts, or navigating into an account from contexts
  /// (like login or the choose-account page) that don't have an ambient account.
  MaterialAccountPageRoute({
    int? accountId,
    BuildContext? context,
    this.loadingPlaceholderPage,
    required super.builder,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
  }) : assert((accountId != null) ^ (context != null),
         "exactly one of accountId or context must be specified"),
       accountId = accountId ?? PerAccountStoreWidget.accountIdOf(context!);

  @override
  final int accountId;

  @override
  final Widget? loadingPlaceholderPage;
}

/// A [MaterialPageRoute] that provides a per-account store for a given account
/// and always builds the same widget.
///
/// This is the [PageRoute] subclass to use for most navigation in the app.
///
/// Always building the same widget is useful for making the route
/// more transparent for a test to inspect.
///
/// See also:
///  * [MaterialWidgetRoute], for routes that need no per-account store.
class MaterialAccountWidgetRoute<T extends Object?> extends MaterialAccountPageRoute<T> implements WidgetRoute<T> {
  /// Construct a [MaterialAccountWidgetRoute] using either the given account ID,
  /// or the ambient one from the given context.
  ///
  /// The account ID used is [accountId] if specified,
  /// else the ambient account ID from [context].
  /// One of those parameters must be specified, and not both.
  ///
  /// Generally most navigation in the app is within a given account,
  /// and should use [context].  Using [accountId] is appropriate for
  /// navigating across accounts, or navigating into an account from contexts
  /// (like login or the choose-account page) that don't have an ambient account.
  MaterialAccountWidgetRoute({
    super.accountId,
    super.context,
    super.loadingPlaceholderPage,
    required this.page,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
  }) : super(builder: (context) => page);

  @override
  final Widget page;
}

/// A [PageRouteBuilder] providing a per-account store for a given account.
///
/// This is the [PageRouteBuilder] analogue of [MaterialAccountPageRoute].
class AccountPageRouteBuilder<T extends Object?> extends PageRouteBuilder<T> with AccountPageRouteMixin<T> {
  /// Construct an [AccountPageRouteBuilder] using either the given account ID,
  /// or the ambient one from the given context.
  ///
  /// The account ID used is [accountId] if specified,
  /// else the ambient account ID from [context].
  /// One of those parameters must be specified, and not both.
  ///
  /// Generally most navigation in the app is within a given account,
  /// and should use [context].  Using [accountId] is appropriate for
  /// navigating across accounts, or navigating into an account from contexts
  /// (like login or the choose-account page) that don't have an ambient account.
  AccountPageRouteBuilder({
    int? accountId,
    BuildContext? context,
    this.loadingPlaceholderPage,
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
  }) : assert((accountId != null) ^ (context != null),
         "exactly one of accountId or context must be specified"),
       accountId = accountId ?? PerAccountStoreWidget.accountIdOf(context!);

  @override
  final int accountId;

  @override
  final Widget? loadingPlaceholderPage;
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
