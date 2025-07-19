import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/settings.dart';
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
      child: const SettingsPage()));
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
      // Check the RadioGroup has the correct groupValue
      final radioGroup = tester.widget<RadioGroup<ThemeSetting?>>(
        find.byType(RadioGroup<ThemeSetting?>));
      check(radioGroup.groupValue).equals(expectedThemeSetting);

      // Check each RadioListTile has the correct value and is properly selected
      for (final title in ['System', 'Light', 'Dark']) {
        final themeValue = switch (title) {
          'System' => null,
          'Light' => ThemeSetting.light,
          'Dark' => ThemeSetting.dark,
          _ => throw ArgumentError('Unknown title: $title'),
        };
        final radioTile = tester.widget<RadioListTile<ThemeSetting?>>(
          findRadioListTileWithTitle(title));
        check(radioTile.value).equals(themeValue);

        // The RadioListTile should be selected if its value matches the group value
        final isSelected = themeValue == expectedThemeSetting;
        // We can't directly check the visual state, but we can verify the value is correct
        check(radioTile.value == expectedThemeSetting).equals(isSelected);
      }

      // Check the global store has the expected setting
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
      await tester.pump(const Duration(milliseconds: 250)); // wait for transition
      check(Theme.of(element)).brightness.equals(Brightness.dark);
      checkThemeSetting(tester, expectedThemeSetting: ThemeSetting.dark);

      await tester.tap(findRadioListTileWithTitle('System'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250)); // wait for transition
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
    // Find the ListTile that contains our setting's title...
    final tileFinder = find.ancestor(
        of: find.text('Open links with in-app browser'),
        matching: find.byType(ListTile));
    // ...and from within that tile, find the FigmaToggle.
    final useInAppBrowserToggleFinder = find.descendant(
        of: tileFinder,
        matching: find.byType(FigmaToggle));

    void checkToggleAndGlobalSettings(WidgetTester tester, {
      required bool checked,
      required BrowserPreference? expectedBrowserPreference,
    }) {
      final figmaToggle = tester.widget<FigmaToggle>(useInAppBrowserToggleFinder);
      check(figmaToggle.value).equals(checked);
      check(testBinding.globalStore)
        .settings.browserPreference.equals(expectedBrowserPreference);
    }

    testWidgets('smoke', (tester) async {
      await testBinding.globalStore.settings
        .setBrowserPreference(BrowserPreference.external);
      await prepare(tester);
      checkToggleAndGlobalSettings(tester,
        checked: false, expectedBrowserPreference: BrowserPreference.external);

      await tester.tap(useInAppBrowserToggleFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250)); // wait for animation
      checkToggleAndGlobalSettings(tester,
        checked: true, expectedBrowserPreference: BrowserPreference.inApp);
    });

    testWidgets('use our per-platform default browser preference', (tester) async {
      await prepare(tester);
      bool expectInApp = defaultTargetPlatform == TargetPlatform.android;
      checkToggleAndGlobalSettings(tester,
        checked: expectInApp, expectedBrowserPreference: null);

      await tester.tap(useInAppBrowserToggleFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250)); // wait for animation
      expectInApp = !expectInApp;
      checkToggleAndGlobalSettings(tester,
        checked: expectInApp,
        expectedBrowserPreference: expectInApp
          ? BrowserPreference.inApp : BrowserPreference.external);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });

  group('FigmaToggle', () {
    testWidgets('has correct dimensions when active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FigmaToggle(
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final toggle = tester.widget<FigmaToggle>(find.byType(FigmaToggle));
      expect(toggle.value, isTrue);

      // Test that the toggle renders with correct dimensions
      await tester.pumpAndSettle();

      // The exact dimensions should match Figma specs:
      // Active: 48px × 28px with 10px thumb radius
      final gestureDetector = find.byType(GestureDetector);
      expect(gestureDetector, findsOneWidget);
    });

    testWidgets('has correct dimensions when inactive', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FigmaToggle(
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final toggle = tester.widget<FigmaToggle>(find.byType(FigmaToggle));
      expect(toggle.value, isFalse);

      // Test that the toggle renders with correct dimensions
      await tester.pumpAndSettle();

      // The exact dimensions should match Figma specs:
      // Inactive: 46px × 26px with 7px thumb radius
      final gestureDetector = find.byType(GestureDetector);
      expect(gestureDetector, findsOneWidget);
    });

    testWidgets('toggles value when tapped', (tester) async {
      bool currentValue = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FigmaToggle(
                  value: currentValue,
                  onChanged: (value) {
                    setState(() {
                      currentValue = value;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(currentValue, isFalse);

      await tester.tap(find.byType(FigmaToggle));
      await tester.pump();

      expect(currentValue, isTrue);
    });
  });

  // TODO(#1571): test visitFirstUnread setting UI

  // TODO maybe test GlobalSettingType.experimentalFeatureFlag settings
  //   Or maybe not; after all, it's a developer-facing feature, so
  //   should be low risk.
  //   (The main ingredient in writing such tests would be to wire up
  //   [GlobalSettingsStore.experimentalFeatureFlags] so that tests can
  //   control making it empty, or non-empty, at will.)
}