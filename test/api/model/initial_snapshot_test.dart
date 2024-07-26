import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/initial_snapshot.dart';

void main() {
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
