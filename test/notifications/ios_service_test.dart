import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/notifications.dart';
import 'package:zulip/host/ios_notifications.g.dart';
import 'package:zulip/model/database.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/notifications/ios_service.dart';
import 'package:zulip/notifications/open.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import 'display_test.dart' show encryptNotification, notifPayloadNewMessage;

/// Encode a notification payload into the form APNs would supply it in.
///
/// The result is suitable for passing to a method like
/// `testBinding.iosNotifFlutterApi.didReceivePushNotification`.
Future<Map<Object?, Object?>> encodeApnsPayload(NotifPayloadWithIdentity data) async {
  final account = testBinding.globalStore.accounts.where((account) =>
    account.realmUrl.origin == data.realmUrl.origin
    && account.userId == data.userId).single;
  final pushKey = testBinding.globalStore.pushKeys.perAccount(account.id)
    .latestPushKey!;
  final encrypted = await encryptNotification(pushKey.pushKey,
    utf8.encode(jsonEncode(data)));

  return {
    'push_key_id': pushKey.pushKeyId,
    'encrypted_data': base64Encode(encrypted),
  };
}

void main() {
  TestZulipBinding.ensureInitialized();

  Future<void> addAccount(Account account, {
    int? zulipFeatureLevel,
  }) async {
    final initialSnapshot = eg.initialSnapshot(
      zulipFeatureLevel: zulipFeatureLevel);
    await testBinding.globalStore.add(account, initialSnapshot);
    await testBinding.globalStore.pushKeys.perAccount(account.id).insertPushKey(
      eg.pushKey(account: account).toCompanion(false));
  }

  Future<void> init({bool addSelfAccount = true}) async {
    addTearDown(testBinding.reset);
    if (addSelfAccount) {
      await addAccount(eg.selfAccount);
    }
    addTearDown(IosNotificationService.debugReset);
    IosNotificationService.init();
  }

  Future<void> checkNotification(
    NotifPayloadNewMessage data, {
    Account? account,
    required String expectedTitle,
    required String expectedSubtitle,
  }) async {
    account ??= eg.selfAccount;
    assert(account.userId == data.userId && account.realmUrl == data.realmUrl);

    final payload = await encodeApnsPayload(data);
    final result = await testBinding.iosNotifFlutterApi.didReceivePushNotification(
      NotificationContent(payload: payload));

    final expectedNotificationUrl = NotificationOpenPayload(
      realmUrl: data.realmUrl,
      userId: data.userId,
      narrow: switch (data.recipient) {
        NotifPayloadChannelRecipient(:var channelId, :var topic) =>
          TopicNarrow(channelId, topic),
        NotifPayloadDmRecipient(:var allRecipientIds) =>
          DmNarrow(allRecipientIds: allRecipientIds, selfUserId: data.userId),
      }).buildNotificationUrl();

    check(result)
      ..title.equals(expectedTitle)
      ..subtitle.equals(expectedSubtitle)
      ..body.equals(data.content)
      ..userInfo.deepEquals({
        NotificationOpenPayload.kIosNotificationUrlKey: expectedNotificationUrl.toString(),
      });
  }

  test('stream message', () async {
    await init();
    final sender = eg.otherUser;
    final stream = eg.stream();
    final message = eg.streamMessage(stream: stream, sender: sender);
    await checkNotification(
      notifPayloadNewMessage(message, streamName: stream.name),
      expectedTitle: '#${stream.name} > ${message.topic}',
      expectedSubtitle: '${sender.fullName}:');
  });

  test('group DM: 3 users', () async {
    await init();
    final message = eg.dmMessage(from: eg.thirdUser, to: [eg.otherUser, eg.selfUser]);
    await checkNotification(notifPayloadNewMessage(message),
      expectedTitle: "${eg.thirdUser.fullName} to you and 1 other",
      expectedSubtitle: '');
  });

  test('1:1 DM', () async {
    await init();
    final message = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]);
    await checkNotification(notifPayloadNewMessage(message),
      expectedTitle: eg.otherUser.fullName,
      expectedSubtitle: '');
  });

  test('self-DM', () async {
    await init();
    final message = eg.dmMessage(from: eg.selfUser, to: []);
    await checkNotification(notifPayloadNewMessage(message),
      expectedTitle: eg.selfUser.fullName,
      expectedSubtitle: '');
  });
}

extension on Subject<ImprovedNotificationContent> {
  Subject<String> get title => has((x) => x.title, 'title');
  Subject<String> get subtitle => has((x) => x.subtitle, 'subtitle');
  Subject<String> get body => has((x) => x.body, 'body');
  Subject<Map<Object?, Object?>> get userInfo => has((x) => x.userInfo, 'userInfo');
}
