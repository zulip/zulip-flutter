import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:clock/clock.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/backoff.dart';
import 'package:zulip/api/exception.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/narrow.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/algorithms.dart';
import 'package:zulip/model/content.dart';
import 'package:zulip/model/message.dart';
import 'package:zulip/model/message_list.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';

import '../api/fake_api.dart';
import '../api/model/model_checks.dart';
import '../example_data.dart' as eg;
import '../fake_async.dart';
import '../stdlib_checks.dart';
import 'binding.dart';
import 'content_checks.dart';
import 'message_checks.dart';
import 'recent_senders_test.dart' as recent_senders_test;
import 'test_store.dart';

const newestResult = eg.newestGetMessagesResult;
const nearResult = eg.nearGetMessagesResult;
const olderResult = eg.olderGetMessagesResult;
const newerResult = eg.newerGetMessagesResult;

void main() {
  // Arrange for errors caught within the Flutter framework to be printed
  // unconditionally, rather than throttled as they normally are in an app.
  //
  // When using `testWidgets` from flutter_test, this is done automatically;
  // compare the [FlutterError.dumpErrorToConsole] call sites,
  // and [FlutterError.onError=] and [debugPrint=] call sites, in flutter_test.
  //
  // This test file is unusual in needing this manual arrangement; it's needed
  // because these aren't widget tests, and yet do have some failures arise as
  // exceptions that get caught by the framework: namely, when [checkInvariants]
  // throws from within an `addListener` callback.  Those exceptions get caught
  // by [ChangeNotifier.notifyListeners] and reported there through
  // [FlutterError.reportError].
  debugPrint = debugPrintSynchronously;
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details, forceReport: true);
  };

  TestZulipBinding.ensureInitialized();

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
  Future<void> prepare({
    Narrow narrow = const CombinedFeedNarrow(),
    Anchor anchor = AnchorCode.newest,
    ZulipStream? stream,
    List<User>? users,
    List<int>? mutedUserIds,
  }) async {
    stream ??= eg.stream(streamId: eg.defaultStreamMessageStreamId);
    subscription = eg.subscription(stream);
    store = eg.store();
    await store.addStream(stream);
    await store.addSubscription(subscription);
    await store.addUsers([...?users, eg.selfUser]);
    if (mutedUserIds != null) {
      await store.setMutedUsers(mutedUserIds);
    }
    connection = store.connection as FakeApiConnection;
    notifiedCount = 0;
    model = MessageListView.init(store: store, narrow: narrow, anchor: anchor)
      ..addListener(() {
        checkInvariants(model);
        notifiedCount++;
      });
    check(model).initialFetched.isFalse();
    checkNotNotified();
  }

  /// Perform the initial message fetch for [model].
  ///
  /// The test case must have already called [prepare] to initialize the state.
  Future<void> prepareMessages({
    bool? foundOldest,
    bool? foundNewest,
    int? anchorMessageId,
    required List<Message> messages,
  }) async {
    final result = eg.getMessagesResult(
      anchor: model.anchor == AnchorCode.firstUnread
        ? NumericAnchor(anchorMessageId!) : model.anchor,
      foundOldest: foundOldest,
      foundNewest: foundNewest,
      messages: messages);
    connection.prepare(json: result.toJson());
    await model.fetchInitial();
    checkNotifiedOnce();
  }

  Future<void> prepareOutboxMessages({
    required int count,
    required ZulipStream stream,
    String topic = 'some topic',
  }) async {
    for (int i = 0; i < count; i++) {
      connection.prepare(json: SendMessageResult(id: 123).toJson());
      await store.sendMessage(
        destination: StreamDestination(stream.streamId, eg.t(topic)),
        content: 'content');
    }
  }

  Future<void> prepareOutboxMessagesTo(List<MessageDestination> destinations) async {
    for (final destination in destinations) {
      connection.prepare(json: SendMessageResult(id: 123).toJson());
      await store.sendMessage(destination: destination, content: 'content');
    }
  }

  void checkLastRequest({
    required ApiNarrow narrow,
    required String anchor,
    bool? includeAnchor,
    required int numBefore,
    required int numAfter,
    required bool allowEmptyTopicName,
  }) {
    check(connection.lastRequest).isA<http.Request>()
      ..method.equals('GET')
      ..url.path.equals('/api/v1/messages')
      ..url.queryParameters.deepEquals({
        'narrow': jsonEncode(resolveApiNarrowForServer(narrow, connection.zulipFeatureLevel!)),
        'anchor': anchor,
        if (includeAnchor != null) 'include_anchor': includeAnchor.toString(),
        'num_before': numBefore.toString(),
        'num_after': numAfter.toString(),
        'allow_empty_topic_name': allowEmptyTopicName.toString(),
      });
  }

  void checkHasMessageIds(Iterable<int> messageIds) {
    check(model.messages.map((m) => m.id)).deepEquals(messageIds);
  }

  void checkHasMessages(Iterable<Message> messages) {
    checkHasMessageIds(messages.map((e) => e.id));
  }

  group('fetchInitial', () {
    final someChannel = eg.stream();
    const someTopic = 'some topic';

    final otherChannel = eg.stream();
    const otherTopic = 'other topic';

    group('smoke', () {
      Future<void> smoke(
        Narrow narrow,
        Message Function(int i) generateMessages,
      ) async {
        await prepare(narrow: narrow);
        connection.prepare(json: newestResult(
          foundOldest: false,
          messages: List.generate(kMessageListFetchBatchSize, generateMessages),
        ).toJson());
        final fetchFuture = model.fetchInitial();
        check(model).initialFetched.isFalse();

        checkNotNotified();
        await fetchFuture;
        checkNotifiedOnce();
        check(model)
          ..messages.length.equals(kMessageListFetchBatchSize)
          ..haveOldest.isFalse()
          ..haveNewest.isTrue();
        checkLastRequest(
          narrow: narrow.apiEncode(),
          anchor: 'newest',
          numBefore: kMessageListFetchBatchSize,
          numAfter: kMessageListFetchBatchSize,
          allowEmptyTopicName: true,
        );
      }

      test('CombinedFeedNarrow', () async {
        await smoke(const CombinedFeedNarrow(), (i) => eg.streamMessage());
      });

      test('TopicNarrow', () async {
        await smoke(TopicNarrow(someChannel.streamId, eg.t(someTopic)),
          (i) => eg.streamMessage(stream: someChannel, topic: someTopic));
      });
    });

    test('short history', () async {
      await prepare();
      connection.prepare(json: newestResult(
        foundOldest: true,
        messages: List.generate(30, (i) => eg.streamMessage()),
      ).toJson());
      await model.fetchInitial();
      checkNotifiedOnce();
      check(model)
        ..messages.length.equals(30)
        ..haveOldest.isTrue()
        ..haveNewest.isTrue();
    });

    test('early in history', () async {
      await prepare(anchor: NumericAnchor(1000));
      connection.prepare(json: nearResult(
        anchor: 1000, foundOldest: true, foundNewest: false,
        messages: List.generate(111, (i) => eg.streamMessage(id: 990 + i)),
      ).toJson());
      await model.fetchInitial();
      checkNotifiedOnce();
      check(model)
        ..messages.length.equals(111)
        ..haveOldest.isTrue()
        ..haveNewest.isFalse();
    });

    test('no messages found', () async {
      await prepare();
      connection.prepare(json: newestResult(
        foundOldest: true,
        messages: [],
      ).toJson());
      await model.fetchInitial();
      checkNotifiedOnce();
      check(model)
        ..initialFetched.isTrue()
        ..messages.isEmpty()
        ..haveOldest.isTrue()
        ..haveNewest.isTrue();
    });

    group('sends proper anchor', () {
      Future<void> checkFetchWithAnchor(Anchor anchor) async {
        await prepare(anchor: anchor);
        // This prepared response isn't entirely realistic, depending on the anchor.
        // That's OK; these particular tests don't use the details of the response.
        connection.prepare(json:
          newestResult(foundOldest: true, messages: []).toJson());
        await model.fetchInitial();
        checkNotifiedOnce();
        check(connection.lastRequest).isA<http.Request>()
          .url.queryParameters['anchor']
            .equals(anchor.toJson());
      }

      test('oldest',      () => checkFetchWithAnchor(AnchorCode.oldest));
      test('firstUnread', () => checkFetchWithAnchor(AnchorCode.firstUnread));
      test('newest',      () => checkFetchWithAnchor(AnchorCode.newest));
      test('numeric',     () => checkFetchWithAnchor(NumericAnchor(12345)));
    });

    test('no messages found in fetch; outbox messages present', () => awaitFakeAsync((async) async {
      final stream = eg.stream();
      await prepare(
        narrow: eg.topicNarrow(stream.streamId, 'topic'), stream: stream);

      await prepareOutboxMessages(count: 1, stream: stream, topic: 'topic');
      async.elapse(kLocalEchoDebounceDuration);
      checkNotNotified();
      check(model)
        ..initialFetched.isFalse()
        ..outboxMessages.isEmpty();

      connection.prepare(
        json: newestResult(foundOldest: true, messages: []).toJson());
      await model.fetchInitial();
      checkNotifiedOnce();
      check(model)
        ..initialFetched.isTrue()
        ..outboxMessages.length.equals(1);
    }));

    test('some messages found in fetch; outbox messages present', () => awaitFakeAsync((async) async {
      final stream = eg.stream();
      await prepare(
        narrow: eg.topicNarrow(stream.streamId, 'topic'), stream: stream);

      await prepareOutboxMessages(count: 1, stream: stream, topic: 'topic');
      async.elapse(kLocalEchoDebounceDuration);
      checkNotNotified();
      check(model)
        ..initialFetched.isFalse()
        ..outboxMessages.isEmpty();

      connection.prepare(json: newestResult(foundOldest: true,
        messages: [eg.streamMessage(stream: stream, topic: 'topic')]).toJson());
      await model.fetchInitial();
      checkNotifiedOnce();
      check(model)
        ..initialFetched.isTrue()
        ..outboxMessages.length.equals(1);
    }));

    test('outbox messages not added until haveNewest', () => awaitFakeAsync((async) async {
      final stream = eg.stream();
      await prepare(
        narrow: eg.topicNarrow(stream.streamId, 'topic'),
        anchor: AnchorCode.firstUnread,
        stream: stream);

      await prepareOutboxMessages(count: 1, stream: stream, topic: 'topic');
      async.elapse(kLocalEchoDebounceDuration);
      checkNotNotified();
      check(model)..initialFetched.isFalse()..outboxMessages.isEmpty();

      final message = eg.streamMessage(stream: stream, topic: 'topic');
      connection.prepare(json: nearResult(
        anchor: message.id,
        foundOldest: true,
        foundNewest: false,
        messages: [message]).toJson());
      await model.fetchInitial();
      checkNotifiedOnce();
      check(model)..initialFetched.isTrue()..haveNewest.isFalse()..outboxMessages.isEmpty();

      connection.prepare(json: newerResult(anchor: message.id, foundNewest: true,
        messages: [eg.streamMessage(stream: stream, topic: 'topic')]).toJson());
      final fetchFuture = model.fetchNewer();
      checkNotifiedOnce();
      await fetchFuture;
      checkNotifiedOnce();
      check(model)..haveNewest.isTrue()..outboxMessages.length.equals(1);
    }));

    test('ignore [OutboxMessage]s outside narrow or with `hidden: true`', () => awaitFakeAsync((async) async {
      final stream = eg.stream();
      final otherStream = eg.stream();
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await store.setUserTopic(stream, 'muted', UserTopicVisibilityPolicy.muted);
      await prepareOutboxMessagesTo([
        StreamDestination(stream.streamId, eg.t('topic')),
        StreamDestination(stream.streamId, eg.t('muted')),
        StreamDestination(otherStream.streamId, eg.t('topic')),
      ]);
      async.elapse(kLocalEchoDebounceDuration);
      checkNotNotified();

      await prepareOutboxMessagesTo(
        [StreamDestination(stream.streamId, eg.t('topic'))]);
      assert(store.outboxMessages.values.last.hidden);

      connection.prepare(json:
        newestResult(foundOldest: true, messages: []).toJson());
      await model.fetchInitial();
      checkNotifiedOnce();
      check(model).outboxMessages.single.isA<StreamOutboxMessage>().conversation
        ..streamId.equals(stream.streamId)
        ..topic.equals(eg.t('topic'));
    }));

    // TODO(#824): move this test
    test('recent senders track all the messages', () async {
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

    group('topic permalinks', () {
      test('if redirect, we follow it and remove "with" element', () async {
        await prepare(narrow: TopicNarrow(someChannel.streamId, eg.t(someTopic), with_: 1));
        connection.prepare(json: newestResult(
          foundOldest: false,
          messages: [eg.streamMessage(id: 1, stream: otherChannel, topic: otherTopic)],
        ).toJson());
        await model.fetchInitial();
        checkNotifiedOnce();
        check(model).narrow
          .equals(TopicNarrow(otherChannel.streamId, eg.t(otherTopic)));
      });

      test('if no redirect, we still remove "with" element', () async {
        await prepare(narrow: TopicNarrow(someChannel.streamId, eg.t(someTopic), with_: 1));
        connection.prepare(json: newestResult(
          foundOldest: false,
          messages: [eg.streamMessage(id: 1, stream: someChannel, topic: someTopic)],
        ).toJson());
        await model.fetchInitial();
        checkNotifiedOnce();
        check(model).narrow
          .equals(TopicNarrow(someChannel.streamId, eg.t(someTopic)));
      });
    });
  });

  group('renarrowAndFetch', () {
    test('smoke', () => awaitFakeAsync((async) async {
      final channel = eg.stream();

      const narrow = CombinedFeedNarrow();
      await prepare(narrow: narrow, stream: channel);
      final messages = List.generate(100,
        (i) => eg.streamMessage(id: 1000 + i, stream: channel));
      await prepareMessages(foundOldest: false, messages: messages);

      // Start a fetchOlder, so we can check that renarrowAndFetch causes its
      // result to be discarded.
      connection.prepare(
        json: olderResult(
          anchor: 1000, foundOldest: false,
          messages: List.generate(100,
            (i) => eg.streamMessage(id: 900 + i, stream: channel)),
        ).toJson(),
        delay: Duration(milliseconds: 500),
      );
      unawaited(model.fetchOlder());
      checkNotifiedOnce();

      // Start the renarrowAndFetch.
      final newNarrow = ChannelNarrow(channel.streamId);
      final newAnchor = NumericAnchor(messages[3].id);

      final result = eg.getMessagesResult(
        anchor: newAnchor,
        foundOldest: false, foundNewest: false,
        messages: messages.sublist(3, 5));
      connection.prepare(json: result.toJson(), delay: Duration(seconds: 1));
      model.renarrowAndFetch(newNarrow, newAnchor);
      checkNotifiedOnce();
      check(model)
        ..initialFetched.isFalse()
        ..narrow.equals(newNarrow)
        ..anchor.equals(newAnchor)
        ..messages.isEmpty();

      // Elapse until the fetchOlder is done but renarrowAndFetch is still
      // pending; check that the list is still empty despite the fetchOlder.
      async.elapse(Duration(milliseconds: 750));
      check(model)
        ..initialFetched.isFalse()
        ..narrow.equals(newNarrow)
        ..messages.isEmpty();

      // Elapse until the renarrowAndFetch completes.
      async.elapse(Duration(seconds: 250));
      check(model)
        ..initialFetched.isTrue()
        ..narrow.equals(newNarrow)
        ..anchor.equals(newAnchor)
        ..messages.length.equals(2);
    }));
  });

  group('fetching more', () {
    test('fetchOlder smoke', () async {
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
      check(model).busyFetchingOlder.isTrue();

      await fetchFuture;
      checkNotifiedOnce();
      check(model)
        ..busyFetchingOlder.isFalse()
        ..messages.length.equals(200);
      checkLastRequest(
        narrow: narrow.apiEncode(),
        anchor: '1000',
        includeAnchor: false,
        numBefore: kMessageListFetchBatchSize,
        numAfter: 0,
        allowEmptyTopicName: true,
      );
    });

    test('fetchNewer smoke', () async {
      const narrow = CombinedFeedNarrow();
      await prepare(narrow: narrow, anchor: NumericAnchor(1000));
      await prepareMessages(foundOldest: true, foundNewest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 1000 + i)));

      connection.prepare(json: newerResult(
        anchor: 1099, foundNewest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 1100 + i)),
      ).toJson());
      final fetchFuture = model.fetchNewer();
      checkNotifiedOnce();
      check(model).busyFetchingNewer.isTrue();

      await fetchFuture;
      checkNotifiedOnce();
      check(model)
        ..busyFetchingNewer.isFalse()
        ..messages.length.equals(200);
      checkLastRequest(
        narrow: narrow.apiEncode(),
        anchor: '1099',
        includeAnchor: false,
        numBefore: 0,
        numAfter: kMessageListFetchBatchSize,
        allowEmptyTopicName: true,
      );
    });

    group('makes multiple requests', () {
      final mutedUser = eg.user();

      List<Message> streamMessages(int count, {required int fromId}) =>
        List.generate(count, (i) => eg.streamMessage(id: fromId + i));

      List<Message> mutedDmMessages(int count, {required int fromId}) =>
        List.generate(count, (i) => eg.dmMessage(id: fromId + i, from: eg.selfUser, to: [mutedUser]));

      group('until enough visible messages', () {
        // Enough visible messages are at least `kMessageListFetchBatchSize / 2`,
        // which in the time of writing this (2025-11), they are `100 / 2 = 50`.

        test('fetchOlder', () async {
          await prepare(users: [mutedUser], mutedUserIds: [mutedUser.userId]);
          await prepareMessages(foundOldest: false,
            messages: List.generate(100, (i) => eg.streamMessage(id: 1000 + i)));

          connection.prepare(json: olderResult(
            anchor: 1000, foundOldest: false,
            messages: streamMessages(30, fromId: 900) + mutedDmMessages(70, fromId: 930),
          ).toJson());
          final fetchFuture = model.fetchOlder();
          check(model).messages.length.equals(100);

          connection.prepare(json: olderResult(
            anchor: 900, foundOldest: false,
            messages: streamMessages(10, fromId: 800) + mutedDmMessages(90, fromId: 810),
          ).toJson());
          await Future(() {});
          check(model).messages.length.equals(130);

          connection.prepare(json: olderResult(
            anchor: 800, foundOldest: false,
            messages: streamMessages(9, fromId: 700) + mutedDmMessages(91, fromId: 709),
          ).toJson());
          await Future(() {});
          check(model).messages.length.equals(140);

          connection.prepare(json: olderResult(
            anchor: 800, foundOldest: false,
            messages: streamMessages(1, fromId: 600) + mutedDmMessages(99, fromId: 601),
          ).toJson());
          await Future(() {});
          check(model).messages.length.equals(149);

          await fetchFuture;
          check(model).messages.length.equals(150);
        });

        test('fetchNewer', () async {
          await prepare(anchor: AnchorCode.firstUnread,
            users: [mutedUser], mutedUserIds: [mutedUser.userId]);
          await prepareMessages(
            foundOldest: true, foundNewest: false,
            anchorMessageId: 950,
            messages: List.generate(100, (i) => eg.streamMessage(id: 900 + i)));

          connection.prepare(json: newerResult(
            anchor: 1000, foundNewest: false,
            messages: streamMessages(30, fromId: 1000) + mutedDmMessages(70, fromId: 1030),
          ).toJson());
          final fetchFuture = model.fetchNewer();
          check(model).messages.length.equals(100);

          connection.prepare(json: newerResult(
            anchor: 900, foundNewest: false,
            messages: streamMessages(10, fromId: 1100) + mutedDmMessages(90, fromId: 1110),
          ).toJson());
          await Future(() {});
          check(model).messages.length.equals(130);

          connection.prepare(json: newerResult(
            anchor: 800, foundNewest: false,
            messages: streamMessages(9, fromId: 1200) + mutedDmMessages(91, fromId: 1209),
          ).toJson());
          await Future(() {});
          check(model).messages.length.equals(140);

          connection.prepare(json: newerResult(
            anchor: 800, foundNewest: false,
            messages: streamMessages(1, fromId: 1300) + mutedDmMessages(99, fromId: 1301),
          ).toJson());
          await Future(() {});
          check(model).messages.length.equals(149);

          await fetchFuture;
          check(model).messages.length.equals(150);
        });
      });

      group('until haveOldest/haveNewest', () {
        test('fetchOlder', () async {
          await prepare(users: [mutedUser], mutedUserIds: [mutedUser.userId]);
          await prepareMessages(foundOldest: false,
            messages: List.generate(100, (i) => eg.streamMessage(id: 1000 + i)));

          connection.prepare(json: olderResult(
            anchor: 1000, foundOldest: false,
            messages: streamMessages(30, fromId: 900) + mutedDmMessages(70, fromId: 930),
          ).toJson());
          final fetchFuture = model.fetchOlder();
          check(model).messages.length.equals(100);

          connection.prepare(json: olderResult(
            anchor: 900, foundOldest: false,
            messages: streamMessages(10, fromId: 800) + mutedDmMessages(90, fromId: 810),
          ).toJson());
          await Future(() {});
          check(model).messages.length.equals(130);

          connection.prepare(json: olderResult(
            anchor: 800, foundOldest: true,
            messages: streamMessages(9, fromId: 700) + mutedDmMessages(91, fromId: 709),
          ).toJson());
          await Future(() {});
          check(model).messages.length.equals(140);

          await fetchFuture;
          check(model).haveOldest.isTrue();
          check(model).messages.length.equals(149);
        });

        test('fetchNewer', () async {
          await prepare(anchor: AnchorCode.firstUnread,
            users: [mutedUser], mutedUserIds: [mutedUser.userId]);
          await prepareMessages(
            foundOldest: true, foundNewest: false,
            anchorMessageId: 950,
            messages: List.generate(100, (i) => eg.streamMessage(id: 900 + i)));

          connection.prepare(json: newerResult(
            anchor: 1000, foundNewest: false,
            messages: streamMessages(30, fromId: 1000) + mutedDmMessages(70, fromId: 1030),
          ).toJson());
          final fetchFuture = model.fetchNewer();
          check(model).messages.length.equals(100);

          connection.prepare(json: newerResult(
            anchor: 900, foundNewest: false,
            messages: streamMessages(10, fromId: 1100) + mutedDmMessages(90, fromId: 1110),
          ).toJson());
          await Future(() {});
          check(model).messages.length.equals(130);

          connection.prepare(json: newerResult(
            anchor: 800, foundNewest: true,
            messages: streamMessages(9, fromId: 1200) + mutedDmMessages(91, fromId: 1209),
          ).toJson());
          await Future(() {});
          check(model).messages.length.equals(140);

          await fetchFuture;
          check(model).haveNewest.isTrue();
          check(model).messages.length.equals(149);
        });
      });
    });

    test('fetchOlder nop when already fetching older', () async {
      await prepare(anchor: NumericAnchor(1000));
      await prepareMessages(foundOldest: false, foundNewest: false,
        messages: List.generate(201, (i) => eg.streamMessage(id: 900 + i)));

      connection.prepare(json: olderResult(
        anchor: 900, foundOldest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 800 + i)),
      ).toJson());
      final fetchFuture = model.fetchOlder();
      checkNotifiedOnce();
      check(model).busyFetchingOlder.isTrue();

      // Don't prepare another response.
      final fetchFuture2 = model.fetchOlder();
      checkNotNotified();
      check(model)..busyFetchingOlder.isTrue()..messages.length.equals(201);

      await fetchFuture;
      await fetchFuture2;
      // We must not have made another request, because we didn't
      // prepare another response and didn't get an exception.
      checkNotifiedOnce();
      check(model)..busyFetchingOlder.isFalse()..messages.length.equals(301);
    });

    test('fetchNewer fetches when already fetching older', () async {
      await prepare(anchor: NumericAnchor(1000));
      await prepareMessages(foundOldest: false, foundNewest: false,
        messages: List.generate(201, (i) => eg.streamMessage(id: 900 + i)));

      connection.prepare(json: olderResult(
        anchor: 900, foundOldest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 800 + i)),
      ).toJson());
      final fetchFuture = model.fetchOlder();
      checkNotifiedOnce();
      check(model).busyFetchingOlder.isTrue();
      check(model).busyFetchingNewer.isFalse();

      connection.prepare(json: newerResult(
        anchor: 1100, foundNewest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 1101 + i)),
      ).toJson());
      final fetchFuture2 = model.fetchNewer();
      checkNotifiedOnce();
      check(model).busyFetchingOlder.isTrue();
      check(model).busyFetchingNewer.isTrue();
      check(model).messages.length.equals(201);

      await fetchFuture;
      await fetchFuture2;
      checkNotified(count: 2);
      check(model).busyFetchingOlder.isFalse();
      check(model).busyFetchingNewer.isFalse();
      check(model).messages.length.equals(401);
    });

    test('fetchNewer nop when already fetching newer', () async {
      await prepare(anchor: NumericAnchor(1000));
      await prepareMessages(foundOldest: false, foundNewest: false,
        messages: List.generate(201, (i) => eg.streamMessage(id: 900 + i)));

      connection.prepare(json: newerResult(
        anchor: 1100, foundNewest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 1101 + i)),
      ).toJson());
      final fetchFuture = model.fetchNewer();
      checkNotifiedOnce();
      check(model).busyFetchingNewer.isTrue();

      // Don't prepare another response.
      final fetchFuture2 = model.fetchNewer();
      checkNotNotified();
      check(model)..busyFetchingNewer.isTrue()..messages.length.equals(201);

      await fetchFuture;
      await fetchFuture2;
      // We must not have made another request, because we didn't
      // prepare another response and didn't get an exception.
      checkNotifiedOnce();
      check(model)..busyFetchingNewer.isFalse()..messages.length.equals(301);
    });

    test('fetchOlder fetches when already fetching newer', () async {
      await prepare(anchor: NumericAnchor(1000));
      await prepareMessages(foundOldest: false, foundNewest: false,
        messages: List.generate(201, (i) => eg.streamMessage(id: 900 + i)));

      connection.prepare(json: newerResult(
        anchor: 1100, foundNewest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 1101 + i)),
      ).toJson());
      final fetchFuture = model.fetchNewer();
      checkNotifiedOnce();
      check(model).busyFetchingNewer.isTrue();
      check(model).busyFetchingOlder.isFalse();

      connection.prepare(json: olderResult(
        anchor: 900, foundOldest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 800 + i)),
      ).toJson());
      final fetchFuture2 = model.fetchOlder();
      checkNotifiedOnce();
      check(model).busyFetchingNewer.isTrue();
      check(model).busyFetchingOlder.isTrue();
      check(model).messages.length.equals(201);

      await fetchFuture;
      await fetchFuture2;
      checkNotified(count: 2);
      check(model).busyFetchingNewer.isFalse();
      check(model).busyFetchingOlder.isFalse();
      check(model).messages.length.equals(401);
    });

    test('fetchOlder nop when already haveOldest true', () async {
      await prepare(anchor: NumericAnchor(1000));
      await prepareMessages(foundOldest: true, foundNewest: false, messages:
        List.generate(151, (i) => eg.streamMessage(id: 950 + i)));
      check(model)
        ..haveOldest.isTrue()
        ..messages.length.equals(151);

      await model.fetchOlder();
      // We must not have made a request, because we didn't
      // prepare a response and didn't get an exception.
      checkNotNotified();
      check(model)
        ..haveOldest.isTrue()
        ..messages.length.equals(151);
    });

    test('fetchNewer nop when already haveNewest true', () async {
      await prepare(anchor: NumericAnchor(1000));
      await prepareMessages(foundOldest: false, foundNewest: true, messages:
        List.generate(151, (i) => eg.streamMessage(id: 950 + i)));
      check(model)
        ..haveNewest.isTrue()
        ..messages.length.equals(151);

      await model.fetchNewer();
      // We must not have made a request, because we didn't
      // prepare a response and didn't get an exception.
      checkNotNotified();
      check(model)
        ..haveNewest.isTrue()
        ..messages.length.equals(151);
    });

    test('fetchOlder nop during fetchOlder backoff', () => awaitFakeAsync((async) async {
      final olderMessages = List.generate(50, (i) => eg.streamMessage());
      final initialMessages = List.generate(50, (i) => eg.streamMessage());
      await prepare(anchor: NumericAnchor(initialMessages[25].id));
      await prepareMessages(foundOldest: false, foundNewest: false,
        messages: initialMessages);
      check(connection.takeRequests()).single;

      connection.prepare(apiException: eg.apiBadRequest());
      check(async.pendingTimers).isEmpty();
      await check(model.fetchOlder()).throws<ZulipApiException>();
      checkNotified(count: 2);
      check(model).busyFetchingOlder.isTrue();
      check(connection.takeRequests()).single;

      await model.fetchOlder();
      checkNotNotified();
      check(model).busyFetchingOlder.isTrue();
      check(connection.lastRequest).isNull();

      // Wait long enough that a first backoff is sure to finish.
      async.elapse(const Duration(seconds: 1));
      check(model).busyFetchingOlder.isFalse();
      checkNotifiedOnce();
      check(connection.lastRequest).isNull();

      connection.prepare(json: olderResult(anchor: initialMessages.first.id,
        foundOldest: false, messages: olderMessages).toJson());
      await model.fetchOlder();
      checkNotified(count: 2);
      check(connection.takeRequests()).single;
    }));

    test('fetchNewer fetches during fetchOlder backoff', () => awaitFakeAsync((async) async {
      final initialMessages = List.generate(50, (i) => eg.streamMessage());
      final newerMessages = List.generate(50, (i) => eg.streamMessage());
      await prepare(anchor: NumericAnchor(initialMessages[25].id));
      await prepareMessages(foundOldest: false, foundNewest: false,
        messages: initialMessages);
      check(connection.takeRequests()).single;

      connection.prepare(apiException: eg.apiBadRequest());
      check(async.pendingTimers).isEmpty();
      await check(model.fetchOlder()).throws<ZulipApiException>();
      checkNotified(count: 2);
      check(model).busyFetchingOlder.isTrue();
      check(connection.takeRequests()).single;

      connection.prepare(json: newerResult(anchor: initialMessages.last.id,
        foundNewest: false, messages: newerMessages).toJson());
      final fetchNewerFuture = model.fetchNewer();
      check(model).busyFetchingOlder.isTrue();
      check(model).busyFetchingNewer.isTrue();
      await fetchNewerFuture;
      check(model).busyFetchingNewer.isFalse();
      checkNotified(count: 2);
      check(connection.takeRequests()).single;
    }));

    test('fetchNewer nop during fetchNewer backoff', () => awaitFakeAsync((async) async {
      final initialMessages = List.generate(50, (i) => eg.streamMessage());
      final newerMessages = List.generate(50, (i) => eg.streamMessage());
      await prepare(anchor: NumericAnchor(initialMessages[25].id));
      await prepareMessages(foundOldest: false, foundNewest: false,
        messages: initialMessages);
      check(connection.takeRequests()).single;

      connection.prepare(apiException: eg.apiBadRequest());
      check(async.pendingTimers).isEmpty();
      await check(model.fetchNewer()).throws<ZulipApiException>();
      checkNotified(count: 2);
      check(model).busyFetchingNewer.isTrue();
      check(connection.takeRequests()).single;

      await model.fetchNewer();
      checkNotNotified();
      check(model).busyFetchingNewer.isTrue();
      check(connection.lastRequest).isNull();

      // Wait long enough that a first backoff is sure to finish.
      async.elapse(const Duration(seconds: 1));
      check(model).busyFetchingNewer.isFalse();
      checkNotifiedOnce();
      check(connection.lastRequest).isNull();

      connection.prepare(json: newerResult(anchor: initialMessages.last.id,
        foundNewest: false, messages: newerMessages).toJson());
      await model.fetchNewer();
      checkNotified(count: 2);
      check(connection.takeRequests()).single;
    }));

    test('fetchOlder fetches during fetchNewer backoff', () => awaitFakeAsync((async) async {
      final olderMessages = List.generate(50, (i) => eg.streamMessage());
      final initialMessages = List.generate(50, (i) => eg.streamMessage());
      await prepare(anchor: NumericAnchor(initialMessages[25].id));
      await prepareMessages(foundOldest: false, foundNewest: false,
        messages: initialMessages);
      check(connection.takeRequests()).single;

      connection.prepare(apiException: eg.apiBadRequest());
      check(async.pendingTimers).isEmpty();
      await check(model.fetchNewer()).throws<ZulipApiException>();
      checkNotified(count: 2);
      check(model).busyFetchingNewer.isTrue();
      check(connection.takeRequests()).single;

      connection.prepare(json: olderResult(anchor: initialMessages.last.id,
        foundOldest: false, messages: olderMessages).toJson());
      final fetchOlderFuture = model.fetchOlder();
      check(model).busyFetchingNewer.isTrue();
      check(model).busyFetchingOlder.isTrue();
      await fetchOlderFuture;
      check(model).busyFetchingOlder.isFalse();
      checkNotified(count: 2);
      check(connection.takeRequests()).single;
    }));

    // TODO(#824): move this test
    test('fetchOlder recent senders track all the messages', () async {
      await prepare();
      final initialMessages = List.generate(50, (i) => eg.streamMessage(id: 100 + i));
      await prepareMessages(foundOldest: false, messages: initialMessages);

      final oldMessages = List.generate(50, (i) => eg.streamMessage(id: 49 + i))
        // Not subscribed to the stream with id 10.
        ..add(eg.streamMessage(id: 99, stream: eg.stream(streamId: 10)));
      connection.prepare(json: olderResult(
        anchor: 100, foundOldest: false,
        messages: oldMessages,
      ).toJson());
      await model.fetchOlder();

      check(model).messages.length.equals(100);
      recent_senders_test.checkMatchesMessages(store.recentSenders,
        [...initialMessages, ...oldMessages]);
    });

    // TODO(#824): move this test
    test('TODO fetchNewer recent senders track all the messages', () async {
      await prepare(anchor: NumericAnchor(100));
      final initialMessages = List.generate(50, (i) => eg.streamMessage(id: 100 + i));
      await prepareMessages(foundOldest: true, foundNewest: false,
        messages: initialMessages);

      final newMessages = List.generate(50, (i) => eg.streamMessage(id: 150 + i))
        // Not subscribed to the stream with id 10.
        ..add(eg.streamMessage(id: 200, stream: eg.stream(streamId: 10)));
      connection.prepare(json: newerResult(
        anchor: 100, foundNewest: false,
        messages: newMessages,
      ).toJson());
      await model.fetchNewer();

      check(model).messages.length.equals(100);
      recent_senders_test.checkMatchesMessages(store.recentSenders,
        [...initialMessages, ...newMessages]);
    });
  });

  group('oldMessageId, newMessageId', () {
    group('fetchInitial', () {
      test('visible messages', () async {
        await prepare();
        check(model)..oldMessageId.isNull()..newMessageId.isNull();

        connection.prepare(json: newestResult(
          foundOldest: true,
          messages: List.generate(100, (i) => eg.streamMessage(id: 100 + i)),
        ).toJson());
        await model.fetchInitial();

        checkNotifiedOnce();
        check(model)
          ..messages.length.equals(100)
          ..oldMessageId.equals(100)..newMessageId.equals(199);
      });

      test('invisible messages', () async {
        final mutedUser = eg.user();
        await prepare(users: [mutedUser], mutedUserIds: [mutedUser.userId]);
        check(model)..oldMessageId.isNull()..newMessageId.isNull();

        connection.prepare(json: newestResult(
          foundOldest: true,
          messages: List.generate(100,
            (i) => eg.dmMessage(id: 100 + i, from: eg.selfUser, to: [mutedUser])),
        ).toJson());
        await model.fetchInitial();

        checkNotifiedOnce();
        check(model)
          ..messages.isEmpty()
          ..oldMessageId.equals(100)..newMessageId.equals(199);
      });

      test('no messages found', () async {
        await prepare();
        check(model)..oldMessageId.isNull()..newMessageId.isNull();

        connection.prepare(json: newestResult(
          foundOldest: true,
          messages: [],
        ).toJson());
        await model.fetchInitial();

        checkNotifiedOnce();
        check(model)
          ..messages.isEmpty()
          ..oldMessageId.isNull()..newMessageId.isNull();
      });
    });

    group('fetching more', () {
      test('visible messages', () async {
        await prepare(anchor: AnchorCode.firstUnread);
        check(model)..oldMessageId.isNull()..newMessageId.isNull();

        await prepareMessages(
          foundOldest: false, foundNewest: false,
          anchorMessageId: 250,
          messages: List.generate(100, (i) => eg.streamMessage(id: 200 + i)));
        check(model)
          ..messages.length.equals(100)
          ..oldMessageId.equals(200)..newMessageId.equals(299);

        connection.prepare(json: olderResult(
          anchor: 200, foundOldest: true,
          messages: List.generate(100, (i) => eg.streamMessage(id: 100 + i)),
        ).toJson());
        await model.fetchOlder();
        checkNotified(count: 2);
        check(model)
          ..messages.length.equals(200)
          ..oldMessageId.equals(100)..newMessageId.equals(299);

        connection.prepare(json: newerResult(
          anchor: 299, foundNewest: true,
          messages: List.generate(100, (i) => eg.streamMessage(id: 300 + i)),
        ).toJson());
        await model.fetchNewer();
        checkNotified(count: 2);
        check(model)
          ..messages.length.equals(300)
          ..oldMessageId.equals(100)..newMessageId.equals(399);
      });

      test('invisible messages', () async {
        final mutedUser = eg.user();
        await prepare(anchor: AnchorCode.firstUnread,
          users: [mutedUser], mutedUserIds: [mutedUser.userId]);
        check(model)..oldMessageId.isNull()..newMessageId.isNull();

        await prepareMessages(
          foundOldest: false, foundNewest: false,
          anchorMessageId: 250,
          messages: List.generate(100, (i) => eg.streamMessage(id: 200 + i)));
        check(model)
          ..messages.length.equals(100)
          ..oldMessageId.equals(200)..newMessageId.equals(299);

        connection.prepare(json: olderResult(
          anchor: 200, foundOldest: true,
          messages: List.generate(100,
            (i) => eg.dmMessage(id: 100 + i, from: eg.selfUser, to: [mutedUser])),
        ).toJson());
        await model.fetchOlder();
        checkNotified(count: 2);
        check(model)
          ..messages.length.equals(100)
          ..oldMessageId.equals(100)..newMessageId.equals(299);

        connection.prepare(json: newerResult(
          anchor: 299, foundNewest: true,
          messages: List.generate(100,
            (i) => eg.dmMessage(id: 300 + i, from: eg.selfUser, to: [mutedUser])),
        ).toJson());
        await model.fetchNewer();
        checkNotified(count: 2);
        check(model)
          ..messages.length.equals(100)
          ..oldMessageId.equals(100)..newMessageId.equals(399);
      });
    });
  });

  // TODO(#1569): test jumpToEnd

  group('MessageEvent', () {
    test('in narrow', () async {
      final stream = eg.stream();
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await prepareMessages(foundOldest: true, messages:
        List.generate(30, (i) => eg.streamMessage(stream: stream)));

      check(model).messages.length.equals(30);
      await store.addMessage(eg.streamMessage(stream: stream));
      checkNotifiedOnce();
      check(model).messages.length.equals(31);
    });

    test('not in narrow', () async {
      final stream = eg.stream();
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await prepareMessages(foundOldest: true, messages:
        List.generate(30, (i) => eg.streamMessage(stream: stream)));

      check(model).messages.length.equals(30);
      final otherStream = eg.stream();
      await store.addMessage(eg.streamMessage(stream: otherStream));
      checkNotNotified();
      check(model).messages.length.equals(30);
    });

    test('while in mid-history', () async {
      final stream = eg.stream();
      await prepare(narrow: ChannelNarrow(stream.streamId),
        anchor: NumericAnchor(1000));
      await prepareMessages(foundOldest: true, foundNewest: false, messages:
        List.generate(30, (i) => eg.streamMessage(id: 1000 + i, stream: stream)));

      check(model).messages.length.equals(30);
      await store.addMessage(eg.streamMessage(stream: stream));
      checkNotNotified();
      check(model).messages.length.equals(30);
    });

    test('before fetch', () async {
      final stream = eg.stream();
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await store.addMessage(eg.streamMessage(stream: stream));
      checkNotNotified();
      check(model).initialFetched.isFalse();
    });

    test('when there are outbox messages', () => awaitFakeAsync((async) async {
      final stream = eg.stream();
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await prepareMessages(foundOldest: true, messages:
        List.generate(30, (i) => eg.streamMessage(stream: stream)));

      await prepareOutboxMessages(count: 5, stream: stream);
      async.elapse(kLocalEchoDebounceDuration);
      checkNotified(count: 5);
      check(model)
        ..messages.length.equals(30)
        ..outboxMessages.length.equals(5);

      await store.handleEvent(eg.messageEvent(eg.streamMessage(stream: stream)));
      checkNotifiedOnce();
      check(model)
        ..messages.length.equals(31)
        ..outboxMessages.length.equals(5);
    }));

    test('from another client (localMessageId present but unrecognized)', () => awaitFakeAsync((async) async {
      final stream = eg.stream();
      await prepare(narrow: eg.topicNarrow(stream.streamId, 'topic'));
      await prepareMessages(foundOldest: true, messages:
        List.generate(30, (i) => eg.streamMessage(stream: stream, topic: 'topic')));

      check(model)
        ..messages.length.equals(30)
        ..outboxMessages.isEmpty();

      await store.handleEvent(eg.messageEvent(
        eg.streamMessage(stream: stream, topic: 'topic'),
        localMessageId: 1234));
      check(store.outboxMessages).isEmpty();
      checkNotifiedOnce();
      check(model)
        ..messages.length.equals(31)
        ..outboxMessages.isEmpty();

      async.elapse(kLocalEchoDebounceDuration);
      checkNotNotified();
    }));

    test('for an OutboxMessage in the narrow', () => awaitFakeAsync((async) async {
      final stream = eg.stream();
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await prepareMessages(foundOldest: true, messages:
        List.generate(30, (i) => eg.streamMessage(stream: stream)));

      await prepareOutboxMessages(count: 5, stream: stream);
      async.elapse(kLocalEchoDebounceDuration);
      checkNotified(count: 5);
      final localMessageId = store.outboxMessages.keys.first;
      check(model)
        ..messages.length.equals(30)
        ..outboxMessages.length.equals(5)
        ..outboxMessages.any((message) =>
            message.localMessageId.equals(localMessageId));

      await store.handleEvent(eg.messageEvent(eg.streamMessage(stream: stream),
        localMessageId: localMessageId));
      checkNotifiedOnce();
      check(model)
        ..messages.length.equals(31)
        ..outboxMessages.length.equals(4)
        ..outboxMessages.every((message) =>
            message.localMessageId.not((m) => m.equals(localMessageId)));
    }));

    test('for an OutboxMessage outside the narrow', () => awaitFakeAsync((async) async {
      final stream = eg.stream();
      await prepare(narrow: eg.topicNarrow(stream.streamId, 'topic'));
      await prepareMessages(foundOldest: true, messages:
        List.generate(30, (i) => eg.streamMessage(stream: stream, topic: 'topic')));

      await prepareOutboxMessages(count: 5, stream: stream, topic: 'other');
      final localMessageId = store.outboxMessages.keys.first;
      check(model)
        ..messages.length.equals(30)
        ..outboxMessages.isEmpty();

      await store.handleEvent(eg.messageEvent(
        eg.streamMessage(stream: stream, topic: 'other'),
        localMessageId: localMessageId));
      checkNotNotified();
      check(model)
        ..messages.length.equals(30)
        ..outboxMessages.isEmpty();

      async.elapse(kLocalEchoDebounceDuration);
      checkNotNotified();
    }));
  });

  group('addOutboxMessage', () {
    final stream = eg.stream();

    test('in narrow', () => awaitFakeAsync((async) async {
      await prepare(narrow: ChannelNarrow(stream.streamId), stream: stream);
      await prepareMessages(foundOldest: true, messages:
        List.generate(30, (i) => eg.streamMessage(stream: stream)));
      await prepareOutboxMessages(count: 5, stream: stream);
      check(model).outboxMessages.isEmpty();

      async.elapse(kLocalEchoDebounceDuration);
      checkNotified(count: 5);
      check(model).outboxMessages.length.equals(5);
    }));

    test('not in narrow', () => awaitFakeAsync((async) async {
      await prepare(narrow: eg.topicNarrow(stream.streamId, 'topic'), stream: stream);
      await prepareMessages(foundOldest: true, messages:
        List.generate(30, (i) => eg.streamMessage(stream: stream, topic: 'topic')));
      await prepareOutboxMessages(count: 5, stream: stream, topic: 'other topic');
      check(model).outboxMessages.isEmpty();

      async.elapse(kLocalEchoDebounceDuration);
      checkNotNotified();
      check(model).outboxMessages.isEmpty();
    }));

    test('before fetch', () => awaitFakeAsync((async) async {
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await prepareOutboxMessages(count: 5, stream: stream);
      check(model)
        ..initialFetched.isFalse()
        ..outboxMessages.isEmpty();

      async.elapse(kLocalEchoDebounceDuration);
      checkNotNotified();
      check(model)
        ..initialFetched.isFalse()
        ..outboxMessages.isEmpty();
    }));
  });

  group('removeOutboxMessage', () {
    final stream = eg.stream();

    Future<void> prepareFailedOutboxMessages(FakeAsync async, {
      required int count,
      required ZulipStream stream,
      String topic = 'some topic',
    }) async {
      for (int i = 0; i < count; i++) {
        connection.prepare(httpException: SocketException('failed'));
        await check(store.sendMessage(
          destination: StreamDestination(stream.streamId, eg.t(topic)),
          content: 'content')).throws();
      }
    }

    test('in narrow', () => awaitFakeAsync((async) async {
      await prepare(narrow: ChannelNarrow(stream.streamId), stream: stream);
      await prepareMessages(foundOldest: true, messages:
        List.generate(30, (i) => eg.streamMessage(stream: stream, topic: 'topic')));
      await prepareFailedOutboxMessages(async,
        count: 5, stream: stream);
      check(model).outboxMessages.length.equals(5);
      checkNotified(count: 5);

      store.takeOutboxMessage(store.outboxMessages.keys.first);
      checkNotifiedOnce();
      check(model).outboxMessages.length.equals(4);
    }));

    test('not in narrow', () => awaitFakeAsync((async) async {
      await prepare(narrow: eg.topicNarrow(stream.streamId, 'topic'), stream: stream);
      await prepareMessages(foundOldest: true, messages:
        List.generate(30, (i) => eg.streamMessage(stream: stream, topic: 'topic')));
      await prepareFailedOutboxMessages(async,
        count: 5, stream: stream, topic: 'other topic');
      check(model).outboxMessages.isEmpty();
      checkNotNotified();

      store.takeOutboxMessage(store.outboxMessages.keys.first);
      check(model).outboxMessages.isEmpty();
      checkNotNotified();
    }));

    test('removed outbox message is the only message in narrow', () => awaitFakeAsync((async) async {
      await prepare(narrow: ChannelNarrow(stream.streamId), stream: stream);
      await prepareMessages(foundOldest: true, messages: []);
      await prepareFailedOutboxMessages(async,
        count: 1, stream: stream);
      check(model).outboxMessages.single;
      checkNotified(count: 1);

      store.takeOutboxMessage(store.outboxMessages.keys.first);
      check(model).outboxMessages.isEmpty();
      checkNotifiedOnce();
    }));
  });

  group('UserTopicEvent', () {
    // The ChannelStore.willChangeIfTopicVisible/InStream methods have their own
    // thorough unit tests.  So these tests focus on the rest of the logic.

    final stream = eg.stream();
    const String topic = 'foo';

    Future<void> setVisibility(UserTopicVisibilityPolicy policy) async {
      await store.handleEvent(eg.userTopicEvent(stream.streamId, topic, policy));
    }

    /// (Should run after `prepare`.)
    Future<void> prepareMutes([
      bool streamMuted = false,
      UserTopicVisibilityPolicy policy = UserTopicVisibilityPolicy.none,
    ]) async {
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream, isMuted: streamMuted));
      await setVisibility(policy);
    }

    test('mute a visible topic', () => awaitFakeAsync((async) async {
      await prepare(narrow: const CombinedFeedNarrow());
      await prepareMutes();
      final otherStream = eg.stream();
      await store.addStream(otherStream);
      await store.addSubscription(eg.subscription(otherStream));
      await prepareMessages(foundOldest: true, messages: [
        eg.streamMessage(id: 1, stream: stream, topic: 'bar'),
        eg.streamMessage(id: 2, stream: stream, topic: topic),
        eg.streamMessage(id: 3, stream: otherStream, topic: 'elsewhere'),
        eg.dmMessage(    id: 4, from: eg.otherUser, to: [eg.selfUser]),
      ]);
      checkHasMessageIds([1, 2, 3, 4]);

      await prepareOutboxMessagesTo([
        StreamDestination(stream.streamId, eg.t(topic)),
        StreamDestination(stream.streamId, eg.t('elsewhere')),
        DmDestination(userIds: [eg.selfUser.userId]),
      ]);
      async.elapse(kLocalEchoDebounceDuration);
      checkNotified(count: 3);
      check(model).outboxMessages.deepEquals(<Condition<Object?>>[
        (it) => it.isA<StreamOutboxMessage>()
                  .conversation.topic.equals(eg.t(topic)),
        (it) => it.isA<StreamOutboxMessage>()
                  .conversation.topic.equals(eg.t('elsewhere')),
        (it) => it.isA<DmOutboxMessage>()
                  .conversation.allRecipientIds.deepEquals([eg.selfUser.userId]),
      ]);

      await setVisibility(UserTopicVisibilityPolicy.muted);
      checkNotifiedOnce();
      checkHasMessageIds([1, 3, 4]);
      check(model).outboxMessages.deepEquals(<Condition<Object?>>[
        (it) => it.isA<StreamOutboxMessage>()
                  .conversation.topic.equals(eg.t('elsewhere')),
        (it) => it.isA<DmOutboxMessage>()
                  .conversation.allRecipientIds.deepEquals([eg.selfUser.userId]),
      ]);
    }));

    test('mute a visible topic containing only outbox messages', () => awaitFakeAsync((async) async {
      await prepare(narrow: const CombinedFeedNarrow());
      await prepareMutes();
      await prepareMessages(foundOldest: true, messages: []);
      await prepareOutboxMessagesTo([
        StreamDestination(stream.streamId, eg.t(topic)),
        StreamDestination(stream.streamId, eg.t(topic)),
      ]);
      async.elapse(kLocalEchoDebounceDuration);
      check(model).outboxMessages.length.equals(2);
      checkNotified(count: 2);

      await setVisibility(UserTopicVisibilityPolicy.muted);
      check(model).outboxMessages.isEmpty();
      checkNotifiedOnce();
    }));

    test('in CombinedFeedNarrow, use combined-feed visibility', () async {
      // Compare the parallel ChannelNarrow test below.
      await prepare(narrow: const CombinedFeedNarrow());
      // Mute the stream, so that combined-feed vs. stream visibility differ.
      await prepareMutes(true, UserTopicVisibilityPolicy.followed);
      await prepareMessages(foundOldest: true, messages: [
        eg.streamMessage(id: 1, stream: stream, topic: topic),
      ]);
      checkHasMessageIds([1]);

      // Dropping from followed to none hides the message
      // (whereas it'd have no effect in a stream narrow).
      await setVisibility(UserTopicVisibilityPolicy.none);
      checkNotifiedOnce();
      checkHasMessageIds([]);

      // Dropping from none to muted has no further effect
      // (whereas it'd hide the message in a stream narrow).
      await setVisibility(UserTopicVisibilityPolicy.muted);
      checkNotNotified();
      checkHasMessageIds([]);
    });

    test('in ChannelNarrow, use stream visibility', () async {
      // Compare the parallel CombinedFeedNarrow test above.
      await prepare(narrow: ChannelNarrow(stream.streamId));
      // Mute the stream, so that combined-feed vs. stream visibility differ.
      await prepareMutes(true, UserTopicVisibilityPolicy.followed);
      await prepareMessages(foundOldest: true, messages: [
        eg.streamMessage(id: 1, stream: stream, topic: topic),
      ]);
      checkHasMessageIds([1]);

      // Dropping from followed to none has no effect
      // (whereas it'd hide the message in the combined feed).
      await setVisibility(UserTopicVisibilityPolicy.none);
      checkNotNotified();
      checkHasMessageIds([1]);

      // Dropping from none to muted hides the message
      // (whereas it'd have no effect in a stream narrow).
      await setVisibility(UserTopicVisibilityPolicy.muted);
      checkNotifiedOnce();
      checkHasMessageIds([]);
    });

    test('in TopicNarrow, stay visible', () async {
      await prepare(narrow: eg.topicNarrow(stream.streamId, topic));
      await prepareMutes();
      await prepareMessages(foundOldest: true, messages: [
        eg.streamMessage(id: 1, stream: stream, topic: topic),
      ]);
      checkHasMessageIds([1]);

      await setVisibility(UserTopicVisibilityPolicy.muted);
      checkNotNotified();
      checkHasMessageIds([1]);
    });

    test('in DmNarrow, do nothing (smoke test)', () async {
      await prepare(narrow:
        DmNarrow.withUser(eg.otherUser.userId, selfUserId: eg.selfUser.userId));
      await prepareMutes();
      await prepareMessages(foundOldest: true, messages: [
        eg.dmMessage(id: 1, from: eg.otherUser, to: [eg.selfUser]),
      ]);
      checkHasMessageIds([1]);

      await setVisibility(UserTopicVisibilityPolicy.muted);
      checkNotNotified();
      checkHasMessageIds([1]);
    });

    test('no affected messages -> no notification', () => awaitFakeAsync((async) async {
      await prepare(narrow: const CombinedFeedNarrow());
      await prepareMutes();
      await prepareMessages(foundOldest: true, messages: [
        eg.streamMessage(id: 1, stream: stream, topic: 'bar'),
      ]);
      checkHasMessageIds([1]);

      await prepareOutboxMessagesTo(
        [StreamDestination(stream.streamId, eg.t('bar'))]);
      async.elapse(kLocalEchoDebounceDuration);
      final outboxMessage = model.outboxMessages.single;
      checkNotifiedOnce();

      await setVisibility(UserTopicVisibilityPolicy.muted);
      checkNotNotified();
      checkHasMessageIds([1]);
      check(model).outboxMessages.single.equals(outboxMessage);
    }));

    test('unmute a topic -> refetch from scratch', () => awaitFakeAsync((async) async {
      await prepare(narrow: const CombinedFeedNarrow());
      await prepareMutes(true);
      final messages = <Message>[
        eg.dmMessage(id: 1, from: eg.otherUser, to: [eg.selfUser]),
        eg.streamMessage(id: 2, stream: stream, topic: topic),
      ];
      await prepareMessages(foundOldest: true, messages: messages);
      await store.setUserTopic(stream, 'muted', UserTopicVisibilityPolicy.muted);
      await prepareOutboxMessagesTo([
        StreamDestination(stream.streamId, eg.t(topic)),
        StreamDestination(stream.streamId, eg.t('muted')),
      ]);
      async.elapse(kLocalEchoDebounceDuration);
      checkHasMessageIds([1]);
      check(model).outboxMessages.isEmpty();

      connection.prepare(
        json: newestResult(foundOldest: true, messages: messages).toJson());
      await setVisibility(UserTopicVisibilityPolicy.unmuted);
      checkNotifiedOnce();
      check(model).initialFetched.isFalse();
      checkHasMessageIds([]);
      check(model).outboxMessages.isEmpty();

      async.elapse(Duration.zero);
      checkNotifiedOnce();
      checkHasMessageIds([1, 2]);
      check(model).outboxMessages.single.isA<StreamOutboxMessage>().conversation
        ..streamId.equals(stream.streamId)
        ..topic.equals(eg.t(topic));
    }));

    test('unmute a topic before initial fetch completes -> do nothing', () => awaitFakeAsync((async) async {
      await prepare(narrow: const CombinedFeedNarrow());
      await prepareMutes(true);
      final messages = [
        eg.streamMessage(id: 1, stream: stream, topic: topic),
      ];

      connection.prepare(
        json: newestResult(foundOldest: true, messages: messages).toJson());
      final fetchFuture = model.fetchInitial();

      await setVisibility(UserTopicVisibilityPolicy.unmuted);
      checkNotNotified();

      // The new policy does get applied when the fetch eventually completes.
      await fetchFuture;
      checkNotifiedOnce();
      checkHasMessageIds([1]);
    }));
  });

  group('MutedUsersEvent', () {
    final user1 = eg.user(userId: 1);
    final user2 = eg.user(userId: 2);
    final user3 = eg.user(userId: 3);
    final users = [user1, user2, user3];

    test('CombinedFeedNarrow', () async {
      await prepare(narrow: CombinedFeedNarrow(), users: users);
      await prepareMessages(foundOldest: true, messages: [
        eg.dmMessage(id: 1, from: eg.selfUser, to: [user1]),
        eg.dmMessage(id: 2, from: eg.selfUser, to: [user1, user2]),
        eg.dmMessage(id: 3, from: eg.selfUser, to: [user2, user3]),
        eg.dmMessage(id: 4, from: eg.selfUser, to: []),
        eg.streamMessage(id: 5),
      ]);
      checkHasMessageIds([1, 2, 3, 4, 5]);

      await store.setMutedUsers([user1.userId]);
      checkNotifiedOnce();
      checkHasMessageIds([2, 3, 4, 5]);

      await store.setMutedUsers([user1.userId, user2.userId]);
      checkNotifiedOnce();
      checkHasMessageIds([3, 4, 5]);
    });

    test('MentionsNarrow', () async {
      await prepare(narrow: MentionsNarrow(), users: users);
      await prepareMessages(foundOldest: true, messages: [
        eg.dmMessage(id: 1, from: eg.selfUser, to: [user1],
          flags: [MessageFlag.mentioned]),
        eg.dmMessage(id: 2, from: eg.selfUser, to: [user2],
          flags: [MessageFlag.mentioned]),
        eg.streamMessage(id: 3, flags: [MessageFlag.mentioned]),
      ]);
      checkHasMessageIds([1, 2, 3]);

      await store.setMutedUsers([user1.userId]);
      checkNotifiedOnce();
      checkHasMessageIds([2, 3]);
    });

    test('StarredMessagesNarrow', () async {
      await prepare(narrow: StarredMessagesNarrow(), users: users);
      await prepareMessages(foundOldest: true, messages: [
        eg.dmMessage(id: 1, from: eg.selfUser, to: [user1],
          flags: [MessageFlag.starred]),
        eg.dmMessage(id: 2, from: eg.selfUser, to: [user2],
          flags: [MessageFlag.starred]),
        eg.streamMessage(id: 3, flags: [MessageFlag.starred]),
      ]);
      checkHasMessageIds([1, 2, 3]);

      await store.setMutedUsers([user1.userId]);
      checkNotifiedOnce();
      checkHasMessageIds([2, 3]);
    });

    test('ChannelNarrow -> do nothing', () async {
      await prepare(narrow: ChannelNarrow(eg.defaultStreamMessageStreamId), users: users);
      await prepareMessages(foundOldest: true, messages: [
        eg.streamMessage(id: 1),
      ]);
      checkHasMessageIds([1]);

      await store.setMutedUsers([user1.userId]);
      checkNotNotified();
      checkHasMessageIds([1]);
    });

    test('TopicNarrow -> do nothing', () async {
      await prepare(narrow: TopicNarrow(eg.defaultStreamMessageStreamId,
        TopicName('topic')), users: users);
      await prepareMessages(foundOldest: true, messages: [
        eg.streamMessage(id: 1, topic: 'topic'),
      ]);
      checkHasMessageIds([1]);

      await store.setMutedUsers([user1.userId]);
      checkNotNotified();
      checkHasMessageIds([1]);
    });

    test('DmNarrow -> do nothing', () async {
      await prepare(
        narrow: DmNarrow.withUser(user1.userId, selfUserId: eg.selfUser.userId),
        users: users);
      await prepareMessages(foundOldest: true, messages: [
        eg.dmMessage(id: 1, from: eg.selfUser, to: [user1]),
      ]);
      checkHasMessageIds([1]);

      await store.setMutedUsers([user1.userId]);
      checkNotNotified();
      checkHasMessageIds([1]);
    });

    test('unmute a user -> refetch from scratch', () => awaitFakeAsync((async) async {
      await prepare(narrow: CombinedFeedNarrow(), users: users,
        mutedUserIds: [user1.userId]);
      final messages = <Message>[
        eg.dmMessage(id: 1, from: eg.selfUser, to: [user1]),
        eg.streamMessage(id: 2),
      ];
      await prepareMessages(foundOldest: true, messages: messages);
      checkHasMessageIds([2]);

      connection.prepare(
        json: newestResult(foundOldest: true, messages: messages).toJson());
      await store.setMutedUsers([]);
      checkNotifiedOnce();
      check(model).initialFetched.isFalse();
      checkHasMessageIds([]);

      async.elapse(Duration.zero);
      checkNotifiedOnce();
      checkHasMessageIds([1, 2]);
    }));

    test('unmute a user before initial fetch completes -> do nothing', () => awaitFakeAsync((async) async {
      await prepare(narrow: CombinedFeedNarrow(), users: users,
        mutedUserIds: [user1.userId]);
      final messages = <Message>[
        eg.dmMessage(id: 1, from: eg.selfUser, to: [user1]),
        eg.streamMessage(id: 2),
      ];
      connection.prepare(
        json: newestResult(foundOldest: true, messages: messages).toJson());
      final fetchFuture = model.fetchInitial();
      await store.setMutedUsers([]);
      checkNotNotified();

      await fetchFuture;
      checkNotifiedOnce();
      checkHasMessageIds([1, 2]);
    }));
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
      checkHasMessages([
        ...messages.sublist(0, 2),
        ...messages.sublist(5, 10),
        ...messages.sublist(15),
      ]);
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

  group('notifyListenersIfOutboxMessagePresent', () {
    final stream = eg.stream();

    test('message present', () => awaitFakeAsync((async) async {
      await prepare(narrow: const CombinedFeedNarrow(), stream: stream);
      await prepareMessages(foundOldest: true, messages: []);
      await prepareOutboxMessages(count: 5, stream: stream);

      async.elapse(kLocalEchoDebounceDuration);
      checkNotified(count: 5);

      model.notifyListenersIfOutboxMessagePresent(
        store.outboxMessages.keys.first);
      checkNotifiedOnce();
    }));

    test('message not present', () => awaitFakeAsync((async) async {
      await prepare(
        narrow: eg.topicNarrow(stream.streamId, 'some topic'), stream: stream);
      await prepareMessages(foundOldest: true, messages: []);
      await prepareOutboxMessages(count: 5,
        stream: stream, topic: 'other topic');

      async.elapse(kLocalEchoDebounceDuration);
      checkNotNotified();

      model.notifyListenersIfOutboxMessagePresent(
        store.outboxMessages.keys.first);
      checkNotNotified();
    }));
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
          newTopicStr: 'new',
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
          newTopicStr: 'new',
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
          origTopicStr: 'orig topic',
          origStreamId: otherStream.streamId,
          newMessages: movedMessages,
        ));
        check(model).initialFetched.isFalse();
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
          newTopicStr: 'new',
          newStreamId: otherStream.streamId,
        ));
        checkHasMessages(initialMessages);
        checkNotifiedOnce();
      });

      test('channel -> new channel (with outbox messages): remove moved messages; outbox messages unaffected', () => awaitFakeAsync((async) async {
        final narrow = ChannelNarrow(stream.streamId);
        await prepareNarrow(narrow, initialMessages + movedMessages);
        connection.prepare(json: SendMessageResult(id: 1).toJson());
        await prepareOutboxMessages(count: 5, stream: stream);

        async.elapse(kLocalEchoDebounceDuration);
        checkNotified(count: 5);
        final outboxMessagesCopy = model.outboxMessages.toList();

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: movedMessages,
          newTopicStr: 'new',
          newStreamId: otherStream.streamId,
        ));
        checkHasMessages(initialMessages);
        check(model).outboxMessages.deepEquals(outboxMessagesCopy);
        checkNotifiedOnce();
      }));

      test('unrelated channel -> new channel: unaffected', () async {
        final thirdStream = eg.stream();
        await prepareNarrow(narrow, initialMessages);
        await store.addStream(thirdStream);
        await store.addSubscription(eg.subscription(thirdStream));

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: otherChannelMovedMessages,
          newStreamId: thirdStream.streamId,
        ));
        checkHasMessages(initialMessages);
        checkNotNotified();
      });

      test('unrelated channel -> unrelated channel: unaffected', () async {
        await prepareNarrow(narrow, initialMessages);

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: otherChannelMovedMessages,
          newTopicStr: 'new',
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
          newTopicStr: 'new',
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
      final narrow = eg.topicNarrow(stream.streamId, 'topic');
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
              origTopicStr: origTopic,
              newMessages: movedMessages,
            ));
            check(model).initialFetched.isFalse();
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
              newTopicStr: newTopic,
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
            origTopicStr: 'other',
            newMessages: otherTopicMovedMessages,
          ));
          check(model).initialFetched.isTrue();
          checkHasMessages(initialMessages);
          checkNotNotified();
        }));

        test('(old channel, topic) - > (unrelated channel, topic)', () => awaitFakeAsync((async) async {
          await prepareNarrow(narrow, initialMessages);

          await store.handleEvent(eg.updateMessageEventMoveTo(
            origStreamId: 200,
            newMessages: otherChannelMovedMessages,
          ));
          check(model).initialFetched.isTrue();
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
          newTopicStr: 'new',
          newStreamId: otherStream.streamId,
          propagateMode: propagateMode,
        ));
        switch (propagateMode) {
          case PropagateMode.changeOne:
            checkNotifiedOnce();
          case PropagateMode.changeLater:
          case PropagateMode.changeAll:
            checkNotified(count: 2);
        }
        async.elapse(const Duration(seconds: 1));
      });

      test('do not follow to the new narrow when propagateMode = changeOne', () {
        handleMoveEvent(PropagateMode.changeOne);
        checkNotNotified();
        checkHasMessages(initialMessages);
        check(model).narrow.equals(eg.topicNarrow(stream.streamId, 'topic'));
      });

      test('follow to the new narrow when propagateMode = changeLater', () {
        handleMoveEvent(PropagateMode.changeLater);
        checkNotifiedOnce();
        checkHasMessages(movedMessages);
        check(model).narrow.equals(eg.topicNarrow(otherStream.streamId, 'new'));
      });

      test('follow to the new narrow when propagateMode = changeAll', () {
        handleMoveEvent(PropagateMode.changeAll);
        checkNotifiedOnce();
        checkHasMessages(movedMessages);
        check(model).narrow.equals(eg.topicNarrow(otherStream.streamId, 'new'));
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

        check(model).initialFetched.isFalse();
        checkHasMessages([]);
        await store.handleEvent(eg.updateMessageEventMoveTo(
          origTopicStr: 'topic',
          newMessages: [followedMessage],
          propagateMode: PropagateMode.changeAll,
        ));
        check(model).narrow.equals(eg.topicNarrow(stream.streamId, 'new'));

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
        check(model).busyFetchingOlder.isTrue();
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
        check(model).busyFetchingOlder.isFalse();
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
        check(model).busyFetchingOlder.isTrue();
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
        check(model).busyFetchingOlder.isFalse();
        checkNotifiedOnce();

        async.elapse(const Duration(seconds: 1));
        checkHasMessages(initialMessages + movedMessages);
        checkNotifiedOnce();

        await fetchFuture;
        checkHasMessages(initialMessages + movedMessages);
        checkNotNotified();
      }));

      test('fetchOlder backoff A starts, _reset, move fetch finishes,'
          ' fetchOlder backoff B starts, fetchOlder backoff A ends', () => awaitFakeAsync((async) async {
        addTearDown(() => BackoffMachine.debugDuration = null);
        await prepareNarrow(narrow, initialMessages);

        connection.prepare(apiException: eg.apiBadRequest());
        BackoffMachine.debugDuration = const Duration(seconds: 1);
        await check(model.fetchOlder()).throws<ZulipApiException>();
        final backoffTimerA = async.pendingTimers.single;
        check(model).busyFetchingOlder.isTrue();
        check(model).initialFetched.isTrue();
        checkHasMessages(initialMessages);
        checkNotified(count: 2);

        connection.prepare(json: newestResult(
          foundOldest: false,
          messages: initialMessages + movedMessages,
        ).toJson());
        await store.handleEvent(eg.updateMessageEventMoveTo(
          origTopic: movedMessages[0].topic,
          origStreamId: otherStream.streamId,
          newMessages: movedMessages,
        ));
        // Check that _reset was called.
        check(model).initialFetched.isFalse();
        checkHasMessages([]);
        checkNotifiedOnce();
        check(model).busyFetchingOlder.isFalse();
        check(backoffTimerA.isActive).isTrue();

        async.elapse(Duration.zero);
        check(model).initialFetched.isTrue();
        checkHasMessages(initialMessages + movedMessages);
        checkNotifiedOnce();
        check(model).busyFetchingOlder.isFalse();
        check(backoffTimerA.isActive).isTrue();

        connection.prepare(apiException: eg.apiBadRequest());
        BackoffMachine.debugDuration = const Duration(seconds: 2);
        await check(model.fetchOlder()).throws<ZulipApiException>();
        final backoffTimerB = async.pendingTimers.last;
        check(model).busyFetchingOlder.isTrue();
        check(backoffTimerA.isActive).isTrue();
        check(backoffTimerB.isActive).isTrue();
        checkNotified(count: 2);

        // When `backoffTimerA` ends, `busyFetchingOlder` remains `true`
        // because the backoff was from a previous generation.
        async.elapse(const Duration(seconds: 1));
        check(model).busyFetchingOlder.isTrue();
        check(backoffTimerA.isActive).isFalse();
        check(backoffTimerB.isActive).isTrue();
        checkNotNotified();

        // When `backoffTimerB` ends, `busyFetchingOlder` gets reset.
        async.elapse(const Duration(seconds: 1));
        check(model).busyFetchingOlder.isFalse();
        check(backoffTimerA.isActive).isFalse();
        check(backoffTimerB.isActive).isFalse();
        checkNotifiedOnce();
      }));

      test('fetchInitial, _reset, initial fetch finishes, move fetch finishes', () => awaitFakeAsync((async) async {
        await prepareNarrow(narrow, null);

        connection.prepare(delay: const Duration(seconds: 1), json: newestResult(
          foundOldest: false,
          messages: initialMessages,
        ).toJson());
        final fetchFuture = model.fetchInitial();
        checkHasMessages([]);
        check(model).initialFetched.isFalse();

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
        check(model).initialFetched.isFalse();
        checkNotifiedOnce();

        await fetchFuture;
        checkHasMessages([]);
        check(model).initialFetched.isFalse();
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
        check(model).initialFetched.isFalse();

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
        check(model).initialFetched.isFalse();

        async.elapse(const Duration(seconds: 1));
        checkHasMessages(initialMessages + movedMessages);
        check(model).initialFetched.isTrue();

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
        check(model).busyFetchingOlder.isTrue();
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
        check(model).busyFetchingOlder.isFalse();
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
        check(model).busyFetchingOlder.isTrue();
        checkNotifiedOnce();

        await fetchFuture1;
        checkHasMessages(initialMessages + movedMessages);
        // The older fetchOlder call should not override fetchingOlder set by
        // the new fetchOlder call, nor should it notify the listeners.
        check(model).busyFetchingOlder.isTrue();
        checkNotNotified();

        await fetchFuture2;
        checkHasMessages(olderMessages + initialMessages + movedMessages);
        check(model).busyFetchingOlder.isFalse();
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
          narrow: ChannelNarrow(stream.streamId),
          anchor: AnchorCode.newest)
        ..addListener(() => notifiedCount1++);

      int notifiedCount2 = 0;
      final model2 = MessageListView.init(store: store,
          narrow: eg.topicNarrow(stream.streamId, 'hello'),
          anchor: AnchorCode.newest)
        ..addListener(() => notifiedCount2++);

      for (final m in [model1, model2]) {
        connection.prepare(json: newestResult(
          foundOldest: false,
          messages: [eg.streamMessage(stream: stream, topic: 'hello')]).toJson());
        await m.fetchInitial();
      }

      final message = eg.streamMessage(stream: stream, topic: 'hello');
      await store.addMessage(message);

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
      model = MessageListView.init(store: store,
        narrow: const CombinedFeedNarrow(), anchor: AnchorCode.newest);
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
    await store.addMessage(eg.streamMessage(stream: stream));
    checkNotifiedOnce();
    check(model).messages.length.equals(31);

    // Mess with model.contents, to simulate it having come from
    // a previous version of the code.
    final correctContent = parseContent(model.messages[0].content);
    model.contents[0] = const ZulipContent(nodes: [
      ParagraphNode(links: null, nodes: [TextNode('something outdated')])
    ]);
    check(model.contents[0]).isA<ZulipContent>()
      .not((it) => it.equalsNode(correctContent));

    model.reassemble();
    checkNotifiedOnce();
    check(model).messages.length.equals(31);
    check(model.contents[0]).isA<ZulipContent>().equalsNode(correctContent);
  });

  group('stream/topic muting', () {
    test('in CombinedFeedNarrow', () async {
      final stream1 = eg.stream();
      final stream2 = eg.stream();
      await prepare(narrow: const CombinedFeedNarrow());
      await store.addStreams([stream1, stream2]);
      await store.addSubscription(eg.subscription(stream1));
      await store.setUserTopic(stream1, 'B', UserTopicVisibilityPolicy.muted);
      await store.addSubscription(eg.subscription(stream2, isMuted: true));
      await store.setUserTopic(stream2, 'C', UserTopicVisibilityPolicy.unmuted);

      // Check filtering on fetchInitial…
      await prepareMessages(foundOldest: false, messages: [
        eg.streamMessage(id: 201, stream: stream1, topic: 'A'),
        eg.streamMessage(id: 202, stream: stream1, topic: 'B'),
        eg.streamMessage(id: 203, stream: stream2, topic: 'C'),
        eg.streamMessage(id: 204, stream: stream2, topic: 'D'),
        eg.dmMessage(    id: 205, from: eg.otherUser, to: [eg.selfUser]),
      ]);
      final expected = <int>[];
      checkHasMessageIds(expected..addAll([201, 203, 205]));

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
      checkHasMessageIds(expected..insertAll(0, [101, 103, 105]));

      // … and on MessageEvent.
      await store.addMessage(
        eg.streamMessage(id: 301, stream: stream1, topic: 'A'));
      checkNotifiedOnce();
      checkHasMessageIds(expected..add(301));

      await store.addMessage(
        eg.streamMessage(id: 302, stream: stream1, topic: 'B'));
      checkNotNotified();
      checkHasMessageIds(expected);

      await store.addMessage(
        eg.streamMessage(id: 303, stream: stream2, topic: 'C'));
      checkNotifiedOnce();
      checkHasMessageIds(expected..add(303));

      await store.addMessage(
        eg.streamMessage(id: 304, stream: stream2, topic: 'D'));
      checkNotNotified();
      checkHasMessageIds(expected);

      await store.addMessage(
        eg.dmMessage(id: 305, from: eg.otherUser, to: [eg.selfUser]));
      checkNotifiedOnce();
      checkHasMessageIds(expected..add(305));
    });

    test('in ChannelNarrow', () async {
      final stream = eg.stream();
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream, isMuted: true));
      await store.setUserTopic(stream, 'A', UserTopicVisibilityPolicy.unmuted);
      await store.setUserTopic(stream, 'C', UserTopicVisibilityPolicy.muted);

      // Check filtering on fetchInitial…
      await prepareMessages(foundOldest: false, messages: [
        eg.streamMessage(id: 201, stream: stream, topic: 'A'),
        eg.streamMessage(id: 202, stream: stream, topic: 'B'),
        eg.streamMessage(id: 203, stream: stream, topic: 'C'),
      ]);
      final expected = <int>[];
      checkHasMessageIds(expected..addAll([201, 202]));

      // … and on fetchOlder…
      connection.prepare(json: olderResult(
        anchor: 201, foundOldest: true, messages: [
          eg.streamMessage(id: 101, stream: stream, topic: 'A'),
          eg.streamMessage(id: 102, stream: stream, topic: 'B'),
          eg.streamMessage(id: 103, stream: stream, topic: 'C'),
        ]).toJson());
      await model.fetchOlder();
      checkNotified(count: 2);
      checkHasMessageIds(expected..insertAll(0, [101, 102]));

      // … and on MessageEvent.
      await store.addMessage(
        eg.streamMessage(id: 301, stream: stream, topic: 'A'));
      checkNotifiedOnce();
      checkHasMessageIds(expected..add(301));

      await store.addMessage(
        eg.streamMessage(id: 302, stream: stream, topic: 'B'));
      checkNotifiedOnce();
      checkHasMessageIds(expected..add(302));

      await store.addMessage(
        eg.streamMessage(id: 303, stream: stream, topic: 'C'));
      checkNotNotified();
      checkHasMessageIds(expected);
    });

    test('handle outbox messages', () => awaitFakeAsync((async) async {
      final stream = eg.stream();
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream));
      await store.setUserTopic(stream, 'muted', UserTopicVisibilityPolicy.muted);
      await prepareMessages(foundOldest: true, messages: []);

      // Check filtering on sent messages…
      await prepareOutboxMessagesTo([
        StreamDestination(stream.streamId, eg.t('not muted')),
        StreamDestination(stream.streamId, eg.t('muted')),
      ]);
      async.elapse(kLocalEchoDebounceDuration);
      checkNotifiedOnce();
      check(model.outboxMessages).single.isA<StreamOutboxMessage>()
        .conversation.topic.equals(eg.t('not muted'));

      final messages = [eg.streamMessage(stream: stream)];
      connection.prepare(json: newestResult(
        foundOldest: true, messages: messages).toJson());
      // Check filtering on fetchInitial…
      await store.handleEvent(eg.updateMessageEventMoveTo(
        newMessages: messages,
        origStreamId: eg.stream().streamId));
      checkNotifiedOnce();
      check(model).initialFetched.isFalse();
      async.elapse(Duration.zero);
      check(model).initialFetched.isTrue();
      check(model.outboxMessages).single.isA<StreamOutboxMessage>()
        .conversation.topic.equals(eg.t('not muted'));
    }));

    test('in TopicNarrow', () async {
      final stream = eg.stream();
      await prepare(narrow: eg.topicNarrow(stream.streamId, 'A'));
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream, isMuted: true));
      await store.setUserTopic(stream, 'A', UserTopicVisibilityPolicy.muted);

      // Check filtering on fetchInitial…
      await prepareMessages(foundOldest: false, messages: [
        eg.streamMessage(id: 201, stream: stream, topic: 'A'),
      ]);
      final expected = <int>[];
      checkHasMessageIds(expected..addAll([201]));

      // … and on fetchOlder…
      connection.prepare(json: olderResult(
        anchor: 201, foundOldest: true, messages: [
          eg.streamMessage(id: 101, stream: stream, topic: 'A'),
        ]).toJson());
      await model.fetchOlder();
      checkNotified(count: 2);
      checkHasMessageIds(expected..insertAll(0, [101]));

      // … and on MessageEvent.
      await store.addMessage(
        eg.streamMessage(id: 301, stream: stream, topic: 'A'));
      checkNotifiedOnce();
      checkHasMessageIds(expected..add(301));
    });

    test('in MentionsNarrow', () async {
      final stream = eg.stream();
      const mutedTopic = 'muted';
      await prepare(narrow: const MentionsNarrow());
      await store.addStream(stream);
      await store.setUserTopic(stream, mutedTopic, UserTopicVisibilityPolicy.muted);
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
      checkHasMessageIds(expected..addAll([201, 202, 203]));

      // … and on fetchOlder…
      connection.prepare(json: olderResult(
        anchor: 201, foundOldest: true, messages: getMessages(101)).toJson());
      await model.fetchOlder();
      checkNotified(count: 2);
      checkHasMessageIds(expected..insertAll(0, [101, 102, 103]));

      // … and on MessageEvent.
      final messages = getMessages(301);
      for (var i = 0; i < 3; i += 1) {
        await store.addMessage(messages[i]);
        checkNotifiedOnce();
        checkHasMessageIds(expected..add(301 + i));
      }
    });

    test('in StarredMessagesNarrow', () async {
      final stream = eg.stream(streamId: 1, name: 'muted stream');
      const mutedTopic = 'muted';
      await prepare(narrow: const StarredMessagesNarrow());
      await store.addStream(stream);
      await store.setUserTopic(stream, mutedTopic, UserTopicVisibilityPolicy.muted);
      await store.addSubscription(eg.subscription(stream, isMuted: true));

      List<Message> getMessages(int startingId) => [
        eg.streamMessage(id: startingId,
          stream: stream, topic: mutedTopic, flags: [MessageFlag.starred]),
        eg.dmMessage(id: startingId + 1,
          from: eg.otherUser, to: [eg.selfUser], flags: [MessageFlag.starred]),
      ];

      // Check filtering on fetchInitial…
      await prepareMessages(foundOldest: false, messages: getMessages(201));
      final expected = <int>[];
      checkHasMessageIds(expected..addAll([201, 202]));

      // … and on fetchOlder…
      connection.prepare(json: olderResult(
        anchor: 201, foundOldest: true, messages: getMessages(101)).toJson());
      await model.fetchOlder();
      checkNotified(count: 2);
      checkHasMessageIds(expected..insertAll(0, [101, 102]));

      // … and on MessageEvent.
      final messages = getMessages(301);
      for (var i = 0; i < 2; i += 1) {
        await store.addMessage(messages[i]);
        checkNotifiedOnce();
        checkHasMessageIds(expected..add(301 + i));
      }
    });
  });

  group('middleMessage maintained', () {
    // In [checkInvariants] we verify that messages don't move from the
    // top to the bottom slice or vice versa.
    // Most of these test cases rely on that for all the checks they need.

    test('on fetchInitial empty', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      await prepareMessages(foundOldest: true, messages: []);
      check(model)..messages.isEmpty()
        ..middleMessage.equals(0);
    });

    test('on fetchInitial empty due to muting', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      final stream = eg.stream();
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream, isMuted: true));
      await prepareMessages(foundOldest: true, messages: [
        eg.streamMessage(stream: stream),
      ]);
      check(model)..messages.isEmpty()
        ..middleMessage.equals(0);
    });

    test('on fetchInitial, anchor past end', () async {
      await prepare(narrow: const CombinedFeedNarrow(),
        anchor: AnchorCode.newest);
      final stream1 = eg.stream();
      final stream2 = eg.stream();
      await store.addStreams([stream1, stream2]);
      await store.addSubscription(eg.subscription(stream1));
      await store.addSubscription(eg.subscription(stream2, isMuted: true));
      final messages = [
        eg.streamMessage(stream: stream1), eg.streamMessage(stream: stream2),
        eg.streamMessage(stream: stream1), eg.streamMessage(stream: stream2),
        eg.streamMessage(stream: stream1), eg.streamMessage(stream: stream2),
        eg.streamMessage(stream: stream1), eg.streamMessage(stream: stream2),
        eg.streamMessage(stream: stream1), eg.streamMessage(stream: stream2),
      ];
      await prepareMessages(foundOldest: true, messages: messages);
      // The anchor message is the last visible message…
      check(model)
        ..messages.length.equals(5)
        ..middleMessage.equals(model.messages.length - 1)
        // … even though that's not the last message that was in the response.
        ..messages[model.middleMessage].id
            .equals(messages[messages.length - 2].id);
    });

    test('on fetchInitial, anchor in middle', () async {
      final s1 = eg.stream();
      final s2 = eg.stream();
      final messages = [
        eg.streamMessage(id: 1, stream: s1), eg.streamMessage(id: 2, stream: s2),
        eg.streamMessage(id: 3, stream: s1), eg.streamMessage(id: 4, stream: s2),
        eg.streamMessage(id: 5, stream: s1), eg.streamMessage(id: 6, stream: s2),
        eg.streamMessage(id: 7, stream: s1), eg.streamMessage(id: 8, stream: s2),
      ];
      final anchorId = 4;

      await prepare(narrow: const CombinedFeedNarrow(),
        anchor: NumericAnchor(anchorId));
      await store.addStreams([s1, s2]);
      await store.addSubscription(eg.subscription(s1));
      await store.addSubscription(eg.subscription(s2, isMuted: true));
      await prepareMessages(foundOldest: true, foundNewest: true,
        messages: messages);
      // The anchor message is the first visible message with ID at least anchorId…
      check(model)
        ..messages[model.middleMessage - 1].id.isLessThan(anchorId)
        ..messages[model.middleMessage].id.isGreaterOrEqual(anchorId);
      // … even though a non-visible message actually had anchorId itself.
      check(messages[3].id)
        ..equals(anchorId)
        ..isLessThan(model.messages[model.middleMessage].id);
    });

    /// Like [prepareMessages], but arrange for the given top and bottom slices.
    Future<void> prepareMessageSplit(List<Message> top, List<Message> bottom, {
      bool foundOldest = true,
    }) async {
      assert(bottom.isNotEmpty); // could handle this too if necessary
      await prepareMessages(foundOldest: foundOldest, messages: [
        ...top,
        bottom.first,
      ]);
      if (bottom.length > 1) {
        await store.addMessages(bottom.skip(1));
        checkNotifiedOnce();
      }
      check(model)
        ..messages.length.equals(top.length + bottom.length)
        ..middleMessage.equals(top.length);
    }

    test('on fetchOlder', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      final stream = eg.stream();
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream));
      await prepareMessageSplit(foundOldest: false,
        [eg.streamMessage(id: 100, stream: stream)],
        [eg.streamMessage(id: 101, stream: stream)]);

      connection.prepare(json: olderResult(anchor: 100, foundOldest: true,
        messages: List.generate(5, (i) =>
          eg.streamMessage(id: 95 + i, stream: stream))).toJson());
      await model.fetchOlder();
      checkNotified(count: 2);
    });

    test('on fetchOlder, from top empty', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      final stream = eg.stream();
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream));
      await prepareMessageSplit(foundOldest: false,
        [], [eg.streamMessage(id: 100, stream: stream)]);

      connection.prepare(json: olderResult(anchor: 100, foundOldest: true,
        messages: List.generate(5, (i) =>
          eg.streamMessage(id: 95 + i, stream: stream))).toJson());
      await model.fetchOlder();
      checkNotified(count: 2);
      // The messages from fetchOlder should go in the top sliver, always.
      check(model).middleMessage.equals(5);
    });

    test('on MessageEvent', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      final stream = eg.stream();
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream));
      await prepareMessageSplit(foundOldest: false,
        [eg.streamMessage(stream: stream)],
        [eg.streamMessage(stream: stream)]);

      await store.addMessage(eg.streamMessage(stream: stream));
      checkNotifiedOnce();
    });

    test('on messages muted, including anchor', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      final stream = eg.stream();
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream));
      await prepareMessageSplit([
        eg.streamMessage(stream: stream, topic: 'foo'),
        eg.streamMessage(stream: stream, topic: 'bar'),
      ], [
        eg.streamMessage(stream: stream, topic: 'bar'),
        eg.streamMessage(stream: stream, topic: 'foo'),
      ]);

      await store.handleEvent(eg.userTopicEvent(
        stream.streamId, 'bar', UserTopicVisibilityPolicy.muted));
      checkNotifiedOnce();
    });

    test('on messages muted, not including anchor', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      final stream = eg.stream();
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream));
      await prepareMessageSplit([
        eg.streamMessage(stream: stream, topic: 'foo'),
        eg.streamMessage(stream: stream, topic: 'bar'),
      ], [
        eg.streamMessage(stream: stream, topic: 'foo'),
      ]);

      await store.handleEvent(eg.userTopicEvent(
        stream.streamId, 'bar', UserTopicVisibilityPolicy.muted));
      checkNotifiedOnce();
    });

    test('on messages muted, bottom empty', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      final stream = eg.stream();
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream));
      await prepareMessageSplit([
        eg.streamMessage(stream: stream, topic: 'foo'),
        eg.streamMessage(stream: stream, topic: 'bar'),
      ], [
        eg.streamMessage(stream: stream, topic: 'third'),
      ]);

      await store.handleEvent(eg.deleteMessageEvent([
        model.messages.last as StreamMessage]));
      checkNotifiedOnce();
      check(model).middleMessage.equals(model.messages.length);

      await store.handleEvent(eg.userTopicEvent(
        stream.streamId, 'bar', UserTopicVisibilityPolicy.muted));
      checkNotifiedOnce();
    });

    test('on messages deleted', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      final stream = eg.stream();
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream));
      final messages = [
        eg.streamMessage(id: 1, stream: stream),
        eg.streamMessage(id: 2, stream: stream),
        eg.streamMessage(id: 3, stream: stream),
        eg.streamMessage(id: 4, stream: stream),
      ];
      await prepareMessageSplit(messages.sublist(0, 2), messages.sublist(2));

      await store.handleEvent(eg.deleteMessageEvent(messages.sublist(1, 3)));
      checkNotifiedOnce();
    });

    test('on messages deleted, bottom empty', () async {
      await prepare(narrow: const CombinedFeedNarrow());
      final stream = eg.stream();
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream));
      final messages = [
        eg.streamMessage(id: 1, stream: stream),
        eg.streamMessage(id: 2, stream: stream),
        eg.streamMessage(id: 3, stream: stream),
        eg.streamMessage(id: 4, stream: stream),
      ];
      await prepareMessageSplit(messages.sublist(0, 3), messages.sublist(3));

      await store.handleEvent(eg.deleteMessageEvent(messages.sublist(3)));
      checkNotifiedOnce();
      check(model).middleMessage.equals(model.messages.length);

      await store.handleEvent(eg.deleteMessageEvent(messages.sublist(1, 2)));
      checkNotifiedOnce();
    });
  });

  group('handle content parsing into subclasses of ZulipMessageContent', () {
    test('ZulipContent', () async {
      final stream = eg.stream();
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await prepareMessages(foundOldest: true, messages: []);

      await store.addMessage(eg.streamMessage(stream: stream));
      // Each [checkNotifiedOnce] call ensures there's been a [checkInvariants]
      // call, where the [ContentNode] gets checked.  The additional checks to
      // make this test explicit.
      checkNotifiedOnce();
      check(model).messages.single.poll.isNull();
      check(model).contents.single.isA<ZulipContent>();
    });

    test('PollContent', () async {
      final stream = eg.stream();
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await prepareMessages(foundOldest: true, messages: []);

      await store.addMessage(eg.streamMessage(
        stream: stream,
        sender: eg.selfUser,
        submessages: [
          eg.submessage(senderId: eg.selfUser.userId,
            content: eg.pollWidgetData(question: 'question', options: ['A'])),
        ]));
      // Each [checkNotifiedOnce] call ensures there's been a [checkInvariants]
      // call, where the value of the [Poll] gets checked.  The additional
      // checks make this test explicit.
      checkNotifiedOnce();
      check(model).messages.single.poll.isNotNull();
      check(model).contents.single.isA<PollContent>();
    });
  });

  group('findItemWithMessageId', () {
    test('has MessageListDateSeparatorItem with null message ID', () => awaitFakeAsync((async) async {
      final stream = eg.stream();
      final message = eg.streamMessage(stream: stream, topic: 'topic',
        timestamp: eg.utcTimestamp(clock.daysAgo(1)));
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await prepareMessages(foundOldest: true, messages: [message]);

      // `findItemWithMessageId` uses binary search.  Set up just enough
      // outbox message items, so that a [MessageListDateSeparatorItem] for
      // the outbox messages is right in the middle.
      await prepareOutboxMessages(count: 2, stream: stream, topic: 'topic');
      async.elapse(kLocalEchoDebounceDuration);
      checkNotified(count: 2);
      check(model.items).deepEquals(<Condition<Object?>>[
        (it) => it.isA<MessageListRecipientHeaderItem>(),
        (it) => it.isA<MessageListMessageItem>(),
        (it) => it.isA<MessageListDateSeparatorItem>().message.id.isNull(),
        (it) => it.isA<MessageListOutboxMessageItem>(),
        (it) => it.isA<MessageListOutboxMessageItem>(),
      ]);
      check(model.findItemWithMessageId(message.id)).equals(1);
    }));

    test('has MessageListOutboxMessageItem', () => awaitFakeAsync((async) async {
      final stream = eg.stream();
      final message = eg.streamMessage(stream: stream, topic: 'topic',
        timestamp: eg.utcTimestamp(clock.now()));
      await prepare(narrow: ChannelNarrow(stream.streamId));
      await prepareMessages(foundOldest: true, messages: [message]);

      // `findItemWithMessageId` uses binary search.  Set up just enough
      // outbox message items, so that a [MessageListOutboxMessageItem]
      // is right in the middle.
      await prepareOutboxMessages(count: 3, stream: stream, topic: 'topic');
      async.elapse(kLocalEchoDebounceDuration);
      checkNotified(count: 3);
      check(model.items).deepEquals(<Condition<Object?>>[
        (it) => it.isA<MessageListRecipientHeaderItem>(),
        (it) => it.isA<MessageListMessageItem>(),
        (it) => it.isA<MessageListOutboxMessageItem>(),
        (it) => it.isA<MessageListOutboxMessageItem>(),
        (it) => it.isA<MessageListOutboxMessageItem>(),
      ]);
      check(model.findItemWithMessageId(message.id)).equals(1);
    }));
  });

  test('recipient headers are maintained consistently (Combined feed)', () => awaitFakeAsync((async) async {
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

    final timestamp = eg.utcTimestamp(clock.now());
    final stream = eg.stream(streamId: eg.defaultStreamMessageStreamId);
    Message streamMessage(int id) =>
      eg.streamMessage(id: id, stream: stream, topic: 'foo', timestamp: timestamp);
    Message dmMessage(int id) =>
      eg.dmMessage(id: id, from: eg.selfUser, to: [], timestamp: timestamp);

    List<Message> streamMessages({required int fromId, required int toId}) {
      assert(fromId > 0 && fromId <= toId);
      return [
        for (int id = fromId; id <= toId; id++)
          streamMessage(id)
      ];
    }

    // First, test fetchInitial, where some headers are needed and others not.
    await prepare(narrow: CombinedFeedNarrow());
    connection.prepare(json: newestResult(
      foundOldest: false,
      messages: [streamMessage(200), streamMessage(201), dmMessage(202)],
    ).toJson());
    await model.fetchInitial();
    checkNotifiedOnce();

    // Then fetchOlder, where a header is needed in between…
    connection.prepare(json: olderResult(
      anchor: model.messages[0].id,
      foundOldest: false,
      messages: [...streamMessages(fromId: 150, toId: 198), dmMessage(199)],
    ).toJson());
    await model.fetchOlder();
    checkNotified(count: 2);

    //  … and fetchOlder where there's no header in between.
    connection.prepare(json: olderResult(
      anchor: model.messages[0].id,
      foundOldest: false,
      messages: streamMessages(fromId: 100, toId: 149),
    ).toJson());
    await model.fetchOlder();
    checkNotified(count: 2);

    // Then test MessageEvent, where a new header is needed…
    await store.addMessage(streamMessage(203));
    checkNotifiedOnce();

    // … and where it's not.
    await store.addMessage(streamMessage(204));
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

    // Then test outbox message, where a new header is needed…
    connection.prepare(json: SendMessageResult(id: 1).toJson());
    await store.sendMessage(
      destination: DmDestination(userIds: [eg.selfUser.userId]), content: 'hi');
    async.elapse(kLocalEchoDebounceDuration);
    checkNotifiedOnce();

    // … and where it's not.
    connection.prepare(json: SendMessageResult(id: 1).toJson());
    await store.sendMessage(
      destination: DmDestination(userIds: [eg.selfUser.userId]), content: 'hi');
    async.elapse(kLocalEchoDebounceDuration);
    checkNotifiedOnce();

    // Have a new fetchOlder reach the oldest, so that a history-start marker appears…
    connection.prepare(json: olderResult(
      anchor: model.messages[0].id,
      foundOldest: true,
      messages: [streamMessage(99)],
    ).toJson());
    await model.fetchOlder();
    checkNotified(count: 2);

    // … and then test reassemble again.
    model.reassemble();
    checkNotifiedOnce();

    final outboxMessageIds = store.outboxMessages.keys.toList();
    // Then test removing the first outbox message…
    await store.handleEvent(eg.messageEvent(
      dmMessage(205), localMessageId: outboxMessageIds.first));
    checkNotifiedOnce();

    // … and handling a new non-outbox message…
    await store.handleEvent(eg.messageEvent(streamMessage(206)));
    checkNotifiedOnce();

    // … and removing the second outbox message.
    await store.handleEvent(eg.messageEvent(
      dmMessage(207), localMessageId: outboxMessageIds.last));
    checkNotifiedOnce();
  }));

  group('one message per block?', () {
    final channelId = 1;
    final topic = 'some topic';
    void doTest({required Narrow narrow, required bool expected}) {
      test('$narrow: ${expected ? 'yes' : 'no'}', () => awaitFakeAsync((async) async {
        final sender = eg.user();
        final channel = eg.stream(streamId: channelId);
        final message1 = eg.streamMessage(
          sender: sender,
          stream: channel,
          topic: topic,
          flags: [MessageFlag.starred, MessageFlag.mentioned],
        );
        final message2 = eg.streamMessage(
          sender: sender,
          stream: channel,
          topic: topic,
          flags: [MessageFlag.starred, MessageFlag.mentioned],
        );

        await prepare(
          narrow: narrow,
          stream: channel,
        );
        connection.prepare(json: newestResult(
          foundOldest: false,
          messages: [message1, message2],
        ).toJson());
        await model.fetchInitial();
        checkNotifiedOnce();

        check(model).items.deepEquals(<Condition<Object?>>[
          (it) => it.isA<MessageListRecipientHeaderItem>(),
          (it) => it.isA<MessageListMessageItem>(),
          if (expected) (it) => it.isA<MessageListRecipientHeaderItem>(),
          (it) => it.isA<MessageListMessageItem>(),
        ]);
      }));
    }

    doTest(narrow: CombinedFeedNarrow(),                expected: false);
    doTest(narrow: ChannelNarrow(channelId),            expected: false);
    doTest(narrow: TopicNarrow(channelId, eg.t(topic)), expected: false);
    doTest(narrow: StarredMessagesNarrow(),             expected: true);
    doTest(narrow: MentionsNarrow(),                    expected: true);
  });

  test('showSender is maintained correctly', () => awaitFakeAsync((async) async {
    // TODO(#150): This will get more complicated with message moves.
    // Until then, we always compute this sequentially from oldest to newest.
    // So we just need to exercise the different cases of the logic for
    // whether the sender should be shown, but the difference between
    // fetchInitial and handleMessageEvent etc. doesn't matter.

    // Elapse test's clock to a specific time, to avoid any flaky-ness
    // that may be caused by a specific local time of the day.
    final initialTime = DateTime(2035, 8, 21);
    async.elapse(initialTime.difference(clock.now()));

    final now = clock.now();
    final t1 = eg.utcTimestamp(now.subtract(Duration(days: 1)));
    final t2 = t1 + Duration(minutes: 1).inSeconds;
    final t3 = t2 + Duration(minutes: 10, seconds: 1).inSeconds;
    final t4 = eg.utcTimestamp(now);
    final stream = eg.stream(streamId: eg.defaultStreamMessageStreamId);
    Message streamMessage(int timestamp, User sender) =>
      eg.streamMessage(sender: sender,
        stream: stream, topic: 'foo', timestamp: timestamp);
    Message dmMessage(int timestamp, User sender) =>
      eg.dmMessage(from: sender, timestamp: timestamp,
        to: [sender.userId == eg.selfUser.userId ? eg.otherUser : eg.selfUser]);
    DmDestination dmDestination(List<User> users) =>
      DmDestination(userIds: users.map((user) => user.userId).toList());

    await prepare();
    await prepareMessages(foundOldest: true, messages: [
      streamMessage(t1, eg.selfUser),  // first message, so show sender
      streamMessage(t1, eg.selfUser),  // hide sender
      streamMessage(t1, eg.otherUser), // no recipient header, but new sender
      streamMessage(t2, eg.otherUser), // same sender, and within 10 mins of last message
      streamMessage(t3, eg.otherUser), // same sender, but after 10 mins from last message
      dmMessage(    t3, eg.otherUser), // same sender, but new recipient
      dmMessage(    t4, eg.otherUser), // same sender/recipient, but new day
    ]);
    await prepareOutboxMessagesTo([
      dmDestination([eg.selfUser, eg.otherUser]), // same day, but new sender
      dmDestination([eg.selfUser, eg.otherUser]), // hide sender
    ]);
    assert(
      store.outboxMessages.values.every((message) => message.timestamp == t4));
    async.elapse(kLocalEchoDebounceDuration);

    // We check showSender has the right values in [checkInvariants],
    // but to make this test explicit:
    check(model.items).deepEquals(<void Function(Subject<Object?>)>[
      (it) => it.isA<MessageListRecipientHeaderItem>(),
      (it) => it.isA<MessageListMessageItem>().showSender.isTrue(),
      (it) => it.isA<MessageListMessageItem>().showSender.isFalse(),
      (it) => it.isA<MessageListMessageItem>().showSender.isTrue(),
      (it) => it.isA<MessageListMessageItem>().showSender.isFalse(),
      (it) => it.isA<MessageListMessageItem>().showSender.isTrue(),
      (it) => it.isA<MessageListRecipientHeaderItem>(),
      (it) => it.isA<MessageListMessageItem>().showSender.isTrue(),
      (it) => it.isA<MessageListDateSeparatorItem>(),
      (it) => it.isA<MessageListMessageItem>().showSender.isTrue(),
      (it) => it.isA<MessageListOutboxMessageItem>().showSender.isTrue(),
      (it) => it.isA<MessageListOutboxMessageItem>().showSender.isFalse(),
    ]);
  }));

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

    group('topics compared case-insensitively', () {
      void doTest(String description, String topicA, String topicB, bool expected) {
        test(description, () {
          final stream = eg.stream();
          final messageA = eg.streamMessage(stream: stream, topic: topicA);
          final messageB = eg.streamMessage(stream: stream, topic: topicB);
          check(haveSameRecipient(messageA, messageB)).equals(expected);
        });
      }

      doTest('same case, all lower',               'abc',  'abc',  true);
      doTest('same case, all upper',               'ABC',  'ABC',  true);
      doTest('same case, mixed',                   'AbC',  'AbC',  true);
      doTest('same non-cased chars',               '嗎',    '嗎',    true);
      doTest('different case',                     'aBc',  'ABC',  true);
      doTest('different case, same diacritics',    'AbÇ',  'aBç',  true);
      doTest('same letters, different diacritics', 'ma',   'mǎ',   false);
      doTest('having different CJK characters',    '嗎', '馬', false);
    });

    test('outbox messages', () {
      final stream = eg.stream();
      final streamMessage1 = eg.streamOutboxMessage(stream: stream, topic: 'foo');
      final streamMessage2 = eg.streamOutboxMessage(stream: stream, topic: 'bar');
      final dmMessage = eg.dmOutboxMessage(from: eg.selfUser, to: [eg.otherUser]);
      check(haveSameRecipient(streamMessage1, streamMessage1)).isTrue();
      check(haveSameRecipient(streamMessage1, streamMessage2)).isFalse();
      check(haveSameRecipient(streamMessage1, dmMessage)).isFalse();
    });
  });

  // These timestamps will differ depending on the timezone of the
  // environment where the tests are run, in order to give the same results
  // in the code under test which is also based on the ambient timezone.
  // TODO(dart): It'd be great if tests could control the ambient timezone,
  //   so as to exercise cases like where local time falls back across midnight.
  int timestampFromLocalTime(String date) => DateTime.parse(date).millisecondsSinceEpoch ~/ 1000;

  test('messagesSameDay', () {
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
            check(because: 'times $time0, $time1', messagesSameDay(
              eg.streamOutboxMessage(timestamp: timestampFromLocalTime(time0)),
              eg.streamOutboxMessage(timestamp: timestampFromLocalTime(time1)),
            )).equals(i0 == i1);
            check(because: 'times $time0, $time1', messagesSameDay(
              eg.dmOutboxMessage(from: eg.selfUser, to: [], timestamp: timestampFromLocalTime(time0)),
              eg.dmOutboxMessage(from: eg.selfUser, to: [], timestamp: timestampFromLocalTime(time1)),
            )).equals(i0 == i1);
          }
        }
      }
    }
  });

  group('messagesCloseInTime', () {
    final stream = eg.stream();
    void doTest(String time0, String time1, bool expected) {
      test('$time0 vs $time1 -> $expected', () {
        check(messagesCloseInTime(
          eg.streamMessage(stream: stream, topic: 'foo', timestamp: timestampFromLocalTime(time0)),
          eg.streamMessage(stream: stream, topic: 'foo', timestamp: timestampFromLocalTime(time1)),
        )).equals(expected);
        check(messagesCloseInTime(
          eg.dmMessage(from: eg.selfUser, to: [], timestamp: timestampFromLocalTime(time0)),
          eg.dmMessage(from: eg.selfUser, to: [], timestamp: timestampFromLocalTime(time1)),
        )).equals(expected);
        check(messagesCloseInTime(
          eg.streamOutboxMessage(timestamp: timestampFromLocalTime(time0)),
          eg.streamOutboxMessage(timestamp: timestampFromLocalTime(time1)),
        )).equals(expected);
        check(messagesCloseInTime(
          eg.dmOutboxMessage(from: eg.selfUser, to: [], timestamp: timestampFromLocalTime(time0)),
          eg.dmOutboxMessage(from: eg.selfUser, to: [], timestamp: timestampFromLocalTime(time1)),
        )).equals(expected);
      });
    }

    const time = '2021-01-01 00:30:00';

    doTest('2021-01-01 00:19:59', time, false);
    doTest('2021-01-01 00:20:00', time, true);
    doTest('2021-01-01 00:29:59', time, true);
    doTest('2021-01-01 00:30:00', time, true);

    doTest(time, '2021-01-01 00:30:01', true);
    doTest(time, '2021-01-01 00:39:59', true);
    doTest(time, '2021-01-01 00:40:00', true);
    doTest(time, '2021-01-01 00:40:01', false);

    doTest(time, '2022-01-01 00:30:00', false);
    doTest(time, '2021-02-01 00:30:00', false);
    doTest(time, '2021-01-02 00:30:00', false);
    doTest(time, '2021-01-01 01:30:00', false);
  });
}

