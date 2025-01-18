import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/unreads.dart';

import '../example_data.dart' as eg;
import 'test_store.dart';
import 'unreads_checks.dart';

void main() {
  // These variables are the common state operated on by each test.
  // Each test case calls [prepare] to initialize them.
  late Unreads model;
  late PerAccountStore channelStore; // TODO reduce this to ChannelStore
  late int notifiedCount;

  void checkNotified({required int count}) {
    check(notifiedCount).equals(count);
    notifiedCount = 0;
  }
  void checkNotNotified() => checkNotified(count: 0);
  void checkNotifiedOnce() => checkNotified(count: 1);

  /// Initialize [model] and the rest of the test state.
  void prepare({
    UnreadMessagesSnapshot initial = const UnreadMessagesSnapshot(
      count: 0,
      channels: [],
      dms: [],
      huddles: [],
      mentions: [],
      oldUnreadsMissing: false,
    ),
  }) {
    channelStore = eg.store();
    notifiedCount = 0;
    model = Unreads(initial: initial,
        selfUserId: eg.selfUser.userId, channelStore: channelStore)
      ..addListener(() {
        notifiedCount++;
      });
    checkNotNotified();
  }

  void fillWithMessages(Iterable<Message> messages) {
    for (final message in messages) {
      model.handleMessageEvent(MessageEvent(id: 0, message: message));
    }
    notifiedCount = 0;
  }

  void checkMatchesMessages(Iterable<Message> messages) {
    assert(Set.of(messages.map((m) => m.id)).length == messages.length,
      'checkMatchesMessages: duplicate messages in test input');

    final Map<int, Map<TopicName, QueueList<int>>> expectedStreams = {};
    final Map<DmNarrow, QueueList<int>> expectedDms = {};
    final Set<int> expectedMentions = {};
    for (final message in messages) {
      if (message.flags.contains(MessageFlag.read)) {
        continue;
      }
      switch (message) {
        case StreamMessage():
          final perTopic = expectedStreams[message.streamId] ??= {};
          final messageIds = perTopic[message.topic] ??= QueueList();
          messageIds.add(message.id);
        case DmMessage():
          final narrow = DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId);
          final messageIds = expectedDms[narrow] ??= QueueList();
          messageIds.add(message.id);
      }
      if (
        message.flags.contains(MessageFlag.mentioned)
        || message.flags.contains(MessageFlag.wildcardMentioned)
      ) {
        expectedMentions.add(message.id);
      }
    }
    for (final perTopic in expectedStreams.values) {
      for (final messageIds in perTopic.values) {
        messageIds.sort();
      }
    }
    for (final messageIds in expectedDms.values) {
      messageIds.sort();
    }

    check(model)
      ..streams.deepEquals(expectedStreams)
      ..dms.deepEquals(expectedDms)
      ..mentions.unorderedEquals(expectedMentions);
  }

  group('constructor', () {
    test('empty', () {
      prepare();
      checkMatchesMessages([]);
    });

    test('not empty', () {
      final stream1 = eg.stream(streamId: 1);
      final stream2 = eg.stream(streamId: 2);

      final user1 = eg.user(userId: 1);
      final user2 = eg.user(userId: 2);
      final user3 = eg.user(userId: 3);

      prepare(initial: UnreadMessagesSnapshot(
        count: 0,
        channels: [
          eg.unreadChannelMsgs(streamId: stream1.streamId, topic: 'a', unreadMessageIds: [1, 2]),
          eg.unreadChannelMsgs(streamId: stream1.streamId, topic: 'b', unreadMessageIds: [3, 4]),
          eg.unreadChannelMsgs(streamId: stream2.streamId, topic: 'b', unreadMessageIds: [5, 6]),
          eg.unreadChannelMsgs(streamId: stream2.streamId, topic: 'c', unreadMessageIds: [7, 8]),
        ],
        dms: [
          UnreadDmSnapshot(otherUserId: 1, unreadMessageIds: [9, 10]),
          UnreadDmSnapshot(otherUserId: 2, unreadMessageIds: [11, 12]),
        ],
        huddles: [
          UnreadHuddleSnapshot(userIdsString: '1,2,${eg.selfUser.userId}', unreadMessageIds: [13, 14]),
          UnreadHuddleSnapshot(userIdsString: '2,3,${eg.selfUser.userId}', unreadMessageIds: [15, 16]),
        ],
        mentions: [6, 12, 16],
        oldUnreadsMissing: false,
      ));
      checkMatchesMessages([
        eg.streamMessage(id: 1, stream: stream1, topic: 'a', flags: []),
        eg.streamMessage(id: 2, stream: stream1, topic: 'a', flags: []),
        eg.streamMessage(id: 3, stream: stream1, topic: 'b', flags: []),
        eg.streamMessage(id: 4, stream: stream1, topic: 'b', flags: []),
        eg.streamMessage(id: 5, stream: stream2, topic: 'b', flags: []),
        eg.streamMessage(id: 6, stream: stream2, topic: 'b', flags: [MessageFlag.mentioned]),
        eg.streamMessage(id: 7, stream: stream2, topic: 'c', flags: []),
        eg.streamMessage(id: 8, stream: stream2, topic: 'c', flags: []),
        eg.dmMessage(id: 9,  from: user1, to: [eg.selfUser], flags: []),
        eg.dmMessage(id: 10, from: user1, to: [eg.selfUser], flags: []),
        eg.dmMessage(id: 11, from: user2, to: [eg.selfUser], flags: []),
        eg.dmMessage(id: 12, from: user2, to: [eg.selfUser], flags: [MessageFlag.mentioned]),
        eg.dmMessage(id: 13, from: user1, to: [user2, eg.selfUser], flags: []),
        eg.dmMessage(id: 14, from: user1, to: [user2, eg.selfUser], flags: []),
        eg.dmMessage(id: 15, from: user2, to: [user3, eg.selfUser], flags: []),
        eg.dmMessage(id: 16, from: user2, to: [user3, eg.selfUser], flags: [MessageFlag.wildcardMentioned]),
      ]);
    });
  });

  group('count helpers', () {
    test('countInCombinedFeedNarrow', () async {
      final stream1 = eg.stream();
      final stream2 = eg.stream();
      final stream3 = eg.stream();
      prepare();
      await channelStore.addStreams([stream1, stream2, stream3]);
      await channelStore.addSubscription(eg.subscription(stream1));
      await channelStore.addSubscription(eg.subscription(stream2));
      await channelStore.addSubscription(eg.subscription(stream3, isMuted: true));
      await channelStore.addUserTopic(stream1, 'a', UserTopicVisibilityPolicy.muted);
      fillWithMessages([
        eg.streamMessage(stream: stream1, topic: 'a', flags: []),
        eg.streamMessage(stream: stream1, topic: 'b', flags: []),
        eg.streamMessage(stream: stream1, topic: 'b', flags: []),
        eg.streamMessage(stream: stream2, topic: 'c', flags: []),
        eg.streamMessage(stream: stream3, topic: 'd', flags: []),
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser], flags: []),
        eg.dmMessage(from: eg.thirdUser, to: [eg.selfUser], flags: []),
      ]);
      check(model.countInCombinedFeedNarrow()).equals(5);
    });

    test('countInChannel/Narrow', () async {
      final stream = eg.stream();
      prepare();
      await channelStore.addStream(stream);
      await channelStore.addSubscription(eg.subscription(stream));
      await channelStore.addUserTopic(stream, 'a', UserTopicVisibilityPolicy.unmuted);
      await channelStore.addUserTopic(stream, 'c', UserTopicVisibilityPolicy.muted);
      fillWithMessages([
        eg.streamMessage(stream: stream, topic: 'a', flags: []),
        eg.streamMessage(stream: stream, topic: 'a', flags: []),
        eg.streamMessage(stream: stream, topic: 'b', flags: []),
        eg.streamMessage(stream: stream, topic: 'b', flags: []),
        eg.streamMessage(stream: stream, topic: 'b', flags: []),
        eg.streamMessage(stream: stream, topic: 'c', flags: []),
      ]);
      check(model.countInChannel      (stream.streamId)).equals(5);
      check(model.countInChannelNarrow(stream.streamId)).equals(5);

      await channelStore.handleEvent(SubscriptionUpdateEvent(id: 1,
        streamId: stream.streamId,
        property: SubscriptionProperty.isMuted, value: true));
      check(model.countInChannel      (stream.streamId)).equals(2);
      check(model.countInChannelNarrow(stream.streamId)).equals(5);
    });

    test('countInTopicNarrow', () {
      final stream = eg.stream();
      prepare();
      fillWithMessages(List.generate(7, (i) => eg.streamMessage(
        stream: stream, topic: 'a', flags: [])));
      check(model.countInTopicNarrow(stream.streamId, eg.t('a'))).equals(7);
    });

    test('countInDmNarrow', () {
      prepare();
      fillWithMessages(List.generate(5, (i) => eg.dmMessage(
        from: eg.otherUser, to: [eg.selfUser], flags: [])));
      final narrow = DmNarrow.withUser(
        eg.otherUser.userId, selfUserId: eg.selfUser.userId);
      check(model.countInDmNarrow(narrow)).equals(5);
    });

    test('countInMentionsNarrow', () async {
      final stream = eg.stream();
      prepare();
      await channelStore.addStream(stream);
      fillWithMessages([
        eg.streamMessage(stream: stream, flags: []),
        eg.streamMessage(stream: stream, flags: [MessageFlag.mentioned]),
        eg.streamMessage(stream: stream, flags: [MessageFlag.wildcardMentioned]),
      ]);
      check(model.countInMentionsNarrow()).equals(2);
    });

    test('countInStarredMessagesNarrow', () async {
      final stream = eg.stream();
      prepare();
      await channelStore.addStream(stream);
      fillWithMessages([
        eg.streamMessage(stream: stream, flags: []),
        eg.streamMessage(stream: stream, flags: [MessageFlag.starred]),
      ]);
      check(model.countInStarredMessagesNarrow()).equals(0);
    });
  });

  group('isUnread', () {
    final unreadDmMessage = eg.dmMessage(
      from: eg.otherUser, to: [eg.selfUser], flags: []);
    final readDmMessage = eg.dmMessage(
      from: eg.otherUser, to: [eg.selfUser], flags: [MessageFlag.read]);
    final unreadChannelMessage = eg.streamMessage(flags: []);
    final readChannelMessage = eg.streamMessage(flags: [MessageFlag.read]);

    final allMessages = [
      unreadDmMessage, unreadChannelMessage,
      readDmMessage,   readChannelMessage,
    ];

    void doTestCommon(String description, int messageId, {required bool expected}) {
      test(description, () {
        prepare();
        model.oldUnreadsMissing = false;
        fillWithMessages(allMessages);
        check(model.isUnread(messageId)).equals(expected);
      });
    }

    void doTestOldUnreadsMissing(String description, int messageId, {required bool? expected}) {
      assert(expected == true || expected == null);
      test('oldUnreadsMissing; $description', () {
        prepare();
        model.oldUnreadsMissing = true;
        fillWithMessages(allMessages);
        check(model.isUnread(messageId)).equals(expected);
      });
    }

    doTestCommon('unread DM message',      unreadDmMessage.id,      expected: true);
    doTestCommon('read DM message',        readDmMessage.id,        expected: false);
    doTestCommon('unread channel message', unreadChannelMessage.id, expected: true);
    doTestCommon('read channel message',   readChannelMessage.id,   expected: false);

    doTestOldUnreadsMissing('unread DM message',      unreadDmMessage.id,      expected: true);
    doTestOldUnreadsMissing('read DM message',        readDmMessage.id,        expected: null);
    doTestOldUnreadsMissing('unread channel message', unreadChannelMessage.id, expected: true);
    doTestOldUnreadsMissing('read channel message',   readChannelMessage.id,   expected: null);
  });

  group('handleMessageEvent', () {
    for (final (isUnread, isStream, isDirectMentioned, isWildcardMentioned) in [
      (true,  true,  true,  true ),
      (true,  true,  true,  false),
      (true,  true,  false, true ),
      (true,  true,  false, false),
      (true,  false, true,  true ),
      (true,  false, true,  false),
      (true,  false, false, true ),
      (true,  false, false, false),
      (false, true,  true,  true ),
      (false, true,  true,  false),
      (false, true,  false, true ),
      (false, true,  false, false),
      (false, false, true,  true ),
      (false, false, true,  false),
      (false, false, false, true ),
      (false, false, false, false),
    ]) {
      final description = [
        isUnread ? 'unread' : 'read',
        isStream ? 'stream' : 'dm',
        isDirectMentioned ? 'direct mentioned' : 'not direct mentioned',
        isWildcardMentioned ? 'wildcard mentioned' : 'not wildcard mentioned',
      ].join(' / ');
      test(description, () {
        prepare();
        final flags = [
          if (!isUnread)           MessageFlag.read,
          if (isDirectMentioned)   MessageFlag.mentioned,
          if (isWildcardMentioned) MessageFlag.wildcardMentioned,
        ];
        final message = isStream
          ? eg.streamMessage(flags: flags)
          : eg.dmMessage(from: eg.otherUser, to: [eg.selfUser], flags: flags);
        model.handleMessageEvent(MessageEvent(id: 0, message: message));
        if (isUnread) {
          checkNotifiedOnce();
        }
        checkMatchesMessages([message]);
      });
    }

    group('stream messages', () {
      group('new unread follows existing unread', () {
        final stream1 = eg.stream(streamId: 1);
        final stream2 = eg.stream(streamId: 2);
        for (final (oldStream, newStream, oldTopic, newTopic) in [
          (stream1, stream1, 'a', 'a'),
          (stream1, stream1, 'a', 'b'),
          (stream1, stream2, 'a', 'a'),
          (stream1, stream2, 'a', 'b'),
        ]) {
          final description = [
            oldStream.streamId == newStream.streamId ? 'same stream' : 'different stream',
            oldTopic == newTopic ? 'same topic' : 'different topic',
          ].join(' / ');
          test(description, () {
            final oldMessage = eg.streamMessage(stream: oldStream, topic: oldTopic, flags: []);
            final newMessage = eg.streamMessage(stream: newStream, topic: newTopic, flags: []);

            prepare();
            fillWithMessages([oldMessage]);
            model.handleMessageEvent(MessageEvent(id: 0, message: newMessage));
            checkNotifiedOnce();
            checkMatchesMessages([oldMessage, newMessage]);
          });
        }
      });
    });

    group('DM messages', () {
      final variousDms = [
        ('self 1:1', eg.selfUser,  <User>[]),
        ('1:1',      eg.otherUser, <User>[eg.selfUser]),
        ('1:1',      eg.thirdUser, <User>[eg.selfUser]),
        ('group',    eg.otherUser, <User>[eg.selfUser, eg.thirdUser]),
        ('group',    eg.otherUser, <User>[eg.selfUser, eg.user(userId: 456)]),
      ];

      group('DM narrow subtypes', () {
        for (final (desc, from, to) in variousDms) {
          test(desc, () {
            final message = eg.dmMessage(from: from, to: to, flags: []);

            prepare();
            model.handleMessageEvent(MessageEvent(id: 0, message: message));
            checkNotifiedOnce();
            checkMatchesMessages([message]);
          });
        }
      });

      group('new unread follows existing unread', () {
        for (final (oldDesc, oldFrom, oldTo) in variousDms) {
          final oldMessage = eg.dmMessage(from: oldFrom, to: oldTo, flags: []);
          final oldNarrow = DmNarrow.ofMessage(oldMessage, selfUserId: eg.selfUser.userId);
          for (final (newDesc, newFrom, newTo) in variousDms) {
            final newMessage = eg.dmMessage(from: newFrom, to: newTo, flags: []);
            final newNarrow = DmNarrow.ofMessage(newMessage, selfUserId: eg.selfUser.userId);

            test('existing in $oldDesc narrow; new in ${oldNarrow == newNarrow ? 'same narrow' : 'different narrow ($newDesc)'}', () {
              prepare();
              fillWithMessages([oldMessage]);
              model.handleMessageEvent(MessageEvent(id: 0, message: newMessage));
              checkNotifiedOnce();
              checkMatchesMessages([oldMessage, newMessage]);
            });
          }
        }
      });
    });
  });

  group('handleUpdateMessageEvent', () {
    group('mentions', () {
      for (final isKnownToModel in [true, false]) {
        for (final isRead in [false, true]) {
          final baseFlags = [if (isRead) MessageFlag.read];
          for (final (messageDesc, message) in [
            ('stream', eg.streamMessage(flags: baseFlags)),
            ('1:1 dm', eg.dmMessage(from: eg.otherUser, to: [eg.selfUser], flags: baseFlags)),
          ]) {
            test('${isRead ? 'read' : 'unread'} $messageDesc message${isKnownToModel ? '' : ' (but read state unknown to model)'}', () {
              prepare();
              fillWithMessages([
                if (isKnownToModel) message,
              ]);

              for (final List<MessageFlag> newFlags in [
                [...baseFlags, MessageFlag.mentioned],
                [...baseFlags, MessageFlag.mentioned, MessageFlag.wildcardMentioned],
                [...baseFlags, MessageFlag.wildcardMentioned],
                [...baseFlags, ],
                [...baseFlags, MessageFlag.wildcardMentioned],
              ]) {
                assert(newFlags.contains(MessageFlag.read) == isRead);
                if (!isKnownToModel) {
                  check(because: "no crash if message is in model's blindspots",
                    () => model.handleUpdateMessageEvent(
                      eg.updateMessageEditEvent(message, flags: newFlags),
                    )).returnsNormally();
                  // Rarely, this event will be about an unread that's unknown
                  // to the model, or at least one of the model's components;
                  // see e.g. [oldUnreadsMissing]. When that happens, I think
                  // we won't usually have necessary data (in the event or model)
                  // to make the unread appear in [streams] or [dms]
                  // if it wasn't there before. However, for stream messages,
                  // we may have that needed data if this event happens to
                  // signal that the message was moved.
                  //
                  // If the message in this event is unread and mentioned,
                  // I *think* the model will cause it to correctly appear in
                  // [mentions], as of 2023-10.
                  //
                  // TODO in any case, confirm behavior and run appropriate
                  //   model checks here.
                  notifiedCount = 0;
                  continue;
                }
                model.handleUpdateMessageEvent(
                  eg.updateMessageEditEvent(message, flags: newFlags),
                );

                if (
                  isRead
                  || (
                    // TODO make less verbose
                    (message.flags.contains(MessageFlag.mentioned) || message.flags.contains(MessageFlag.wildcardMentioned))
                      == (newFlags.contains(MessageFlag.mentioned) || newFlags.contains(MessageFlag.wildcardMentioned))
                  )
                ) {
                  checkNotNotified();
                } else {
                  checkNotifiedOnce();
                }
                // It would be more realistic to set [message]'s content too,
                // but the implementation doesn't depend on that.
                message.flags = newFlags;
                checkMatchesMessages(isKnownToModel ? [message] : []);
              }
            });
          }
        }
      }
    });
  });


  group('handleDeleteMessageEvent', () {
    final stream1 = eg.stream(streamId: 1);
    final stream2 = eg.stream(streamId: 2);

    final message1 = eg.dmMessage(id: 1, from: eg.selfUser, to: [], flags: []);
    final message2 = eg.dmMessage(id: 2, from: eg.otherUser, to: [eg.selfUser], flags: []);
    final message3 = eg.dmMessage(id: 3, from: eg.thirdUser, to: [eg.selfUser], flags: []);
    final message4 = eg.dmMessage(id: 4, from: eg.otherUser, to: [eg.selfUser, eg.thirdUser], flags: []);
    final message5 = eg.dmMessage(id: 5, from: eg.otherUser, to: [eg.selfUser, eg.user(userId: 456)], flags: []);

    final message6 = eg.dmMessage(id: 6, from: eg.selfUser, to: [], flags: [MessageFlag.mentioned]);
    final message7 = eg.dmMessage(id: 7, from: eg.otherUser, to: [eg.selfUser], flags: [MessageFlag.mentioned]);
    final message8 = eg.dmMessage(id: 8, from: eg.thirdUser, to: [eg.selfUser], flags: [MessageFlag.mentioned]);
    final message9 = eg.dmMessage(id: 9, from: eg.otherUser, to: [eg.selfUser, eg.thirdUser], flags: [MessageFlag.mentioned]);
    final message10 = eg.dmMessage(id: 10, from: eg.otherUser, to: [eg.selfUser, eg.user(userId: 456)], flags: [MessageFlag.mentioned]);

    final message11 = eg.streamMessage(id: 11, stream: stream1, topic: 'a', flags: []);
    final message12 = eg.streamMessage(id: 12, stream: stream1, topic: 'a', flags: [MessageFlag.mentioned]);
    final message13 = eg.streamMessage(id: 13, stream: stream2, topic: 'b', flags: []);
    final message14 = eg.streamMessage(id: 14, stream: stream2, topic: 'b', flags: [MessageFlag.mentioned]);

    final messages = [
      message1, message2, message3, message4, message5,
      message6, message7, message8, message9, message10,
      message11, message12, message13, message14,
    ];

    test('single deletes of unreads', () {
      prepare();
      fillWithMessages(messages);

      final expectedRemainingMessages = Set.of(messages);
      for (final message in messages) {
        final event = switch (message) {
          StreamMessage() => DeleteMessageEvent(
            id: 0,
            messageType: MessageType.stream,
            messageIds: [message.id],
            streamId: message.streamId,
            topic: message.topic,
          ),
          DmMessage() => DeleteMessageEvent(
            id: 0,
            messageType: MessageType.direct,
            messageIds: [message.id],
            streamId: null,
            topic: null,
          ),
        };
        model.handleDeleteMessageEvent(event);
        checkNotifiedOnce();
        checkMatchesMessages(expectedRemainingMessages..remove(message));
      }
    });

    test('bulk deletes of unreads', () {
      prepare();
      fillWithMessages(messages);

      final expectedRemainingMessages = Set.of(messages);

      model.handleDeleteMessageEvent(DeleteMessageEvent(
        id: 0,
        messageIds: [11, 12],
        messageType: MessageType.stream,
        streamId: stream1.streamId,
        topic: eg.t('a'),
      ));
      checkNotifiedOnce();
      checkMatchesMessages(expectedRemainingMessages..removeAll([message11, message12]));
      model.handleDeleteMessageEvent(DeleteMessageEvent(
        id: 0,
        messageIds: [13, 14],
        messageType: MessageType.stream,
        streamId: stream2.streamId,
        topic: eg.t('b'),
      ));
      checkNotifiedOnce();
      checkMatchesMessages(expectedRemainingMessages..removeAll([message13, message14]));
      model.handleDeleteMessageEvent(DeleteMessageEvent(
        id: 0,
        messageIds: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        messageType: MessageType.direct,
        streamId: null,
        topic: null,
      ));
      checkNotifiedOnce();
      checkMatchesMessages([]);
    });

    test('delete read (or unknown) stream message', () {
      final message = eg.streamMessage(flags: [MessageFlag.read]);

      prepare();
      // Equivalently, could do: fillWithMessages([message]);
      model.handleDeleteMessageEvent(DeleteMessageEvent(
        id: 0,
        messageIds: [message.id],
        messageType: MessageType.stream,
        streamId: message.streamId,
        topic: message.topic,
      ));
      // TODO improve implementation; then:
      //   checkNotNotified();
      // For now, at least check callers aren't notified *more* than once:
      checkNotifiedOnce();
      checkMatchesMessages([message]);
    });

    test('delete read (or unknown) DM message', () {
      final message = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser], flags: [MessageFlag.read]);

      prepare();
      // Equivalently, could do: fillWithMessages([message]);
      model.handleDeleteMessageEvent(DeleteMessageEvent(
        id: 0,
        messageIds: [message.id],
        messageType: MessageType.direct,
        streamId: null,
        topic: null,
      ));
      // TODO improve implementation; then:
      //   checkNotNotified();
      // For now, at least check callers aren't notified *more* than once:
      checkNotifiedOnce();
      checkMatchesMessages([message]);
    });
  });

  group('handleUpdateMessageFlagsEvent', () {
    final irrelevantFlags = MessageFlag.values.where((flag) =>
      switch (flag) {
        MessageFlag.starred => true,
        MessageFlag.collapsed => true,
        MessageFlag.hasAlertWord => true,
        MessageFlag.historical => true,
        MessageFlag.unknown => true,
        MessageFlag.mentioned => false,
        MessageFlag.wildcardMentioned => false,
        MessageFlag.read => false,
      });

    for (final (isRead, isMentioned) in [
      (true,  true ),
      (true,  false),
      (false, true ),
      (false, false),
    ]) {
      // When isRead is true, the message won't appear in the model.
      // That case is indistinguishable from an unread that's unknown to
      // the model, so we get coverage for that case too.
      test('remove irrelevant flags; ${isRead ? 'read' : 'unread'} / ${isMentioned ? 'mentioned' : 'not mentioned'}', () {
        final message = eg.streamMessage(flags: [
          ...irrelevantFlags,
          if (isRead) MessageFlag.read,
          if (isMentioned) MessageFlag.mentioned,
        ]);
        prepare();
        fillWithMessages([message]);
        for (final flag in irrelevantFlags) {
          model.handleUpdateMessageFlagsEvent(UpdateMessageFlagsRemoveEvent(
            id: 0,
            flag: flag,
            messages: [message.id],
            messageDetails: null,
          ));
          checkNotNotified();
          message.flags.remove(flag);
          checkMatchesMessages([message]);
        }
      });
    }

    for (final (isRead, isMentioned) in [
      (true,  true ),
      (true,  false),
      (false, true ),
      (false, false),
    ]) {
      // When isRead is true, the message won't appear in the model.
      // That case is indistinguishable from an unread that's unknown to
      // the model, so we get coverage for that case too.
      test('add irrelevant flags; ${isRead ? 'read' : 'unread'} / ${isMentioned ? 'mentioned' : 'not mentioned'}', () {
        final message = eg.streamMessage(flags: [
          if (isRead) MessageFlag.read,
          if (isMentioned) MessageFlag.mentioned,
        ]);
        prepare();
        fillWithMessages([message]);
        for (final flag in irrelevantFlags) {
          model.handleUpdateMessageFlagsEvent(UpdateMessageFlagsAddEvent(
            id: 0,
            flag: flag,
            messages: [message.id],
            all: false,
          ));
          checkNotNotified();
          message.flags.add(flag);
          checkMatchesMessages([message]);
        }
      });
    }

    for (final mentionFlag in [MessageFlag.mentioned, MessageFlag.wildcardMentioned]) {
      // For a read message in this test, the message won't appear in the model.
      // That case is indistinguishable from an unread that's unknown to
      // the model, so we get coverage for that case too.
      test('add flag: ${mentionFlag.name}', () {
        final messages = [
          eg.streamMessage(flags: []),
          eg.streamMessage(flags: [MessageFlag.read]),
          eg.dmMessage(from: eg.otherUser, to: [eg.selfUser], flags: []),
          eg.dmMessage(from: eg.otherUser, to: [eg.selfUser], flags: [MessageFlag.read]),
        ];

        prepare();
        fillWithMessages(messages);
        for (final message in messages) {
          model.handleUpdateMessageFlagsEvent(UpdateMessageFlagsAddEvent(
            id: 0,
            flag: mentionFlag,
            messages: [message.id],
            all: false,
          ));
          if (!message.flags.contains(MessageFlag.read)) {
            checkNotifiedOnce();
          } else {
            // TODO improve implementation; then:
            //   checkNotNotified();
            // For now, at least check callers aren't notified *more* than once:
            checkNotifiedOnce();
          }
          message.flags.add(mentionFlag);
          checkMatchesMessages(messages);
        }
      });

      // TODO test adding wildcard mention when direct mention is already present
      //   and vice versa (implementation should skip notifyListeners;
      //   test should checkNotNotified)

      // For a read message in this test, the message won't appear in the model.
      // That case is indistinguishable from an unread that's unknown to
      // the model, so we get coverage for that case too.
      test('remove flag: ${mentionFlag.name}', () {
        final messages = [
          eg.streamMessage(flags: [mentionFlag]),
          eg.streamMessage(flags: [mentionFlag, MessageFlag.read]),
          eg.dmMessage(from: eg.otherUser, to: [eg.selfUser], flags: [mentionFlag]),
          eg.dmMessage(from: eg.otherUser, to: [eg.selfUser], flags: [mentionFlag, MessageFlag.read]),
        ];

        prepare();
        fillWithMessages(messages);
        for (final message in messages) {
          model.handleUpdateMessageFlagsEvent(UpdateMessageFlagsRemoveEvent(
            id: 0,
            flag: mentionFlag,
            messages: [message.id],
            messageDetails: null,
          ));
          if (!message.flags.contains(MessageFlag.read)) {
            checkNotifiedOnce();
          } else {
            // TODO improve implementation; then:
            //   checkNotNotified();
            // For now, at least check callers aren't notified *more* than once:
            checkNotifiedOnce();
          }
          message.flags.remove(mentionFlag);
          checkMatchesMessages(messages);
        }
      });
    }

    // TODO test removing just direct or wildcard mention when both are present
    //   (implementation should skip notifyListeners;
    //   test should checkNotNotified)

    test('mark all as read', () {
      final message1 = eg.streamMessage(id: 1, flags: []);
      final message2 = eg.streamMessage(id: 2, flags: [MessageFlag.mentioned]);
      final message3 = eg.dmMessage(id: 3, from: eg.otherUser, to: [eg.selfUser], flags: []);
      final message4 = eg.dmMessage(id: 4, from: eg.otherUser, to: [eg.selfUser], flags: [MessageFlag.wildcardMentioned]);
      final messages = [message1, message2, message3, message4];

      prepare();
      fillWithMessages([message1, message2, message3, message4]);

      // Might as well test with oldUnreadsMissing: true.
      //
      // We didn't fill the model with 50k unreads, so this is questionably
      // realistic… but the 50k cap isn't actually API-guaranteed, and this is
      // plausibly realistic for a hypothetical server that decides based on
      // message age rather than the 50k cap.
      model.oldUnreadsMissing = true;

      model.handleUpdateMessageFlagsEvent(UpdateMessageFlagsAddEvent(
        id: 0,
        flag: MessageFlag.read,
        messages: [],
        all: true,
      ));
      checkNotifiedOnce();
      for (final message in messages) {
        message.flags.add(MessageFlag.read);
      }
      checkMatchesMessages(messages);
      check(model).oldUnreadsMissing.isFalse();
    });

    group('mark some as read', () {
      test('usual cases', () {
        final stream1 = eg.stream(streamId: 1);
        final stream2 = eg.stream(streamId: 2);

        final message1 = eg.dmMessage(id: 1, from: eg.selfUser, to: [], flags: []);
        final message2 = eg.dmMessage(id: 2, from: eg.otherUser, to: [eg.selfUser], flags: []);
        final message3 = eg.dmMessage(id: 3, from: eg.thirdUser, to: [eg.selfUser], flags: []);
        final message4 = eg.dmMessage(id: 4, from: eg.otherUser, to: [eg.selfUser, eg.thirdUser], flags: []);
        final message5 = eg.dmMessage(id: 5, from: eg.otherUser, to: [eg.selfUser, eg.user(userId: 456)], flags: []);

        final message6 = eg.dmMessage(id: 6, from: eg.selfUser, to: [], flags: [MessageFlag.mentioned]);
        final message7 = eg.dmMessage(id: 7, from: eg.otherUser, to: [eg.selfUser], flags: [MessageFlag.mentioned]);
        final message8 = eg.dmMessage(id: 8, from: eg.thirdUser, to: [eg.selfUser], flags: [MessageFlag.mentioned]);
        final message9 = eg.dmMessage(id: 9, from: eg.otherUser, to: [eg.selfUser, eg.thirdUser], flags: [MessageFlag.mentioned]);
        final message10 = eg.dmMessage(id: 10, from: eg.otherUser, to: [eg.selfUser, eg.user(userId: 456)], flags: [MessageFlag.mentioned]);

        final message11 = eg.streamMessage(id: 11, stream: stream1, topic: 'a', flags: []);
        final message12 = eg.streamMessage(id: 12, stream: stream1, topic: 'a', flags: [MessageFlag.mentioned]);
        final message13 = eg.streamMessage(id: 13, stream: stream2, topic: 'b', flags: []);
        final message14 = eg.streamMessage(id: 14, stream: stream2, topic: 'b', flags: [MessageFlag.mentioned]);

        final messages = [
          message1, message2, message3, message4, message5,
          message6, message7, message8, message9, message10,
          message11, message12, message13, message14,
        ];

        prepare();
        fillWithMessages(messages);

        model.handleUpdateMessageFlagsEvent(UpdateMessageFlagsAddEvent(
          id: 0,
          flag: MessageFlag.read,
          messages: [message1.id],
          all: false,
        ));
        checkNotifiedOnce();
        message1.flags.add(MessageFlag.read);
        checkMatchesMessages(messages);

        model.handleUpdateMessageFlagsEvent(UpdateMessageFlagsAddEvent(
          id: 0,
          flag: MessageFlag.read,
          messages: [message14.id],
          all: false,
        ));
        checkNotifiedOnce();
        message14.flags.add(MessageFlag.read);
        checkMatchesMessages(messages);

        model.handleUpdateMessageFlagsEvent(UpdateMessageFlagsAddEvent(
          id: 0,
          flag: MessageFlag.read,
          messages: [message5.id, message6.id],
          all: false,
        ));
        checkNotifiedOnce();
        message5.flags.add(MessageFlag.read);
        message6.flags.add(MessageFlag.read);
        checkMatchesMessages(messages);

        model.handleUpdateMessageFlagsEvent(UpdateMessageFlagsAddEvent(
          id: 0,
          flag: MessageFlag.read,
          messages: [
            message2.id, message3.id, message3.id, message4.id,
            message7.id, message8.id, message9.id, message10.id,
            message11.id, message12.id, message13.id,
          ],
          all: false,
        ));
        checkNotifiedOnce();
        message2.flags.add(MessageFlag.read);
        message3.flags.add(MessageFlag.read);
        message4.flags.add(MessageFlag.read);
        message7.flags.add(MessageFlag.read);
        message8.flags.add(MessageFlag.read);
        message9.flags.add(MessageFlag.read);
        message10.flags.add(MessageFlag.read);
        message11.flags.add(MessageFlag.read);
        message12.flags.add(MessageFlag.read);
        message13.flags.add(MessageFlag.read);
        checkMatchesMessages(messages);
      });

      test('on unreads that are unknown to the model', () {
        final stream = eg.stream();
        final message1 = eg.streamMessage(id: 1, flags: [], stream: stream, topic: 'a');
        final message2 = eg.dmMessage(id: 2, flags: [], from: eg.otherUser, to: [eg.selfUser]);
        final message3 = eg.streamMessage(id: 3, flags: [], stream: stream, topic: 'a');
        final message4 = eg.dmMessage(id: 4, flags: [], from: eg.otherUser, to: [eg.selfUser]);

        prepare();
        fillWithMessages([message3, message4]);

        check(() => model.handleUpdateMessageFlagsEvent(UpdateMessageFlagsAddEvent(
          id: 0,
          flag: MessageFlag.read,
          messages: [message1.id, message2.id, message3.id, message4.id],
          all: false,
        ))).returnsNormally();
        checkNotifiedOnce();
        message3.flags.add(MessageFlag.read);
        message4.flags.add(MessageFlag.read);
        checkMatchesMessages([message3, message4]);
      });
    });

    group('mark as unread', () {
      UpdateMessageFlagsEvent mkEvent(Iterable<Message> messages) =>
        eg.updateMessageFlagsRemoveEvent(MessageFlag.read, messages);

      test('usual cases', () {
        final stream1 = eg.stream(streamId: 1);
        final stream2 = eg.stream(streamId: 2);

        final message1 = eg.dmMessage(id: 1, from: eg.selfUser, to: [], flags: [MessageFlag.read]);
        final message2 = eg.dmMessage(id: 2, from: eg.otherUser, to: [eg.selfUser], flags: [MessageFlag.read]);
        final message3 = eg.dmMessage(id: 3, from: eg.thirdUser, to: [eg.selfUser], flags: [MessageFlag.read]);
        final message4 = eg.dmMessage(id: 4, from: eg.otherUser, to: [eg.selfUser, eg.thirdUser], flags: [MessageFlag.read]);
        final message5 = eg.dmMessage(id: 5, from: eg.otherUser, to: [eg.selfUser, eg.user(userId: 456)], flags: [MessageFlag.read]);

        final message6 = eg.dmMessage(id: 6, from: eg.selfUser, to: [], flags: [MessageFlag.mentioned, MessageFlag.read]);
        final message7 = eg.dmMessage(id: 7, from: eg.otherUser, to: [eg.selfUser], flags: [MessageFlag.mentioned, MessageFlag.read]);
        final message8 = eg.dmMessage(id: 8, from: eg.thirdUser, to: [eg.selfUser], flags: [MessageFlag.mentioned, MessageFlag.read]);
        final message9 = eg.dmMessage(id: 9, from: eg.otherUser, to: [eg.selfUser, eg.thirdUser], flags: [MessageFlag.mentioned, MessageFlag.read]);
        final message10 = eg.dmMessage(id: 10, from: eg.otherUser, to: [eg.selfUser, eg.user(userId: 456)], flags: [MessageFlag.mentioned, MessageFlag.read]);

        final message11 = eg.streamMessage(id: 11, stream: stream1, topic: 'a', flags: [MessageFlag.read]);
        final message12 = eg.streamMessage(id: 12, stream: stream1, topic: 'a', flags: [MessageFlag.mentioned, MessageFlag.read]);
        final message13 = eg.streamMessage(id: 13, stream: stream2, topic: 'b', flags: [MessageFlag.read]);
        final message14 = eg.streamMessage(id: 14, stream: stream2, topic: 'b', flags: [MessageFlag.mentioned, MessageFlag.read]);

        final messages = [
          message1, message2, message3, message4, message5,
          message6, message7, message8, message9, message10,
          message11, message12, message13, message14,
        ];

        prepare();
        fillWithMessages(messages);

        model.handleUpdateMessageFlagsEvent(mkEvent([message1]));
        checkNotifiedOnce();
        message1.flags.remove(MessageFlag.read);
        checkMatchesMessages(messages);

        model.handleUpdateMessageFlagsEvent(mkEvent([message14]));
        checkNotifiedOnce();
        message14.flags.remove(MessageFlag.read);
        checkMatchesMessages(messages);

        model.handleUpdateMessageFlagsEvent(mkEvent([message5, message6]));
        checkNotifiedOnce();
        message5.flags.remove(MessageFlag.read);
        message6.flags.remove(MessageFlag.read);
        checkMatchesMessages(messages);

        model.handleUpdateMessageFlagsEvent(mkEvent([
          message2, message3, message4,
          message7, message8, message9, message10,
          message11, message12, message13,
        ]));
        checkNotifiedOnce();
        message2.flags.remove(MessageFlag.read);
        message3.flags.remove(MessageFlag.read);
        message4.flags.remove(MessageFlag.read);
        message7.flags.remove(MessageFlag.read);
        message8.flags.remove(MessageFlag.read);
        message9.flags.remove(MessageFlag.read);
        message10.flags.remove(MessageFlag.read);
        message11.flags.remove(MessageFlag.read);
        message12.flags.remove(MessageFlag.read);
        message13.flags.remove(MessageFlag.read);
        checkMatchesMessages(messages);
      });

      test('tolerates unsorted event.messages: stream messages', () {
        final stream = eg.stream();
        final message1 = eg.streamMessage(id: 1, flags: [MessageFlag.read], stream: stream, topic: 'a');
        final message2 = eg.streamMessage(id: 2, flags: [MessageFlag.read], stream: stream, topic: 'a');

        prepare();
        fillWithMessages([message1, message2]);

        model.handleUpdateMessageFlagsEvent(mkEvent([message2, message1]));
        checkNotifiedOnce();

        message1.flags.remove(MessageFlag.read);
        message2.flags.remove(MessageFlag.read);
        checkMatchesMessages([message1, message2]);
      });

      test('tolerates unsorted event.messages: DM messages', () {
        final message1 = eg.dmMessage(id: 1, flags: [MessageFlag.read], from: eg.otherUser, to: [eg.selfUser]);
        final message2 = eg.dmMessage(id: 2, flags: [MessageFlag.read], from: eg.otherUser, to: [eg.selfUser]);

        prepare();
        fillWithMessages([message1, message2]);

        model.handleUpdateMessageFlagsEvent(mkEvent([message2, message1]));
        checkNotifiedOnce();

        message1.flags.remove(MessageFlag.read);
        message2.flags.remove(MessageFlag.read);
        checkMatchesMessages([message1, message2]);
      });

      // TODO(server-6) remove mention of zulip/zulip#22164, fixed in 6.0
      test('tolerates event pointing to DM/stream messages that are already unread (zulip/zulip#22164)', () {
        final message1 = eg.streamMessage(id: 1, flags: []);
        final message2 = eg.dmMessage(id: 2, from: eg.otherUser, to: [eg.selfUser], flags: []);

        prepare();
        fillWithMessages([message1, message2]);

        model.handleUpdateMessageFlagsEvent(mkEvent([message1, message2]));
        checkNotifiedOnce();

        message1.flags.remove(MessageFlag.read);
        message2.flags.remove(MessageFlag.read);
        checkMatchesMessages([message1, message2]);
      });

      test('tolerates "message details" missing', () {
        final stream = eg.stream();
        const topic = 'a';
        final message1 = eg.streamMessage(id: 1, flags: [MessageFlag.read], stream: stream, topic: topic);
        final message2 = eg.streamMessage(id: 2, flags: [MessageFlag.read], stream: stream, topic: topic);
        final message3 = eg.dmMessage(id: 3, flags: [MessageFlag.read], from: eg.otherUser, to: [eg.selfUser]);
        final message4 = eg.dmMessage(id: 4, flags: [MessageFlag.read], from: eg.otherUser, to: [eg.selfUser]);

        prepare();
        fillWithMessages([message1, message2, message3, message4]);

        check(() {
          model.handleUpdateMessageFlagsEvent(UpdateMessageFlagsRemoveEvent(
            id: 0,
            flag: MessageFlag.read,
            messages: [message1.id, message2.id, message3.id, message4.id],
            messageDetails: {
              message1.id: UpdateMessageFlagsMessageDetail(
                type: MessageType.stream,
                mentioned: false,
                streamId: stream.streamId,
                topic: eg.t(topic),
                userIds: null,
              ),
              // message 2 and 3 have their details missing
              message4.id: UpdateMessageFlagsMessageDetail(
                type: MessageType.direct,
                mentioned: false,
                streamId: null,
                topic: null,
                userIds: DmNarrow.ofMessage(message4, selfUserId: eg.selfUser.userId)
                  .otherRecipientIds,
              ),
            }));
        }).returnsNormally();

        checkNotifiedOnce();

        message1.flags.remove(MessageFlag.read);
        // messages 2 and 3 not marked unread, but at least we didn't crash
        message4.flags.remove(MessageFlag.read);
        checkMatchesMessages([message1, message2, message3, message4]);
      });
    });
  });

  group('handleAllMessagesReadSuccess', () {
      prepare();
      fillWithMessages([]);

      // We didn't fill the model with 50k unreads, so this is questionably
      // realistic… but the 50k cap isn't actually API-guaranteed, and this is
      // plausibly realistic for a hypothetical server that decides based on
      // message age rather than the 50k cap.
      model.oldUnreadsMissing = true;
      model.handleAllMessagesReadSuccess();
      checkNotifiedOnce();
      check(model).oldUnreadsMissing.isFalse();
  });
}
