import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/notifications.dart';
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
import '../stdlib_checks.dart';
import '../test_navigation.dart';
import '../widgets/dialog_checks.dart';
import '../widgets/message_list_checks.dart';
import '../widgets/page_checks.dart';
import 'display_test.dart';

void main() {
  TestZulipBinding.ensureInitialized();
  final zulipLocalizations = GlobalLocalizations.zulipLocalizations;

  Future<void> init({bool addSelfAccount = true}) async {
    if (addSelfAccount) {
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    }
    addTearDown(testBinding.reset);
    testBinding.firebaseMessagingInitialToken = '012abc';
    addTearDown(NotificationService.debugReset);
    NotificationService.debugBackgroundIsolateIsLive = false;
    await NotificationService.instance.start();
  }

  group('NotificationOpenService', () {
    late List<Route<void>> pushedRoutes;

    void takeStartingRoutes({Account? account, bool withAccount = true}) {
      account ??= eg.selfAccount;
      final expected = <Condition<Object?>>[
        if (withAccount)
          (it) => it.isA<MaterialAccountWidgetRoute>()
            ..accountId.equals(account!.id)
            ..page.isA<HomePage>()
        else
          (it) => it.isA<WidgetRoute>().page.isA<ChooseAccountPage>(),
      ];
      check(pushedRoutes.take(expected.length)).deepEquals(expected);
      pushedRoutes.removeRange(0, expected.length);
    }

    Future<void> prepare(WidgetTester tester,
        {bool early = false, bool withAccount = true}) async {
      await init(addSelfAccount: false);
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
      takeStartingRoutes(withAccount: withAccount);
      check(pushedRoutes).isEmpty();
    }

    Future<void> openNotification(WidgetTester tester, Account account, Message message) async {
      final data = messageFcmMessage(message, account: account);
      final intentDataUrl = NotificationOpenPayload(
        realmUrl: data.realmUrl,
        userId: data.userId,
        narrow: switch (data.recipient) {
        FcmMessageChannelRecipient(:var streamId, :var topic) =>
          TopicNarrow(streamId, topic),
        FcmMessageDmRecipient(:var allRecipientIds) =>
          DmNarrow(allRecipientIds: allRecipientIds, selfUserId: data.userId),
      }).buildUrl();
      unawaited(
        WidgetsBinding.instance.handlePushRoute(intentDataUrl.toString()));
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

    testWidgets('stream message', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await prepare(tester);
      await checkOpenNotification(tester, eg.selfAccount, eg.streamMessage());
    });

    testWidgets('direct message', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await prepare(tester);
      await checkOpenNotification(tester, eg.selfAccount,
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]));
    });

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
    });

    testWidgets('no accounts', (tester) async {
      await prepare(tester, withAccount: false);
      await openNotification(tester, eg.selfAccount, eg.streamMessage());
      await tester.pump();
      check(pushedRoutes.single).isA<DialogRoute<void>>();
      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: zulipLocalizations.errorNotificationOpenTitle,
        expectedMessage: zulipLocalizations.errorNotificationOpenAccountNotFound)));
    });

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
    });

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
      for (final account in accounts) {
        await testBinding.globalStore.add(account, eg.initialSnapshot());
      }
      await prepare(tester);

      await checkOpenNotification(tester, accounts[0], eg.streamMessage());
      await checkOpenNotification(tester, accounts[1], eg.streamMessage());
      await checkOpenNotification(tester, accounts[2], eg.streamMessage());
      await checkOpenNotification(tester, accounts[3], eg.streamMessage());
    });

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
      takeStartingRoutes();
      // … and then the one the notification leads to.
      matchesNavigation(check(pushedRoutes).single, eg.selfAccount, message);
    });

    testWidgets('at app launch', (tester) async {
      addTearDown(testBinding.reset);
      // Set up a value for `PlatformDispatcher.defaultRouteName` to return,
      // for determining the intial route.
      final account = eg.selfAccount;
      final message = eg.streamMessage();
      final data = messageFcmMessage(message, account: account);
      final intentDataUrl = NotificationOpenPayload(
        realmUrl: data.realmUrl,
        userId: data.userId,
        narrow: switch (data.recipient) {
          FcmMessageChannelRecipient(:var streamId, :var topic) =>
            TopicNarrow(streamId, topic),
          FcmMessageDmRecipient(:var allRecipientIds) =>
            DmNarrow(allRecipientIds: allRecipientIds, selfUserId: data.userId),
        }).buildUrl();
      addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
      tester.binding.platformDispatcher.defaultRouteNameTestValue = intentDataUrl.toString();

      // Now start the app.
      await testBinding.globalStore.add(account, eg.initialSnapshot());
      await prepare(tester, early: true);
      check(pushedRoutes).isEmpty(); // GlobalStore hasn't loaded yet

      // Once the app is ready, we navigate to the conversation.
      await tester.pump();
      takeStartingRoutes();
      matchesNavigation(check(pushedRoutes).single, account, message);
    });

    testWidgets('uses associated account as initial account; if initial route', (tester) async {
      addTearDown(testBinding.reset);

      final accountA = eg.selfAccount;
      final accountB = eg.otherAccount;
      final message = eg.streamMessage();
      final data = messageFcmMessage(message, account: accountB);
      await testBinding.globalStore.add(accountA, eg.initialSnapshot());
      await testBinding.globalStore.add(accountB, eg.initialSnapshot());

      final intentDataUrl = NotificationOpenPayload(
        realmUrl: data.realmUrl,
        userId: data.userId,
        narrow: switch (data.recipient) {
          FcmMessageChannelRecipient(:var streamId, :var topic) =>
            TopicNarrow(streamId, topic),
          FcmMessageDmRecipient(:var allRecipientIds) =>
            DmNarrow(allRecipientIds: allRecipientIds, selfUserId: data.userId),
        }).buildUrl();
      addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
      tester.binding.platformDispatcher.defaultRouteNameTestValue = intentDataUrl.toString();

      await prepare(tester, early: true);
      check(pushedRoutes).isEmpty(); // GlobalStore hasn't loaded yet

      await tester.pump();
      takeStartingRoutes(account: accountB);
      matchesNavigation(check(pushedRoutes).single, accountB, message);
    });
  });

  group('NotificationOpenPayload', () {
    test('smoke round-trip', () {
      // DM narrow
      var payload = NotificationOpenPayload(
        realmUrl: Uri.parse('http://chat.example'),
        userId: 1001,
        narrow: DmNarrow(allRecipientIds: [1001, 1002], selfUserId: 1001),
      );
      var url = payload.buildUrl();
      check(NotificationOpenPayload.parseUrl(url))
        ..realmUrl.equals(payload.realmUrl)
        ..userId.equals(payload.userId)
        ..narrow.equals(payload.narrow);

      // Topic narrow
      payload = NotificationOpenPayload(
        realmUrl: Uri.parse('http://chat.example'),
        userId: 1001,
        narrow: eg.topicNarrow(1, 'topic A'),
      );
      url = payload.buildUrl();
      check(NotificationOpenPayload.parseUrl(url))
        ..realmUrl.equals(payload.realmUrl)
        ..userId.equals(payload.userId)
        ..narrow.equals(payload.narrow);
    });

    test('buildUrl: smoke DM', () {
      final url = NotificationOpenPayload(
        realmUrl: Uri.parse('http://chat.example'),
        userId: 1001,
        narrow: DmNarrow(allRecipientIds: [1001, 1002], selfUserId: 1001),
      ).buildUrl();
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

    test('buildUrl: smoke topic', () {
      final url = NotificationOpenPayload(
        realmUrl: Uri.parse('http://chat.example'),
        userId: 1001,
        narrow: eg.topicNarrow(1, 'topic A'),
      ).buildUrl();
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

    test('parse: smoke DM', () {
      final url = Uri(
        scheme: 'zulip',
        host: 'notification',
        queryParameters: <String, String>{
          'realm_url': 'http://chat.example',
          'user_id': '1001',
          'narrow_type': 'dm',
          'all_recipient_ids': '1001,1002',
        });
      check(NotificationOpenPayload.parseUrl(url))
        ..realmUrl.equals(Uri.parse('http://chat.example'))
        ..userId.equals(1001)
        ..narrow.which((it) => it.isA<DmNarrow>()
          ..allRecipientIds.deepEquals([1001, 1002])
          ..otherRecipientIds.deepEquals([1002]));
    });

    test('parse: smoke topic', () {
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
      check(NotificationOpenPayload.parseUrl(url))
        ..realmUrl.equals(Uri.parse('http://chat.example'))
        ..userId.equals(1001)
        ..narrow.which((it) => it.isA<TopicNarrow>()
          ..streamId.equals(1)
          ..topic.equals(eg.t('topic A')));
    });

    test('parse: fails when missing any expected query parameters', () {
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
        check(() => NotificationOpenPayload.parseUrl(Uri(
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

    test('parse: fails when scheme is not "zulip"', () {
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
      check(() => NotificationOpenPayload.parseUrl(url))
        .throws<FormatException>();
    });

    test('parse: fails when host is not "notification"', () {
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
      check(() => NotificationOpenPayload.parseUrl(url))
        .throws<FormatException>();
    });
  });
}

extension on Subject<NotificationOpenPayload> {
  Subject<Uri> get realmUrl => has((x) => x.realmUrl, 'realmUrl');
  Subject<int> get userId => has((x) => x.userId, 'userId');
  Subject<Narrow> get narrow => has((x) => x.narrow, 'narrow');
}
