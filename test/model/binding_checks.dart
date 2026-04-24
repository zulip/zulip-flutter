import 'package:checks/checks.dart';
import 'package:zulip/model/binding.dart';

extension IosDeviceInfoChecks on Subject<IosDeviceInfo> {
  Subject<int?> get majorVersion => has((x) => x.majorVersion, 'majorVersion');
}
