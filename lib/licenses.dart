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
  // Alphabetic by path.

  yield LicenseEntryWithLineBreaks(
    ['KaTeX'],
    await rootBundle.loadString('assets/KaTeX/LICENSE'));
  yield LicenseEntryWithLineBreaks(
    ['Noto Color Emoji'],
    await rootBundle.loadString('assets/Noto_Color_Emoji/LICENSE'));
  yield LicenseEntryWithLineBreaks(
    ['Pygments'],
    await () async {
      final [licenseFileText, authorsFileText] = await Future.wait([
        rootBundle.loadString('assets/Pygments/LICENSE.txt'),
        rootBundle.loadString('assets/Pygments/AUTHORS.txt'),
      ]);

      // This does not need to be translated, as it is just a small fragment
      // of text surrounded by a large quantity of English text that isn't
      // translated anyway.
      // (And it would be logistically tricky to translate, as this code is
      // called from the `main` function before the [ZulipApp] widget is built,
      // let alone has updated [GlobalLocalizations].)
      return '$licenseFileText\n\nAUTHORS file follows:\n\n$authorsFileText';
    }());
  yield LicenseEntryWithLineBreaks(
    ['Source Code Pro'],
    await rootBundle.loadString('assets/Source_Code_Pro/LICENSE.md'));
  yield LicenseEntryWithLineBreaks(
    ['Source Sans 3'],
    await rootBundle.loadString('assets/Source_Sans_3/LICENSE.md'));

  // Alphabetic by path.
}
