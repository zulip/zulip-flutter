import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/settings.dart';
import 'package:zulip/widgets/settings.dart';
import 'package:zulip/widgets/app.dart';

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

  Future<void> prepareLanguageSelectionScreen(WidgetTester tester) async {
    addTearDown(testBinding.reset);

    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    await tester.pumpWidget(TestZulipApp(
        accountId: eg.selfAccount.id,
        child: const LanguageSelectionScreen()));
    await tester.pumpAndSettle();
  }

  group('Language Selection', () {
    testWidgets('SettingsPage shows current language name', (tester) async {
      await prepare(tester);

      final languageTile = find.byWidgetPredicate((widget) =>
      widget is ListTile &&
          widget.leading is Icon &&
          (widget.leading as Icon).icon == Icons.language);
      expect(languageTile, findsOneWidget);

      final trailingText = tester.widget<Text>(
          find.descendant(of: languageTile, matching: find.byType(Text)).last);
      check(trailingText.data).equals('System default');
    });

    testWidgets('Language selection screen shows search field', (tester) async {
      await prepareLanguageSelectionScreen(tester);

      final searchField = find.byWidgetPredicate((widget) =>
      widget is TextField &&
          widget.decoration?.hintText == 'Search');
      expect(searchField, findsOneWidget);
    });

    testWidgets('Language selection screen shows language options', (tester) async {
      await prepareLanguageSelectionScreen(tester);

      final languageTiles = find.byWidgetPredicate((widget) =>
      widget is ListTile && find.descendant(
        of: find.byWidget(widget),
        matching: find.byType(Text),
      ).evaluate().isNotEmpty
      );

      expect(languageTiles, findsAtLeastNWidgets(3));
    });

    testWidgets('Can select a language', (tester) async {
      await prepareLanguageSelectionScreen(tester);

      final firstLanguageTile = find.byWidgetPredicate((widget) =>
      widget is ListTile && find.descendant(
        of: find.byWidget(widget),
        matching: find.byType(Text),
      ).evaluate().isNotEmpty
      ).first;

      await tester.ensureVisible(firstLanguageTile);
      await tester.pumpAndSettle();
      await tester.tap(firstLanguageTile);
      await tester.pumpAndSettle();

      check(ZulipApp.currentLocale).isNotNull();
    });

    testWidgets('Selected language shows checkmark', (tester) async {
      ZulipApp.setLocale(const Locale('en'));
      addTearDown(() => ZulipApp.setLocale(null));

      await prepareLanguageSelectionScreen(tester);

      final englishText = find.text('English').first;
      await tester.ensureVisible(englishText);
      await tester.pumpAndSettle();

      final englishTile = find.ancestor(
        of: englishText,
        matching: find.byType(ListTile),
      ).first;

      final englishListTile = tester.widget<ListTile>(englishTile);
      check(englishListTile.trailing).isNotNull();
      check(englishListTile.trailing).isA<Icon>();
      check((englishListTile.trailing! as Icon).icon).equals(Icons.check);
    });

    testWidgets('Can navigate to language screen and back', (tester) async {
      await prepare(tester);

      // Open language selection screen
      final languageTile = find.byWidgetPredicate((widget) =>
      widget is ListTile &&
          widget.leading is Icon &&
          (widget.leading as Icon).icon == Icons.language);
      await tester.tap(languageTile);
      await tester.pumpAndSettle();

      expect(find.byType(LanguageSelectionScreen), findsOneWidget);

      // Find and tap the back button in the AppBar
      final appBar = find.byType(AppBar);
      final backButton = find.descendant(
        of: appBar,
        matching: find.byWidgetPredicate((widget) =>
        widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.arrow_back),
      );

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    });
  });

  // TODO maybe test GlobalSettingType.experimentalFeatureFlag settings
  //   Or maybe not; after all, it's a developer-facing feature, so
  //   should be low risk.
  //   (The main ingredient in writing such tests would be to wire up
  //   [GlobalSettingsStore.experimentalFeatureFlags] so that tests can
  //   control making it empty, or non-empty, at will.)
}
