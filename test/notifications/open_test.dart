import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/host/notifications.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/notifications/open.dart';
import 'package:zulip/notifications/receive.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../test_navigation.dart';
import '../widgets/dialog_checks.dart';
import '../widgets/message_list_checks.dart';
import '../widgets/page_checks.dart';

Map<String, Object?> messageApnsPayload(
  Message zulipMessage, {
  String? streamName,
  Account? account,
}) {
  account ??= eg.selfAccount;
  return {
    "aps": {
      "alert": {
        "title": "test",
        "subtitle": "test",
        "body": zulipMessage.content,
      },
      "sound": "default",
      "badge": 0,
    },
    "zulip": {
      "server": "zulip.example.cloud",
      "realm_id": 4,
      "realm_uri": account.realmUrl.toString(),
      "realm_url": account.realmUrl.toString(),
      "realm_name": "Test",
      "user_id": account.userId,
      "sender_id": zulipMessage.senderId,
      "sender_email": zulipMessage.senderEmail,
      "time": zulipMessage.timestamp,
      "message_ids": [zulipMessage.id],
      ...(switch (zulipMessage) {
        StreamMessage(:var streamId, :var topic) => {
          "recipient_type": "stream",
          "stream_id": streamId,
          if (streamName != null) "stream": streamName,
          "topic": topic,
        },
        DmMessage(allRecipientIds: [_, _, _, ...]) => {
          "recipient_type": "private",
          "pm_users": zulipMessage.allRecipientIds.join(","),
        },
        DmMessage() => {"recipient_type": "private"},
      }),
    },
  };
}

