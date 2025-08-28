import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/notifications.dart';
import 'package:zulip/host/notifications.dart';
import 'package:zulip/model/database.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/notifications/open.dart';
import 'package:zulip/notifications/receive.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/narrow_checks.dart';
import '../model/store_checks.dart';
import '../stdlib_checks.dart';
import '../test_navigation.dart';
import '../widgets/checks.dart';
import '../widgets/dialog_checks.dart';
import 'display_test.dart';

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
    NotificationService.debugBackgroundIsolateIsLive = false;
    await NotificationService.instance.start();
  }

  group('NotificationOpenService', () {
    late List<Route<void>> pushedRoutes;

    void takeHomePageRouteForAccount(int accountId) {
      check(pushedRoutes).first.which(
        (it) => it.isA<MaterialAccountWidgetRoute>()
          ..accountId.equals(accountId)
          ..page.isA<HomePage>());
      pushedRoutes.removeAt(0);
    }

    void takeChooseAccountPageRoute() {
      check(pushedRoutes).first.which(
        (it) => it.isA<WidgetRoute>().page.isA<ChooseAccountPage>());
      pushedRoutes.removeAt(0);
    }

    Future<void> prepare(WidgetTester tester, {bool early = false}) async {
      await init();
      pushedRoutes = [];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      // This uses [ZulipApp] instead of [TestZulipApp] because notification
      // logic uses `await ZulipApp.navigator`.
      await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
      if (early) {
        check(pushedRoutes).isEmpty();
        return;
      }
      await tester.pump();
      final lastVisitedAccountId = testBinding.globalStore.lastVisitedAccount?.id;
      if (lastVisitedAccountId == null) {
        takeChooseAccountPageRoute();
      } else {
        takeHomePageRouteForAccount(lastVisitedAccountId);
      }
      check(pushedRoutes).isEmpty();
    }

    Uri androidNotificationUrlForMessage(Account account, Message message) {
      final data = messageFcmMessage(message, account: account);
      return NotificationOpenPayload(
        realmUrl: data.realmUrl,
        userId: data.userId,
        narrow: switch (data.recipient) {
        FcmMessageChannelRecipient(:var streamId, :var topic) =>
          TopicNarrow(streamId, topic),
        FcmMessageDmRecipient(:var allRecipientIds) =>
          DmNarrow(allRecipientIds: allRecipientIds, selfUserId: data.userId),
      }).buildAndroidNotificationUrl();
    }

    Future<void> openNotification(WidgetTester tester, Account account, Message message) async {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final intentDataUrl = androidNotificationUrlForMessage(account, message);
          unawaited(
            WidgetsBinding.instance.handlePushRoute(intentDataUrl.toString()));
          await tester.idle(); // let navigateForNotification find navigator

        case TargetPlatform.iOS:
          final payload = messageApnsPayload(message, account: account);
          testBinding.notificationPigeonApi.addNotificationTapEvent(
            NotificationTapEvent(payload: payload));
          await tester.idle(); // let navigateForNotification find navigator

        default:
          throw UnsupportedError('Unsupported target platform: "$defaultTargetPlatform"');
      }
    }

    void setupNotificationDataForLaunch(WidgetTester tester, Account account, Message message) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          // Set up a value for `PlatformDispatcher.defaultRouteName` to return,
          // for determining the initial route.
          final intentDataUrl = androidNotificationUrlForMessage(account, message);
          addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
          tester.binding.platformDispatcher.defaultRouteNameTestValue = intentDataUrl.toString();

        case TargetPlatform.iOS:
          // Set up a value to return for
          // `notificationPigeonApi.getNotificationDataFromLaunch`.
          final payload = messageApnsPayload(message, account: account);
          testBinding.notificationPigeonApi.setNotificationDataFromLaunch(
            NotificationDataFromLaunch(payload: payload));

        default:
          throw UnsupportedError('Unsupported target platform: "$defaultTargetPlatform"');
      }
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

    testWidgets('stream message', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await prepare(tester);
      await checkOpenNotification(tester, eg.selfAccount, eg.streamMessage());
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('direct message', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await prepare(tester);
      await checkOpenNotification(tester, eg.selfAccount,
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]));
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('account queried by realmUrl origin component', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(
        eg.selfAccount.copyWith(realmUrl: Uri.parse('http://chat.example')),
        eg.initialSnapshot());
      await prepare(tester);

      await checkOpenNotification(tester,
        eg.selfAccount.copyWith(realmUrl: Uri.parse('http://chat.example/')),
        eg.streamMessage());
      await checkOpenNotification(tester,
        eg.selfAccount.copyWith(realmUrl: Uri.parse('http://chat.example')),
        eg.streamMessage());
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('no accounts', (tester) async {
      await prepare(tester);
      // (just to make sure the test is working)
      check(testBinding.globalStore.accountIds).isEmpty();
      await openNotification(tester, eg.selfAccount, eg.streamMessage());
      await tester.pump();
      check(pushedRoutes.single).isA<DialogRoute<void>>();
      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: zulipLocalizations.errorNotificationOpenTitle,
        expectedMessage: zulipLocalizations.errorNotificationOpenAccountNotFound)));
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('mismatching account', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await prepare(tester);
      await openNotification(tester, eg.otherAccount, eg.streamMessage());
      await tester.pump();
      check(pushedRoutes.single).isA<DialogRoute<void>>();
      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: zulipLocalizations.errorNotificationOpenTitle,
        expectedMessage: zulipLocalizations.errorNotificationOpenAccountNotFound)));
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('find account among several', (tester) async {
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
      await testBinding.globalStore.add(
        accounts[0], eg.initialSnapshot(realmUsers: [user1]));
      await testBinding.globalStore.add(
        accounts[1], eg.initialSnapshot(realmUsers: [user2]));
      await testBinding.globalStore.add(
        accounts[2], eg.initialSnapshot(realmUsers: [user1]));
      await testBinding.globalStore.add(
        accounts[3], eg.initialSnapshot(realmUsers: [user2]));
      await prepare(tester);

      await checkOpenNotification(tester, accounts[0], eg.streamMessage());
      await checkOpenNotification(tester, accounts[1], eg.streamMessage());
      await checkOpenNotification(tester, accounts[2], eg.streamMessage());
      await checkOpenNotification(tester, accounts[3], eg.streamMessage());
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('wait for app to become ready', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await prepare(tester, early: true);
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
      takeHomePageRouteForAccount(eg.selfAccount.id); // because last-visited
      // … and then the one the notification leads to.
      matchesNavigation(check(pushedRoutes).single, eg.selfAccount, message);
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('at app launch', (tester) async {
      addTearDown(testBinding.reset);
      final account = eg.selfAccount;
      final message = eg.streamMessage();
      setupNotificationDataForLaunch(tester, account, message);

      // Now start the app.
      await testBinding.globalStore.add(account, eg.initialSnapshot());
      await prepare(tester, early: true);
      check(pushedRoutes).isEmpty(); // GlobalStore hasn't loaded yet

      // Once the app is ready, we navigate to the conversation.
      await tester.pump();
      takeHomePageRouteForAccount(account.id); // because associated account
      matchesNavigation(check(pushedRoutes).single, account, message);
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('uses associated account as initial account; if initial route', (tester) async {
      addTearDown(testBinding.reset);

      final accountA = eg.selfAccount;
      final accountB = eg.otherAccount;
      final message = eg.streamMessage();
      await testBinding.globalStore.add(accountA, eg.initialSnapshot());
      await testBinding.globalStore.add(accountB, eg.initialSnapshot(
        realmUsers: [eg.otherUser]));
      setupNotificationDataForLaunch(tester, accountB, message);

      await prepare(tester, early: true);
      check(pushedRoutes).isEmpty(); // GlobalStore hasn't loaded yet

      await tester.pump();
      takeHomePageRouteForAccount(accountB.id); // because associated account
      matchesNavigation(check(pushedRoutes).single, accountB, message);
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    group('changes last visited account', () {
      testWidgets('app already opened, then notification is opened', (tester) async {
        addTearDown(testBinding.reset);
        await testBinding.globalStore.add(
          eg.selfAccount, eg.initialSnapshot(realmUsers: [eg.selfUser]));
        await testBinding.globalStore.add(
          eg.otherAccount, eg.initialSnapshot(realmUsers: [eg.otherUser]),
          markLastVisited: false);
        await prepare(tester);
        check(testBinding.globalStore).lastVisitedAccount.equals(eg.selfAccount);

        await checkOpenNotification(tester, eg.otherAccount, eg.streamMessage());
        check(testBinding.globalStore).lastVisitedAccount.equals(eg.otherAccount);
      }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

      testWidgets('app is opened through notification', (tester) async {
        addTearDown(testBinding.reset);

        final accountA = eg.selfAccount;
        final accountB = eg.otherAccount;
        final message = eg.streamMessage();
        await testBinding.globalStore.add(accountA, eg.initialSnapshot());
        await testBinding.globalStore.add(
          accountB, eg.initialSnapshot(realmUsers: [eg.otherUser]),
          markLastVisited: false);
        check(testBinding.globalStore).lastVisitedAccount.equals(accountA);
        setupNotificationDataForLaunch(tester, accountB, message);

        await prepare(tester, early: true);
        check(pushedRoutes).isEmpty(); // GlobalStore hasn't loaded yet

        await tester.pump();
        takeHomePageRouteForAccount(accountB.id); // because associated account
        matchesNavigation(check(pushedRoutes).single, accountB, message);
        check(testBinding.globalStore).lastVisitedAccount.equals(accountB);
      }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
    });
  });

  group('NotificationOpenPayload', () {
    test('android: smoke round-trip', () {
      // DM narrow
      var payload = NotificationOpenPayload(
        realmUrl: Uri.parse('http://chat.example'),
        userId: 1001,
        narrow: DmNarrow(allRecipientIds: [1001, 1002], selfUserId: 1001),
      );
      var url = payload.buildAndroidNotificationUrl();
      check(NotificationOpenPayload.parseAndroidNotificationUrl(url))
        ..realmUrl.equals(payload.realmUrl)
        ..userId.equals(payload.userId)
        ..narrow.equals(payload.narrow);

      // Topic narrow
      payload = NotificationOpenPayload(
        realmUrl: Uri.parse('http://chat.example'),
        userId: 1001,
        narrow: eg.topicNarrow(1, 'topic A'),
      );
      url = payload.buildAndroidNotificationUrl();
      check(NotificationOpenPayload.parseAndroidNotificationUrl(url))
        ..realmUrl.equals(payload.realmUrl)
        ..userId.equals(payload.userId)
        ..narrow.equals(payload.narrow);
    });

    group('parseIosApnsPayload', () {
      test('smoke one-one DM', () {
        final userA = eg.user(userId: 1001);
        final userB = eg.user(userId: 1002);
        final account = eg.account(
          realmUrl: Uri.parse('http://chat.example'),
          user: userA);
        final payload = messageApnsPayload(eg.dmMessage(from: userB, to: [userA]),
          account: account);
        check(NotificationOpenPayload.parseIosApnsPayload(payload))
          ..realmUrl.equals(Uri.parse('http://chat.example'))
          ..userId.equals(1001)
          ..narrow.which((it) => it.isA<DmNarrow>()
            ..otherRecipientIds.deepEquals([1002]));
      });

      test('smoke group DM', () {
        final userA = eg.user(userId: 1001);
        final userB = eg.user(userId: 1002);
        final userC = eg.user(userId: 1003);
        final account = eg.account(
          realmUrl: Uri.parse('http://chat.example'),
          user: userA);
        final payload = messageApnsPayload(eg.dmMessage(from: userC, to: [userA, userB]),
          account: account);
        check(NotificationOpenPayload.parseIosApnsPayload(payload))
          ..realmUrl.equals(Uri.parse('http://chat.example'))
          ..userId.equals(1001)
          ..narrow.which((it) => it.isA<DmNarrow>()
            ..otherRecipientIds.deepEquals([1002, 1003]));
      });

      test('smoke topic message', () {
        final userA = eg.user(userId: 1001);
        final account = eg.account(
          realmUrl: Uri.parse('http://chat.example'),
          user: userA);
        final payload = messageApnsPayload(eg.streamMessage(
          stream: eg.stream(streamId: 1),
          topic: 'topic A'),
          account: account);
        check(NotificationOpenPayload.parseIosApnsPayload(payload))
          ..realmUrl.equals(Uri.parse('http://chat.example'))
          ..userId.equals(1001)
          ..narrow.which((it) => it.isA<TopicNarrow>()
            ..streamId.equals(1)
            ..topic.equals(TopicName('topic A')));
      });
    });

    group('buildAndroidNotificationUrl', () {
      test('smoke DM', () {
        final url = NotificationOpenPayload(
          realmUrl: Uri.parse('http://chat.example'),
          userId: 1001,
          narrow: DmNarrow(allRecipientIds: [1001, 1002], selfUserId: 1001),
        ).buildAndroidNotificationUrl();
        check(url)
          ..scheme.equals('zulip')
          ..host.equals('notification')
          ..queryParameters.deepEquals({
            'realm_url': 'http://chat.example',
            'user_id': '1001',
            'narrow_type': 'dm',
            'all_recipient_ids': '1001,1002',
          });
      });

      test('smoke topic', () {
        final url = NotificationOpenPayload(
          realmUrl: Uri.parse('http://chat.example'),
          userId: 1001,
          narrow: eg.topicNarrow(1, 'topic A'),
        ).buildAndroidNotificationUrl();
        check(url)
          ..scheme.equals('zulip')
          ..host.equals('notification')
          ..queryParameters.deepEquals({
            'realm_url': 'http://chat.example',
            'user_id': '1001',
            'narrow_type': 'topic',
            'channel_id': '1',
            'topic': 'topic A',
          });
      });
    });

    group('parseAndroidNotificationUrl', () {
      test('smoke DM', () {
        final url = Uri(
          scheme: 'zulip',
          host: 'notification',
          queryParameters: <String, String>{
            'realm_url': 'http://chat.example',
            'user_id': '1001',
            'narrow_type': 'dm',
            'all_recipient_ids': '1001,1002',
          });
        check(NotificationOpenPayload.parseAndroidNotificationUrl(url))
          ..realmUrl.equals(Uri.parse('http://chat.example'))
          ..userId.equals(1001)
          ..narrow.which((it) => it.isA<DmNarrow>()
            ..allRecipientIds.deepEquals([1001, 1002])
            ..otherRecipientIds.deepEquals([1002]));
      });

      test('smoke topic', () {
        final url = Uri(
          scheme: 'zulip',
          host: 'notification',
          queryParameters: <String, String>{
            'realm_url': 'http://chat.example',
            'user_id': '1001',
            'narrow_type': 'topic',
            'channel_id': '1',
            'topic': 'topic A',
          });
        check(NotificationOpenPayload.parseAndroidNotificationUrl(url))
          ..realmUrl.equals(Uri.parse('http://chat.example'))
          ..userId.equals(1001)
          ..narrow.which((it) => it.isA<TopicNarrow>()
            ..streamId.equals(1)
            ..topic.equals(eg.t('topic A')));
      });

      test('fails when missing any expected query parameters', () {
        final testCases = <Map<String, String>>[
          {
            // 'realm_url': 'http://chat.example',
            'user_id': '1001',
            'narrow_type': 'topic',
            'channel_id': '1',
            'topic': 'topic A',
          },
          {
            'realm_url': 'http://chat.example',
            // 'user_id': '1001',
            'narrow_type': 'topic',
            'channel_id': '1',
            'topic': 'topic A',
          },
          {
            'realm_url': 'http://chat.example',
            'user_id': '1001',
            // 'narrow_type': 'topic',
            'channel_id': '1',
            'topic': 'topic A',
          },
          {
            'realm_url': 'http://chat.example',
            'user_id': '1001',
            'narrow_type': 'topic',
            // 'channel_id': '1',
            'topic': 'topic A',
          },
          {
            'realm_url': 'http://chat.example',
            'user_id': '1001',
            'narrow_type': 'topic',
            'channel_id': '1',
            // 'topic': 'topic A',
          },
          {
            'realm_url': 'http://chat.example',
            'user_id': '1001',
            // 'narrow_type': 'dm',
            'all_recipient_ids': '1001,1002',
          },
          {
            'realm_url': 'http://chat.example',
            'user_id': '1001',
            'narrow_type': 'dm',
            // 'all_recipient_ids': '1001,1002',
          },
        ];
        for (final params in testCases) {
          check(() => NotificationOpenPayload.parseAndroidNotificationUrl(Uri(
            scheme: 'zulip',
            host: 'notification',
            queryParameters: params,
          )))
            // Missing 'realm_url', 'user_id' and 'narrow_type'
            // throws 'FormatException'.
            // Missing 'channel_id', 'topic', when narrow_type == 'topic'
            // throws 'TypeError'.
            // Missing 'all_recipient_ids', when narrow_type == 'dm'
            // throws 'TypeError'.
            .throws<Object>();
        }
      });

      test('fails when scheme is not "zulip"', () {
        final url = Uri(
          scheme: 'http',
          host: 'notification',
          queryParameters: <String, String>{
            'realm_url': 'http://chat.example',
            'user_id': '1001',
            'narrow_type': 'topic',
            'channel_id': '1',
            'topic': 'topic A',
          });
        check(() => NotificationOpenPayload.parseAndroidNotificationUrl(url))
          .throws<FormatException>();
      });

      test('fails when host is not "notification"', () {
        final url = Uri(
          scheme: 'zulip',
          host: 'example',
          queryParameters: <String, String>{
            'realm_url': 'http://chat.example',
            'user_id': '1001',
            'narrow_type': 'topic',
            'channel_id': '1',
            'topic': 'topic A',
          });
        check(() => NotificationOpenPayload.parseAndroidNotificationUrl(url))
          .throws<FormatException>();
      });
    });
  });
}

extension on Subject<NotificationOpenPayload> {
  Subject<Uri> get realmUrl => has((x) => x.realmUrl, 'realmUrl');
  Subject<int> get userId => has((x) => x.userId, 'userId');
  Subject<Narrow> get narrow => has((x) => x.narrow, 'narrow');
}
