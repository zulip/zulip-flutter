import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:zulip/widgets/page.dart';

extension WidgetRouteChecks on Subject<WidgetRoute> {
  Subject<Widget> get page => has((x) => x.page, 'page');
}

extension AccountPageRouteMixinChecks on Subject<AccountPageRouteMixin> {
  Subject<int> get accountId => has((x) => x.accountId, 'accountId');
}
