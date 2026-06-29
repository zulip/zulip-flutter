import 'package:pigeon/pigeon.dart';

// To rebuild this pigeon's output after editing this file,
// run `tools/check pigeon --fix`.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/ios_native.g.dart',
  swiftOut: 'ios/Runner/IosNative.g.swift',
  swiftOptions: SwiftOptions(includeErrorClass: false),
))

@HostApi()
abstract class IosNativeHostApi {
  /// Sets UrlResourceValues.isExcludedFromBackup for the given file path.
  ///
  /// The file at this path must already exist,
  /// and be a regular file (not a directory).
  ///
  /// See doc:
  ///   https://developer.apple.com/documentation/foundation/urlresourcevalues/isexcludedfrombackup
  ///   https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup
  void setExcludedFromBackup(String filePath);
}
