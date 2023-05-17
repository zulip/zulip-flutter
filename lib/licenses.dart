import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Our [LicenseEntryCollector] for licenses that aren't included by default.
///
/// Licenses that ship with our Dart-package dependencies are included
/// automatically. This collects other licenses, such as for fonts we include in
/// our asset bundle.
// If the license text is meant to be read from a file in the asset bundle,
// remember to include the file in the asset bundle by listing its path
// under `assets` in pubspec.yaml.
Stream<LicenseEntry> additionalLicenses() async* {
  yield LicenseEntryWithLineBreaks(
    ['Source Code Pro'],
    await rootBundle.loadString('assets/Source_Code_Pro/LICENSE.md'));
}
