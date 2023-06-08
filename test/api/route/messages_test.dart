import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/narrow.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/narrow.dart';

import '../../example_data.dart' as eg;
import '../../stdlib_checks.dart';
import '../fake_api.dart';
import 'route_checks.dart';

void main() {
  group('getMessage', () {
    Future<GetMessageResult> checkGetMessage(
      FakeApiConnection connection, {
      required int messageId,
      bool? applyMarkdown,
      required Map<String, String> expected,
    }) async {
      final result = await getMessage(connection,
        messageId: messageId,
        applyMarkdown: applyMarkdown,
      );
      check(connection.lastRequest).isNotNull().isA<http.Request>()
        ..method.equals('GET')
        ..url.path.equals('/api/v1/messages/$messageId')
        ..url.queryParameters.deepEquals(expected);
      return result;
    }

    final fakeResult = GetMessageResult(message: eg.streamMessage());

    test('applyMarkdown true', () {
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: fakeResult.toJson());
        await checkGetMessage(connection,
          messageId: 1,
          applyMarkdown: true,
          expected: {'apply_markdown': 'true'});
      });
    });

    test('applyMarkdown false', () {
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: fakeResult.toJson());
        await checkGetMessage(connection,
          messageId: 1,
          applyMarkdown: false,
          expected: {'apply_markdown': 'false'});
      });
    });

    test('Throws assertion error when FL <120', () {
      return FakeApiConnection.with_(zulipFeatureLevel: 119, (connection) async {
        connection.prepare(json: fakeResult.toJson());
        check(() => getMessage(connection,
          messageId: 1,
        )).throws<AssertionError>();
      });
    });
  });

  group('getMessages', () {
    Future<GetMessagesResult> checkGetMessages(
      FakeApiConnection connection, {
      required ApiNarrow narrow,
      required Anchor anchor,
      bool? includeAnchor,
      required int numBefore,
      required int numAfter,
      bool? clientGravatar,
      bool? applyMarkdown,
      required Map<String, String> expected,
    }) async {
      final result = await getMessages(connection,
        narrow: narrow, anchor: anchor, includeAnchor: includeAnchor,
        numBefore: numBefore, numAfter: numAfter,
        clientGravatar: clientGravatar, applyMarkdown: applyMarkdown,
      );
      check(connection.lastRequest).isNotNull().isA<http.Request>()
        ..method.equals('GET')
        ..url.path.equals('/api/v1/messages')
        ..url.queryParameters.deepEquals(expected);
      return result;
    }

    final fakeResult = GetMessagesResult(
      anchor: 12345, foundNewest: false, foundOldest: false, foundAnchor: false,
      historyLimited: false, messages: []);

    test('smoke', () {
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: fakeResult.toJson());
        await checkGetMessages(connection,
          narrow: const AllMessagesNarrow().apiEncode(),
          anchor: AnchorCode.newest, numBefore: 10, numAfter: 20,
          expected: {
            'narrow': jsonEncode([]),
            'anchor': 'newest',
            'num_before': '10',
            'num_after': '20',
          });
      });
    });

    test('narrow', () {
      return FakeApiConnection.with_((connection) async {
        Future<void> checkNarrow(ApiNarrow narrow, String expected) async {
          connection.prepare(json: fakeResult.toJson());
          await checkGetMessages(connection,
            narrow: narrow,
            anchor: AnchorCode.newest, numBefore: 10, numAfter: 20,
            expected: {
              'narrow': expected,
              'anchor': 'newest',
              'num_before': '10',
              'num_after': '20',
            });
        }

        await checkNarrow(const AllMessagesNarrow().apiEncode(), jsonEncode([]));
        await checkNarrow(const StreamNarrow(12).apiEncode(), jsonEncode([
          {'operator': 'stream', 'operand': 12},
        ]));
        await checkNarrow(const TopicNarrow(12, 'stuff').apiEncode(), jsonEncode([
          {'operator': 'stream', 'operand': 12},
          {'operator': 'topic', 'operand': 'stuff'},
        ]));

        await checkNarrow([ApiNarrowDm([123, 234])], jsonEncode([
          {'operator': 'dm', 'operand': [123, 234]},
        ]));
        connection.zulipFeatureLevel = 176;
        await checkNarrow([ApiNarrowDm([123, 234])], jsonEncode([
          {'operator': 'pm-with', 'operand': [123, 234]},
        ]));
        connection.zulipFeatureLevel = eg.futureZulipFeatureLevel;
      });
    });

    test('anchor', () {
      return FakeApiConnection.with_((connection) async {
        Future<void> checkAnchor(Anchor anchor, String expected) async {
          connection.prepare(json: fakeResult.toJson());
          await checkGetMessages(connection,
            narrow: const AllMessagesNarrow().apiEncode(),
            anchor: anchor, numBefore: 10, numAfter: 20,
            expected: {
              'narrow': jsonEncode([]),
              'anchor': expected,
              'num_before': '10',
              'num_after': '20',
            });
        }

        await checkAnchor(AnchorCode.newest,      'newest');
        await checkAnchor(AnchorCode.oldest,      'oldest');
        await checkAnchor(AnchorCode.firstUnread, 'first_unread');
        await checkAnchor(const NumericAnchor(1), '1');
        await checkAnchor(const NumericAnchor(999999999), '999999999');
        await checkAnchor(const NumericAnchor(10000000000000000), '10000000000000000');
      });
    });
  });

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
            'type': 'direct',
            'to': jsonEncode(userIds),
            'content': content,
          });
      });
    });

    test('to DM conversation, with legacy type "private"', () {
      return FakeApiConnection.with_(zulipFeatureLevel: 173, (connection) async {
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
