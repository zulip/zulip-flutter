import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zulip/model/settings.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/dialog.dart';
import 'package:zulip/widgets/store.dart';

import '../model/binding.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late BuildContext context;

  const title = "Dialog Title";
  const message = "Dialog message.";

  Future<void> prepare(WidgetTester tester) async {
    addTearDown(testBinding.reset);

    await tester.pumpWidget(const TestZulipApp(
      child: Scaffold(body: Placeholder())));
    await tester.pump();
    context = tester.element(find.byType(Placeholder));
  }

  group('showErrorDialog', () {
    testWidgets('show error dialog', (tester) async {
      await prepare(tester);

      showErrorDialog(context: context, title: title, message: message);
      await tester.pump();
      checkErrorDialog(tester, expectedTitle: title, expectedMessage: message);
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('user closes error dialog', (tester) async {
      await prepare(tester);

      showErrorDialog(context: context, title: title, message: message);
      await tester.pump();

      final button = checkErrorDialog(tester, expectedTitle: title);
      await tester.tap(find.byWidget(button));
      await tester.pump();
      checkNoDialog(tester);
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('tap "Learn more" button', (tester) async {
      await prepare(tester);

      final learnMoreButtonUrl = Uri.parse('https://foo.example');
      showErrorDialog(context: context, title: title, learnMoreButtonUrl: learnMoreButtonUrl);
      await tester.pump();
      checkErrorDialog(tester, expectedTitle: title);

      await tester.tap(find.text('Learn more'));
      final expectedMode = switch (defaultTargetPlatform) {
        TargetPlatform.android => LaunchMode.inAppBrowserView,
        TargetPlatform.iOS =>     LaunchMode.externalApplication,
        _ => throw StateError('attempted to test with $defaultTargetPlatform'),
      };
      check(testBinding.takeLaunchUrlCalls()).single
        .equals((url: learnMoreButtonUrl, mode: expectedMode));
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('only one SingleChildScrollView created', (tester) async {
      await prepare(tester);

      showErrorDialog(context: context, title: title, message: message);
      await tester.pump();
      checkErrorDialog(tester, expectedTitle: title, expectedMessage: message);

      check(find.ancestor(of: find.text(message),
        matching: find.byType(SingleChildScrollView))).findsOne();
    }, variant: TargetPlatformVariant.all());
  });

  group('showSuggestedActionDialog', () {
    testWidgets('tap action button', (tester) async {
      addTearDown(testBinding.reset);
      await tester.pumpWidget(TestZulipApp());
      await tester.pump();
      final element = tester.element(find.byType(Placeholder));

      final dialog = showSuggestedActionDialog(context: element,
        title: 'Continue?',
        message: 'Do the thing?',
        actionButtonText: 'Sure');
      await tester.pump();
      await tester.tap(find.text('Sure'));
      await check(dialog.result).completes((it) => it.equals(true));
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('tap cancel', (tester) async {
      addTearDown(testBinding.reset);
      await tester.pumpWidget(TestZulipApp());
      await tester.pump();
      final element = tester.element(find.byType(Placeholder));

      final dialog = showSuggestedActionDialog(context: element,
        title: 'Continue?',
        message: 'Do the thing?',
        actionButtonText: 'Sure');
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await check(dialog.result).completes((it) => it.equals(null));
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('tap outside dialog area', (tester) async {
      addTearDown(testBinding.reset);
      await tester.pumpWidget(TestZulipApp());
      await tester.pump();
      final element = tester.element(find.byType(Placeholder));

      final dialog = showSuggestedActionDialog(context: element,
        title: 'Continue?',
        message: 'Do the thing?',
        actionButtonText: 'Sure');
      await tester.pump();
      await tester.tapAt(tester.getTopLeft(find.byType(TestZulipApp)));
      await check(dialog.result).completes((it) => it.equals(null));
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
  });

  testWidgets('only one SingleChildScrollView created', (tester) async {
    addTearDown(testBinding.reset);
    await tester.pumpWidget(TestZulipApp());
    await tester.pump();
    final element = tester.element(find.byType(Placeholder));

    showSuggestedActionDialog(context: element,
      title: 'Continue?',
      message: 'Do the thing?',
      actionButtonText: 'Sure');
    await tester.pump();

    check(find.ancestor(of: find.text('Do the thing?'),
      matching: find.byType(SingleChildScrollView))).findsOne();
  }, variant: TargetPlatformVariant.all());

  group('UpgradeWelcomeDialog', () {
    // TODO(#1594): test LegacyUpgradeState and BoolGlobalSetting.upgradeWelcomeDialogShown

    testWidgets('only one SingleChildScrollView created', (tester) async {
      final transitionDurationObserver = TransitionDurationObserver();
      addTearDown(testBinding.reset);

      // Real ZulipApp needed because the show-dialog function calls
      // `await ZulipApp.navigator`.
      await tester.pumpWidget(ZulipApp(navigatorObservers: [transitionDurationObserver]));
      await tester.pump();

      await testBinding.globalStore.settings
        .debugSetLegacyUpgradeState(LegacyUpgradeState.found);

      UpgradeWelcomeDialog.maybeShow();
      await transitionDurationObserver.pumpPastTransition(tester);

      final expectedMessage = 'You’ll find a familiar experience in a faster, sleeker package.';
      check(find.ancestor(of: find.text(expectedMessage),
        matching: find.byType(SingleChildScrollView))).findsOne();
    }, variant: TargetPlatformVariant.all());
  });
}
