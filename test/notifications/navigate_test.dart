import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/host/notifications.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/notifications/navigate.dart';
import 'package:zulip/notifications/receive.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../test_navigation.dart';
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

  Future<void> init() async {
    addTearDown(testBinding.reset);
    testBinding.firebaseMessagingInitialToken = '012abc';
    addTearDown(NotificationService.debugReset);
    addTearDown(NotificationNavigationService.debugReset);
    NotificationService.debugBackgroundIsolateIsLive = false;
    await NotificationService.instance.start();
  }

  group('NotificationNavigationService', () {
    late List<Route<void>> pushedRoutes;

    void takeStartingRoutes({Account? account}) {
      account ??= eg.selfAccount;
      final expected = <Condition<Object?>>[
        (it) => it.isA<MaterialAccountWidgetRoute>()
            ..accountId.equals(account!.id)
            ..page.isA<HomePage>(),
      ];
      check(pushedRoutes.take(expected.length)).deepEquals(expected);
      pushedRoutes.removeRange(0, expected.length);
    }

    Future<void> prepare(WidgetTester tester) async {
      await init();
      pushedRoutes = [];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
    }

    void matchesNavigation(Subject<Route<void>> route, Account account, Message message) {
      route.isA<MaterialAccountWidgetRoute>()
        ..accountId.equals(account.id)
        ..page.isA<MessageListPage>()
          .initNarrow.equals(SendableNarrow.ofMessage(message,
            selfUserId: account.userId));
    }

    testWidgets('(iOS) at app launch', (tester) async {
      addTearDown(testBinding.reset);
      // Set up a value for `PlatformDispatcher.defaultRouteName` to return,
      // for determining the initial route.
      final account = eg.selfAccount;
      final message = eg.streamMessage();
      final payload = messageApnsPayload(message, account: account);
      testBinding.notificationPigeonApi.setNotificationDataFromLaunch(
        NotificationDataFromLaunch(payload: payload));

      // Now start the app.
      await testBinding.globalStore.add(account, eg.initialSnapshot());
      await prepare(tester);
      check(pushedRoutes).isEmpty(); // GlobalStore hasn't loaded yet

      // Once the app is ready, we navigate to the conversation.
      await tester.pump();
      takeStartingRoutes();
      matchesNavigation(check(pushedRoutes).single, account, message);
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

      await prepare(tester);
      check(pushedRoutes).isEmpty(); // GlobalStore hasn't loaded yet

      await tester.pump();
      takeStartingRoutes(account: accountB);
      matchesNavigation(check(pushedRoutes).single, accountB, message);
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));
  });
}
