import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/log.dart';
import 'package:zulip/model/actions.dart';
import 'package:zulip/model/database.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/page.dart';

import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/store_checks.dart';
import '../model/test_store.dart';
import '../test_navigation.dart';
import 'dialog_checks.dart';
import 'checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('ZulipApp initial navigation', () {
    late List<Route<dynamic>> pushedRoutes = [];

    Future<void> prepare(WidgetTester tester) async {
      addTearDown(testBinding.reset);

      pushedRoutes = [];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
      await tester.pump();
    }

    testWidgets('when no accounts, go to choose account', (tester) async {
      check(testBinding.globalStore).accounts.isEmpty();
      check(testBinding.globalStore).lastVisitedAccount.isNull();
      await prepare(tester);
      check(pushedRoutes).deepEquals(<Condition<Object?>>[
        (it) => it.isA<WidgetRoute>().page.isA<ChooseAccountPage>(),
      ]);
    });

    group('when have accounts', () {
      testWidgets('with account(s) visited, go to home page for the last visited account', (tester) async {
        await testBinding.globalStore.insertAccount(eg.otherAccount.toCompanion(false));
        // We'll need per-account data for the account that a page will be opened
        // for, but not for the other accounts.
        await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
        await testBinding.globalStore.insertAccount(eg.thirdAccount.toCompanion(false));
        check(testBinding.globalStore).lastVisitedAccount.equals(eg.selfAccount);
        await prepare(tester);

        check(pushedRoutes).deepEquals(<Condition<Object?>>[
          (it) => it.isA<MaterialAccountWidgetRoute>()
            ..accountId.equals(eg.selfAccount.id)
            ..page.isA<HomePage>(),
        ]);
      });

      testWidgets('with last visited account logged out, go to choose account', (tester) async {
        await testBinding.globalStore.insertAccount(eg.selfAccount.toCompanion(false));
        await testBinding.globalStore.setLastVisitedAccount(eg.selfAccount.id);
        await testBinding.globalStore.insertAccount(eg.otherAccount.toCompanion(false));
        check(testBinding.globalStore).lastVisitedAccount.equals(eg.selfAccount);
        final future = logOutAccount(testBinding.globalStore, eg.selfAccount.id);
        await tester.pump(TestGlobalStore.removeAccountDuration);
        await future;
        check(testBinding.globalStore).lastVisitedAccount.isNull();
        check(testBinding.globalStore).accounts.isNotEmpty();
        await prepare(tester);

        check(pushedRoutes).deepEquals(<Condition<Object?>>[
          (it) => it.isA<WidgetRoute>().page.isA<ChooseAccountPage>(),
        ]);
      });
    });
  });

  group('_PreventEmptyStack', () {
    late List<Route<void>> pushedRoutes;
    late List<Route<void>> removedRoutes;
    late List<Route<void>> poppedRoutes;

    Future<void> prepare(WidgetTester tester) async {
      addTearDown(testBinding.reset);

      pushedRoutes = [];
      removedRoutes = [];
      poppedRoutes = [];
      final testNavObserver = TestNavigatorObserver();
      testNavObserver.onPushed = (route, prevRoute) => pushedRoutes.add(route);
      testNavObserver.onRemoved = (route, prevRoute) => removedRoutes.add(route);
      testNavObserver.onPopped = (route, prevRoute) => poppedRoutes.add(route);

      await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
      await tester.pump(); // start to load account
      check(pushedRoutes).single.isA<WidgetRoute>().page.isA<HomePage>();
      pushedRoutes.clear();
    }

    testWidgets('push route when removing last route on stack', (tester) async {
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await prepare(tester);
      // The navigator stack should contain only a home page route.

      // Log out, causing the home page to be removed from the stack.
      final future = logOutAccount(testBinding.globalStore, eg.selfAccount.id);
      await tester.pump(TestGlobalStore.removeAccountDuration);
      await future;
      check(testBinding.globalStore.takeDoRemoveAccountCalls())
        .single.equals(eg.selfAccount.id);
      // The choose-account page should appear.
      check(removedRoutes).single.isA<WidgetRoute>().page.isA<HomePage>();
      check(pushedRoutes).single.isA<WidgetRoute>().page.isA<ChooseAccountPage>();
    });

    testWidgets('push route when popping last route on stack', (tester) async {
      // Set up the loading of per-account data to fail.
      await testBinding.globalStore.insertAccount(eg.selfAccount.toCompanion(false));
      await testBinding.globalStore.setLastVisitedAccount(eg.selfAccount.id);
      testBinding.globalStore.loadPerAccountDuration = Duration.zero;
      testBinding.globalStore.loadPerAccountException = eg.apiExceptionUnauthorized();
      await prepare(tester);
      // The navigator stack should contain only a home page route.

      // Await the failed load, causing the home page to be removed
      // and an error dialog pushed in its place.
      await tester.pump(Duration.zero);
      await tester.pump(TestGlobalStore.removeAccountDuration);
      check(testBinding.globalStore.takeDoRemoveAccountCalls())
        .single.equals(eg.selfAccount.id);
      check(removedRoutes).single.isA<WidgetRoute>().page.isA<HomePage>();
      check(poppedRoutes).isEmpty();
      check(pushedRoutes).single.isA<DialogRoute<void>>();
      pushedRoutes.clear();

      // Dismiss the error dialog, causing it to be popped from the stack.
      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: 'Could not connect',
        expectedMessage:
          'Your account at ${eg.selfAccount.realmUrl} could not be authenticated.'
          ' Please try logging in again or use another account.')));
      // The choose-account page should appear, because the error dialog
      // was the only route remaining.
      check(poppedRoutes).single.isA<DialogRoute<void>>();
      check(pushedRoutes).single.isA<WidgetRoute>().page.isA<ChooseAccountPage>();
    });

    testWidgets('do not push route to non-empty navigator stack', (tester) async {
      // Set up the loading of per-account data to fail, but only after a
      // long enough time for the "Try another account" button to appear.
      const loadPerAccountDuration = Duration(seconds: 30);
      assert(loadPerAccountDuration > kTryAnotherAccountWaitPeriod);
      await testBinding.globalStore.insertAccount(eg.selfAccount.toCompanion(false));
      await testBinding.globalStore.setLastVisitedAccount(eg.selfAccount.id);
      testBinding.globalStore.loadPerAccountDuration = loadPerAccountDuration;
      testBinding.globalStore.loadPerAccountException = eg.apiExceptionUnauthorized();
      await prepare(tester);
      // The navigator stack should contain only a home page route.

      // Await the "Try another account" button, and tap it.
      await tester.pump(kTryAnotherAccountWaitPeriod);
      await tester.tap(find.text('Try another account'));
      await tester.pump();
      // The navigator stack should contain the home page route
      // and a choose-account page route.
      check(removedRoutes).isEmpty();
      check(poppedRoutes).isEmpty();
      check(pushedRoutes).single.isA<WidgetRoute>().page.isA<ChooseAccountPage>();
      pushedRoutes.clear();

      // Now await the failed load, causing the home page to be removed
      // and an error dialog pushed, while the choose-account page remains.
      await tester.pump(loadPerAccountDuration);
      await tester.pump(TestGlobalStore.removeAccountDuration);
      check(testBinding.globalStore.takeDoRemoveAccountCalls())
        .single.equals(eg.selfAccount.id);
      check(removedRoutes).single.isA<WidgetRoute>().page.isA<HomePage>();
      check(poppedRoutes).isEmpty();
      check(pushedRoutes).single.isA<DialogRoute<void>>();
      pushedRoutes.clear();
      // The navigator stack should now contain the choose-account page route
      // and the dialog route.

      // Dismiss the error dialog, causing it to be popped from the stack.
      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: 'Could not connect',
        expectedMessage:
          'Your account at ${eg.selfAccount.realmUrl} could not be authenticated.'
          ' Please try logging in again or use another account.')));
      // No routes should be pushed after dismissing the error dialog,
      // because there was already another route remaining on the stack
      // (namely the choose-account page route).
      check(poppedRoutes).single.isA<DialogRoute<void>>();
      check(pushedRoutes).isEmpty();
    });
  });

  group('ChooseAccountPage', () {
    Future<void> setupChooseAccountPage(WidgetTester tester, {
      required List<Account> accounts,
    }) async {
      addTearDown(testBinding.reset);

      for (final account in accounts) {
        await testBinding.globalStore
          .insertAccount(account.toCompanion(false));
      }

      await tester.pumpWidget(const TestZulipApp(
        child: ChooseAccountPage()));

      // global store gets loaded
      await tester.pumpAndSettle();
    }

    List<Account> generateAccounts(int count) {
      return List.generate(count, (i) {
        final id = i+1;
        return eg.account(
          id: id,
          user: eg.user(fullName: 'User $id', email: 'user$id@example'),
          apiKey: 'user${id}apikey',
        );
      });
    }

    Finder findAccount(Account account) => find.text(account.email).hitTestable();

    Finder findButton<T extends ButtonStyleButton>({required String withText}) {
      return find
        .descendant(of: find.bySubtype<T>(), matching: find.text(withText))
        .hitTestable();
    }

    void checkAccountShown(Account account, {required bool expected}) {
      check(findAccount(account).evaluate()).length.equals(expected ? 1 : 0);
    }

    void checkButtonShown<T extends ButtonStyleButton>({
      required String withText,
      required bool expected,
    }) {
      check(findButton<T>(withText: withText).evaluate())
        .length.equals(expected ? 1 : 0);
    }

    testWidgets('accounts list is scrollable when more than a screenful', (tester) async {
      final accounts = generateAccounts(15);
      await setupChooseAccountPage(tester, accounts: accounts);

      // Accounts list is more than a screenful
      //  * First account is shown
      //  * Last account is out of view
      checkAccountShown(accounts.first, expected: true);
      checkAccountShown(accounts.last, expected: false);

      // Button to add an account is visible
      // and not moved offscreen by the long list of accounts
      checkButtonShown(withText: 'Add an account', expected: true);

      // Accounts list is scrollable to the bottom
      await tester.scrollUntilVisible(findAccount(accounts.last), 50);
      checkAccountShown(accounts.last, expected: true);
    });

    testWidgets('with just one account, the layout is centered', (tester) async {
      final account = eg.selfAccount;
      await setupChooseAccountPage(tester, accounts: [account]);

      const buttonText = 'Add an account';
      checkAccountShown(account, expected: true);
      checkButtonShown(withText: buttonText, expected: true);

      final screenHeight =
        (tester.view.physicalSize / tester.view.devicePixelRatio).height;

      check(tester.getRect(findAccount(account)))
        ..top.isGreaterThan(1 / 3 * screenHeight)
        ..bottom.isLessThan(2 / 3 * screenHeight);

      check(tester.getRect(findButton(withText: buttonText)))
        ..top.isGreaterThan(1 / 3 * screenHeight)
        ..bottom.isLessThan(2 / 3 * screenHeight);
    });

    testWidgets('with no accounts, the Add an Account button is centered', (tester) async {
      await setupChooseAccountPage(tester, accounts: []);

      const buttonText = 'Add an account';
      checkButtonShown(withText: buttonText, expected: true);

      final screenHeight =
        (tester.view.physicalSize / tester.view.devicePixelRatio).height;

      check(tester.getRect(findButton(withText: buttonText)))
        ..top.isGreaterThan(1 / 3 * screenHeight)
        ..bottom.isLessThan(2 / 3 * screenHeight);
    });

    testWidgets('choosing an account clears the navigator stack', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await testBinding.globalStore.add(
        eg.otherAccount, eg.initialSnapshot(realmUsers: [eg.otherUser]),
        markLastVisited: false);

      final pushedRoutes = <Route<void>>[];
      final poppedRoutes = <Route<void>>[];
      final testNavObserver = TestNavigatorObserver();
      testNavObserver.onPushed = (route, prevRoute) => pushedRoutes.add(route);
      testNavObserver.onPopped = (route, prevRoute) => poppedRoutes.add(route);
      testNavObserver.onReplaced = (route, prevRoute) {
        poppedRoutes.add(prevRoute!);
        pushedRoutes.add(route!);
      };
      await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
      await tester.pump();

      final navigator = await ZulipApp.navigator;
      unawaited(navigator.push(
        MaterialWidgetRoute(page: const ChooseAccountPage())));
      await tester.pump();
      await tester.pump();

      check(poppedRoutes).isEmpty();
      check(pushedRoutes).deepEquals(<Condition<Object?>>[
        (it) => it.isA<MaterialAccountWidgetRoute>()
          ..accountId.equals(eg.selfAccount.id)
          ..page.isA<HomePage>(),
        (it) => it.isA<WidgetRoute>().page.isA<ChooseAccountPage>()
      ]);
      pushedRoutes.clear();

      await tester.tap(find.text(eg.otherAccount.email));
      await tester.pump();
      check(poppedRoutes).length.equals(2);
      check(pushedRoutes).single.isA<MaterialAccountWidgetRoute>()
        ..accountId.equals(eg.otherAccount.id)
        ..page.isA<HomePage>();
    });

    testWidgets('choosing an account changes the last visited account', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await testBinding.globalStore.add(
        eg.otherAccount, eg.initialSnapshot(realmUsers: [eg.otherUser]),
        markLastVisited: false);

      await tester.pumpWidget(ZulipApp());
      await tester.pump();

      final navigator = await ZulipApp.navigator;
      unawaited(navigator.push(MaterialWidgetRoute(page: const ChooseAccountPage())));
      await tester.pump();
      await tester.pump();

      check(testBinding.globalStore).lastVisitedAccount.equals(eg.selfAccount);
      await tester.tap(find.text(eg.otherAccount.email));
      await tester.pump();
      check(testBinding.globalStore).lastVisitedAccount.equals(eg.otherAccount);
    });

    group('log out', () {
      Future<(Widget, Widget)> prepare(WidgetTester tester, {required Account account}) async {
        await setupChooseAccountPage(tester, accounts: [account]);

        final findThreeDotsButton = find.descendant(
          of: find.widgetWithText(Card, eg.selfAccount.realmUrl.toString()),
          matching: find.byIcon(Icons.adaptive.more));

        await tester.tap(findThreeDotsButton);
        await tester.pump();
        await tester.tap(find.descendant(
          of: find.byType(MenuItemButton), matching: find.text('Log out')));
        await tester.pumpAndSettle(); // TODO just `pump`? But the dialog doesn't appear.
        return checkSuggestedActionDialog(tester,
          expectedTitle: 'Log out?',
          expectedMessage: 'To use this account in the future, you will have to re-enter the URL for your organization and your account information.',
          expectDestructiveActionButton: true,
          expectedActionButtonText: 'Log out');
      }

      testWidgets('user confirms logging out', (tester) async {
        final (actionButton, _) = await prepare(tester, account: eg.selfAccount);
        await tester.tap(find.byWidget(actionButton));
        await tester.pump(TestGlobalStore.removeAccountDuration);
        check(testBinding.globalStore).accounts.isEmpty();
      });

      testWidgets('user cancels logging out', (tester) async {
        final (_, cancelButton) = await prepare(tester, account: eg.selfAccount);
        await tester.tap(find.byWidget(cancelButton));
        await tester.pumpAndSettle();
        check(testBinding.globalStore).accounts.deepEquals([eg.selfAccount]);
      });
    });
  });

  group('scaffoldMessenger', () {
    testWidgets('scaffoldMessenger becomes non-null after startup', (tester) async {
      addTearDown(testBinding.reset);
      await tester.pumpWidget(const ZulipApp());

      check(ZulipApp.scaffoldMessenger).isNull();
      check(ZulipApp.ready).value.isFalse();
      await tester.pump();
      check(ZulipApp.scaffoldMessenger).isNotNull();
      check(ZulipApp.ready).value.isTrue();
    });
  });

  group('error reporting', () {
    Finder findSnackBarByText(String text) => find.descendant(
      of: find.byType(SnackBar),
      matching: find.text(text));

    testWidgets('reportErrorToUserBriefly', (tester) async {
      addTearDown(testBinding.reset);
      await tester.pumpWidget(const ZulipApp());
      const message = 'test error message';

      // Prior to app startup, reportErrorToUserBriefly only logs.
      reportErrorToUserBriefly(message);
      check(ZulipApp.ready).value.isFalse();
      await tester.pump();
      check(findSnackBarByText(message).evaluate()).isEmpty();

      check(ZulipApp.ready).value.isTrue();
      // After app startup, reportErrorToUserBriefly displays a SnackBar.
      reportErrorToUserBriefly(message);
      await tester.pump();
      check(findSnackBarByText(message).evaluate()).single;
      check(find.text('Details').evaluate()).isEmpty();
    });

    testWidgets('reportErrorToUserBriefly with details', (tester) async {
      addTearDown(testBinding.reset);
      await tester.pumpWidget(const ZulipApp());
      const message = 'test error message';
      const details = 'error details';

      // Prior to app startup, reportErrorToUserBriefly only logs.
      reportErrorToUserBriefly(message, details: details);
      check(ZulipApp.ready).value.isFalse();
      await tester.pump();
      check(findSnackBarByText(message).evaluate()).isEmpty();
      checkNoDialog(tester);

      check(ZulipApp.ready).value.isTrue();
      // After app startup, reportErrorToUserBriefly displays a SnackBar.
      reportErrorToUserBriefly(message, details: details);
      await tester.pumpAndSettle();
      check(findSnackBarByText(message).evaluate()).single;
      checkNoDialog(tester);

      // Open the error details dialog.
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      check(findSnackBarByText(message).evaluate()).isEmpty();
      checkErrorDialog(tester, expectedTitle: 'Error', expectedMessage: details);
    });

    Future<void> prepareSnackBarWithDetails(WidgetTester tester, String message, String details) async {
      addTearDown(testBinding.reset);
      await tester.pumpWidget(const ZulipApp());
      await tester.pump();
      check(ZulipApp.ready).value.isTrue();

      reportErrorToUserBriefly(message, details: details);
      await tester.pumpAndSettle();
      check(findSnackBarByText(message).evaluate()).single;
    }

    testWidgets('reportErrorToUserBriefly dismissing SnackBar', (tester) async {
      const message = 'test error message';
      const details = 'error details';
      await prepareSnackBarWithDetails(tester, message, details);

      // Dismissing the SnackBar.
      reportErrorToUserBriefly(null);
      await tester.pumpAndSettle();
      check(findSnackBarByText(message).evaluate()).isEmpty();

      // Verify that the SnackBar would otherwise stay when not dismissed.
      reportErrorToUserBriefly(message, details: details);
      await tester.pumpAndSettle();
      check(findSnackBarByText(message).evaluate()).single;
      await tester.pumpAndSettle();
      check(findSnackBarByText(message).evaluate()).single;
    });

    testWidgets('reportErrorToUserBriefly(null) does not dismiss dialog', (tester) async {
      const message = 'test error message';
      const details = 'error details';
      await prepareSnackBarWithDetails(tester, message, details);

      // Open the error details dialog.
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      check(findSnackBarByText(message).evaluate()).isEmpty();
      checkErrorDialog(tester, expectedTitle: 'Error', expectedMessage: details);

      // The dialog should not get dismissed.
      reportErrorToUserBriefly(null);
      await tester.pumpAndSettle();
      checkErrorDialog(tester, expectedTitle: 'Error', expectedMessage: details);
    });

    testWidgets('reportErrorToUserBriefly(null) does not dismiss unrelated SnackBar', (tester) async {
      const message = 'test error message';
      const details = 'error details';
      await prepareSnackBarWithDetails(tester, message, details);

      // Dismissing the SnackBar.
      reportErrorToUserBriefly(null);
      await tester.pumpAndSettle();
      check(findSnackBarByText(message).evaluate()).isEmpty();

      // Unrelated SnackBars should not be dismissed.
      ZulipApp.scaffoldMessenger!.showSnackBar(
        const SnackBar(content: Text ('unrelated')));
      await tester.pumpAndSettle();
      check(findSnackBarByText('unrelated').evaluate()).single;
      reportErrorToUserBriefly(null);
      await tester.pumpAndSettle();
      check(findSnackBarByText('unrelated').evaluate()).single;
    });

    testWidgets('reportErrorToUserModally', (tester) async {
      addTearDown(testBinding.reset);
      await tester.pumpWidget(const ZulipApp());
      const title = 'test title';
      const message = 'test message';

      // Prior to app startup, reportErrorToUserModally only logs.
      reportErrorToUserModally(title, message: message);
      check(ZulipApp.ready).value.isFalse();
      await tester.pump();
      checkNoDialog(tester);

      check(ZulipApp.ready).value.isTrue();
      // After app startup, reportErrorToUserModally displays an [AlertDialog].
      reportErrorToUserModally(title, message: message);
      await tester.pump();
      checkErrorDialog(tester, expectedTitle: title, expectedMessage: message);
    });
  });
}
