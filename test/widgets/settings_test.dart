import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
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
      child: SettingsPage()));
    await tester.pump();
    await tester.pump();
  }

  Finder findRadioListTileWithTitle<T>(String title) => find.ancestor(
    of: find.text(title),
    matching: find.byType(RadioListTile<T>));

  void checkRadioButtonAppearsChecked<T>(WidgetTester tester, String title, bool expectedIsChecked) {
    check(tester.semantics.find(findRadioListTileWithTitle<T>(title)))
      .containsSemantics(
        label: title,
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true, isChecked: expectedIsChecked);
  }

  group('ThemeSetting', () {
    void checkThemeSetting(WidgetTester tester, {
      required ThemeSetting? expectedThemeSetting,
    }) {
      final expectedCheckedTitle = switch (expectedThemeSetting) {
        null => 'System',
        ThemeSetting.light => 'Light',
        ThemeSetting.dark => 'Dark',
      };
      for (final title in ['System', 'Light', 'Dark']) {
        checkRadioButtonAppearsChecked<ThemeSetting?>(tester, title, title == expectedCheckedTitle);
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

      await tester.tap(findRadioListTileWithTitle<ThemeSetting?>('Dark'));
      await tester.pump();
      await tester.pump(Duration(milliseconds: 250)); // wait for transition
      check(Theme.of(element)).brightness.equals(Brightness.dark);
      checkThemeSetting(tester, expectedThemeSetting: ThemeSetting.dark);

      await tester.tap(findRadioListTileWithTitle<ThemeSetting?>('System'));
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

  // TODO maybe test GlobalSettingType.experimentalFeatureFlag settings
  //   Or maybe not; after all, it's a developer-facing feature, so
  //   should be low risk.
  //   (The main ingredient in writing such tests would be to wire up
  //   [GlobalSettingsStore.experimentalFeatureFlags] so that tests can
  //   control making it empty, or non-empty, at will.)
}
