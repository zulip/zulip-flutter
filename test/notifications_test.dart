import 'dart:convert';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Message;
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/notifications.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/notifications.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/store.dart';

import 'model/binding.dart';
import 'example_data.dart' as eg;
import 'test_navigation.dart';
import 'widgets/message_list_checks.dart';
import 'widgets/page_checks.dart';
import 'widgets/store_checks.dart';

FakeAndroidFlutterLocalNotificationsPlugin get notifAndroid =>
  testBinding.notifications
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    as FakeAndroidFlutterLocalNotificationsPlugin;

MessageFcmMessage messageFcmMessage(
  Message zulipMessage, {
  String? streamName,
  Account? account,
}) {
  account ??= eg.selfAccount;
  final narrow = SendableNarrow.ofMessage(zulipMessage, selfUserId: account.userId);
  return FcmMessage.fromJson({
    "event": "message",

    "server": "zulip.example.cloud",
    "realm_id": "4",
    "realm_uri": account.realmUrl.toString(),
    "user_id": account.userId.toString(),

    "zulip_message_id": zulipMessage.id.toString(),
    "time": zulipMessage.timestamp.toString(),
    "content": zulipMessage.content,

    "sender_id": zulipMessage.senderId.toString(),
    "sender_avatar_url": "${account.realmUrl}avatar/${zulipMessage.senderId}.jpeg",
    "sender_full_name": zulipMessage.senderFullName.toString(),

    ...(switch (narrow) {
      TopicNarrow(:var streamId, :var topic) => {
        "recipient_type": "stream",
        "stream_id": streamId.toString(),
        if (streamName != null) "stream": streamName,
        "topic": topic,
      },
      DmNarrow(allRecipientIds: [_, _, _, ...]) => {
        "recipient_type": "private",
        "pm_users": narrow.allRecipientIds.join(","),
      },
      DmNarrow() => {
        "recipient_type": "private",
      },
    }),
  }) as MessageFcmMessage;
}

