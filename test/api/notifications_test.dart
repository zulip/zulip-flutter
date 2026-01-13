import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/notifications.dart';

import '../stdlib_checks.dart';

void main() {
  final baseBaseJson = <String, Object?>{ // TODO(#1764) finish updating these test fixtures
    "realm_url": "https://zulip.example.com/",
    "user_id": "234",
  };

  // Before E2EE notifications, the data comes directly as FCM payloads,
  // which we treat as "JSON" for convenience but are really string-string maps.
  // TODO(server-12) cut all these pre-E2EE forms (including in negative tests)
  final baseBaseJsonPreE2ee = <String, String>{
    "server": "zulip.example.cloud",
    "realm_id": "4",
    "realm_uri": "https://zulip.example.com/",  // TODO(server-9)
    "realm_url": "https://zulip.example.com/",
    "user_id": "234",
  };

  void checkParseFails(Map<String, Object?> data) {
    check(() => FcmMessage.fromJson(data)).throws<void>();
  }

  group('FcmMessage', () {
    test('parse fails on missing or bad type', () {
      check(FcmMessage.fromJson({})).isA<UnexpectedFcmMessage>();
      check(FcmMessage.fromJson({'type': 'nonsense'})).isA<UnexpectedFcmMessage>();
      check(FcmMessage.fromJson({'event': 'nonsense'})).isA<UnexpectedFcmMessage>();
    });
  });

  group('MessageFcmMessage', () {
    // These JSON test data aim to reflect what current servers send.
    // We ignore some of the fields; see tests.

    final baseJson = {
      ...baseBaseJson,
      "type": "message",

      "sender_id": "123",
      "sender_avatar_url": "https://zulip.example.com/avatar/123.jpeg",
      "sender_full_name": "A Sender",

      "time": "1546300800",
      "message_id": 12345,

      "content": "This is a message",
    };

    final baseJsonPreE2ee = <String, String>{
      ...baseBaseJsonPreE2ee,
      "event": "message",

      "sender_id": "123",
      "sender_email": "sender@example.com",
      "sender_avatar_url": "https://zulip.example.com/avatar/123.jpeg",
      "sender_full_name": "A Sender",

      "time": "1546300800",
      "zulip_message_id": "12345",

      "content": "This is a message",
      "content_truncated": "This is a m…",
    };

    final streamJson = {
      ...baseJson,
      "recipient_type": "channel",
      "stream_id": "42",
      "stream": "denmark",
      "topic": "play",
    };

    final streamJsonPreE2ee = {
      ...baseJson,
      "recipient_type": "stream",
      "stream_id": "42",
      "stream": "denmark",
      "topic": "play",
    };

    final groupDmJson = {
      ...baseJson,
      "recipient_type": "direct",
      "pm_users": "123,234,345",
    };

    final groupDmJsonPreE2ee = {
      ...baseJson,
      "recipient_type": "private",
      "pm_users": "123,234,345",
    };

    final dmJson = {
      ...baseJson,
      "recipient_type": "direct",
    };

    final dmJsonPreE2ee = <String, String>{
      ...baseJsonPreE2ee,
      "recipient_type": "private",
    };

    MessageFcmMessage parse(Map<String, dynamic> json) {
      return FcmMessage.fromJson(json) as MessageFcmMessage;
    }

    test("fields get parsed right in happy path", () {
      check(parse(streamJson))
        ..realmUrl.equals(Uri.parse(baseJson['realm_url'] as String))
        ..realmUrl.equals(Uri.parse(baseJsonPreE2ee['realm_uri'] as String)) // TODO(server-9)
        ..userId.equals(234)
        ..senderId.equals(123)
        ..senderAvatarUrl.equals(Uri.parse(streamJson['sender_avatar_url'] as String))
        ..senderFullName.equals(streamJson['sender_full_name'] as String)
        ..messageId.equals(12345)
        ..recipient.isA<FcmMessageChannelRecipient>().which((it) => it
          ..channelId.equals(42)
          ..channelName.equals(streamJson['stream'] as String)
          ..topic.jsonEquals(streamJson['topic']!))
        ..content.equals(streamJson['content'] as String)
        ..time.equals(1546300800);

      check(parse(groupDmJson))
        .recipient.isA<FcmMessageDmRecipient>()
        .allRecipientIds.deepEquals([123, 234, 345]);

      check(parse(dmJson))
        .recipient.isA<FcmMessageDmRecipient>()
        .allRecipientIds.deepEquals([123, 234]);
    });

    test('optional fields missing cause no error', () {
      check(parse({ ...streamJson }..remove('stream')))
        .recipient.isA<FcmMessageChannelRecipient>().which((it) => it
          ..channelId.equals(42)
          ..channelName.isNull());
    });

    test('toJson round-trips', () {
      void checkRoundTrip(Map<String, Object?> json) {
        check(parse(json).toJson())
          .deepEquals({ ...json }
            ..remove('recipient_type') // Redundant with stream_id.
          );
      }

      checkRoundTrip(streamJson);
      checkRoundTrip(groupDmJson);
      checkRoundTrip(dmJson);
      checkRoundTrip({ ...streamJson }..remove('stream'));
    });

    test('ignored fields missing have no effect', () {
      final baseline = parse(streamJson);
      check(parse({ ...streamJson }..remove('recipient_type'))).jsonEquals(baseline);
      check(parse({ ...streamJsonPreE2ee }..remove('server'))).jsonEquals(baseline);
      check(parse({ ...streamJsonPreE2ee }..remove('realm_id'))).jsonEquals(baseline);
    });

    test('obsolete or novel fields have no effect', () {
      final baseline = parse(dmJson);
      void checkInert(Map<String, String> extraJson) =>
        check(parse({ ...dmJson, ...extraJson })).jsonEquals(baseline);

      // Cut in 2017, in zulip/zulip@c007b9ea4.
      checkInert({ 'user': 'client@example.com' });

      // Cut in 2023, in zulip/zulip@5d8897b90.
      checkInert({ 'alert': 'New private message from A Sender' });

      // Hypothetical future field.
      checkInert({ 'awesome_feature': 'enabled' });
    });

    test('pre-E2EE forms accepted too', () {
      check(parse(streamJsonPreE2ee)).jsonEquals(parse(streamJson));
      check(parse(groupDmJsonPreE2ee)).jsonEquals(parse(groupDmJson));
      check(parse(dmJsonPreE2ee)).jsonEquals(parse(dmJson));
    });

    test('uses deprecated fields when newer fields are missing', () {
      final baseline = parse(dmJson);

      // FL 257 deprecated 'realm_uri' in favor of 'realm_url'.
      final jsonSansRealm =
        { ...dmJsonPreE2ee }..remove('realm_url')..remove('realm_uri');
      check(parse({ ...jsonSansRealm, 'realm_url': 'https://zulip.example.com/' }))
        .jsonEquals(baseline);
    });

    group("parse failures on malformed 'message'", () {
      int n = 1;
      test("${n++}", () => checkParseFails({ ...dmJson }
                                            ..remove('realm_url')
                                            ..remove('realm_uri'))); // TODO(server-9)
      test(skip: true, // Dart's Uri.parse is lax in what it accepts.
           "${n++}", () => checkParseFails({ ...dmJson, 'realm_url': 'zulip.example.com' }));
      test(skip: true, // Dart's Uri.parse is lax in what it accepts.
           "${n++}", () => checkParseFails({ ...dmJson, 'realm_url': '/examplecorp' }));

      test("${n++}", () => checkParseFails({ ...streamJson, 'stream_id': '12,34' }));
      test("${n++}", () => checkParseFails({ ...streamJson, 'stream_id': 'abc' }));
      test("${n++}", () => checkParseFails({ ...streamJson }..remove('topic')));
      test("${n++}", () => checkParseFails({ ...groupDmJson, 'pm_users': 'abc,34' }));
      test("${n++}", () => checkParseFails({ ...groupDmJson, 'pm_users': '12,abc' }));
      test("${n++}", () => checkParseFails({ ...groupDmJson, 'pm_users': '12,' }));

      test("${n++}", () => checkParseFails({ ...dmJson }..remove('sender_avatar_url')));
      test(skip: true, // Dart's Uri.parse is lax in what it accepts.
           "${n++}", () => checkParseFails({ ...dmJson, 'sender_avatar_url': '/avatar/123.jpeg' }));
      test(skip: true, // Dart's Uri.parse is lax in what it accepts.
           "${n++}", () => checkParseFails({ ...dmJson, 'sender_avatar_url': '' }));

      test("${n++}", () => checkParseFails({ ...dmJson }..remove('sender_id')));
      test("${n++}", () => checkParseFails({ ...dmJson }..remove('sender_full_name')));
      test("${n++}", () => checkParseFails({ ...dmJson }..remove('message_id')));
      test("${n++}", () => checkParseFails({ ...dmJson, 'message_id': '12,34' }));
      test("${n++}", () => checkParseFails({ ...dmJson, 'message_id': 'abc' }));
      test("${n++}", () => checkParseFails({ ...dmJson }..remove('content')));
      test("${n++}", () => checkParseFails({ ...dmJson }..remove('time')));
      test("${n++}", () => checkParseFails({ ...dmJson, 'time': '12:34' }));
    });
  });

  group('RemoveFcmMessage', () {
    final baseJson = {
      ...baseBaseJson,
      'type': 'remove',

      'message_ids': [123, 234],
    };

    final preE2eeJson = <String, String>{
      ...baseBaseJsonPreE2ee,
      'event': 'remove',

      'zulip_message_ids': '123,234',
      'zulip_message_id': '123',
    };

    RemoveFcmMessage parse(Map<String, dynamic> json) {
      return FcmMessage.fromJson(json) as RemoveFcmMessage;
    }

    test('fields get parsed right in happy path', () {
      check(parse(baseJson))
        ..realmUrl.equals(Uri.parse(baseJson['realm_url'] as String))
        ..realmUrl.equals(Uri.parse(preE2eeJson['realm_uri'] as String)) // TODO(server-9)
        ..userId.equals(234)
        ..messageIds.deepEquals([123, 234]);
    });

    test('toJson round-trips', () {
      check(parse(baseJson).toJson())
        .deepEquals(baseJson);
    });

    test('ignored fields missing have no effect', () {
      final baseline = parse(baseJson);
      check(parse({ ...preE2eeJson }..remove('server'))).jsonEquals(baseline);
      check(parse({ ...preE2eeJson }..remove('realm_id'))).jsonEquals(baseline);
    });

    test('obsolete or novel fields have no effect', () {
      final baseline = parse(baseJson);
      check(parse({ ...baseJson, 'awesome_feature': 'enabled' })).jsonEquals(baseline);
    });

    test('pre-E2EE forms accepted too', () {
      check(parse(preE2eeJson)).jsonEquals(parse(baseJson));
    });

    test('uses deprecated fields when newer fields are missing', () {
      final baseline = parse(baseJson);

      // FL 257 deprecated 'realm_uri' in favor of 'realm_url'.
      final jsonSansRealm =
        { ...preE2eeJson }..remove('realm_url')..remove('realm_uri');
      check(parse({ ...jsonSansRealm, 'realm_url': 'https://zulip.example.com/' }))
        .jsonEquals(baseline);
    });

    group('parse failures on malformed data', () {
      int n = 1;

      test("${n++}", () => checkParseFails({ ...baseJson }
                                            ..remove('realm_url')
                                            ..remove('realm_uri'))); // TODO(server-9)
      test(skip: true, // Dart's Uri.parse is lax in what it accepts.
           "${n++}", () => checkParseFails({ ...baseJson, 'realm_url': 'zulip.example.com' }));
      test(skip: true, // Dart's Uri.parse is lax in what it accepts.
           "${n++}", () => checkParseFails({ ...baseJson, 'realm_url': '/examplecorp' }));

      for (final badIntList in ["abc,34", "12,abc", "12,", ""]) {
        test("${n++}", () => checkParseFails({ ...baseJson, 'message_ids': badIntList }));
      }
    });
  });
}

