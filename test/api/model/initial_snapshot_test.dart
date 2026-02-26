import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';

import '../../example_data.dart' as eg;
import '../../stdlib_checks.dart';
import 'model_checks.dart';

void main() {
  test('UnreadMessagesSnapshot from json recognizes channels as streams', () {
    final snapshot = UnreadMessagesSnapshot.fromJson({
      'count': 1,
      'pms': <dynamic>[],
      'huddles': <dynamic>[],
      'mentions': <dynamic>[],
      'old_unreads_missing': false,
      'streams': [{
        'stream_id': 1,
        'topic': 'topic name',
        'unread_message_ids': [1, 2]}]
    });

    check(snapshot.channels).single.jsonEquals(
      UnreadChannelSnapshot(
        topic: const TopicName('topic name'), streamId: 1,
        unreadMessageIds: [1, 2]));
  });

  test('UnreadDmSnapshot: require sorted unreadMessageIds', () {
    check(() => UnreadDmSnapshot.fromJson({
      'other_user_id': 1,
      'unread_message_ids': [1, 2, 3],
    })).returnsNormally();

    check(() => UnreadDmSnapshot.fromJson({
      'other_user_id': 1,
      'unread_message_ids': [11, 2, 3],
    })).throws<AssertionError>();
  });

  test('UnreadChannelSnapshot: require sorted unreadMessageIds', () {
    check(() => UnreadChannelSnapshot.fromJson({
      'topic': 'a',
      'stream_id': 1,
      'unread_message_ids': [1, 2, 3],
    })).returnsNormally();

    check(() => UnreadChannelSnapshot.fromJson({
      'topic': 'a',
      'stream_id': 1,
      'unread_message_ids': [11, 2, 3],
    })).throws<AssertionError>();
  });

  test('UnreadHuddleSnapshot: require sorted unreadMessageIds', () {
    check(() => UnreadHuddleSnapshot.fromJson({
      'user_ids_string': '1,2',
      'unread_message_ids': [1, 2, 3],
    })).returnsNormally();

    check(() => UnreadHuddleSnapshot.fromJson({
      'user_ids_string': '1,2',
      'unread_message_ids': [11, 2, 3],
    })).throws<AssertionError>();
  });

  test('UserSettings.emojiset handles various unknown values', () {
    final unknownValues = ['apple', ''];
    for (final unknownValue in unknownValues) {
      final json = eg.userSettings().toJson()..['emojiset'] = unknownValue;
      final settings = UserSettings.fromJson(json);
      check(settings.emojiset).equals(Emojiset.unknown);
    }
  });
  group('UserTopicItem: visibility_policy unknown to null conversion', () {
    final baseJson = {
      'stream_id': 123,
      'topic_name': 'test topic',
      'last_updated': 1234567890,
    };

    test('known visibility_policy values deserialize correctly', () {
      check(UserTopicItem.fromJson({...baseJson, 'visibility_policy': 0}))
        .visibilityPolicy.equals(UserTopicVisibilityPolicy.none);
      check(UserTopicItem.fromJson({...baseJson, 'visibility_policy': 1}))
        .visibilityPolicy.equals(UserTopicVisibilityPolicy.muted);
      check(UserTopicItem.fromJson({...baseJson, 'visibility_policy': 2}))
        .visibilityPolicy.equals(UserTopicVisibilityPolicy.unmuted);
      check(UserTopicItem.fromJson({...baseJson, 'visibility_policy': 3}))
        .visibilityPolicy.equals(UserTopicVisibilityPolicy.followed);
    });

    test('unknown visibility_policy value becomes null', () {
      check(UserTopicItem.fromJson({...baseJson, 'visibility_policy': 999}))
        .visibilityPolicy.isNull();
    });

    test('missing visibility_policy field becomes null', () {
      check(UserTopicItem.fromJson(baseJson))
        .visibilityPolicy.isNull();
    });

    test('explicit null visibility_policy remains null', () {
      check(UserTopicItem.fromJson({...baseJson, 'visibility_policy': null}))
        .visibilityPolicy.isNull();
    });
  });
}
