import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/basic.dart';

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

  test('UserStatusChange', () {
    void doCheck({
      required (String? statusText, String? emojiName,
                String? emojiCode, String? reactionType)          incoming,
      required (Option<String?> text, Option<StatusEmoji?> emoji) expected,
    }) {
      check(UserStatusChange.fromJson({
        'status_text': incoming.$1,
        'emoji_name': incoming.$2,
        'emoji_code': incoming.$3,
        'reaction_type': incoming.$4,
      }))
        ..text.equals(expected.$1)
        ..emoji.equals(expected.$2);
    }

    doCheck(
      incoming: ('Busy', 'working_on_it', '1f6e0', 'unicode_emoji'),
      expected: (OptionSome('Busy'), OptionSome(StatusEmoji(
                                       emojiName: 'working_on_it',
                                       emojiCode: '1f6e0',
                                       reactionType: ReactionType.unicodeEmoji))));

    doCheck(
      incoming: ('', 'working_on_it', '1f6e0', 'unicode_emoji'),
      expected: (OptionSome(null), OptionSome(StatusEmoji(
                                     emojiName: 'working_on_it',
                                     emojiCode: '1f6e0',
                                     reactionType: ReactionType.unicodeEmoji))));

    doCheck(
      incoming: (null, 'working_on_it', '1f6e0', 'unicode_emoji'),
      expected: (OptionNone(), OptionSome(StatusEmoji(
                                 emojiName: 'working_on_it',
                                 emojiCode: '1f6e0',
                                 reactionType: ReactionType.unicodeEmoji))));

    doCheck(
      incoming: ('Busy', '', '', ''),
      expected: (OptionSome('Busy'), OptionSome(null)));

    doCheck(
      incoming: ('Busy', null, null, null),
      expected: (OptionSome('Busy'), OptionNone()));

    doCheck(
      incoming: ('', '', '', ''),
      expected: (OptionSome(null), OptionSome(null)));

    doCheck(
      incoming: (null, null, null, null),
      expected: (OptionNone(), OptionNone()));

    // For the API quirk when `reaction_type` is 'unicode_emoji' when the
    // emoji is cleared.
    doCheck(
      incoming: ('', '', '', 'unicode_emoji'),
      expected: (OptionSome(null), OptionSome(null)));

    // Hardly likely to happen from the API standpoint, but we handle it anyway.
    doCheck(
      incoming: (null, null, null, 'unicode_emoji'),
      expected: (OptionNone(), OptionNone()));
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

  group('TopicName', () {
    test('unresolve', () {
      void doCheck(TopicName input, TopicName expected) {
        final output = input.unresolve();
        check(output).apiName.equals(expected.apiName);
      }

      doCheck(eg.t('some topic'),       eg.t('some topic'));
      doCheck(eg.t('Some Topic'),       eg.t('Some Topic'));
      doCheck(eg.t('✔ some topic'),     eg.t('some topic'));
      doCheck(eg.t('✔ Some Topic'),     eg.t('Some Topic'));

      doCheck(eg.t('Some ✔ Topic'),     eg.t('Some ✔ Topic'));
      doCheck(eg.t('✔ Some ✔ Topic'),   eg.t('Some ✔ Topic'));

      doCheck(eg.t('✔ ✔✔✔ some topic'), eg.t('some topic'));
      doCheck(eg.t('✔ ✔ ✔✔some topic'), eg.t('some topic'));
    });

    test('isSameAs', () {
      void doCheck(TopicName topicA, TopicName topicB, bool expected) {
        check(topicA.isSameAs(topicB)).equals(expected);
      }

      doCheck(eg.t('some topic'),   eg.t('some topic'),   true);
      doCheck(eg.t('SOME TOPIC'),   eg.t('SOME TOPIC'),   true);
      doCheck(eg.t('Some Topic'),   eg.t('sOME tOPIC'),   true);
      doCheck(eg.t('✔ a'),          eg.t('✔ a'),          true);

      doCheck(eg.t('✔ some topic'), eg.t('some topic'),   false);
      doCheck(eg.t('SOME TOPIC'),   eg.t('✔ SOME TOPIC'), false);
      doCheck(eg.t('✔ Some Topic'), eg.t('sOME tOPIC'),   false);

      doCheck(eg.t('✔ a'),          eg.t('✔ b'),          false);
    });
  });

  group('DmMessage', () {
    final Map<String, dynamic> baseJson = Map.unmodifiable(deepToJson(
      eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]),
    ) as Map<String, dynamic>);

    DmMessage parse(Map<String, dynamic> specialJson) {
      return DmMessage.fromJson({ ...baseJson, ...specialJson });
    }

    List<Map<String, dynamic>> asRecipients(Iterable<User> users) {
      return users.map((u) =>
        {'id': u.userId, 'email': u.email, 'full_name': u.fullName}).toList();
    }

    Map<String, dynamic> withRecipients(Iterable<User> recipients) {
      final from = recipients.first;
      return {
        'sender_id': from.userId,
        'sender_email': from.email,
        'sender_full_name': from.fullName,
        'display_recipient': asRecipients(recipients),
      };
    }

    User user2 = eg.user(userId: 2);
    User user3 = eg.user(userId: 3);
    User user11 = eg.user(userId: 11);

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

      // Technically the topic *was* unresolved, so MessageEditState.none
      // would be valid and preferable -- if it didn't need more intense
      // computation than we're comfortable with in a hot codepath, i.e.,
      // a regex test instead of a simple `startsWith` / `substring` check.
      // See comment on the implementation, and discussion:
      //   https://github.com/zulip/zulip-flutter/pull/1242#discussion_r1917592157
      test('Unresolving topic with a weird prefix -> moved', () {
          checkEditState(MessageEditState.moved,
            [{'prev_topic': '✔ ✔old_topic', 'topic': 'old_topic'}]);
      });

      // Similar reasoning as in the previous test.
      // Also, Zulip doesn't produce topics with a weird resolved-topic prefix,
      // so this case can only be produced by unusual input in an
      // edit/move-topic UI. A "moved" marker seems like a fine response
      // in that circumstance.
      test('Resolving topic with a weird prefix -> moved', () {
          checkEditState(MessageEditState.moved,
            [{'prev_topic': 'old_topic', 'topic': '✔ ✔old_topic'}]);
      });

      // Similar reasoning as the previous test, including that this case had to
      // involve unusual input in an edit/move-topic UI.
      // Here the computation burden would have come from calling
      // [TopicName.canonicalize].
      test('Topic was resolved but with changed case -> moved', () {
        checkEditState(MessageEditState.moved,
          [{'prev_topic': 'old ToPiC', 'topic': '✔ OLD tOpIc'}]);
      });
    });
  });
}
