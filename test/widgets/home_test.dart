import 'dart:ui';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/actions.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/about_zulip.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/app_bar.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/inbox.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/profile.dart';
import 'package:zulip/widgets/subscription_list.dart';
import 'package:zulip/widgets/theme.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/store_checks.dart';
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import '../test_images.dart';
import '../test_navigation.dart';
import 'checks.dart';
import 'test_app.dart';

void main () {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;

  late Route<dynamic>? topRoute;
  late Route<dynamic>? previousTopRoute;
  late List<Route<dynamic>> pushedRoutes;
  late Route<dynamic>? lastPoppedRoute;

  final testNavObserver = TestNavigatorObserver()
    ..onChangedTop = ((current, previous) {
        topRoute = current;
        previousTopRoute = previous;
      })
    ..onPushed = ((route, prevRoute) => pushedRoutes.add(route))
    ..onPopped = ((route, prevRoute) => lastPoppedRoute = route);

  Future<void> prepare(WidgetTester tester) async {
    addTearDown(testBinding.reset);
    topRoute = null;
    previousTopRoute = null;
    pushedRoutes = [];
    lastPoppedRoute = null;
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    connection = store.connection as FakeApiConnection;
    await store.addUser(eg.selfUser);

    await tester.pumpWidget(TestZulipApp(
      accountId: eg.selfAccount.id,
      navigatorObservers: [testNavObserver],
      child: const HomePage()));
    await tester.pump();
  }

  void checkOnLoadingPage() {
    check(find.byType(CircularProgressIndicator).hitTestable()).findsOne();
    check(find.byType(ChooseAccountPage)).findsNothing();
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

  group('bottom nav navigation', () {
    final findBottomNavSemantics = find.byWidgetPredicate((widget) {
      if (widget is! Semantics) return false;
      return widget.properties.role == SemanticsRole.tab;
    });

    // Finds a widget within the bottom navbar's semantics box subtree.
    Finder findInBottomNav(Finder finder) =>
      find.descendant(of: findBottomNavSemantics, matching: finder);

    testWidgets('preserve states when switching between views', (tester) async {
      await prepare(tester);
      await store.addUser(eg.otherUser);
      await store.addMessage(
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]));
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

      await tester.tap(find.byIcon(ZulipIcons.two_person));
      await tester.pump();
      check(find.descendant(
        of: find.byType(ZulipAppBar),
        matching: find.text('Direct messages'))).findsOne();
    });

    testWidgets("view switches when labels are tapped", (tester) async {
      await prepare(tester);

      check(find.descendant(
        of: find.byType(ZulipAppBar),
        matching: find.text('Inbox'))).findsOne();

      await tester.tap(findInBottomNav(find.text('Channels')));
      await tester.pump();
      check(find.descendant(
        of: find.byType(ZulipAppBar),
        matching: find.text('Channels'))).findsOne();

      await tester.tap(findInBottomNav(find.text('Direct messages')));
      await tester.pump();
      check(find.descendant(
        of: find.byType(ZulipAppBar),
        matching: find.text('Direct messages'))).findsOne();
    });

    testWidgets('combined feed', (tester) async {
      await prepare(tester);
      pushedRoutes.clear();

      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true, messages: []).toJson());
      await tester.tap(find.byIcon(ZulipIcons.message_feed));
      await tester.pump();
      check(pushedRoutes).single.isA<WidgetRoute>().page
        .isA<MessageListPage>()
        .initNarrow.equals(const CombinedFeedNarrow());
      await tester.pump(Duration.zero); // message-list fetch
    });
  });

  group('menu', () {
    final designVariables = DesignVariables.light;

    final inboxMenuIconFinder = find.byIcon(ZulipIcons.inbox);
    final channelsMenuIconFinder = find.byIcon(ZulipIcons.hash_italic);
    final combinedFeedMenuIconFinder = find.byIcon(ZulipIcons.message_feed);

    Future<void> tapOpenMenuAndAwait(WidgetTester tester) async {
      final topRouteBeforePress = topRoute;
      await tester.tap(find.byIcon(ZulipIcons.menu));
      await tester.pump();
      final topRouteAfterPress = topRoute;
      check(topRouteAfterPress).isA<ModalBottomSheetRoute<void>>();
      await tester.pump((topRouteAfterPress as ModalBottomSheetRoute<void>).transitionDuration);

      // This was the only change during the interaction.
      check(topRouteBeforePress).identicalTo(previousTopRoute);

      // We got to the sheet by pushing, not popping or something else.
      check(pushedRoutes.last).identicalTo(topRouteAfterPress);

      check(find.byType(BottomSheet)).findsOne();
    }

    /// Taps the [buttonFinder] button and awaits the bottom sheet's exit.
    ///
    /// Includes a check that the bottom sheet is gone.
    /// Also awaits the transition to a new pushed route, if one is pushed.
    ///
    /// [buttonFinder] will be run only in the bottom sheet's subtree;
    /// it doesn't need its own `find.descendant` logic.
    Future<void> tapButtonAndAwaitTransition(WidgetTester tester, Finder buttonFinder) async {
      final topRouteBeforePress = topRoute;
      check(topRouteBeforePress).isA<ModalBottomSheetRoute<void>>();
      final numPushedRoutesBeforePress = pushedRoutes.length;
      await tester.tap(find.descendant(
        of: find.byType(BottomSheet),
        matching: buttonFinder));
      await tester.pump(Duration.zero);

      final newPushedRoute = pushedRoutes.skip(numPushedRoutesBeforePress)
        .singleOrNull;

      final sheetPopDuration = (topRouteBeforePress as ModalBottomSheetRoute<void>)
        .reverseTransitionDuration;
      // TODO not sure why a 1ms fudge is needed; investigate.
      await tester.pump(sheetPopDuration + Duration(milliseconds: 1));
      check(find.byType(BottomSheet)).findsNothing();

      if (newPushedRoute != null) {
        final pushDuration = (newPushedRoute as TransitionRoute).transitionDuration;
        if (pushDuration > sheetPopDuration) {
          await tester.pump(pushDuration - sheetPopDuration);
        }
      }

      // We dismissed the sheet by popping, not pushing or replacing.
      check(topRouteBeforePress as Route<dynamic>?)
        ..not((it) => it.identicalTo(topRoute))
        ..identicalTo(lastPoppedRoute);
    }

    void checkIconSelected(WidgetTester tester, Finder finder) {
      final widget = tester.widget(find.descendant(
        of: find.byType(BottomSheet),
        matching: finder));
      check(widget).isA<Icon>().color.isNotNull()
        .isSameColorAs(designVariables.iconSelected);
    }

    void checkIconNotSelected(WidgetTester tester, Finder finder) {
      final widget = tester.widget(find.descendant(
        of: find.byType(BottomSheet),
        matching: finder));
      check(widget).isA<Icon>().color.isNotNull()
        .isSameColorAs(designVariables.icon);
    }

    testWidgets('buttons are 44px tall', (tester) async {
      prepareBoringImageHttpClient();
      await prepare(tester);

      await tapOpenMenuAndAwait(tester);
      checkIconSelected(tester, inboxMenuIconFinder);
      checkIconNotSelected(tester, channelsMenuIconFinder);

      final inboxElement = tester.element(
        find.ancestor(of: inboxMenuIconFinder, matching: find.bySubtype<MenuButton>()));
      check((inboxElement.renderObject as RenderBox)).size.height.equals(44);

      final channelsElement = tester.element(
        find.ancestor(of: inboxMenuIconFinder, matching: find.bySubtype<MenuButton>()));
      check((channelsElement.renderObject as RenderBox)).size.height.equals(44);

      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('navigation states reflect on navigation bar menu buttons', (tester) async {
      prepareBoringImageHttpClient();
      await prepare(tester);

      await tapOpenMenuAndAwait(tester);
      checkIconSelected(tester, inboxMenuIconFinder);
      checkIconNotSelected(tester, channelsMenuIconFinder);
      await tapButtonAndAwaitTransition(tester, find.text('Close'));

      await tester.tap(find.byIcon(ZulipIcons.hash_italic));
      await tester.pump();

      await tapOpenMenuAndAwait(tester);
      checkIconNotSelected(tester, inboxMenuIconFinder);
      checkIconSelected(tester, channelsMenuIconFinder);
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('navigation bar menu buttons control navigation states', (tester) async {
      prepareBoringImageHttpClient();
      await prepare(tester);

      await tapOpenMenuAndAwait(tester);
      checkIconSelected(tester, inboxMenuIconFinder);
      checkIconNotSelected(tester, channelsMenuIconFinder);
      check(find.byType(InboxPageBody)).findsOne();
      check(find.byType(SubscriptionListPageBody)).findsNothing();

      await tapButtonAndAwaitTransition(tester, channelsMenuIconFinder);
      check(find.byType(InboxPageBody)).findsNothing();
      check(find.byType(SubscriptionListPageBody)).findsOne();

      await tapOpenMenuAndAwait(tester);
      checkIconNotSelected(tester, inboxMenuIconFinder);
      checkIconSelected(tester, channelsMenuIconFinder);
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('navigation bar menu buttons dismiss the menu', (tester) async {
      prepareBoringImageHttpClient();
      await prepare(tester);
      await tapOpenMenuAndAwait(tester);
      await tapButtonAndAwaitTransition(tester, channelsMenuIconFinder);
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('close button dismisses the menu', (tester) async {
      prepareBoringImageHttpClient();
      await prepare(tester);
      await tapOpenMenuAndAwait(tester);
      await tapButtonAndAwaitTransition(tester, find.text('Close'));
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('menu buttons dismiss the menu', (tester) async {
      prepareBoringImageHttpClient();
      addTearDown(testBinding.reset);
      topRoute = null;
      previousTopRoute = null;
      pushedRoutes = [];
      lastPoppedRoute = null;
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

      await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final connection = store.connection as FakeApiConnection;
      await tester.pump();

      await tapOpenMenuAndAwait(tester);

      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true, messages: [eg.streamMessage()]).toJson());
      await tapButtonAndAwaitTransition(tester, combinedFeedMenuIconFinder);

      // When we go back to the home page, the menu sheet should be gone.
      final topBeforePop = topRoute;
      check(topBeforePop).isNotNull().isA<MaterialAccountWidgetRoute>()
        .page.isA<MessageListPage>().initNarrow.equals(CombinedFeedNarrow());
      (await ZulipApp.navigator).pop();
      await tester.pump((topBeforePop as TransitionRoute).reverseTransitionDuration);

      check(find.byType(BottomSheet)).findsNothing();
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('_MainMenuHeader', (tester) async {
      prepareBoringImageHttpClient();
      await prepare(tester);
      await tapOpenMenuAndAwait(tester);
      await tapButtonAndAwaitTransition(tester, find.byIcon(ZulipIcons.arrow_left_right));
      check(find.byType(ChooseAccountPage)).findsOne();
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('_StarredMessagesButton', (tester) async {
      prepareBoringImageHttpClient();

      final findButton = find.byWidgetPredicate((widget) =>
        widget is MenuButton && widget.icon == ZulipIcons.star);

      await prepare(tester);
      final message = eg.streamMessage();
      await store.addMessage(message);
      await store.handleEvent(UpdateMessageFlagsAddEvent(
        id: 1, flag: MessageFlag.starred, messages: [message.id], all: false));

      await tapOpenMenuAndAwait(tester);
      check(find.descendant(of: findButton, matching: find.text('1'))).findsOne();

      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true,
        messages: [
          Message.fromJson((deepToJson(message) as Map<String, dynamic>)
                              ..['flags'] = ['starred'])
        ]).toJson());
      await tapButtonAndAwaitTransition(tester, findButton);
      check(find.byType(MessageListPage)).findsOne();
      check(find.text('Starred messages')).findsOne();
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('_MyProfileButton', (tester) async {
      prepareBoringImageHttpClient();
      await prepare(tester);
      await tapOpenMenuAndAwait(tester);
      await tapButtonAndAwaitTransition(tester, find.text('My profile'));
      check(find.byType(ProfilePage)).findsOne();
      check(find.text(eg.selfUser.fullName)).findsAny();
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('_AboutZulipButton', (tester) async {
      prepareBoringImageHttpClient();
      await prepare(tester);
      await tapOpenMenuAndAwait(tester);
      await tester.ensureVisible(find.byIcon(ZulipIcons.info));
      await tapButtonAndAwaitTransition(tester, find.byIcon(ZulipIcons.info));
      check(find.byType(AboutZulipPage)).findsOne();
      debugNetworkImageHttpClientProvider = null;
    });
  });

  group('_LoadingPlaceholderPage', () {
    const loadPerAccountDuration = Duration(seconds: 30);
    assert(loadPerAccountDuration > kTryAnotherAccountWaitPeriod);

    void checkOnChooseAccountPage() {
      // Ignore the possible loading page in the background.
      check(find.byType(CircularProgressIndicator).hitTestable()).findsNothing();
      check(find.byType(ChooseAccountPage)).findsOne();
      check(find.byType(HomePage)).findsNothing();
    }

    Future<void> prepare(WidgetTester tester) async {
      addTearDown(testBinding.reset);
      topRoute = null;
      previousTopRoute = null;
      pushedRoutes = [];
      lastPoppedRoute = null;
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await testBinding.globalStore.add(
        eg.otherAccount, eg.initialSnapshot(realmUsers: [eg.otherUser]),
        markLastVisited: false);
      await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
      await tester.pump(Duration.zero); // wait for the loading page
      checkOnLoadingPage();
    }

    Future<void> tapTryAnotherAccount(WidgetTester tester) async {
      final numPushedRoutesBefore = pushedRoutes.length;
      await tester.tap(find.text('Try another account'));
      await tester.pump();
      final pushedRoute = pushedRoutes.skip(numPushedRoutesBefore).single;
      check(pushedRoute).isA<MaterialWidgetRoute>().page.isA<ChooseAccountPage>();
      await tester.pump((pushedRoute as TransitionRoute).transitionDuration);
      checkOnChooseAccountPage();
    }

    Future<void> chooseAccountWithEmail(WidgetTester tester, String email) async {
      lastPoppedRoute = null;
      await tester.tap(find.text(email));
      await tester.pump();
      check(topRoute).isA<MaterialAccountWidgetRoute>().page.isA<HomePage>();
      check(lastPoppedRoute).isA<MaterialWidgetRoute>().page.isA<ChooseAccountPage>();
      final popDuration = (lastPoppedRoute as TransitionRoute).reverseTransitionDuration;
      final pushDuration = (topRoute as TransitionRoute).transitionDuration;
      final animationDuration = popDuration > pushDuration ? popDuration : pushDuration;
      // TODO not sure why a 1ms fudge is needed; investigate.
      await tester.pump(animationDuration + Duration(milliseconds: 1));
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
      await tapTryAnotherAccount(tester);

      lastPoppedRoute = null;
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      check(lastPoppedRoute).isA<MaterialWidgetRoute>().page.isA<ChooseAccountPage>();
      await tester.pump(
        (lastPoppedRoute as TransitionRoute).reverseTransitionDuration
        // TODO not sure why a 1ms fudge is needed; investigate.
        + Duration(milliseconds: 1));
      checkOnLoadingPage();

      await tester.pump(loadPerAccountDuration);
      checkOnHomePage(tester, expectedAccount: eg.selfAccount);
    });

    testWidgets('while loading, choose a different account', (tester) async {
      testBinding.globalStore.loadPerAccountDuration = loadPerAccountDuration;
      await prepare(tester);
      await tester.pump(kTryAnotherAccountWaitPeriod);
      await tapTryAnotherAccount(tester);

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
      await tapTryAnotherAccount(tester);

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
      await testBinding.globalStore.add(thirdAccount, eg.initialSnapshot(
        realmUsers: [eg.thirdUser]));
      await prepare(tester);

      await tester.pump(kTryAnotherAccountWaitPeriod);
      // While still loading the first account, choose a different account.
      await tapTryAnotherAccount(tester);
      await chooseAccountWithEmail(tester, eg.otherAccount.email);
      // User cannot go back because the navigator stack
      // was cleared after choosing an account.
      check(getRouteOf(tester, find.byType(CircularProgressIndicator)))
        .isA<MaterialAccountWidgetRoute>()
          ..isFirst.isTrue()
          ..accountId.equals(eg.otherAccount.id);

      await tester.pump(kTryAnotherAccountWaitPeriod);
      // While still loading the second account, choose a different account.
      await tapTryAnotherAccount(tester);
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
      await tapTryAnotherAccount(tester);

      // Stall while on ChoooseAccountPage so that the account finished loading.
      await tester.pump(loadPerAccountDuration);
      checkOnChooseAccountPage();

      lastPoppedRoute = null;
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      check(lastPoppedRoute).isA<MaterialWidgetRoute>().page.isA<ChooseAccountPage>();
      await tester.pump(
        (lastPoppedRoute as TransitionRoute).reverseTransitionDuration
        // TODO not sure why a 1ms fudge is needed; investigate.
        + Duration(milliseconds: 1));
      checkOnHomePage(tester, expectedAccount: eg.selfAccount);
    });

    testWidgets('after finishing loading, choose the loaded account', (tester) async {
      testBinding.globalStore.loadPerAccountDuration = loadPerAccountDuration;
      await prepare(tester);
      await tester.pump(kTryAnotherAccountWaitPeriod);
      await tapTryAnotherAccount(tester);

      // Stall while on ChoooseAccountPage so that the account finished loading.
      await tester.pump(loadPerAccountDuration);
      checkOnChooseAccountPage();

      // Choosing the already loaded account should result in no loading page.
      lastPoppedRoute = null;
      await tester.tap(find.text(eg.selfAccount.email));
      await tester.pump();
      check(lastPoppedRoute).isA<MaterialWidgetRoute>().page.isA<ChooseAccountPage>();
      await tester.pump(
        (lastPoppedRoute as TransitionRoute).reverseTransitionDuration
        // TODO not sure why a 1ms fudge is needed; investigate.
        + Duration(milliseconds: 1));
      // No additional wait for loadPerAccount.
      checkOnHomePage(tester, expectedAccount: eg.selfAccount);
    });
  });

  testWidgets('logging out while still loading', (tester) async {
    // Regression test for: https://github.com/zulip/zulip-flutter/issues/1219
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    await tester.pumpWidget(const ZulipApp());
    await tester.pump(); // wait for the loading page
    checkOnLoadingPage();

    final future = logOutAccount(testBinding.globalStore, eg.selfAccount.id);
    await tester.pump(TestGlobalStore.removeAccountDuration);
    await future;
    // No error expected from briefly not having
    // access to the account being logged out.
    check(testBinding.globalStore).accountIds.isEmpty();
  });

  testWidgets('logging out after fully loaded', (tester) async {
    // Regression test for: https://github.com/zulip/zulip-flutter/issues/1219
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    await tester.pumpWidget(const ZulipApp());
    await tester.pump(); // wait for the loading page
    await tester.pump(); // wait for store
    checkOnHomePage(tester, expectedAccount: eg.selfAccount);

    final future = logOutAccount(testBinding.globalStore, eg.selfAccount.id);
    await tester.pump(TestGlobalStore.removeAccountDuration);
    await future;
    // No error expected from briefly not having
    // access to the account being logged out.
    check(testBinding.globalStore).accountIds.isEmpty();
  });

  // TODO end-to-end widget test that checks the error dialog when connecting
  //   to an ancient server:
  //     https://github.com/zulip/zulip-flutter/pull/1410#discussion_r1999991512
}
