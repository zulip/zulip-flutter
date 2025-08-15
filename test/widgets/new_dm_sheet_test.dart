import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/basic.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/app_bar.dart';
import 'package:zulip/widgets/compose_box.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/new_dm_sheet.dart';
import 'package:zulip/widgets/store.dart';
import 'package:zulip/widgets/user.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/test_store.dart';
import '../test_navigation.dart';
import 'finders.dart';
import 'test_app.dart';

late PerAccountStore store;

Future<void> setupSheet(WidgetTester tester, {
  User? selfUser,
  required List<User> users,
  List<int>? mutedUserIds,
}) async {
  addTearDown(testBinding.reset);

  Route<dynamic>? lastPushedRoute;
  final testNavObserver = TestNavigatorObserver()
    ..onPushed = (route, _) => lastPushedRoute = route;

  selfUser ??= eg.selfUser;
  final account = eg.account(user: selfUser);
  await testBinding.globalStore.add(account, eg.initialSnapshot(
    realmUsers: [selfUser, ...users]));
  store = await testBinding.globalStore.perAccount(account.id);
  if (mutedUserIds != null) {
    await store.setMutedUsers(mutedUserIds);
  }

  await tester.pumpWidget(TestZulipApp(
    navigatorObservers: [testNavObserver],
    accountId: account.id,
    child: const HomePage()));
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(ZulipIcons.two_person));
  await tester.pumpAndSettle();

  await tester.tap(find.widgetWithText(GestureDetector, 'New DM'));
  await tester.pump();
  check(lastPushedRoute).isNotNull().isA<ModalBottomSheetRoute<void>>();
  await tester.pump((lastPushedRoute as TransitionRoute).transitionDuration);
}

