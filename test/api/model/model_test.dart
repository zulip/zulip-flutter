import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';

import '../../example_data.dart' as eg;
import '../../stdlib_checks.dart';
import 'model_checks.dart';

void main() {
  test('CustomProfileFieldChoiceDataItem', () {
    const input = '''{
      "0": {"text": "Option 0", "order": 1},
      "1": {"text": "Option 1", "order": 2},
      "2": {"text": "Option 2", "order": 3}
    }''';
    final decoded = jsonDecode(input) as Map<String, dynamic>;
    final choices = CustomProfileFieldChoiceDataItem.parseFieldDataChoices(decoded);
    check(choices).jsonEquals({
      '0': const CustomProfileFieldChoiceDataItem(text: 'Option 0'),
      '1': const CustomProfileFieldChoiceDataItem(text: 'Option 1'),
      '2': const CustomProfileFieldChoiceDataItem(text: 'Option 2'),
    });
  });

  group('User', () {
    final Map<String, dynamic> baseJson = Map.unmodifiable({
      'user_id': 123,
      'delivery_email': 'name@example.com',
      'email': 'name@example.com',
      'full_name': 'A User',
      'date_joined': '2023-04-28',
      'is_active': true,
      'is_owner': false,
      'is_admin': false,
      'is_guest': false,
      'is_billing_admin': false,
      'is_bot': false,
      'role': 400,
      'timezone': 'UTC',
      'avatar_version': 0,
      'profile_data': <String, dynamic>{},
    });

    User mkUser(Map<String, dynamic> specialJson) {
      return User.fromJson({ ...baseJson, ...specialJson });
    }

    test('delivery_email', () {
      check(mkUser({'delivery_email': 'name@email.com'}).deliveryEmail)
        .equals('name@email.com');
    });

    test('profile_data', () {
      check(mkUser({'profile_data': <String, dynamic>{}}).profileData).isNull();
      check(mkUser({'profile_data': null}).profileData).isNull();
      check(mkUser({'profile_data': {'1': {'value': 'foo'}}}).profileData)
        .isNotNull().keys.single.equals(1);
    });

    test('is_system_bot', () {
      check(mkUser({}).isSystemBot).isFalse();
      check(mkUser({'is_cross_realm_bot': true}).isSystemBot).isTrue();
      check(mkUser({'is_system_bot': true}).isSystemBot).isTrue();
    });
  });

  group('Subscription', () {
    test('converts color to int', () {
      Subscription subWithColor(String color) {
        return Subscription.fromJson(
          deepToJson(eg.subscription(eg.stream())) as Map<String, dynamic>
            ..['color'] = color,
        );
      }
      check(subWithColor('#e79ab5').color).equals(0xffe79ab5);
      check(subWithColor('#ffffff').color).equals(0xffffffff);
      check(subWithColor('#000000').color).equals(0xff000000);
    });
  });

  group('Message', () {
    Map<String, dynamic> baseStreamJson() =>
      deepToJson(eg.streamMessage()) as Map<String, dynamic>;

    test('subject -> topic', () {
      check(baseStreamJson()).not((it) => it.containsKey('topic'));
      check(Message.fromJson(baseStreamJson()
        ..['subject'] = 'hello'
      )).isA<StreamMessage>()
        .topic.equals(const TopicName('hello'));
    });

    test('match_subject -> matchTopic', () {
      check(baseStreamJson()).not((it) => it.containsKey('match_topic'));
      check(Message.fromJson(baseStreamJson()
        ..['match_subject'] = 'yo'
      )).matchTopic.equals('yo');
    });

    test('no crash on unrecognized flag', () {
      final m1 = Message.fromJson(
        (deepToJson(eg.streamMessage()) as Map<String, dynamic>)
          ..['flags'] = ['read', 'something_unknown'],
      );
      check(m1).flags.deepEquals([MessageFlag.read, MessageFlag.unknown]);

      final m2 = Message.fromJson(
        (deepToJson(eg.dmMessage(from: eg.selfUser, to: [eg.otherUser])) as Map<String, dynamic>)
          ..['flags'] = ['read', 'something_unknown'],
      );
      check(m2).flags.deepEquals([MessageFlag.read, MessageFlag.unknown]);
    });

    test('require displayRecipient on parse', () {
      check(() => StreamMessage.fromJson(baseStreamJson()..['display_recipient'] = null))
        .throws<DisallowedNullValueException>();

      check(() => StreamMessage.fromJson(baseStreamJson()..remove('display_recipient')))
        .throws<MissingRequiredKeysException>();
    });

    // Code relevant to messageEditState is tested separately in the
    // MessageEditState group.
  });

  group('DmMessage', () {
    final Map<String, dynamic> baseJson = Map.unmodifiable(deepToJson(
      eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]),
    ) as Map<String, dynamic>);

    DmMessage parse(Map<String, dynamic> specialJson) {
      return DmMessage.fromJson({ ...baseJson, ...specialJson });
    }

    Iterable<DmRecipient> asRecipients(Iterable<User> users) {
      return users.map((u) =>
        DmRecipient(id: u.userId, email: u.email, fullName: u.fullName));
    }

    Map<String, dynamic> withRecipients(Iterable<User> recipients) {
      final from = recipients.first;
      return {
        'sender_id': from.userId,
        'sender_email': from.email,
        'sender_full_name': from.fullName,
        'display_recipient': asRecipients(recipients).map((r) => r.toJson()).toList(),
      };
    }

    User user2 = eg.user(userId: 2);
    User user3 = eg.user(userId: 3);
    User user11 = eg.user(userId: 11);

    test('displayRecipient', () {
      check(parse(withRecipients([user2])).displayRecipient)
        .deepEquals(asRecipients([user2]));

      check(parse(withRecipients([user2, user3])).displayRecipient)
        .deepEquals(asRecipients([user2, user3]));
      check(parse(withRecipients([user3, user2])).displayRecipient)
        .deepEquals(asRecipients([user2, user3]));

      check(parse(withRecipients([user2, user3, user11])).displayRecipient)
        .deepEquals(asRecipients([user2, user3, user11]));
      check(parse(withRecipients([user3, user11, user2])).displayRecipient)
        .deepEquals(asRecipients([user2, user3, user11]));
      check(parse(withRecipients([user11, user2, user3])).displayRecipient)
        .deepEquals(asRecipients([user2, user3, user11]));
    });

    test('allRecipientIds', () {
      check(parse(withRecipients([user2])).allRecipientIds)
        .deepEquals([2]);

      check(parse(withRecipients([user2, user3])).allRecipientIds)
        .deepEquals([2, 3]);
      check(parse(withRecipients([user3, user2])).allRecipientIds)
        .deepEquals([2, 3]);

      check(parse(withRecipients([user2, user3, user11])).allRecipientIds)
        .deepEquals([2, 3, 11]);
      check(parse(withRecipients([user3, user11, user2])).allRecipientIds)
        .deepEquals([2, 3, 11]);
      check(parse(withRecipients([user11, user2, user3])).allRecipientIds)
        .deepEquals([2, 3, 11]);
    });
  });

  group('MessageEditState', () {
    Map<String, dynamic> baseJson() => deepToJson(eg.streamMessage()) as Map<String, dynamic>;

    group('Edit history is absent', () {
      test('Message with no evidence of an edit history -> none', () {
        check(Message.fromJson(baseJson()..['edit_history'] = null))
          .editState.equals(MessageEditState.none);
      });

      test('Message without edit history has last edit timestamp -> edited', () {
        check(Message.fromJson(baseJson()
            ..['edit_history'] = null
            ..['last_edit_timestamp'] = 1678139636))
          .editState.equals(MessageEditState.edited);
      });
    });

    void checkEditState(MessageEditState editState, List<Map<String, dynamic>> editHistory){
      check(Message.fromJson(baseJson()..['edit_history'] = editHistory))
        .editState.equals(editState);
    }

    group('edit history exists', () {
      test('Moved message has last edit timestamp but no actual edits -> moved', () {
        check(Message.fromJson(baseJson()
            ..['edit_history'] = [{'prev_stream': 5, 'stream': 7}]
            ..['last_edit_timestamp'] = 1678139636))
          .editState.equals(MessageEditState.moved);
      });

      test('Channel change only -> moved', () {
        checkEditState(MessageEditState.moved,
          [{'prev_stream': 5, 'stream': 7}]);
      });

      test('Topic name change only -> moved', () {
        checkEditState(MessageEditState.moved,
          [{'prev_topic': 'old_topic', 'topic': 'new_topic'}]);
      });

      test('Both topic and content changed -> edited', () {
        checkEditState(MessageEditState.edited, [
          {'prev_topic': 'old_topic', 'topic': 'new_topic'},
          {'prev_content': 'old_content'},
        ]);
        checkEditState(MessageEditState.edited, [
          {'prev_content': 'old_content'},
          {'prev_topic': 'old_topic', 'topic': 'new_topic'},
        ]);
      });

      test('Both topic and content changed in a single edit -> edited', () {
        checkEditState(MessageEditState.edited,
          [{'prev_topic': 'old_topic', 'topic': 'new_topic', 'prev_content': 'old_content'}]);
      });

      test('Content change only -> edited', () {
        checkEditState(MessageEditState.edited,
          [{'prev_content': 'old_content'}]);
      });

      test("'prev_topic' present without the 'topic' field -> moved", () {
        checkEditState(MessageEditState.moved,
          [{'prev_topic': 'old_topic'}]);
      });

      test("'prev_subject' present from a pre-5.0 server -> moved", () {
        checkEditState(MessageEditState.moved,
          [{'prev_subject': 'old_topic'}]);
      });
    });

    group('topic resolved in edit history', () {
      test('Topic was only resolved -> none', () {
        checkEditState(MessageEditState.none,
          [{'prev_topic': 'old_topic', 'topic': '✔ old_topic'}]);
      });

      test('Topic was resolved but the content changed in the history -> edited', () {
        checkEditState(MessageEditState.edited, [
          {'prev_topic': 'old_topic', 'topic': '✔ old_topic'},
          {'prev_content': 'old_content'},
        ]);
      });

      test('Topic was resolved but it also moved in the history -> moved', () {
        checkEditState(MessageEditState.moved, [
          {'prev_topic': 'old_topic', 'topic': 'new_topic'},
          {'prev_topic': '✔ old_topic', 'topic': 'old_topic'},
        ]);
      });

      test('Topic was moved but it also was resolved in the history -> moved', () {
        checkEditState(MessageEditState.moved, [
          {'prev_topic': '✔ old_topic', 'topic': 'old_topic'},
          {'prev_topic': 'old_topic', 'topic': 'new_topic'},
        ]);
      });

      test('Unresolving topic with a weird prefix -> moved', () {
          checkEditState(MessageEditState.moved,
            [{'prev_topic': '✔ ✔old_topic', 'topic': 'old_topic'}]);
      });
    });
  });
}