void main() {
  TestZulipBinding.ensureInitialized();

  Future<void> init() async {
    addTearDown(testBinding.reset);
    testBinding.firebaseMessagingInitialToken = '012abc';
    addTearDown(NotificationService.debugReset);
    NotificationService.debugBackgroundIsolateIsLive = false;
    await NotificationService.instance.start();
  }

  group('NotificationChannelManager', () {
    test('smoke', () async {
      await init();
      check(notifAndroid.takeCreatedChannels()).single
        ..id.equals(NotificationChannelManager.kChannelId)
        ..name.equals('Messages')
        ..description.isNull()
        ..groupId.isNull()
        ..importance.equals(Importance.high)
        ..playSound.isTrue()
        ..sound.isNull()
        ..enableVibration.isTrue()
        ..vibrationPattern.isNotNull().deepEquals(
            NotificationChannelManager.kVibrationPattern)
        ..showBadge.isTrue()
        ..enableLights.isTrue()
        ..ledColor.isNull()
      ;
    });
  });

  group('NotificationDisplayManager show', () {
    void checkNotification(MessageFcmMessage data, {
      required String expectedTitle,
      required String expectedTagComponent,
    }) {
      final expectedTag = '${data.realmUri}|${data.userId}|$expectedTagComponent';
      final expectedId =
        NotificationDisplayManager.notificationIdAsHashOf(expectedTag);
      check(testBinding.notifications.takeShowCalls()).single
        ..id.equals(expectedId)
        ..title.equals(expectedTitle)
        ..body.equals(data.content)
        ..payload.equals(jsonEncode(data.toJson()))
        ..notificationDetails.isNotNull().android.isNotNull().which(it()
          ..channelId.equals(NotificationChannelManager.kChannelId)
          ..tag.equals(expectedTag)
          ..color.equals(kZulipBrandColor)
          ..icon.equals('zulip_notification')
        );
    }

    Future<void> checkNotifications(MessageFcmMessage data, {
      required String expectedTitle,
      required String expectedTagComponent,
    }) async {
      testBinding.firebaseMessaging.onMessage.add(
        RemoteMessage(data: data.toJson()));
      await null;
      checkNotification(data, expectedTitle: expectedTitle,
        expectedTagComponent: expectedTagComponent);

      testBinding.firebaseMessaging.onBackgroundMessage.add(
        RemoteMessage(data: data.toJson()));
      await null;
      checkNotification(data, expectedTitle: expectedTitle,
        expectedTagComponent: expectedTagComponent);
    }

    test('stream message', () async {
      await init();
      final stream = eg.stream();
      final message = eg.streamMessage(stream: stream);
      await checkNotifications(messageFcmMessage(message, streamName: stream.name),
        expectedTitle: '${stream.name} > ${message.subject}',
        expectedTagComponent: 'stream:${message.streamId}:${message.subject}');
    });

    test('stream message, stream name omitted', () async {
      await init();
      final stream = eg.stream();
      final message = eg.streamMessage(stream: stream);
      await checkNotifications(messageFcmMessage(message, streamName: null),
        expectedTitle: '(unknown stream) > ${message.subject}',
        expectedTagComponent: 'stream:${message.streamId}:${message.subject}');
    });

    test('group DM', () async {
      await init();
      final message = eg.dmMessage(from: eg.thirdUser, to: [eg.otherUser, eg.selfUser]);
      await checkNotifications(messageFcmMessage(message),
        expectedTitle: "${eg.thirdUser.fullName} to you and 1 others",
        expectedTagComponent: 'dm:${message.allRecipientIds.join(",")}');
    });

    test('1:1 DM', () async {
      await init();
      final message = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]);
      await checkNotifications(messageFcmMessage(message),
        expectedTitle: eg.otherUser.fullName,
        expectedTagComponent: 'dm:${message.allRecipientIds.join(",")}');
    });

    test('self-DM', () async {
      await init();
      final message = eg.dmMessage(from: eg.selfUser, to: []);
      await checkNotifications(messageFcmMessage(message),
        expectedTitle: eg.selfUser.fullName,
        expectedTagComponent: 'dm:${message.allRecipientIds.join(",")}');
    });
  });

  group('NotificationDisplayManager open', () {
    late List<Route<dynamic>> pushedRoutes;

    Future<void> prepare(WidgetTester tester) async {
      await init();
      pushedRoutes = [];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
      await tester.pump();
      check(pushedRoutes).length.equals(1);
      pushedRoutes.clear();
    }

    void openNotification(Account account, Message message) {
      final fcmMessage = messageFcmMessage(message, account: account);
      testBinding.notifications.receiveNotificationResponse(NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: jsonEncode(fcmMessage)));
    }

    void checkOpenedMessageList({required int expectedAccountId, required Narrow expectedNarrow}) {
      check(pushedRoutes).single.isA<WidgetRoute>().page
        .isA<PerAccountStoreWidget>()
        ..accountId.equals(expectedAccountId)
        ..child.isA<MessageListPage>()
            .narrow.equals(expectedNarrow);
      pushedRoutes.clear();
    }

    void checkOpenNotification(Account account, Message message) {
      openNotification(account, message);
      checkOpenedMessageList(
        expectedAccountId: account.id,
        expectedNarrow: SendableNarrow.ofMessage(message,
          selfUserId: account.userId));
    }

    testWidgets('stream message', (tester) async {
      testBinding.globalStore.insertAccount(eg.selfAccount.toCompanion(false));
      await prepare(tester);
      checkOpenNotification(eg.selfAccount, eg.streamMessage());
    });

    testWidgets('direct message', (tester) async {
      testBinding.globalStore.insertAccount(eg.selfAccount.toCompanion(false));
      await prepare(tester);
      checkOpenNotification(eg.selfAccount,
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]));
    });

    testWidgets('no widgets in tree', (tester) async {
      await init();
      final message = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]);

      openNotification(eg.selfAccount, message);
      // nothing happened, but nothing blew up
    });

    testWidgets('no accounts', (tester) async {
      await prepare(tester);
      openNotification(eg.selfAccount, eg.streamMessage());
      check(pushedRoutes).isEmpty();
    });

    testWidgets('mismatching account', (tester) async {
      testBinding.globalStore.insertAccount(eg.selfAccount.toCompanion(false));
      await prepare(tester);
      openNotification(eg.otherAccount, eg.streamMessage());
      check(pushedRoutes).isEmpty();
    });

    testWidgets('find account among several', (tester) async {
      final realmUrlA = Uri.parse('https://a-chat.example/');
      final realmUrlB = Uri.parse('https://chat-b.example/');
      final accounts = [
        eg.account(id: 1001, realmUrl: realmUrlA, user: eg.user(userId: 123)),
        eg.account(id: 1002, realmUrl: realmUrlA, user: eg.user(userId: 234)),
        eg.account(id: 1003, realmUrl: realmUrlB, user: eg.user(userId: 123)),
        eg.account(id: 1004, realmUrl: realmUrlB, user: eg.user(userId: 234)),
      ];
      for (final account in accounts) {
        testBinding.globalStore.insertAccount(account.toCompanion(false));
      }
      await prepare(tester);

      checkOpenNotification(accounts[0], eg.streamMessage());
      checkOpenNotification(accounts[1], eg.streamMessage());
      checkOpenNotification(accounts[2], eg.streamMessage());
      checkOpenNotification(accounts[3], eg.streamMessage());
    });
  });
}

