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
    // See also test/widgets/actions_test.dart, where we test that the setting
    // is actually used when we open links, with PlatformActions.launchUrl.

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

  group('setThemeSetting', () {
    test('smoke', () async {
      final globalSettings = eg.globalStore().settings;
      check(globalSettings).themeSetting.equals(null);

      await globalSettings.setThemeSetting(ThemeSetting.dark);
      check(globalSettings).themeSetting.equals(ThemeSetting.dark);
    });

    test('should notify listeners', () async {
      int notifyCount = 0;
      final globalSettings = eg.globalStore().settings;
      globalSettings.addListener(() => notifyCount++);
      check(notifyCount).equals(0);

      await globalSettings.setThemeSetting(ThemeSetting.light);
      check(notifyCount).equals(1);
    });

    // TODO integration tests with sqlite
  });

  // TODO(#1571) test visitFirstUnread applies default
  // TODO(#1571) test shouldVisitFirstUnread

  // TODO(#1583) test markReadOnScroll applies default
  // TODO(#1583) test markReadOnScrollForNarrow

  group('getBool/setBool', () {
    test('get from default', () {
      final globalSettings = eg.globalStore(boolGlobalSettings: {}).settings;
      check(globalSettings).getBool(BoolGlobalSetting.placeholderIgnore)
        .isFalse();
      assert(!BoolGlobalSetting.placeholderIgnore.default_);
    });

    test('get from initial load', () {
      final globalSettings = eg.globalStore(boolGlobalSettings: {
        BoolGlobalSetting.placeholderIgnore: true,
      }).settings;
      check(globalSettings).getBool(BoolGlobalSetting.placeholderIgnore)
        .isTrue();
    });

    test('set, get', () async {
      final globalSettings = eg.globalStore(boolGlobalSettings: {}).settings;
      check(globalSettings).getBool(BoolGlobalSetting.placeholderIgnore)
        .isFalse();

      await globalSettings.setBool(BoolGlobalSetting.placeholderIgnore, true);
      check(globalSettings).getBool(BoolGlobalSetting.placeholderIgnore)
        .isTrue();

      await globalSettings.setBool(BoolGlobalSetting.placeholderIgnore, false);
      check(globalSettings).getBool(BoolGlobalSetting.placeholderIgnore)
        .isFalse();
    });

    test('set to null -> revert to default', () async {
      final globalSettings = eg.globalStore(boolGlobalSettings: {
        BoolGlobalSetting.placeholderIgnore: true,
      }).settings;
      check(globalSettings).getBool(BoolGlobalSetting.placeholderIgnore)
        .isTrue();

      await globalSettings.setBool(BoolGlobalSetting.placeholderIgnore, null);
      check(globalSettings).getBool(BoolGlobalSetting.placeholderIgnore)
        .isFalse();
      assert(!BoolGlobalSetting.placeholderIgnore.default_);
    });

    group('set avoids redundant updates', () {
      int notifiedCount = 0;
      tearDown(() => notifiedCount = 0);

      test('null to null -> no update', () async {
        final globalSettings = eg.globalStore(boolGlobalSettings: {}).settings;
        globalSettings.addListener(() => notifiedCount++);

        await globalSettings.setBool(BoolGlobalSetting.placeholderIgnore, null);
        check(notifiedCount).equals(0);
      });

      test('true to true -> no update', () async {
        final globalSettings = eg.globalStore(boolGlobalSettings: {
          BoolGlobalSetting.placeholderIgnore: true,
        }).settings;
        globalSettings.addListener(() => notifiedCount++);

        await globalSettings.setBool(BoolGlobalSetting.placeholderIgnore, true);
        check(notifiedCount).equals(0);
      });

      test('false to false -> no update', () async {
        final globalSettings = eg.globalStore(boolGlobalSettings: {
          BoolGlobalSetting.placeholderIgnore: false,
        }).settings;
        globalSettings.addListener(() => notifiedCount++);

        await globalSettings.setBool(BoolGlobalSetting.placeholderIgnore, false);
        check(notifiedCount).equals(0);
      });

      test('null to false -> does the update', () async {
        final globalSettings = eg.globalStore(boolGlobalSettings: {}).settings;
        globalSettings.addListener(() => notifiedCount++);

        await globalSettings.setBool(BoolGlobalSetting.placeholderIgnore, false);
        check(notifiedCount).equals(1);
      });

      test('true to null -> does the update', () async {
        final globalSettings = eg.globalStore(boolGlobalSettings: {
          BoolGlobalSetting.placeholderIgnore: true,
        }).settings;
        globalSettings.addListener(() => notifiedCount++);

        await globalSettings.setBool(BoolGlobalSetting.placeholderIgnore, null);
        check(notifiedCount).equals(1);
      });

      test('false to true -> does the update', () async {
        final globalSettings = eg.globalStore(boolGlobalSettings: {
          BoolGlobalSetting.placeholderIgnore: false,
        }).settings;
        globalSettings.addListener(() => notifiedCount++);

        await globalSettings.setBool(BoolGlobalSetting.placeholderIgnore, true);
        check(notifiedCount).equals(1);
      });
    });
  });

  group('getInt/setInt', () {
    test('get from initial load', () {
      final globalSettings = eg.globalStore(intGlobalSettings: {
        IntGlobalSetting.placeholderIgnore: 1,
      }).settings;
      check(globalSettings).getInt(IntGlobalSetting.placeholderIgnore)
        .equals(1);
    });

    test('set, get', () async {
      final globalSettings = eg.globalStore(intGlobalSettings: {}).settings;
      check(globalSettings).getInt(IntGlobalSetting.placeholderIgnore)
        .isNull();

      await globalSettings.setInt(IntGlobalSetting.placeholderIgnore, 1);
      check(globalSettings).getInt(IntGlobalSetting.placeholderIgnore)
        .equals(1);

      await globalSettings.setInt(IntGlobalSetting.placeholderIgnore, 100);
      check(globalSettings).getInt(IntGlobalSetting.placeholderIgnore)
        .equals(100);
    });

    test('set to null -> get returns null', () async {
      final globalSettings = eg.globalStore(intGlobalSettings: {
        IntGlobalSetting.placeholderIgnore: 1,
      }).settings;
      check(globalSettings).getInt(IntGlobalSetting.placeholderIgnore)
        .equals(1);

      await globalSettings.setInt(IntGlobalSetting.placeholderIgnore, null);
      check(globalSettings).getInt(IntGlobalSetting.placeholderIgnore)
        .isNull();
    });

    group('set avoids redundant updates', () {
      int notifiedCount = 0;
      tearDown(() => notifiedCount = 0);

      test('null to null -> no update', () async {
        final globalSettings = eg.globalStore(intGlobalSettings: {}).settings;
        globalSettings.addListener(() => notifiedCount++);

        await globalSettings.setInt(IntGlobalSetting.placeholderIgnore, null);
        check(notifiedCount).equals(0);
      });

      test('10 to 10 -> no update', () async {
        final globalSettings = eg.globalStore(intGlobalSettings: {
          IntGlobalSetting.placeholderIgnore: 10,
        }).settings;
        globalSettings.addListener(() => notifiedCount++);

        await globalSettings.setInt(IntGlobalSetting.placeholderIgnore, 10);
        check(notifiedCount).equals(0);
      });

      test('null to 10 -> does the update', () async {
        final globalSettings = eg.globalStore(intGlobalSettings: {}).settings;
        globalSettings.addListener(() => notifiedCount++);

        await globalSettings.setInt(IntGlobalSetting.placeholderIgnore, 10);
        check(notifiedCount).equals(1);
      });

      test('10 to null -> does the update', () async {
        final globalSettings = eg.globalStore(intGlobalSettings: {
          IntGlobalSetting.placeholderIgnore: 10,
        }).settings;
        globalSettings.addListener(() => notifiedCount++);

        await globalSettings.setInt(IntGlobalSetting.placeholderIgnore, null);
        check(notifiedCount).equals(1);
      });

      test('10 to 100 -> does the update', () async {
        final globalSettings = eg.globalStore(intGlobalSettings: {
          IntGlobalSetting.placeholderIgnore: 10,
        }).settings;
        globalSettings.addListener(() => notifiedCount++);

        await globalSettings.setInt(IntGlobalSetting.placeholderIgnore, 100);
        check(notifiedCount).equals(1);
      });
    });
  });
}
