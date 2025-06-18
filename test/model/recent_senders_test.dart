import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/channel.dart';
import 'package:zulip/model/recent_senders.dart';
import '../example_data.dart' as eg;

/// [messages] should be sorted by [id] ascending.
void checkMatchesMessages(RecentSenders model, List<Message> messages) {
  final Map<int, Map<int, Set<int>>> messagesByUserInStream = {};
  final Map<int, TopicKeyedMap<Map<int, Set<int>>>> messagesByUserInTopic = {};
  for (final message in messages) {
    if (message is! StreamMessage) {
      throw UnsupportedError('Message of type ${message.runtimeType} is not expected.');
    }

    final StreamMessage(:streamId, :topic, :senderId, id: int messageId) = message;

    ((messagesByUserInStream[streamId] ??= {})
      [senderId] ??= {}).add(messageId);
    (((messagesByUserInTopic[streamId] ??= makeTopicKeyedMap())[topic] ??= {})
      [senderId] ??= {}).add(messageId);
  }

  final actualMessagesByUserInStream = model.streamSenders.map((streamId, sendersByStream) =>
    MapEntry(streamId, sendersByStream.map((senderId, tracker) =>
      MapEntry(senderId, Set<int>.from(tracker.ids)))));
  final actualMessagesByUserInTopic = model.topicSenders.map((streamId, topicsByStream) =>
    MapEntry(streamId, topicsByStream.map((topic, sendersByTopic) =>
      MapEntry(topic, sendersByTopic.map((senderId, tracker) =>
        MapEntry(senderId, Set<int>.from(tracker.ids)))))));

  check(actualMessagesByUserInStream).deepEquals(messagesByUserInStream);
  check(actualMessagesByUserInTopic).deepEquals(messagesByUserInTopic);
}

