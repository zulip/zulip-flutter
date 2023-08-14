import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:zulip/widgets/page.dart';

extension WidgetRouteChecks on Subject<WidgetRoute> {
  Subject<Widget> get page => has((x) => x.page, 'page');
}
