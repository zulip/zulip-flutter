import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/recent_senders.dart';
import '../example_data.dart' as eg;

/// [messages] should be sorted by [id] ascending.
void checkMatchesMessages(RecentSenders model, List<Message> messages) {
  final Map<int, Map<int, Set<int>>> messagesByUserInStream = {};
  final Map<int, Map<String, Map<int, Set<int>>>> messagesByUserInTopic = {};
  for (final message in messages) {
    if (message is! ChannelMessage) {
      throw UnsupportedError('Message of type ${message.runtimeType} is not expected.');
    }

    final ChannelMessage(:streamId, :topic, :senderId, id: int messageId) = message;

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
    test('channel message gets included', () {
      final model = RecentSenders();
      final channelMessage = eg.channelMessage();
      model.handleMessage(channelMessage);
      checkMatchesMessages(model, [channelMessage]);
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
        ..removeWhere((m) => m is! ChannelMessage);
      checkMatchesMessages(model, expectedMessages);
    }

    group('single tracker', () {
      void checkHandleMessagesSingle(List<int> oldIds, List<int> newIds) {
        checkHandleMessages([
          for (final id in oldIds)
            eg.channelMessage(stream: streamA, topic: 'a', sender: userX, id: id),
        ], [
          for (final id in newIds)
            eg.channelMessage(stream: streamA, topic: 'a', sender: userX, id: id),
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

    test('batch with both DM and channel messages -> ignores DM, processes channel messages', () {
      checkHandleMessages([], [
        eg.channelMessage(stream: streamA, topic: 'thing', sender: userX),
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]),
        eg.channelMessage(stream: streamA, topic: 'thing', sender: userX),
      ]);
    });

    test('add new sender', () {
      checkHandleMessages(
        [eg.channelMessage(stream: streamA, topic: 'thing', sender: userX)],
        [eg.channelMessage(stream: streamA, topic: 'thing', sender: userY)]);
    });

    test('add new topic', () {
      checkHandleMessages(
        [eg.channelMessage(stream: streamA, topic: 'thing', sender: userX)],
        [eg.channelMessage(stream: streamA, topic: 'other', sender: userX)]);
    });

    test('add new stream', () {
      checkHandleMessages(
        [eg.channelMessage(stream: streamA, topic: 'thing', sender: userX)],
        [eg.channelMessage(stream: streamB, topic: 'thing', sender: userX)]);
    });

    test('multiple conversations and senders interspersed', () {
      checkHandleMessages([], [
        eg.channelMessage(stream: streamA, topic: 'thing', sender: userX),
        eg.channelMessage(stream: streamA, topic: 'other', sender: userX),
        eg.channelMessage(stream: streamB, topic: 'thing', sender: userX),
        eg.channelMessage(stream: streamA, topic: 'thing', sender: userY),
        eg.channelMessage(stream: streamA, topic: 'thing', sender: userX),
      ]);
    });
  });

  test('RecentSenders.handleDeleteMessageEvent', () {
    final model = RecentSenders();
    final stream = eg.stream();
    final userX = eg.user();
    final userY = eg.user();

    final messages = [
      eg.channelMessage(stream: stream, topic: 'thing', sender: userX),
      eg.channelMessage(stream: stream, topic: 'other', sender: userX),
      eg.channelMessage(stream: stream, topic: 'thing', sender: userY),
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
      eg.channelMessage(stream: stream1, sender: user10, id: 100),
      eg.channelMessage(stream: stream1, sender: user10, id: 200),
      eg.channelMessage(stream: stream1, sender: user10, id: 300),
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
      eg.channelMessage(stream: stream1, topic: 'a', sender: user10, id: 200),
      eg.channelMessage(stream: stream1, topic: 'a', sender: user10, id: 300),
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
