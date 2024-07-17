import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/narrow.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/algorithms.dart';
import 'package:zulip/model/content.dart';
import 'package:zulip/model/message_list.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';

import '../api/fake_api.dart';
import '../api/model/model_checks.dart';
import '../example_data.dart' as eg;
import '../fake_async.dart';
import '../stdlib_checks.dart';
import 'content_checks.dart';
import 'recent_senders_test.dart' as recent_senders_test;
import 'test_store.dart';

void main() {
  // These variables are the common state operated on by each test.
  // Each test case calls [prepare] to initialize them.
  late Subscription subscription;
  late PerAccountStore store;
  late FakeApiConnection connection;
  late MessageListView model;
  late int notifiedCount;

  void checkNotified({required int count}) {
    check(notifiedCount).equals(count);
    notifiedCount = 0;
  }
  void checkNotNotified() {
    checkInvariants(model);
    checkNotified(count: 0);
  }
  void checkNotifiedOnce() => checkNotified(count: 1);

  /// Initialize [model] and the rest of the test state.
  Future<void> prepare({Narrow narrow = const CombinedFeedNarrow()}) async {
    final stream = eg.stream(streamId: eg.defaultStreamMessageStreamId);
    subscription = eg.subscription(stream);
    store = eg.store();
    await store.addStream(stream);
    await store.addSubscription(subscription);
    connection = store.connection as FakeApiConnection;
    notifiedCount = 0;
    model = MessageListView.init(store: store, narrow: narrow)
      ..addListener(() {
        checkInvariants(model);
        notifiedCount++;
      });
    check(model).fetched.isFalse();
    checkNotNotified();
  }

  /// Perform the initial message fetch for [model].
  ///
  /// The test case must have already called [prepare] to initialize the state.
  Future<void> prepareMessages({
    required bool foundOldest,
    required List<Message> messages,
  }) async {
    connection.prepare(json:
      newestResult(foundOldest: foundOldest, messages: messages).toJson());
    await model.fetchInitial();
    checkNotifiedOnce();
  }

  void checkLastRequest({
    required ApiNarrow narrow,
    required String anchor,
    bool? includeAnchor,
    required int numBefore,
    required int numAfter,
  }) {
    check(connection.lastRequest).isA<http.Request>()
      ..method.equals('GET')
      ..url.path.equals('/api/v1/messages')
      ..url.queryParameters.deepEquals({
        'narrow': jsonEncode(narrow),
        'anchor': anchor,
        if (includeAnchor != null) 'include_anchor': includeAnchor.toString(),
        'num_before': numBefore.toString(),
        'num_after': numAfter.toString(),
      });
  }

  test('fetchInitial', () async {
    const narrow = CombinedFeedNarrow();
    await prepare(narrow: narrow);
    connection.prepare(json: newestResult(
      foundOldest: false,
      messages: List.generate(kMessageListFetchBatchSize,
        (i) => eg.streamMessage()),
    ).toJson());
    final fetchFuture = model.fetchInitial();
    check(model).fetched.isFalse();

    checkNotNotified();
    await fetchFuture;
    checkNotifiedOnce();
    check(model)
      ..messages.length.equals(kMessageListFetchBatchSize)
      ..haveOldest.isFalse();
    checkLastRequest(
      narrow: narrow.apiEncode(),
      anchor: 'newest',
      numBefore: kMessageListFetchBatchSize,
      numAfter: 0,
    );
  });

  test('fetchInitial, short history', () async {
    await prepare();
    connection.prepare(json: newestResult(
      foundOldest: true,
      messages: List.generate(30, (i) => eg.streamMessage()),
    ).toJson());
    await model.fetchInitial();
    checkNotifiedOnce();
    check(model)
      ..messages.length.equals(30)
      ..haveOldest.isTrue();
  });

  test('fetchInitial, no messages found', () async {
    await prepare();
    connection.prepare(json: newestResult(
      foundOldest: true,
      messages: [],
    ).toJson());
    await model.fetchInitial();
    checkNotifiedOnce();
    check(model)
      ..fetched.isTrue()
      ..messages.isEmpty()
      ..haveOldest.isTrue();
  });

  // TODO(#824): move this test
  test('fetchInitial, recent senders track all the messages', () async {
    const narrow = CombinedFeedNarrow();
    await prepare(narrow: narrow);
    final messages = [
      eg.streamMessage(),
      // Not subscribed to the stream with id 10.
      eg.streamMessage(stream: eg.stream(streamId: 10)),
    ];
    connection.prepare(json: newestResult(
      foundOldest: false,
      messages: messages,
    ).toJson());
    await model.fetchInitial();

    check(model).messages.length.equals(1);
    recent_senders_test.checkMatchesMessages(store.recentSenders, messages);
  });

  test('fetchOlder', () async {
    const narrow = CombinedFeedNarrow();
    await prepare(narrow: narrow);
    await prepareMessages(foundOldest: false,
      messages: List.generate(100, (i) => eg.streamMessage(id: 1000 + i)));

    connection.prepare(json: olderResult(
      anchor: 1000, foundOldest: false,
      messages: List.generate(100, (i) => eg.streamMessage(id: 900 + i)),
    ).toJson());
    final fetchFuture = model.fetchOlder();
    checkNotifiedOnce();
    check(model).fetchingOlder.isTrue();

    await fetchFuture;
    checkNotifiedOnce();
    check(model)
      ..fetchingOlder.isFalse()
      ..messages.length.equals(200);
    checkLastRequest(
      narrow: narrow.apiEncode(),
      anchor: '1000',
      includeAnchor: false,
      numBefore: kMessageListFetchBatchSize,
      numAfter: 0,
    );
  });

  test('fetchOlder nop when already fetching', () async {
    const narrow = CombinedFeedNarrow();
    await prepare(narrow: narrow);
    await prepareMessages(foundOldest: false,
      messages: List.generate(100, (i) => eg.streamMessage(id: 1000 + i)));

    connection.prepare(json: olderResult(
      anchor: 1000, foundOldest: false,
      messages: List.generate(100, (i) => eg.streamMessage(id: 900 + i)),
    ).toJson());
    final fetchFuture = model.fetchOlder();
    checkNotifiedOnce();
    check(model).fetchingOlder.isTrue();

    // Don't prepare another response.
    final fetchFuture2 = model.fetchOlder();
    checkNotNotified();
    check(model).fetchingOlder.isTrue();

    await fetchFuture;
    await fetchFuture2;
    // We must not have made another request, because we didn't
    // prepare another response and didn't get an exception.
    checkNotifiedOnce();
    check(model)
      ..fetchingOlder.isFalse()
      ..messages.length.equals(200);
  });

  test('fetchOlder nop when already haveOldest true', () async {
    await prepare(narrow: const CombinedFeedNarrow());
    await prepareMessages(foundOldest: true, messages:
      List.generate(30, (i) => eg.streamMessage()));
    check(model)
      ..haveOldest.isTrue()
      ..messages.length.equals(30);

    await model.fetchOlder();
    // We must not have made a request, because we didn't
    // prepare a response and didn't get an exception.
    checkNotNotified();
    check(model)
      ..haveOldest.isTrue()
      ..messages.length.equals(30);
  });

  test('fetchOlder handles servers not understanding includeAnchor', () async {
    const narrow = CombinedFeedNarrow();
    await prepare(narrow: narrow);
    await prepareMessages(foundOldest: false,
      messages: List.generate(100, (i) => eg.streamMessage(id: 1000 + i)));

    // The old behavior is to include the anchor message regardless of includeAnchor.
    connection.prepare(json: olderResult(
      anchor: 1000, foundOldest: false, foundAnchor: true,
      messages: List.generate(101, (i) => eg.streamMessage(id: 900 + i)),
    ).toJson());
    await model.fetchOlder();
    checkNotified(count: 2);
    check(model)
      ..fetchingOlder.isFalse()
      ..messages.length.equals(200);
  });

  // TODO(#824): move this test
  test('fetchOlder, recent senders track all the messages', () async {
    const narrow = CombinedFeedNarrow();
    await prepare(narrow: narrow);
    final initialMessages = List.generate(10, (i) => eg.streamMessage(id: 100 + i));
    await prepareMessages(foundOldest: false, messages: initialMessages);

    final oldMessages = List.generate(10, (i) => eg.streamMessage(id: 89 + i))
      // Not subscribed to the stream with id 10.
      ..add(eg.streamMessage(id: 99, stream: eg.stream(streamId: 10)));
    connection.prepare(json: olderResult(
      anchor: 100, foundOldest: false,
      messages: oldMessages,
    ).toJson());
    await model.fetchOlder();

    check(model).messages.length.equals(20);
    recent_senders_test.checkMatchesMessages(store.recentSenders,
      [...initialMessages, ...oldMessages]);
  });

  test('MessageEvent', () async {
    final stream = eg.stream();
    await prepare(narrow: ChannelNarrow(stream.streamId));
    await prepareMessages(foundOldest: true, messages:
      List.generate(30, (i) => eg.streamMessage(stream: stream)));

    check(model).messages.length.equals(30);
    await store.handleEvent(MessageEvent(id: 0,
      message: eg.streamMessage(stream: stream)));
    checkNotifiedOnce();
    check(model).messages.length.equals(31);
  });

  test('MessageEvent, not in narrow', () async {
    final stream = eg.stream();
    await prepare(narrow: ChannelNarrow(stream.streamId));
    await prepareMessages(foundOldest: true, messages:
      List.generate(30, (i) => eg.streamMessage(stream: stream)));

    check(model).messages.length.equals(30);
    final otherStream = eg.stream();
    await store.handleEvent(MessageEvent(id: 0,
      message: eg.streamMessage(stream: otherStream)));
    checkNotNotified();
    check(model).messages.length.equals(30);
  });

  test('MessageEvent, before fetch', () async {
    final stream = eg.stream();
    await prepare(narrow: ChannelNarrow(stream.streamId));
    await store.handleEvent(MessageEvent(id: 0,
      message: eg.streamMessage(stream: stream)));
    checkNotNotified();
    check(model).fetched.isFalse();
  });

  group('DeleteMessageEvent', () {
    final stream = eg.stream();
    final messages = List.generate(30, (i) => eg.streamMessage(stream: stream));

    test('in narrow', () async {
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await prepareMessages(foundOldest: true, messages: messages);

      check(model).messages.length.equals(30);
      await store.handleEvent(eg.deleteMessageEvent(messages.sublist(0, 10)));
      checkNotifiedOnce();
      check(model).messages.length.equals(20);
    });

    test('not all in narrow', () async {
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await prepareMessages(foundOldest: true, messages: messages.sublist(5));

      check(model).messages.length.equals(25);
      await store.handleEvent(eg.deleteMessageEvent(messages.sublist(0, 10)));
      checkNotifiedOnce();
      check(model).messages.length.equals(20);
    });

    test('not in narrow', () async {
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await prepareMessages(foundOldest: true, messages: messages.sublist(5));

      check(model).messages.length.equals(25);
      await store.handleEvent(eg.deleteMessageEvent(messages.sublist(0, 5)));
      checkNotNotified();
      check(model).messages.length.equals(25);
    });

    test('complete message deletion', () async {
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await prepareMessages(foundOldest: true, messages: messages.sublist(0, 25));

      check(model).messages.length.equals(25);
      await store.handleEvent(eg.deleteMessageEvent(messages));
      checkNotifiedOnce();
      check(model).messages.length.equals(0);
    });

    test('non-consecutive message deletion', () async {
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await prepareMessages(foundOldest: true, messages: messages);
      final messagesToDelete = messages.sublist(2, 5) + messages.sublist(10, 15);

      check(model).messages.length.equals(30);
      await store.handleEvent(eg.deleteMessageEvent(messagesToDelete));
      checkNotifiedOnce();
      check(model.messages.map((message) => message.id)).deepEquals([
        ...messages.sublist(0, 2),
        ...messages.sublist(5, 10),
        ...messages.sublist(15),
      ].map((message) => message.id));
    });
  });

  group('notifyListenersIfMessagePresent', () {
    test('message present', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      await prepareMessages(foundOldest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 100 + i)));
      model.notifyListenersIfMessagePresent(150);
      checkNotifiedOnce();
    });

    test('message absent', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      await prepareMessages(foundOldest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 100 + i))
          .where((m) => m.id != 150).toList());
      model.notifyListenersIfMessagePresent(150);
      checkNotNotified();
    });

    test('message absent (older than window)', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      await prepareMessages(foundOldest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 100 + i)));
      model.notifyListenersIfMessagePresent(50);
      checkNotNotified();
    });

    test('message absent (newer than window)', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      await prepareMessages(foundOldest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 100 + i)));
      model.notifyListenersIfMessagePresent(250);
      checkNotNotified();
    });
  });

  group('notifyListenersIfAnyMessagePresent', () {
    final messages = List.generate(100, (i) => eg.streamMessage(id: 100 + i));

    test('all messages present', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      await prepareMessages(foundOldest: false, messages: messages);
      model.notifyListenersIfAnyMessagePresent([150, 151, 152]);
      checkNotifiedOnce();
    });

    test('some messages present', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      await prepareMessages(foundOldest: false,
        messages: messages.where((m) => m.id != 151).toList());
      model.notifyListenersIfAnyMessagePresent([150, 151, 152]);
      checkNotifiedOnce();
    });

    test('no messages present', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      await prepareMessages(foundOldest: false, messages:
        messages.where((m) => ![150, 151, 152].contains(m.id)).toList());
      model.notifyListenersIfAnyMessagePresent([150, 151, 152]);
      checkNotNotified();
    });
  });

  group('messageContentChanged', () {
    test('message present', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      await prepareMessages(foundOldest: false,
        messages: List.generate(10, (i) => eg.streamMessage(id: 10 + i)));

      final message = model.messages[5];
      await store.handleEvent(eg.updateMessageEditEvent(message,
        renderedContent: '${message.content}<p>edited</p'));
      checkNotifiedOnce();
    });

    test('message absent', () async {
      final stream = eg.stream();
      final narrow = ChannelNarrow(stream.streamId);
      await prepare(narrow: narrow);

      final messagesInNarrow = List<Message>.generate(10,
        (i) => eg.streamMessage(id: 10 + i, stream: stream));
      check(messagesInNarrow.every(narrow.containsMessage)).isTrue();

      final messageNotInNarrow = eg.dmMessage(id: 100, from: eg.otherUser, to: [eg.selfUser]);
      check(narrow.containsMessage(messageNotInNarrow)).isFalse();

      await prepareMessages(foundOldest: false, messages: messagesInNarrow);
      await store.addMessage(messageNotInNarrow);

      await store.handleEvent(eg.updateMessageEditEvent(messageNotInNarrow,
        renderedContent: '${messageNotInNarrow.content}<p>edited</p'));
      checkNotNotified();
    });
  });

  group('messagesMoved', () {
    final stream = eg.stream();
    final otherStream = eg.stream();

    void checkHasMessages(Iterable<Message> messages) {
      check(model.messages.map((e) => e.id)).deepEquals(messages.map((e) => e.id));
    }

    Future<void> prepareNarrow(Narrow narrow, List<Message>? messages) async {
      await prepare(narrow: narrow);
      for (final streamToAdd in [stream, otherStream]) {
        final subscription = eg.subscription(streamToAdd);
        await store.addStream(streamToAdd);
        await store.addSubscription(subscription);
      }
      if (messages != null) {
        await prepareMessages(foundOldest: false, messages: messages);
      }
      checkHasMessages(messages ?? []);
    }

    group('in combined feed narrow', () {
      const narrow = CombinedFeedNarrow();
      final initialMessages = List.generate(5, (i) => eg.streamMessage(stream: stream));
      final movedMessages = List.generate(5, (i) => eg.streamMessage(stream: stream));

      test('internal move between channels', () => awaitFakeAsync((async) async {
        await prepareNarrow(narrow, initialMessages);

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: initialMessages,
          newTopic: initialMessages[0].topic,
          newStreamId: otherStream.streamId,
        ));
        checkHasMessages(initialMessages);
        checkNotified(count: 2);
      }));

      test('internal move between topics', () async {
        await prepareNarrow(narrow, initialMessages + movedMessages);

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: movedMessages,
          newTopic: 'new',
        ));
        checkHasMessages(initialMessages + movedMessages);
        checkNotified(count: 2);
      });
    });

    group('in channel narrow', () {
      final narrow = ChannelNarrow(stream.streamId);
      final initialMessages = List.generate(5, (i) => eg.streamMessage(stream: stream));
      final movedMessages = List.generate(5, (i) => eg.streamMessage(stream: stream));
      final otherChannelMovedMessages = List.generate(5, (i) => eg.streamMessage(stream: otherStream, topic: 'topic'));

      test('channel -> channel: internal move', () async {
        await prepareNarrow(narrow, initialMessages + movedMessages);

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: movedMessages,
          newTopic: 'new',
        ));
        checkHasMessages(initialMessages + movedMessages);
        checkNotified(count: 2);
      });

      test('old channel -> channel: refetch', () => awaitFakeAsync((async) async {
        await prepareNarrow(narrow, initialMessages);

        connection.prepare(delay: const Duration(seconds: 2), json: newestResult(
          foundOldest: false,
          messages: initialMessages + movedMessages,
        ).toJson());
        await store.handleEvent(eg.updateMessageEventMoveTo(
          origTopic: 'orig topic',
          origStreamId: otherStream.streamId,
          newMessages: movedMessages,
        ));
        check(model).fetched.isFalse();
        checkHasMessages([]);
        checkNotifiedOnce();

        async.elapse(const Duration(seconds: 2));
        checkHasMessages(initialMessages + movedMessages);
        checkNotifiedOnce();
      }));

      test('channel -> new channel: remove moved messages', () async {
        await prepareNarrow(narrow, initialMessages + movedMessages);

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: movedMessages,
          newTopic: 'new',
          newStreamId: otherStream.streamId,
        ));
        checkHasMessages(initialMessages);
        checkNotifiedOnce();
      });

      test('unrelated channel -> new channel: unaffected', () async {
        await prepareNarrow(narrow, initialMessages);

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: otherChannelMovedMessages,
          newStreamId: otherStream.streamId,
        ));
        checkHasMessages(initialMessages);
        checkNotNotified();
      });

      test('unrelated channel -> unrelated channel: unaffected', () async {
        await prepareNarrow(narrow, initialMessages);

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: otherChannelMovedMessages,
          newTopic: 'new',
        ));
        checkHasMessages(initialMessages);
        checkNotNotified();
      });

      void testMessageMove(PropagateMode propagateMode) => awaitFakeAsync((async) async {
        await prepareNarrow(narrow, initialMessages + movedMessages);
        connection.prepare(delay: const Duration(seconds: 1), json: newestResult(
          foundOldest: false,
          messages: movedMessages,
        ).toJson());
        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: movedMessages,
          newTopic: 'new',
          newStreamId: otherStream.streamId,
          propagateMode: propagateMode,
        ));
        checkNotifiedOnce();
        async.elapse(const Duration(seconds: 1));
        checkHasMessages(initialMessages);
        check(model).narrow.equals(ChannelNarrow(stream.streamId));
        checkNotNotified();
      });

      test('do not follow when propagateMode = changeOne', () {
        testMessageMove(PropagateMode.changeOne);
      });

      test('do not follow when propagateMode = changeLater', () {
        testMessageMove(PropagateMode.changeLater);
      });

      test('do not follow when propagateMode = changeAll', () {
        testMessageMove(PropagateMode.changeAll);
      });
    });

    group('in topic narrow', () {
      final narrow = TopicNarrow(stream.streamId, 'topic');
      final initialMessages = List.generate(5, (i) => eg.streamMessage(stream: stream, topic: 'topic'));
      final movedMessages = List.generate(5, (i) => eg.streamMessage(stream: stream, topic: 'topic'));
      final otherTopicMovedMessages = List.generate(5, (i) => eg.streamMessage(stream: stream, topic: 'other topic'));
      final otherChannelMovedMessages = List.generate(5, (i) => eg.streamMessage(stream: otherStream, topic: 'topic'));

      group('moved into narrow: should refetch messages', () {
        final testCases = [
          ('(old channel, topic) -> (channel, topic)',     200,   null),
          ('(channel, old topic) -> (channel, topic)',     null, 'other'),
          ('(old channel, old topic) -> (channel, topic)', 200,  'other'),
        ];

        for (final (description, origStreamId, origTopic) in testCases) {
          test(description, () => awaitFakeAsync((async) async {
            await prepareNarrow(narrow, initialMessages);

            connection.prepare(delay: const Duration(seconds: 2), json: newestResult(
              foundOldest: false,
              messages: initialMessages + movedMessages,
            ).toJson());
            await store.handleEvent(eg.updateMessageEventMoveTo(
              origStreamId: origStreamId,
              origTopic: origTopic,
              newMessages: movedMessages,
            ));
            check(model).fetched.isFalse();
            checkHasMessages([]);
            checkNotifiedOnce();

            async.elapse(const Duration(seconds: 2));
            checkHasMessages(initialMessages + movedMessages);
            checkNotifiedOnce();
          }));
        }
      });

      group('moved from narrow: should remove moved messages', () {
        final testCases = [
          ('(channel, topic) -> (new channel, topic)',     200,   null),
          ('(channel, topic) -> (channel, new topic)',     null, 'new'),
          ('(channel, topic) -> (new channel, new topic)', 200,  'new'),
        ];

        for (final (description, newStreamId, newTopic) in testCases) {
          test(description, () async {
            await prepareNarrow(narrow, initialMessages + movedMessages);

            await store.handleEvent(eg.updateMessageEventMoveFrom(
              origMessages: movedMessages,
              newStreamId: newStreamId,
              newTopic: newTopic,
            ));
            checkHasMessages(initialMessages);
            checkNotifiedOnce();
          });
        }
      });

      group('irrelevant moves', () {
        test('(channel, old topic) -> (channel, unrelated topic)', () => awaitFakeAsync((async) async {
          await prepareNarrow(narrow, initialMessages);

          await store.handleEvent(eg.updateMessageEventMoveTo(
            origTopic: 'other',
            newMessages: otherTopicMovedMessages,
          ));
          check(model).fetched.isTrue();
          checkHasMessages(initialMessages);
          checkNotNotified();
        }));

        test('(old channel, topic) - > (unrelated channel, topic)', () => awaitFakeAsync((async) async {
          await prepareNarrow(narrow, initialMessages);

          await store.handleEvent(eg.updateMessageEventMoveTo(
            origStreamId: 200,
            newMessages: otherChannelMovedMessages,
          ));
          check(model).fetched.isTrue();
          checkHasMessages(initialMessages);
          checkNotNotified();
        }));
      });

      void handleMoveEvent(PropagateMode propagateMode) => awaitFakeAsync((async) async {
        await prepareNarrow(narrow, initialMessages + movedMessages);
        connection.prepare(delay: const Duration(seconds: 1), json: newestResult(
          foundOldest: false,
          messages: movedMessages,
        ).toJson());
        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: movedMessages,
          newTopic: 'new',
          newStreamId: otherStream.streamId,
          propagateMode: propagateMode,
        ));
        checkNotifiedOnce();
        async.elapse(const Duration(seconds: 1));
      });

      test('do not follow to the new narrow when propagateMode = changeOne', () {
        handleMoveEvent(PropagateMode.changeOne);
        checkNotNotified();
        checkHasMessages(initialMessages);
        check(model).narrow.equals(TopicNarrow(stream.streamId, 'topic'));
      });

      test('follow to the new narrow when propagateMode = changeLater', () {
        handleMoveEvent(PropagateMode.changeLater);
        checkNotifiedOnce();
        checkHasMessages(movedMessages);
        check(model).narrow.equals(TopicNarrow(otherStream.streamId, 'new'));
      });

      test('follow to the new narrow when propagateMode = changeAll', () {
        handleMoveEvent(PropagateMode.changeAll);
        checkNotifiedOnce();
        checkHasMessages(movedMessages);
        check(model).narrow.equals(TopicNarrow(otherStream.streamId, 'new'));
      });

      test('handle move event before initial fetch', () => awaitFakeAsync((async) async {
        await prepare(narrow: narrow);
        final subscription = eg.subscription(stream);
        await store.addStream(stream);
        await store.addSubscription(subscription);
        final followedMessage = eg.streamMessage(stream: stream, topic: 'new');

        connection.prepare(delay: const Duration(seconds: 2), json: newestResult(
          foundOldest: true,
          messages: [followedMessage],
        ).toJson());

        check(model).fetched.isFalse();
        checkHasMessages([]);
        await store.handleEvent(eg.updateMessageEventMoveTo(
          origTopic: 'topic',
          newMessages: [followedMessage],
          propagateMode: PropagateMode.changeAll,
        ));
        check(model).narrow.equals(TopicNarrow(stream.streamId, 'new'));

        async.elapse(const Duration(seconds: 2));
        checkHasMessages([followedMessage]);
      }));
    });

    group('fetch races', () {
      final narrow = ChannelNarrow(stream.streamId);
      final olderMessages = List.generate(5, (i) => eg.streamMessage(stream: stream));
      final initialMessages = List.generate(5, (i) => eg.streamMessage(stream: stream));
      final movedMessages = List.generate(5, (i) => eg.streamMessage(stream: stream));

      test('fetchOlder, _reset, fetchOlder returns, move fetch finishes', () => awaitFakeAsync((async) async {
        await prepareNarrow(narrow, initialMessages);

        connection.prepare(delay: const Duration(seconds: 1), json: olderResult(
          anchor: model.messages[0].id,
          foundOldest: true,
          messages: olderMessages,
        ).toJson());
        final fetchFuture = model.fetchOlder();
        check(model).fetchingOlder.isTrue();
        checkHasMessages(initialMessages);
        checkNotifiedOnce();

        connection.prepare(delay: const Duration(seconds: 2), json: newestResult(
          foundOldest: false,
          messages: initialMessages + movedMessages,
        ).toJson());
        await store.handleEvent(eg.updateMessageEventMoveTo(
          origTopic: movedMessages[0].topic,
          origStreamId: otherStream.streamId,
          newMessages: movedMessages,
        ));
        check(model).fetchingOlder.isFalse();
        checkHasMessages([]);
        checkNotifiedOnce();

        await fetchFuture;
        checkHasMessages([]);
        checkNotNotified();

        async.elapse(const Duration(seconds: 1));
        checkHasMessages(initialMessages + movedMessages);
        checkNotifiedOnce();
      }));

      test('fetchOlder, _reset, move fetch finishes, fetchOlder returns', () => awaitFakeAsync((async) async {
        await prepareNarrow(narrow, initialMessages);

        connection.prepare(delay: const Duration(seconds: 2), json: olderResult(
          anchor: model.messages[0].id,
          foundOldest: true,
          messages: olderMessages,
        ).toJson());
        final fetchFuture = model.fetchOlder();
        checkHasMessages(initialMessages);
        check(model).fetchingOlder.isTrue();
        checkNotifiedOnce();

        connection.prepare(delay: const Duration(seconds: 1), json: newestResult(
          foundOldest: false,
          messages: initialMessages + movedMessages,
        ).toJson());
        await store.handleEvent(eg.updateMessageEventMoveTo(
          origTopic: movedMessages[0].topic,
          origStreamId: otherStream.streamId,
          newMessages: movedMessages,
        ));
        checkHasMessages([]);
        check(model).fetchingOlder.isFalse();
        checkNotifiedOnce();

        async.elapse(const Duration(seconds: 1));
        checkHasMessages(initialMessages + movedMessages);
        checkNotifiedOnce();

        await fetchFuture;
        checkHasMessages(initialMessages + movedMessages);
        checkNotNotified();
      }));

      test('fetchInitial, _reset, initial fetch finishes, move fetch finishes', () => awaitFakeAsync((async) async {
        await prepareNarrow(narrow, null);

        connection.prepare(delay: const Duration(seconds: 1), json: newestResult(
          foundOldest: false,
          messages: initialMessages,
        ).toJson());
        final fetchFuture = model.fetchInitial();
        checkHasMessages([]);
        check(model).fetched.isFalse();

        connection.prepare(delay: const Duration(seconds: 2), json: newestResult(
          foundOldest: false,
          messages: initialMessages + movedMessages,
        ).toJson());
        await store.handleEvent(eg.updateMessageEventMoveTo(
          origTopic: movedMessages[0].topic,
          origStreamId: otherStream.streamId,
          newMessages: movedMessages,
        ));
        checkHasMessages([]);
        check(model).fetched.isFalse();
        checkNotifiedOnce();

        await fetchFuture;
        checkHasMessages([]);
        check(model).fetched.isFalse();
        checkNotNotified();

        async.elapse(const Duration(seconds: 1));
        checkHasMessages(initialMessages + movedMessages);
        checkNotifiedOnce();
      }));

      test('fetchInitial, _reset, move fetch finishes, initial fetch finishes', () => awaitFakeAsync((async) async {
        await prepareNarrow(narrow, null);

        connection.prepare(delay: const Duration(seconds: 2), json: newestResult(
          foundOldest: false,
          messages: initialMessages,
        ).toJson());
        final fetchFuture = model.fetchInitial();
        checkHasMessages([]);
        check(model).fetched.isFalse();

        connection.prepare(delay: const Duration(seconds: 1), json: newestResult(
          foundOldest: false,
          messages: initialMessages + movedMessages,
        ).toJson());
        await store.handleEvent(eg.updateMessageEventMoveTo(
          origTopic: movedMessages[0].topic,
          origStreamId: otherStream.streamId,
          newMessages: movedMessages,
        ));
        checkHasMessages([]);
        check(model).fetched.isFalse();

        async.elapse(const Duration(seconds: 1));
        checkHasMessages(initialMessages + movedMessages);
        check(model).fetched.isTrue();

        await fetchFuture;
        checkHasMessages(initialMessages + movedMessages);
      }));

      test('fetchOlder #1, _reset, move fetch finishes, fetchOlder #2, '
        'fetchOlder #1 finishes, fetchOlder #2 finishes', () => awaitFakeAsync((async) async {
        await prepareNarrow(narrow, initialMessages);

        connection.prepare(delay: const Duration(seconds: 2), json: olderResult(
          anchor: model.messages[0].id,
          foundOldest: true,
          messages: olderMessages,
        ).toJson());
        final fetchFuture1 = model.fetchOlder();
        checkHasMessages(initialMessages);
        check(model).fetchingOlder.isTrue();
        checkNotifiedOnce();

        connection.prepare(delay: const Duration(seconds: 1), json: newestResult(
          foundOldest: false,
          messages: initialMessages + movedMessages,
        ).toJson());
        await store.handleEvent(eg.updateMessageEventMoveTo(
          origTopic: movedMessages[0].topic,
          origStreamId: otherStream.streamId,
          newMessages: movedMessages,
        ));
        checkHasMessages([]);
        check(model).fetchingOlder.isFalse();
        checkNotifiedOnce();

        async.elapse(const Duration(seconds: 1));
        checkNotifiedOnce();

        connection.prepare(delay: const Duration(seconds: 2), json: olderResult(
          anchor: model.messages[0].id,
          foundOldest: true,
          messages: olderMessages
        ).toJson());
        final fetchFuture2 = model.fetchOlder();
        checkHasMessages(initialMessages + movedMessages);
        check(model).fetchingOlder.isTrue();
        checkNotifiedOnce();

        await fetchFuture1;
        checkHasMessages(initialMessages + movedMessages);
        // The older fetchOlder call should not override fetchingOlder set by
        // the new fetchOlder call, nor should it notify the listeners.
        check(model).fetchingOlder.isTrue();
        checkNotNotified();

        await fetchFuture2;
        checkHasMessages(olderMessages + initialMessages + movedMessages);
        check(model).fetchingOlder.isFalse();
        checkNotifiedOnce();
      }));
    });
  });

  group('regression tests for #455', () {
    test('reaction events handled once, even when message is in two message lists', () async {
      final stream = eg.stream();
      store = eg.store();
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream));
      connection = store.connection as FakeApiConnection;

      int notifiedCount1 = 0;
      final model1 = MessageListView.init(store: store,
          narrow: ChannelNarrow(stream.streamId))
        ..addListener(() => notifiedCount1++);

      int notifiedCount2 = 0;
      final model2 = MessageListView.init(store: store,
          narrow: TopicNarrow(stream.streamId, 'hello'))
        ..addListener(() => notifiedCount2++);

      for (final m in [model1, model2]) {
        connection.prepare(json: newestResult(
          foundOldest: false,
          messages: [eg.streamMessage(stream: stream, topic: 'hello')]).toJson());
        await m.fetchInitial();
      }

      final message = eg.streamMessage(stream: stream, topic: 'hello');
      await store.handleEvent(MessageEvent(id: 0, message: message));

      await store.handleEvent(
        eg.reactionEvent(eg.unicodeEmojiReaction, ReactionOp.add, message.id));

      check(notifiedCount1).equals(3); // fetch, new-message event, reaction event
      check(notifiedCount2).equals(3); // fetch, new-message event, reaction event

      check(model1.messages.last)
        ..identicalTo(model2.messages.last)
        ..reactions.isNotNull().total.equals(1);
    });

    Future<void> checkApplied({
      required Event Function(Message) mkEvent,
      required void Function(Subject<Message>) doCheckMessageAfterFetch,
    }) async {
      final stream = eg.stream();
      store = eg.store();
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream));
      connection = store.connection as FakeApiConnection;

      final message = eg.streamMessage(stream: stream);

      await store.addMessage(Message.fromJson(message.toJson()));
      await store.handleEvent(mkEvent(message));

      // init msglist *after* event was handled
      model = MessageListView.init(store: store, narrow: const CombinedFeedNarrow());
      checkInvariants(model);

      connection.prepare(json:
        newestResult(foundOldest: false, messages: [message]).toJson());
      await model.fetchInitial();
      checkInvariants(model);
      doCheckMessageAfterFetch(
        check(model).messages.single
          ..id.equals(message.id)
      );
    }

    test('ReactionEvent is applied even when message not in any msglists', () async {
      await checkApplied(
        mkEvent: (message) =>
          eg.reactionEvent(eg.unicodeEmojiReaction, ReactionOp.add, message.id),
        doCheckMessageAfterFetch:
          (messageSubject) => messageSubject.reactions.isNotNull().total.equals(1),
      );
    });

    test('UpdateMessageEvent (edit) is applied even when message not in any msglists', () async {
      await checkApplied(
        mkEvent: (message) {
          final newContent = '${message.content}<p>edited</p>';
          return eg.updateMessageEditEvent(message,
            renderedContent: newContent);
        },
        doCheckMessageAfterFetch:
          (messageSubject) => messageSubject.content.endsWith('<p>edited</p>'),
      );
    });

    test('UpdateMessageFlagsEvent is applied even when message not in any msglists', () async {
      await checkApplied(
        mkEvent: (message) => UpdateMessageFlagsAddEvent(
          id: 1,
          flag: MessageFlag.starred,
          messages: [message.id],
          all: false,
        ),
        doCheckMessageAfterFetch:
          (messageSubject) => messageSubject.flags.contains(MessageFlag.starred),
      );
    });
  });

  test('reassemble', () async {
    final stream = eg.stream();
    await prepare(narrow: ChannelNarrow(stream.streamId));
    await prepareMessages(foundOldest: true, messages:
      List.generate(30, (i) => eg.streamMessage(stream: stream)));
    await store.handleEvent(MessageEvent(id: 0,
      message: eg.streamMessage(stream: stream)));
    checkNotifiedOnce();
    check(model).messages.length.equals(31);

    // Mess with model.contents, to simulate it having come from
    // a previous version of the code.
    final correctContent = parseContent(model.messages[0].content);
    model.contents[0] = const ZulipContent(nodes: [
      ParagraphNode(links: null, nodes: [TextNode('something outdated')])
    ]);
    check(model.contents[0]).not((it) => it.equalsNode(correctContent));

    model.reassemble();
    checkNotifiedOnce();
    check(model).messages.length.equals(31);
    check(model.contents[0]).equalsNode(correctContent);
  });

  group('stream/topic muting', () {
    test('in CombinedFeedNarrow', () async {
      final stream1 = eg.stream();
      final stream2 = eg.stream();
      await prepare(narrow: const CombinedFeedNarrow());
      await store.addStreams([stream1, stream2]);
      await store.addSubscription(eg.subscription(stream1));
      await store.addUserTopic(stream1, 'B', UserTopicVisibilityPolicy.muted);
      await store.addSubscription(eg.subscription(stream2, isMuted: true));
      await store.addUserTopic(stream2, 'C', UserTopicVisibilityPolicy.unmuted);

      // Check filtering on fetchInitial…
      await prepareMessages(foundOldest: false, messages: [
        eg.streamMessage(id: 201, stream: stream1, topic: 'A'),
        eg.streamMessage(id: 202, stream: stream1, topic: 'B'),
        eg.streamMessage(id: 203, stream: stream2, topic: 'C'),
        eg.streamMessage(id: 204, stream: stream2, topic: 'D'),
        eg.dmMessage(    id: 205, from: eg.otherUser, to: [eg.selfUser]),
      ]);
      final expected = <int>[];
      check(model.messages.map((m) => m.id))
        .deepEquals(expected..addAll([201, 203, 205]));

      // … and on fetchOlder…
      connection.prepare(json: olderResult(
        anchor: 201, foundOldest: true, messages: [
          eg.streamMessage(id: 101, stream: stream1, topic: 'A'),
          eg.streamMessage(id: 102, stream: stream1, topic: 'B'),
          eg.streamMessage(id: 103, stream: stream2, topic: 'C'),
          eg.streamMessage(id: 104, stream: stream2, topic: 'D'),
          eg.dmMessage(    id: 105, from: eg.otherUser, to: [eg.selfUser]),
        ]).toJson());
      await model.fetchOlder();
      checkNotified(count: 2);
      check(model.messages.map((m) => m.id))
        .deepEquals(expected..insertAll(0, [101, 103, 105]));

      // … and on MessageEvent.
      await store.handleEvent(MessageEvent(id: 0,
        message: eg.streamMessage(id: 301, stream: stream1, topic: 'A')));
      checkNotifiedOnce();
      check(model.messages.map((m) => m.id)).deepEquals(expected..add(301));

      await store.handleEvent(MessageEvent(id: 0,
        message: eg.streamMessage(id: 302, stream: stream1, topic: 'B')));
      checkNotNotified();
      check(model.messages.map((m) => m.id)).deepEquals(expected);

      await store.handleEvent(MessageEvent(id: 0,
        message: eg.streamMessage(id: 303, stream: stream2, topic: 'C')));
      checkNotifiedOnce();
      check(model.messages.map((m) => m.id)).deepEquals(expected..add(303));

      await store.handleEvent(MessageEvent(id: 0,
        message: eg.streamMessage(id: 304, stream: stream2, topic: 'D')));
      checkNotNotified();
      check(model.messages.map((m) => m.id)).deepEquals(expected);

      await store.handleEvent(MessageEvent(id: 0,
        message: eg.dmMessage(id: 305, from: eg.otherUser, to: [eg.selfUser])));
      checkNotifiedOnce();
      check(model.messages.map((m) => m.id)).deepEquals(expected..add(305));
    });

    test('in ChannelNarrow', () async {
      final stream = eg.stream();
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream, isMuted: true));
      await store.addUserTopic(stream, 'A', UserTopicVisibilityPolicy.unmuted);
      await store.addUserTopic(stream, 'C', UserTopicVisibilityPolicy.muted);

      // Check filtering on fetchInitial…
      await prepareMessages(foundOldest: false, messages: [
        eg.streamMessage(id: 201, stream: stream, topic: 'A'),
        eg.streamMessage(id: 202, stream: stream, topic: 'B'),
        eg.streamMessage(id: 203, stream: stream, topic: 'C'),
      ]);
      final expected = <int>[];
      check(model.messages.map((m) => m.id))
        .deepEquals(expected..addAll([201, 202]));

      // … and on fetchOlder…
      connection.prepare(json: olderResult(
        anchor: 201, foundOldest: true, messages: [
          eg.streamMessage(id: 101, stream: stream, topic: 'A'),
          eg.streamMessage(id: 102, stream: stream, topic: 'B'),
          eg.streamMessage(id: 103, stream: stream, topic: 'C'),
        ]).toJson());
      await model.fetchOlder();
      checkNotified(count: 2);
      check(model.messages.map((m) => m.id))
        .deepEquals(expected..insertAll(0, [101, 102]));

      // … and on MessageEvent.
      await store.handleEvent(MessageEvent(id: 0,
        message: eg.streamMessage(id: 301, stream: stream, topic: 'A')));
      checkNotifiedOnce();
      check(model.messages.map((m) => m.id)).deepEquals(expected..add(301));

      await store.handleEvent(MessageEvent(id: 0,
        message: eg.streamMessage(id: 302, stream: stream, topic: 'B')));
      checkNotifiedOnce();
      check(model.messages.map((m) => m.id)).deepEquals(expected..add(302));

      await store.handleEvent(MessageEvent(id: 0,
        message: eg.streamMessage(id: 303, stream: stream, topic: 'C')));
      checkNotNotified();
      check(model.messages.map((m) => m.id)).deepEquals(expected);
    });

    test('in TopicNarrow', () async {
      final stream = eg.stream();
      await prepare(narrow: TopicNarrow(stream.streamId, 'A'));
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream, isMuted: true));
      await store.addUserTopic(stream, 'A', UserTopicVisibilityPolicy.muted);

      // Check filtering on fetchInitial…
      await prepareMessages(foundOldest: false, messages: [
        eg.streamMessage(id: 201, stream: stream, topic: 'A'),
      ]);
      final expected = <int>[];
      check(model.messages.map((m) => m.id))
        .deepEquals(expected..addAll([201]));

      // … and on fetchOlder…
      connection.prepare(json: olderResult(
        anchor: 201, foundOldest: true, messages: [
          eg.streamMessage(id: 101, stream: stream, topic: 'A'),
        ]).toJson());
      await model.fetchOlder();
      checkNotified(count: 2);
      check(model.messages.map((m) => m.id))
        .deepEquals(expected..insertAll(0, [101]));

      // … and on MessageEvent.
      await store.handleEvent(MessageEvent(id: 0,
        message: eg.streamMessage(id: 301, stream: stream, topic: 'A')));
      checkNotifiedOnce();
      check(model.messages.map((m) => m.id)).deepEquals(expected..add(301));
    });

    test('in MentionsNarrow', () async {
      final stream = eg.stream();
      const mutedTopic = 'muted';
      await prepare(narrow: const MentionsNarrow());
      await store.addStream(stream);
      await store.addUserTopic(stream, mutedTopic, UserTopicVisibilityPolicy.muted);
      await store.addSubscription(eg.subscription(stream, isMuted: true));

      List<Message> getMessages(int startingId) => [
        eg.streamMessage(id: startingId,
          stream: stream, topic: mutedTopic, flags: [MessageFlag.wildcardMentioned]),
        eg.streamMessage(id: startingId + 1,
          stream: stream, topic: mutedTopic, flags: [MessageFlag.mentioned]),
        eg.dmMessage(id: startingId + 2,
          from: eg.otherUser, to: [eg.selfUser], flags: [MessageFlag.mentioned]),
      ];

      // Check filtering on fetchInitial…
      await prepareMessages(foundOldest: false, messages: getMessages(201));
      final expected = <int>[];
      check(model.messages.map((m) => m.id))
        .deepEquals(expected..addAll([201, 202, 203]));

      // … and on fetchOlder…
      connection.prepare(json: olderResult(
        anchor: 201, foundOldest: true, messages: getMessages(101)).toJson());
      await model.fetchOlder();
      checkNotified(count: 2);
      check(model.messages.map((m) => m.id))
        .deepEquals(expected..insertAll(0, [101, 102, 103]));

      // … and on MessageEvent.
      final messages = getMessages(301);
      for (var i = 0; i < 3; i += 1) {
        await store.handleEvent(MessageEvent(id: 0, message: messages[i]));
        checkNotifiedOnce();
        check(model.messages.map((m) => m.id)).deepEquals(expected..add(301 + i));
      }
    });
  });

  test('recipient headers are maintained consistently', () async {
    // TODO test date separators are maintained consistently too
    // This tests the code that maintains the invariant that recipient headers
    // are present just where they're required.
    // In [checkInvariants] we check the current state against that invariant,
    // so here we just need to exercise that code through all the relevant cases.
    // Each [checkNotifiedOnce] call ensures there's been a [checkInvariants] call
    // (in the listener that increments [notifiedCount]).
    //
    // A separate unit test covers [haveSameRecipient] itself.  So this test
    // just needs messages that have the same recipient, and that don't, and
    // doesn't need to exercise the different reasons that messages don't.

    const timestamp = 1693602618;
    final stream = eg.stream(streamId: eg.defaultStreamMessageStreamId);
    Message streamMessage(int id) =>
      eg.streamMessage(id: id, stream: stream, topic: 'foo', timestamp: timestamp);
    Message dmMessage(int id) =>
      eg.dmMessage(id: id, from: eg.selfUser, to: [], timestamp: timestamp);

    // First, test fetchInitial, where some headers are needed and others not.
    await prepare();
    connection.prepare(json: newestResult(
      foundOldest: false,
      messages: [streamMessage(10), streamMessage(11), dmMessage(12)],
    ).toJson());
    await model.fetchInitial();
    checkNotifiedOnce();

    // Then fetchOlder, where a header is needed in between…
    connection.prepare(json: olderResult(
      anchor: model.messages[0].id,
      foundOldest: false,
      messages: [streamMessage(7), streamMessage(8), dmMessage(9)],
    ).toJson());
    await model.fetchOlder();
    checkNotified(count: 2);

    //  … and fetchOlder where there's no header in between.
    connection.prepare(json: olderResult(
      anchor: model.messages[0].id,
      foundOldest: false,
      messages: [streamMessage(6)],
    ).toJson());
    await model.fetchOlder();
    checkNotified(count: 2);

    // Then test MessageEvent, where a new header is needed…
    await store.handleEvent(MessageEvent(id: 0, message: streamMessage(13)));
    checkNotifiedOnce();

    // … and where it's not.
    await store.handleEvent(MessageEvent(id: 0, message: streamMessage(14)));
    checkNotifiedOnce();

    // Then test UpdateMessageEvent edits, where a header is and remains needed…
    UpdateMessageEvent updateEvent(Message message) => eg.updateMessageEditEvent(
      message, renderedContent: '${message.content}<p>edited</p>',
    );
    await store.handleEvent(updateEvent(model.messages.first));
    checkNotifiedOnce();
    await store.handleEvent(updateEvent(model.messages[model.messages.length - 2]));
    checkNotifiedOnce();

    // … and where it's not.
    await store.handleEvent(updateEvent(model.messages.last));
    checkNotifiedOnce();

    // Then test reassemble.
    model.reassemble();
    checkNotifiedOnce();

    // Have a new fetchOlder reach the oldest, so that a history-start marker appears…
    connection.prepare(json: olderResult(
      anchor: model.messages[0].id,
      foundOldest: true,
      messages: [streamMessage(5)],
    ).toJson());
    await model.fetchOlder();
    checkNotified(count: 2);

    // … and then test reassemble again.
    model.reassemble();
    checkNotifiedOnce();
  });

  test('showSender is maintained correctly', () async {
    // TODO(#150): This will get more complicated with message moves.
    // Until then, we always compute this sequentially from oldest to newest.
    // So we just need to exercise the different cases of the logic for
    // whether the sender should be shown, but the difference between
    // fetchInitial and handleMessageEvent etc. doesn't matter.

    const t1 = 1693602618;
    const t2 = t1 + 86400;
    final stream = eg.stream(streamId: eg.defaultStreamMessageStreamId);
    Message streamMessage(int id, int timestamp, User sender) =>
      eg.streamMessage(id: id, sender: sender,
        stream: stream, topic: 'foo', timestamp: timestamp);
    Message dmMessage(int id, int timestamp, User sender) =>
      eg.dmMessage(id: id, from: sender, timestamp: timestamp,
        to: [sender.userId == eg.selfUser.userId ? eg.otherUser : eg.selfUser]);

    await prepare();
    await prepareMessages(foundOldest: true, messages: [
      streamMessage(1, t1, eg.selfUser),  // first message, so show sender
      streamMessage(2, t1, eg.selfUser),  // hide sender
      streamMessage(3, t1, eg.otherUser), // no recipient header, but new sender
      dmMessage(4,     t1, eg.otherUser), // same sender, but new recipient
      dmMessage(5,     t2, eg.otherUser), // same sender/recipient, but new day
    ]);

    // We check showSender has the right values in [checkInvariants],
    // but to make this test explicit:
    check(model.items).deepEquals(<void Function(Subject<Object?>)>[
      (it) => it.isA<MessageListHistoryStartItem>(),
      (it) => it.isA<MessageListRecipientHeaderItem>(),
      (it) => it.isA<MessageListMessageItem>().showSender.isTrue(),
      (it) => it.isA<MessageListMessageItem>().showSender.isFalse(),
      (it) => it.isA<MessageListMessageItem>().showSender.isTrue(),
      (it) => it.isA<MessageListRecipientHeaderItem>(),
      (it) => it.isA<MessageListMessageItem>().showSender.isTrue(),
      (it) => it.isA<MessageListDateSeparatorItem>(),
      (it) => it.isA<MessageListMessageItem>().showSender.isTrue(),
    ]);
  });

  group('haveSameRecipient', () {
    test('stream messages vs DMs, no match', () {
      final dmMessage = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]);
      final streamMessage = eg.streamMessage();
      check(haveSameRecipient(streamMessage, dmMessage)).isFalse();
      check(haveSameRecipient(dmMessage, streamMessage)).isFalse();
    });

    test('stream messages match just if same stream/topic', () {
      final stream0 = eg.stream();
      final stream1 = eg.stream();
      final messageAB = eg.streamMessage(stream: stream0, topic: 'foo');
      final messageXB = eg.streamMessage(stream: stream1, topic: 'foo');
      final messageAX = eg.streamMessage(stream: stream0, topic: 'bar');
      check(haveSameRecipient(messageAB, messageAB)).isTrue();
      check(haveSameRecipient(messageAB, messageXB)).isFalse();
      check(haveSameRecipient(messageXB, messageAB)).isFalse();
      check(haveSameRecipient(messageAB, messageAX)).isFalse();
      check(haveSameRecipient(messageAX, messageAB)).isFalse();
      check(haveSameRecipient(messageAX, messageXB)).isFalse();
      check(haveSameRecipient(messageXB, messageAX)).isFalse();
    });

    test('DMs match just if same recipients', () {
      final message0 = eg.dmMessage(from: eg.selfUser, to: []);
      final message01 = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]);
      final message10 = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]);
      final message02 = eg.dmMessage(from: eg.selfUser, to: [eg.thirdUser]);
      final message20 = eg.dmMessage(from: eg.thirdUser, to: [eg.selfUser]);
      final message012 = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser, eg.thirdUser]);
      final message102 = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser, eg.thirdUser]);
      final message201 = eg.dmMessage(from: eg.thirdUser, to: [eg.selfUser, eg.otherUser]);
      final groups = [[message0], [message01, message10],
        [message02, message20], [message012, message102, message201]];
      for (int i0 = 0; i0 < groups.length; i0++) {
        for (int i1 = 0; i1 < groups.length; i1++) {
          for (int j0 = 0; j0 < groups[i0].length; j0++) {
            for (int j1 = 0; j1 < groups[i1].length; j1++) {
              final message0 = groups[i0][j0];
              final message1 = groups[i1][j1];
              check(
                because: 'recipients ${message0.allRecipientIds} vs ${message1.allRecipientIds}',
                haveSameRecipient(message0, message1),
              ).equals(i0 == i1);
            }
          }
        }
      }
    });
  });

  test('messagesSameDay', () {
    // These timestamps will differ depending on the timezone of the
    // environment where the tests are run, in order to give the same results
    // in the code under test which is also based on the ambient timezone.
    // TODO(dart): It'd be great if tests could control the ambient timezone,
    //   so as to exercise cases like where local time falls back across midnight.
    int timestampFromLocalTime(String date) => DateTime.parse(date).millisecondsSinceEpoch ~/ 1000;

    const t111a = '2021-01-01 00:00:00';
    const t111b = '2021-01-01 12:00:00';
    const t111c = '2021-01-01 23:59:58';
    const t111d = '2021-01-01 23:59:59';
    const t112a = '2021-01-02 00:00:00';
    const t112b = '2021-01-02 00:00:01';
    const t121 = '2021-02-01 00:00:00';
    const t211 = '2022-01-01 00:00:00';
    final groups = [[t111a, t111b, t111c, t111d], [t112a, t112b], [t121], [t211]];

    final stream = eg.stream();
    for (int i0 = 0; i0 < groups.length; i0++) {
      for (int i1 = i0; i1 < groups.length; i1++) {
        for (int j0 = 0; j0 < groups[i0].length; j0++) {
          for (int j1 = (i0 == i1) ? j0 : 0; j1 < groups[i1].length; j1++) {
            final time0 = groups[i0][j0];
            final time1 = groups[i1][j1];
            check(because: 'times $time0, $time1', messagesSameDay(
              eg.streamMessage(stream: stream, topic: 'foo', timestamp: timestampFromLocalTime(time0)),
              eg.streamMessage(stream: stream, topic: 'foo', timestamp: timestampFromLocalTime(time1)),
            )).equals(i0 == i1);
            check(because: 'times $time0, $time1', messagesSameDay(
              eg.dmMessage(from: eg.selfUser, to: [], timestamp: timestampFromLocalTime(time0)),
              eg.dmMessage(from: eg.selfUser, to: [], timestamp: timestampFromLocalTime(time1)),
            )).equals(i0 == i1);
          }
        }
      }
    }
  });
}

