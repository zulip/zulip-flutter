import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/settings.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/app_bar.dart';
import 'package:zulip/widgets/dialog.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/message_list.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
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

    testWidgets('triggers error haptic feedback', (tester) async {
      await prepare(tester);

      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (methodCall) async {
          calls.add(methodCall);
          return null;
        });
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform, null);
      });

      showErrorDialog(context: context, title: title, message: message);
      await tester.pump();

      check(calls).single.isMethodCall(
          'HapticFeedback.vibrate', arguments: 'HapticFeedbackType.errorNotification');
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

  group('IntroDialog', () {
    late TransitionDurationObserver transitionObserver;
    late PerAccountStore store;
    late FakeApiConnection connection;

    Future<void> prepare(WidgetTester tester, {
      required BoolGlobalSetting setting,
    }) async {
      transitionObserver = TransitionDurationObserver();
      addTearDown(testBinding.reset);

      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      connection = store.connection as FakeApiConnection;
      // Clear the value that TestGlobalStore sets to suppress these dialogs,
      // so that the app's real default for the setting applies.
      await testBinding.globalStore.settings.setBool(setting, null);

      // Real ZulipApp needed because the show-dialog function calls
      // `await ZulipApp.navigator`.
      await tester.pumpWidget(ZulipApp(navigatorObservers: [transitionObserver]));
      await tester.pump();
    }

    void checkOnPage(String title) {
      check(find.descendant(of: find.byType(ZulipAppBar),
        matching: find.text(title))
      ).findsOne();
    }

    void checkDialogShown({required String title, required bool expected}) {
      check(find.byType(IntroDialog)).findsExactly(expected ? 1 : 0);
      check(find.text(title)).findsExactly(expected ? 1 : 0);
    }

    Future<void> dismissDialog(WidgetTester tester) async {
      await tester.tap(find.text('Got it'));
      await transitionObserver.pumpPastTransition(tester);
    }

    testWidgets('inbox: show only on first visit', (tester) async {
      const title = 'Welcome to your inbox!';
      await prepare(tester, setting: .inboxIntroDialogShown);

      // The app starts in the "Inbox" page.
      checkOnPage('Inbox');
      // The dialog appears one frame after the page does.
      await tester.pump();
      checkDialogShown(title: title, expected: true);

      await dismissDialog(tester);
      checkDialogShown(title: title, expected: false);

      // Visit the inbox afresh, as happens on switching to another account.
      // (Switching tabs on the home page wouldn't do, because the home page
      // keeps all its tabs alive.)
      await testBinding.globalStore.add(eg.otherAccount,
        eg.initialSnapshot(realmUsers: [eg.otherUser]));
      final navigator = await ZulipApp.navigator;
      unawaited(navigator.push(HomePage.buildRoute(accountId: eg.otherAccount.id)));
      await transitionObserver.pumpPastTransition(tester);

      checkOnPage('Inbox');

      // A dialog, if any, would appear one frame after the page does.
      await tester.pump();
      checkDialogShown(title: title, expected: false);
    });

    testWidgets('combined feed: show only on first visit', (tester) async {
      const title = 'Welcome to your combined feed!';
      await prepare(tester, setting: .combinedFeedIntroDialogShown);

      Future<void> visitCombinedFeed() async {
        connection.prepare(json: eg.newestGetMessagesResult(
          foundOldest: true, messages: []).toJson());
        await tester.tap(find.text('Feed'));
        await transitionObserver.pumpPastTransition(tester);
        checkOnPage('Combined feed');
      }

      // The app starts in the "Inbox" page.
      checkOnPage('Inbox');

      await visitCombinedFeed();
      checkDialogShown(title: title, expected: true);
      await dismissDialog(tester);
      checkDialogShown(title: title, expected: false);

      // Go back to the "Inbox" page, then visit the combined feed again.
      await tester.pageBack();
      await transitionObserver.pumpPastTransition(tester);
      checkOnPage('Inbox');
      await visitCombinedFeed();
      checkDialogShown(title: title, expected: false);
    });

    testWidgets('combined feed: no show on other message lists', (tester) async {
      await prepare(tester, setting: .combinedFeedIntroDialogShown);
      final channel = eg.stream();
      await store.addStream(channel);
      await store.addSubscription(eg.subscription(channel));

      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true, messages: []).toJson());
      final navigator = await ZulipApp.navigator;
      unawaited(navigator.push(MessageListPage.buildRoute(
        accountId: eg.selfAccount.id,
        narrow: TopicNarrow(channel.streamId, eg.t('some topic')))));
      await transitionObserver.pumpPastTransition(tester);
      checkOnPage('some topic');

      // A dialog, if any, would appear one frame after the page does.
      await tester.pump();
      check(find.byType(IntroDialog)).findsNothing();
    });
  });
}
