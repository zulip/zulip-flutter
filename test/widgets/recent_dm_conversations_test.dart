import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/recent_dm_conversations.dart';
import 'package:zulip/widgets/store.dart';

import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/test_store.dart';
import '../test_navigation.dart';
import 'content_checks.dart';
import 'message_list_checks.dart';
import 'page_checks.dart';

Future<void> setupPage(WidgetTester tester, {
  required List<DmMessage> dmMessages,
  required List<User> users,
  NavigatorObserver? navigatorObserver,
  String? newNameForSelfUser,
}) async {
  addTearDown(testBinding.reset);

  await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
  final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

  await store.addUser(eg.selfUser);
  for (final user in users) {
    await store.addUser(user);
  }

  for (final dmMessage in dmMessages) {
    await store.handleEvent(MessageEvent(id: 1, message: dmMessage));
  }

  if (newNameForSelfUser != null) {
    await store.handleEvent(RealmUserUpdateEvent(id: 1, userId: eg.selfUser.userId,
      fullName: newNameForSelfUser));
  }

  await tester.pumpWidget(
    GlobalStoreWidget(
      child: MaterialApp(
        localizationsDelegates: ZulipLocalizations.localizationsDelegates,
        supportedLocales: ZulipLocalizations.supportedLocales,
        navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
        home: PerAccountStoreWidget(
          accountId: eg.selfAccount.id,
          child: const RecentDmConversationsPage()))));

  // global store, per-account store, and page get loaded
  await tester.pumpAndSettle();
}

