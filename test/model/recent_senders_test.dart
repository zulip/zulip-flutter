import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/recent_senders.dart';
import 'package:zulip/model/store.dart';
import '../example_data.dart' as eg;
import 'test_store.dart';

/// [messages] should be sorted by [id] ascending.
void checkMatchesMessages(RecentSenders model, List<Message> messages) {
  final Map<int, Map<int, Set<int>>> messagesByUserInStream = {};
  final Map<int, Map<TopicName, Map<int, Set<int>>>> messagesByUserInTopic = {};
  messages.sort((a, b) => a.id - b.id);
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

  group('RecentSenders.handleUpdateMessageEvent', () {
    late PerAccountStore store;
    late RecentSenders model;

    final origChannel = eg.stream(); final newChannel = eg.stream();
    final origTopic   = 'origTopic'; final newTopic   = 'newTopic';
    final userX       = eg.user();   final userY      = eg.user();

    Future<void> prepare(List<Message> messages) async {
      store = eg.store();
      await store.addMessages(messages);
      await store.addStreams([origChannel, newChannel]);
      await store.addUsers([userX, userY]);
      model = store.recentSenders;
    }

    List<StreamMessage> copyMessagesWith(Iterable<StreamMessage> messages, {
      ZulipStream? newChannel,
      String? newTopic,
    }) {
      assert(newChannel != null || newTopic != null);
      return messages.map((message) => StreamMessage.fromJson(
        message.toJson()
          ..['stream_id'] = newChannel?.streamId ?? message.streamId
          // See [StreamMessage.displayRecipient] for why this is needed.
          ..['display_recipient'] = newChannel?.name ?? message.displayRecipient!

          ..['subject'] = newTopic ?? message.topic
      )).toList();
    }

    test('move a conversation entirely, with additional unknown messages', () async {
      final messages = List.generate(10, (i) => eg.streamMessage(
        stream: origChannel, topic: origTopic, sender: userX));
      await prepare(messages);
      final unknownMessages = List.generate(10, (i) => eg.streamMessage(
        stream: origChannel, topic: origTopic, sender: userX));
      checkMatchesMessages(model, messages);

      final messageIdsByUserInTopicBefore =
        model.topicSenders[origChannel.streamId]![eg.t(origTopic)]![userX.userId]!.ids;

      await store.handleEvent(eg.updateMessageEventMoveFrom(
        origMessages: messages + unknownMessages,
        newStreamId: newChannel.streamId));
      checkMatchesMessages(model, copyMessagesWith(
        messages, newChannel: newChannel));

      // Check we avoided creating a new list for the moved message IDs.
      check(messageIdsByUserInTopicBefore).identicalTo(
        model.topicSenders[newChannel.streamId]![eg.t(origTopic)]![userX.userId]!.ids);
    });

    test('move a conversation exactly', () async {
      final messages = List.generate(10, (i) => eg.streamMessage(
        stream: origChannel, topic: origTopic, sender: userX));
      await prepare(messages);

      final messageIdsByUserInTopicBefore =
        model.topicSenders[origChannel.streamId]![eg.t(origTopic)]![userX.userId]!.ids;

      await store.handleEvent(eg.updateMessageEventMoveFrom(
        origMessages: messages,
        newStreamId: newChannel.streamId,
        newTopicStr: newTopic));
      checkMatchesMessages(model, copyMessagesWith(
        messages, newChannel: newChannel, newTopic: newTopic));

      // Check we avoided creating a new list for the moved message IDs.
      check(messageIdsByUserInTopicBefore).identicalTo(
        model.topicSenders[newChannel.streamId]![eg.t(newTopic)]![userX.userId]!.ids);
    });

    test('move a conversation partially to a different channel', () async {
      final messages = List.generate(10, (i) => eg.streamMessage(
        stream: origChannel, topic: origTopic));
      final movedMessages = messages.take(5).toList();
      final otherMessages = messages.skip(5);
      await prepare(messages);

      await store.handleEvent(eg.updateMessageEventMoveFrom(
        origMessages: movedMessages,
        newStreamId: newChannel.streamId));
      checkMatchesMessages(model, [
        ...copyMessagesWith(movedMessages, newChannel: newChannel),
        ...otherMessages,
      ]);
    });

    test('move a conversation partially to a different topic, within the same channel', () async {
      final messages = List.generate(10, (i) => eg.streamMessage(
        stream: origChannel, topic: origTopic, sender: userX));
      final movedMessages = messages.take(5).toList();
      final otherMessages = messages.skip(5);
      await prepare(messages);

      final messageIdsByUserInStreamBefore =
        model.streamSenders[origChannel.streamId]![userX.userId]!.ids;

      await store.handleEvent(eg.updateMessageEventMoveFrom(
        origMessages: movedMessages,
        newTopicStr: newTopic));
      checkMatchesMessages(model, [
        ...copyMessagesWith(movedMessages, newTopic: newTopic),
        ...otherMessages,
      ]);

      // Check that we did not touch stream message IDs tracker
      // when there wasn't a stream move.
      check(messageIdsByUserInStreamBefore).identicalTo(
        model.streamSenders[origChannel.streamId]![userX.userId]!.ids);
    });

    test('move a conversation with multiple senders', () async {
      final messages = [
        eg.streamMessage(stream: origChannel, topic: origTopic, sender: userX),
        eg.streamMessage(stream: origChannel, topic: origTopic, sender: userX),
        eg.streamMessage(stream: origChannel, topic: origTopic, sender: userY),
      ];
      await prepare(messages);

      await store.handleEvent(eg.updateMessageEventMoveFrom(
        origMessages: messages,
        newStreamId: newChannel.streamId));
      checkMatchesMessages(model, copyMessagesWith(
        messages, newChannel: newChannel));
    });

    test('move a converstion, but message IDs from the event are not sorted in ascending order', () async {
      final messages = List.generate(10, (i) => eg.streamMessage(
        id: 100-i, stream: origChannel, topic: origTopic));
      await prepare(messages);

      await store.handleEvent(eg.updateMessageEventMoveFrom(
        origMessages: messages,
        newStreamId: newChannel.streamId));
      checkMatchesMessages(model,
        copyMessagesWith(messages, newChannel: newChannel));
    });

    test('message edit update without move', () async {
      final messages = List.generate(10, (i) => eg.streamMessage(
        stream: origChannel, topic: origTopic));
      await prepare(messages);

      await store.handleEvent(eg.updateMessageEditEvent(messages[0]));
      checkMatchesMessages(model, messages);
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
