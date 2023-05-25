import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/route/messages.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';
import 'route_checks.dart';

void main() {
  test('sendMessage to stream', () {
    return FakeApiConnection.with_((connection) async {
      const streamId = 123;
      const topic = 'world';
      const content = 'hello';
      connection.prepare(json: SendMessageResult(id: 42).toJson());
      final result = await sendMessage(connection,
        destination: StreamDestination(streamId, topic), content: content);
      check(result).id.equals(42);
      check(connection.lastRequest).isNotNull().isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages')
        ..bodyFields.deepEquals({
          'type': 'stream',
          'to': streamId.toString(),
          'topic': topic,
          'content': content,
        });
    });
  });

  test('sendMessage to PM conversation', () {
    return FakeApiConnection.with_((connection) async {
      const userIds = [23, 34];
      const content = 'hi there';
      connection.prepare(json: SendMessageResult(id: 42).toJson());
      final result = await sendMessage(connection,
        destination: PmDestination(userIds: userIds), content: content);
      check(result).id.equals(42);
      check(connection.lastRequest).isNotNull().isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages')
        ..bodyFields.deepEquals({
          'type': 'private',
          'to': jsonEncode(userIds),
          'content': content,
        });
    });
  });
}
