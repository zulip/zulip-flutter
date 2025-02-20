import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/settings.dart';

import '../example_data.dart' as eg;
import 'store_checks.dart';
import 'store_test.dart';

void main() {
  group('effectiveBrowserPreference', () {
    testAndroidIos('use non-default values', () {
      final globalStore = eg.globalStore(globalSettings: eg.globalSettings(
        browserPreference: BrowserPreference.external));
      check(globalStore).globalSettings.effectiveBrowserPreference.equals(
        BrowserPreference.external);
    });

    testAndroidIos('use default values by platform', () {
      check(eg.globalStore()).globalSettings.effectiveBrowserPreference.equals(
        defaultTargetPlatform == TargetPlatform.iOS
          ? BrowserPreference.external : BrowserPreference.embedded);
    });
  });
}
