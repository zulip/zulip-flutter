import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/settings.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/dialog.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/message_list.dart';
import '../api/fake_api.dart';
import '../example_data.dart' as eg;
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
        matching: find.byType(SingleChildScrollView),)).findsOne();
    }, variant: TargetPlatformVariant.all(),);
  });

  group('IntroModal', () {
    testWidgets('IntroModal widget displays correctly', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

      const modal = IntroModal(title: 'Test Title', message: 'Test Message');

      await tester.pumpWidget(TestZulipApp(child: modal));
      await tester.pumpAndSettle();

      check(find.text('Test Title')).findsOne();
      check(find.text('Test Message')).findsOne();
      check(find.text('Got it')).findsOne();
    });

    group('showInboxIntroModal', () {
      testWidgets('shows modal on first visit to inbox', (tester) async {
        addTearDown(testBinding.reset);
        await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
        await testBinding.globalStore.settings.setBool(BoolGlobalSetting.inboxIntroModalShown, false);
        
        await tester.pumpWidget(TestZulipApp(
          accountId: eg.selfAccount.id,
          child: const HomePage(),
        ));
        await tester.pump();
        await tester.pumpAndSettle();
        
        check(find.byType(IntroModal)).findsOne();
        check(find.text('Welcome to your inbox!')).findsOne();
        check(testBinding.globalStore.settings.getBool(BoolGlobalSetting.inboxIntroModalShown)).isFalse();
        
        await tester.tap(find.text('Got it'));
        await tester.pumpAndSettle();
        
        check(testBinding.globalStore.settings.getBool(BoolGlobalSetting.inboxIntroModalShown)).isTrue();
      });

      testWidgets('does not show modal on subsequent visits', (tester) async {
        addTearDown(testBinding.reset);
        await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
        await testBinding.globalStore.settings.setBool(BoolGlobalSetting.inboxIntroModalShown, true);
        
        await tester.pumpWidget(TestZulipApp(
          accountId: eg.selfAccount.id,
          child: const HomePage(),
        ));
        await tester.pump();
        await tester.pumpAndSettle();
        
        check(find.byType(IntroModal)).findsNothing();
      });
    });

    group('showCombinedFeedIntroModal', () {
      testWidgets('shows modal on first visit to combined feed', (tester) async {
        addTearDown(testBinding.reset);
        await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
        await testBinding.globalStore.settings.setBool(BoolGlobalSetting.combinedFeedIntroModalShown, false);
        
        final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
        final connection = store.connection as FakeApiConnection;
        connection.prepare(json: eg.newestGetMessagesResult(foundOldest: true, messages: []).toJson());
        
        await tester.pumpWidget(TestZulipApp(
          accountId: eg.selfAccount.id,
          child: MessageListPage(initNarrow: const CombinedFeedNarrow()),
        ));
        await tester.pumpAndSettle();
        
        check(find.byType(IntroModal)).findsOne();
        check(find.text('Welcome to your combined feed!')).findsOne();
        check(testBinding.globalStore.settings.getBool(BoolGlobalSetting.combinedFeedIntroModalShown)).isFalse();
        
        await tester.tap(find.text('Got it'));
        await tester.pumpAndSettle();
        
        check(testBinding.globalStore.settings.getBool(BoolGlobalSetting.combinedFeedIntroModalShown)).isTrue();
      });

      testWidgets('does not show modal on subsequent visits', (tester) async {
        addTearDown(testBinding.reset);
        await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
        await testBinding.globalStore.settings.setBool(BoolGlobalSetting.combinedFeedIntroModalShown, true);
        
        final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
        final connection = store.connection as FakeApiConnection;
        connection.prepare(json: eg.newestGetMessagesResult(foundOldest: true, messages: []).toJson());
        
        await tester.pumpWidget(TestZulipApp(
          accountId: eg.selfAccount.id,
          child: MessageListPage(initNarrow: const CombinedFeedNarrow()),
        ));
        await tester.pumpAndSettle(); 
        check(find.byType(IntroModal)).findsNothing();
      });
    });
  });
}