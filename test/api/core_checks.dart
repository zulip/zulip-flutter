import 'package:checks/checks.dart';
import 'package:zulip/api/core.dart';

extension ApiConnectionChecks on Subject<ApiConnection> {
  Subject<Uri> get realmUrl => has((x) => x.realmUrl, 'realmUrl');
  Subject<int?> get zulipFeatureLevel => has((x) => x.zulipFeatureLevel, 'zulipFeatureLevel');
}
