import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/narrow.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/content.dart';
import 'package:zulip/model/message_list.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';

import '../api/fake_api.dart';
import '../api/model/model_checks.dart';
import '../example_data.dart' as eg;
import '../stdlib_checks.dart';
import 'content_checks.dart';
import 'test_store.dart';

void main() async {
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
  void checkNotNotified() => checkNotified(count: 0);
  void checkNotifiedOnce() => checkNotified(count: 1);

  /// Initialize [model] and the rest of the test state.
  Future<void> prepare({Narrow narrow = const CombinedFeedNarrow()}) async {
    final stream = eg.stream();
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
    checkInvariants(model);
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
    checkInvariants(model);

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
    checkInvariants(model);
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
    checkInvariants(model);
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

  test('maybeAddMessage', () async {
    final stream = eg.stream();
    await prepare(narrow: StreamNarrow(stream.streamId));
    await prepareMessages(foundOldest: true, messages:
      List.generate(30, (i) => eg.streamMessage(stream: stream)));

    check(model).messages.length.equals(30);
    model.maybeAddMessage(eg.streamMessage(stream: stream));
    checkNotifiedOnce();
    check(model).messages.length.equals(31);
  });

  test('maybeAddMessage, not in narrow', () async {
    final stream = eg.stream(streamId: 123);
    await prepare(narrow: StreamNarrow(stream.streamId));
    await prepareMessages(foundOldest: true, messages:
      List.generate(30, (i) => eg.streamMessage(stream: stream)));

    check(model).messages.length.equals(30);
    final otherStream = eg.stream(streamId: 234);
    model.maybeAddMessage(eg.streamMessage(stream: otherStream));
    checkNotNotified();
    check(model).messages.length.equals(30);
  });

  test('maybeAddMessage, before fetch', () async {
    final stream = eg.stream();
    await prepare(narrow: StreamNarrow(stream.streamId));
    model.maybeAddMessage(eg.streamMessage(stream: stream));
    checkNotNotified();
    check(model).fetched.isFalse();
    checkInvariants(model);
  });

  group('maybeUpdateMessage', () {
    test('update a message', () async {
      final originalMessage = eg.streamMessage(
        content: "<p>Hello, world</p>");
      final updateEvent = eg.updateMessageEditEvent(originalMessage,
        flags: [MessageFlag.starred],
        renderedContent: "<p>Hello, edited</p>",
        editTimestamp: 99999,
        isMeMessage: true,
      );
      await prepare();
      await prepareMessages(foundOldest: true, messages: [originalMessage]);

      final message = model.messages.single;
      check(message)
        ..content.not((it) => it.equals(updateEvent.renderedContent!))
        ..lastEditTimestamp.isNull()
        ..flags.not((it) => it.deepEquals(updateEvent.flags))
        ..isMeMessage.not((it) => it.equals(updateEvent.isMeMessage!));

      model.maybeUpdateMessage(updateEvent);
      checkNotifiedOnce();
      check(model).messages.single
        ..identicalTo(message)
        ..content.equals(updateEvent.renderedContent!)
        ..lastEditTimestamp.equals(updateEvent.editTimestamp)
        ..flags.equals(updateEvent.flags)
        ..isMeMessage.equals(updateEvent.isMeMessage!);
    });

    test('ignore when message not present', () async {
      final originalMessage = eg.streamMessage(
        content: "<p>Hello, world</p>");
      final updateEvent = eg.updateMessageEditEvent(originalMessage,
        messageId: originalMessage.id + 1,
        renderedContent: "<p>Hello, edited</p>",
      );
      await prepare();
      await prepareMessages(foundOldest: true, messages: [originalMessage]);

      model.maybeUpdateMessage(updateEvent);
      checkNotNotified();
      check(model).messages.single
        ..content.equals(originalMessage.content)
        ..content.not((it) => it.equals(updateEvent.renderedContent!));
    });

    // TODO(server-5): Cut legacy case for rendering-only message update
    Future<void> checkRenderingOnly({required bool legacy}) async {
      final originalMessage = eg.streamMessage(
        lastEditTimestamp: 78492,
        content: "<p>Hello, world</p>");
      final updateEvent = eg.updateMessageEditEvent(originalMessage,
        renderedContent: "<p>Hello, world</p> <div>Some link preview</div>",
        editTimestamp: 99999,
        renderingOnly: legacy ? null : true,
        userId: null,
      );
      await prepare();
      await prepareMessages(foundOldest: true, messages: [originalMessage]);
      final message = model.messages.single;

      model.maybeUpdateMessage(updateEvent);
      checkNotifiedOnce();
      check(model).messages.single
        ..identicalTo(message)
        // Content is updated...
        ..content.equals(updateEvent.renderedContent!)
        // ... edit timestamp is not.
        ..lastEditTimestamp.equals(originalMessage.lastEditTimestamp)
        ..lastEditTimestamp.not((it) => it.equals(updateEvent.editTimestamp));
    }

    test('rendering-only update does not change timestamp', () async {
      await checkRenderingOnly(legacy: false);
    });

    test('rendering-only update does not change timestamp (for old server versions)', () async {
      await checkRenderingOnly(legacy: true);
    });

    group('ReactionEvent handling', () {
      ReactionEvent mkEvent(Reaction reaction, ReactionOp op, int messageId) {
        return ReactionEvent(
          id: 1,
          op: op,
          emojiName: reaction.emojiName,
          emojiCode: reaction.emojiCode,
          reactionType: reaction.reactionType,
          userId: reaction.userId,
          messageId: messageId,
        );
      }

      test('add reaction', () async {
        final originalMessage = eg.streamMessage(reactions: []);
        await prepare();
        await prepareMessages(foundOldest: true, messages: [originalMessage]);
        final message = model.messages.single;

        model.maybeUpdateMessageReactions(
          mkEvent(eg.unicodeEmojiReaction, ReactionOp.add, originalMessage.id));
        checkNotifiedOnce();
        check(model).messages.single
          ..identicalTo(message)
          ..reactions.isNotNull().jsonEquals([eg.unicodeEmojiReaction]);
      });

      test('add reaction; message is not in list', () async {
        final someMessage = eg.streamMessage(reactions: []);
        await prepare();
        await prepareMessages(foundOldest: true, messages: [someMessage]);
        model.maybeUpdateMessageReactions(
          mkEvent(eg.unicodeEmojiReaction, ReactionOp.add, 1000));
        checkNotNotified();
        check(model).messages.single.reactions.isNull();
      });

      test('remove reaction', () async {
        final eventReaction = Reaction(reactionType: ReactionType.unicodeEmoji,
          emojiName: 'wave',          emojiCode: '1f44b', userId: 1);

        // Same emoji, different user. Not to be removed.
        final reaction2 = Reaction(reactionType: ReactionType.unicodeEmoji,
          emojiName: 'wave',          emojiCode: '1f44b', userId: 2);

        // Same user, different emoji. Not to be removed.
        final reaction3 = Reaction(reactionType: ReactionType.unicodeEmoji,
          emojiName: 'working_on_it', emojiCode: '1f6e0', userId: 1);

        // Same user, same emojiCode, different emojiName. To be removed: servers
        // key on user, message, reaction type, and emoji code, but not emoji name.
        // So we mimic that behavior; see discussion:
        //   https://github.com/zulip/zulip-flutter/pull/256#discussion_r1284865099
        final reaction4 = Reaction(reactionType: ReactionType.unicodeEmoji,
          emojiName: 'hello',         emojiCode: '1f44b', userId: 1);

        final originalMessage = eg.streamMessage(
          reactions: [reaction2, reaction3, reaction4]);
        await prepare();
        await prepareMessages(foundOldest: true, messages: [originalMessage]);
        final message = model.messages.single;

        model.maybeUpdateMessageReactions(
          mkEvent(eventReaction, ReactionOp.remove, originalMessage.id));
        checkNotifiedOnce();
        check(model).messages.single
          ..identicalTo(message)
          ..reactions.isNotNull().jsonEquals([reaction2, reaction3]);
      });

      test('remove reaction; message is not in list', () async {
        final someMessage = eg.streamMessage(reactions: [eg.unicodeEmojiReaction]);
        await prepare();
        await prepareMessages(foundOldest: true, messages: [someMessage]);
        model.maybeUpdateMessageReactions(
          mkEvent(eg.unicodeEmojiReaction, ReactionOp.remove, 1000));
        checkNotNotified();
        check(model).messages.single.reactions.isNotNull().jsonEquals([eg.unicodeEmojiReaction]);
      });
    });
  });

  group('maybeUpdateMessageFlags', () {
    UpdateMessageFlagsAddEvent mkAddEvent(
      MessageFlag flag,
      List<int> messageIds, {
      bool all = false,
    }) {
      return UpdateMessageFlagsAddEvent(
        id: 1,
        flag: flag,
        messages: messageIds,
        all: all,
      );
    }

    const mkRemoveEvent = eg.updateMessageFlagsRemoveEvent;

    group('add flag', () {
      test('not in list', () async {
        await prepare();
        final message = eg.streamMessage(flags: []);
        await prepareMessages(foundOldest: true, messages: [message]);
        model.maybeUpdateMessageFlags(mkAddEvent(MessageFlag.read, [2]));
        checkNotNotified();
        check(model).messages.single.flags.deepEquals([]);
      });

      test('affected message, unaffected message, absent message', () async {
        await prepare();
        final message1 = eg.streamMessage(flags: []);
        final message2 = eg.streamMessage(flags: []);
        await prepareMessages(foundOldest: true, messages: [message1, message2]);
        model.maybeUpdateMessageFlags(mkAddEvent(MessageFlag.read, [message2.id, 3]));
        checkNotifiedOnce();
        check(model).messages
          ..[0].flags.deepEquals([])
          ..[1].flags.deepEquals([MessageFlag.read]);
      });

      test('all: true, list non-empty', () async {
        await prepare();
        final message1 = eg.streamMessage(flags: []);
        final message2 = eg.streamMessage(flags: []);
        await prepareMessages(foundOldest: true, messages: [message1, message2]);
        model.maybeUpdateMessageFlags(mkAddEvent(MessageFlag.read, [], all: true));
        checkNotifiedOnce();
        check(model).messages
          ..[0].flags.deepEquals([MessageFlag.read])
          ..[1].flags.deepEquals([MessageFlag.read]);
      });

      test('all: true, list empty', () async {
        await prepare();
        await prepareMessages(foundOldest: true, messages: []);
        model.maybeUpdateMessageFlags(mkAddEvent(MessageFlag.read, [], all: true));
        checkNotNotified();
      });

      test('other flags not clobbered', () async {
        final message = eg.streamMessage(flags: [MessageFlag.starred]);
        await prepare();
        await prepareMessages(foundOldest: true, messages: [message]);
        model.maybeUpdateMessageFlags(mkAddEvent(MessageFlag.read, [message.id]));
        checkNotifiedOnce();
        check(model).messages.single.flags.deepEquals([MessageFlag.starred, MessageFlag.read]);
      });
    });

    group('remove flag', () {
      test('not in list', () async {
        await prepare();
        final message = eg.streamMessage(flags: [MessageFlag.read]);
        await prepareMessages(foundOldest: true, messages: [message]);
        model.maybeUpdateMessageFlags(mkAddEvent(MessageFlag.read, [2]));
        checkNotNotified();
        check(model).messages.single.flags.deepEquals([MessageFlag.read]);
      });

      test('affected message, unaffected message, absent message', () async {
        await prepare();
        final message1 = eg.streamMessage(flags: [MessageFlag.read]);
        final message2 = eg.streamMessage(flags: [MessageFlag.read]);
        final message3 = eg.streamMessage(flags: [MessageFlag.read]);
        await prepareMessages(foundOldest: true, messages: [message1, message2]);
        model.maybeUpdateMessageFlags(mkRemoveEvent(MessageFlag.read, [message2, message3]));
        checkNotifiedOnce();
        check(model).messages
          ..[0].flags.deepEquals([MessageFlag.read])
          ..[1].flags.deepEquals([]);
      });

      test('other flags not affected', () async {
        final message = eg.streamMessage(flags: [MessageFlag.starred, MessageFlag.read]);
        await prepare();
        await prepareMessages(foundOldest: true, messages: [message]);
        model.maybeUpdateMessageFlags(mkRemoveEvent(MessageFlag.read, [message]));
        checkNotifiedOnce();
        check(model).messages.single.flags.deepEquals([MessageFlag.starred]);
      });
    });
  });

  test('reassemble', () async {
    final stream = eg.stream();
    await prepare(narrow: StreamNarrow(stream.streamId));
    await prepareMessages(foundOldest: true, messages:
      List.generate(30, (i) => eg.streamMessage(stream: stream)));
    model.maybeAddMessage(eg.streamMessage(stream: stream));
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
      final stream1 = eg.stream(streamId: 1, name: 'stream 1');
      final stream2 = eg.stream(streamId: 2, name: 'stream 2');
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

      // … and on maybeAddMessage.
      model.maybeAddMessage(eg.streamMessage(id: 301, stream: stream1, topic: 'A'));
      checkNotifiedOnce();
      check(model.messages.map((m) => m.id)).deepEquals(expected..add(301));

      model.maybeAddMessage(eg.streamMessage(id: 302, stream: stream1, topic: 'B'));
      checkNotNotified();
      check(model.messages.map((m) => m.id)).deepEquals(expected);

      model.maybeAddMessage(eg.streamMessage(id: 303, stream: stream2, topic: 'C'));
      checkNotifiedOnce();
      check(model.messages.map((m) => m.id)).deepEquals(expected..add(303));

      model.maybeAddMessage(eg.streamMessage(id: 304, stream: stream2, topic: 'D'));
      checkNotNotified();
      check(model.messages.map((m) => m.id)).deepEquals(expected);

      model.maybeAddMessage(eg.dmMessage(id: 305, from: eg.otherUser, to: [eg.selfUser]));
      checkNotifiedOnce();
      check(model.messages.map((m) => m.id)).deepEquals(expected..add(305));
    });

    test('in StreamNarrow', () async {
      final stream = eg.stream(streamId: 1, name: 'stream 1');
      await prepare(narrow: StreamNarrow(stream.streamId));
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

      // … and on maybeAddMessage.
      model.maybeAddMessage(eg.streamMessage(id: 301, stream: stream, topic: 'A'));
      checkNotifiedOnce();
      check(model.messages.map((m) => m.id)).deepEquals(expected..add(301));

      model.maybeAddMessage(eg.streamMessage(id: 302, stream: stream, topic: 'B'));
      checkNotifiedOnce();
      check(model.messages.map((m) => m.id)).deepEquals(expected..add(302));

      model.maybeAddMessage(eg.streamMessage(id: 303, stream: stream, topic: 'C'));
      checkNotNotified();
      check(model.messages.map((m) => m.id)).deepEquals(expected);
    });

    test('in TopicNarrow', () async {
      final stream = eg.stream(streamId: 1, name: 'stream 1');
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

      // … and on maybeAddMessage.
      model.maybeAddMessage(eg.streamMessage(id: 301, stream: stream, topic: 'A'));
      checkNotifiedOnce();
      check(model.messages.map((m) => m.id)).deepEquals(expected..add(301));
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
    final stream = eg.stream();
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

    // Then test maybeAddMessage, where a new header is needed…
    model.maybeAddMessage(streamMessage(13));
    checkNotifiedOnce();

    // … and where it's not.
    model.maybeAddMessage(streamMessage(14));
    checkNotifiedOnce();

    // Then test maybeUpdateMessage, where a header is and remains needed…
    UpdateMessageEvent updateEvent(Message message) => eg.updateMessageEditEvent(
      message, renderedContent: '${message.content}<p>edited</p>',
    );
    model.maybeUpdateMessage(updateEvent(model.messages.first));
    checkNotifiedOnce();
    model.maybeUpdateMessage(updateEvent(model.messages[model.messages.length - 2]));
    checkNotifiedOnce();

    // … and where it's not.
    model.maybeUpdateMessage(updateEvent(model.messages.last));
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
    // fetchInitial and maybeAddMessage etc. doesn't matter.

    const t1 = 1693602618;
    const t2 = t1 + 86400;
    final stream = eg.stream();
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
      final stream0 = eg.stream(streamId: 123);
      final stream1 = eg.stream(streamId: 234);
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
    check(model.narrow.containsMessage(message)).isTrue();

    if (message is! StreamMessage) continue;
    switch (model.narrow) {
      case CombinedFeedNarrow():
        check(model.store.isTopicVisible(message.streamId, message.subject))
          .isTrue();
      case StreamNarrow():
        check(model.store.isTopicVisibleInStream(message.streamId, message.subject))
          .isTrue();
      case TopicNarrow():
      case DmNarrow():
    }
  }

  for (int i = 0; i < model.messages.length - 1; i++) {
    check(model.messages[i].id).isLessThan(model.messages[i+1].id);
  }

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
