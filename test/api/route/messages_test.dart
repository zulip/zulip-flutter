import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/narrow.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/narrow.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';
import 'route_checks.dart';

void main() {
  group('sendMessage', () {
    const streamId = 123;
    const content = 'hello';
    const topic = 'world';
    const userIds = [23, 34];

    Future<void> checkSendMessage(
      FakeApiConnection connection, {
      required MessageDestination destination,
      required String content,
      required Map<String, String> expectedBodyFields,
    }) async {
      connection.prepare(json: SendMessageResult(id: 42).toJson());
      final result = await sendMessage(connection,
        destination: destination, content: content);
      check(result).id.equals(42);
      check(connection.lastRequest).isNotNull().isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages')
        ..bodyFields.deepEquals(expectedBodyFields);
    }

    test('to stream', () {
      return FakeApiConnection.with_((connection) async {
        await checkSendMessage(connection,
          destination: StreamDestination(streamId, topic), content: content,
          expectedBodyFields: {
            'type': 'stream',
            'to': streamId.toString(),
            'topic': topic,
            'content': content,
          });
      });
    });

    test('to DM conversation', () {
      return FakeApiConnection.with_((connection) async {
        await checkSendMessage(connection,
          destination: DmDestination(userIds: userIds), content: content,
          expectedBodyFields: {
            'type': 'private',
            'to': jsonEncode(userIds),
            'content': content,
          });
      });
    });
  });
}
