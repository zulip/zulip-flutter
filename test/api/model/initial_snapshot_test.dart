import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';

import '../../stdlib_checks.dart';

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
}