MessageListView? _lastModel;
List<Message>? _lastMessages;
int? _lastMiddleMessage;

void checkInvariants(MessageListView model) {
  if (!model.initialFetched) {
    check(model)
      ..messages.isEmpty()
      ..outboxMessages.isEmpty()
      ..oldMessageId.isNull()
      ..newMessageId.isNull()
      ..haveOldest.isFalse()
      ..haveNewest.isFalse()
      ..busyFetchingOlder.isFalse()
      ..busyFetchingNewer.isFalse();
  }
  if (model.haveOldest && model.haveNewest) {
    check(model)..busyFetchingOlder.isFalse()..busyFetchingNewer.isFalse();
  }

  for (final message in model.messages) {
    check(model.store.messages)[message.id].isNotNull().identicalTo(message);
  }
  if (model.outboxMessages.isNotEmpty) {
    check(model.haveNewest).isTrue();
  }
  for (final message in model.outboxMessages) {
    check(message).hidden.isFalse();
    check(model.store.outboxMessages)[message.localMessageId].isNotNull().identicalTo(message);
  }

  final allMessages = [...model.messages, ...model.outboxMessages];

  for (final message in allMessages) {
    check(model.narrow.containsMessage(message)).anyOf(<Condition<bool?>>[
      (it) => it.isNull(),
      (it) => it.isNotNull().isTrue(),
    ]);

    if (message is MessageBase<StreamConversation>) {
      final conversation = message.conversation;
      switch (model.narrow) {
        case CombinedFeedNarrow():
          check(model.store.isTopicVisible(conversation.streamId, conversation.topic))
            .isTrue();
        case ChannelNarrow():
          check(model.store.isTopicVisibleInStream(conversation.streamId, conversation.topic))
            .isTrue();
        case TopicNarrow():
        case DmNarrow():
        case MentionsNarrow():
        case StarredMessagesNarrow():
        case KeywordSearchNarrow():
      }
    } else if (message is DmMessage) {
      final narrow = DmNarrow.ofMessage(message, selfUserId: model.store.selfUserId);
      switch (model.narrow) {
        case CombinedFeedNarrow():
        case MentionsNarrow():
        case StarredMessagesNarrow():
        case KeywordSearchNarrow():
          check(model.store.shouldMuteDmConversation(narrow)).isFalse();
        case ChannelNarrow():
        case TopicNarrow():
        case DmNarrow():
      }
    }
  }

  check(isSortedWithoutDuplicates(model.messages.map((m) => m.id).toList()))
    .isTrue();
  check(isSortedWithoutDuplicates(model.outboxMessages.map((m) => m.localMessageId).toList()))
    .isTrue();

  check(model).middleMessage
    ..isGreaterOrEqual(0)
    ..isLessOrEqual(model.messages.length);

  if (identical(model, _lastModel)
      && model.generation == _lastModel!.generation) {
    // All messages that were present, and still are, should be on the same side
    // of `middleMessage` (still top or bottom slice respectively) as they were.
    _checkNoIntersection(ListSlice(model.messages, 0, model.middleMessage),
      ListSlice(_lastMessages!, _lastMiddleMessage!, _lastMessages!.length),
      because: 'messages moved from bottom slice to top slice');
    _checkNoIntersection(ListSlice(_lastMessages!, 0, _lastMiddleMessage!),
      ListSlice(model.messages, model.middleMessage, model.messages.length),
      because: 'messages moved from top slice to bottom slice');
  }
  _lastModel = model;
  _lastMessages = model.messages.toList();
  _lastMiddleMessage = model.middleMessage;

  check(model).contents.length.equals(model.messages.length);
  for (int i = 0; i < model.contents.length; i++) {
    final poll = model.messages[i].poll;
    if (poll != null) {
      check(model).contents[i].isA<PollContent>().poll.identicalTo(poll);
      continue;
    }
    check(model.contents[i]).isA<ZulipContent>()
      .equalsNode(parseContent(model.messages[i].content));
  }

  int i = 0;
  for (int j = 0; j < allMessages.length; j++) {
    final bool showSender;
    if (j == 0
        || model.oneMessagePerBlock
        || !haveSameRecipient(allMessages[j-1], allMessages[j])) {
      check(model.items[i++]).isA<MessageListRecipientHeaderItem>()
        .message.identicalTo(allMessages[j]);
      showSender = true;
    } else if (!messagesSameDay(allMessages[j-1], allMessages[j])) {
      check(model.items[i++]).isA<MessageListDateSeparatorItem>()
        .message.identicalTo(allMessages[j]);
      showSender = true;
    } else if (allMessages[j-1].senderId == allMessages[j].senderId) {
      showSender = !messagesCloseInTime(allMessages[j-1], allMessages[j]);
    } else {
      showSender = true;
    }
    if (j < model.messages.length) {
      check(model.items[i]).isA<MessageListMessageItem>()
        ..message.identicalTo(model.messages[j])
        ..content.identicalTo(model.contents[j]);
    } else {
      check(model.items[i]).isA<MessageListOutboxMessageItem>()
        .message.identicalTo(model.outboxMessages[j-model.messages.length]);
    }
    check(model.items[i++]).isA<MessageListMessageBaseItem>()
      ..showSender.equals(showSender)
      ..isLastInBlock.equals(
        i == model.items.length || switch (model.items[i]) {
          MessageListMessageItem()
          || MessageListOutboxMessageItem()
          || MessageListDateSeparatorItem() => false,
          MessageListRecipientHeaderItem()  => true,
        });
  }
  check(model.items).length.equals(i);

  check(model).middleItem
    ..isGreaterOrEqual(0)
    ..isLessOrEqual(model.items.length);
  if (model.middleMessage == model.messages.length) {
    if (model.outboxMessages.isEmpty) {
      // the bottom slice of `model.messages` is empty
      check(model).middleItem.equals(model.items.length);
    } else {
      check(model.items[model.middleItem]).isA<MessageListOutboxMessageItem>()
        .message.identicalTo(model.outboxMessages.first);
    }
  } else {
    check(model.items[model.middleItem]).isA<MessageListMessageItem>()
      .message.identicalTo(model.messages[model.middleMessage]);
  }
}

