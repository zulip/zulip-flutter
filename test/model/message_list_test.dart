import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/content.dart';
import 'package:zulip/model/message_list.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';

import '../api/fake_api.dart';
import '../api/model/model_checks.dart';
import '../example_data.dart' as eg;
import 'content_checks.dart';

void main() async {
  // These variables are the common state operated on by each test.
  // Each test case calls [prepare] to initialize them.
  late PerAccountStore store;
  late FakeApiConnection connection;
  late MessageListView model;
  late int notifiedCount;

  void checkNotNotified() {
    check(notifiedCount).equals(0);
  }

  void checkNotifiedOnce() {
    check(notifiedCount).equals(1);
    notifiedCount = 0;
  }

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
    await model.fetch();
    checkNotifiedOnce();
  }

  test('findMessageWithId', () async {
    prepare();
    await prepareMessages(foundOldest: true, messages: [
      eg.streamMessage(id: 2),
      eg.streamMessage(id: 4),
      eg.streamMessage(id: 6),
    ]);

    // Exercise the binary search before, at, and after each element of the list.
    check(model.findMessageWithId(1)).equals(-1);
    check(model.findMessageWithId(2)).equals(0);
    check(model.findMessageWithId(3)).equals(-1);
    check(model.findMessageWithId(4)).equals(1);
    check(model.findMessageWithId(5)).equals(-1);
    check(model.findMessageWithId(6)).equals(2);
    check(model.findMessageWithId(7)).equals(-1);
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
          emojiName: 'wave',                  emojiCode: '1f44b', userId: 1);

        // Same emoji, different user. Not to be removed.
        final reaction2 = Reaction.fromJson(eventReaction.toJson()
          ..['user_id'] = 2);

        // Same user, different emoji. Not to be removed.
        final reaction3 = Reaction.fromJson(eventReaction.toJson()
          ..['emoji_code'] = '1f6e0'
          ..['emoji_name'] = 'working_on_it');

        // Same user, same emojiCode, different emojiName. To be removed: servers
        // key on user, message, reaction type, and emoji code, but not emoji name.
        // So we mimic that behavior; see discussion:
        //   https://github.com/zulip/zulip-flutter/pull/256#discussion_r1284865099
        final reaction4 = Reaction.fromJson(eventReaction.toJson()
          ..['emoji_name'] = 'hello');

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
}

void checkInvariants(MessageListView model) {
  if (!model.fetched) {
    check(model).messages.isEmpty();
  }

  for (int i = 0; i < model.messages.length - 1; i++) {
    check(model.messages[i].id).isLessThan(model.messages[i+1].id);
  }

  check(model).contents.length.equals(model.messages.length);
  for (int i = 0; i < model.contents.length; i++) {
    check(model.contents[i])
      .equalsNode(parseContent(model.messages[i].content));
  }
}

extension MessageListViewChecks on Subject<MessageListView> {
  Subject<PerAccountStore> get store => has((x) => x.store, 'store');
  Subject<Narrow> get narrow => has((x) => x.narrow, 'narrow');
  Subject<List<Message>> get messages => has((x) => x.messages, 'messages');
  Subject<List<ZulipContent>> get contents => has((x) => x.contents, 'contents');
  Subject<bool> get fetched => has((x) => x.fetched, 'fetched');
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
