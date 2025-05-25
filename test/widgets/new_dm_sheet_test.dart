import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/widgets/app_bar.dart';
import 'package:zulip/widgets/compose_box.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/new_dm_sheet.dart';
import 'package:zulip/widgets/store.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import 'test_app.dart';

Future<void> setupSheet(WidgetTester tester, {
  required List<User> users,
}) async {
  addTearDown(testBinding.reset);
  await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
  final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
  await store.addUsers(users);

  await tester.pumpWidget(TestZulipApp(
    accountId: eg.selfAccount.id,
    child: const HomePage()));
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(ZulipIcons.user));
  await tester.pumpAndSettle();

  final fab = find.ancestor(
    of: find.text("New DM"),
    matching: find.byType(InkWell));
  await tester.tap(fab);
  await tester.pumpAndSettle();
}

void main() {
  TestZulipBinding.ensureInitialized();

  group('NewDmSheet', () {
    testWidgets('shows header with correct buttons', (tester) async {
      await setupSheet(tester, users: []);

      check(find.descendant(
        of: find.byType(NewDmPicker),
        matching: find.text('New DM'))).findsOne();
      check(find.text('Back')).findsOne();
      check(find.text('Next')).findsOne();
      check(find.byIcon(ZulipIcons.chevron_left)).findsOne();
      check(find.byIcon(ZulipIcons.chevron_right)).findsOne();

      final nextButton = tester.widget<GestureDetector>(
        find.widgetWithText(GestureDetector, 'Next'));
      check(nextButton.onTap).isNull();
    });

    group('user filtering', () {
      final testUsers = [
        eg.user(fullName: 'Alice Anderson'),
        eg.user(fullName: 'Bob Brown'),
        eg.user(fullName: 'Charlie Carter'),
      ];

      testWidgets('shows all users initially', (tester) async {
        await setupSheet(tester, users: testUsers);
        check(find.text('Alice Anderson')).findsOne();
        check(find.text('Bob Brown')).findsOne();
        check(find.text('Charlie Carter')).findsOne();
      });

      testWidgets('shows filtered users based on search', (tester) async {
        await setupSheet(tester, users: testUsers);
        await tester.enterText(find.byType(TextField), 'Alice');
        await tester.pump();
        check(find.text('Alice Anderson')).findsOne();
        check(find.text('Charlie Carter')).findsNothing();
        check(find.text('Bob Brown')).findsNothing();
      });

      testWidgets('search is case-insensitive', (tester) async {
        await setupSheet(tester, users: testUsers);
        await tester.enterText(find.byType(TextField), 'alice');
        await tester.pump();
        check(find.text('Alice Anderson')).findsOne();

        await tester.enterText(find.byType(TextField), 'ALICE');
        await tester.pump();
        check(find.text('Alice Anderson')).findsOne();
      });

      testWidgets('partial name and last name search handling', (tester) async {
        await setupSheet(tester, users: testUsers);

        await tester.enterText(find.byType(TextField), 'Ali');
        await tester.pump();
        check(find.text('Alice Anderson')).findsOne();
        check(find.text('Bob Brown')).findsNothing();
        check(find.text('Charlie Carter')).findsNothing();

        await tester.enterText(find.byType(TextField), 'Anderson');
        await tester.pump();
        check(find.text('Alice Anderson')).findsOne();
        check(find.text('Charlie Carter')).findsNothing();
        check(find.text('Bob Brown')).findsNothing();

        await tester.enterText(find.byType(TextField), 'son');
        await tester.pump();
        check(find.text('Alice Anderson')).findsOne();
        check(find.text('Charlie Carter')).findsNothing();
        check(find.text('Bob Brown')).findsNothing();
      });

      testWidgets('shows empty state when no users match', (tester) async {
        await setupSheet(tester, users: testUsers);
        await tester.enterText(find.byType(TextField), 'Zebra');
        await tester.pump();
        check(find.text('No users found')).findsOne();
        check(find.text('Alice Anderson')).findsNothing();
        check(find.text('Bob Brown')).findsNothing();
        check(find.text('Charlie Carter')).findsNothing();
      });
    });

    group('user selection', () {
      testWidgets('selecting and deselecting a user', (tester) async {
        final user = eg.user(fullName: 'Test User');
        final userTileFinder = find.ancestor(
          of: find.text(user.fullName),
          matching: find.byType(InkWell));
        await setupSheet(tester, users: [eg.selfUser, user]);

        var nextButton = tester.widget<GestureDetector>(
          find.widgetWithText(GestureDetector, 'Next'));
        check(find.byIcon(Icons.circle_outlined)).findsExactly(2);
        check(find.byIcon(Icons.check_circle)).findsNothing();
        check(nextButton.onTap).isNull();

        await tester.tap(userTileFinder);
        await tester.pump();
        check(find.byIcon(Icons.check_circle)).findsOne();
        nextButton = tester.widget<GestureDetector>(
          find.widgetWithText(GestureDetector, 'Next'));
        check(nextButton.onTap).isNotNull();

        await tester.tap(userTileFinder);
        await tester.pump();
        nextButton = tester.widget<GestureDetector>(
          find.widgetWithText(GestureDetector, 'Next'));
        check(find.byIcon(Icons.circle_outlined)).findsExactly(2);
        check(nextButton.onTap).isNull();
      });

      testWidgets('other user selection deselects self user', (tester) async {
        final otherUser = eg.user(fullName: 'Other User');
        final otherUserTileFinder = find.ancestor(
          of: find.text(otherUser.fullName),
          matching: find.byType(InkWell));
        final selfUserTileFinder = find.ancestor(
          of: find.text(eg.selfUser.fullName),
          matching: find.byType(InkWell));
        await setupSheet(tester, users: [eg.selfUser, otherUser]);

        await tester.tap(selfUserTileFinder);
        await tester.pump();
        check(find.descendant(
          of: selfUserTileFinder,
          matching: find.byIcon(Icons.check_circle))).findsOne();
        check(find.text(eg.selfUser.fullName)).findsExactly(2);

        await tester.tap(otherUserTileFinder);
        await tester.pump();
        check(find.descendant(
          of: otherUserTileFinder,
          matching: find.byIcon(Icons.check_circle))).findsOne();
        check(find.text(eg.selfUser.fullName)).findsNothing();
      });

      testWidgets('other user selection hides self user', (tester) async {
        final otherUser = eg.user(fullName: 'Other User');
        final otherUserTileFinder = find.ancestor(
          of: find.text(otherUser.fullName),
          matching: find.byType(InkWell));
        await setupSheet(tester, users: [eg.selfUser, otherUser]);

        check(find.text(eg.selfUser.fullName)).findsOne();

        await tester.tap(otherUserTileFinder);
        await tester.pump();
        check(find.text(eg.selfUser.fullName)).findsNothing();
      });

      testWidgets('can select multiple users', (tester) async {
        final user1 = eg.user(fullName: 'Test User 1');
        final user2 = eg.user(fullName: 'Test User 2');
        await setupSheet(tester, users: [user1, user2]);

        final userTile1 = find.ancestor(
          of: find.text(user1.fullName),
          matching: find.byType(InkWell));
        final userTile2 = find.ancestor(
          of: find.text(user2.fullName),
          matching: find.byType(InkWell));

        await tester.tap(userTile1);
        await tester.pump();
        await tester.tap(userTile2);
        await tester.pump();
        check(find.byIcon(Icons.check_circle)).findsExactly(2);
      });
    });

    group('navigation to DM Narrow', () {
      Future<void> runAndCheck(WidgetTester tester, {
        required List<User> users,
        required String expectedAppBarTitle,
      }) async {
        await setupSheet(tester, users: users);

        final context = tester.element(find.byType(NewDmPicker));
        final store = PerAccountStoreWidget.of(context);
        final connection = store.connection as FakeApiConnection;

        connection.prepare(
          json: eg.newestGetMessagesResult(foundOldest: true, messages: []).toJson());
        for (final user in users) {
          final userTile = find.ancestor(
            of: find.text(user.fullName),
            matching: find.byType(InkWell));
          await tester.tap(userTile);
          await tester.pump();
        }
        await tester.tap(find.widgetWithText(GestureDetector, 'Next'));
        await tester.pumpAndSettle();
        check(find.descendant(
          of: find.byType(ZulipAppBar),
          matching: find.text(expectedAppBarTitle))).findsOne();

        check(find.byType(ComposeBox)).findsOne();
      }

      testWidgets('navigates to self DM on Next', (tester) async {
        await runAndCheck(
          tester,
          users: [eg.selfUser],
          expectedAppBarTitle: 'DMs with yourself');
      });

      testWidgets('navigates to 1:1 DM on Next', (tester) async {
        final user = eg.user(fullName: 'Test User');
        await runAndCheck(
          tester,
          users: [user],
          expectedAppBarTitle: 'DMs with Test User');
      });

      testWidgets('navigates to group DM on Next', (tester) async {
        final users = [
          eg.user(fullName: 'User 1'),
          eg.user(fullName: 'User 2'),
          eg.user(fullName: 'User 3'),
        ];
        await runAndCheck(
          tester,
          users: users,
          expectedAppBarTitle: 'DMs with User 1, User 2, User 3');
      });
    });
  });
}
