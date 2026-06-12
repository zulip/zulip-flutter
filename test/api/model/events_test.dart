import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';

import '../../example_data.dart' as eg;
import '../../stdlib_checks.dart';
import 'events_checks.dart';
import 'model_checks.dart';

void main() {
  test('user_settings: all known settings have event handling', () {
    final dataClassFieldNames = UserSettings.debugKnownNames;
    final enumNames = UserSettingName.values.map((n) => n.name);
    final missingEnumNames = dataClassFieldNames.where((key) => !enumNames.contains(key)).toList();
    check(
      missingEnumNames,
      because:
        'You have added these fields to [UserSettings]\n'
        'without handling the corresponding forms of the\n'
        'user_settings/update event in [PerAccountStore]:\n'
        '  $missingEnumNames\n'
        'To do that, please follow these steps:\n'
        '  (1) Add corresponding members to the [UserSettingName] enum.\n'
        '  (2) Then, re-run the command to refresh the .g.dart files.\n'
        '  (3) Resolve the Dart analysis errors about not exhaustively\n'
        '      matching on that enum, by adding new `switch` cases\n'
        '      on the pattern of the existing cases.'
    ).isEmpty();
  });

  test('user_settings/update: unknown property', () {
    final json = {
      'id': 1,
      'type': 'user_settings',
      'op': 'update',
      'property': 'twenty_four_hour_time',
      'value': true,
    };

    check(UserSettingsUpdateEvent.fromJson(json))
      ..property.equals(.twentyFourHourTime)
      ..value.equals(TwentyFourHourTimeMode.twentyFourHour);

    for (final unknown in ['unknown_user_setting_name', '']) {
      json['property'] = unknown;
      check(UserSettingsUpdateEvent.fromJson(json))
        ..property.equals(.unknown)
        ..value.equals(null);
    }
  });

  group('device/update', () {
    final baseJson = {'id': 1, 'type': 'device', 'op': 'update', 'device_id': 3 };

    test('push_key_id absent', () {
      check(Event.fromJson({ ...baseJson }))
        .isA<DeviceUpdateEvent>().pushKeyId.isNull();
    });

    test('push_key_id null', () {
      check(Event.fromJson({ ...baseJson, 'push_key_id': null }))
        .isA<DeviceUpdateEvent>().pushKeyId.equals(JsonNullable(null));
    });

    test('push_key_id an int', () {
      check(Event.fromJson({ ...baseJson, 'push_key_id': 123 }))
        .isA<DeviceUpdateEvent>().pushKeyId.equals(JsonNullable(123));
    });

    test('pending_push_token_id absent', () {
      check(Event.fromJson({ ...baseJson }))
        .isA<DeviceUpdateEvent>().pendingPushTokenId.isNull();
    });

    test('pending_push_token_id null', () {
      check(Event.fromJson({ ...baseJson, 'pending_push_token_id': null }))
        .isA<DeviceUpdateEvent>().pendingPushTokenId.equals(JsonNullable(null));
    });

    test('pending_push_token_id a string', () {
      check(Event.fromJson({ ...baseJson, 'pending_push_token_id': 'ab12' }))
        .isA<DeviceUpdateEvent>().pendingPushTokenId.equals(JsonNullable('ab12'));
    });
  });

  group('realm_user/update', () {
    Map<String, Object?> mkJson(Map<String, Object?> data) =>
      {'id': 1, 'type': 'realm_user', 'op': 'update',
       'person': {'user_id': 1, ...data}};

    test('delivery_email absent', () {
      check(Event.fromJson(mkJson({})))
        .isA<RealmUserUpdateEvent>().deliveryEmail.isNull();
    });

    test('delivery_email null', () {
      check(Event.fromJson(mkJson({'delivery_email': null})))
        .isA<RealmUserUpdateEvent>().deliveryEmail.equals(const JsonNullable(null));
    });

    test('delivery_email a string', () {
      check(Event.fromJson(mkJson({'delivery_email': 'name@example.org'})))
        .isA<RealmUserUpdateEvent>().deliveryEmail.equals(
          const JsonNullable('name@example.org'));
    });
  });

  test('stream/update: unknown property', () {
    final json = {
      'id': 1,
      'type': 'stream',
      'op': 'update',
      'stream_id': 1,
      'name': 'channel name',
      'property': 'is_recently_active',
      'value': true,
    };

    check(ChannelUpdateEvent.fromJson(json))
      ..property.equals(.isRecentlyActive)
      ..value.equals(true);

    for (final unknown in ['unknown_channel_property', '']) {
      json['property'] = unknown;
      check(ChannelUpdateEvent.fromJson(json))
        ..property.equals(.unknown)
        ..value.equals(null);
    }
  });

  test('subscription/remove: deserialize stream_ids correctly', () {
    check(Event.fromJson({
      'id': 1,
      'type': 'subscription',
      'op': 'remove',
      'subscriptions': [
        {'stream_id': 123, 'name': 'name 1'},
        {'stream_id': 456, 'name': 'name 2'},
      ],
    }) as SubscriptionRemoveEvent).channelIds.jsonEquals([123, 456]);
  });

  test('subscription/update: convert color correctly', () {
    check(Event.fromJson({
      'id': 1,
      'type': 'subscription',
      'op': 'update',
      'stream_id': 1,
      'property': 'color',
      'value': '#123456',
    }) as SubscriptionUpdateEvent).value.equals(0xff123456);
  });

  test('user_topic: handle unknown value', () {
    final json = {
      'id': 1,
      'type': 'user_topic',
      'stream_id': 1,
      'topic_name': 'topic',
      'last_updated': 1781195876,
      'visibility_policy': 1,
    };

    check(UserTopicEvent.fromJson(json).visibilityPolicy).equals(.muted);

    json['visibility_policy'] = -100;
    check(UserTopicEvent.fromJson(json).visibilityPolicy).equals(.unknown);
  });

  test('message: move flags into message object', () {
    final message = eg.streamMessage();
    MessageEvent mkEvent(List<MessageFlag> flags) => Event.fromJson({
      'type': 'message',
      'id': 1,
      'message': (deepToJson(message) as Map<String, dynamic>)..remove('flags'),
      'flags': flags.map((f) => f.toJson()).toList(),
    }) as MessageEvent;
    check(mkEvent(message.flags)).message.jsonEquals(message);
    check(mkEvent([])).message.flags.deepEquals([]);
    check(mkEvent([.read])).message.flags.deepEquals(<MessageFlag>[.read]);
  });

  group('update_message', () {
    final message = eg.streamMessage();
    final baseJson = {
      'id': 1,
      'type': 'update_message',
      'user_id': eg.selfUser.userId,
      'rendering_only': false,
      'message_id': message.id,
      'message_ids': [message.id],
      'flags': <String>[],
      'edit_timestamp': 1718741351,
      'stream_id': eg.stream().streamId,
    };

    test('handle unknown message flags', () {
      check(UpdateMessageEvent.fromJson({
        ...baseJson,
        'flags': ['has_alert_word', 'unknown_message_flag', ''],
      })).flags.deepEquals(<MessageFlag>[.hasAlertWord, .unknown, .unknown]);
    });

    final baseMoveJson = { ...baseJson,
      'orig_subject': 'foo',
      'propagate_mode': 'change_all',
    };

    test('smoke moveData', () {
      check(Event.fromJson({ ...baseMoveJson,
        'stream_id': 1,
        'new_stream_id': 2,
        'orig_subject': 'foo',
        'subject': 'bar',
        'propagate_mode': 'change_all',
      })).isA<UpdateMessageEvent>().moveData.isNotNull()
        ..origStreamId.equals(1)
        ..newStreamId.equals(2)
        ..origTopic.equals(const TopicName('foo'))
        ..newTopic.equals(const TopicName('bar'))
        ..propagateMode.equals(.changeAll);
    });

    test('stream_id -> origStreamId', () {
      check(Event.fromJson({ ...baseMoveJson,
        'stream_id': 1,
        'new_stream_id': 2,
      })).isA<UpdateMessageEvent>().moveData.isNotNull()
        ..origStreamId.equals(1)
        ..newStreamId.equals(2);
    });

    test('orig_subject -> origTopic, subject -> newTopic', () {
      check(Event.fromJson({ ...baseMoveJson,
        'orig_subject': 'foo',
        'subject': 'bar',
      })).isA<UpdateMessageEvent>().moveData.isNotNull()
        ..origTopic.equals(const TopicName('foo'))
        ..newTopic.equals(const TopicName('bar'));
    });

    test('new channel, same topic: fill in newTopic', () {
      // The server omits 'subject' in this situation.
      check(Event.fromJson({ ...baseMoveJson,
        'stream_id': 1,
        'new_stream_id': 2,
        'orig_subject': 'foo',
        'subject': null,
      })).isA<UpdateMessageEvent>().moveData.isNotNull()
        ..origTopic.equals(const TopicName('foo'))
        ..newTopic.equals(const TopicName('foo'));
    });

    test('same channel, new topic; fill in newStreamId', () {
      // The server omits 'new_stream_id' in this situation.
      check(Event.fromJson({ ...baseMoveJson,
        'stream_id': 1,
        'new_stream_id': null,
        'orig_subject': 'foo',
        'subject': 'bar',
      })).isA<UpdateMessageEvent>().moveData.isNotNull()
        ..origStreamId.equals(1)
        ..newStreamId.equals(1);
    });

    test('no message move', () {
      check(Event.fromJson({ ...baseJson,
        'orig_content': 'foo',
        'orig_rendered_content': 'foo',
        'content': 'bar',
        'rendered_content': 'bar',
      })).isA<UpdateMessageEvent>().moveData.isNull();
    });

    test('stream move but no orig_subject', () {
      check(() => Event.fromJson({ ...baseMoveJson,
        'stream_id': 1,
        'new_stream_id': 2,
        'orig_subject': null,
      })).throws<void>();
    });

    test('move but no subject or new_stream_id', () {
      check(() => Event.fromJson({ ...baseMoveJson,
        'new_stream_id': null,
        'subject': null,
      })).throws<void>();
    });

    test('move but no orig_stream_id', () {
      check(() => Event.fromJson({ ...baseMoveJson,
        'stream_id': null,
        'new_stream_id': 2,
      })).throws<void>();
    });

    test('move but no propagate_mode', () {
      check(() => Event.fromJson({ ...baseMoveJson,
        'orig_subject': 'foo',
        'subject': 'bar',
        'propagate_mode': null,
      })).throws<void>();
    });
  });

  test('delete_message: require streamId and topic for stream messages', () {
    check(() => DeleteMessageEvent.fromJson({
      'id': 1,
      'type': 'delete_message',
      'message_ids': [1, 2, 3],
      'message_type': 'private',
    })).returnsNormally();

    // TODO(server-future): remove
    final baseJsonStream = {
      'id': 1,
      'type': 'delete_message',
      'message_ids': [1, 2, 3],
      'message_type': 'stream',
    };

    // Future server.
    final baseJsonChannel = {
      'id': 1,
      'type': 'delete_message',
      'message_ids': [1, 2, 3],
      'message_type': 'channel',
    };

    for (final baseJson in [baseJsonStream, baseJsonChannel]) {
      check(() => DeleteMessageEvent.fromJson({
        ...baseJson
      })).throws<void>();

      check(() => DeleteMessageEvent.fromJson({
        ...baseJson, 'stream_id': 1, 'topic': 'some topic',
      })).returnsNormally();

      check(() => DeleteMessageEvent.fromJson({
        ...baseJson, 'stream_id': 1,
      })).throws<void>();

      check(() => DeleteMessageEvent.fromJson({
        ...baseJson, 'topic': 'some topic',
      })).throws<void>();
    }
  });

  test('delete_message: private -> direct', () {
    check(DeleteMessageEvent.fromJson({
      'id': 1,
      'type': 'delete_message',
      'message_ids': [1, 2, 3],
      'message_type': 'private',
    })).messageType.equals(.direct);
  });

  test('delete_message: stream -> channel', () {
    check(DeleteMessageEvent.fromJson({
      'id': 1,
      'type': 'delete_message',
      'message_ids': [1, 2, 3],
      'message_type': 'stream',
      'stream_id': 1,
      'topic': 'some topic',
    })).messageType.equals(.channel);
  });

  group('update_message_flags/remove', () {
    final baseJson = {
      'id': 1,
      'type': 'update_message_flags',
      'op': 'remove',
      'flag': 'starred',
      'messages': [123],
      'all': false,
    };
    final messageDetail = {'type': 'direct', 'mentioned': false, 'user_ids': [2]};

    test('require messageDetails in mark-as-unread', () {
      check(() => UpdateMessageFlagsRemoveEvent.fromJson(baseJson)).returnsNormally();
      check(() => UpdateMessageFlagsRemoveEvent.fromJson({
        ...baseJson, 'flag': 'read',
      })).throws<void>();
      check(() => UpdateMessageFlagsRemoveEvent.fromJson({
        ...baseJson,
        'flag': 'read',
        'message_details': {'123': messageDetail},
      })).returnsNormally();
    });

    test('private -> direct', () {
      check(UpdateMessageFlagsRemoveEvent.fromJson({
        ...baseJson,
        'flag': 'read',
        'message_details': {
          '123': {
            ...messageDetail,
            'type': 'private',
          }}})).messageDetails.isNotNull()
               .values.single.type.equals(.direct);
    });

    test('stream -> channel', () {
      final messageDetail = {'type': 'stream', 'mentioned': false, 'stream_id': 1, 'topic': 'some topic'};
      check(UpdateMessageFlagsRemoveEvent.fromJson({
        ...baseJson,
        'flag': 'read',
        'message_details': {
          '123': messageDetail
        }})).messageDetails.isNotNull()
            .values.single.type.equals(.channel);
    });
  });

  group('typing status event', () {
    final baseJson = {
      'id': 1,
      'type': 'typing',
      'op': 'start',
      'sender': {'user_id': 123, 'email': '123@example.com'},
    };

    final directMessageJson = {
      ...baseJson,
      'message_type': 'direct',
      'recipients': [1, 2, 3].map((e) => {'user_id': e, 'email': '$e@example.com'}).toList(),
    };

    test('direct message typing events', () {
      check(TypingEvent.fromJson(directMessageJson))
        ..recipientIds.isNotNull().deepEquals([1, 2, 3])
        ..senderId.equals(123);
    });

    test('private type missing recipient', () {
      check(() => TypingEvent.fromJson({
        ...baseJson, 'message_type': 'private'})).throws<void>();
    });

    test('private -> direct', () {
      check(TypingEvent.fromJson({
        ...directMessageJson,
        'message_type': 'private',
      })).messageType.equals(.direct);
    });

    test('stream/channel type missing streamId/topic', () {
      // TODO(server-future): remove
      final baseJsonStream = {...baseJson, 'message_type': 'stream'};
      // Future server.
      final baseJsonChannel = {...baseJson, 'message_type': 'channel'};

      for (final baseJson in [baseJsonStream, baseJsonChannel]) {
        check(() => TypingEvent.fromJson({
          ...baseJson, 'stream_id': 123, 'topic': 'foo'}))
          .returnsNormally();
        check(() => TypingEvent.fromJson({
          ...baseJson})).throws<void>();
        check(() => TypingEvent.fromJson({
          ...baseJson, 'topic': 'foo'})).throws<void>();
        check(() => TypingEvent.fromJson({
          ...baseJson, 'stream_id': 123})).throws<void>();
      }
    });

    test('direct type sort recipient ids', () {
      check(TypingEvent.fromJson({
        ...directMessageJson,
        'recipients': [4, 10, 8, 2, 1].map((e) => {'user_id': e, 'email': '$e@example.com'}).toList(),
      })).recipientIds.isNotNull().deepEquals([1, 2, 4, 8, 10]);
    });
  });
}