void main() {
  TestZulipBinding.ensureInitialized();

  final findComposeButton = find.widgetWithText(GestureDetector, 'Compose');
  void checkComposeButtonEnabled(WidgetTester tester, bool expected) {
    final button = tester.widget<GestureDetector>(findComposeButton);
    if (expected) {
      check(button.onTap).isNotNull();
    } else {
      check(button.onTap).isNull();
    }
  }

  Finder findUserTile(User user) =>
    find.ancestor(of: findText(user.fullName, includePlaceholders: false),
      matching: find.byType(InkWell)).first;

  Finder findUserChip(User user) {
    final findAvatar = find.byWidgetPredicate((widget) =>
      widget is Avatar
      && widget.userId == user.userId
      && widget.size == 22);

    return find.ancestor(of: findAvatar, matching: find.byType(GestureDetector));
  }

  testWidgets('shows header with correct buttons', (tester) async {
    await setupSheet(tester, users: []);

    check(find.descendant(
      of: find.byType(NewDmPicker),
      matching: find.text('New DM'))).findsOne();
    check(find.text('Cancel')).findsOne();
    check(findComposeButton).findsOne();

    checkComposeButtonEnabled(tester, false);
  });

  testWidgets('search field has focus when sheet opens', (tester) async {
    await setupSheet(tester, users: []);

    void checkHasFocus() {
      // Some element is focused…
      final focusedElement = tester.binding.focusManager.primaryFocus?.context;
      check(focusedElement).isNotNull();

      // …it's a TextField. Specifically, the search input.
      final focusedTextFieldWidget = focusedElement!
        .findAncestorWidgetOfExactType<TextField>();
      check(focusedTextFieldWidget).isNotNull()
        .decoration.isNotNull()
        .hintText.equals('Add one or more users');
    }

    checkHasFocus(); // It's focused initially.
    await tester.pump(Duration(seconds: 1));
    checkHasFocus(); // Something else doesn't come along and steal the focus.
  });

  group('user filtering', () {
    final testUsers = [
      eg.user(fullName: 'Alice Anderson'),
      eg.user(fullName: 'Bob Brown'),
      eg.user(fullName: 'Charlie Carter'),
      eg.user(fullName: 'Édith Piaf'),
    ];

    testWidgets('shows full list initially', (tester) async {
      await setupSheet(tester, selfUser: testUsers[0], users: testUsers);
      check(findText(includePlaceholders: false, 'Alice Anderson')).findsOne();
      check(findText(includePlaceholders: false, 'Bob Brown')).findsOne();
      check(findText(includePlaceholders: false, 'Charlie Carter')).findsOne();
      check(find.byIcon(ZulipIcons.check_circle_unchecked)).findsExactly(testUsers.length);
      check(find.byIcon(ZulipIcons.check_circle_checked)).findsNothing();
    });

    testWidgets('shows filtered users based on search', (tester) async {
      await setupSheet(tester, users: testUsers);
      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.pump();
      check(findText(includePlaceholders: false, 'Alice Anderson')).findsOne();
      check(findText(includePlaceholders: false, 'Charlie Carter')).findsNothing();
      check(findText(includePlaceholders: false, 'Bob Brown')).findsNothing();
    });

    testWidgets('deactivated users excluded', (tester) async {
      // Omit a deactivated user both before there's a query…
      final deactivatedUser = eg.user(fullName: 'Impostor Charlie', isActive: false);
      await setupSheet(tester, selfUser: testUsers[0],
        users: [...testUsers, deactivatedUser]);
      check(findText(includePlaceholders: false, 'Impostor Charlie')).findsNothing();
      check(findText(includePlaceholders: false, 'Charlie Carter')).findsOne();
      check(find.byIcon(ZulipIcons.check_circle_unchecked)).findsExactly(testUsers.length);

      // … and after a query that would match their name.
      await tester.enterText(find.byType(TextField), 'Charlie');
      await tester.pump();
      check(findText(includePlaceholders: false, 'Impostor Charlie')).findsNothing();
      check(findText(includePlaceholders: false, 'Charlie Carter')).findsOne();
      check(find.byIcon(ZulipIcons.check_circle_unchecked)).findsExactly(1);
    });

    testWidgets('muted users excluded', (tester) async {
      // Omit muted users both before there's a query…
      final mutedUser = eg.user(fullName: 'Someone Muted');
      await setupSheet(tester, selfUser: testUsers[0],
        users: [...testUsers, mutedUser], mutedUserIds: [mutedUser.userId]);
      check(findText(includePlaceholders: false, 'Someone Muted')).findsNothing();
      check(findText(includePlaceholders: false, 'Muted user')).findsNothing();
      check(findText(includePlaceholders: false, 'Alice Anderson')).findsOne();
      check(find.byIcon(ZulipIcons.check_circle_unchecked)).findsExactly(testUsers.length);

      // … and after a query.  One which matches both the user's actual name and
      // the replacement text "Muted user", for good measure.
      await tester.enterText(find.byType(TextField), 'e');
      await tester.pump();
      check(findText(includePlaceholders: false, 'Someone Muted')).findsNothing();
      check(findText(includePlaceholders: false, 'Muted user')).findsNothing();
      check(findText(includePlaceholders: false, 'Alice Anderson')).findsOne();
      check(findText(includePlaceholders: false, 'Charlie Carter')).findsOne();
      check(find.byIcon(ZulipIcons.check_circle_unchecked)).findsExactly(2);
    });

    // TODO test sorting by recent-DMs
    // TODO test that scroll position resets on query change

    testWidgets('search is case-insensitive', (tester) async {
      await setupSheet(tester, users: testUsers);
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.pump();
      check(findText(includePlaceholders: false, 'Alice Anderson')).findsOne();

      await tester.enterText(find.byType(TextField), 'ALICE');
      await tester.pump();
      check(findText(includePlaceholders: false, 'Alice Anderson')).findsOne();
    });

    testWidgets('partial name and last name search handling', (tester) async {
      await setupSheet(tester, users: testUsers);

      await tester.enterText(find.byType(TextField), 'Ali');
      await tester.pump();
      check(findText(includePlaceholders: false, 'Alice Anderson')).findsOne();
      check(findText(includePlaceholders: false, 'Bob Brown')).findsNothing();
      check(findText(includePlaceholders: false, 'Charlie Carter')).findsNothing();

      await tester.enterText(find.byType(TextField), 'Anderson');
      await tester.pump();
      check(findText(includePlaceholders: false, 'Alice Anderson')).findsOne();
      check(findText(includePlaceholders: false, 'Charlie Carter')).findsNothing();
      check(findText(includePlaceholders: false, 'Bob Brown')).findsNothing();

      await tester.enterText(find.byType(TextField), 'son');
      await tester.pump();
      check(findText(includePlaceholders: false, 'Alice Anderson')).findsOne();
      check(findText(includePlaceholders: false, 'Charlie Carter')).findsNothing();
      check(findText(includePlaceholders: false, 'Bob Brown')).findsNothing();
    });

    testWidgets('shows empty state when no users match', (tester) async {
      await setupSheet(tester, users: testUsers);
      await tester.enterText(find.byType(TextField), 'Zebra');
      await tester.pump();
      check(findText(includePlaceholders: false, 'No users found')).findsOne();
      check(findText(includePlaceholders: false, 'Alice Anderson')).findsNothing();
      check(findText(includePlaceholders: false, 'Bob Brown')).findsNothing();
      check(findText(includePlaceholders: false, 'Charlie Carter')).findsNothing();
    });

    testWidgets('search text clears when user is selected', (tester) async {
      final user = eg.user(fullName: 'Test User');
      await setupSheet(tester, users: [user]);

      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pump();
      final textField = tester.widget<TextField>(find.byType(TextField));
      check(textField.controller!.text).equals('Test');

      await tester.tap(findUserTile(user));
      await tester.pump();
      check(textField.controller!.text).isEmpty();
    });
  });

  group('user selection', () {
    void checkUserSelected(WidgetTester tester, User user, bool expected) {
      final icon = tester.widget<Icon>(find.descendant(
        of: findUserTile(user),
        matching: find.byType(Icon)));

      if (expected) {
        check(findUserChip(user)).findsOne();
        check(icon).icon.equals(ZulipIcons.check_circle_checked);
      } else {
        check(findUserChip(user)).findsNothing();
        check(icon).icon.equals(ZulipIcons.check_circle_unchecked);
      }
    }

    testWidgets('tapping user chip deselects the user', (tester) async {
      await setupSheet(tester, users: [eg.otherUser, eg.thirdUser]);

      await tester.tap(findUserTile(eg.otherUser));
      await tester.pump();
      checkUserSelected(tester, eg.otherUser, true);
      await tester.tap(findUserChip(eg.otherUser));
      await tester.pump();
      checkUserSelected(tester, eg.otherUser, false);
    });

    testWidgets('selecting and deselecting a user', (tester) async {
      final user = eg.user(fullName: 'Test User');
      await setupSheet(tester, users: [user]);

      checkUserSelected(tester, user, false);
      checkUserSelected(tester, eg.selfUser, false);
      checkComposeButtonEnabled(tester, false);

      await tester.tap(findUserTile(user));
      await tester.pump();
      checkUserSelected(tester, user, true);
      checkComposeButtonEnabled(tester, true);

      await tester.tap(findUserTile(user));
      await tester.pump();
      checkUserSelected(tester, user, false);
      checkComposeButtonEnabled(tester, false);
    });

    testWidgets('other user selection deselects self user', (tester) async {
      final otherUser = eg.user(fullName: 'Other User');
      await setupSheet(tester, users: [otherUser]);

      await tester.tap(findUserTile(eg.selfUser));
      await tester.pump();
      checkUserSelected(tester, eg.selfUser, true);
      check(findText(includePlaceholders: false, eg.selfUser.fullName)).findsExactly(2);

      await tester.tap(findUserTile(otherUser));
      await tester.pump();
      checkUserSelected(tester, otherUser, true);
      check(find.text(eg.selfUser.fullName)).findsNothing();
    });

    testWidgets('other user selection hides self user', (tester) async {
      final otherUser = eg.user(fullName: 'Other User');
      await setupSheet(tester, users: [otherUser]);

      check(findText(includePlaceholders: false, eg.selfUser.fullName)).findsOne();

      await tester.tap(findUserTile(otherUser));
      await tester.pump();
      check(find.text(eg.selfUser.fullName)).findsNothing();
    });

    testWidgets('can select multiple users', (tester) async {
      final user1 = eg.user(fullName: 'Test User 1');
      final user2 = eg.user(fullName: 'Test User 2');
      await setupSheet(tester, users: [user1, user2]);

      await tester.tap(findUserTile(user1));
      await tester.pump();
      await tester.tap(findUserTile(user2));
      await tester.pump();
      checkUserSelected(tester, user1, true);
      checkUserSelected(tester, user2, true);
    });
  });

  group('User status', () {
    void checkFindsTileStatusEmoji(WidgetTester tester, User user, Finder emojiFinder) {
      final statusEmojiFinder = find.ancestor(of: emojiFinder,
        matching: find.byType(UserStatusEmoji));
      final tileStatusEmojiFinder = find.descendant(of: findUserTile(user),
        matching: statusEmojiFinder);
      check(tester.widget<UserStatusEmoji>(tileStatusEmojiFinder)
        .neverAnimate).isTrue();
      check(tileStatusEmojiFinder).findsOne();
    }

    void checkFindsChipStatusEmoji(WidgetTester tester, User user, Finder emojiFinder) {
      final statusEmojiFinder = find.ancestor(of: emojiFinder,
        matching: find.byType(UserStatusEmoji));
      final chipStatusEmojiFinder = find.descendant(of: findUserChip(user),
        matching: statusEmojiFinder);
      check(tester.widget<UserStatusEmoji>(chipStatusEmojiFinder)
        .neverAnimate).isTrue();
      check(chipStatusEmojiFinder).findsOne();
    }

    testWidgets('emoji & text are set -> emoji is displayed, text is not', (tester) async {
      final user = eg.user();
      await setupSheet(tester, users: [user]);
      await store.changeUserStatus(user.userId, UserStatusChange(
        text: OptionSome('Busy'),
        emoji: OptionSome(StatusEmoji(emojiName: 'working_on_it',
          emojiCode: '1f6e0', reactionType: ReactionType.unicodeEmoji))));
      await tester.pump();

      checkFindsTileStatusEmoji(tester, user, find.text('\u{1f6e0}'));
      check(findUserChip(user)).findsNothing();
      check(find.textContaining('Busy')).findsNothing();

      await tester.tap(findUserTile(user));
      await tester.pump();

      checkFindsTileStatusEmoji(tester, user, find.text('\u{1f6e0}'));
      check(findUserChip(user)).findsOne();
      checkFindsChipStatusEmoji(tester, user, find.text('\u{1f6e0}'));
      check(find.textContaining('Busy')).findsNothing();
    });

    testWidgets('emoji is not set, text is set -> text is not displayed', (tester) async {
      final user = eg.user();
      await setupSheet(tester, users: [user]);
      await store.changeUserStatus(user.userId, UserStatusChange(
        text: OptionSome('Busy'), emoji: OptionNone()));
      await tester.pump();

      check(findUserTile(user)).findsOne();
      check(findUserChip(user)).findsNothing();
      check(find.textContaining('Busy')).findsNothing();

      await tester.tap(findUserTile(user));
      await tester.pump();

      check(findUserTile(user)).findsOne();
      check(findUserChip(user)).findsOne();
      check(find.textContaining('Busy')).findsNothing();
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
        await tester.tap(findUserTile(user));
        await tester.pump();
      }
      await tester.tap(findComposeButton);
      await tester.pumpAndSettle();
      check(find.widgetWithText(ZulipAppBar, expectedAppBarTitle)).findsOne();

      check(find.byType(ComposeBox)).findsOne();
    }

    testWidgets('navigates to self DM', (tester) async {
      await runAndCheck(
        tester,
        users: [eg.selfUser],
        expectedAppBarTitle: 'DMs with yourself');
    });

    testWidgets('navigates to 1:1 DM', (tester) async {
      final user = eg.user(fullName: 'Test User');
      await runAndCheck(
        tester,
        users: [user],
        expectedAppBarTitle: 'DMs with Test User');
    });

    testWidgets('navigates to group DM', (tester) async {
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
}
