import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:zulip/widgets/page.dart';

extension WidgetRouteChecks<T> on Subject<WidgetRoute<T>> {
  Subject<Widget> get page => has((x) => x.page, 'page');
}

extension AccountPageRouteMixinChecks<T> on Subject<AccountPageRouteMixin<T>> {
  Subject<int> get accountId => has((x) => x.accountId, 'accountId');
}
