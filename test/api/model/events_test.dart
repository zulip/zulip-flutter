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

  test('subscription/remove: deserialize stream_ids correctly', () {
    check(Event.fromJson({
      'id': 1,
      'type': 'subscription',
      'op': 'remove',
      'subscriptions': [
        {'stream_id': 123, 'name': 'name 1'},
        {'stream_id': 456, 'name': 'name 2'},
      ],
    }) as SubscriptionRemoveEvent).streamIds.jsonEquals([123, 456]);
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
    check(mkEvent([MessageFlag.read])).message.flags.deepEquals([MessageFlag.read]);
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
        ..propagateMode.equals(PropagateMode.changeAll);
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

    final baseJsonStream = {
      'id': 1,
      'type': 'delete_message',
      'message_ids': [1, 2, 3],
      'message_type': 'stream',
    };

    check(() => DeleteMessageEvent.fromJson({
      ...baseJsonStream
    })).throws<void>();

    check(() => DeleteMessageEvent.fromJson({
      ...baseJsonStream, 'stream_id': 1, 'topic': 'some topic',
    })).returnsNormally();

    check(() => DeleteMessageEvent.fromJson({
      ...baseJsonStream, 'stream_id': 1,
    })).throws<void>();

    check(() => DeleteMessageEvent.fromJson({
      ...baseJsonStream, 'topic': 'some topic',
    })).throws<void>();
  });

  test('delete_message: private -> direct', () {
    check(DeleteMessageEvent.fromJson({
      'id': 1,
      'type': 'delete_message',
      'message_ids': [1, 2, 3],
      'message_type': 'private',
    })).messageType.equals(MessageType.direct);
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
               .values.single.type.equals(MessageType.direct);
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
      })).messageType.equals(MessageType.direct);
    });

    test('stream type missing streamId/topic', () {
      check(() => TypingEvent.fromJson({
        ...baseJson, 'message_type': 'stream', 'stream_id': 123, 'topic': 'foo'}))
        .returnsNormally();
      check(() => TypingEvent.fromJson({
        ...baseJson, 'message_type': 'stream'})).throws<void>();
      check(() => TypingEvent.fromJson({
        ...baseJson, 'message_type': 'stream', 'topic': 'foo'})).throws<void>();
      check(() => TypingEvent.fromJson({
        ...baseJson, 'message_type': 'stream', 'stream_id': 123})).throws<void>();
    });

    test('direct type sort recipient ids', () {
      check(TypingEvent.fromJson({
        ...directMessageJson,
        'recipients': [4, 10, 8, 2, 1].map((e) => {'user_id': e, 'email': '$e@example.com'}).toList(),
      })).recipientIds.isNotNull().deepEquals([1, 2, 4, 8, 10]);
    });
  });
}
