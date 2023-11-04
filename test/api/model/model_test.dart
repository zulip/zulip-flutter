import 'dart:convert';

import 'package:checks/checks.dart';
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
    final choices = CustomProfileFieldChoiceDataItem.parseFieldDataChoices(jsonDecode(input));
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
      check(mkUser({'delivery_email': 'name@email.com'}).deliveryEmailStaleDoNotUse)
        .equals('name@email.com');
    });

    test('profile_data', () {
      check(mkUser({'profile_data': <String, dynamic>{}}).profileData).isNull();
      check(mkUser({'profile_data': null}).profileData).isNull();
      check(mkUser({'profile_data': {'1': {'value': 'foo'}}}).profileData)
        .isNotNull().deepEquals({1: it()});
    });

    test('is_system_bot', () {
      check(mkUser({}).isSystemBot).isFalse();
      check(mkUser({'is_cross_realm_bot': true}).isSystemBot).isTrue();
      check(mkUser({'is_system_bot': true}).isSystemBot).isTrue();
    });
  });

  group('Message', () {
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
}