void main() {
  TestZulipBinding.ensureInitialized();

  group('RecentDmConversationsPage', () {
    Finder findConversationItem(Narrow narrow) => find.byWidgetPredicate(
      (widget) => widget is RecentDmConversationsItem && widget.narrow == narrow,
    );

    testWidgets('page builds; conversations appear in order', (WidgetTester tester) async {
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

    testWidgets('fling to scroll down', (WidgetTester tester) async {
      final List<User> users = [];
      final List<DmMessage> messages = [];
      for (int i = 0; i < 30; i++) {
        final user = eg.user(userId: i, fullName: 'User ${i.toString()}');
        users.add(user);
        messages.add(eg.dmMessage(from: eg.selfUser, to: [user]));
      }

      await setupPage(tester, users: users, dmMessages: messages);

      final oldestConversationFinder = findConversationItem(
        DmNarrow.ofMessage(messages.first, selfUserId: eg.selfUser.userId));

      check(tester.any(oldestConversationFinder)).isFalse(); // not onscreen
      await tester.fling(find.byType(RecentDmConversationsPage),
        const Offset(0, -200), 4000);
      await tester.pumpAndSettle();
      check(tester.any(oldestConversationFinder)).isTrue(); // onscreen
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
          matching: find.text(expectedText),
        ));
        if (expectedLines != null) {
          final renderObject = tester.renderObject<RenderParagraph>(find.byWidget(widget));
          check(renderObject.size.height).equals(
            20.0 // line height
            * expectedLines);
        }
      }

      Future<void> markMessageAsRead(WidgetTester tester, Message message) async {
        final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
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
        testWidgets('has right title/avatar', (WidgetTester tester) async {
          final message = eg.dmMessage(from: eg.selfUser, to: []);
          await setupPage(tester, users: [], dmMessages: [message]);

          checkAvatar(tester, DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId));
          checkTitle(tester, eg.selfUser.fullName);
        });

        testWidgets('short name takes one line', (WidgetTester tester) async {
          final message = eg.dmMessage(from: eg.selfUser, to: []);
          const name = 'Short name';
          await setupPage(tester, users: [], dmMessages: [message],
            newNameForSelfUser: name);
          checkTitle(tester, name, 1);
        });

        testWidgets('very long name takes two lines (must be ellipsized)', (WidgetTester tester) async {
          final message = eg.dmMessage(from: eg.selfUser, to: []);
          const name = 'Long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name';
          await setupPage(tester, users: [], dmMessages: [message],
            newNameForSelfUser: name);
          checkTitle(tester, name, 2);
        });

        testWidgets('unread counts', (WidgetTester tester) async {
          final message = eg.dmMessage(from: eg.selfUser, to: []);
          await setupPage(tester, users: [], dmMessages: [message]);

          checkUnreadCount(tester, 1);
          await markMessageAsRead(tester, message);
          checkUnreadCount(tester, 0);
        });
      });

      group('1:1', () {
        testWidgets('has right title/avatar', (WidgetTester tester) async {
          final user = eg.user(userId: 1);
          final message = eg.dmMessage(from: eg.selfUser, to: [user]);
          await setupPage(tester, users: [user], dmMessages: [message]);

          checkAvatar(tester, DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId));
          checkTitle(tester, user.fullName);
        });

        testWidgets('no error when user somehow missing from store.users', (WidgetTester tester) async {
          final user = eg.user(userId: 1);
          final message = eg.dmMessage(from: eg.selfUser, to: [user]);
          await setupPage(tester,
            users: [], // exclude user
            dmMessages: [message],
          );

          checkAvatar(tester, DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId));
          checkTitle(tester, '(unknown user)');
        });

        testWidgets('short name takes one line', (WidgetTester tester) async {
          final user = eg.user(userId: 1, fullName: 'Short name');
          final message = eg.dmMessage(from: eg.selfUser, to: [user]);
          await setupPage(tester, users: [user], dmMessages: [message]);
          checkTitle(tester, user.fullName, 1);
        });

        testWidgets('very long name takes two lines (must be ellipsized)', (WidgetTester tester) async {
          final user = eg.user(userId: 1, fullName: 'Long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name long name');
          final message = eg.dmMessage(from: eg.selfUser, to: [user]);
          await setupPage(tester, users: [user], dmMessages: [message]);
          checkTitle(tester, user.fullName, 2);
        });

        testWidgets('unread counts', (WidgetTester tester) async {
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
          for (int i = 0; i < count; i++) {
            result.add(eg.user(userId: i, fullName: 'User ${i.toString()}'));
          }
          return result;
        }

        testWidgets('has right title/avatar', (WidgetTester tester) async {
          final users = usersList(2);
          final user0 = users[0];
          final user1 = users[1];
          final message = eg.dmMessage(from: eg.selfUser, to: [user0, user1]);
          await setupPage(tester, users: users, dmMessages: [message]);

          checkAvatar(tester, DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId));
          checkTitle(tester, '${user0.fullName}, ${user1.fullName}');
        });

        testWidgets('no error when one user somehow missing from store.users', (WidgetTester tester) async {
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

        testWidgets('few names takes one line', (WidgetTester tester) async {
          final users = usersList(2);
          final message = eg.dmMessage(from: eg.selfUser, to: users);
          await setupPage(tester, users: users, dmMessages: [message]);
          checkTitle(tester, users.map((u) => u.fullName).join(', '), 1);
        });

        testWidgets('very many names takes two lines (must be ellipsized)', (WidgetTester tester) async {
          final users = usersList(40);
          final message = eg.dmMessage(from: eg.selfUser, to: users);
          await setupPage(tester, users: users, dmMessages: [message]);
          checkTitle(tester, users.map((u) => u.fullName).join(', '), 2);
        });

        testWidgets('unread counts', (WidgetTester tester) async {
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
          .narrow.equals(expectedNarrow);
      }

      testWidgets('1:1', (WidgetTester tester) async {
        final user = eg.user(userId: 1, fullName: 'User 1');
        await runAndCheck(tester, users: [user],
          message: eg.dmMessage(from: eg.selfUser, to: [user]));
      });

      testWidgets('self-1:1', (WidgetTester tester) async {
        await runAndCheck(tester, users: [],
          message: eg.dmMessage(from: eg.selfUser, to: []));
      });

      testWidgets('group', (WidgetTester tester) async {
        final user1 = eg.user(userId: 1, fullName: 'User 1');
        final user2 = eg.user(userId: 2, fullName: 'User 2');
        await runAndCheck(tester, users: [user1, user2],
          message: eg.dmMessage(from: eg.selfUser, to: [user1, user2]));
      });
    });
  });
}
