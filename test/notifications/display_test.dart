import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:fake_async/fake_async.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/notifications.dart';
import 'package:zulip/host/android_notifications.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/notifications/display.dart';
import 'package:zulip/notifications/receive.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/color.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/theme.dart';

import '../example_data.dart' as eg;
import '../fake_async.dart';
import '../model/binding.dart';
import '../model/narrow_checks.dart';
import '../stdlib_checks.dart';
import '../test_images.dart';
import '../test_navigation.dart';
import '../widgets/dialog_checks.dart';
import '../widgets/message_list_checks.dart';
import '../widgets/page_checks.dart';

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

RemoveFcmMessage removeFcmMessage(List<Message> zulipMessages, {Account? account}) {
  account ??= eg.selfAccount;
  return FcmMessage.fromJson({
    "event": "remove",

    "server": "zulip.example.cloud",
    "realm_id": "4",
    "realm_uri": account.realmUrl.toString(),
    "user_id": account.userId.toString(),

    "zulip_message_ids": zulipMessages.map((e) => e.id).join(','),
  }) as RemoveFcmMessage;
}

void main() {
  TestZulipBinding.ensureInitialized();
  final zulipLocalizations = GlobalLocalizations.zulipLocalizations;

  http.Client makeFakeHttpClient({http.Response? response, Exception? exception}) {
    return http_testing.MockClient((request) async {
      assert((response != null) ^ (exception != null));
      if (exception != null) throw exception;
      return response!; // TODO return 404 on non avatar urls
    });
  }

  final fakeHttpClientGivingSuccess = makeFakeHttpClient(
    response: http.Response.bytes(kSolidBlueAvatar, HttpStatus.ok));

  T runWithHttpClient<T>(
    T Function() callback, {
    http.Client Function()? httpClientFactory,
  }) {
    return http.runWithClient(callback, httpClientFactory ?? () => fakeHttpClientGivingSuccess);
  }

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

  group('NotificationChannelManager create channel', () {
    test('smoke', () async {
      await init();
      check(testBinding.androidNotificationHost.takeCreatedChannels()).single
        ..id.equals(NotificationChannelManager.kChannelId)
        ..name.equals('Messages')
        ..importance.equals(NotificationImportance.high)
        ..lightsEnabled.equals(true)
        ..soundUrl.equals(testBinding.androidNotificationHost.fakeStoredNotificationSoundUrl(
            NotificationChannelManager.kDefaultNotificationSound.resourceName))
        ..vibrationPattern.isNotNull().deepEquals(
            NotificationChannelManager.kVibrationPattern)
      ;
    });

    test('channel is not recreated if one with same id already exists', () async {
      addTearDown(testBinding.reset);

      // Setup initial channel.
      await testBinding.androidNotificationHost.createNotificationChannel(
        NotificationChannel(
          id: NotificationChannelManager.kChannelId,
          name: 'Messages',
          importance: NotificationImportance.high,
          lightsEnabled: true,
          vibrationPattern: NotificationChannelManager.kVibrationPattern));
      // Clear the log.
      check(testBinding.androidNotificationHost.takeCreatedChannels())
        .length.equals(1);

      // Ensure that no calls were made to the deleteChannel or createChannel
      // functions.
      await NotificationChannelManager.ensureChannel();
      check(testBinding.androidNotificationHost.takeDeletedChannels())
        .isEmpty();
      check(testBinding.androidNotificationHost.takeCreatedChannels())
        .isEmpty();
      check(testBinding.androidNotificationHost.activeChannels).single
        ..id.equals(NotificationChannelManager.kChannelId)
        ..name.equals('Messages')
        ..importance.equals(NotificationImportance.high)
        ..lightsEnabled.equals(true)
        ..vibrationPattern.isNotNull().deepEquals(
            NotificationChannelManager.kVibrationPattern);
    });

    test('obsolete channels are removed', () async {
      addTearDown(testBinding.reset);

      // Setup initial channels.
      await testBinding.androidNotificationHost.createNotificationChannel(
        NotificationChannel(
          id: 'obsolete-1',
          name: 'Obsolete 1',
          importance: NotificationImportance.high,
          lightsEnabled: true,
          vibrationPattern: NotificationChannelManager.kVibrationPattern));
      await testBinding.androidNotificationHost.createNotificationChannel(
        NotificationChannel(
          id: 'obsolete-2',
          name: 'Obsolete 2',
          importance: NotificationImportance.high,
          lightsEnabled: true,
          vibrationPattern: NotificationChannelManager.kVibrationPattern));
      // Clear the log.
      check(testBinding.androidNotificationHost.takeCreatedChannels())
        .length.equals(2);

      // Ensure that any channel whose channel-id differs from the desired
      // channel-id (NotificationChannelManager.kChannelId) is deleted, and a
      // new one with the desired channel-id is created.
      await NotificationChannelManager.ensureChannel();
      check(testBinding.androidNotificationHost.takeDeletedChannels())
        .deepEquals(['obsolete-1', 'obsolete-2']);
      check(testBinding.androidNotificationHost.takeCreatedChannels()).single
        ..id.equals(NotificationChannelManager.kChannelId)
        ..name.equals('Messages')
        ..importance.equals(NotificationImportance.high)
        ..lightsEnabled.equals(true)
        ..vibrationPattern.isNotNull().deepEquals(
            NotificationChannelManager.kVibrationPattern);
      check(testBinding.androidNotificationHost.activeChannels).single
        ..id.equals(NotificationChannelManager.kChannelId)
        ..name.equals('Messages')
        ..importance.equals(NotificationImportance.high)
        ..lightsEnabled.equals(true)
        ..vibrationPattern.isNotNull().deepEquals(
            NotificationChannelManager.kVibrationPattern);
    });
  });

  group('NotificationChannelManager sounds', () {
    final defaultSoundResourceName =
      NotificationChannelManager.kDefaultNotificationSound.resourceName;
    String fakeStoredUrl(String resourceName) =>
      testBinding.androidNotificationHost.fakeStoredNotificationSoundUrl(resourceName);
    String fakeResourceUrl(String resourceName) =>
      'android.resource://com.zulip.flutter/raw/$resourceName';

    test('on Android 28 (and lower) resource file is used for notification sound', () async {
      addTearDown(testBinding.reset);
      final androidNotificationHost = testBinding.androidNotificationHost;

      testBinding.deviceInfoResult =
        const AndroidDeviceInfo(sdkInt: 28, release: '9');

      // Ensure that on Android 10, notification sounds aren't being copied to
      // the media store, and resource file is used directly.
      await NotificationChannelManager.ensureChannel();
      check(androidNotificationHost.takeCopySoundResourceToMediaStoreCalls())
        .isEmpty();
      check(androidNotificationHost.takeCreatedChannels())
        .single
        .soundUrl.equals(fakeResourceUrl(defaultSoundResourceName));
    });

    test('notification sound resource files are being copied to the media store', () async {
      addTearDown(testBinding.reset);
      final androidNotificationHost = testBinding.androidNotificationHost;

      await NotificationChannelManager.ensureChannel();
      check(androidNotificationHost.takeCopySoundResourceToMediaStoreCalls())
        .deepEquals(NotificationSound.values.map((e) => (
          sourceResourceName: e.resourceName,
          targetFileDisplayName: e.fileDisplayName),
        ));

      // Ensure the default source URL points to a file in the media store,
      // rather than a resource file.
      check(androidNotificationHost.takeCreatedChannels())
        .single
        .soundUrl.equals(fakeStoredUrl(defaultSoundResourceName));
    });

    test('notification sounds are not copied again if they were previously copied', () async {
      addTearDown(testBinding.reset);
      final androidNotificationHost = testBinding.androidNotificationHost;

      // Emulate that all notifications sounds are already in the media store.
      androidNotificationHost.setupStoredNotificationSounds(
        NotificationSound.values.map((e) => StoredNotificationSound(
          fileName: e.fileDisplayName,
          isOwned: true,
          contentUrl: fakeStoredUrl(e.resourceName)),
        ).toList(),
      );

      await NotificationChannelManager.ensureChannel();
      check(androidNotificationHost.takeCopySoundResourceToMediaStoreCalls())
        .isEmpty();
      check(androidNotificationHost.takeCreatedChannels())
        .single
        .soundUrl.equals(fakeStoredUrl(defaultSoundResourceName));
    });

    test('new notification sounds are copied to media store', () async {
      addTearDown(testBinding.reset);
      final androidNotificationHost = testBinding.androidNotificationHost;

      // Emulate that except one sound, all other sounds are already in
      // media store.
      androidNotificationHost.setupStoredNotificationSounds(
        NotificationSound.values.skip(1).map((e) => StoredNotificationSound(
          fileName: e.fileDisplayName,
          isOwned: true,
          contentUrl: fakeStoredUrl(e.resourceName)),
        ).toList()
      );

      await NotificationChannelManager.ensureChannel();
      final firstSound = NotificationSound.values.first;
      check(androidNotificationHost.takeCopySoundResourceToMediaStoreCalls())
        .single
        ..sourceResourceName.equals(firstSound.resourceName)
        ..targetFileDisplayName.equals(firstSound.fileDisplayName);
      check(androidNotificationHost.takeCreatedChannels())
        .single
        .soundUrl.equals(fakeStoredUrl(defaultSoundResourceName));
    });

    test('no recopying of existing notification sounds in the media store; default sound URL points to resource file', () async {
      addTearDown(testBinding.reset);
      final androidNotificationHost = testBinding.androidNotificationHost;

      androidNotificationHost.setupStoredNotificationSounds(
        NotificationSound.values.map((e) => StoredNotificationSound(
          fileName: e.fileDisplayName,
          isOwned: false,
          contentUrl: fakeStoredUrl(e.resourceName)),
        ).toList()
      );

      // Ensure that if a notification sound with the same name already exists
      // in the media store, but it wasn't copied by us, no recopying should
      // happen. Additionally, the default sound URL should point to the
      // resource file, not the version in the media store.
      await NotificationChannelManager.ensureChannel();
      check(androidNotificationHost.takeCopySoundResourceToMediaStoreCalls())
        .isEmpty();
      check(androidNotificationHost.takeCreatedChannels())
        .single
        .soundUrl.equals(fakeResourceUrl(defaultSoundResourceName));
    });
  });

  group('NotificationDisplayManager show', () {
    void checkNotification(MessageFcmMessage data, {
      required List<MessageFcmMessage> messageStyleMessages,
      required String expectedTitle,
      required String expectedTagComponent,
      required bool expectedIsGroupConversation,
      List<int>? expectedIconBitmap = kSolidBlueAvatar,
    }) {
      assert(messageStyleMessages.every((e) => e.userId == data.userId));
      assert(messageStyleMessages.every((e) => e.realmUrl == data.realmUrl));

      final expectedTag = '${data.realmUrl}|${data.userId}|$expectedTagComponent';
      final expectedGroupKey = '${data.realmUrl}|${data.userId}';
      const expectedPendingIntentFlags = PendingIntentFlag.immutable;
      const expectedIntentFlags = IntentFlag.activityClearTop | IntentFlag.activityNewTask;
      final expectedSelfUserKey = '${data.realmUrl}|${data.userId}';
      final expectedIntentDataUrl = NotificationOpenPayload(
        realmUrl: data.realmUrl,
        userId: data.userId,
        narrow: switch (data.recipient) {
        FcmMessageChannelRecipient(:var streamId, :var topic) =>
          TopicNarrow(streamId, topic),
        FcmMessageDmRecipient(:var allRecipientIds) =>
          DmNarrow(allRecipientIds: allRecipientIds, selfUserId: data.userId),
      }).buildUrl();

      final messageStyleMessagesChecks =
        messageStyleMessages.mapIndexed((i, messageData) {
          final expectedSenderKey =
            '${messageData.realmUrl}|${messageData.senderId}';
          final isLast = i == (messageStyleMessages.length - 1);
          return (Subject<Object?> it) => it.isA<MessagingStyleMessage>()
            ..text.equals(messageData.content)
            ..timestampMs.equals(messageData.time * 1000)
            ..person.which((it) => it.isNotNull()
              ..iconBitmap.which((it) => (isLast && expectedIconBitmap != null)
                ? it.isNotNull().deepEquals(expectedIconBitmap) : it.isNull())
              ..key.equals(expectedSenderKey)
              ..name.equals(messageData.senderFullName));
        });

      check(testBinding.androidNotificationHost.takeNotifyCalls())
        .deepEquals(<Condition<Object?>>[
          (it) => it.isA<AndroidNotificationHostApiNotifyCall>()
            ..id.equals(NotificationDisplayManager.kNotificationId)
            ..tag.equals(expectedTag)
            ..channelId.equals(NotificationChannelManager.kChannelId)
            ..contentTitle.isNull()
            ..contentText.isNull()
            ..messagingStyle.which((it) => it.isNotNull()
              ..user.which((it) => it
                ..iconBitmap.isNull()
                ..key.equals(expectedSelfUserKey)
                ..name.equals(zulipLocalizations.notifSelfUser))
              ..isGroupConversation.equals(expectedIsGroupConversation)
              ..conversationTitle.equals(expectedTitle)
              ..messages.deepEquals(messageStyleMessagesChecks))
            ..number.equals(messageStyleMessages.length)
            ..color.equals(kZulipBrandColor.argbInt)
            ..smallIconResourceName.equals('zulip_notification')
            ..extras.which((it) => it.isNotNull()
              ..deepEquals(<String, String>{
                NotificationDisplayManager.kExtraLastZulipMessageId: data.zulipMessageId.toString(),
              }))
            ..groupKey.equals(expectedGroupKey)
            ..isGroupSummary.isNull()
            ..inboxStyle.isNull()
            ..autoCancel.equals(true)
            ..contentIntent.which((it) => it.isNotNull()
              ..requestCode.equals(0)
              ..flags.equals(expectedPendingIntentFlags)
              ..intent.which((it) => it
                ..action.equals(IntentAction.view)
                ..dataUrl.equals(expectedIntentDataUrl.toString())
                ..flags.equals(expectedIntentFlags))),
          (it) => it.isA<AndroidNotificationHostApiNotifyCall>()
            ..id.equals(NotificationDisplayManager.kNotificationId)
            ..tag.equals(expectedGroupKey)
            ..channelId.equals(NotificationChannelManager.kChannelId)
            ..contentTitle.isNull()
            ..contentText.isNull()
            ..color.equals(kZulipBrandColor.argbInt)
            ..smallIconResourceName.equals('zulip_notification')
            ..extras.isNull()
            ..groupKey.equals(expectedGroupKey)
            ..isGroupSummary.equals(true)
            ..inboxStyle.which((it) => it.isNotNull()
              ..summaryText.equals(data.realmUrl.toString()))
            ..autoCancel.equals(true)
            ..contentIntent.isNull(),
        ]);
    }

    Future<void> checkNotifications(FakeAsync async, MessageFcmMessage data, {
      required String expectedTitle,
      required String expectedTagComponent,
      required bool expectedIsGroupConversation,
    }) async {
      // We could just call `NotificationDisplayManager.onFcmMessage`.
      // But this way is cheap, and it provides our test coverage of
      // the logic in `NotificationService` that listens for these FCM messages.

      testBinding.firebaseMessaging.onMessage.add(
        RemoteMessage(data: data.toJson()));
      async.flushMicrotasks();
      checkNotification(data,
        messageStyleMessages: [data],
        expectedIsGroupConversation: expectedIsGroupConversation,
        expectedTitle: expectedTitle,
        expectedTagComponent: expectedTagComponent);
      testBinding.androidNotificationHost.clearActiveNotifications();

      testBinding.firebaseMessaging.onBackgroundMessage.add(
        RemoteMessage(data: data.toJson()));
      async.flushMicrotasks();
      checkNotification(data,
        messageStyleMessages: [data],
        expectedIsGroupConversation: expectedIsGroupConversation,
        expectedTitle: expectedTitle,
        expectedTagComponent: expectedTagComponent);
    }

    void receiveFcmMessage(FakeAsync async, FcmMessage data) {
      testBinding.firebaseMessaging.onMessage.add(
        RemoteMessage(data: data.toJson()));
      async.flushMicrotasks();
    }

    Condition<Object?> conditionActiveNotif(MessageFcmMessage data, String tagComponent) {
      final expectedGroupKey = '${data.realmUrl}|${data.userId}';
      final expectedTag = '$expectedGroupKey|$tagComponent';
      return (it) => it.isA<StatusBarNotification>()
        ..id.equals(NotificationDisplayManager.kNotificationId)
        ..notification.which((it) => it
          ..group.equals(expectedGroupKey)
          ..extras.deepEquals(<String, String>{
            NotificationDisplayManager.kExtraLastZulipMessageId: data.zulipMessageId.toString(),
          }))
        ..tag.equals(expectedTag);
    }

    Condition<Object?> conditionSummaryActiveNotif(String expectedGroupKey) {
      return (it) => it.isA<StatusBarNotification>()
        ..id.equals(NotificationDisplayManager.kNotificationId)
        ..notification.which((it) => it
          ..group.equals(expectedGroupKey)
          ..extras.isEmpty())
        ..tag.equals(expectedGroupKey);
    }

    test('stream message', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final stream = eg.stream();
      final message = eg.streamMessage(stream: stream);
      await checkNotifications(async, messageFcmMessage(message, streamName: stream.name),
        expectedIsGroupConversation: true,
        expectedTitle: '#${stream.name} > ${message.topic}',
        expectedTagComponent: 'stream:${message.streamId}:${message.topic}');
    })));

    test('stream message: multiple messages, same topic', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final stream = eg.stream();
      const topic = 'topic 1';
      final message1 = eg.streamMessage(topic: topic, stream: stream);
      final data1 = messageFcmMessage(message1, streamName: stream.name);
      final message2 = eg.streamMessage(topic: topic, stream: stream);
      final data2 = messageFcmMessage(message2, streamName: stream.name);
      final message3 = eg.streamMessage(topic: topic, stream: stream);
      final data3 = messageFcmMessage(message3, streamName: stream.name);

      final expectedTitle = '#${stream.name} > $topic';
      final expectedTagComponent = 'stream:${stream.streamId}:$topic';

      receiveFcmMessage(async, data1);
      checkNotification(data1,
        messageStyleMessages: [data1],
        expectedIsGroupConversation: true,
        expectedTitle: expectedTitle,
        expectedTagComponent: expectedTagComponent);

      receiveFcmMessage(async, data2);
      checkNotification(data2,
        messageStyleMessages: [data1, data2],
        expectedIsGroupConversation: true,
        expectedTitle: expectedTitle,
        expectedTagComponent: expectedTagComponent);

      receiveFcmMessage(async, data3);
      checkNotification(data3,
        messageStyleMessages: [data1, data2, data3],
        expectedIsGroupConversation: true,
        expectedTitle: expectedTitle,
        expectedTagComponent: expectedTagComponent);
    })));

    test('stream message: multiple messages, different topics', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final stream = eg.stream();
      const topicA = 'topic A';
      const topicB = 'topic B';
      final message1 = eg.streamMessage(topic: topicA, stream: stream);
      final data1 = messageFcmMessage(message1, streamName: stream.name);
      final message2 = eg.streamMessage(topic: topicB, stream: stream);
      final data2 = messageFcmMessage(message2, streamName: stream.name);
      final message3 = eg.streamMessage(topic: topicA, stream: stream);
      final data3 = messageFcmMessage(message3, streamName: stream.name);

      receiveFcmMessage(async, data1);
      checkNotification(data1,
        messageStyleMessages: [data1],
        expectedIsGroupConversation: true,
        expectedTitle: '#${stream.name} > $topicA',
        expectedTagComponent: 'stream:${stream.streamId}:${topicA.toLowerCase()}');

      receiveFcmMessage(async, data2);
      checkNotification(data2,
        messageStyleMessages: [data2],
        expectedIsGroupConversation: true,
        expectedTitle: '#${stream.name} > $topicB',
        expectedTagComponent: 'stream:${stream.streamId}:${topicB.toLowerCase()}');

      receiveFcmMessage(async, data3);
      checkNotification(data3,
        messageStyleMessages: [data1, data3],
        expectedIsGroupConversation: true,
        expectedTitle: '#${stream.name} > $topicA',
        expectedTagComponent: 'stream:${stream.streamId}:${topicA.toLowerCase()}');
    })));

    test('stream message: topic changes only case', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final stream = eg.stream();
      const topic1 = 'A ToPic';
      const topic2 = 'a TOpic';
      final message1 = eg.streamMessage(topic: topic1, stream: stream);
      final data1 = messageFcmMessage(message1, streamName: stream.name);
      final message2 = eg.streamMessage(topic: topic2, stream: stream);
      final data2 = messageFcmMessage(message2, streamName: stream.name);

      receiveFcmMessage(async, data1);
      checkNotification(data1,
        messageStyleMessages: [data1],
        expectedIsGroupConversation: true,
        expectedTitle: '#${stream.name} > $topic1',
        expectedTagComponent: 'stream:${stream.streamId}:a topic');

      receiveFcmMessage(async, data2);
      checkNotification(data2,
        messageStyleMessages: [data1, data2],
        expectedIsGroupConversation: true,
        // Title updates with latest casing of topic.
        expectedTitle: '#${stream.name} > $topic2',
        expectedTagComponent: 'stream:${stream.streamId}:a topic');
    })));

    test('stream message: conversation stays same when stream is renamed', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      var stream = eg.stream(streamId: 1, name: 'Before');
      const topic = 'topic';
      final message1 = eg.streamMessage(topic: topic, stream: stream);
      final data1 = messageFcmMessage(message1, streamName: stream.name);

      receiveFcmMessage(async, data1);
      checkNotification(data1,
        messageStyleMessages: [data1],
        expectedIsGroupConversation: true,
        expectedTitle: '#Before > $topic',
        expectedTagComponent: 'stream:${stream.streamId}:$topic');

      stream = eg.stream(streamId: 1, name: 'After');
      final message2 = eg.streamMessage(topic: topic, stream: stream);
      final data2 = messageFcmMessage(message2, streamName: stream.name);

      receiveFcmMessage(async, data2);
      checkNotification(data2,
        messageStyleMessages: [data1, data2],
        expectedIsGroupConversation: true,
        expectedTitle: '#After > $topic',
        expectedTagComponent: 'stream:${stream.streamId}:$topic');
    })));

    test('stream message: stream name omitted', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final stream = eg.stream();
      final message = eg.streamMessage(stream: stream);
      await checkNotifications(async, messageFcmMessage(message, streamName: null),
        expectedIsGroupConversation: true,
        expectedTitle: '#(unknown channel) > ${message.topic}',
        expectedTagComponent: 'stream:${message.streamId}:${message.topic}');
    })));

    test('group DM: 3 users', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final message = eg.dmMessage(from: eg.thirdUser, to: [eg.otherUser, eg.selfUser]);
      await checkNotifications(async, messageFcmMessage(message),
        expectedIsGroupConversation: true,
        expectedTitle: "${eg.thirdUser.fullName} to you and 1 other",
        expectedTagComponent: 'dm:${message.allRecipientIds.join(",")}');
    })));

    test('group DM: more than 3 users', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final message = eg.dmMessage(from: eg.thirdUser,
        to: [eg.otherUser, eg.selfUser, eg.fourthUser]);
      await checkNotifications(async, messageFcmMessage(message),
        expectedIsGroupConversation: true,
        expectedTitle: "${eg.thirdUser.fullName} to you and 2 others",
        expectedTagComponent: 'dm:${message.allRecipientIds.join(",")}');
    })));

    test('group DM: title updates with latest sender', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final message1 = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser, eg.thirdUser]);
      final data1 = messageFcmMessage(message1);
      final message2 = eg.dmMessage(from: eg.thirdUser, to: [eg.selfUser, eg.otherUser]);
      final data2 = messageFcmMessage(message2);

      final expectedTagComponent = 'dm:${message1.allRecipientIds.join(",")}';

      receiveFcmMessage(async, data1);
      checkNotification(data1,
        messageStyleMessages: [data1],
        expectedIsGroupConversation: true,
        expectedTitle: "${eg.otherUser.fullName} to you and 1 other",
        expectedTagComponent: expectedTagComponent);

      receiveFcmMessage(async, data2);
      checkNotification(data2,
        messageStyleMessages: [data1, data2],
        expectedIsGroupConversation: true,
        expectedTitle: "${eg.thirdUser.fullName} to you and 1 other",
        expectedTagComponent: expectedTagComponent);
    })));

    test('1:1 DM', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final message = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]);
      await checkNotifications(async, messageFcmMessage(message),
        expectedIsGroupConversation: false,
        expectedTitle: eg.otherUser.fullName,
        expectedTagComponent: 'dm:${message.allRecipientIds.join(",")}');
    })));

    test('1:1 DM: title updates when sender name changes', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final otherUser = eg.user(fullName: 'Before');
      final message1 = eg.dmMessage(from: otherUser, to: [eg.selfUser]);
      final data1 = messageFcmMessage(message1);

      final expectedTagComponent = 'dm:${message1.allRecipientIds.join(",")}';

      receiveFcmMessage(async, data1);
      checkNotification(data1,
        messageStyleMessages: [data1],
        expectedIsGroupConversation: false,
        expectedTitle: 'Before',
        expectedTagComponent: expectedTagComponent);

      otherUser.fullName = 'After';
      final message2 = eg.dmMessage(from: otherUser, to: [eg.selfUser]);
      final data2 = messageFcmMessage(message2);

      receiveFcmMessage(async, data2);
      checkNotification(data2,
        messageStyleMessages: [data1, data2],
        expectedIsGroupConversation: false,
        expectedTitle: 'After',
        expectedTagComponent: expectedTagComponent);
    })));

    test('1:1 DM: conversation stays same when sender email changes', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final otherUser = eg.user(email: 'before@example.com');
      final message1 = eg.dmMessage(from: otherUser, to: [eg.selfUser]);
      final data1 = messageFcmMessage(message1);

      final expectedTagComponent = 'dm:${message1.allRecipientIds.join(",")}';

      receiveFcmMessage(async, data1);
      checkNotification(data1,
        messageStyleMessages: [data1],
        expectedIsGroupConversation: false,
        expectedTitle: otherUser.fullName,
        expectedTagComponent: expectedTagComponent);

      otherUser.email = 'after@example.com';
      final message2 = eg.dmMessage(from: otherUser, to: [eg.selfUser]);
      final data2 = messageFcmMessage(message2);

      receiveFcmMessage(async, data2);
      checkNotification(data2,
        messageStyleMessages: [data1, data2],
        expectedIsGroupConversation: false,
        expectedTitle: otherUser.fullName,
        expectedTagComponent: expectedTagComponent);
    })));

    test('1:1 DM: sender avatar loading fails, remote error', () => runWithHttpClient(
      () => awaitFakeAsync((async) async {
        await init();
        final message = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]);
        final data = messageFcmMessage(message);
        receiveFcmMessage(async, data);
        checkNotification(data,
          messageStyleMessages: [data],
          expectedIsGroupConversation: false,
          expectedTitle: eg.otherUser.fullName,
          expectedTagComponent: 'dm:${message.allRecipientIds.join(",")}',
          expectedIconBitmap: null); // Failed to fetch avatar photo
      }),
      httpClientFactory: () => makeFakeHttpClient(
        response: http.Response.bytes([], HttpStatus.internalServerError))));

    test('1:1 DM: sender avatar loading fails, local error', () => runWithHttpClient(
      () => awaitFakeAsync((async) async {
        await init();
        final message = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]);
        final data = messageFcmMessage(message);
        receiveFcmMessage(async, data);
        checkNotification(data,
          messageStyleMessages: [data],
          expectedIsGroupConversation: false,
          expectedTitle: eg.otherUser.fullName,
          expectedTagComponent: 'dm:${message.allRecipientIds.join(",")}',
          expectedIconBitmap: null); // Failed to fetch avatar photo
      }),
      httpClientFactory: () => makeFakeHttpClient(
        exception: http.ClientException('Network failure'))));

    test('self-DM', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final message = eg.dmMessage(from: eg.selfUser, to: []);
      await checkNotifications(async, messageFcmMessage(message),
        expectedIsGroupConversation: false,
        expectedTitle: eg.selfUser.fullName,
        expectedTagComponent: 'dm:${message.allRecipientIds.join(",")}');
    })));

    test('remove: smoke', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final message = eg.streamMessage();
      final data = messageFcmMessage(message);
      final expectedGroupKey = '${data.realmUrl}|${data.userId}';

      check(testBinding.androidNotificationHost.activeNotifications).isEmpty();

      // Check on foreground event; onMessage
      receiveFcmMessage(async, data);
      check(testBinding.androidNotificationHost.activeNotifications).deepEquals(<Condition<Object?>>[
        conditionActiveNotif(data, 'stream:${message.streamId}:${message.topic}'),
        conditionSummaryActiveNotif(expectedGroupKey),
      ]);
      testBinding.firebaseMessaging.onMessage.add(
        RemoteMessage(data: removeFcmMessage([message]).toJson()));
      async.flushMicrotasks();
      check(testBinding.androidNotificationHost.activeNotifications).isEmpty();

      // Check on background event; onBackgroundMessage
      receiveFcmMessage(async, data);
      check(testBinding.androidNotificationHost.activeNotifications).deepEquals(<Condition<Object?>>[
        conditionActiveNotif(data, 'stream:${message.streamId}:${message.topic}'),
        conditionSummaryActiveNotif(expectedGroupKey),
      ]);
      testBinding.firebaseMessaging.onBackgroundMessage.add(
        RemoteMessage(data: removeFcmMessage([message]).toJson()));
      async.flushMicrotasks();
      check(testBinding.androidNotificationHost.activeNotifications).isEmpty();
    })));

    test('remove: clears conversation only if the removal event is for the last message', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final stream = eg.stream();
      const topicA = 'Topic A';
      final message1 = eg.streamMessage(stream: stream, topic: topicA);
      final data1 = messageFcmMessage(message1, streamName: stream.name);
      final message2 = eg.streamMessage(stream: stream, topic: topicA);
      final data2 = messageFcmMessage(message2, streamName: stream.name);
      final message3 = eg.streamMessage(stream: stream, topic: topicA);
      final data3 = messageFcmMessage(message3, streamName: stream.name);
      final conversationKey = 'stream:${stream.streamId}:${topicA.toLowerCase()}';
      final expectedGroupKey = '${data1.realmUrl}|${data1.userId}';

      check(testBinding.androidNotificationHost.activeNotifications).isEmpty();

      receiveFcmMessage(async, data1);
      receiveFcmMessage(async, data2);
      receiveFcmMessage(async, data3);
      check(testBinding.androidNotificationHost.activeNotifications).deepEquals(<Condition<Object?>>[
        conditionActiveNotif(data3, conversationKey),
        conditionSummaryActiveNotif(expectedGroupKey),
      ]);

      // A RemoveFcmMessage for the first two messages; the notification stays.
      receiveFcmMessage(async, removeFcmMessage([message1, message2]));
      check(testBinding.androidNotificationHost.activeNotifications).deepEquals(<Condition<Object?>>[
        conditionActiveNotif(data3, conversationKey),
        conditionSummaryActiveNotif(expectedGroupKey),
      ]);

      // Then a RemoveFcmMessage for the last message; clear the notification.
      receiveFcmMessage(async, removeFcmMessage([message3]));
      check(testBinding.androidNotificationHost.activeNotifications).isEmpty();
    })));

    test('remove: clears summary notification only if all conversation notifications are cleared', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final stream = eg.stream();

      const topicA = 'Topic A';
      final message1 = eg.streamMessage(stream: stream, topic: topicA);
      final data1 = messageFcmMessage(message1, streamName: stream.name);
      final conversationKey1 = 'stream:${stream.streamId}:${topicA.toLowerCase()}';
      final expectedGroupKey = '${data1.realmUrl}|${data1.userId}';

      const topicB = 'Topic B';
      final message2 = eg.streamMessage(stream: stream, topic: topicB);
      final data2 = messageFcmMessage(message2, streamName: stream.name);
      final conversationKey2 = 'stream:${stream.streamId}:${topicB.toLowerCase()}';

      check(testBinding.androidNotificationHost.activeNotifications).isEmpty();

      // Two notifications for different conversations; but same account.
      receiveFcmMessage(async, data1);
      receiveFcmMessage(async, data2);
      check(testBinding.androidNotificationHost.activeNotifications).deepEquals(<Condition<Object?>>[
        conditionActiveNotif(data1, conversationKey1),
        conditionSummaryActiveNotif(expectedGroupKey),
        conditionActiveNotif(data2, conversationKey2),
      ]);

      // A RemoveFcmMessage for first conversation; only clears the first conversation notif.
      receiveFcmMessage(async, removeFcmMessage([message1]));
      check(testBinding.androidNotificationHost.activeNotifications).deepEquals(<Condition<Object?>>[
        conditionSummaryActiveNotif(expectedGroupKey),
        conditionActiveNotif(data2, conversationKey2),
      ]);

      // Then a RemoveFcmMessage for the only remaining conversation;
      // clears both the conversation notif and summary notif.
      receiveFcmMessage(async, removeFcmMessage([message2]));
      check(testBinding.androidNotificationHost.activeNotifications).isEmpty();
    })));

    test('remove: different realm URLs but same user-ids and same message-ids', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init(addSelfAccount: false);

      final stream = eg.stream();
      const topic = 'Some Topic';
      final conversationKey = 'stream:${stream.streamId}:some topic';

      final account1 = eg.account(
        realmUrl: Uri.parse('https://1.chat.example'),
        id: 1001,
        user: eg.user(userId: 1001));
      await testBinding.globalStore.add(account1, eg.initialSnapshot());
      final message1 = eg.streamMessage(id: 1000, stream: stream, topic: topic);
      final data1 =
        messageFcmMessage(message1, account: account1, streamName: stream.name);
      final groupKey1 = '${account1.realmUrl}|${account1.userId}';

      final account2 = eg.account(
        realmUrl: Uri.parse('https://2.chat.example'),
        id: 1002,
        user: eg.user(userId: 1001));
      await testBinding.globalStore.add(account2, eg.initialSnapshot());
      final message2 = eg.streamMessage(id: 1000, stream: stream, topic: topic);
      final data2 =
        messageFcmMessage(message2, account: account2, streamName: stream.name);
      final groupKey2 = '${account2.realmUrl}|${account2.userId}';

      check(testBinding.androidNotificationHost.activeNotifications).isEmpty();

      receiveFcmMessage(async, data1);
      receiveFcmMessage(async, data2);
      check(testBinding.androidNotificationHost.activeNotifications).deepEquals(<Condition<Object?>>[
        conditionActiveNotif(data1, conversationKey),
        conditionSummaryActiveNotif(groupKey1),
        conditionActiveNotif(data2, conversationKey),
        conditionSummaryActiveNotif(groupKey2),
      ]);

      receiveFcmMessage(async, removeFcmMessage([message1], account: account1));
      check(testBinding.androidNotificationHost.activeNotifications).deepEquals(<Condition<Object?>>[
        conditionActiveNotif(data2, conversationKey),
        conditionSummaryActiveNotif(groupKey2),
      ]);

      receiveFcmMessage(async, removeFcmMessage([message2], account: account2));
      check(testBinding.androidNotificationHost.activeNotifications).isEmpty();
    })));

    test('remove: different user-ids but same realm URL and same message-ids', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init(addSelfAccount: false);
      final realmUrl = eg.realmUrl;
      final stream = eg.stream();
      const topic = 'Some Topic';
      final conversationKey = 'stream:${stream.streamId}:some topic';

      final account1 = eg.account(id: 1001, user: eg.user(userId: 1001), realmUrl: realmUrl);
      await testBinding.globalStore.add(account1, eg.initialSnapshot());
      final message1 = eg.streamMessage(id: 1000, stream: stream, topic: topic);
      final data1 =
        messageFcmMessage(message1, account: account1, streamName: stream.name);
      final groupKey1 = '${account1.realmUrl}|${account1.userId}';

      final account2 = eg.account(id: 1002, user: eg.user(userId: 1002), realmUrl: realmUrl);
      await testBinding.globalStore.add(account2, eg.initialSnapshot());
      final message2 = eg.streamMessage(id: 1000, stream: stream, topic: topic);
      final data2 =
        messageFcmMessage(message2, account: account2, streamName: stream.name);
      final groupKey2 = '${account2.realmUrl}|${account2.userId}';

      check(testBinding.androidNotificationHost.activeNotifications).isEmpty();

      receiveFcmMessage(async, data1);
      receiveFcmMessage(async, data2);
      check(testBinding.androidNotificationHost.activeNotifications).deepEquals(<Condition<Object?>>[
        conditionActiveNotif(data1, conversationKey),
        conditionSummaryActiveNotif(groupKey1),
        conditionActiveNotif(data2, conversationKey),
        conditionSummaryActiveNotif(groupKey2),
      ]);

      receiveFcmMessage(async, removeFcmMessage([message1], account: account1));
      check(testBinding.androidNotificationHost.activeNotifications).deepEquals(<Condition<Object?>>[
        conditionActiveNotif(data2, conversationKey),
        conditionSummaryActiveNotif(groupKey2),
      ]);

      receiveFcmMessage(async, removeFcmMessage([message2], account: account2));
      check(testBinding.androidNotificationHost.activeNotifications).isEmpty();
    })));

    test('removeNotificationsForAccount: removes notifications', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      final message = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]);
      receiveFcmMessage(async, messageFcmMessage(message));
      check(testBinding.androidNotificationHost.activeNotifications).isNotEmpty();

      await NotificationDisplayManager.removeNotificationsForAccount(
        eg.selfAccount.realmUrl, eg.selfAccount.userId);
      check(testBinding.androidNotificationHost.activeNotifications).isEmpty();
    })));

    test('removeNotificationsForAccount: leaves notifications for other accounts (same realm URL)', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init(addSelfAccount: false);

      final realmUrl = eg.realmUrl;
      final account1 = eg.account(id: 1001, user: eg.user(userId: 1001), realmUrl: realmUrl);
      final account2 = eg.account(id: 1002, user: eg.user(userId: 1002), realmUrl: realmUrl);
      await testBinding.globalStore.add(account1, eg.initialSnapshot());
      await testBinding.globalStore.add(account2, eg.initialSnapshot());

      check(testBinding.androidNotificationHost.activeNotifications).isEmpty();

      final message1 = eg.streamMessage();
      final message2 = eg.streamMessage();
      receiveFcmMessage(async, messageFcmMessage(message1, account: account1));
      receiveFcmMessage(async, messageFcmMessage(message2, account: account2));
      check(testBinding.androidNotificationHost.activeNotifications)
        .length.equals(4);

      await NotificationDisplayManager.removeNotificationsForAccount(
        realmUrl, account1.userId);
      check(testBinding.androidNotificationHost.activeNotifications)
        ..length.equals(2)
        ..first.notification.group.equals('$realmUrl|${account2.userId}');
    })));

    test('removeNotificationsForAccount leaves notifications for other accounts (same user-ids)', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init(addSelfAccount: false);

      final userId = 1001;
      final account1 = eg.account(
        id: 1001, user: eg.user(userId: userId),
        realmUrl: Uri.parse('https://realm1.example'));
      final account2 = eg.account(
        id: 1002, user: eg.user(userId: userId),
        realmUrl: Uri.parse('https://realm2.example'));
      await testBinding.globalStore.add(account1, eg.initialSnapshot());
      await testBinding.globalStore.add(account2, eg.initialSnapshot());

      final message1 = eg.streamMessage();
      final message2 = eg.streamMessage();
      receiveFcmMessage(async, messageFcmMessage(message1, account: account1));
      receiveFcmMessage(async, messageFcmMessage(message2, account: account2));
      check(testBinding.androidNotificationHost.activeNotifications)
        .length.equals(4);

      await NotificationDisplayManager.removeNotificationsForAccount(account1.realmUrl, userId);
      check(testBinding.androidNotificationHost.activeNotifications)
        ..length.equals(2)
        ..first.notification.group.equals('${account2.realmUrl}|$userId');
    })));

    test('removeNotificationsForAccount does nothing if there are no notifications', () => runWithHttpClient(() => awaitFakeAsync((async) async {
      await init();
      check(testBinding.androidNotificationHost.activeNotifications).isEmpty();

      await NotificationDisplayManager.removeNotificationsForAccount(eg.selfAccount.realmUrl, eg.selfAccount.userId);
      check(testBinding.androidNotificationHost.activeNotifications).isEmpty();
    })));
  });

  group('NotificationDisplayManager open', () {
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

extension on Subject<CopySoundResourceToMediaStoreCall> {
  Subject<String> get targetFileDisplayName => has((x) => x.targetFileDisplayName, 'targetFileDisplayName');
  Subject<String> get sourceResourceName => has((x) => x.sourceResourceName, 'sourceResourceName');
}

extension NotificationChannelChecks on Subject<NotificationChannel> {
  Subject<String> get id => has((x) => x.id, 'id');
  Subject<int> get importance => has((x) => x.importance, 'importance');
  Subject<String?> get name => has((x) => x.name, 'name');
  Subject<bool?> get lightsEnabled => has((x) => x.lightsEnabled, 'lightsEnabled');
  Subject<String?> get soundUrl => has((x) => x.soundUrl, 'soundUrl');
  Subject<Int64List?> get vibrationPattern => has((x) => x.vibrationPattern, 'vibrationPattern');
}

extension on Subject<AndroidNotificationHostApiNotifyCall> {
  Subject<String?> get tag => has((x) => x.tag, 'tag');
  Subject<int> get id => has((x) => x.id, 'id');
  Subject<bool?> get autoCancel => has((x) => x.autoCancel, 'autoCancel');
  Subject<String> get channelId => has((x) => x.channelId, 'channelId');
  Subject<int?> get color => has((x) => x.color, 'color');
  Subject<PendingIntent?> get contentIntent => has((x) => x.contentIntent, 'contentIntent');
  Subject<String?> get contentText => has((x) => x.contentText, 'contentText');
  Subject<String?> get contentTitle => has((x) => x.contentTitle, 'contentTitle');
  Subject<Map<String?, String?>?> get extras => has((x) => x.extras, 'extras');
  Subject<String?> get groupKey => has((x) => x.groupKey, 'groupKey');
  Subject<InboxStyle?> get inboxStyle => has((x) => x.inboxStyle, 'inboxStyle');
  Subject<bool?> get isGroupSummary => has((x) => x.isGroupSummary, 'isGroupSummary');
  Subject<MessagingStyle?> get messagingStyle => has((x) => x.messagingStyle, 'messagingStyle');
  Subject<int?> get number => has((x) => x.number, 'number');
  Subject<String?> get smallIconResourceName => has((x) => x.smallIconResourceName, 'smallIconResourceName');
}

extension on Subject<PendingIntent> {
  Subject<int> get requestCode => has((x) => x.requestCode, 'requestCode');
  Subject<AndroidIntent> get intent => has((x) => x.intent, 'intent');
  Subject<int> get flags => has((x) => x.flags, 'flags');
}

extension on Subject<AndroidIntent> {
  Subject<String> get action => has((x) => x.action, 'action');
  Subject<String> get dataUrl => has((x) => x.dataUrl, 'dataUrl');
  Subject<int> get flags => has((x) => x.flags, 'flags');
}

extension on Subject<InboxStyle> {
  Subject<String> get summaryText => has((x) => x.summaryText, 'summaryText');
}

extension on Subject<MessagingStyle> {
  Subject<Person> get user => has((x) => x.user, 'user');
  Subject<String?> get conversationTitle => has((x) => x.conversationTitle, 'conversationTitle');
  Subject<List<MessagingStyleMessage?>> get messages => has((x) => x.messages, 'messages');
  Subject<bool> get isGroupConversation => has((x) => x.isGroupConversation, 'isGroupConversation');
}

extension on Subject<Person> {
  Subject<Uint8List?> get iconBitmap => has((x) => x.iconBitmap, 'iconBitmap');
  Subject<String> get key => has((x) => x.key, 'key');
  Subject<String> get name => has((x) => x.name, 'name');
}

extension on Subject<MessagingStyleMessage> {
  Subject<String> get text => has((x) => x.text, 'text');
  Subject<int> get timestampMs => has((x) => x.timestampMs, 'timestampMs');
  Subject<Person> get person => has((x) => x.person, 'person');
}

extension on Subject<Notification> {
  Subject<String> get group => has((x) => x.group, 'group');
  Subject<Map<String?, String?>> get extras => has((x) => x.extras, 'extras');
}

extension on Subject<StatusBarNotification> {
  Subject<int> get id => has((x) => x.id, 'id');
  Subject<Notification> get notification => has((x) => x.notification, 'notification');
  Subject<String> get tag => has((x) => x.tag, 'tag');
}

extension on Subject<NotificationOpenPayload> {
  Subject<Uri> get realmUrl => has((x) => x.realmUrl, 'realmUrl');
  Subject<int> get userId => has((x) => x.userId, 'userId');
  Subject<Narrow> get narrow => has((x) => x.narrow, 'narrow');
}