void checkInvariants(MessageListView model) {
  if (!model.fetched) {
    check(model)
      ..messages.isEmpty()
      ..haveOldest.isFalse()
      ..fetchingOlder.isFalse();
  }
  if (model.haveOldest) {
    check(model).fetchingOlder.isFalse();
  }

  for (final message in model.messages) {
    check(model.store.messages)[message.id].isNotNull().identicalTo(message);
    check(model.narrow.containsMessage(message)).isTrue();

    if (message is! StreamMessage) continue;
    switch (model.narrow) {
      case CombinedFeedNarrow():
        check(model.store.isTopicVisible(message.streamId, message.topic))
          .isTrue();
      case ChannelNarrow():
        check(model.store.isTopicVisibleInStream(message.streamId, message.topic))
          .isTrue();
      case TopicNarrow():
      case DmNarrow():
      case MentionsNarrow():
    }
  }

  check(isSortedWithoutDuplicates(model.messages.map((m) => m.id).toList()))
    .isTrue();

  check(model).contents.length.equals(model.messages.length);
  for (int i = 0; i < model.contents.length; i++) {
    check(model.contents[i])
      .equalsNode(parseContent(model.messages[i].content));
  }

  int i = 0;
  if (model.haveOldest) {
    check(model.items[i++]).isA<MessageListHistoryStartItem>();
  }
  if (model.fetchingOlder) {
    check(model.items[i++]).isA<MessageListLoadingItem>();
  }
  for (int j = 0; j < model.messages.length; j++) {
    bool forcedShowSender = false;
    if (j == 0
        || !haveSameRecipient(model.messages[j-1], model.messages[j])) {
      check(model.items[i++]).isA<MessageListRecipientHeaderItem>()
        .message.identicalTo(model.messages[j]);
      forcedShowSender = true;
    } else if (!messagesSameDay(model.messages[j-1], model.messages[j])) {
      check(model.items[i++]).isA<MessageListDateSeparatorItem>()
        .message.identicalTo(model.messages[j]);
      forcedShowSender = true;
    }
    check(model.items[i++]).isA<MessageListMessageItem>()
      ..message.identicalTo(model.messages[j])
      ..content.identicalTo(model.contents[j])
      ..showSender.equals(
        forcedShowSender || model.messages[j].senderId != model.messages[j-1].senderId)
      ..isLastInBlock.equals(
        i == model.items.length || switch (model.items[i]) {
          MessageListMessageItem()
          || MessageListDateSeparatorItem() => false,
          MessageListRecipientHeaderItem()
          || MessageListHistoryStartItem()
          || MessageListLoadingItem()       => true,
        });
  }
  check(model.items).length.equals(i);
}

