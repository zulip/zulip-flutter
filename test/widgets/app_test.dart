import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/log.dart';
import 'package:zulip/model/database.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/inbox.dart';
import 'package:zulip/widgets/page.dart';

import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../test_navigation.dart';
import 'dialog_checks.dart';
import 'page_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('ZulipApp initial navigation', () {
    late List<Route<dynamic>> pushedRoutes = [];

    Future<List<Route<dynamic>>> initialRoutes(WidgetTester tester) async {
      pushedRoutes = [];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
      await tester.pump();
      return pushedRoutes;
    }

    testWidgets('when no accounts, go to choose account', (tester) async {
      addTearDown(testBinding.reset);
      check(await initialRoutes(tester)).deepEquals(<Condition<Object?>>[
        (it) => it.isA<WidgetRoute>().page.isA<ChooseAccountPage>(),
      ]);
    });

    testWidgets('when have accounts, go to inbox for first account', (tester) async {
      addTearDown(testBinding.reset);

      // We'll need per-account data for the account that a page will be opened
      // for, but not for the other account.
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await testBinding.globalStore.insertAccount(eg.otherAccount.toCompanion(false));

      check(await initialRoutes(tester)).deepEquals(<Condition<Object?>>[
        (it) => it.isA<WidgetRoute>().page.isA<ChooseAccountPage>(),
        (it) => it.isA<MaterialAccountWidgetRoute>()
          ..accountId.equals(eg.selfAccount.id)
          ..page.isA<HomePage>(),
        (it) => it.isA<MaterialAccountWidgetRoute>()
          ..accountId.equals(eg.selfAccount.id)
          ..page.isA<InboxPage>(),
      ]);
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
      check(find.byType(AlertDialog).evaluate()).isEmpty();

      check(ZulipApp.ready).value.isTrue();
      // After app startup, reportErrorToUserBriefly displays a SnackBar.
      reportErrorToUserBriefly(message, details: details);
      await tester.pumpAndSettle();
      check(findSnackBarByText(message).evaluate()).single;
      check(find.byType(AlertDialog).evaluate()).isEmpty();

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

    testWidgets('reportErrorToUser dismissing SnackBar', (tester) async {
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
  });
}