void _checkNoIntersection(List<Message> xs, List<Message> ys, {String? because}) {
  // Both lists are sorted by ID.  As an optimization, bet on all or nearly all
  // of the first list having smaller IDs than all or nearly all of the other.
  if (xs.isEmpty || ys.isEmpty) return;
  if (xs.last.id < ys.first.id) return;
  final yCandidates = Set.of(ys.takeWhile((m) => m.id <= xs.last.id));
  final intersection = xs.reversed.takeWhile((m) => ys.first.id <= m.id)
    .where(yCandidates.contains);
  check(intersection, because: because).isEmpty();
}

extension MessageListRecipientHeaderItemChecks on Subject<MessageListRecipientHeaderItem> {
  Subject<MessageBase> get message => has((x) => x.message, 'message');
}

extension MessageListDateSeparatorItemChecks on Subject<MessageListDateSeparatorItem> {
  Subject<MessageBase> get message => has((x) => x.message, 'message');
}

extension MessageListMessageBaseItemChecks on Subject<MessageListMessageBaseItem> {
  Subject<MessageBase> get message => has((x) => x.message, 'message');
  Subject<ZulipMessageContent> get content => has((x) => x.content, 'content');
  Subject<bool> get showSender => has((x) => x.showSender, 'showSender');
  Subject<bool> get isLastInBlock => has((x) => x.isLastInBlock, 'isLastInBlock');
}

