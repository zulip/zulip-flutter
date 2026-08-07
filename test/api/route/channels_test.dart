import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';

void main() {
  test('smoke subscribeToChannel', () {
    return FakeApiConnection.with_((connection) async {
      connection.prepare(json: {});
      await subscribeToChannel(connection,
        subscriptions: ['foo'],
        principals: [1]);
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/users/me/subscriptions')
        ..bodyFields.deepEquals({
          'subscriptions': jsonEncode([{'name': 'foo'}]),
          'principals': jsonEncode([1]),
        });
    });
  });

  test('smoke unsubscribeFromChannel', () {
    return FakeApiConnection.with_((connection) async {
      connection.prepare(json: {});
      await unsubscribeFromChannel(connection,
        subscriptions: ['foo'],
        principals: [1]);
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('DELETE')
        ..url.path.equals('/api/v1/users/me/subscriptions')
        ..bodyFields.deepEquals({
          'subscriptions': jsonEncode(['foo']),
          'principals': jsonEncode([1]),
        });
    });
  });

  test('smoke updateUserTopic', () {
    return FakeApiConnection.with_((connection) async {
      connection.prepare(json: {});
      await updateUserTopic(connection,
        channelId: 1, topic: const TopicName('topic'),
        visibilityPolicy: UserTopicVisibilityPolicy.followed);
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/user_topics')
        ..bodyFields.deepEquals({
          'stream_id': '1',
          'topic': 'topic',
          'visibility_policy': '3',
        });
    });
  });

  test('updateUserTopic only accepts valid visibility policy', () {
    return FakeApiConnection.with_((connection) async {
      check(() => updateUserTopic(connection,
        channelId: 1, topic: const TopicName('topic'),
        visibilityPolicy: UserTopicVisibilityPolicy.unknown),
      ).throws<AssertionError>();
    });
  });
}
