import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/settings.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/settings.dart';

import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/store_checks.dart';
import '../example_data.dart' as eg;
import 'test_app.dart';

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

  group('ThemeSetting', () {
    Finder findRadioListTileWithTitle(String title) => find.ancestor(
      of: find.text(title),
      matching: find.byType(RadioListTile<ThemeSetting?>));

    void checkThemeSetting(WidgetTester tester, {
      required ThemeSetting? expectedThemeSetting,
    }) {
      final expectedCheckedTitle = switch (expectedThemeSetting) {
        null => 'System',
        ThemeSetting.light => 'Light',
        ThemeSetting.dark => 'Dark',
      };
      for (final title in ['System', 'Light', 'Dark']) {
        check(tester.widget<RadioListTile<ThemeSetting?>>(
          findRadioListTileWithTitle(title)))
            .checked.equals(title == expectedCheckedTitle);
      }
      check(testBinding.globalStore)
        .settings.themeSetting.equals(expectedThemeSetting);
    }

    testWidgets('smoke', (tester) async {
      debugBrightnessOverride = Brightness.light;

      await testBinding.globalStore.settings.setThemeSetting(ThemeSetting.light);
      await prepare(tester);
      final element = tester.element(find.byType(SettingsPage));
      check(Theme.of(element)).brightness.equals(Brightness.light);
      checkThemeSetting(tester, expectedThemeSetting: ThemeSetting.light);

      await tester.tap(findRadioListTileWithTitle('Dark'));
      await tester.pump();
      await tester.pump(Duration(milliseconds: 250)); // wait for transition
      check(Theme.of(element)).brightness.equals(Brightness.dark);
      checkThemeSetting(tester, expectedThemeSetting: ThemeSetting.dark);

      await tester.tap(findRadioListTileWithTitle('System'));
      await tester.pump();
      await tester.pump(Duration(milliseconds: 250)); // wait for transition
      check(Theme.of(element)).brightness.equals(Brightness.light);
      checkThemeSetting(tester, expectedThemeSetting: null);

      debugBrightnessOverride = null;
    });

    testWidgets('follow system setting when themeSetting is null', (tester) async {
      debugBrightnessOverride = Brightness.dark;

      await prepare(tester);
      final element = tester.element(find.byType(SettingsPage));
      check(Theme.of(element)).brightness.equals(Brightness.dark);
      checkThemeSetting(tester, expectedThemeSetting: null);

      debugBrightnessOverride = null;
    });
  });

  group('BrowserPreference', () {
    Finder useInAppBrowserSwitchFinder = find.ancestor(
      of: find.text('Open links with in-app browser'),
      matching: find.byType(SwitchListTile));

    void checkSwitchAndGlobalSettings(WidgetTester tester, {
      required bool checked,
      required BrowserPreference? expectedBrowserPreference,
    }) {
      check(tester.widget<SwitchListTile>(useInAppBrowserSwitchFinder))
        .value.equals(checked);
      check(testBinding.globalStore)
        .settings.browserPreference.equals(expectedBrowserPreference);
    }

    testWidgets('smoke', (tester) async {
      await testBinding.globalStore.settings
        .setBrowserPreference(BrowserPreference.external);
      await prepare(tester);
      checkSwitchAndGlobalSettings(tester,
        checked: false, expectedBrowserPreference: BrowserPreference.external);

      await tester.tap(useInAppBrowserSwitchFinder);
      await tester.pump();
      checkSwitchAndGlobalSettings(tester,
        checked: true, expectedBrowserPreference: BrowserPreference.inApp);
    });

    testWidgets('use our per-platform default browser preference', (tester) async {
      await prepare(tester);
      bool expectInApp = defaultTargetPlatform == TargetPlatform.android;
      checkSwitchAndGlobalSettings(tester,
        checked: expectInApp, expectedBrowserPreference: null);

      await tester.tap(useInAppBrowserSwitchFinder);
      await tester.pump();
      expectInApp = !expectInApp;
      checkSwitchAndGlobalSettings(tester,
        checked: expectInApp,
        expectedBrowserPreference: expectInApp
          ? BrowserPreference.inApp : BrowserPreference.external);
    }, variant: TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
  });

  // TODO(#1571): test visitFirstUnread setting UI

  group('language setting', () {
    Finder languageListTileFinder = find.ancestor(
      of: find.text('Language'), matching: find.byType(ListTile));

    Subject<Locale> checkAmbientLocale(WidgetTester tester) =>
      check(Localizations.localeOf(tester.element(find.byType(SettingsPage))));

    testWidgets('on SettingsPage, when no language is set', (tester) async {
      await prepare(tester);
      checkAmbientLocale(tester).equals(const Locale('en'));

      assert(testBinding.globalStore.settings.language == null);
      await tester.pump();
      check(languageListTileFinder).findsOne();
      check(find.text('English')).findsNothing();
    });

    testWidgets('on SettingsPage, when a language is set', (tester) async {
      await prepare(tester);
      checkAmbientLocale(tester).equals(const Locale('en'));

      await testBinding.globalStore.settings.setLanguage(const Locale('en'));
      await tester.pump();
      check(find.descendant(
        of: languageListTileFinder, matching: find.text('English'))).findsOne();
    });

    testWidgets('LanguagePage smoke', (tester) async {
      await prepare(tester);
      await tester.tap(languageListTileFinder);
      await tester.pump();
      await tester.pump();
      check(find.text('Polski').hitTestable()).findsOne();
      check(find.text('Polish')).findsOne();
      check(find.byIcon(ZulipIcons.check)).findsNothing();
      checkAmbientLocale(tester).equals(const Locale('en'));
      check(testBinding.globalStore).settings.language.isNull();

      await tester.tap(find.text('Polish'));
      await tester.pump();
      check(find.text('Polski').hitTestable()).findsExactly(2);
      check(find.text('Polish')).findsNothing();
      check(find.descendant(
        of: find.widgetWithText(ListTile, 'Polski'),
        matching: find.byIcon(ZulipIcons.check)),
      ).findsOne();
      checkAmbientLocale(tester).equals(const Locale('pl'));
      check(testBinding.globalStore).settings.language.equals(const Locale('pl'));
    });

    testWidgets('handle unsupported (but valid) locale stored in database', (tester) async {
      await prepare(tester);
      // https://www.loc.gov/standards/iso639-2/php/code_list.php
      await testBinding.globalStore.settings.setLanguage(const Locale('zxx'));
      await tester.pumpAndSettle(); // expect no errors
      checkAmbientLocale(tester).equals(const Locale('en'));

      await tester.tap(languageListTileFinder);
      await tester.pump();
      await tester.pump();
      check(find.byIcon(ZulipIcons.check)).findsNothing();

      await tester.tap(find.text('Polish'));
      await tester.pump();
      checkAmbientLocale(tester).equals(const Locale('pl'));
      check(testBinding.globalStore).settings.language.equals(const Locale('pl'));
    });
  });

  // TODO maybe test GlobalSettingType.experimentalFeatureFlag settings
  //   Or maybe not; after all, it's a developer-facing feature, so
  //   should be low risk.
  //   (The main ingredient in writing such tests would be to wire up
  //   [GlobalSettingsStore.experimentalFeatureFlags] so that tests can
  //   control making it empty, or non-empty, at will.)
}
