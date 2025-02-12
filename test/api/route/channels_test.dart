import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';

void main() {
  test('smoke updateUserTopic', () {
    return FakeApiConnection.with_((connection) async {
      connection.prepare(json: {});
      await updateUserTopic(connection,
        streamId: 1, topic: const TopicName('topic'),
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
        streamId: 1, topic: const TopicName('topic'),
        visibilityPolicy: UserTopicVisibilityPolicy.unknown),
      ).throws<AssertionError>();
    });
  });

  test('updateUserTopicCompat when FL >= 170', () {
    return FakeApiConnection.with_((connection) async {
      connection.prepare(json: {});
      await updateUserTopicCompat(connection,
        streamId: 1, topic: const TopicName('topic'),
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

  group('legacy: use muteTopic when FL < 170', () {
    test('updateUserTopic throws AssertionError when FL < 170', () {
      return FakeApiConnection.with_(zulipFeatureLevel: 169, (connection) async {
        check(() => updateUserTopic(connection,
          streamId: 1, topic: const TopicName('topic'),
          visibilityPolicy: UserTopicVisibilityPolicy.muted),
        ).throws<AssertionError>();
      });
    });

    test('updateUserTopicCompat throws UnsupportedError on unsupported policy', () {
      return FakeApiConnection.with_(zulipFeatureLevel: 169, (connection) async {
        check(() => updateUserTopicCompat(connection,
          streamId: 1, topic: const TopicName('topic'),
          visibilityPolicy: UserTopicVisibilityPolicy.followed),
        ).throws<UnsupportedError>();
      });
    });

    test('policy: none -> op: remove', () {
      return FakeApiConnection.with_(zulipFeatureLevel: 169, (connection) async {
        connection.prepare(json: {});
        await updateUserTopicCompat(connection,
          streamId: 1, topic: const TopicName('topic'),
          visibilityPolicy: UserTopicVisibilityPolicy.none);
        check(connection.takeRequests()).single.isA<http.Request>()
          ..method.equals('PATCH')
          ..url.path.equals('/api/v1/users/me/subscriptions/muted_topics')
          ..bodyFields.deepEquals({
            'stream_id': '1',
            'topic': 'topic',
            'op': 'remove',
          });
      });
    });

    test('policy: muted -> op: add', () {
      return FakeApiConnection.with_(zulipFeatureLevel: 169, (connection) async {
        connection.prepare(json: {});
        await updateUserTopicCompat(connection,
          streamId: 1, topic: const TopicName('topic'),
          visibilityPolicy: UserTopicVisibilityPolicy.muted);
        check(connection.takeRequests()).single.isA<http.Request>()
          ..method.equals('PATCH')
          ..url.path.equals('/api/v1/users/me/subscriptions/muted_topics')
          ..bodyFields.deepEquals({
            'stream_id': '1',
            'topic': 'topic',
            'op': 'add',
          });
      });
    });
  });
}
