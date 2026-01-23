import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/basic.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/image.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/new_dm_sheet.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/recent_dm_conversations.dart';
import 'package:zulip/widgets/user.dart';

import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/test_store.dart';
import '../test_navigation.dart';
import 'checks.dart';
import 'finders.dart';
import 'test_app.dart';

late PerAccountStore store;

Future<void> setupPage(WidgetTester tester, {
  required List<DmMessage> dmMessages,
  required List<User> users,
  User? selfUser,
  List<int>? mutedUserIds,
  NavigatorObserver? navigatorObserver,
}) async {
  addTearDown(testBinding.reset);

  selfUser ??= eg.selfUser;
  final selfAccount = eg.account(user: selfUser);
  await testBinding.globalStore.add(selfAccount, eg.initialSnapshot(
    realmUsers: [selfUser, ...users]));
  store = await testBinding.globalStore.perAccount(selfAccount.id);

  if (mutedUserIds != null) {
    await store.setMutedUsers(mutedUserIds);
  }

  await store.addMessages(dmMessages);

  await tester.pumpWidget(TestZulipApp(
    accountId: selfAccount.id,
    navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
    child: const HomePage()));

  // global store, per-account store, and page get loaded
  await tester.pumpAndSettle();

  // Switch to direct messages tab.
  await tester.tap(find.descendant(
    of: find.byType(DecoratedBox),
    matching: find.byIcon(ZulipIcons.two_person)));
  await tester.pump();
}

