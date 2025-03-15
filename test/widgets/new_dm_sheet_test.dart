import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/new_dm_sheet.dart';
import 'package:zulip/widgets/page.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import '../test_navigation.dart';
import 'message_list_checks.dart';
import 'page_checks.dart';
import 'test_app.dart';

Future<void> setupSheet(WidgetTester tester, {
  required List<User> users,
  NavigatorObserver? navigatorObserver,
}) async {
  addTearDown(testBinding.reset);
  await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
  final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
  await store.addUser(eg.selfUser);
  for (final user in users) {
    await store.addUser(user);
  }

  await tester.pumpWidget(TestZulipApp(
    accountId: eg.selfAccount.id,
    navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
    child: const HomePage()));
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(ZulipIcons.user));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

void main() {
  TestZulipBinding.ensureInitialized();

  group('NewDmSheet', () {
    testWidgets('shows header with correct buttons', (tester) async {
      await setupSheet(tester, users: []);
      check(find.descendant(
        of: find.byType(NewDmPicker),
        matching: find.text('New DM')
      )).findsOne();

      check(find.text('Back')).findsOne();
      check(find.text('Next')).findsOne();
      check(find.byIcon(ZulipIcons.chevron_left)).findsOne();
      check(find.byIcon(ZulipIcons.chevron_right)).findsOne();

      final nextButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Next'));
      check(nextButton.onPressed).isNull();
    });

    testWidgets('shows filtered users based on search', (tester) async {
      final users = [
        eg.user(userId: 1, fullName: 'Alice Anderson'),
        eg.user(userId: 2, fullName: 'Bob Brown'),
        eg.user(userId: 3, fullName: 'Alice Carter'),
      ];
      await setupSheet(tester, users: users);

      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.pump();
      check(find.text('Alice Anderson')).findsOne();
      check(find.text('Alice Carter')).findsOne();
      check(find.text('Bob Brown')).findsNothing();
    });

    testWidgets('can select and unselect users', (tester) async {
      final user = eg.user(userId: 1, fullName: 'Test User');
      await setupSheet(tester, users: [user]);

      check(find.byIcon(Icons.circle_outlined)).findsOne();
      check(find.byIcon(Icons.check_circle)).findsNothing();

      final userTile = find.ancestor(
        of: find.text(user.fullName),
        matching: find.byType(InkWell),
      );

      await tester.tap(userTile);
      await tester.pump();
      check(find.byIcon(Icons.check_circle)).findsOne();
      check(find.byIcon(Icons.circle_outlined)).findsNothing();

      final nextButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Next'));
      check(nextButton.onPressed).isNotNull();

      await tester.tap(userTile);
      await tester.pump();
      check(find.byIcon(Icons.circle_outlined)).findsOne();
      check(find.byIcon(Icons.check_circle)).findsNothing();
    });

    Future<void> runAndCheck(WidgetTester tester, {
      required User user,
      NavigatorObserver? navigatorObserver,
    }) async {
      final pushedRoutes = <Route<dynamic>>[];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);

      await setupSheet(tester,
        users: [user],
        navigatorObserver: testNavObserver);

      final userTile = find.ancestor(
        of: find.text(user.fullName),
        matching: find.byType(InkWell),
      );

      await tester.tap(userTile);
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Next'));

      check(pushedRoutes).last.isA<WidgetRoute>().page
        .isA<MessageListPage>()
        .initNarrow.equals(DmNarrow.withOtherUsers(
          [user.userId],
          selfUserId: eg.selfUser.userId));
    }

    testWidgets('navigates to message list on Next', (tester) async {
      final user = eg.user(userId: 1, fullName: 'Test User');
      await runAndCheck(tester, user: user);
    });
  });
}