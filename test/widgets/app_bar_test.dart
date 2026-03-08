import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/app_bar.dart';
import 'package:zulip/widgets/image.dart';
import 'package:zulip/widgets/profile.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import '../test_images.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  testWidgets('show progress indicator when loading', (tester) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

    final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    await store.addUser(eg.selfUser);

    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
      child: ProfilePage(userId: eg.selfUser.userId)));

    final finder = find.descendant(
      of: find.byType(ZulipAppBar),
      matching: find.byType(LinearProgressIndicator));

    await tester.pumpAndSettle();
    final rectBefore = tester.getRect(find.byType(ZulipAppBar));
    check(finder.evaluate()).isEmpty();
    store.isRecoveringEventStream = true;

    await tester.pump();
    check(tester.getRect(find.byType(ZulipAppBar))).equals(rectBefore);
    check(finder.evaluate()).single;
  });

  group("buildTitle's willCenterTitle agrees with Material AppBar", () {
    /// Build an [AppBar]; inspect and return whether it decided to center.
    Future<bool> material(WidgetTester tester, {
      required bool? paramValue,
      required bool? themeValue,
      required List<Widget>? actions,
    }) async {
      testBinding.reset();

      final themeData = ThemeData(appBarTheme: AppBarTheme(centerTitle: themeValue));
      final widget = TestZulipApp(
        child: Theme(data: themeData,
          child: AppBar(
            centerTitle: paramValue,
            actions: actions,
            title: const Text('a'))));

      await tester.pumpWidget(widget);
      await tester.pump();

      // test assumes LTR text direction
      check(tester.platformDispatcher.locale).equals(const Locale('en', 'US'));
      assert(actions == null || actions.isNotEmpty);
      final titleAreaRightEdgeOffset = actions == null
        ? (tester.view.physicalSize / tester.view.devicePixelRatio).width
        : tester.getTopLeft(find.byWidget(actions.first)).dx;
      final titlePosition = tester.getTopLeft(find.text('a')).dx;
      final isCentered = titlePosition > ((1 / 3) * titleAreaRightEdgeOffset);
      check(titlePosition).isLessThan((2 / 3) * titleAreaRightEdgeOffset);

      return isCentered;
    }

    /// Build a [ZulipAppBar]; return willCenterTitle from the buildTitle call.
    Future<bool> ours(WidgetTester tester, {
      required bool? paramValue,
      required bool? themeValue,
      required List<Widget>? actions,
    }) async {
      testBinding.reset();
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

      bool? result;

      final widget = TestZulipApp(
        // ZulipAppBar expects a per-account context (for the loading indicator)
        accountId: eg.selfAccount.id,
        child: Builder(builder: (context) => Theme(
          data: Theme.of(context).copyWith(appBarTheme: AppBarTheme(centerTitle: themeValue)),
          child: ZulipAppBar(
            centerTitle: paramValue,
            actions: actions,
            buildTitle: (willCenterTitle) {
              result = willCenterTitle;
              return const Text('a');
            },
            showRealmIcon: false))));

      await tester.pumpWidget(widget);
      await tester.pump(); // global store
      await tester.pump(); // per-account store
      check(find.widgetWithText(ZulipAppBar, 'a')).findsOne();

      check(result).isNotNull();
      return result!;
    }

    void doTest(String description, bool expectedWillCenter, {
      bool? paramValue,
      bool? themeValue,
      TargetPlatform? platform,
      List<Widget>? actions,
    }) {
      testWidgets(description, (tester) async {
        addTearDown(testBinding.reset);
        debugDefaultTargetPlatformOverride = platform;

        check(
          await ours(tester, paramValue: paramValue, themeValue: themeValue, actions: actions)
        )..equals(
          await material(tester, paramValue: paramValue, themeValue: themeValue, actions: actions)
        )..equals(expectedWillCenter);

        // TODO(upstream) Do this in an addTearDown, once we can:
        //   https://github.com/flutter/flutter/issues/123189
        debugDefaultTargetPlatformOverride = null;
      });
    }

    const iOS = TargetPlatform.iOS;
    const android = TargetPlatform.android;

    Widget button() => IconButton(icon: const Icon(Icons.add), onPressed: () {});
    final oneButton =    [button()];
    final twoButtons =   [button(), button()];
    final threeButtons = [button(), button(), button()];

    doTest('ios',     true,  platform: iOS);
    doTest('android', false, platform: android);

    doTest('ios, theme false',    false, platform: iOS,     themeValue: false);
    doTest('android, theme true', true,  platform: android, themeValue: true);

    doTest('ios, param false',    false, platform: iOS,     paramValue: false);
    doTest('android, param true', true,  platform: android, paramValue: true);

    doTest('ios, theme true, param false', false,     platform: iOS,     themeValue: true,  paramValue: false);
    doTest('ios, theme false, param true', true,      platform: iOS,     themeValue: false, paramValue: true);

    doTest('android, theme true, param false', false, platform: android, themeValue: true,  paramValue: false);
    doTest('android, theme false, param true', true,  platform: android, themeValue: false, paramValue: true);

    doTest('ios, no actions',    true,  platform: iOS, actions: null);
    doTest('ios, one action',    true,  platform: iOS, actions: oneButton);
    doTest('ios, two actions' ,  false, platform: iOS, actions: twoButtons);
    doTest('ios, three actions', false, platform: iOS, actions: threeButtons);

    doTest('ios, two actions but param true', true, platform: iOS, paramValue: true, actions: twoButtons);
    doTest('ios, two actions but theme true', true, platform: iOS, themeValue: true, actions: twoButtons);
  });

  group('realm icon', () {
    Future<void> setupPage(WidgetTester tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

      prepareBoringImageHttpClient();

      await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
        child: Builder(builder: (context) => Scaffold(
          appBar: ZulipAppBar(
            showRealmIcon: true,
            buildTitle: (_) => const Text('Inbox'))))));

      await tester.pump();
      await tester.pump();
    }

    testWidgets('shows realm icon when showRealmIcon is true', (tester) async {
      await setupPage(tester);

      check(find.descendant(
        of: find.byType(ZulipAppBar),
        matching: find.byType(RealmContentNetworkImage))).findsOne();
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('no realm icon when showRealmIcon is false', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

      await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
        child: Builder(builder: (context) => Scaffold(
          appBar: ZulipAppBar(
            buildTitle: (_) => const Text('Inbox'),
            showRealmIcon: false)))));

      await tester.pump();
      await tester.pump();

      check(find.descendant(
        of: find.byType(ZulipAppBar),
        matching: find.byType(RealmContentNetworkImage))).findsNothing();
    });

    testWidgets('realm icon tap navigates to ChooseAccountPage', (tester) async {
      await setupPage(tester);

      await tester.tap(find.byType(RealmContentNetworkImage));
      await tester.pumpAndSettle();

      check(find.byType(ChooseAccountPage)).findsOne();
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('appbar height unaffected by loading indicator', (tester) async {
      await setupPage(tester);

      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final rectBefore = tester.getRect(find.byType(ZulipAppBar));

      store.isRecoveringEventStream = true;
      await tester.pump();

      check(tester.getRect(find.byType(ZulipAppBar))).equals(rectBefore);
      debugNetworkImageHttpClientProvider = null;
    });
  });
}
