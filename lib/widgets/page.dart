
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

mixin AccountPageRouteMixin<T> on PageRoute<T> {
  int get accountId;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return PerAccountStoreWidget(
      accountId: accountId,
      child: super.buildPage(context, animation, secondaryAnimation));
  }
}

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

/// A [MaterialAccountPageRoute] that always builds the same widget.
///
/// This is useful for making the route more transparent for a test to inspect.
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
