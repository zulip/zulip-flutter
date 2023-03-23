
import 'package:flutter/material.dart';

import 'store.dart';

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