void main() {
  TestZulipBinding.ensureInitialized();

  Finder findConversationItem(Narrow narrow) => find.byWidgetPredicate(
    (widget) => widget is RecentDmConversationsItem && widget.narrow == narrow,
  );

  group('RecentDmConversationsPage', () {
    testWidgets('appearance when empty', (tester) async {
      await setupPage(tester, users: [], dmMessages: []);
      check(find.text('You have no direct messages yet!')).findsOne();
      check(find.text('Why not start a conversation?')).findsOne();
    });

    testWidgets('page builds; conversations appear in order', (tester) async {
      final user1 = eg.user(userId: 1);
      final user2 = eg.user(userId: 2);

      final message1 = eg.dmMessage(id: 1, from: eg.selfUser, to: [user1]); // 1:1
      final message2 = eg.dmMessage(id: 2, from: eg.selfUser, to: []); // self-1:1
      final message3 = eg.dmMessage(id: 3, from: eg.selfUser, to: [user1, user2]); // group

      await setupPage(tester, users: [user1, user2],
        dmMessages: [message1, message2, message3]);

      final items = tester.widgetList<RecentDmConversationsItem>(find.byType(RecentDmConversationsItem)).toList();
      check(items).length.equals(3);
      check(items[0].narrow).equals(DmNarrow.ofMessage(message3, selfUserId: eg.selfUser.userId));
      check(items[1].narrow).equals(DmNarrow.ofMessage(message2, selfUserId: eg.selfUser.userId));
      check(items[2].narrow).equals(DmNarrow.ofMessage(message1, selfUserId: eg.selfUser.userId));
    });

    testWidgets('fling to scroll down', (tester) async {
      final List<User> users = [];
      final List<DmMessage> messages = [];
      for (int i = 1; i <= 30; i++) {
        final user = eg.user(userId: i, fullName: 'User ${i.toString()}');
        users.add(user);
        messages.add(eg.dmMessage(from: eg.selfUser, to: [user]));
      }

      await setupPage(tester, users: users, dmMessages: messages);

      final oldestConversationFinder = findConversationItem(
        DmNarrow.ofMessage(messages.first, selfUserId: eg.selfUser.userId));

      check(tester.any(oldestConversationFinder)).isFalse(); // not onscreen
      await tester.fling(find.byType(RecentDmConversationsPageBody),
        const Offset(0, -200), 4000);
      await tester.pumpAndSettle();
      check(tester.any(oldestConversationFinder)).isTrue(); // onscreen
    });

    testWidgets('opens new DM sheet on New DM button tap', (tester) async {
      Route<dynamic>? lastPushedRoute;
      Route<dynamic>? lastPoppedRoute;
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = ((route, _) => lastPushedRoute = route)
        ..onPopped = ((route, _) => lastPoppedRoute = route);

      await setupPage(tester, navigatorObserver: testNavObserver,
        users: [], dmMessages: []);

      await tester.tap(find.widgetWithText(GestureDetector, 'New DM'));
      await tester.pump();
      check(lastPushedRoute).isA<ModalBottomSheetRoute<void>>();
      await tester.pump((lastPushedRoute as TransitionRoute).transitionDuration);
      check(find.byType(NewDmPicker)).findsOne();

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      check(lastPoppedRoute).isA<ModalBottomSheetRoute<void>>();
      await tester.pump(
        (lastPoppedRoute as TransitionRoute).reverseTransitionDuration
        // TODO not sure why a 1ms fudge is needed; investigate.
        + Duration(milliseconds: 1));
      check(find.byType(NewDmPicker)).findsNothing();
    });

    group('filter DMs', () {
      testWidgets('search box is rendered', (tester) async {
        final user = eg.user(userId: 1, fullName: 'User 1');
        await setupPage(tester, users: [user], dmMessages: [
          eg.dmMessage(from: eg.selfUser, to: [user]),
        ]);
        check(find.byType(TextField)).findsOne();
        check(find.text('Filter direct messages')).findsOne();
      });

      testWidgets('filters by name (1:1)', (tester) async {
        final user1 = eg.user(userId: 1, fullName: 'Alice');
        final user2 = eg.user(userId: 2, fullName: 'Bob');
        await setupPage(tester, users: [user1, user2], dmMessages: [
          eg.dmMessage(id: 1, from: eg.selfUser, to: [user1]),
          eg.dmMessage(id: 2, from: eg.selfUser, to: [user2]),
        ]);

        await tester.enterText(find.byType(TextField), 'Alice');
        await tester.pump();

        check(findConversationItem(DmNarrow.ofMessage(eg.dmMessage(id: 1, from: eg.selfUser, to: [user1]), selfUserId: eg.selfUser.userId))).findsOne();
        check(findConversationItem(DmNarrow.ofMessage(eg.dmMessage(id: 2, from: eg.selfUser, to: [user2]), selfUserId: eg.selfUser.userId))).findsNothing();
      });

      testWidgets('filters by name (group)', (tester) async {
        final user1 = eg.user(userId: 1, fullName: 'Alice');
        final user2 = eg.user(userId: 2, fullName: 'Bob');
        final user3 = eg.user(userId: 3, fullName: 'Charlie');
        await setupPage(tester, users: [user1, user2, user3], dmMessages: [
          eg.dmMessage(id: 1, from: eg.selfUser, to: [user1, user2]), // Alice, Bob
          eg.dmMessage(id: 2, from: eg.selfUser, to: [user3]),        // Charlie
        ]);

        await tester.enterText(find.byType(TextField), 'Bob');
        await tester.pump();

        check(findConversationItem(DmNarrow.ofMessage(eg.dmMessage(id: 1, from: eg.selfUser, to: [user1, user2]), selfUserId: eg.selfUser.userId))).findsOne();
        check(findConversationItem(DmNarrow.ofMessage(eg.dmMessage(id: 2, from: eg.selfUser, to: [user3]), selfUserId: eg.selfUser.userId))).findsNothing();
      });

      testWidgets('filters by name (self-1:1)', (tester) async {
        final user1 = eg.user(userId: 1, fullName: 'Alice');
        await setupPage(tester, users: [user1], dmMessages: [
          eg.dmMessage(id: 1, from: eg.selfUser, to: []),
          eg.dmMessage(id: 2, from: eg.selfUser, to: [user1]),
        ]);

        await tester.enterText(find.byType(TextField), eg.selfUser.fullName);
        await tester.pump();

        check(findConversationItem(DmNarrow.ofMessage(eg.dmMessage(id: 1, from: eg.selfUser, to: []), selfUserId: eg.selfUser.userId))).findsOne();
        // Alice shouldn't be found unless her name contains selfUser.fullName (unlikely in test data)
      });

      testWidgets('empty search results show no placeholder', (tester) async {
        final user1 = eg.user(userId: 1, fullName: 'Alice');
        await setupPage(tester, users: [user1], dmMessages: [
          eg.dmMessage(from: eg.selfUser, to: [user1]),
        ]);

        await tester.enterText(find.byType(TextField), 'Zack');
        await tester.pump();

        check(find.byType(RecentDmConversationsItem)).findsNothing();
        check(find.text('You have no direct messages yet!')).findsNothing();
      });
    });
  });

  group('RecentDmConversationsItem', () {
    group('content/appearance', () {
      void checkAvatar(WidgetTester tester, DmNarrow narrow) {
        final shape = tester.widget<AvatarShape>(
          find.descendant(
            of: find.byType(RecentDmConversationsItem),
            matching: find.byType(AvatarShape),
          ));
        check(shape)
          ..size.equals(32)
          ..borderRadius.equals(3);

        switch (narrow.otherRecipientIds) {
          case []:                // self-1:1
            check(shape).child.isA<AvatarImage>().userId.equals(eg.selfUser.userId);
          case [var otherUserId]: // 1:1
            check(shape).child.isA<AvatarImage>().userId.equals(otherUserId);
          default:                // group
            // TODO(#232): syntax like `check(find(…), findsOneWidget)`
            tester.widget(find.descendant(
              of: find.byWidget(shape.child),
              matching: find.byIcon(ZulipIcons.group_dm),
            ));
        }
      }

      void checkTitle(WidgetTester tester, String expectedText, [int? expectedLines]) {
        // TODO(#232): syntax like `check(find(…), findsOneWidget)`
        final widget = tester.widget(find.descendant(
          of: find.byType(RecentDmConversationsItem),
          // The title might contain a WidgetSpan (for status emoji); exclude
          // the resulting placeholder character from the text to be matched.
          matching: findText(expectedText, includePlaceholders: false)));
        if (expectedLines != null) {
          final renderObject = tester.renderObject<RenderParagraph>(find.byWidget(widget));
          check(renderObject.size.height).equals(
            20.0 // line height
            * expectedLines);
        }
      }

      void checkFindsStatusEmoji(WidgetTester tester, Finder emojiFinder) {
        final statusEmojiFinder = find.ancestor(of: emojiFinder,
          matching: find.byType(UserStatusEmoji));
        check(statusEmojiFinder).findsOne();
        check(tester.widget<UserStatusEmoji>(statusEmojiFinder)
          .animationMode).equals(ImageAnimationMode.animateNever);
        check(find.ancestor(of: statusEmojiFinder,
          matching: find.byType(RecentDmConversationsItem))).findsOne();
      }

      Future<void> markMessageAsRead(WidgetTester tester, Message message) async {
        final store = await testBinding.globalStore.perAccount(
          testBinding.globalStore.accounts.single.id);
        await store.handleEvent(UpdateMessageFlagsAddEvent(
          id: 1, flag: MessageFlag.read, all: false, messages: [message.id]));
        await tester.pump();
      }

      void checkUnreadCount(WidgetTester tester, int expectedCount) {
        final Text? textWidget = tester.widgetList<Text>(find.descendant(
          of: find.byType(RecentDmConversationsItem),
          matching: find.textContaining(RegExp(r'^\d+$'),
        ))).singleOrNull;

        if (expectedCount == 0) {
          check(textWidget).isNull();
        } else {
          check(textWidget).isNotNull().data.equals(expectedCount.toString());
        }
      }

      group('self-1:1', () {
        testWidgets('has right title/avatar', (tester) async {
          final message = eg.dmMessage(from: eg.selfUser, to: []);
          await setupPage(tester, users: [], dmMessages: [message]);

          checkAvatar(tester, DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId));
          checkTitle(tester, eg.selfUser.fullName);
        });

        testWidgets('short name takes one line', (tester) async {
          const name = 'Short name';
          final selfUser = eg.user(fullName: name);
          await setupPage(tester, selfUser: selfUser, users: [],
            dmMessages: [eg.dmMessage(from: selfUser, to: [])]);
          checkTitle(tester, name, 1);
        });

        testWidgets('very long name takes two lines (must be ellipsized)', (tester) async {
          const name = 'Long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name';
          final selfUser = eg.user(fullName: name);
          await setupPage(tester, selfUser: selfUser, users: [],
            dmMessages: [eg.dmMessage(from: selfUser, to: [])]);
          checkTitle(tester, name, 2);
        });

        group('User status', () {
          testWidgets('emoji & text are set -> emoji is displayed, text is not', (tester) async {
            final message = eg.dmMessage(from: eg.selfUser, to: []);
            await setupPage(tester, dmMessages: [message], users: []);
            await store.changeUserStatus(eg.selfUser.userId, UserStatusChange(
              text: OptionSome('Busy'),
              emoji: OptionSome(StatusEmoji(emojiName: 'working_on_it',
                emojiCode: '1f6e0', reactionType: ReactionType.unicodeEmoji))));
            await tester.pump();

            checkFindsStatusEmoji(tester, find.text('\u{1f6e0}'));
            check(find.textContaining('Busy')).findsNothing();
          });

          testWidgets('emoji is not set, text is set -> text is not displayed', (tester) async {
            final message = eg.dmMessage(from: eg.selfUser, to: []);
            await setupPage(tester, dmMessages: [message], users: []);
            await store.changeUserStatus(eg.selfUser.userId, UserStatusChange(
              text: OptionSome('Busy'), emoji: OptionNone()));
            await tester.pump();

            check(find.textContaining('Busy')).findsNothing();
          });
        });

        testWidgets('unread counts', (tester) async {
          final message = eg.dmMessage(from: eg.selfUser, to: []);
          await setupPage(tester, users: [], dmMessages: [message]);

          checkUnreadCount(tester, 1);
          await markMessageAsRead(tester, message);
          checkUnreadCount(tester, 0);
        });
      });

      group('1:1', () {
        group('has right title/avatar', () {
          testWidgets('non-muted user', (tester) async {
            final user = eg.user(userId: 1);
            final message = eg.dmMessage(from: eg.selfUser, to: [user]);
            await setupPage(tester, users: [user], dmMessages: [message]);

            checkAvatar(tester, DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId));
            checkTitle(tester, user.fullName);
          });

          testWidgets('muted user', (tester) async {
            final user = eg.user(userId: 1);
            final message = eg.dmMessage(from: eg.selfUser, to: [user]);
            await setupPage(tester,
              users: [user],
              mutedUserIds: [user.userId],
              dmMessages: [message]);

            final narrow = DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId);
            check(findConversationItem(narrow)).findsNothing();
          });
        });

        testWidgets('no error when user somehow missing from user store', (tester) async {
          final user = eg.user(userId: 1);
          final message = eg.dmMessage(from: eg.selfUser, to: [user]);
          await setupPage(tester,
            users: [], // exclude user
            dmMessages: [message],
          );

          checkAvatar(tester, DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId));
          checkTitle(tester, '(unknown user)');
        });

        testWidgets('short name takes one line', (tester) async {
          final user = eg.user(userId: 1, fullName: 'Short name');
          final message = eg.dmMessage(from: eg.selfUser, to: [user]);
          await setupPage(tester, users: [user], dmMessages: [message]);
          checkTitle(tester, user.fullName, 1);
        });

        testWidgets('very long name takes two lines (must be ellipsized)', (tester) async {
          final user = eg.user(userId: 1, fullName: 'Long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name');
          final message = eg.dmMessage(from: eg.selfUser, to: [user]);
          await setupPage(tester, users: [user], dmMessages: [message]);
          checkTitle(tester, user.fullName, 2);
        });

        group('User status', () {
          testWidgets('emoji & text are set -> emoji is displayed, text is not', (tester) async {
            final user = eg.user();
            final message = eg.dmMessage(from: eg.selfUser, to: [user]);
            await setupPage(tester, users: [user], dmMessages: [message]);
            await store.changeUserStatus(user.userId, UserStatusChange(
              text: OptionSome('Busy'),
              emoji: OptionSome(StatusEmoji(emojiName: 'working_on_it',
                emojiCode: '1f6e0', reactionType: ReactionType.unicodeEmoji))));
            await tester.pump();

            checkFindsStatusEmoji(tester, find.text('\u{1f6e0}'));
            check(find.textContaining('Busy')).findsNothing();
          });

          testWidgets('emoji is not set, text is set -> text is not displayed', (tester) async {
            final user = eg.user();
            final message = eg.dmMessage(from: eg.selfUser, to: [user]);
            await setupPage(tester, users: [user], dmMessages: [message]);
            await store.changeUserStatus(user.userId, UserStatusChange(
              text: OptionSome('Busy'), emoji: OptionNone()));
            await tester.pump();

            check(find.textContaining('Busy')).findsNothing();
          });
        });

        testWidgets('unread counts', (tester) async {
          final message = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]);
          await setupPage(tester, users: [], dmMessages: [message]);

          checkUnreadCount(tester, 1);
          await markMessageAsRead(tester, message);
          checkUnreadCount(tester, 0);
        });
      });

      group('group', () {
        List<User> usersList(int count) {
          final result = <User>[];
          for (int i = 1; i <= count; i++) {
            result.add(eg.user(userId: i, fullName: 'User ${i.toString()}'));
          }
          return result;
        }

        group('has right title/avatar', () {
          testWidgets('no users muted', (tester) async {
            final users = usersList(2);
            final user0 = users[0];
            final user1 = users[1];
            final message = eg.dmMessage(from: eg.selfUser, to: [user0, user1]);
            await setupPage(tester, users: users, dmMessages: [message]);

            checkAvatar(tester, DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId));
            checkTitle(tester, '${user0.fullName}, ${user1.fullName}');
          });

          testWidgets('some users muted', (tester) async {
            final users = usersList(2);
            final user0 = users[0];
            final user1 = users[1];
            final message = eg.dmMessage(from: eg.selfUser, to: [user0, user1]);
            await setupPage(tester,
              users: users,
              mutedUserIds: [user0.userId],
              dmMessages: [message]);

            checkAvatar(tester, DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId));
            checkTitle(tester, 'Muted user, ${user1.fullName}');
          });

          testWidgets('all users muted', (tester) async {
            final users = usersList(2);
            final user0 = users[0];
            final user1 = users[1];
            final message = eg.dmMessage(from: eg.selfUser, to: [user0, user1]);
            await setupPage(tester,
              users: users,
              mutedUserIds: [user0.userId, user1.userId],
              dmMessages: [message]);

            final narrow = DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId);
            check(findConversationItem(narrow)).findsNothing();
          });
        });

        testWidgets('no error when one user somehow missing from user store', (tester) async {
          final users = usersList(2);
          final user0 = users[0];
          final user1 = users[1];
          final message = eg.dmMessage(from: eg.selfUser, to: [user0, user1]);
          await setupPage(tester,
            users: [user0], // exclude user1
            dmMessages: [message],
          );

          checkAvatar(tester, DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId));
          checkTitle(tester, '${user0.fullName}, (unknown user)');
        });

        testWidgets('few names takes one line', (tester) async {
          final users = usersList(2);
          final message = eg.dmMessage(from: eg.selfUser, to: users);
          await setupPage(tester, users: users, dmMessages: [message]);
          checkTitle(tester, users.map((u) => u.fullName).join(', '), 1);
        });

        testWidgets('very many names takes two lines (must be ellipsized)', (tester) async {
          final users = usersList(40);
          final message = eg.dmMessage(from: eg.selfUser, to: users);
          await setupPage(tester, users: users, dmMessages: [message]);
          checkTitle(tester, users.map((u) => u.fullName).join(', '), 2);
        });

        testWidgets('status emoji & text are set -> none of them is displayed', (tester) async {
          final users = usersList(4);
          final message = eg.dmMessage(from: eg.selfUser, to: users);
          await setupPage(tester, users: users, dmMessages: [message]);
          await store.changeUserStatus(users.first.userId, UserStatusChange(
            text: OptionSome('Busy'),
            emoji: OptionSome(StatusEmoji(emojiName: 'working_on_it',
              emojiCode: '1f6e0', reactionType: ReactionType.unicodeEmoji))));
          await tester.pump();

          check(find.text('\u{1f6e0}')).findsNothing();
          check(find.textContaining('Busy')).findsNothing();
        });

        testWidgets('unread counts', (tester) async {
          final message = eg.dmMessage(from: eg.thirdUser, to: [eg.selfUser, eg.otherUser]);
          await setupPage(tester, users: [], dmMessages: [message]);

          checkUnreadCount(tester, 1);
          await markMessageAsRead(tester, message);
          checkUnreadCount(tester, 0);
        });
      });
    });

    group('on tap, navigates to message list', () {
      Future<void> runAndCheck(WidgetTester tester, {
        required DmMessage message,
        required List<User> users
      }) async {
        final expectedNarrow = DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId);
        final pushedRoutes = <Route<dynamic>>[];
        final testNavObserver = TestNavigatorObserver()
          ..onPushed = (route, prevRoute) => pushedRoutes.add(route);

        await setupPage(tester, users: users,
          dmMessages: [message],
          navigatorObserver: testNavObserver);

        await tester.tap(find.byType(RecentDmConversationsItem));
        // no `tester.pump`, to avoid having to mock API response for [MessageListPage]

        check(pushedRoutes).last.isA<WidgetRoute>().page
          .isA<MessageListPage>()
          .initNarrow.equals(expectedNarrow);
      }

      testWidgets('1:1', (tester) async {
        final user = eg.user(userId: 1, fullName: 'User 1');
        await runAndCheck(tester, users: [user],
          message: eg.dmMessage(from: eg.selfUser, to: [user]));
      });

      testWidgets('self-1:1', (tester) async {
        await runAndCheck(tester, users: [],
          message: eg.dmMessage(from: eg.selfUser, to: []));
      });

      testWidgets('group', (tester) async {
        final user1 = eg.user(userId: 1, fullName: 'User 1');
        final user2 = eg.user(userId: 2, fullName: 'User 2');
        await runAndCheck(tester, users: [user1, user2],
          message: eg.dmMessage(from: eg.selfUser, to: [user1, user2]));
      });
    });
  });
}
