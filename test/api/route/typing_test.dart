import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/api/route/typing.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';

void main() {
  const streamId = 123;
  const topic = 'topic';
  const userIds = [101, 102, 103];

  Future<void> checkSetTypingStatus(FakeApiConnection connection,
    TypingOp op, {
    required MessageDestination destination,
    required Map<String, String> expectedBodyFields,
  }) async {
    connection.prepare(json: {});
    await setTypingStatus(connection, op: op, destination: destination);
    check(connection.lastRequest).isA<http.Request>()
      ..method.equals('POST')
      ..url.path.equals('/api/v1/typing')
      ..bodyFields.deepEquals(expectedBodyFields);
  }

  Future<void> checkSetTypingStatusForTopic(TypingOp op, String expectedOp) {
    return FakeApiConnection.with_((connection) {
      return checkSetTypingStatus(connection, op,
        destination: const StreamDestination(streamId, TopicName(topic)),
        expectedBodyFields: {
          'op': expectedOp,
          'type': 'channel',
          'stream_id': streamId.toString(),
          'topic': topic,
        });
    });
  }

  test('send typing status start for topic', () {
    return checkSetTypingStatusForTopic(TypingOp.start, 'start');
  });

  test('send typing status stop for topic', () {
    return checkSetTypingStatusForTopic(TypingOp.stop, 'stop');
  });

  test('send typing status start for dm', () {
    return FakeApiConnection.with_((connection) {
      return checkSetTypingStatus(connection, TypingOp.start,
        destination: const DmDestination(userIds: userIds),
        expectedBodyFields: {
          'op': 'start',
          'type': 'direct',
          'to': jsonEncode(userIds),
        });
    });
  });

  test('legacy: use "stream" instead of "channel"', () {
    return FakeApiConnection.with_(zulipFeatureLevel: 247, (connection) {
      return checkSetTypingStatus(connection, TypingOp.start,
        destination: const StreamDestination(streamId, TopicName(topic)),
        expectedBodyFields: {
          'op': 'start',
          'type': 'stream',
          'stream_id': streamId.toString(),
          'topic': topic,
        });
    });
  });

  test('legacy: use to=[streamId] instead of stream_id=streamId', () {
    return FakeApiConnection.with_(zulipFeatureLevel: 214, (connection) {
      return checkSetTypingStatus(connection, TypingOp.start,
        destination: const StreamDestination(streamId, TopicName(topic)),
        expectedBodyFields: {
          'op': 'start',
          'type': 'stream',
          'to': jsonEncode([streamId]),
          'topic': topic,
        });
    });
  });

  test('legacy: use "private" instead of "direct"', () {
    return FakeApiConnection.with_(zulipFeatureLevel: 173, (connection) {
      return checkSetTypingStatus(connection, TypingOp.start,
        destination: const DmDestination(userIds: userIds),
        expectedBodyFields: {
          'op': 'start',
          'type': 'private',
          'to': jsonEncode(userIds),
        });
    });
  });
}
