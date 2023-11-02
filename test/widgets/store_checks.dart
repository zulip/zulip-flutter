import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:zulip/widgets/store.dart';

extension PerAccountStoreWidgetChecks on Subject<PerAccountStoreWidget> {
  Subject<int> get accountId => has((x) => x.accountId, 'accountId');
  Subject<Widget> get child => has((x) => x.child, 'child');
}
