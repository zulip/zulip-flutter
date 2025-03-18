import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/database.dart';
import 'package:zulip/model/settings.dart';

import '../example_data.dart' as eg;
import 'store_checks.dart';
import 'store_test.dart';

void main() {
  final httpLink = Uri.parse('http://chat.zulip.org');
  final nonHttpLink = Uri.parse('mailto:chat@zulip.org');

  group('getUrlLaunchMode', () {
    testAndroidIos('globalSettings.browserPreference is null; use our per-platform defaults for HTTP links', () {
      final globalSettings = eg.globalStore(globalSettings: GlobalSettingsData(
        browserPreference: null)).settings;
      check(globalSettings).getUrlLaunchMode(httpLink).equals(
        defaultTargetPlatform == TargetPlatform.android
          ? UrlLaunchMode.inAppBrowserView : UrlLaunchMode.externalApplication);
    });

    testAndroidIos('globalSettings.browserPreference is null; use our per-platform defaults for non-HTTP links', () {
      final globalSettings = eg.globalStore(globalSettings: GlobalSettingsData(
        browserPreference: null)).settings;
      check(globalSettings).getUrlLaunchMode(nonHttpLink).equals(
        defaultTargetPlatform == TargetPlatform.android
          ? UrlLaunchMode.platformDefault : UrlLaunchMode.externalApplication);
    });

    testAndroidIos('globalSettings.browserPreference is inApp; follow the user preference for http links', () {
      final globalSettings = eg.globalStore(globalSettings: GlobalSettingsData(
        browserPreference: BrowserPreference.inApp)).settings;
      check(globalSettings).getUrlLaunchMode(httpLink).equals(
        UrlLaunchMode.inAppBrowserView);
    });

    testAndroidIos('globalSettings.browserPreference is inApp; use platform default for non-http links', () {
      final globalSettings = eg.globalStore(globalSettings: GlobalSettingsData(
        browserPreference: BrowserPreference.inApp)).settings;
      check(globalSettings).getUrlLaunchMode(nonHttpLink).equals(
        UrlLaunchMode.platformDefault);
    });

    testAndroidIos('globalSettings.browserPreference is external; follow the user preference', () {
      final globalSettings = eg.globalStore(globalSettings: GlobalSettingsData(
        browserPreference: BrowserPreference.external)).settings;
      check(globalSettings).getUrlLaunchMode(httpLink).equals(
        UrlLaunchMode.externalApplication);
    });
  });
}
