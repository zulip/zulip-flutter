import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/about_zulip.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/app_bar.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/inbox.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/profile.dart';
import 'package:zulip/widgets/subscription_list.dart';
import 'package:zulip/widgets/theme.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/test_store.dart';
import 'page_checks.dart';
import 'test_app.dart';

void main () {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;

  Future<void> prepare(WidgetTester tester) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

    await store.addUsers([eg.selfUser, eg.otherUser]);
    final stream = eg.stream();
    await store.addStream(stream);
    await store.addSubscription(eg.subscription(stream));

    await tester.pumpWidget(TestZulipApp(
      accountId: eg.selfAccount.id,
      child: const HomePage()));
    await tester.pump();
  }

  group('bottom nav navigation', () {
    testWidgets('preserve states when switching between views', (tester) async {
      await prepare(tester);
      await store.handleEvent(MessageEvent(
        id: 0, message: eg.dmMessage(from: eg.otherUser, to: [eg.selfUser])));
      await tester.pump();

      check(find.byIcon(ZulipIcons.arrow_down)).findsExactly(2);
      check(find.byIcon(ZulipIcons.arrow_right)).findsNothing();

      // Collapsing the header updates inbox's internal state.
      await tester.tap(find.byIcon(ZulipIcons.arrow_down).first);
      await tester.pump();
      check(find.byIcon(ZulipIcons.arrow_down)).findsNothing();
      check(find.byIcon(ZulipIcons.arrow_right)).findsExactly(2);

      // Switch to channels view.
      await tester.tap(find.byIcon(ZulipIcons.hash_italic));
      await tester.pump();
      check(find.byIcon(ZulipIcons.arrow_down)).findsNothing();
      check(find.byIcon(ZulipIcons.arrow_right)).findsNothing();

      // The header should remain collapsed when we return to the inbox.
      await tester.tap(find.byIcon(ZulipIcons.inbox));
      await tester.pump();
      check(find.byIcon(ZulipIcons.arrow_down)).findsNothing();
      check(find.byIcon(ZulipIcons.arrow_right)).findsExactly(2);
    });

    testWidgets('update app bar title when switching between views', (tester) async {
      await prepare(tester);

      check(find.descendant(
        of: find.byType(ZulipAppBar),
        matching: find.text('Inbox'))).findsOne();

      await tester.tap(find.byIcon(ZulipIcons.hash_italic));
      await tester.pump();
      check(find.descendant(
        of: find.byType(ZulipAppBar),
        matching: find.text('Channels'))).findsOne();

      await tester.tap(find.byIcon(ZulipIcons.user));
      await tester.pump();
      check(find.descendant(
        of: find.byType(ZulipAppBar),
        matching: find.text('Direct messages'))).findsOne();
    });
  });

  group('menu', () {
    final designVariables = DesignVariables.light();

    final inboxMenuIconFinder = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byIcon(ZulipIcons.inbox));
    final channelsMenuIconFinder = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byIcon(ZulipIcons.hash_italic));
    final combinedFeedMenuIconFinder = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byIcon(ZulipIcons.message_feed));

    Future<void> tapOpenMenu(WidgetTester tester) async {
      await tester.tap(find.byIcon(ZulipIcons.menu));
      await tester.pump(Duration.zero); // tap the button
      await tester.pump(const Duration(milliseconds: 250)); // wait for animation
      check(find.byType(BottomSheet)).findsOne();
    }

    void checkIconSelected(WidgetTester tester, Finder finder) {
      check(tester.widget(finder)).isA<Icon>().color.isNotNull()
        .isSameColorAs(designVariables.iconSelected);
    }

    void checkIconNotSelected(WidgetTester tester, Finder finder) {
      check(tester.widget(finder)).isA<Icon>().color.isNotNull()
        .isSameColorAs(designVariables.icon);
    }

    testWidgets('navigation states reflect on navigation bar menu buttons', (tester) async {
      await prepare(tester);

      await tapOpenMenu(tester);
      checkIconSelected(tester, inboxMenuIconFinder);
      checkIconNotSelected(tester, channelsMenuIconFinder);
      await tester.tap(find.text('Cancel'));
      await tester.pump(Duration.zero); // tap the button
      await tester.pump(const Duration(milliseconds: 250)); // wait for animation

      await tester.tap(find.byIcon(ZulipIcons.hash_italic));
      await tester.pump();

      await tapOpenMenu(tester);
      checkIconNotSelected(tester, inboxMenuIconFinder);
      checkIconSelected(tester, channelsMenuIconFinder);
    });

    testWidgets('navigation bar menu buttons control navigation states', (tester) async {
      await prepare(tester);

      await tapOpenMenu(tester);
      checkIconSelected(tester, inboxMenuIconFinder);
      checkIconNotSelected(tester, channelsMenuIconFinder);
      check(find.byType(InboxPageBody)).findsOne();
      check(find.byType(SubscriptionListPageBody)).findsNothing();

      await tester.tap(channelsMenuIconFinder);
      await tester.pump(Duration.zero); // tap the button
      await tester.pump(const Duration(milliseconds: 250)); // wait for animation
      check(find.byType(BottomSheet)).findsNothing();
      check(find.byType(InboxPageBody)).findsNothing();
      check(find.byType(SubscriptionListPageBody)).findsOne();

      await tapOpenMenu(tester);
      checkIconNotSelected(tester, inboxMenuIconFinder);
      checkIconSelected(tester, channelsMenuIconFinder);
    });

    testWidgets('navigation bar menu buttons dismiss the menu', (tester) async {
      await prepare(tester);
      await tapOpenMenu(tester);

      await tester.tap(channelsMenuIconFinder);
      await tester.pump(Duration.zero); // tap the button
      await tester.pump(const Duration(milliseconds: 250)); // wait for animation
      check(find.byType(BottomSheet)).findsNothing();
    });

    testWidgets('cancel button dismisses the menu', (tester) async {
      await prepare(tester);
      await tapOpenMenu(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pump(Duration.zero); // tap the button
      await tester.pump(const Duration(milliseconds: 250)); // wait for animation
      check(find.byType(BottomSheet)).findsNothing();
    });

    testWidgets('menu buttons dismiss the menu', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

      await tester.pumpWidget(const ZulipApp());
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final connection = store.connection as FakeApiConnection;
      await tester.pump();

      await tapOpenMenu(tester);

      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true, messages: [eg.streamMessage()]).toJson());
      await tester.tap(combinedFeedMenuIconFinder);
      await tester.pump(Duration.zero); // tap the button
      await tester.pump(const Duration(milliseconds: 250)); // wait for animation

      // When we go back to the home page, the menu sheet should be gone.
      (await ZulipApp.navigator).pop();
      await tester.pump(const Duration(milliseconds: 350)); // wait for pop animation
      check(find.byType(BottomSheet)).findsNothing();
    });

    testWidgets('_MyProfileButton', (tester) async {
      await prepare(tester);
      await tapOpenMenu(tester);

      await tester.tap(find.text('My profile'));
      await tester.pump(Duration.zero); // tap the button
      await tester.pump(const Duration(milliseconds: 250)); // wait for animation
      check(find.byType(ProfilePage)).findsOne();
      check(find.text(eg.selfUser.fullName)).findsAny();
    });

    testWidgets('_AboutZulipButton', (tester) async {
      await prepare(tester);
      await tapOpenMenu(tester);

      await tester.tap(find.byIcon(ZulipIcons.info));
      await tester.pump(Duration.zero); // tap the button
      await tester.pump(const Duration(milliseconds: 250)); // wait for animation
      check(find.byType(AboutZulipPage)).findsOne();
    });
  });

  group('_LoadingPlaceholderPage', () {
    const loadPerAccountDuration = Duration(seconds: 30);
    assert(loadPerAccountDuration > kTryAnotherAccountWaitPeriod);

    void checkOnLoadingPage() {
      check(find.byType(CircularProgressIndicator).hitTestable()).findsOne();
      check(find.byType(ChooseAccountPage)).findsNothing();
      check(find.byType(HomePage)).findsNothing();
    }

    void checkOnChooseAccountPage() {
      // Ignore the possible loading page in the background.
      check(find.byType(CircularProgressIndicator).hitTestable()).findsNothing();
      check(find.byType(ChooseAccountPage)).findsOne();
      check(find.byType(HomePage)).findsNothing();
    }

    ModalRoute<void>? getRouteOf(WidgetTester tester, Finder finder) =>
      ModalRoute.of(tester.element(finder));

    void checkOnHomePage(WidgetTester tester, {required Account expectedAccount}) {
      check(find.byType(CircularProgressIndicator)).findsNothing();
      check(find.byType(ChooseAccountPage)).findsNothing();
      check(find.byType(HomePage).hitTestable()).findsOne();
      check(getRouteOf(tester, find.byType(HomePage)))
        .isA<MaterialAccountWidgetRoute>().accountId.equals(expectedAccount.id);
    }

    Future<void> prepare(WidgetTester tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await testBinding.globalStore.add(eg.otherAccount, eg.initialSnapshot());
      await tester.pumpWidget(const ZulipApp());
      await tester.pump(Duration.zero); // wait for the loading page
      checkOnLoadingPage();
    }

    Future<void> tapChooseAccount(WidgetTester tester) async {
      await tester.tap(find.text('Try another account'));
      await tester.pump(Duration.zero); // tap the button
      await tester.pump(const Duration(milliseconds: 250)); // wait for animation
      checkOnChooseAccountPage();
    }

    Future<void> chooseAccountWithEmail(WidgetTester tester, String email) async {
      await tester.tap(find.text(email));
      await tester.pump(Duration.zero); // tap the button
      await tester.pump(const Duration(milliseconds: 350)); // wait for push & pop animations
      checkOnLoadingPage();
    }

    testWidgets('smoke', (tester) async {
      addTearDown(testBinding.reset);
      testBinding.globalStore.loadPerAccountDuration = loadPerAccountDuration;
      await prepare(tester);
      await tester.pump(loadPerAccountDuration);
      checkOnHomePage(tester, expectedAccount: eg.selfAccount);
    });

    testWidgets('"Try another account" button appears after timeout', (tester) async {
      addTearDown(testBinding.reset);
      testBinding.globalStore.loadPerAccountDuration = loadPerAccountDuration;
      await prepare(tester);
      checkOnLoadingPage();
      check(find.text('Try another account').hitTestable()).findsNothing();

      await tester.pump(kTryAnotherAccountWaitPeriod);
      checkOnLoadingPage();
      check(find.text('Try another account').hitTestable()).findsOne();

      await tester.pump(loadPerAccountDuration);
      checkOnHomePage(tester, expectedAccount: eg.selfAccount);
    });

    testWidgets('while loading, go back from ChooseAccountPage', (tester) async {
      testBinding.globalStore.loadPerAccountDuration = loadPerAccountDuration;
      await prepare(tester);
      await tester.pump(kTryAnotherAccountWaitPeriod);
      await tapChooseAccount(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pump(Duration.zero); // tap the button
      await tester.pump(const Duration(milliseconds: 350)); // wait for pop animation
      checkOnLoadingPage();

      await tester.pump(loadPerAccountDuration);
      checkOnHomePage(tester, expectedAccount: eg.selfAccount);
    });

    testWidgets('while loading, choose a different account', (tester) async {
      testBinding.globalStore.loadPerAccountDuration = loadPerAccountDuration;
      await prepare(tester);
      await tester.pump(kTryAnotherAccountWaitPeriod);
      await tapChooseAccount(tester);

      testBinding.globalStore.loadPerAccountDuration = loadPerAccountDuration * 2;
      await chooseAccountWithEmail(tester, eg.otherAccount.email);

      await tester.pump(loadPerAccountDuration);
      // The second loadPerAccount is still pending.
      checkOnLoadingPage();

      await tester.pump(loadPerAccountDuration);
      // The second loadPerAccount finished.
      checkOnHomePage(tester, expectedAccount: eg.otherAccount);
    });

    testWidgets('while loading, choosing an account disallows going back', (tester) async {
      testBinding.globalStore.loadPerAccountDuration = loadPerAccountDuration;
      await prepare(tester);
      await tester.pump(kTryAnotherAccountWaitPeriod);
      await tapChooseAccount(tester);

      // While still loading, choose a different account.
      await chooseAccountWithEmail(tester, eg.otherAccount.email);

      // User cannot go back because the navigator stack
      // was cleared after choosing an account.
      check(getRouteOf(tester, find.byType(CircularProgressIndicator)))
        .isNotNull().isFirst.isTrue();

      await tester.pump(loadPerAccountDuration); // wait for loadPerAccount
      checkOnHomePage(tester, expectedAccount: eg.otherAccount);
    });

    testWidgets('while loading, go to nested levels of ChooseAccountPage', (tester) async {
      testBinding.globalStore.loadPerAccountDuration = loadPerAccountDuration;
      final thirdAccount = eg.account(user: eg.thirdUser);
      await testBinding.globalStore.add(thirdAccount, eg.initialSnapshot());
      await prepare(tester);

      await tester.pump(kTryAnotherAccountWaitPeriod);
      // While still loading the first account, choose a different account.
      await tapChooseAccount(tester);
      await chooseAccountWithEmail(tester, eg.otherAccount.email);
      // User cannot go back because the navigator stack
      // was cleared after choosing an account.
      check(getRouteOf(tester, find.byType(CircularProgressIndicator)))
        .isA<MaterialAccountWidgetRoute>()
          ..isFirst.isTrue()
          ..accountId.equals(eg.otherAccount.id);

      await tester.pump(kTryAnotherAccountWaitPeriod);
      // While still loading the second account, choose a different account.
      await tapChooseAccount(tester);
      await chooseAccountWithEmail(tester, thirdAccount.email);
      // User cannot go back because the navigator stack
      // was cleared after choosing an account.
      check(getRouteOf(tester, find.byType(CircularProgressIndicator)))
        .isA<MaterialAccountWidgetRoute>()
          ..isFirst.isTrue()
          ..accountId.equals(thirdAccount.id);

      await tester.pump(loadPerAccountDuration); // wait for loadPerAccount
      checkOnHomePage(tester, expectedAccount: thirdAccount);
    });

    testWidgets('after finishing loading, go back from ChooseAccountPage', (tester) async {
      testBinding.globalStore.loadPerAccountDuration = loadPerAccountDuration;
      await prepare(tester);
      await tester.pump(kTryAnotherAccountWaitPeriod);
      await tapChooseAccount(tester);

      // Stall while on ChoooseAccountPage so that the account finished loading.
      await tester.pump(loadPerAccountDuration);
      checkOnChooseAccountPage();

      await tester.tap(find.byType(BackButton));
      await tester.pump(Duration.zero); // tap the button
      await tester.pump(const Duration(milliseconds: 350)); // wait for pop animation
      checkOnHomePage(tester, expectedAccount: eg.selfAccount);
    });

    testWidgets('after finishing loading, choose the loaded account', (tester) async {
      testBinding.globalStore.loadPerAccountDuration = loadPerAccountDuration;
      await prepare(tester);
      await tester.pump(kTryAnotherAccountWaitPeriod);
      await tapChooseAccount(tester);

      // Stall while on ChoooseAccountPage so that the account finished loading.
      await tester.pump(loadPerAccountDuration);
      checkOnChooseAccountPage();

      // Choosing the already loaded account should result in no loading page.
      await tester.tap(find.text(eg.selfAccount.email));
      await tester.pump(Duration.zero); // tap the button
      await tester.pump(const Duration(milliseconds: 350)); // wait for push & pop animations
      // No additional wait for loadPerAccount.
      checkOnHomePage(tester, expectedAccount: eg.selfAccount);
    });
  });
}