void main() {
  TestZulipBinding.ensureInitialized();
  final zulipLocalizations = GlobalLocalizations.zulipLocalizations;

  Future<void> init() async {
    addTearDown(testBinding.reset);
    testBinding.firebaseMessagingInitialToken = '012abc';
    addTearDown(NotificationService.debugReset);
    addTearDown(NotificationOpenManager.debugReset);
    NotificationService.debugBackgroundIsolateIsLive = false;
    await NotificationService.instance.start();
  }

  group('NotificationOpenManager', () {
    late List<Route<void>> pushedRoutes;

    void takeStartingRoutes({Account? account}) {
      final expected = <Condition<Object?>>[
        if (account != null)
          (it) => it.isA<MaterialAccountWidgetRoute>()
            ..accountId.equals(account.id)
            ..page.isA<HomePage>()
        else
          (it) => it.isA<WidgetRoute>().page.isA<ChooseAccountPage>(),
      ];
      check(pushedRoutes.take(expected.length)).deepEquals(expected);
      pushedRoutes.removeRange(0, expected.length);
    }

    Future<void> prepare(
      WidgetTester tester, {
      bool dropStartingRoutes = true,
      Account? account,
      bool withAccount = true,
    }) async {
      if (withAccount) {
        account ??= eg.selfAccount;
        await testBinding.globalStore.add(account, eg.initialSnapshot());
      }
      await init();
      pushedRoutes = [];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      // This uses [ZulipApp] instead of [TestZulipApp] because notification
      // logic uses `await ZulipApp.navigator`.
      await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
      if (!dropStartingRoutes) {
        check(pushedRoutes).isEmpty();
        return;
      }
      await tester.pump();
      takeStartingRoutes(account: account);
      check(pushedRoutes).isEmpty();
    }

    Future<void> openNotification(WidgetTester tester, Account account, Message message) async {
      final payload = messageApnsPayload(message, account: account);
      testBinding.notificationPigeonApi.addNotificationTapEvent(
        NotificationTapEvent(payload: payload));
      await tester.idle(); // let navigateForNotification find navigator
    }

    void matchesNavigation(Subject<Route<void>> route, Account account, Message message) {
      route.isA<MaterialAccountWidgetRoute>()
        ..accountId.equals(account.id)
        ..page.isA<MessageListPage>()
          .initNarrow.equals(SendableNarrow.ofMessage(message,
            selfUserId: account.userId));
    }

    Future<void> checkOpenNotification(WidgetTester tester, Account account, Message message) async {
      await openNotification(tester, account, message);
      matchesNavigation(check(pushedRoutes).single, account, message);
      pushedRoutes.clear();
    }

    testWidgets('(iOS) stream message', (tester) async {
      addTearDown(testBinding.reset);
      await prepare(tester);
      await checkOpenNotification(tester, eg.selfAccount, eg.streamMessage());
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

    testWidgets('(iOS) direct message', (tester) async {
      addTearDown(testBinding.reset);
      await prepare(tester);
      await checkOpenNotification(tester, eg.selfAccount,
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]));
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

    testWidgets('(iOS) account queried by realmUrl origin component', (tester) async {
      addTearDown(testBinding.reset);
      await prepare(tester,
        account: eg.selfAccount.copyWith(realmUrl: Uri.parse('http://chat.example')));

      await checkOpenNotification(tester,
        eg.selfAccount.copyWith(realmUrl: Uri.parse('http://chat.example/')),
        eg.streamMessage());
      await checkOpenNotification(tester,
        eg.selfAccount.copyWith(realmUrl: Uri.parse('http://chat.example')),
        eg.streamMessage());
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

    testWidgets('(iOS) no accounts', (tester) async {
      await prepare(tester, withAccount: false);
      await openNotification(tester, eg.selfAccount, eg.streamMessage());
      await tester.pump();
      check(pushedRoutes.single).isA<DialogRoute<void>>();
      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: zulipLocalizations.errorNotificationOpenTitle,
        expectedMessage: zulipLocalizations.errorNotificationOpenAccountLoggedOut)));
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

    testWidgets('(iOS) mismatching account', (tester) async {
      addTearDown(testBinding.reset);
      await prepare(tester);
      await openNotification(tester, eg.otherAccount, eg.streamMessage());
      await tester.pump();
      check(pushedRoutes.single).isA<DialogRoute<void>>();
      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: zulipLocalizations.errorNotificationOpenTitle,
        expectedMessage: zulipLocalizations.errorNotificationOpenAccountLoggedOut)));
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

    testWidgets('(iOS) find account among several', (tester) async {
      addTearDown(testBinding.reset);
      final realmUrlA = Uri.parse('https://a-chat.example/');
      final realmUrlB = Uri.parse('https://chat-b.example/');
      final user1 = eg.user();
      final user2 = eg.user();
      final accounts = [
        eg.account(id: 1001, realmUrl: realmUrlA, user: user1),
        eg.account(id: 1002, realmUrl: realmUrlA, user: user2),
        eg.account(id: 1003, realmUrl: realmUrlB, user: user1),
        eg.account(id: 1004, realmUrl: realmUrlB, user: user2),
      ];
      for (final account in accounts) {
        await testBinding.globalStore.add(account, eg.initialSnapshot());
      }

      await prepare(tester, dropStartingRoutes: false, withAccount: false);
      check(pushedRoutes).isEmpty(); // GlobalStore hasn't loaded yet
      await tester.pump();
      takeStartingRoutes(account: accounts[0]);

      await checkOpenNotification(tester, accounts[0], eg.streamMessage());
      await checkOpenNotification(tester, accounts[1], eg.streamMessage());
      await checkOpenNotification(tester, accounts[2], eg.streamMessage());
      await checkOpenNotification(tester, accounts[3], eg.streamMessage());
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

    testWidgets('(iOS) wait for app to become ready', (tester) async {
      addTearDown(testBinding.reset);
      await prepare(tester, dropStartingRoutes: false);
      final message = eg.streamMessage();
      await openNotification(tester, eg.selfAccount, message);
      // The app should still not be ready (or else this test won't work right).
      check(ZulipApp.ready.value).isFalse();
      check(ZulipApp.navigatorKey.currentState).isNull();
      // And the openNotification hasn't caused any navigation yet.
      check(pushedRoutes).isEmpty();

      // Now let the GlobalStore get loaded and the app's main UI get mounted.
      await tester.pump();
      // The navigator first pushes the starting routes…
      takeStartingRoutes(account: eg.selfAccount);
      // … and then the one the notification leads to.
      matchesNavigation(check(pushedRoutes).single, eg.selfAccount, message);
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

    testWidgets('(iOS) at app launch', (tester) async {
      addTearDown(testBinding.reset);
      // Set up a value for `PlatformDispatcher.defaultRouteName` to return,
      // for determining the initial route.
      final message = eg.streamMessage();
      final payload = messageApnsPayload(message, account: eg.selfAccount);
      testBinding.notificationPigeonApi.setNotificationDataFromLaunch(
        NotificationDataFromLaunch(payload: payload));

      // Now start the app.
      await prepare(tester, dropStartingRoutes: false);
      check(pushedRoutes).isEmpty(); // GlobalStore hasn't loaded yet

      // Once the app is ready, we navigate to the conversation.
      await tester.pump();
      takeStartingRoutes(account: eg.selfAccount);
      matchesNavigation(check(pushedRoutes).single, eg.selfAccount, message);
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

    testWidgets('(iOS) uses associated account as initial account; if initial route', (tester) async {
      addTearDown(testBinding.reset);

      final accountA = eg.selfAccount;
      final accountB = eg.otherAccount;
      final message = eg.streamMessage();
      await testBinding.globalStore.add(accountA, eg.initialSnapshot());
      await testBinding.globalStore.add(accountB, eg.initialSnapshot());

      final payload = messageApnsPayload(message, account: accountB);
      testBinding.notificationPigeonApi.setNotificationDataFromLaunch(
        NotificationDataFromLaunch(payload: payload));

      await prepare(tester, dropStartingRoutes: false, withAccount: false);
      check(pushedRoutes).isEmpty(); // GlobalStore hasn't loaded yet

      await tester.pump();
      takeStartingRoutes(account: accountB);
      matchesNavigation(check(pushedRoutes).single, accountB, message);
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));
  });
}
