import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/api/model/model.dart';
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
      required bool allowEmptyTopicName,
      required Map<String, String> expected,
    }) async {
      final result = await getMessage(connection,
        messageId: messageId,
        applyMarkdown: applyMarkdown,
        allowEmptyTopicName: allowEmptyTopicName,
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
          allowEmptyTopicName: true,
          expected: {
            'apply_markdown': 'true',
            'allow_empty_topic_name': 'true',
          });
      });
    });

    test('applyMarkdown false', () {
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: fakeResult.toJson());
        await checkGetMessage(connection,
          messageId: 1,
          applyMarkdown: false,
          allowEmptyTopicName: true,
          expected: {
            'apply_markdown': 'false',
            'allow_empty_topic_name': 'true',
          });
      });
    });

    test('allow empty topic name', () {
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: fakeResult.toJson());
        await checkGetMessage(connection,
          messageId: 1,
          allowEmptyTopicName: true,
          expected: {'allow_empty_topic_name': 'true'});
      });
    });
  });

  test('ApiNarrow.toJson', () {
    return FakeApiConnection.with_((connection) async {
      void checkNarrow(ApiNarrow narrow, String expected) {
        narrow = resolveApiNarrowForServer(narrow, connection.zulipFeatureLevel!);
        check(jsonEncode(narrow)).equals(expected);
      }

      checkNarrow(const MentionsNarrow().apiEncode(), jsonEncode([
        {'operator': 'is', 'operand': 'mentioned'},
      ]));
      checkNarrow(const StarredMessagesNarrow().apiEncode(), jsonEncode([
        {'operator': 'is', 'operand': 'starred'},
      ]));

      checkNarrow(const CombinedFeedNarrow().apiEncode(), jsonEncode([]));
      checkNarrow(const ChannelNarrow(12).apiEncode(), jsonEncode([
        {'operator': 'stream', 'operand': 12},
      ]));
      checkNarrow(eg.topicNarrow(12, 'stuff').apiEncode(), jsonEncode([
        {'operator': 'stream', 'operand': 12},
        {'operator': 'topic', 'operand': 'stuff'},
      ]));
      checkNarrow(eg.topicNarrow(12, 'stuff', with_: 1).apiEncode(), jsonEncode([
        {'operator': 'stream', 'operand': 12},
        {'operator': 'topic', 'operand': 'stuff'},
        {'operator': 'with', 'operand': 1},
      ]));
      checkNarrow([ApiNarrowDm([123, 234])], jsonEncode([
        {'operator': 'dm', 'operand': [123, 234]},
      ]));
      checkNarrow([ApiNarrowDm([123, 234]), ApiNarrowWith(1)], jsonEncode([
        {'operator': 'dm', 'operand': [123, 234]},
        {'operator': 'with', 'operand': 1},
      ]));

      connection.zulipFeatureLevel = 270;
      checkNarrow(eg.topicNarrow(12, 'stuff', with_: 1).apiEncode(), jsonEncode([
        {'operator': 'stream', 'operand': 12},
        {'operator': 'topic', 'operand': 'stuff'},
      ]));
      checkNarrow([ApiNarrowDm([123, 234])], jsonEncode([
        {'operator': 'dm', 'operand': [123, 234]},
      ]));
      checkNarrow([ApiNarrowDm([123, 234]), ApiNarrowWith(1)], jsonEncode([
        {'operator': 'dm', 'operand': [123, 234]},
      ]));

      connection.zulipFeatureLevel = 176;
      checkNarrow(eg.topicNarrow(12, 'stuff', with_: 1).apiEncode(), jsonEncode([
        {'operator': 'stream', 'operand': 12},
        {'operator': 'topic', 'operand': 'stuff'},
      ]));
      checkNarrow([ApiNarrowDm([123, 234])], jsonEncode([
        {'operator': 'pm-with', 'operand': [123, 234]},
      ]));
      checkNarrow([ApiNarrowDm([123, 234]), ApiNarrowWith(1)], jsonEncode([
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
      required bool allowEmptyTopicName,
      required Map<String, String> expected,
    }) async {
      final result = await getMessages(connection,
        narrow: narrow, anchor: anchor, includeAnchor: includeAnchor,
        numBefore: numBefore, numAfter: numAfter,
        clientGravatar: clientGravatar, applyMarkdown: applyMarkdown,
        allowEmptyTopicName: allowEmptyTopicName,
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
          narrow: const CombinedFeedNarrow().apiEncode(),
          anchor: AnchorCode.newest, numBefore: 10, numAfter: 20,
          allowEmptyTopicName: true,
          expected: {
            'narrow': jsonEncode([]),
            'anchor': 'newest',
            'num_before': '10',
            'num_after': '20',
            'allow_empty_topic_name': 'true',
          });
      });
    });

    test('narrow uses resolveApiNarrowForServer to encode', () {
      return FakeApiConnection.with_(zulipFeatureLevel: 176, (connection) async {
        connection.prepare(json: fakeResult.toJson());
        await checkGetMessages(connection,
          narrow: [ApiNarrowDm([123, 234])],
          anchor: AnchorCode.newest, numBefore: 10, numAfter: 20,
          allowEmptyTopicName: true,
          expected: {
            'narrow': jsonEncode([
              {'operator': 'pm-with', 'operand': [123, 234]},
            ]),
            'anchor': 'newest',
            'num_before': '10',
            'num_after': '20',
            'allow_empty_topic_name': 'true',
          });
      });
    });

    test('numeric anchor', () {
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: fakeResult.toJson());
        await checkGetMessages(connection,
          narrow: const CombinedFeedNarrow().apiEncode(),
          anchor: const NumericAnchor(42),
          numBefore: 10, numAfter: 20,
          allowEmptyTopicName: true,
          expected: {
            'narrow': jsonEncode([]),
            'anchor': '42',
            'num_before': '10',
            'num_after': '20',
            'allow_empty_topic_name': 'true',
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
      String? queueId,
      String? localId,
      bool? readBySender,
      required Map<String, String> expectedBodyFields,
      String? expectedUserAgent,
    }) async {
      connection.prepare(json: SendMessageResult(id: 42).toJson());
      final result = await sendMessage(connection,
        destination: destination, content: content,
        queueId: queueId, localId: localId, readBySender: readBySender);
      check(result).id.equals(42);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages')
        ..bodyFields.deepEquals(expectedBodyFields)
        ..headers['User-Agent'].equals(expectedUserAgent ?? kFallbackUserAgentHeader['User-Agent']!);
    }

    test('smoke', () {
      return FakeApiConnection.with_((connection) async {
        await checkSendMessage(connection,
          destination: StreamDestination(streamId, eg.t(topic)), content: content,
          queueId: 'abc:123',
          localId: '456',
          readBySender: true,
          expectedBodyFields: {
            'type': 'stream',
            'to': streamId.toString(),
            'topic': topic,
            'content': content,
            'queue_id': 'abc:123',
            'local_id': '456',
            'read_by_sender': 'true',
          });
      });
    });

    test('to stream', () {
      return FakeApiConnection.with_((connection) async {
        await checkSendMessage(connection,
          destination: StreamDestination(streamId, eg.t(topic)), content: content,
          readBySender: true,
          expectedBodyFields: {
            'type': 'stream',
            'to': streamId.toString(),
            'topic': topic,
            'content': content,
            'read_by_sender': 'true',
          });
      });
    });

    test('to DM conversation', () {
      return FakeApiConnection.with_((connection) async {
        await checkSendMessage(connection,
          destination: const DmDestination(userIds: userIds), content: content,
          readBySender: true,
          expectedBodyFields: {
            'type': 'direct',
            'to': jsonEncode(userIds),
            'content': content,
            'read_by_sender': 'true',
          });
      });
    });

    test('to DM conversation, with legacy type "private"', () {
      return FakeApiConnection.with_(zulipFeatureLevel: 173, (connection) async {
        await checkSendMessage(connection,
          destination: const DmDestination(userIds: userIds), content: content,
          readBySender: true,
          expectedBodyFields: {
            'type': 'private',
            'to': jsonEncode(userIds),
            'content': content,
            'read_by_sender': 'true',
          },
          expectedUserAgent: 'ZulipMobile/flutter');
      });
    });

    test('when readBySender is null, sends a User-Agent we know the server will recognize', () {
      return FakeApiConnection.with_((connection) async {
        await checkSendMessage(connection,
          destination: StreamDestination(streamId, eg.t(topic)), content: content,
          readBySender: null,
          expectedBodyFields: {
            'type': 'stream',
            'to': streamId.toString(),
            'topic': topic,
            'content': content,
          },
          expectedUserAgent: 'ZulipMobile/flutter');
      });
    });

    test('legacy: when server does not support readBySender, sends a User-Agent the server will recognize', () {
      return FakeApiConnection.with_(zulipFeatureLevel: 235, (connection) async {
        await checkSendMessage(connection,
          destination: StreamDestination(streamId, eg.t(topic)), content: content,
          readBySender: true,
          expectedBodyFields: {
            'type': 'stream',
            'to': streamId.toString(),
            'topic': topic,
            'content': content,
            'read_by_sender': 'true',
          },
          expectedUserAgent: 'ZulipMobile/flutter');
      });
    });
  });

  group('updateMessage', () {
    Future<UpdateMessageResult> checkUpdateMessage(
      FakeApiConnection connection, {
      required int messageId,
      TopicName? topic,
      PropagateMode? propagateMode,
      bool? sendNotificationToOldThread,
      bool? sendNotificationToNewThread,
      String? content,
      String? prevContentSha256,
      int? streamId,
      required Map<String, String> expected,
    }) async {
      final result = await updateMessage(connection,
        messageId: messageId,
        topic: topic,
        propagateMode: propagateMode,
        sendNotificationToOldThread: sendNotificationToOldThread,
        sendNotificationToNewThread: sendNotificationToNewThread,
        content: content,
        prevContentSha256: prevContentSha256,
        streamId: streamId,
      );
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('PATCH')
        ..url.path.equals('/api/v1/messages/$messageId')
        ..bodyFields.deepEquals(expected);
      return result;
    }

    test('pure content change', () {
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: UpdateMessageResult().toJson());
        await checkUpdateMessage(connection,
          messageId: eg.streamMessage().id,
          content: 'asdf',
          prevContentSha256: '34a780ad578b997db55b260beb60b501f3e04d30ba1a51fcf43cd8dd1241780d',
          expected: {
            'content': 'asdf',
            'prev_content_sha256': '34a780ad578b997db55b260beb60b501f3e04d30ba1a51fcf43cd8dd1241780d',
          });
      });
    });

    test('topic/content change', () {
      // A separate test exercises `streamId`;
      // the API doesn't allow changing channel and content at the same time.
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: UpdateMessageResult().toJson());
        await checkUpdateMessage(connection,
          messageId: eg.streamMessage().id,
          topic: eg.t('new topic'),
          propagateMode: PropagateMode.changeAll,
          sendNotificationToOldThread: true,
          sendNotificationToNewThread: true,
          content: 'asdf',
          expected: {
            'topic': 'new topic',
            'propagate_mode': 'change_all',
            'send_notification_to_old_thread': 'true',
            'send_notification_to_new_thread': 'true',
            'content': 'asdf',
          });
      });
    });

    test('channel change', () {
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: UpdateMessageResult().toJson());
        await checkUpdateMessage(connection,
          messageId: eg.streamMessage().id,
          streamId: 1,
          expected: {'stream_id': '1'});
      });
    });
  });

  group('uploadFile', () {
    Future<void> checkUploadFile(FakeApiConnection connection, {
      required List<List<int>> content,
      required int length,
      required String filename,
      required String? contentType,
    }) async {
      connection.prepare(json:
        UploadFileResult(url: '/user_uploads/1/4e/m2A3MSqFnWRLUf9SaPzQ0Up_/$filename').toJson());
      await uploadFile(connection,
        content: Stream.fromIterable(content),
        length: length,
        filename: filename,
        contentType: contentType);
      check(connection.lastRequest).isA<http.MultipartRequest>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/user_uploads')
        ..files.single.which((it) => it
          ..field.equals('file')
          ..length.equals(length)
          ..filename.equals(filename)
          ..contentType.asString.equals(contentType ?? 'application/octet-stream')
          ..has<Future<List<int>>>((f) => f.finalize().toBytes(), 'contents')
            .completes((it) => it.deepEquals(content.expand((l) => l))));
    }

    test('with mime type', () {
      return FakeApiConnection.with_((connection) async {
        await checkUploadFile(connection,
          content: ['asdf'.codeUnits],
          length: 4,
          filename: 'image.jpg',
          contentType: 'image/jpeg',
        );
      });
    });

    test('without mime type', () {
      return FakeApiConnection.with_((connection) async {
        await checkUploadFile(connection,
          content: ['asdf'.codeUnits],
          length: 4,
          filename: 'some_file',
          contentType: null,
        );
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
          narrow: const CombinedFeedNarrow().apiEncode(),
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

    test('narrow uses resolveApiNarrowForServer to encode', () {
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
          narrow: const CombinedFeedNarrow().apiEncode(),
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

  test('smoke getReadReceipts', () {
    return FakeApiConnection.with_((connection) async {
      final response = GetReadReceiptsResult(userIds: [7, 6543, 210]);
      connection.prepare(json: response.toJson());
      await getReadReceipts(connection, messageId: 123321);
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('GET')
        ..url.path.equals('/api/v1/messages/123321/read_receipts');
    });
  });
}
