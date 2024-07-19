import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/recent_senders.dart';
import '../example_data.dart' as eg;

/// [messages] should be sorted by [id] ascendingly.
void checkMatchesMessages(RecentSenders model, List<Message> messages) {
  final Map<int, Map<int, Set<int>>> messagesByUserInStream = {};
  final Map<int, Map<String, Map<int, Set<int>>>> messagesByUserInTopic = {};
  for (final message in messages) {
    if (message is! StreamMessage) {
      throw UnsupportedError('Message of type ${message.runtimeType} is not expected.');
    }

    final StreamMessage(:streamId, :topic, :senderId, id: int messageId) = message;

    ((messagesByUserInStream[streamId] ??= {})
      [senderId] ??= {}).add(messageId);
    (((messagesByUserInTopic[streamId] ??= {})[topic] ??= {})
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
    final stream1 = eg.stream(streamId: 1);
    final user10 = eg.user(userId: 10);

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
            eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: id),
        ], [
          for (final id in newIds)
            eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: id),
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
      checkHandleMessages([
        eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 100),
        eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 200),
      ], [
        eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 300),
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser], id: 400),
        eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 500),
      ]);
    });

    group('multiple trackers', () {
      test('batch goes before the existing messages', () {
        checkHandleMessages([
          eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 300),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 500),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 600),
        ], [
          eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 200),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 400),
        ]);
      });

      test('batch goes after the existing messages', () {
        checkHandleMessages([
          eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 300),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 600),
        ], [
          eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 400),
          eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 500),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 700),
        ]);
      });

      test('batch is interspersed among the existing messages', () {
        checkHandleMessages([
          eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 100),
          eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 300),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 500),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 700),
        ], [
          eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 200),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 400),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 600),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 800),
        ]);
      });

      test('batch contains some of already-existing messages', () {
        checkHandleMessages([
          eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 200),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 300),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 400),
        ], [
          eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 200),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 400),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 500),
        ]);
      });

      test('batch with both DM and stream messages -> ignores DM, processes stream messages', () {
        checkHandleMessages([
          eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 100),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 200),
        ], [
          eg.streamMessage(stream: stream1, topic: 'a', sender: user10, id: 300),
          eg.dmMessage(from: eg.otherUser, to: [eg.selfUser], id: 200),
          eg.streamMessage(stream: stream1, topic: 'b', sender: user10, id: 400),
        ]);
      });
    });
  });

  test('RecentSenders.handleDeleteMessageEvent', () {
    final model = RecentSenders();
    final stream1 = eg.stream(streamId: 1);
    final user1 = eg.user(userId: 1);
    final user2 = eg.user(userId: 2);

    final messages = [
      eg.streamMessage(stream: stream1, topic: 'a', sender: user1, id: 100),
      eg.streamMessage(stream: stream1, topic: 'b', sender: user1, id: 200),
      eg.streamMessage(stream: stream1, topic: 'a', sender: user2, id: 300),
    ];

    model.handleMessages(messages);
    checkMatchesMessages(model, messages);

    model.handleDeleteMessageEvent(eg.deleteMessageEvent([messages[0], messages[2]]),
      Map.fromEntries(messages.map((msg) => MapEntry(msg.id, msg))));

    checkMatchesMessages(model, [messages[1]]);
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
      topic: 'a', senderId: 10)).equals(300);
    // No message of user 20 in topic "a".
    check(model.latestMessageIdOfSenderInTopic(streamId: 1,
      topic: 'a', senderId: 20)).equals(null);
    // No message in topic "b" at all.
    check(model.latestMessageIdOfSenderInTopic(streamId: 1,
      topic: 'b', senderId: 10)).equals(null);
    // No message in stream 2 at all.
    check(model.latestMessageIdOfSenderInTopic(streamId: 2,
      topic: 'a', senderId: 10)).equals(null);
  });
}