extension MessageListRecipientHeaderItemChecks on Subject<MessageListRecipientHeaderItem> {
  Subject<Message> get message => has((x) => x.message, 'message');
}

extension MessageListDateSeparatorItemChecks on Subject<MessageListDateSeparatorItem> {
  Subject<Message> get message => has((x) => x.message, 'message');
}

extension MessageListMessageItemChecks on Subject<MessageListMessageItem> {
  Subject<Message> get message => has((x) => x.message, 'message');
  Subject<ZulipContent> get content => has((x) => x.content, 'content');
  Subject<bool> get showSender => has((x) => x.showSender, 'showSender');
  Subject<bool> get isLastInBlock => has((x) => x.isLastInBlock, 'isLastInBlock');
}

extension MessageListViewChecks on Subject<MessageListView> {
  Subject<PerAccountStore> get store => has((x) => x.store, 'store');
  Subject<Narrow> get narrow => has((x) => x.narrow, 'narrow');
  Subject<List<Message>> get messages => has((x) => x.messages, 'messages');
  Subject<List<ZulipContent>> get contents => has((x) => x.contents, 'contents');
  Subject<List<MessageListItem>> get items => has((x) => x.items, 'items');
  Subject<bool> get fetched => has((x) => x.fetched, 'fetched');
  Subject<bool> get haveOldest => has((x) => x.haveOldest, 'haveOldest');
  Subject<bool> get fetchingOlder => has((x) => x.fetchingOlder, 'fetchingOlder');
}

/// A GetMessagesResult the server might return on an `anchor=newest` request.
GetMessagesResult newestResult({
  required bool foundOldest,
  bool historyLimited = false,
  required List<Message> messages,
}) {
  return GetMessagesResult(
    // These anchor, foundAnchor, and foundNewest values are what the server
    // appears to always return when the request had `anchor=newest`.
    anchor: 10000000000000000, // that's 16 zeros
    foundAnchor: false,
    foundNewest: true,

    foundOldest: foundOldest,
    historyLimited: historyLimited,
    messages: messages,
  );
}

/// A GetMessagesResult the server might return when we request older messages.
GetMessagesResult olderResult({
  required int anchor,
  bool foundAnchor = false, // the value if the server understood includeAnchor false
  required bool foundOldest,
  bool historyLimited = false,
  required List<Message> messages,
}) {
  return GetMessagesResult(
    anchor: anchor,
    foundAnchor: foundAnchor,
    foundNewest: false, // empirically always this, even when anchor happens to be latest
    foundOldest: foundOldest,
    historyLimited: historyLimited,
    messages: messages,
  );
}