extension MessageListMessageItemChecks on Subject<MessageListMessageItem> {
  Subject<Message> get message => has((x) => x.message, 'message');
}

extension MessageListViewChecks on Subject<MessageListView> {
  Subject<PerAccountStore> get store => has((x) => x.store, 'store');
  Subject<Narrow> get narrow => has((x) => x.narrow, 'narrow');
  Subject<Anchor> get anchor => has((x) => x.anchor, 'anchor');
  Subject<List<Message>> get messages => has((x) => x.messages, 'messages');
  Subject<List<OutboxMessage>> get outboxMessages => has((x) => x.outboxMessages, 'outboxMessages');
  Subject<int> get middleMessage => has((x) => x.middleMessage, 'middleMessage');
  Subject<List<ZulipMessageContent>> get contents => has((x) => x.contents, 'contents');
  Subject<List<MessageListItem>> get items => has((x) => x.items, 'items');
  Subject<int> get middleItem => has((x) => x.middleItem, 'middleItem');
  Subject<bool> get initialFetched => has((x) => x.initialFetched, 'initialFetched');
  Subject<int?> get oldMessageId => has((x) => x.oldMessageId, 'oldMessageId');
  Subject<int?> get newMessageId => has((x) => x.newMessageId, 'newMessageId');
  Subject<bool> get haveOldest => has((x) => x.haveOldest, 'haveOldest');
  Subject<bool> get haveNewest => has((x) => x.haveNewest, 'haveNewest');
  Subject<bool> get busyFetchingOlder => has((x) => x.busyFetchingOlder, 'busyFetchingOlder');
  Subject<bool> get busyFetchingNewer => has((x) => x.busyFetchingNewer, 'busyFetchingNewer');
}
