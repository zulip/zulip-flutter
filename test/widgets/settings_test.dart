import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/settings.dart';
import 'package:zulip/widgets/settings.dart';

import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/store_checks.dart';
import 'test_app.dart';
import '../example_data.dart' as eg;

void main() {
  TestZulipBinding.ensureInitialized();

  Future<void> prepare(WidgetTester tester) async {
    addTearDown(testBinding.reset);

    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    await tester.pumpWidget(TestZulipApp(
      accountId: eg.selfAccount.id,
      child: SettingsPage()));
    await tester.pump();
    await tester.pump();
  }

  group('BrowserPreference', () {
    Finder useInAppBrowserSwitchFinder = find.ancestor(
      of: find.text('Open links with in-app browser'),
      matching: find.byType(SwitchListTile));

    void checkSwitchAndGlobalSettings(WidgetTester tester, {
      required bool useInAppBrowser,
    }) {
      check(tester.widget<SwitchListTile>(useInAppBrowserSwitchFinder))
        .value.equals(useInAppBrowser);
      check(testBinding.globalStore).globalSettings.effectiveBrowserPreference.equals(
        useInAppBrowser ? BrowserPreference.embedded : BrowserPreference.external);
    }

    testWidgets('smoke', (tester) async {
      await testBinding.globalStore.updateGlobalSettings(
        eg.globalSettings(
          browserPreference: BrowserPreference.external).toCompanion(false));
      await prepare(tester);
      checkSwitchAndGlobalSettings(tester, useInAppBrowser: false);

      await tester.tap(useInAppBrowserSwitchFinder);
      await tester.pump();
      checkSwitchAndGlobalSettings(tester, useInAppBrowser: true);
    });

    testWidgets('use platform-specific default browser preference', (tester) async {
      await prepare(tester);
      final defaultUseInAppBrowser = defaultTargetPlatform == TargetPlatform.android;
      checkSwitchAndGlobalSettings(tester, useInAppBrowser: defaultUseInAppBrowser);

      await tester.tap(useInAppBrowserSwitchFinder);
      await tester.pump();
      checkSwitchAndGlobalSettings(tester, useInAppBrowser: !defaultUseInAppBrowser);
    }, variant: TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
  });

  group('ThemeSetting', () {
    Finder findRadioListTileWithTitle(String title) => find.ancestor(
      of: find.text(title),
      matching: find.byType(RadioListTile<ThemeSetting>));

    testWidgets('smoke', (tester) async {
      await testBinding.globalStore.updateGlobalSettings(
        eg.globalSettings(themeSetting: ThemeSetting.light).toCompanion(false));
      await prepare(tester);

      final element = tester.element(find.byType(SettingsPage));
      check(testBinding.globalStore).globalSettings.themeSetting.equals(
        ThemeSetting.light);
      check(Theme.of(element)).brightness.equals(Brightness.light);
      check(tester.widget<RadioListTile<ThemeSetting>>(
        findRadioListTileWithTitle('Light'))).checked.isTrue();

      await tester.tap(findRadioListTileWithTitle('Dark'));
      await tester.pump();
      await tester.pump(Duration(milliseconds: 250)); // wait for transition
      check(testBinding.globalStore).globalSettings.themeSetting.equals(
        ThemeSetting.dark);
      check(Theme.of(element)).brightness.equals(Brightness.dark);
      check(tester.widget<RadioListTile<ThemeSetting>>(
        findRadioListTileWithTitle('Dark'))).checked.isTrue();
    });
  });
}
