import 'package:checks/checks.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zulip/model/binding.dart';

extension DarwinOptionsChecks on Subject<DarwinOptions> {
  Subject<DarwinAssetRepresentationMode> get assetRepresentationMode => has((x) => x.assetRepresentationMode, 'assetRepresentationMode');
  Subject<bool> get orderedSelection => has((x) => x.orderedSelection, 'orderedSelection');
}

extension IosDeviceInfoChecks on Subject<IosDeviceInfo> {
  Subject<int?> get majorVersion => has((x) => x.majorVersion, 'majorVersion');
}
