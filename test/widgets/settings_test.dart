import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/settings.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/settings.dart';
import 'package:zulip/widgets/store.dart';

import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/store_checks.dart';
import '../example_data.dart' as eg;
import '../test_navigation.dart';
import 'checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late TestNavigatorObserver testNavObserver;
  late Route<dynamic>? lastPushedRoute;
  late Route<dynamic>? lastPoppedRoute;

  Future<void> prepare(WidgetTester tester) async {
    addTearDown(testBinding.reset);

    testNavObserver = TestNavigatorObserver()
      ..onPushed = ((route, _) => lastPushedRoute = route)
      ..onPopped = ((route, _) => lastPoppedRoute = route);
    lastPushedRoute = null;
    lastPoppedRoute = null;

    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    await tester.pumpWidget(TestZulipApp(
      accountId: eg.selfAccount.id,
      navigatorObservers: [testNavObserver],
      child: SettingsPage()));
    await tester.pump();
    await tester.pump();
  }

  void checkTileOnSettingsPage(WidgetTester tester, {
    required String expectedTitle,
    required String expectedSubtitle,
  }) {
    check(find.descendant(of: find.widgetWithText(ListTile, expectedTitle),
      matching: find.text(expectedSubtitle))).findsOne();
  }

  Finder findRadioListTileWithTitle<T>(String title) => find.ancestor(
    of: find.text(title),
    matching: find.byType(RadioTile<T>));

  void checkRadioButtonAppearsChecked<T>(WidgetTester tester,
      String title, bool expectedIsChecked, {String? subtitle}) {
    check(tester.semantics.find(findRadioListTileWithTitle<T>(title)))
      .containsSemantics(
        label: subtitle == null
          ? title
          : '$title\n$subtitle',
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true, isChecked: expectedIsChecked);
  }

  testWidgets('SettingsPage is scrollable when taller than a screenful', (tester) async {
    tester.view.physicalSize = const Size(200, 200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await prepare(tester);

    final lastElementFinder = GlobalSettingsStore.experimentalFeatureFlags.isNotEmpty
      ? find.text("Experimental features")
      : find.text("Mark messages as read on scroll");
    check(lastElementFinder).findsNothing();

    await tester.scrollUntilVisible(lastElementFinder, 100);
    check(lastElementFinder).findsOne();
  });

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

  group('VisitFirstUnreadSetting', () {
    String settingTitle(VisitFirstUnreadSetting setting) => switch (setting) {
      VisitFirstUnreadSetting.always => 'First unread message',
      VisitFirstUnreadSetting.conversations => 'First unread message in conversation views, newest message elsewhere',
      VisitFirstUnreadSetting.never => 'Newest message',
    };

    void checkPage(WidgetTester tester, {
      required VisitFirstUnreadSetting expectedSetting,
    }) {
      for (final setting in VisitFirstUnreadSetting.values) {
        final thisSettingTitle = settingTitle(setting);
        checkRadioButtonAppearsChecked<VisitFirstUnreadSetting>(tester,
          thisSettingTitle, setting == expectedSetting);
      }
    }

    testWidgets('smoke', (tester) async {
      await prepare(tester);

      // "conversations" is the default, and it appears in the SettingsPage
      // (as the setting tile's subtitle)
      check(GlobalStoreWidget.settingsOf(tester.element(find.byType(SettingsPage))))
        .visitFirstUnread.equals(VisitFirstUnreadSetting.conversations);
      checkTileOnSettingsPage(tester,
        expectedTitle: 'Open message feeds at',
        expectedSubtitle: settingTitle(VisitFirstUnreadSetting.conversations));

      await tester.tap(find.text('Open message feeds at'));
      await tester.pump();
      check(lastPushedRoute).isA<MaterialWidgetRoute>()
        .page.isA<VisitFirstUnreadSettingPage>();
      await tester.pump((lastPushedRoute as TransitionRoute).transitionDuration);
      checkPage(tester, expectedSetting: VisitFirstUnreadSetting.conversations);

      await tester.tap(findRadioListTileWithTitle<VisitFirstUnreadSetting>(
        settingTitle(VisitFirstUnreadSetting.always)));
      await tester.pump();
      checkPage(tester, expectedSetting: VisitFirstUnreadSetting.always);

      await tester.tap(findRadioListTileWithTitle<VisitFirstUnreadSetting>(
        settingTitle(VisitFirstUnreadSetting.conversations)));
      await tester.pump();
      checkPage(tester, expectedSetting: VisitFirstUnreadSetting.conversations);

      await tester.tap(findRadioListTileWithTitle<VisitFirstUnreadSetting>(
        settingTitle(VisitFirstUnreadSetting.never)));
      await tester.pump();
      checkPage(tester, expectedSetting: VisitFirstUnreadSetting.never);

      await tester.tap(find.backButton());
      check(lastPoppedRoute).isA<MaterialWidgetRoute>()
        .page.isA<VisitFirstUnreadSettingPage>();
      await tester.pump((lastPoppedRoute as TransitionRoute).reverseTransitionDuration);
      check(GlobalStoreWidget.settingsOf(tester.element(find.byType(SettingsPage))))
        .visitFirstUnread.equals(VisitFirstUnreadSetting.never);

      checkTileOnSettingsPage(tester,
        expectedTitle: 'Open message feeds at',
        expectedSubtitle: settingTitle(VisitFirstUnreadSetting.never));
    });
  });

  group('MarkReadOnScrollSetting', () {
    String settingTitle(MarkReadOnScrollSetting setting) => switch (setting) {
      MarkReadOnScrollSetting.always => 'Always',
      MarkReadOnScrollSetting.conversations => 'Only in conversation views',
      MarkReadOnScrollSetting.never => 'Never',
    };

    String? settingSubtitle(MarkReadOnScrollSetting setting) => switch (setting) {
      MarkReadOnScrollSetting.always => null,
      MarkReadOnScrollSetting.conversations =>
        'Messages will be automatically marked as read only when viewing a single topic or direct message conversation.',
      MarkReadOnScrollSetting.never => null,
    };

    void checkPage(WidgetTester tester, {
      required MarkReadOnScrollSetting expectedSetting,
    }) {
      for (final setting in MarkReadOnScrollSetting.values) {
        final thisSettingTitle = settingTitle(setting);
        checkRadioButtonAppearsChecked<MarkReadOnScrollSetting>(tester,
          thisSettingTitle,
          setting == expectedSetting,
          subtitle: settingSubtitle(setting));
      }
    }

    testWidgets('smoke', (tester) async {
      await prepare(tester);

      // "conversations" is the default, and it appears in the SettingsPage
      // (as the setting tile's subtitle)
      check(GlobalStoreWidget.settingsOf(tester.element(find.byType(SettingsPage))))
        .markReadOnScroll.equals(MarkReadOnScrollSetting.conversations);
      checkTileOnSettingsPage(tester,
        expectedTitle: 'Mark messages as read on scroll',
        expectedSubtitle: settingTitle(MarkReadOnScrollSetting.conversations));

      await tester.tap(find.text('Mark messages as read on scroll'));
      await tester.pump();
      check(lastPushedRoute).isA<MaterialWidgetRoute>()
        .page.isA<MarkReadOnScrollSettingPage>();
      await tester.pump((lastPushedRoute as TransitionRoute).transitionDuration);
      checkPage(tester, expectedSetting: MarkReadOnScrollSetting.conversations);

      await tester.tap(findRadioListTileWithTitle<MarkReadOnScrollSetting>(
        settingTitle(MarkReadOnScrollSetting.always)));
      await tester.pump();
      checkPage(tester, expectedSetting: MarkReadOnScrollSetting.always);

      await tester.tap(findRadioListTileWithTitle<MarkReadOnScrollSetting>(
        settingTitle(MarkReadOnScrollSetting.conversations)));
      await tester.pump();
      checkPage(tester, expectedSetting: MarkReadOnScrollSetting.conversations);

      await tester.tap(findRadioListTileWithTitle<MarkReadOnScrollSetting>(
        settingTitle(MarkReadOnScrollSetting.never)));
      await tester.pump();
      checkPage(tester, expectedSetting: MarkReadOnScrollSetting.never);

      await tester.tap(find.byType(BackButton));
      check(lastPoppedRoute).isA<MaterialWidgetRoute>()
        .page.isA<MarkReadOnScrollSettingPage>();
      await tester.pump((lastPoppedRoute as TransitionRoute).reverseTransitionDuration);
      check(GlobalStoreWidget.settingsOf(tester.element(find.byType(SettingsPage))))
        .markReadOnScroll.equals(MarkReadOnScrollSetting.never);

      checkTileOnSettingsPage(tester,
        expectedTitle: 'Mark messages as read on scroll',
        expectedSubtitle: settingTitle(MarkReadOnScrollSetting.never));
    });
  });

  // TODO maybe test GlobalSettingType.experimentalFeatureFlag settings
  //   Or maybe not; after all, it's a developer-facing feature, so
  //   should be low risk.
  //   (The main ingredient in writing such tests would be to wire up
  //   [GlobalSettingsStore.experimentalFeatureFlags] so that tests can
  //   control making it empty, or non-empty, at will.)
}

