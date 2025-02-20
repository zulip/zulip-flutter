import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/settings.dart';

import '../example_data.dart' as eg;
import 'store_checks.dart';
import 'store_test.dart';

void main() {
  group('urlLaunchMode', () {
    testAndroidIos('globalSettings.browserPreference is null; use platform-specific defaults', () {
      check(eg.globalStore()).globalSettings.urlLaunchMode.equals(
        defaultTargetPlatform == TargetPlatform.iOS
          ? UrlLaunchMode.externalApplication : UrlLaunchMode.platformDefault);
    });

    testAndroidIos('globalSettings.browserPreference is non-null; follow the preference', () {
      final globalStore = eg.globalStore(globalSettings: eg.globalSettings(
        browserPreference: BrowserPreference.external));
      check(globalStore).globalSettings.urlLaunchMode.equals(
        UrlLaunchMode.externalApplication);
    });
  });
}
