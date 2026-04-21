import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/notifications.dart';

import '../stdlib_checks.dart';

void main() {
  group('E2EE types', () {
    final baseBaseJson = <String, Object?>{
      "realm_url": "https://zulip.example.com/",
      "realm_name": "Example Organization",
      "user_id": 234,
    };

    void checkParseFails(Map<String, Object?> data) {
      check(() => NotifPayload.fromJson(data)).throws<void>();
    }

    group('NotifPayload', () {
      test('parse fails on missing or bad type', () {
        check(NotifPayload.fromJson({})).isA<UnexpectedNotifPayload>();
        check(NotifPayload.fromJson({'type': 'nonsense'})).isA<UnexpectedNotifPayload>();
        check(NotifPayload.fromJson({'event': 'nonsense'})).isA<UnexpectedNotifPayload>();
      });
    });

    group('NotifPayloadNewMessage', () {
      // These JSON test data aim to reflect what current servers send.
      // We ignore some of the fields; see tests.

      final baseJson = {
        ...baseBaseJson,
        "type": "message",

        "sender_id": 123,
        "sender_avatar_url": "https://zulip.example.com/avatar/123.jpeg",
        "sender_full_name": "A Sender",

        "time": 1546300800,
        "message_id": 12345,

        "content": "This is a message",
      };

      final streamJson = {
        ...baseJson,
        "recipient_type": "channel",
        "channel_id": 42,
        "channel_name": "denmark",
        "topic": "play",
      };

      final groupDmJson = {
        ...baseJson,
        "recipient_type": "direct",
        "recipient_user_ids": [123, 234, 345],
      };

      final dmJson = {
        ...baseJson,
        "recipient_type": "direct",
        "recipient_user_ids": [123, 234],
      };

      NotifPayloadNewMessage parse(Map<String, dynamic> json) {
        return NotifPayload.fromJson(json) as NotifPayloadNewMessage;
      }

      test("fields get parsed right in happy path", () {
        check(parse(streamJson))
          ..realmUrl.equals(Uri.parse(baseJson['realm_url'] as String))
          ..realmName.equals(baseBaseJson['realm_name'] as String)
          ..userId.equals(234)
          ..senderId.equals(123)
          ..senderAvatarUrl.equals(Uri.parse(streamJson['sender_avatar_url'] as String))
          ..senderFullName.equals(streamJson['sender_full_name'] as String)
          ..messageId.equals(12345)
          ..recipient.isA<NotifPayloadChannelRecipient>().which((it) => it
            ..channelId.equals(42)
            ..channelName.equals(streamJson['channel_name'] as String)
            ..topic.jsonEquals(streamJson['topic']!))
          ..content.equals(streamJson['content'] as String)
          ..time.equals(1546300800);

        check(parse(groupDmJson))
          .recipient.isA<NotifPayloadDmRecipient>()
          .allRecipientIds.deepEquals([123, 234, 345]);

        check(parse(dmJson))
          .recipient.isA<NotifPayloadDmRecipient>()
          .allRecipientIds.deepEquals([123, 234]);
      });

      test('optional fields missing cause no error', () {
        check(parse({ ...streamJson }..remove('realm_name')))
          .realmName.isNull();

        check(parse({ ...streamJson }..remove('channel_name')))
          .recipient.isA<NotifPayloadChannelRecipient>().which((it) => it
            ..channelId.equals(42)
            ..channelName.isNull());
      });

      test('toJson round-trips', () {
        void checkRoundTrip(Map<String, Object?> json) {
          check(parse(json).toJson())
            .deepEquals({ ...json }
              ..remove('recipient_type') // Redundant with channel_id / stream_id.
            );
        }

        checkRoundTrip(streamJson);
        checkRoundTrip(groupDmJson);
        checkRoundTrip(dmJson);
        checkRoundTrip({ ...streamJson }..remove('channel_name'));
      });

      test('ignored fields missing have no effect', () {
        final baseline = parse(streamJson);
        check(parse({ ...streamJson }..remove('recipient_type'))).jsonEquals(baseline);
      });

      test('obsolete or novel fields have no effect', () {
        final baseline = parse(dmJson);
        void checkInert(Map<String, String> extraJson) =>
          check(parse({ ...dmJson, ...extraJson })).jsonEquals(baseline);

        // Hypothetical future field.
        checkInert({ 'awesome_feature': 'enabled' });
      });

      group("parse failures on malformed 'message'", () {
        int n = 1;
        test("${n++}", () => checkParseFails({ ...dmJson }
                                              ..remove('realm_url')));
        test(skip: true, // Dart's Uri.parse is lax in what it accepts.
            "${n++}", () => checkParseFails({ ...dmJson, 'realm_url': 'zulip.example.com' }));
        test(skip: true, // Dart's Uri.parse is lax in what it accepts.
            "${n++}", () => checkParseFails({ ...dmJson, 'realm_url': '/examplecorp' }));

        test("${n++}", () => checkParseFails({ ...streamJson, 'channel_id': 'abc' }));
        test("${n++}", () => checkParseFails({ ...streamJson }..remove('topic')));
        test("${n++}", () => checkParseFails({ ...groupDmJson, 'recipient_user_ids': ['12'] }));

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

    group('NotifPayloadRemove', () {
      final baseJson = {
        ...baseBaseJson,
        'type': 'remove',

        'message_ids': [123, 234],
      };

      NotifPayloadRemove parse(Map<String, dynamic> json) {
        return NotifPayload.fromJson(json) as NotifPayloadRemove;
      }

      test('fields get parsed right in happy path', () {
        check(parse(baseJson))
          ..realmUrl.equals(Uri.parse(baseJson['realm_url'] as String))
          ..realmName.equals(baseJson['realm_name'] as String)
          ..userId.equals(234)
          ..messageIds.deepEquals([123, 234]);
      });

      test('toJson round-trips', () {
        check(parse(baseJson).toJson())
          .deepEquals(baseJson);
      });

      test('obsolete or novel fields have no effect', () {
        final baseline = parse(baseJson);
        check(parse({ ...baseJson, 'awesome_feature': 'enabled' })).jsonEquals(baseline);
      });

      group('parse failures on malformed data', () {
        int n = 1;

        test("${n++}", () => checkParseFails({ ...baseJson }
                                              ..remove('realm_url')));
        test(skip: true, // Dart's Uri.parse is lax in what it accepts.
            "${n++}", () => checkParseFails({ ...baseJson, 'realm_url': 'zulip.example.com' }));
        test(skip: true, // Dart's Uri.parse is lax in what it accepts.
            "${n++}", () => checkParseFails({ ...baseJson, 'realm_url': '/examplecorp' }));
      });
    });
  });

  // TODO(server-12) remove legacy non-E2EE notification tests.
  group('Legacy plaintext types', () {
    final baseBaseJson = {
      "realm_uri": "https://zulip.example.com/",  // TODO(server-9)
      "realm_url": "https://zulip.example.com/",
      "realm_name": "Example Organization",
      "user_id": "234",
    };

    void checkParseFails(Map<String, String> data) {
      check(() => LegacyFcmMessage.fromJson(data)).throws<void>();
    }

    group('LegacyFcmMessage', () {
      test('parse fails on missing or bad event type', () {
        check(LegacyFcmMessage.fromJson({})).isA<UnexpectedFcmMessage>();
        check(LegacyFcmMessage.fromJson({'event': 'nonsense'})).isA<UnexpectedFcmMessage>();
      });
    });

    group('MessageLegacyFcmMessage', () {
      // These JSON test data aim to reflect what current servers send.
      // We ignore some of the fields; see tests.

      final baseJson = {
        ...baseBaseJson,
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
        "recipient_type": "stream",
        "stream_id": "42",
        "stream": "denmark",
        "topic": "play",
      };

      final groupDmJson = {
        ...baseJson,
        "recipient_type": "private",
        "pm_users": "123,234,345",
      };

      final dmJson = {
        ...baseJson,
        "recipient_type": "private",
      };

      MessageLegacyFcmMessage parse(Map<String, dynamic> json) {
        return LegacyFcmMessage.fromJson(json) as MessageLegacyFcmMessage;
      }

      test("fields get parsed right in happy path", () {
        check(parse(streamJson))
          ..realmUrl.equals(Uri.parse(baseJson['realm_url'] as String))
          ..realmUrl.equals(Uri.parse(baseJson['realm_uri'] as String)) // TODO(server-9)
          ..realmName.equals(baseBaseJson['realm_name'] as String)
          ..userId.equals(234)
          ..senderId.equals(123)
          ..senderAvatarUrl.equals(Uri.parse(streamJson['sender_avatar_url'] as String))
          ..senderFullName.equals(streamJson['sender_full_name'] as String)
          ..messageId.equals(12345)
          ..recipient.isA<LegacyFcmMessageChannelRecipient>().which((it) => it
            ..channelId.equals(42)
            ..channelName.equals(streamJson['stream'] as String)
            ..topic.jsonEquals(streamJson['topic']!))
          ..content.equals(streamJson['content'] as String)
          ..time.equals(1546300800);

        check(parse(groupDmJson))
          .recipient.isA<LegacyFcmMessageDmRecipient>()
          .allRecipientIds.deepEquals([123, 234, 345]);

        check(parse(dmJson))
          .recipient.isA<LegacyFcmMessageDmRecipient>()
          .allRecipientIds.deepEquals([123, 234]);
      });

      test('optional fields missing cause no error', () {
        check(parse({ ...streamJson }..remove('realm_name')))
          .realmName.isNull();

        check(parse({ ...streamJson }..remove('stream')))
          .recipient.isA<LegacyFcmMessageChannelRecipient>().which((it) => it
            ..channelId.equals(42)
            ..channelName.isNull());
      });

      test('toJson round-trips', () {
        void checkRoundTrip(Map<String, String> json) {
          check(parse(json).toJson())
            .deepEquals({ ...json }
              ..remove('recipient_type') // Redundant with stream_id.
              ..remove('content_truncated') // Redundant with content.
              ..remove('sender_email') // Redundant with sender_id.
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
        check(parse({ ...streamJson }..remove('content_truncated'))).jsonEquals(baseline);
        check(parse({ ...streamJson }..remove('sender_email'))).jsonEquals(baseline);
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

      test('uses deprecated fields when newer fields are missing', () {
        final baseline = parse(dmJson);

        // FL 257 deprecated 'realm_uri' in favor of 'realm_url'.
        final jsonSansRealm =
          { ...dmJson }..remove('realm_url')..remove('realm_uri');
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

        test("${n++}", () => checkParseFails({ ...streamJson, 'stream_id': 'abc' }));
        test("${n++}", () => checkParseFails({ ...streamJson, 'stream_id': '12,34' }));
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
        test("${n++}", () => checkParseFails({ ...dmJson }..remove('zulip_message_id')));
        test("${n++}", () => checkParseFails({ ...dmJson, 'zulip_message_id': '12,34' }));
        test("${n++}", () => checkParseFails({ ...dmJson, 'zulip_message_id': 'abc' }));
        test("${n++}", () => checkParseFails({ ...dmJson }..remove('content')));
        test("${n++}", () => checkParseFails({ ...dmJson }..remove('time')));
        test("${n++}", () => checkParseFails({ ...dmJson, 'time': '12:34' }));
      });
    });

    group('RemoveLegacyFcmMessage', () {
      final baseJson = {
        ...baseBaseJson,
        'event': 'remove',

        'zulip_message_ids': '123,234',
        'zulip_message_id': '123',
      };

      RemoveLegacyFcmMessage parse(Map<String, dynamic> json) {
        return LegacyFcmMessage.fromJson(json) as RemoveLegacyFcmMessage;
      }

      test('fields get parsed right in happy path', () {
        check(parse(baseJson))
          ..realmUrl.equals(Uri.parse(baseJson['realm_url'] as String))
          ..realmUrl.equals(Uri.parse(baseJson['realm_uri'] as String)) // TODO(server-9)
          ..realmName.equals(baseJson['realm_name'] as String)
          ..userId.equals(234)
          ..messageIds.deepEquals([123, 234]);
      });

      test('toJson round-trips', () {
        check(parse(baseJson).toJson())
          .deepEquals({ ...baseJson }..remove('zulip_message_id'));
      });

      test('ignored fields missing have no effect', () {
        final baseline = parse(baseJson);
        check(parse({ ...baseJson }..remove('zulip_message_id'))).jsonEquals(baseline);
      });

      test('obsolete or novel fields have no effect', () {
        final baseline = parse(baseJson);
        check(parse({ ...baseJson, 'awesome_feature': 'enabled' })).jsonEquals(baseline);
      });

      test('uses deprecated fields when newer fields are missing', () {
        final baseline = parse(baseJson);

        // FL 257 deprecated 'realm_uri' in favor of 'realm_url'.
        final jsonSansRealm =
          { ...baseJson }..remove('realm_url')..remove('realm_uri');
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
          test("${n++}", () => checkParseFails({ ...baseJson, 'zulip_message_ids': badIntList }));
        }
      });
    });
  });
}

extension UnexpectedNotifPayloadChecks on Subject<UnexpectedNotifPayload> {
  Subject<Map<String, dynamic>> get json => has((x) => x.json, 'json');
}

extension NotifPayloadWithIdentityChecks on Subject<NotifPayloadWithIdentity> {
  Subject<Uri> get realmUrl => has((x) => x.realmUrl, 'realmUrl');
  Subject<String?> get realmName => has((x) => x.realmName, 'realmName');
  Subject<int> get userId => has((x) => x.userId, 'userId');
}

extension NotifPayloadNewMessageChecks on Subject<NotifPayloadNewMessage> {
  Subject<int> get senderId => has((x) => x.senderId, 'senderId');
  Subject<Uri> get senderAvatarUrl => has((x) => x.senderAvatarUrl, 'senderAvatarUrl');
  Subject<String> get senderFullName => has((x) => x.senderFullName, 'senderFullName');
  Subject<NotifPayloadRecipient> get recipient => has((x) => x.recipient, 'recipient');
  Subject<int> get messageId => has((x) => x.messageId, 'messageId');
  Subject<int> get time => has((x) => x.time, 'time');
  Subject<String> get content => has((x) => x.content, 'content');
}

extension NotifPayloadChannelRecipientChecks on Subject<NotifPayloadChannelRecipient> {
  Subject<int> get channelId => has((x) => x.channelId, 'channelId');
  Subject<String?> get channelName => has((x) => x.channelName, 'channelName');
  Subject<TopicName> get topic => has((x) => x.topic, 'topic');
}

extension NotifPayloadDmRecipientChecks on Subject<NotifPayloadDmRecipient> {
  Subject<List<int>> get allRecipientIds => has((x) => x.allRecipientIds, 'allRecipientIds');
}

extension NotifPayloadRemoveChecks on Subject<NotifPayloadRemove> {
  Subject<List<int>> get messageIds => has((x) => x.messageIds, 'messageIds');
}