extension AndroidNotificationChannelChecks on Subject<AndroidNotificationChannel> {
  Subject<String> get id => has((x) => x.id, 'id');
  Subject<String> get name => has((x) => x.name, 'name');
  Subject<String?> get description => has((x) => x.description, 'description');
  Subject<String?> get groupId => has((x) => x.groupId, 'groupId');
  Subject<Importance> get importance => has((x) => x.importance, 'importance');
  Subject<bool> get playSound => has((x) => x.playSound, 'playSound');
  Subject<AndroidNotificationSound?> get sound => has((x) => x.sound, 'sound');
  Subject<bool> get enableVibration => has((x) => x.enableVibration, 'enableVibration');
  Subject<bool> get enableLights => has((x) => x.enableLights, 'enableLights');
  Subject<Int64List?> get vibrationPattern => has((x) => x.vibrationPattern, 'vibrationPattern');
  Subject<Color?> get ledColor => has((x) => x.ledColor, 'ledColor');
  Subject<bool> get showBadge => has((x) => x.showBadge, 'showBadge');
}

extension ShowCallChecks on Subject<FlutterLocalNotificationsPluginShowCall> {
  Subject<int> get id => has((x) => x.$1, 'id');
  Subject<String?> get title => has((x) => x.$2, 'title');
  Subject<String?> get body => has((x) => x.$3, 'body');
  Subject<NotificationDetails?> get notificationDetails => has((x) => x.$4, 'notificationDetails');
  Subject<String?> get payload => has((x) => x.payload, 'payload');
}

extension NotificationDetailsChecks on Subject<NotificationDetails> {
  Subject<AndroidNotificationDetails?> get android => has((x) => x.android, 'android');
  Subject<DarwinNotificationDetails?> get iOS => has((x) => x.iOS, 'iOS');
  Subject<DarwinNotificationDetails?> get macOS => has((x) => x.macOS, 'macOS');
  Subject<LinuxNotificationDetails?> get linux => has((x) => x.linux, 'linux');
}

extension AndroidNotificationDetailsChecks on Subject<AndroidNotificationDetails> {
  // The upstream [AndroidNotificationDetails] has many more properties
  // which only apply to creating a channel, or to notifications before
  // channels were introduced in Android 8.  We ignore those here.
  Subject<String?> get icon => has((x) => x.icon, 'icon');
  Subject<String> get channelId => has((x) => x.channelId, 'channelId');
  Subject<StyleInformation?> get styleInformation => has((x) => x.styleInformation, 'styleInformation');
  Subject<String?> get groupKey => has((x) => x.groupKey, 'groupKey');
  Subject<bool> get setAsGroupSummary => has((x) => x.setAsGroupSummary, 'setAsGroupSummary');
  Subject<GroupAlertBehavior> get groupAlertBehavior => has((x) => x.groupAlertBehavior, 'groupAlertBehavior');
  Subject<bool> get autoCancel => has((x) => x.autoCancel, 'autoCancel');
  Subject<bool> get ongoing => has((x) => x.ongoing, 'ongoing');
  Subject<Color?> get color => has((x) => x.color, 'color');
  Subject<AndroidBitmap<Object>?> get largeIcon => has((x) => x.largeIcon, 'largeIcon');
  Subject<bool> get onlyAlertOnce => has((x) => x.onlyAlertOnce, 'onlyAlertOnce');
  Subject<bool> get showWhen => has((x) => x.showWhen, 'showWhen');
  Subject<int?> get when => has((x) => x.when, 'when');
  Subject<bool> get usesChronometer => has((x) => x.usesChronometer, 'usesChronometer');
  Subject<bool> get chronometerCountDown => has((x) => x.chronometerCountDown, 'chronometerCountDown');
  Subject<bool> get showProgress => has((x) => x.showProgress, 'showProgress');
  Subject<int> get maxProgress => has((x) => x.maxProgress, 'maxProgress');
  Subject<int> get progress => has((x) => x.progress, 'progress');
  Subject<bool> get indeterminate => has((x) => x.indeterminate, 'indeterminate');
  Subject<String?> get ticker => has((x) => x.ticker, 'ticker');
  Subject<AndroidNotificationChannelAction> get channelAction => has((x) => x.channelAction, 'channelAction');
  Subject<NotificationVisibility?> get visibility => has((x) => x.visibility, 'visibility');
  Subject<int?> get timeoutAfter => has((x) => x.timeoutAfter, 'timeoutAfter');
  Subject<AndroidNotificationCategory?> get category => has((x) => x.category, 'category');
  Subject<bool> get fullScreenIntent => has((x) => x.fullScreenIntent, 'fullScreenIntent');
  Subject<String?> get shortcutId => has((x) => x.shortcutId, 'shortcutId');
  Subject<Int32List?> get additionalFlags => has((x) => x.additionalFlags, 'additionalFlags');
  Subject<List<AndroidNotificationAction>?> get actions => has((x) => x.actions, 'actions');
  Subject<String?> get subText => has((x) => x.subText, 'subText');
  Subject<String?> get tag => has((x) => x.tag, 'tag');
  Subject<bool> get colorized => has((x) => x.colorized, 'colorized');
  Subject<int?> get number => has((x) => x.number, 'number');
  Subject<AudioAttributesUsage> get audioAttributesUsage => has((x) => x.audioAttributesUsage, 'audioAttributesUsage');
}
