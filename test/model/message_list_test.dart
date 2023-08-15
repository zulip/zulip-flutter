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

void main() async {
  // These variables are the common state operated on by each test.
  // Each test case calls [prepare] to initialize them.
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
  void prepare({Narrow narrow = const AllMessagesNarrow()}) {
    store = eg.store();
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
    const narrow = AllMessagesNarrow();
    prepare(narrow: narrow);
    connection.prepare(json: newestResult(
      foundOldest: false,
      messages: List.generate(kMessageListFetchBatchSize,
        (i) => eg.streamMessage(id: 1000 + i)),
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
    prepare();
    connection.prepare(json: newestResult(
      foundOldest: true,
      messages: List.generate(30, (i) => eg.streamMessage(id: 1000 + i)),
    ).toJson());
    await model.fetchInitial();
    checkNotifiedOnce();
    check(model)
      ..messages.length.equals(30)
      ..haveOldest.isTrue();
  });

  test('fetchInitial, no messages found', () async {
    prepare();
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
    const narrow = AllMessagesNarrow();
    prepare(narrow: narrow);
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
    const narrow = AllMessagesNarrow();
    prepare(narrow: narrow);
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
    prepare(narrow: const AllMessagesNarrow());
    await prepareMessages(foundOldest: true, messages:
      List.generate(30, (i) => eg.streamMessage(id: 1000 + i)));
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
    const narrow = AllMessagesNarrow();
    prepare(narrow: narrow);
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
    prepare(narrow: StreamNarrow(stream.streamId));
    await prepareMessages(foundOldest: true, messages:
      List.generate(30, (i) => eg.streamMessage(id: 1000 + i, stream: stream)));

    check(model).messages.length.equals(30);
    model.maybeAddMessage(eg.streamMessage(id: 1100, stream: stream));
    checkNotifiedOnce();
    check(model).messages.length.equals(31);
  });

  test('maybeAddMessage, not in narrow', () async {
    final stream = eg.stream(streamId: 123);
    prepare(narrow: StreamNarrow(stream.streamId));
    await prepareMessages(foundOldest: true, messages:
      List.generate(30, (i) => eg.streamMessage(id: 1000 + i, stream: stream)));

    check(model).messages.length.equals(30);
    final otherStream = eg.stream(streamId: 234);
    model.maybeAddMessage(eg.streamMessage(id: 1100, stream: otherStream));
    checkNotNotified();
    check(model).messages.length.equals(30);
  });

  test('maybeAddMessage, before fetch', () async {
    final stream = eg.stream();
    prepare(narrow: StreamNarrow(stream.streamId));
    model.maybeAddMessage(eg.streamMessage(id: 1100, stream: stream));
    checkNotNotified();
    check(model).fetched.isFalse();
    checkInvariants(model);
  });

  group('maybeUpdateMessage', () {
    test('update a message', () async {
      final originalMessage = eg.streamMessage(id: 243,
        content: "<p>Hello, world</p>");
      final updateEvent = UpdateMessageEvent(
        id: 1,
        messageId: originalMessage.id,
        messageIds: [originalMessage.id],
        flags: ["starred"],
        renderedContent: "<p>Hello, edited</p>",
        editTimestamp: 99999,
        isMeMessage: true,
        userId: 1,
        renderingOnly: false,
      );
      prepare();
      await prepareMessages(foundOldest: true, messages: [originalMessage]);

      final message = model.messages.single;
      check(message)
        ..content.not(it()..equals(updateEvent.renderedContent!))
        ..lastEditTimestamp.isNull()
        ..flags.not(it()..deepEquals(updateEvent.flags))
        ..isMeMessage.not(it()..equals(updateEvent.isMeMessage!));

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
      final originalMessage = eg.streamMessage(id: 243,
        content: "<p>Hello, world</p>");
      final updateEvent = UpdateMessageEvent(
        id: 1,
        messageId: originalMessage.id + 1,
        messageIds: [originalMessage.id + 1],
        flags: originalMessage.flags,
        renderedContent: "<p>Hello, edited</p>",
        editTimestamp: 99999,
        userId: 1,
        renderingOnly: false,
      );
      prepare();
      await prepareMessages(foundOldest: true, messages: [originalMessage]);

      model.maybeUpdateMessage(updateEvent);
      checkNotNotified();
      check(model).messages.single
        ..content.equals(originalMessage.content)
        ..content.not(it()..equals(updateEvent.renderedContent!));
    });

    // TODO(server-5): Cut legacy case for rendering-only message update
    Future<void> checkRenderingOnly({required bool legacy}) async {
      final originalMessage = eg.streamMessage(id: 972,
        lastEditTimestamp: 78492,
        content: "<p>Hello, world</p>");
      final updateEvent = UpdateMessageEvent(
        id: 1,
        messageId: originalMessage.id,
        messageIds: [originalMessage.id],
        flags: originalMessage.flags,
        renderedContent: "<p>Hello, world</p> <div>Some link preview</div>",
        editTimestamp: 99999,
        renderingOnly: legacy ? null : true,
        userId: null,
      );
      prepare();
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
        ..lastEditTimestamp.not(it()..equals(updateEvent.editTimestamp));
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
        prepare();
        await prepareMessages(foundOldest: true, messages: [originalMessage]);
        final message = model.messages.single;

        model.maybeUpdateMessageReactions(
          mkEvent(eg.unicodeEmojiReaction, ReactionOp.add, originalMessage.id));
        checkNotifiedOnce();
        check(model).messages.single
          ..identicalTo(message)
          ..reactions.jsonEquals([eg.unicodeEmojiReaction]);
      });

      test('add reaction; message is not in list', () async {
        final someMessage = eg.streamMessage(id: 1, reactions: []);
        prepare();
        await prepareMessages(foundOldest: true, messages: [someMessage]);
        model.maybeUpdateMessageReactions(
          mkEvent(eg.unicodeEmojiReaction, ReactionOp.add, 1000));
        checkNotNotified();
        check(model).messages.single.reactions.jsonEquals([]);
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
        prepare();
        await prepareMessages(foundOldest: true, messages: [originalMessage]);
        final message = model.messages.single;

        model.maybeUpdateMessageReactions(
          mkEvent(eventReaction, ReactionOp.remove, originalMessage.id));
        checkNotifiedOnce();
        check(model).messages.single
          ..identicalTo(message)
          ..reactions.jsonEquals([reaction2, reaction3]);
      });

      test('remove reaction; message is not in list', () async {
        final someMessage = eg.streamMessage(id: 1, reactions: [eg.unicodeEmojiReaction]);
        prepare();
        await prepareMessages(foundOldest: true, messages: [someMessage]);
        model.maybeUpdateMessageReactions(
          mkEvent(eg.unicodeEmojiReaction, ReactionOp.remove, 1000));
        checkNotNotified();
        check(model).messages.single.reactions.jsonEquals([eg.unicodeEmojiReaction]);
      });
    });
  });

  test('reassemble', () async {
    final stream = eg.stream();
    prepare(narrow: StreamNarrow(stream.streamId));
    await prepareMessages(foundOldest: true, messages:
      List.generate(30, (i) => eg.streamMessage(id: 1000 + i, stream: stream)));
    model.maybeAddMessage(eg.streamMessage(id: 1100, stream: stream));
    checkNotifiedOnce();
    check(model).messages.length.equals(31);

    // Mess with model.contents, to simulate it having come from
    // a previous version of the code.
    final correctContent = parseContent(model.messages[0].content);
    model.contents[0] = const ZulipContent(nodes: [
      ParagraphNode(links: null, nodes: [TextNode('something outdated')])
    ]);
    check(model.contents[0]).not(it()..equalsNode(correctContent));

    model.reassemble();
    checkNotifiedOnce();
    check(model).messages.length.equals(31);
    check(model.contents[0]).equalsNode(correctContent);
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

  for (int i = 0; i < model.messages.length - 1; i++) {
    check(model.messages[i].id).isLessThan(model.messages[i+1].id);
  }

  check(model).contents.length.equals(model.messages.length);
  for (int i = 0; i < model.contents.length; i++) {
    check(model.contents[i])
      .equalsNode(parseContent(model.messages[i].content));
  }

  check(model).items.length.equals(
    ((model.haveOldest || model.fetchingOlder) ? 1 : 0)
    + model.messages.length);
  int i = 0;
  if (model.haveOldest) {
    check(model.items[i++]).isA<MessageListHistoryStartItem>();
  }
  if (model.fetchingOlder) {
    check(model.items[i++]).isA<MessageListLoadingItem>();
  }
  for (int j = 0; j < model.messages.length; j++) {
    check(model.items[i++]).isA<MessageListMessageItem>()
      ..message.identicalTo(model.messages[j])
      ..content.identicalTo(model.contents[j]);
  }
}

extension MessageListMessageItemChecks on Subject<MessageListMessageItem> {
  Subject<Message> get message => has((x) => x.message, 'message');
  Subject<ZulipContent> get content => has((x) => x.content, 'content');
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
