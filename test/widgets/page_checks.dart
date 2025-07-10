import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:zulip/widgets/page.dart';

extension WidgetRouteChecks<T> on Subject<WidgetRoute<T>> {
  Subject<Widget> get page => has((x) => x.page, 'page');
}

extension AccountRouteChecks<T> on Subject<AccountRoute<T>> {
  Subject<int> get accountId => has((x) => x.accountId, 'accountId');
}