void main() {
  test('starts with empty stream and topic senders', () {
    final model = RecentSenders();
    checkMatchesMessages(model, []);
  });

  group('RecentSenders.handleMessage', () {
    test('stream message gets included', () {
      final model = RecentSenders();
      final streamMessage = eg.streamMessage();
      model.handleMessage(streamMessage);
      checkMatchesMessages(model, [streamMessage]);
    });

    test('DM message gets ignored', () {
      final model = RecentSenders();
      final dmMessage = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]);
      model.handleMessage(dmMessage);
      checkMatchesMessages(model, []);
    });
  });

  group('RecentSenders.handleMessages', () {
    late RecentSenders model;
    final streamA = eg.stream();
    final streamB = eg.stream();
    final userX = eg.user();
    final userY = eg.user();

    void setupModel(List<Message> messages) {
      model = RecentSenders();
      for (final message in messages) {
        model.handleMessage(message);
      }
    }

    void checkHandleMessages(List<Message> oldMessages, List<Message> newMessages) {
      setupModel(oldMessages);
      model.handleMessages(newMessages);
      final expectedMessages = [...oldMessages, ...newMessages]
        ..removeWhere((m) => m is! StreamMessage);
      checkMatchesMessages(model, expectedMessages);
    }

    group('single tracker', () {
      void checkHandleMessagesSingle(List<int> oldIds, List<int> newIds) {
        checkHandleMessages([
          for (final id in oldIds)
            eg.streamMessage(stream: streamA, topic: 'a', sender: userX, id: id),
        ], [
          for (final id in newIds)
            eg.streamMessage(stream: streamA, topic: 'a', sender: userX, id: id),
        ]);
      }

      test('batch goes before the existing messages', () {
        checkHandleMessagesSingle([300, 400], [100, 200]);
      });

      test('batch goes after the existing messages', () {
        checkHandleMessagesSingle([300, 400], [500, 600]);
      });

      test('batch is interspersed among the existing messages', () {
        checkHandleMessagesSingle([200, 400], [100, 300, 500]);
      });

      test('batch contains some of already-existing messages', () {
        checkHandleMessagesSingle([200, 300, 400], [100, 200, 400, 500]);
      });
    });

    test('batch with both DM and stream messages -> ignores DM, processes stream messages', () {
      checkHandleMessages([], [
        eg.streamMessage(stream: streamA, topic: 'thing', sender: userX),
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]),
        eg.streamMessage(stream: streamA, topic: 'thing', sender: userX),
      ]);
    });

    test('add new sender', () {
      checkHandleMessages(
        [eg.streamMessage(stream: streamA, topic: 'thing', sender: userX)],
        [eg.streamMessage(stream: streamA, topic: 'thing', sender: userY)]);
    });

    test('add new topic', () {
      checkHandleMessages(
        [eg.streamMessage(stream: streamA, topic: 'thing', sender: userX)],
        [eg.streamMessage(stream: streamA, topic: 'other', sender: userX)]);
    });

    test('case-insensitive topics', () {
      checkHandleMessages(
        [eg.streamMessage(stream: streamA, topic: 'thing', sender: userX)],
        [eg.streamMessage(stream: streamA, topic: 'ThInG', sender: userX)]);
      check(model.topicSenders).values.single.deepEquals(
        {eg.t('thing'):
          {userX.userId: (Subject<Object?> it) =>
             it.isA<MessageIdTracker>().ids.length.equals(2)}});
    });

    test('add new stream', () {
      checkHandleMessages(
        [eg.streamMessage(stream: streamA, topic: 'thing', sender: userX)],
        [eg.streamMessage(stream: streamB, topic: 'thing', sender: userX)]);
    });

    test('multiple conversations and senders interspersed', () {
      checkHandleMessages([], [
        eg.streamMessage(stream: streamA, topic: 'thing', sender: userX),
        eg.streamMessage(stream: streamA, topic: 'other', sender: userX),
        eg.streamMessage(stream: streamB, topic: 'thing', sender: userX),
        eg.streamMessage(stream: streamA, topic: 'thing', sender: userY),
        eg.streamMessage(stream: streamA, topic: 'thing', sender: userX),
      ]);
    });
  });

  test('RecentSenders.handleDeleteMessageEvent', () {
    final model = RecentSenders();
    final stream = eg.stream();
    final userX = eg.user();
    final userY = eg.user();

    final messages = [
      eg.streamMessage(stream: stream, topic: 'thing', sender: userX),
      eg.streamMessage(stream: stream, topic: 'other', sender: userX),
      eg.streamMessage(stream: stream, topic: 'thing', sender: userY),
    ];

    model.handleMessages(messages);
    checkMatchesMessages(model, messages);

    model.handleDeleteMessageEvent(eg.deleteMessageEvent([messages[0], messages[2]]),
      Map.fromEntries(messages.map((msg) => MapEntry(msg.id, msg))));

    checkMatchesMessages(model, [messages[1]]);

    // check case-insensitivity
    model.handleDeleteMessageEvent(DeleteMessageEvent(
      id: 0,
      messageIds: [messages[1].id],
      messageType: MessageType.stream,
      streamId: stream.streamId,
      topic: eg.t('oThEr'),
    ), {messages[1].id: messages[1]});
    checkMatchesMessages(model, []);
  });

  test('RecentSenders.latestMessageIdOfSenderInStream', () {
    final model = RecentSenders();
    final stream1 = eg.stream(streamId: 1);
    final user10 = eg.user(userId: 10);

    final messages = [
      eg.streamMessage(stream: stream1, sender: user10, id: 100),
      eg.streamMessage(stream: stream1, sender: user10, id: 200),
      eg.streamMessage(stream: stream1, sender: user10, id: 300),
    ];

    model.handleMessages(messages);

    check(model.latestMessageIdOfSenderInStream(
      streamId: 1, senderId: 10)).equals(300);
    // No message of user 20 in stream1.
    check(model.latestMessageIdOfSenderInStream(
      streamId: 1, senderId: 20)).equals(null);
    // No message in stream 2 at all.
    check(model.latestMessageIdOfSenderInStream(
      streamId: 2, senderId: 10)).equals(null);
  });

  test('RecentSenders.latestMessageIdOfSenderInTopic', () {
    final model = RecentSenders();
    final stream1 = eg.stream(streamId: 1);
    final user10 = eg.user(userId: 10);

    final messages = [
      eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 200),
      eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 300),
    ];

    model.handleMessages(messages);

    check(model.latestMessageIdOfSenderInTopic(streamId: 1,
      topic: eg.t('a'), senderId: 10)).equals(300);
    // case-insensitivity
    check(model.latestMessageIdOfSenderInTopic(streamId: 1,
      topic: eg.t('A'), senderId: 10)).equals(300);
    // No message of user 20 in topic "a".
    check(model.latestMessageIdOfSenderInTopic(streamId: 1,
      topic: eg.t('a'), senderId: 20)).equals(null);
    // No message in topic "b" at all.
    check(model.latestMessageIdOfSenderInTopic(streamId: 1,
      topic: eg.t('b'), senderId: 10)).equals(null);
    // No message in stream 2 at all.
    check(model.latestMessageIdOfSenderInTopic(streamId: 2,
      topic: eg.t('a'), senderId: 10)).equals(null);
  });
}

extension MessageIdTrackerChecks on Subject<MessageIdTracker> {
  Subject<QueueList<int>> get ids => has((x) => x.ids, 'ids');
}
