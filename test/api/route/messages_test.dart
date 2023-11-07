import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/narrow.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/narrow.dart';

import '../../example_data.dart' as eg;
import '../../stdlib_checks.dart';
import '../fake_api.dart';
import 'route_checks.dart';

void main() {
  group('getMessageCompat', () {
    Future<Message?> checkGetMessageCompat(FakeApiConnection connection, {
      required bool expectLegacy,
      required int messageId,
      bool? applyMarkdown,
    }) async {
      final result = await getMessageCompat(connection,
        messageId: messageId,
        applyMarkdown: applyMarkdown,
      );
      if (expectLegacy) {
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('GET')
          ..url.path.equals('/api/v1/messages')
          ..url.queryParameters.deepEquals({
            'narrow': jsonEncode([ApiNarrowMessageId(messageId)]),
            'anchor': messageId.toString(),
            'num_before': '0',
            'num_after': '0',
            if (applyMarkdown != null) 'apply_markdown': applyMarkdown.toString(),
            'client_gravatar': 'true',
          });
      } else {
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('GET')
          ..url.path.equals('/api/v1/messages/$messageId')
          ..url.queryParameters.deepEquals({
            if (applyMarkdown != null) 'apply_markdown': applyMarkdown.toString(),
          });
      }
      return result;
    }

    test('modern; message found', () {
      return FakeApiConnection.with_((connection) async {
        final message = eg.streamMessage();
        final fakeResult = GetMessageResult(message: message);
        connection.prepare(json: fakeResult.toJson());
        final result = await checkGetMessageCompat(connection,
          expectLegacy: false,
          messageId: message.id,
          applyMarkdown: true,
        );
        check(result).isNotNull().jsonEquals(message);
      });
    });

    test('modern; message not found', () {
      return FakeApiConnection.with_((connection) async {
        final message = eg.streamMessage();
        final fakeResponseJson = {
          'code': 'BAD_REQUEST',
          'msg': 'Invalid message(s)',
          'result': 'error',
        };
        connection.prepare(httpStatus: 400, json: fakeResponseJson);
        final result = await checkGetMessageCompat(connection,
          expectLegacy: false,
          messageId: message.id,
          applyMarkdown: true,
        );
        check(result).isNull();
      });
    });

    test('legacy; message found', () {
      return FakeApiConnection.with_(zulipFeatureLevel: 119, (connection) async {
        final message = eg.streamMessage();
        final fakeResult = GetMessagesResult(
          anchor: message.id,
          foundNewest: false,
          foundOldest: false,
          foundAnchor: true,
          historyLimited: false,
          messages: [message],
        );
        connection.prepare(json: fakeResult.toJson());
        final result = await checkGetMessageCompat(connection,
          expectLegacy: true,
          messageId: message.id,
          applyMarkdown: true,
        );
        check(result).isNotNull().jsonEquals(message);
      });
    });

    test('legacy; message not found', () {
      return FakeApiConnection.with_(zulipFeatureLevel: 119, (connection) async {
        final message = eg.streamMessage();
        final fakeResult = GetMessagesResult(
          anchor: message.id,
          foundNewest: false,
          foundOldest: false,
          foundAnchor: false,
          historyLimited: false,
          messages: [],
        );
        connection.prepare(json: fakeResult.toJson());
        final result = await checkGetMessageCompat(connection,
          expectLegacy: true,
          messageId: message.id,
          applyMarkdown: true,
        );
        check(result).isNull();
      });
    });
  });

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
      check(connection.lastRequest).isA<http.Request>()
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

  test('Narrow.toJson', () {
    return FakeApiConnection.with_((connection) async {
      void checkNarrow(ApiNarrow narrow, String expected) {
        narrow = resolveDmElements(narrow, connection.zulipFeatureLevel!);
        check(jsonEncode(narrow)).equals(expected);
      }

      checkNarrow(const AllMessagesNarrow().apiEncode(), jsonEncode([]));
      checkNarrow(const StreamNarrow(12).apiEncode(), jsonEncode([
        {'operator': 'stream', 'operand': 12},
      ]));
      checkNarrow(const TopicNarrow(12, 'stuff').apiEncode(), jsonEncode([
        {'operator': 'stream', 'operand': 12},
        {'operator': 'topic', 'operand': 'stuff'},
      ]));

      checkNarrow([ApiNarrowDm([123, 234])], jsonEncode([
        {'operator': 'dm', 'operand': [123, 234]},
      ]));

      connection.zulipFeatureLevel = 176;
      checkNarrow([ApiNarrowDm([123, 234])], jsonEncode([
        {'operator': 'pm-with', 'operand': [123, 234]},
      ]));
      connection.zulipFeatureLevel = eg.futureZulipFeatureLevel;
    });
  });

  test('Anchor.toJson', () {
    void checkAnchor(Anchor anchor, String expected) {
      check(anchor.toJson()).equals(expected);
    }

    checkAnchor(AnchorCode.newest,      'newest');
    checkAnchor(AnchorCode.oldest,      'oldest');
    checkAnchor(AnchorCode.firstUnread, 'first_unread');
    checkAnchor(const NumericAnchor(1), '1');
    checkAnchor(const NumericAnchor(999999999), '999999999');
    checkAnchor(const NumericAnchor(10000000000000000), '10000000000000000');
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
      check(connection.lastRequest).isA<http.Request>()
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

    test('narrow uses resolveDmElements to encode', () {
      return FakeApiConnection.with_(zulipFeatureLevel: 176, (connection) async {
        connection.prepare(json: fakeResult.toJson());
        await checkGetMessages(connection,
          narrow: [ApiNarrowDm([123, 234])],
          anchor: AnchorCode.newest, numBefore: 10, numAfter: 20,
          expected: {
            'narrow': jsonEncode([
              {'operator': 'pm-with', 'operand': [123, 234]},
            ]),
            'anchor': 'newest',
            'num_before': '10',
            'num_after': '20',
          });
      });
    });

    test('numeric anchor', () {
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: fakeResult.toJson());
        await checkGetMessages(connection,
          narrow: const AllMessagesNarrow().apiEncode(),
          anchor: const NumericAnchor(42),
          numBefore: 10, numAfter: 20,
          expected: {
            'narrow': jsonEncode([]),
            'anchor': '42',
            'num_before': '10',
            'num_after': '20',
          });
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
      check(connection.lastRequest).isA<http.Request>()
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

  group('addReaction', () {
    Future<void> checkAddReaction(FakeApiConnection connection, {
      required int messageId,
      required Reaction reaction,
      required String expectedReactionType,
    }) async {
      connection.prepare(json: {});
      await addReaction(connection,
        messageId: messageId,
        reactionType: reaction.reactionType,
        emojiCode: reaction.emojiCode,
        emojiName: reaction.emojiName,
      );
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/$messageId/reactions')
        ..bodyFields.deepEquals({
            'reaction_type': expectedReactionType,
            'emoji_code': reaction.emojiCode,
            'emoji_name': reaction.emojiName,
          });
    }

    test('unicode emoji', () {
      return FakeApiConnection.with_((connection) async {
        await checkAddReaction(connection,
          messageId: eg.streamMessage().id,
          reaction: eg.unicodeEmojiReaction,
          expectedReactionType: 'unicode_emoji');
      });
    });

    test('realm emoji', () {
      return FakeApiConnection.with_((connection) async {
        await checkAddReaction(connection,
          messageId: eg.streamMessage().id,
          reaction: eg.realmEmojiReaction,
          expectedReactionType: 'realm_emoji');
      });
    });

    test('Zulip extra emoji', () {
      return FakeApiConnection.with_((connection) async {
        await checkAddReaction(connection,
          messageId: eg.streamMessage().id,
          reaction: eg.zulipExtraEmojiReaction,
          expectedReactionType: 'zulip_extra_emoji');
      });
    });
  });

  group('removeReaction', () {
    Future<void> checkRemoveReaction(FakeApiConnection connection, {
      required int messageId,
      required Reaction reaction,
      required String expectedReactionType,
    }) async {
      connection.prepare(json: {});
      await removeReaction(connection,
        messageId: messageId,
        reactionType: reaction.reactionType,
        emojiCode: reaction.emojiCode,
        emojiName: reaction.emojiName,
      );
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('DELETE')
        ..url.path.equals('/api/v1/messages/$messageId/reactions')
        ..bodyFields.deepEquals({
            'reaction_type': expectedReactionType,
            'emoji_code': reaction.emojiCode,
            'emoji_name': reaction.emojiName,
          });
    }

    test('unicode emoji', () {
      return FakeApiConnection.with_((connection) async {
        await checkRemoveReaction(connection,
          messageId: eg.streamMessage().id,
          reaction: eg.unicodeEmojiReaction,
          expectedReactionType: 'unicode_emoji');
      });
    });

    test('realm emoji', () {
      return FakeApiConnection.with_((connection) async {
        await checkRemoveReaction(connection,
          messageId: eg.streamMessage().id,
          reaction: eg.realmEmojiReaction,
          expectedReactionType: 'realm_emoji');
      });
    });

    test('Zulip extra emoji', () {
      return FakeApiConnection.with_((connection) async {
        await checkRemoveReaction(connection,
          messageId: eg.streamMessage().id,
          reaction: eg.zulipExtraEmojiReaction,
          expectedReactionType: 'zulip_extra_emoji');
      });
    });
  });

  group('updateMessageFlags', () {
    Future<UpdateMessageFlagsResult> checkUpdateMessageFlags(
      FakeApiConnection connection, {
      required List<int> messages,
      required UpdateMessageFlagsOp op,
      required MessageFlag flag,
      required Map<String, String> expected,
    }) async {
      final result = await updateMessageFlags(connection,
        messages: messages, op: op, flag: flag);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/flags')
        ..bodyFields.deepEquals(expected);
      return result;
    }

    test('smoke', () {
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json:
          UpdateMessageFlagsResult(messages: [1, 2]).toJson());
        await checkUpdateMessageFlags(connection,
          messages: [1, 2, 3],
          op: UpdateMessageFlagsOp.add, flag: MessageFlag.read,
          expected: {
            'messages': jsonEncode([1, 2, 3]),
            'op': 'add',
            'flag': 'read',
          });
      });
    });
  });

  group('updateMessageFlagsForNarrow', () {
    Future<UpdateMessageFlagsForNarrowResult> checkUpdateMessageFlagsForNarrow(
      FakeApiConnection connection, {
      required Anchor anchor,
      required int numBefore,
      required int numAfter,
      required ApiNarrow narrow,
      required UpdateMessageFlagsOp op,
      required MessageFlag flag,
      required Map<String, String> expected,
    }) async {
      final result = await updateMessageFlagsForNarrow(connection,
        anchor: anchor, numBefore: numBefore, numAfter: numAfter,
        narrow: narrow, op: op, flag: flag);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/flags/narrow')
        ..bodyFields.deepEquals(expected);
      return result;
    }

    UpdateMessageFlagsForNarrowResult mkResult({required bool foundOldest}) =>
      UpdateMessageFlagsForNarrowResult(
        processedCount: 11, updatedCount: 3,
        firstProcessedId: null, lastProcessedId: null,
        foundOldest: foundOldest, foundNewest: true);

    test('smoke', () {
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: mkResult(foundOldest: true).toJson());
        await checkUpdateMessageFlagsForNarrow(connection,
          anchor: AnchorCode.oldest,
          numBefore: 0, numAfter: 20,
          narrow: const AllMessagesNarrow().apiEncode(),
          op: UpdateMessageFlagsOp.add, flag: MessageFlag.read,
          expected: {
            'anchor': 'oldest',
            'num_before': '0',
            'num_after': '20',
            'narrow': jsonEncode([]),
            'op': 'add',
            'flag': 'read',
          });
      });
    });

    test('narrow uses resolveDmElements to encode', () {
      return FakeApiConnection.with_(zulipFeatureLevel: 176, (connection) async {
        connection.prepare(json: mkResult(foundOldest: true).toJson());
        await checkUpdateMessageFlagsForNarrow(connection,
          anchor: AnchorCode.oldest,
          numBefore: 0, numAfter: 20,
          narrow: [ApiNarrowDm([123, 234])],
          op: UpdateMessageFlagsOp.add, flag: MessageFlag.read,
          expected: {
            'anchor': 'oldest',
            'num_before': '0',
            'num_after': '20',
            'narrow': jsonEncode([
              {'operator': 'pm-with', 'operand': [123, 234]},
            ]),
            'op': 'add',
            'flag': 'read',
          });
      });
    });

    test('numeric anchor', () {
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: mkResult(foundOldest: false).toJson());
        await checkUpdateMessageFlagsForNarrow(connection,
          anchor: const NumericAnchor(42),
          numBefore: 0, numAfter: 20,
          narrow: const AllMessagesNarrow().apiEncode(),
          op: UpdateMessageFlagsOp.add, flag: MessageFlag.read,
          expected: {
            'anchor': '42',
            'num_before': '0',
            'num_after': '20',
            'narrow': jsonEncode([]),
            'op': 'add',
            'flag': 'read',
          });
      });
    });
  });

  group('markAllAsRead', () {
    Future<void> checkMarkAllAsRead(
      FakeApiConnection connection, {
      required Map<String, String> expected,
    }) async {
      connection.prepare(json: {});
      await markAllAsRead(connection);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/mark_all_as_read')
        ..bodyFields.deepEquals(expected);
    }

    test('smoke', () {
      return FakeApiConnection.with_((connection) async {
        await checkMarkAllAsRead(connection, expected: {});
      });
    });
  });

  group('markStreamAsRead', () {
    Future<void> checkMarkStreamAsRead(
      FakeApiConnection connection, {
      required int streamId,
      required Map<String, String> expected,
    }) async {
      connection.prepare(json: {});
      await markStreamAsRead(connection, streamId: streamId);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/mark_stream_as_read')
        ..bodyFields.deepEquals(expected);
    }

    test('smoke', () {
      return FakeApiConnection.with_((connection) async {
        await checkMarkStreamAsRead(connection,
          streamId: 10,
          expected: {'stream_id': '10'});
      });
    });
  });

  group('markTopicAsRead', () {
    Future<void> checkMarkTopicAsRead(
      FakeApiConnection connection, {
      required int streamId,
      required String topicName,
      required Map<String, String> expected,
    }) async {
      connection.prepare(json: {});
      await markTopicAsRead(connection,
        streamId: streamId, topicName: topicName);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/mark_topic_as_read')
        ..bodyFields.deepEquals(expected);
    }

    test('smoke', () {
      return FakeApiConnection.with_((connection) async {
        await checkMarkTopicAsRead(connection,
          streamId: 10,
          topicName: 'topic',
          expected: {
            'stream_id': '10',
            'topic_name': 'topic',
          });
      });
    });
  });
}
