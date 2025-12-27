import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/topics.dart';

import '../api/fake_api.dart';
import '../api/route/route_checks.dart';
import '../example_data.dart' as eg;
import '../fake_async.dart';
import '../stdlib_checks.dart';
import 'test_store.dart';

void main() {
  late PerAccountStore store;
  late Topics model;
  late FakeApiConnection connection;
  late int notifiedCount;

  void checkNotified({required int count}) {
    check(notifiedCount).equals(count);
    notifiedCount = 0;
  }
  void checkNotNotified()  => checkNotified(count: 0);
  void checkNotifiedOnce() => checkNotified(count: 1);

  Condition<Object?> isChannelTopicsRequest(int channelId) {
    return (it) => it.isA<http.Request>()
      ..method.equals('GET')
      ..url.path.equals('/api/v1/users/me/$channelId/topics')
      ..url.queryParameters['allow_empty_topic_name'].equals('true');
  }

  Condition<Object?> isChannelTopicsEntry(String topic, int maxId) {
    return (it) => it.isA<GetChannelTopicsEntry>()
      ..maxId.equals(maxId)
      ..name.equals(eg.t(topic));
  }

  final channel = eg.stream();
  final otherChannel = eg.stream();

  Future<void> prepare({
    List<GetChannelTopicsEntry>? topics,
  }) async {
    store = eg.store();

    notifiedCount = 0;
    model = store.topics..addListener(() => notifiedCount++);

    connection = store.connection as FakeApiConnection;
    if (topics != null) {
      connection.prepare(json: GetChannelTopicsResult(topics: topics).toJson());
      await model.fetchChannelTopics(channel.streamId);
      check(connection.takeRequests()).single.which(isChannelTopicsRequest(channel.streamId));
    }
  }

  test('fetch topics -> update data, try fetching again -> no request sent', () async {
    await prepare(topics: [
      eg.getChannelTopicsEntry(name: 'foo', maxId: 100),
    ]);
    check(model).getChannelTopics(channel.streamId).isNotNull()
      .single.which(isChannelTopicsEntry('foo', 100));

    // No need to prepare a response as there will be no request made.
    await model.fetchChannelTopics(channel.streamId);
    check(connection.takeRequests()).isEmpty();
    check(model).getChannelTopics(channel.streamId).isNotNull()
      .single.which(isChannelTopicsEntry('foo', 100));
  });

  test('fetchChannelTopics prevents concurrent requests for the same channel', () => awaitFakeAsync((async) async {
    await prepare();

    connection.prepare(delay: Duration(seconds: 3),
      json: GetChannelTopicsResult(topics: [
        eg.getChannelTopicsEntry(name: 'foo', maxId: 100),
      ]).toJson());
    final future1 = model.fetchChannelTopics(channel.streamId);
    check(connection.takeRequests()).single.which(isChannelTopicsRequest(channel.streamId));
    check(model).getChannelTopics(channel.streamId).isNull();

    // No need to prepare a response as there will be no request made.
    final future2 = model.fetchChannelTopics(channel.streamId);
    check(connection.takeRequests()).isEmpty();
    check(model).getChannelTopics(channel.streamId).isNull();

    await future2;
    check(model).getChannelTopics(channel.streamId).isNull();

    async.elapse(Duration(seconds: 3));
    await future1;
    check(model).getChannelTopics(channel.streamId).isNotNull()
      .single.which(isChannelTopicsEntry('foo', 100));
  }));

  test('getChannelTopics sorts descending by maxId', () async {
    await prepare(topics: [
      eg.getChannelTopicsEntry(name: 'bar', maxId: 200),
      eg.getChannelTopicsEntry(name: 'foo', maxId: 100),
      eg.getChannelTopicsEntry(name: 'baz', maxId: 300),
    ]);
    check(model).getChannelTopics(channel.streamId).isNotNull().deepEquals([
      isChannelTopicsEntry('baz', 300),
      isChannelTopicsEntry('bar', 200),
      isChannelTopicsEntry('foo', 100),
    ]);

    await store.addMessage(eg.streamMessage(
      id: 301, stream: channel, topic: 'foo'));
    check(model).getChannelTopics(channel.streamId).isNotNull().deepEquals([
      isChannelTopicsEntry('foo', 301),
      isChannelTopicsEntry('baz', 300),
      isChannelTopicsEntry('bar', 200),
    ]);
  });

  group('handleMessageEvent', () {
    test('new message in fetched channel', () async {
      await prepare(topics: [
        eg.getChannelTopicsEntry(name: 'old topic', maxId: 1),
      ]);
      check(model).getChannelTopics(channel.streamId).isNotNull().deepEquals([
        isChannelTopicsEntry('old topic', 1),
      ]);

      await store.addMessage(eg.streamMessage(id: 2, stream: channel, topic: 'new topic'));
      check(model).getChannelTopics(channel.streamId).isNotNull().deepEquals([
        isChannelTopicsEntry('new topic', 2),
        isChannelTopicsEntry('old topic', 1),
      ]);
      checkNotifiedOnce();

      await store.addMessage(eg.streamMessage(id: 3, stream: channel, topic: 'old topic'));
      check(model).getChannelTopics(channel.streamId).isNotNull().deepEquals([
        isChannelTopicsEntry('old topic', 3),
        isChannelTopicsEntry('new topic', 2),
      ]);
      checkNotifiedOnce();
    });

    test('new message in channel not fetched before', () async {
      await prepare(topics: []);
      check(model).getChannelTopics(otherChannel.streamId).isNull();

      await store.addMessage(
        eg.streamMessage(id: 2, stream: otherChannel, topic: 'new topic'));
      check(model).getChannelTopics(otherChannel.streamId).isNull();
      checkNotNotified();
    });

    test('new message with equal or lower message ID', () async {
      await prepare(topics: [
        eg.getChannelTopicsEntry(name: 'topic', maxId: 2),
      ]);

      await store.addMessage(
        eg.streamMessage(id: 2, stream: channel, topic: 'topic'));
      check(model).getChannelTopics(channel.streamId).isNotNull()
        .single.which(isChannelTopicsEntry('topic', 2));
      checkNotNotified();

      await store.addMessage(
        eg.streamMessage(id: 1, stream: channel, topic: 'topic'));
      check(model).getChannelTopics(channel.streamId).isNotNull()
        .single.which(isChannelTopicsEntry('topic', 2));
      checkNotNotified();
    });

    test('ignore DM messages', () async {
      await prepare(topics: []);

      await store.addMessage(eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]));
      checkNotNotified();
    });
  });

  group('handleUpdateMessageEvent', () {
    Future<void> prepareWithMessages(List<StreamMessage> messages, {
      required List<Condition<Object?>> expectedTopics,
    }) async {
      await prepare(topics: []);
      assert(messages.isNotEmpty);
      assert(messages.every((m) => m.streamId == channel.streamId));
      await store.addMessages(messages);
      check(model).getChannelTopics(channel.streamId).isNotNull().deepEquals(expectedTopics);
      checkNotified(count: messages.length);
    }

    test('ignore content-only update', () async {
      final message = eg.streamMessage(id: 123, stream: channel, topic: 'foo');
      await prepareWithMessages([message], expectedTopics: [
        isChannelTopicsEntry('foo', 123),
      ]);

      await store.handleEvent(eg.updateMessageEditEvent(message));
      checkNotNotified();
    });

    group('PropagateMode.changeAll', () {
      test('topic moved to another channel with no previously fetched topics', () async {
        final messagesToMove = List.generate(10, (i) =>
          eg.streamMessage(id: 100 + i, stream: channel, topic: 'foo'));
        await prepareWithMessages(messagesToMove, expectedTopics: [
          isChannelTopicsEntry('foo', 109),
        ]);

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: messagesToMove,
          newStreamId: otherChannel.streamId,
          propagateMode: .changeAll));
        check(model).getChannelTopics(channel.streamId).isNotNull().isEmpty();
        check(model).getChannelTopics(otherChannel.streamId).isNull();
        checkNotifiedOnce();
      });

      test('topic moved to new topic in another channel', () async {
        final messagesToMove = List.generate(10, (i) =>
          eg.streamMessage(id: 100 + i, stream: channel, topic: 'foo'));
        await prepareWithMessages(messagesToMove, expectedTopics: [
          isChannelTopicsEntry('foo', 109),
        ]);

        // Make sure that topics in otherChannel have been fetched.
        connection.prepare(json: GetChannelTopicsResult(topics: [
          eg.getChannelTopicsEntry(name: 'foo', maxId: 1),
        ]).toJson());
        await model.fetchChannelTopics(otherChannel.streamId);
        check(model).getChannelTopics(otherChannel.streamId).isNotNull()
          .single.which(isChannelTopicsEntry('foo', 1));
        checkNotNotified();

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: messagesToMove,
          newStreamId: otherChannel.streamId,
          newTopicStr: 'bar',
          propagateMode: .changeAll));
        check(model).getChannelTopics(channel.streamId).isNotNull().isEmpty();
        check(model).getChannelTopics(otherChannel.streamId).isNotNull().deepEquals([
          isChannelTopicsEntry('bar', 109),
          isChannelTopicsEntry('foo', 1),
        ]);
        checkNotifiedOnce();
      });

      test('topic moved to existing topic in another channel', () async {
        final messagesToMove = List.generate(10, (i) =>
          eg.streamMessage(id: 100 + i, stream: channel, topic: 'foo'));
        await prepareWithMessages(messagesToMove, expectedTopics: [
          isChannelTopicsEntry('foo', 109),
        ]);

        // Make sure that topics in otherChannel have been fetched.
        connection.prepare(json: GetChannelTopicsResult(topics: [
          eg.getChannelTopicsEntry(name: 'foo', maxId: 1),
        ]).toJson());
        await model.fetchChannelTopics(otherChannel.streamId);
        check(model).getChannelTopics(otherChannel.streamId).isNotNull()
          .single.which(isChannelTopicsEntry('foo', 1));
        checkNotNotified();

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: messagesToMove,
          newStreamId: otherChannel.streamId,
          propagateMode: .changeAll));
        check(model).getChannelTopics(channel.streamId).isNotNull().isEmpty();
        check(model).getChannelTopics(otherChannel.streamId).isNotNull()
          .single.which(isChannelTopicsEntry('foo', 109));
        checkNotifiedOnce();
      });

      test('topic moved to new topic in the same channel', () async {
        final messagesToMove = List.generate(10, (i) =>
          eg.streamMessage(id: 100 + i, stream: channel, topic: 'foo'));
        await prepareWithMessages(messagesToMove, expectedTopics: [
          isChannelTopicsEntry('foo', 109),
        ]);

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: messagesToMove,
          newTopicStr: 'bar',
          propagateMode: .changeAll));
        check(model).getChannelTopics(channel.streamId).isNotNull()
          .single.which(isChannelTopicsEntry('bar', 109));
        checkNotifiedOnce();
      });

      test('topic moved to existing topic in the same channel', () async {
        final messagesToMove = List.generate(10, (i) =>
          eg.streamMessage(id: 100 + i, stream: channel, topic: 'foo'));
        await prepareWithMessages([
          ...messagesToMove,
          eg.streamMessage(id: 1, stream: channel, topic: 'bar'),
        ], expectedTopics: [
          isChannelTopicsEntry('foo', 109),
          isChannelTopicsEntry('bar', 1),
        ]);

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: messagesToMove,
          newTopicStr: 'bar',
          propagateMode: .changeAll));
        check(model).getChannelTopics(channel.streamId).isNotNull()
          .single.which(isChannelTopicsEntry('bar', 109));
        checkNotifiedOnce();
      });
    });

    group('PropagateMode.changeOne', () {
      test('message moved to new topic', () async {
        final messageToMove =
          eg.streamMessage(id: 101, stream: channel, topic: 'foo');
        await prepareWithMessages([
          messageToMove,
        ], expectedTopics: [
          isChannelTopicsEntry('foo', 101),
        ]);

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: [messageToMove],
          newTopicStr: 'bar',
          propagateMode: .changeOne));
        check(model).getChannelTopics(channel.streamId).isNotNull().deepEquals([
          isChannelTopicsEntry('foo', 101),
          isChannelTopicsEntry('bar', 101),
        ]);
        checkNotifiedOnce();
      });

      test('message moved to existing topic; moved message ID < maxId', () async {
        final messageToMove =
          eg.streamMessage(id: 100, stream: channel, topic: 'foo');
        await prepareWithMessages([
          messageToMove,
          eg.streamMessage(id: 999, stream: channel, topic: 'bar'),
        ], expectedTopics: [
          isChannelTopicsEntry('bar', 999),
          isChannelTopicsEntry('foo', 100),
        ]);

        // Message with ID 100 moved from "foo" to "bar", whose maxId was 999.
        // We expect no updates to "bar"'s maxId, since the moved message
        // has a lower ID.
        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: [messageToMove],
          newTopicStr: 'bar',
          propagateMode: .changeOne));
        check(model).getChannelTopics(channel.streamId).isNotNull().deepEquals([
          isChannelTopicsEntry('bar', 999),
          isChannelTopicsEntry('foo', 100),
        ]);
        checkNotNotified();
      });

      test('message moved to existing topic; moved message ID > maxId', () async {
        final messageToMove =
          eg.streamMessage(id: 999, stream: channel, topic: 'foo');
        await prepareWithMessages([
          messageToMove,
          eg.streamMessage(id: 100, stream: channel, topic: 'bar'),
        ], expectedTopics: [
          isChannelTopicsEntry('foo', 999),
          isChannelTopicsEntry('bar', 100),
        ]);

        // Message with ID 999 moved from "foo" to "bar", whose maxId was 100.
        // We expect an update to "bar"'s maxId, since the moved message has
        // a higher ID.
        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: [messageToMove],
          newTopicStr: 'bar',
          propagateMode: .changeOne));
        check(model).getChannelTopics(channel.streamId).isNotNull().deepEquals([
          isChannelTopicsEntry('foo', 999),
          isChannelTopicsEntry('bar', 999),
        ]);
        checkNotifiedOnce();
      });
    });

    group('PropagateMode.changeLater', () {
      test('messages moved to new topic', () async {
        final messagesToMove = [
          eg.streamMessage(id: 99,  stream: channel, topic: 'foo'),
          eg.streamMessage(id: 100, stream: channel, topic: 'foo'),
        ];
        await prepareWithMessages(messagesToMove,
          expectedTopics: [
            isChannelTopicsEntry('foo', 100),
          ]);

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: messagesToMove,
          newTopicStr: 'bar',
          propagateMode: .changeLater));
        check(model).getChannelTopics(channel.streamId).isNotNull().deepEquals([
          isChannelTopicsEntry('foo', 100),
          isChannelTopicsEntry('bar', 100),
        ]);
        checkNotifiedOnce();
      });

      test('messages moved to existing topic; moved messages max ID < maxId', () async {
        final messagesToMove = [
          eg.streamMessage(id: 99,  stream: channel, topic: 'foo'),
          eg.streamMessage(id: 100, stream: channel, topic: 'foo'),
        ];
        await prepareWithMessages([
          ...messagesToMove,
          eg.streamMessage(id: 999, stream: channel, topic: 'bar'),
        ], expectedTopics: [
          isChannelTopicsEntry('bar', 999),
          isChannelTopicsEntry('foo', 100),
        ]);

        // Messages with max ID 100 moved from "foo" to "bar", whose maxId
        // was 999. We expect no updates to "bar"'s maxId, since the moved
        // messages have a lower max ID.
        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: messagesToMove,
          newTopicStr: 'bar',
          propagateMode: .changeLater));
        check(model).getChannelTopics(channel.streamId).isNotNull().deepEquals([
          isChannelTopicsEntry('bar', 999),
          isChannelTopicsEntry('foo', 100),
        ]);
        checkNotNotified();
      });

      test('message moved to existing topic; moved messages max ID > maxId', () async {
        final messagesToMove = [
          eg.streamMessage(id: 999,  stream: channel, topic: 'foo'),
          eg.streamMessage(id: 1000, stream: channel, topic: 'foo'),
        ];
        await prepareWithMessages([
          ...messagesToMove,
          eg.streamMessage(id: 100, stream: channel, topic: 'bar'),
        ], expectedTopics: [
          isChannelTopicsEntry('foo', 1000),
          isChannelTopicsEntry('bar', 100),
        ]);

        // Messages with max ID 1000 moved from "foo" to "bar", whose maxId
        // was 100. We expect an update to "bar"'s maxId, since the moved
        // messages have a higher max ID.
        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: messagesToMove,
          newTopicStr: 'bar',
          propagateMode: .changeLater));
        check(model).getChannelTopics(channel.streamId).isNotNull().deepEquals([
          isChannelTopicsEntry('foo', 1000),
          isChannelTopicsEntry('bar', 1000),
        ]);
        checkNotifiedOnce();
      });
    });
  });
}

extension TopicsChecks on Subject<Topics> {
  Subject<List<GetChannelTopicsEntry>?> getChannelTopics(int channelId) => has((x) => x.getChannelTopics(channelId), 'getChannelTopics');
}