extension UnexpectedFcmMessageChecks on Subject<UnexpectedFcmMessage> {
  Subject<Map<String, dynamic>> get json => has((x) => x.json, 'json');
}

extension FcmMessageWithIdentityChecks on Subject<FcmMessageWithIdentity> {
  Subject<Uri> get realmUrl => has((x) => x.realmUrl, 'realmUrl');
  Subject<int> get userId => has((x) => x.userId, 'userId');
}

extension MessageFcmMessageChecks on Subject<MessageFcmMessage> {
  Subject<int> get senderId => has((x) => x.senderId, 'senderId');
  Subject<Uri> get senderAvatarUrl => has((x) => x.senderAvatarUrl, 'senderAvatarUrl');
  Subject<String> get senderFullName => has((x) => x.senderFullName, 'senderFullName');
  Subject<FcmMessageRecipient> get recipient => has((x) => x.recipient, 'recipient');
  Subject<int> get messageId => has((x) => x.messageId, 'messageId');
  Subject<int> get time => has((x) => x.time, 'time');
  Subject<String> get content => has((x) => x.content, 'content');
}

extension FcmMessageChannelRecipientChecks on Subject<FcmMessageChannelRecipient> {
  Subject<int> get channelId => has((x) => x.channelId, 'channelId');
  Subject<String?> get channelName => has((x) => x.channelName, 'channelName');
  Subject<TopicName> get topic => has((x) => x.topic, 'topic');
}

extension FcmMessageDmRecipientChecks on Subject<FcmMessageDmRecipient> {
  Subject<List<int>> get allRecipientIds => has((x) => x.allRecipientIds, 'allRecipientIds');
}

extension RemoveFcmMessageChecks on Subject<RemoveFcmMessage> {
  Subject<List<int>> get messageIds => has((x) => x.messageIds, 'messageIds');
}
