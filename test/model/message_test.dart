import 'dart:async';
import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:fake_async/fake_async.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/submessage.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/message.dart';
import 'package:zulip/model/message_list.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';

import '../api/fake_api.dart';
import '../api/model/model_checks.dart';
import '../api/model/submessage_checks.dart';
import '../example_data.dart' as eg;
import '../fake_async.dart';
import '../fake_async_checks.dart';
import '../stdlib_checks.dart';
import 'message_checks.dart';
import 'message_list_test.dart';
import 'store_checks.dart';
import 'test_store.dart';

void main() {
  // These "late" variables are the common state operated on by each test.
  // Each test case calls [prepare] to initialize them.
  late Subscription subscription;
  late PerAccountStore store;
  late FakeApiConnection connection;
  // [messageList] is here only for the sake of checking when it notifies.
  // For anything deeper than that, use `message_list_test.dart`.
  late MessageListView messageList;
  late int notifiedCount;

  void checkNotified({required int count}) {
    check(notifiedCount).equals(count);
    notifiedCount = 0;
  }
  void checkNotNotified() => checkNotified(count: 0);
  void checkNotifiedOnce() => checkNotified(count: 1);

  /// Initialize [store] and the rest of the test state.
  Future<void> prepare({
    Narrow narrow = const CombinedFeedNarrow(),
    ZulipStream? stream,
    int? zulipFeatureLevel,
  }) async {
    stream ??= eg.stream(streamId: eg.defaultStreamMessageStreamId);
    subscription = eg.subscription(stream);
    final account = eg.selfAccount.copyWith(zulipFeatureLevel: zulipFeatureLevel);
    store = eg.store(account: account,
      initialSnapshot: eg.initialSnapshot(zulipFeatureLevel: zulipFeatureLevel));
    await store.addStream(stream);
    await store.addSubscription(subscription);
    connection = store.connection as FakeApiConnection;
    notifiedCount = 0;
    messageList = MessageListView.init(store: store, narrow: narrow)
      ..addListener(() {
        notifiedCount++;
      });
    addTearDown(messageList.dispose);
    check(messageList).fetched.isFalse();
    checkNotNotified();

    // This cleans up possibly pending timers from [MessageStoreImpl].
    addTearDown(store.dispose);
  }

  /// Perform the initial message fetch for [messageList].
  ///
  /// The test case must have already called [prepare] to initialize the state.
  ///
  /// This does not support submessages. Use [prepareMessageWithSubmessages]
  /// instead if needed.
  Future<void> prepareMessages(
    List<Message> messages, {
    bool foundOldest = false,
  }) async {
    assert(messages.every((message) => message.poll == null));
    connection.prepare(json:
      eg.newestGetMessagesResult(foundOldest: foundOldest, messages: messages).toJson());
    await messageList.fetchInitial();
    checkNotifiedOnce();
  }

  Future<void> addMessages(Iterable<Message> messages) async {
    await store.addMessages(messages);
    checkNotified(count: messageList.fetched ? messages.length : 0);
  }

  test('dispose cancels pending timers', () => awaitFakeAsync((async) async {
    final stream = eg.stream();
    final store = eg.store();
    await store.addStream(stream);
    await store.addSubscription(eg.subscription(stream));

    (store.connection as FakeApiConnection).prepare(
      json: SendMessageResult(id: 1).toJson());
    await store.sendMessage(
      destination: StreamDestination(stream.streamId, eg.t('topic')),
      content: 'content');
    check(async.pendingTimers).deepEquals(<Condition<Object?>>[
      (it) => it.isA<FakeTimer>().duration.equals(kLocalEchoDebounceDuration),
      (it) => it.isA<FakeTimer>().duration.equals(kSendMessageRetryWaitPeriod),
    ]);

    store.dispose();
    check(async.pendingTimers).isEmpty();
  }));

  group('sendMessage', () {
    final stream = eg.stream();
    final message = eg.streamMessage(stream: stream);
    final streamDestination = StreamDestination(stream.streamId, eg.t('some topic'));

    test('outbox messages get unique localMessageId', () async {
      await prepare(stream: stream);
      await prepareMessages([]);

      for (int i = 0; i < 10; i++) {
        connection.prepare(json: SendMessageResult(id: 1).toJson());
        await store.sendMessage(destination: streamDestination, content: 'content');
      }
      // [store.outboxMessages] has the same number of keys (localMessageId)
      // as the number of sent messages, which are guaranteed to be distinct.
      check(store.outboxMessages).keys.length.equals(10);
    });

    late Future<void> sendMessageFuture;
    late OutboxMessage outboxMessage;

    Future<void> prepareSendMessageToSucceed({
      MessageDestination? destination,
      Duration delay = Duration.zero,
      int? zulipFeatureLevel,
    }) async {
      await prepare(stream: stream, zulipFeatureLevel: zulipFeatureLevel);
      await prepareMessages([eg.streamMessage(stream: stream)]);
      connection.prepare(json: SendMessageResult(id: 1).toJson(), delay: delay);
      sendMessageFuture = store.sendMessage(
        destination: destination ?? streamDestination, content: 'content');
      outboxMessage = store.outboxMessages.values.single;
    }

    Future<void> prepareSendMessageToFail({
      Duration delay = Duration.zero,
    }) async {
      await prepare(stream: stream);
      await prepareMessages([eg.streamMessage(stream: stream)]);
      connection.prepare(apiException: eg.apiBadRequest(), delay: delay);
      sendMessageFuture = store.sendMessage(
        destination: streamDestination, content: 'content');

      // This allows `async.elapse` to not fail when `sendMessageFuture` throws.
      // The caller should still await the future since this does not await it.
      unawaited(check(sendMessageFuture).throws());

      outboxMessage = store.outboxMessages.values.single;
    }

    test('while message is being sent, message event arrives, then the send succeeds', () => awaitFakeAsync((async) async {
      // Send message with a delay in response, leaving time for the message
      // event to arrive.
      await prepareSendMessageToSucceed(delay: Duration(seconds: 1));
      check(connection.lastRequest).isA<http.Request>()
        ..bodyFields['queue_id'].equals(store.queueId)
        ..bodyFields['local_id'].equals('${outboxMessage.localMessageId}');
      check(outboxMessage).state.equals(OutboxMessageState.hidden);

      // Handle the message event before `future` completes, i.e. while the
      // message is being sent.
      await store.handleEvent(eg.messageEvent(message,
        localMessageId: outboxMessage.localMessageId));
      check(store.outboxMessages).isEmpty();
      check(outboxMessage).state.equals(OutboxMessageState.hidden);

      // Complete the send request. The outbox message should no longer get
      // updated because it is not in the store any more.
      async.elapse(const Duration(seconds: 1));
      await sendMessageFuture;
      check(outboxMessage).state.equals(OutboxMessageState.hidden);
    }));

    test('while message is being sent, message event arrives, then the send fails', () => awaitFakeAsync((async) async {
      // Set up an error to fail `sendMessage` with a delay, leaving time for
      // the message event to arrive.
      await prepareSendMessageToFail(delay: const Duration(seconds: 1));
      check(outboxMessage).state.equals(OutboxMessageState.hidden);

      // Handle the message event before `future` completes, i.e. while the
      // message is being sent.
      await store.handleEvent(eg.messageEvent(message,
        localMessageId: outboxMessage.localMessageId));
      check(store.outboxMessages).isEmpty();
      check(outboxMessage).state.equals(OutboxMessageState.hidden);

      // Complete the send request with an error.  The outbox message should no
      // longer be updated because it is not in the store any more.
      async.elapse(const Duration(seconds: 1));
      await check(sendMessageFuture).throws();
      check(outboxMessage).state.equals(OutboxMessageState.hidden);
    }));

    test('message is sent successfully, message event arrives before debounce timeout', () async {
      // Set up to successfully send the message immediately.
      await prepareSendMessageToSucceed();
      await sendMessageFuture;
      check(outboxMessage).state.equals(OutboxMessageState.hidden);

      // Handle the event after the message is sent but before the debounce
      // timeout.
      await store.handleEvent(eg.messageEvent(message,
        localMessageId: outboxMessage.localMessageId));
      check(store.outboxMessages).isEmpty();
      // The outbox message should remain hidden since the send
      // request was successful.
      check(outboxMessage).state.equals(OutboxMessageState.hidden);
    });

    test('DM message is sent successfully, message event arrives before debounce timeout', () async {
      // Set up to successfully send the message immediately.
      await prepareSendMessageToSucceed(destination: DmDestination(
        userIds: [eg.selfUser.userId, eg.otherUser.userId]));
      await sendMessageFuture;
      check(outboxMessage).state.equals(OutboxMessageState.hidden);

      // Handle the event after the message is sent but before the debounce
      // timeout.
      await store.handleEvent(eg.messageEvent(
        eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]),
        localMessageId: outboxMessage.localMessageId));
      check(store.outboxMessages).isEmpty();
      // The outbox message should remain hidden since the send
      // request was successful.
      check(outboxMessage).state.equals(OutboxMessageState.hidden);
    });

    test('message is sent successfully, message event arrives after debounce timeout', () => awaitFakeAsync((async) async {
      // Set up to successfully send the message immediately.
      await prepareSendMessageToSucceed();
      await sendMessageFuture;
      check(outboxMessage).state.equals(OutboxMessageState.hidden);

      // Pass enough time without handling the message event, to expire
      // the debounce timer.
      async.elapse(kLocalEchoDebounceDuration);
      check(store.outboxMessages).values.single.identicalTo(outboxMessage);
      check(outboxMessage).state.equals(OutboxMessageState.waiting);

      // Handle the event when the outbox message is in waiting state.
      // The outbox message should be removed without errors.
      await store.handleEvent(eg.messageEvent(message,
        localMessageId: outboxMessage.localMessageId));
      check(store.outboxMessages).isEmpty();
      // The outbox message should no longer be updated because it is not in
      // the store any more.
      check(outboxMessage).state.equals(OutboxMessageState.waiting);
    }));

    test('message failed to send before debounce timeout', () => awaitFakeAsync((async) async {
      // Set up to fail the send request, but do not complete it yet, to
      // check the initial states.
      await prepareSendMessageToFail();
      check(outboxMessage).state.equals(OutboxMessageState.hidden);
      check(async.pendingTimers).deepEquals(<Condition<Object?>>[
        (it) => it.isA<FakeTimer>().duration.equals(kLocalEchoDebounceDuration),
        (it) => it.isA<FakeTimer>().duration.equals(kSendMessageRetryWaitPeriod),
        (it) => it.isA<FakeTimer>().duration.equals(Duration.zero),  // timer for send-message response
      ]);

      // Complete the send request with an error.
      await check(sendMessageFuture).throws();
      check(store.outboxMessages).values.single.identicalTo(outboxMessage);
      check(outboxMessage).state.equals(OutboxMessageState.failed);
      // Both the debounce timer and wait period timer should have been cancelled.
      check(async.pendingTimers).isEmpty();
    }));

    test('message failed to send after debounce timeout', () => awaitFakeAsync((async) async {
      // Set up to fail the send request, but only after the debounce timeout.
      await prepareSendMessageToFail(
        delay: kLocalEchoDebounceDuration + const Duration(milliseconds: 1));
      check(outboxMessage).state.equals(OutboxMessageState.hidden);

      // Wait for just enough time for the debounce timer to expire, but not
      // for the send request to complete.
      async.elapse(kLocalEchoDebounceDuration);
      check(store.outboxMessages).values.single.identicalTo(outboxMessage);
      check(outboxMessage).state.equals(OutboxMessageState.waiting);

      // Complete the send request with an error.
      async.elapse(const Duration(milliseconds: 1));
      await check(sendMessageFuture).throws();
      check(store.outboxMessages).values.single.identicalTo(outboxMessage);
      check(outboxMessage).state.equals(OutboxMessageState.failed);
    }));

    test('message failed to send, message event arrives', () async {
      // Set up to fail the send request immediately.
      await prepareSendMessageToFail();
      await check(sendMessageFuture).throws();
      check(outboxMessage).state.equals(OutboxMessageState.failed);

      // Handle the event when the outbox message is in failed state.
      // The outbox message should be removed without errors.
      await store.handleEvent(eg.messageEvent(message,
        localMessageId: outboxMessage.localMessageId));
      check(store.outboxMessages).isEmpty();
      // The outbox message should no longer be updated because it is not in
      // the store any more.
      check(outboxMessage).state.equals(OutboxMessageState.failed);
    });

    test('send request pending until after kSendMessageRetryWaitPeriod, completes successfully, then message event arrives', () => awaitFakeAsync((async) async {
      // Send a message, but keep it pending until after reaching
      // [kSendMessageRetryWaitPeriod].
      await prepareSendMessageToSucceed(
        delay: kSendMessageRetryWaitPeriod + Duration(seconds: 1));
      async.elapse(kLocalEchoDebounceDuration);
      check(outboxMessage).state.equals(OutboxMessageState.waiting);

      // Wait till we reach [kSendMessageRetryWaitPeriod] after the send request
      // was initiated, but before it actually completes.
      assert(kSendMessageRetryWaitPeriod > kLocalEchoDebounceDuration);
      async.elapse(kSendMessageRetryWaitPeriod - kLocalEchoDebounceDuration);
      check(outboxMessage).state.equals(OutboxMessageState.waitPeriodExpired);

      // Wait till the send request completes successfully.
      async.elapse(const Duration(seconds: 1));
      await sendMessageFuture;
      // The outbox message should remain in the store …
      check(store.outboxMessages).values.single.identicalTo(outboxMessage);
      // … and stay in the waitPeriodExpired state.
      check(outboxMessage).state.equals(OutboxMessageState.waitPeriodExpired);

      // Handle the message event.  The outbox message should get removed
      // without errors.
      await store.handleEvent(eg.messageEvent(message,
        localMessageId: outboxMessage.localMessageId));
      check(store.outboxMessages).isEmpty();
      // The outbox message should no longer be updated because it is not in
      // the store any more.
      check(outboxMessage).state.equals(OutboxMessageState.waitPeriodExpired);
    }));

    test('send request pending until after kSendMessageRetryWaitPeriod, then fails', () => awaitFakeAsync((async) async {
      // Send a message, but keep it pending until after reaching
      // [kSendMessageRetryWaitPeriod].
      await prepareSendMessageToFail(
        delay: kSendMessageRetryWaitPeriod + Duration(seconds: 1));
      async.elapse(kLocalEchoDebounceDuration);
      check(outboxMessage).state.equals(OutboxMessageState.waiting);

      // Wait till we reach [kSendMessageRetryWaitPeriod] after the send request
      // was initiated, but before it fails.
      assert(kSendMessageRetryWaitPeriod > kLocalEchoDebounceDuration);
      async.elapse(kSendMessageRetryWaitPeriod - kLocalEchoDebounceDuration);
      check(outboxMessage).state.equals(OutboxMessageState.waitPeriodExpired);

      // Wait till the send request fails.
      async.elapse(Duration(seconds: 1));
      await check(sendMessageFuture).throws();
      // The outbox message should remain in the store …
      check(store.outboxMessages).values.single.identicalTo(outboxMessage);
      // … and transition to failed state.
      check(outboxMessage).state.equals(OutboxMessageState.failed);
    }));

    test('send request completes, message event does not arrive after kSendMessageRetryWaitPeriod', () => awaitFakeAsync((async) async {
      // Send a message and have it complete successfully without wait.
      await prepareSendMessageToSucceed();
      async.elapse(kLocalEchoDebounceDuration);
      check(outboxMessage).state.equals(OutboxMessageState.waiting);

      // Wait till we reach [kSendMessageRetryWaitPeriod] after the send request
      // was initiated.
      assert(kSendMessageRetryWaitPeriod > kLocalEchoDebounceDuration);
      async.elapse(kSendMessageRetryWaitPeriod - kLocalEchoDebounceDuration);
      // The outbox message should transition to waitPeriodExpired state.
      check(outboxMessage).state.equals(OutboxMessageState.waitPeriodExpired);
    }));

    test('send request fails, message event does not arrive after kSendMessageRetryWaitPeriod', () => awaitFakeAsync((async) async {
      // Send a message and have it fail without wait.
      await prepareSendMessageToFail();
      async.elapse(kLocalEchoDebounceDuration);
      check(outboxMessage).state.equals(OutboxMessageState.failed);

      // Wait till we reach [kSendMessageRetryWaitPeriod] after the send request
      // was initiated.
      assert(kSendMessageRetryWaitPeriod > kLocalEchoDebounceDuration);
      async.elapse(kSendMessageRetryWaitPeriod - kLocalEchoDebounceDuration);
      // The outbox message should stay in failed state,
      // and it should not transition to waitPeriodExpired state.
      check(outboxMessage).state.equals(OutboxMessageState.failed);
    }));

    test('when sending to empty topic, interpret topic like the server does when creating outbox message', () => awaitFakeAsync((async) async {
      // Send a message and have it complete successfully without wait.
      await prepareSendMessageToSucceed(
        destination: StreamDestination(stream.streamId, TopicName('(no topic)')),
        zulipFeatureLevel: 334);
      async.elapse(kLocalEchoDebounceDuration);
      check(outboxMessage).conversation.isA<StreamConversation>()
        .topic.equals(eg.t(eg.defaultRealmEmptyTopicDisplayName));
    }));

    test('legacy: when sending to empty topic, interpret topic like the server does when creating outbox message', () => awaitFakeAsync((async) async {
      // Send a message and have it complete successfully without wait.
      await prepareSendMessageToSucceed(
        destination: StreamDestination(stream.streamId, TopicName('(no topic)')),
        zulipFeatureLevel: 333);
      async.elapse(kLocalEchoDebounceDuration);
      check(outboxMessage).conversation.isA<StreamConversation>()
        .topic.equals(eg.t('(no topic)'));
    }));
  });

  test('removeOutboxMessage', () async {
    final stream = eg.stream();
    await prepare(stream: stream);
    await prepareMessages([]);

    for (int i = 0; i < 10; i++) {
      connection.prepare(json: SendMessageResult(id: 1).toJson());
      await store.sendMessage(
        destination: StreamDestination(stream.streamId, eg.t('topic')),
        content: 'content');
    }

    final localMessageIds = store.outboxMessages.keys.toList();
    store.removeOutboxMessage(localMessageIds.removeAt(5));
    check(store.outboxMessages.keys).deepEquals(localMessageIds);
  });

  group('reconcileMessages', () {
    test('from empty', () async {
      await prepare();
      check(store.messages).isEmpty();
      final message1 = eg.streamMessage();
      final message2 = eg.streamMessage();
      final message3 = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]);
      final messages = <Message>[message1, message2, message3];
      store.reconcileMessages(messages);
      check(messages).deepEquals(
        [message1, message2, message3]
          .map((m) => (Subject<Object?> it) => it.identicalTo(m)));
      check(store.messages).deepEquals({
        for (final m in messages) m.id: m,
      });
    });

    test('from not-empty', () async {
      await prepare();
      final message1 = eg.streamMessage();
      final message2 = eg.streamMessage();
      final message3 = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]);
      final messages = <Message>[message1, message2, message3];
      await addMessages(messages);
      final newMessage = eg.streamMessage();
      store.reconcileMessages([newMessage]);
      check(messages).deepEquals(
        [message1, message2, message3]
          .map((m) => (Subject<Object?> it) => it.identicalTo(m)));
      check(store.messages).deepEquals({
        for (final m in messages) m.id: m,
        newMessage.id: newMessage,
      });
    });

    test('on ID collision, new message does not clobber old in store.messages', () async {
      await prepare();
      final message = eg.streamMessage(id: 1, content: '<p>foo</p>');
      await addMessages([message]);
      check(store.messages).deepEquals({1: message});
      final newMessage = eg.streamMessage(id: 1, content: '<p>bar</p>');
      final messages = [newMessage];
      store.reconcileMessages(messages);
      check(messages).single.identicalTo(message);
      check(store.messages).deepEquals({1: message});
    });
  });

  group('handleMessageEvent', () {
    test('from empty', () async {
      await prepare();
      check(store.messages).isEmpty();

      final newMessage = eg.streamMessage();
      await store.handleEvent(eg.messageEvent(newMessage));
      check(store.messages).deepEquals({
        newMessage.id: newMessage,
      });
    });

    test('from not-empty', () async {
      await prepare();
      final messages = <Message>[
        eg.streamMessage(),
        eg.streamMessage(),
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]),
      ];
      await addMessages(messages);
      check(store.messages).deepEquals({
        for (final m in messages) m.id: m,
      });

      final newMessage = eg.streamMessage();
      await store.handleEvent(eg.messageEvent(newMessage));
      check(store.messages).deepEquals({
        for (final m in messages) m.id: m,
        newMessage.id: newMessage,
      });
    });

    test('new message clobbers old on ID collision', () async {
      await prepare();
      final message = eg.streamMessage(id: 1, content: '<p>foo</p>');
      await addMessages([message]);
      check(store.messages).deepEquals({1: message});

      final newMessage = eg.streamMessage(id: 1, content: '<p>bar</p>');
      await store.handleEvent(eg.messageEvent(newMessage));
      check(store.messages).deepEquals({1: newMessage});
    });
  });

  group('handleUpdateMessageEvent', () {
    test('update timestamps on all messages', () async {
      const t1 = 1718748879;
      const t2 = t1 + 60;
      final message1 = eg.streamMessage(lastEditTimestamp: null);
      final message2 = eg.streamMessage(lastEditTimestamp: t1);
      // This event is a bit artificial, but convenient.
      // TODO use a realistic move-messages event here
      final updateEvent = Event.fromJson({
        ...eg.updateMessageEditEvent(message1).toJson(),
        'message_ids': [message1.id, message2.id],
        'edit_timestamp': t2,
      }) as UpdateMessageEvent;
      await prepare();
      await prepareMessages([message1, message2]);

      check(store).messages.values.unorderedMatches(<Condition<Message>>[
        (it) => it.lastEditTimestamp.isNull,
        (it) => it.lastEditTimestamp.equals(t1),
      ]);

      await store.handleEvent(updateEvent);
      checkNotifiedOnce();
      check(store).messages.values.unorderedMatches(<Condition<Message>>[
        (it) => it.lastEditTimestamp.equals(t2),
        (it) => it.lastEditTimestamp.equals(t2),
      ]);
    });

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
      await prepareMessages([originalMessage]);

      final message = store.messages.values.single;
      check(message)
        ..content.not((it) => it.equals(updateEvent.renderedContent!))
        ..lastEditTimestamp.isNull()
        ..flags.not((it) => it.deepEquals(updateEvent.flags))
        ..isMeMessage.not((it) => it.equals(updateEvent.isMeMessage!))
        ..editState.equals(MessageEditState.none);

      await store.handleEvent(updateEvent);
      checkNotifiedOnce();
      check(store).messages.values.single
        ..identicalTo(message)
        ..content.equals(updateEvent.renderedContent!)
        ..lastEditTimestamp.equals(updateEvent.editTimestamp)
        ..flags.equals(updateEvent.flags)
        ..isMeMessage.equals(updateEvent.isMeMessage!)
        ..editState.equals(MessageEditState.edited);
    });

    test('ignore when message unknown', () async {
      final originalMessage = eg.streamMessage(
        content: "<p>Hello, world</p>");
      final updateEvent = eg.updateMessageEditEvent(originalMessage,
        messageId: originalMessage.id + 1,
        renderedContent: "<p>Hello, edited</p>",
      );
      await prepare();
      await prepareMessages([originalMessage]);

      await store.handleEvent(updateEvent);
      checkNotNotified();
      check(store).messages.values.single
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
      await prepareMessages([originalMessage]);
      final message = store.messages.values.single;

      await store.handleEvent(updateEvent);
      checkNotifiedOnce();
      check(store).messages.values.single
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

    group('Handle message edit state update', () {
      late List<StreamMessage> origMessages;

      Future<void> prepareOrigMessages({
        required String origTopic,
        String? origContent,
      }) async {
        origMessages = List.generate(2, (i) => eg.streamMessage(
          topic: origTopic,
          content: origContent,
        ));
        await prepare();
        await prepareMessages(origMessages);
      }

      test('message not moved update', () async {
        await prepareOrigMessages(origTopic: 'origTopic');
        await store.handleEvent(eg.updateMessageEditEvent(origMessages[0]));
        checkNotifiedOnce();
        check(store).messages[origMessages[0].id].editState.equals(MessageEditState.edited);
        check(store).messages[origMessages[1].id].editState.equals(MessageEditState.none);
      });

      test('message topic moved update', () async {
        await prepareOrigMessages(origTopic: 'old topic');
        final originalDisplayRecipient = origMessages[0].displayRecipient!;
        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: origMessages,
          newTopicStr: 'new topic'));
        checkNotified(count: 2);
        check(store).messages.values.every(((message) =>
          message.isA<StreamMessage>()
            ..editState.equals(MessageEditState.moved)
            ..displayRecipient.equals(originalDisplayRecipient)));
      });

      test('message topic resolved update', () async {
        await prepareOrigMessages(origTopic: 'new topic');
        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: origMessages,
          newTopicStr: '✔ new topic'));
        checkNotified(count: 2);
        check(store).messages.values.every(((message) => message.editState.equals(MessageEditState.none)));
      });

      test('message topic unresolved update', () async {
        await prepareOrigMessages(origTopic: '✔ new topic');
        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: origMessages,
          newTopicStr: 'new topic'));
        checkNotified(count: 2);
        check(store).messages.values.every(((message) => message.editState.equals(MessageEditState.none)));
      });

      test('message topic both resolved and edited update', () async {
        await prepareOrigMessages(origTopic: 'new topic');
        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: origMessages,
          newTopicStr: '✔ new topic 2'));
        checkNotified(count: 2);
        check(store).messages.values.every(((message) => message.editState.equals(MessageEditState.moved)));
      });

      test('message topic both unresolved and edited update', () async {
        await prepareOrigMessages(origTopic: '✔ new topic');
        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: origMessages,
          newTopicStr: 'new topic 2'));
        checkNotified(count: 2);
        check(store).messages.values.every(((message) => message.editState.equals(MessageEditState.moved)));
      });

      test('message stream moved without topic change', () async {
        await prepareOrigMessages(origTopic: 'topic');
        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: origMessages,
          newStreamId: 20));
        checkNotified(count: 2);
        check(store).messages.values.every(((message) =>
          message.isA<StreamMessage>()
            ..editState.equals(MessageEditState.moved)
            ..displayRecipient.equals(null)));
      });

      test('message is both moved and updated', () async {
        await prepareOrigMessages(origTopic: 'topic', origContent: 'old content');
        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: origMessages,
          newStreamId: 20,
          newContent: 'new content'));
        checkNotified(count: 2);
        check(store).messages[origMessages[0].id].editState.equals(MessageEditState.edited);
        check(store).messages[origMessages[1].id].editState.equals(MessageEditState.moved);
      });
    });
  });

  group('handleDeleteMessageEvent', () {
    test('delete an unknown message', () async {
      final message1 = eg.streamMessage();
      final message2 = eg.streamMessage();
      await prepare();
      await prepareMessages([message1]);
      await store.handleEvent(eg.deleteMessageEvent([message2]));
      checkNotNotified();
      check(store).messages.values.single.id.equals(message1.id);
    });

    test('delete messages', () async {
      final message1 = eg.streamMessage();
      final message2 = eg.streamMessage();
      await prepare();
      await prepareMessages([message1, message2]);
      await store.handleEvent(eg.deleteMessageEvent([message1, message2]));
      checkNotifiedOnce();
      check(store).messages.isEmpty();
    });

    test('delete an unknown message with a known message', () async {
      final message1 = eg.streamMessage();
      final message2 = eg.streamMessage();
      final message3 = eg.streamMessage();
      await prepare();
      await prepareMessages([message1, message2]);
      await store.handleEvent(eg.deleteMessageEvent([message2, message3]));
      checkNotifiedOnce();
      check(store).messages.values.single.id.equals(message1.id);
    });
  });

  group('handleUpdateMessageFlagsEvent', () {
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
      test('message is unknown', () async {
        await prepare();
        final message = eg.streamMessage(flags: []);
        await prepareMessages([message]);
        await store.handleEvent(mkAddEvent(MessageFlag.read, [2]));
        checkNotNotified();
        check(store).messages.values.single.flags.deepEquals([]);
      });

      test('affected message, unaffected message, absent message', () async {
        await prepare();
        final message1 = eg.streamMessage(flags: []);
        final message2 = eg.streamMessage(flags: []);
        await prepareMessages([message1, message2]);
        await store.handleEvent(mkAddEvent(MessageFlag.read, [message2.id, 3]));
        checkNotifiedOnce();
        check(store).messages
          ..[message1.id].flags.deepEquals([])
          ..[message2.id].flags.deepEquals([MessageFlag.read]);
      });

      test('all: true; we have some known messages', () async {
        await prepare();
        final message1 = eg.streamMessage(flags: []);
        final message2 = eg.streamMessage(flags: []);
        await prepareMessages([message1, message2]);
        await store.handleEvent(mkAddEvent(MessageFlag.read, [], all: true));
        checkNotifiedOnce();
        check(store).messages
          ..[message1.id].flags.deepEquals([MessageFlag.read])
          ..[message2.id].flags.deepEquals([MessageFlag.read]);
      });

      test('all: true; we don\'t know about any messages', () async {
        await prepare();
        await prepareMessages([]);
        await store.handleEvent(mkAddEvent(MessageFlag.read, [], all: true));
        checkNotNotified();
      });

      test('other flags not clobbered', () async {
        final message = eg.streamMessage(flags: [MessageFlag.starred]);
        await prepare();
        await prepareMessages([message]);
        await store.handleEvent(mkAddEvent(MessageFlag.read, [message.id]));
        checkNotifiedOnce();
        check(store).messages.values
          .single.flags.deepEquals([MessageFlag.starred, MessageFlag.read]);
      });
    });

    group('remove flag', () {
      test('message is unknown', () async {
        await prepare();
        final message = eg.streamMessage(flags: [MessageFlag.read]);
        await prepareMessages([message]);
        await store.handleEvent(mkAddEvent(MessageFlag.read, [2]));
        checkNotNotified();
        check(store).messages.values
          .single.flags.deepEquals([MessageFlag.read]);
      });

      test('affected message, unaffected message, absent message', () async {
        await prepare();
        final message1 = eg.streamMessage(flags: [MessageFlag.read]);
        final message2 = eg.streamMessage(flags: [MessageFlag.read]);
        final message3 = eg.streamMessage(flags: [MessageFlag.read]);
        await prepareMessages([message1, message2]);
        await store.handleEvent(mkRemoveEvent(MessageFlag.read, [message2, message3]));
        checkNotifiedOnce();
        check(store).messages
          ..[message1.id].flags.deepEquals([MessageFlag.read])
          ..[message2.id].flags.deepEquals([]);
      });

      test('other flags not affected', () async {
        final message = eg.streamMessage(flags: [MessageFlag.starred, MessageFlag.read]);
        await prepare();
        await prepareMessages([message]);
        await store.handleEvent(mkRemoveEvent(MessageFlag.read, [message]));
        checkNotifiedOnce();
        check(store).messages.values
          .single.flags.deepEquals([MessageFlag.starred]);
      });
    });
  });

  group('handleReactionEvent', () {
    test('add reaction', () async {
      final originalMessage = eg.streamMessage(reactions: []);
      await prepare();
      await prepareMessages([originalMessage]);
      final message = store.messages.values.single;

      await store.handleEvent(
        eg.reactionEvent(eg.unicodeEmojiReaction, ReactionOp.add, originalMessage.id));
      checkNotifiedOnce();
      check(store.messages).values.single
        ..identicalTo(message)
        ..reactions.isNotNull().jsonEquals([eg.unicodeEmojiReaction]);
    });

    test('add reaction; message is unknown', () async {
      final someMessage = eg.streamMessage(reactions: []);
      await prepare();
      await prepareMessages([someMessage]);
      await store.handleEvent(
        eg.reactionEvent(eg.unicodeEmojiReaction, ReactionOp.add, 1000));
      checkNotNotified();
      check(store.messages).values.single
        .reactions.isNull();
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
      await prepareMessages([originalMessage]);
      final message = store.messages.values.single;

      await store.handleEvent(
        eg.reactionEvent(eventReaction, ReactionOp.remove, originalMessage.id));
      checkNotifiedOnce();
      check(store.messages).values.single
        ..identicalTo(message)
        ..reactions.isNotNull().jsonEquals([reaction2, reaction3]);
    });

    test('remove reaction; message is unknown', () async {
      final someMessage = eg.streamMessage(reactions: [eg.unicodeEmojiReaction]);
      await prepare();
      await prepareMessages([someMessage]);
      await store.handleEvent(
        eg.reactionEvent(eg.unicodeEmojiReaction, ReactionOp.remove, 1000));
      checkNotNotified();
      check(store.messages).values.single
        .reactions.isNotNull().jsonEquals([eg.unicodeEmojiReaction]);
    });
  });

  group('handle Poll related events', () {
    Condition<Object?> conditionPollOption(String text, {Iterable<int>? voters}) =>
      (it) => it.isA<PollOption>()..text.equals(text)..voters.deepEquals(voters ?? []);

    Subject<Poll> checkPoll(Message message) =>
      check(store.messages[message.id]).isNotNull().poll.isNotNull();

    late int pollNotifiedCount;

    void checkPollNotified({required int count}) {
      check(pollNotifiedCount).equals(count);
      pollNotifiedCount = 0;
      // This captures any unchecked [messageList] notifications, to verify
      // that poll live-updates do not trigger broader rebuilds.
      checkNotNotified();
    }
    void checkPollNotNotified() => checkPollNotified(count: 0);
    void checkPollNotifiedOnce() => checkPollNotified(count: 1);

    group('handleSubmessageEvent', () {
      Future<Message> preparePollMessage({
        String? question,
        List<(String, Iterable<int>)>? optionVoterIdsPairs,
        User? messageSender,
      }) async {
        final effectiveMessageSender = messageSender ?? eg.selfUser;
        final message = eg.streamMessage(sender: effectiveMessageSender);
        final submessages = [
          eg.submessage(senderId: effectiveMessageSender.userId,
            content: eg.pollWidgetData(
              question: question ?? 'example question',
              options: (optionVoterIdsPairs != null)
                ? optionVoterIdsPairs.map((e) => e.$1).toList()
                : ['foo', 'bar'])),
          if (optionVoterIdsPairs != null)
            for (int i = 0; i < optionVoterIdsPairs.length; i++)
              ...[
                for (final voter in optionVoterIdsPairs[i].$2)
                  eg.submessage(senderId: voter,
                    content: PollVoteEventSubmessage(
                      key: PollEventSubmessage.optionKey(senderId: null, idx: i),
                      op: PollVoteOp.add)),
              ],
        ];
        await prepare();
        // Perform a single-message initial message fetch for [messageList] with
        // submessages.
        connection.prepare(json:
          eg.newestGetMessagesResult(foundOldest: true, messages: []).toJson()
            ..['messages'] = [{
              ...message.toJson(),
              "submessages": submessages.map(deepToJson).toList(),
            }]);
        await messageList.fetchInitial();
        checkNotifiedOnce();
        pollNotifiedCount = 0;
        store.messages[message.id]!.poll!.addListener(() {
          pollNotifiedCount++;
        });
        return message;
      }

      test('message is unknown', () async {
        await prepare();
        await store.handleEvent(eg.submessageEvent(1000, eg.selfUser.userId,
          content: PollQuestionEventSubmessage(question: 'New question')));
        checkNotNotified();
      });

      test('message has no submessages', () async {
        final message = eg.streamMessage();
        await prepare();
        await prepareMessages([message]);
        await store.handleEvent(eg.submessageEvent(message.id, eg.otherUser.userId,
          content: PollQuestionEventSubmessage(question: 'New question')));
        checkNotNotified();
        check(store.messages[message.id]).isNotNull().poll.isNull();
      });

      test('ignore submessage event with malformed content', () async {
        final message = await preparePollMessage(question: 'Old question');
        await store.handleEvent(SubmessageEvent(
          id: 0, msgType: SubmessageType.widget, submessageId: 123,
          messageId: message.id,
          senderId: eg.selfUser.userId,
          content: jsonEncode({
            'type': 'question',
            // Invalid type for question
            'question': 100,
          })));
        checkPollNotNotified();
        checkPoll(message).question.equals('Old question');
      });

      group('question event', () {
        test('update question', () async {
          final message = await preparePollMessage(question: 'Old question');
          await store.handleEvent(eg.submessageEvent(message.id, eg.selfUser.userId,
            content: PollQuestionEventSubmessage(question: 'New question')));
          checkPollNotifiedOnce();
          checkPoll(message).question.equals('New question');
        });

        test('unauthorized question edits', () async {
          final message = await preparePollMessage(
            question: 'Old question',
            messageSender: eg.otherUser,
          );
          checkPoll(message).question.equals('Old question');
          await store.handleEvent(eg.submessageEvent(message.id, eg.selfUser.userId,
            content: PollQuestionEventSubmessage(question: 'edit')));
          checkPoll(message).question.equals('Old question');
        });
      });

      group('new option event', () {
        late Message message;

        Future<void> handleNewOptionEvent(User sender, {
          required String option,
          required int idx,
        }) async {
          await store.handleEvent(eg.submessageEvent(message.id, sender.userId,
            content: PollNewOptionEventSubmessage(option: option, idx: idx)));
          checkPollNotifiedOnce();
        }

        test('add option', () async {
          message = await preparePollMessage(
            optionVoterIdsPairs: [('bar', [])]);
          await handleNewOptionEvent(eg.otherUser, option: 'baz', idx: 0);
          checkPoll(message).options.deepEquals([
            conditionPollOption('bar'),
            conditionPollOption('baz'),
          ]);
        });

        test('option with duplicate text ignored', () async {
          message = await preparePollMessage(
            optionVoterIdsPairs: [('existing', [])]);
          checkPoll(message).options.deepEquals([conditionPollOption('existing')]);
          await handleNewOptionEvent(eg.otherUser, option: 'existing', idx: 0);
          checkPoll(message).options.deepEquals([conditionPollOption('existing')]);
        });

        test('option index limit exceeded', () async{
          message = await preparePollMessage(
            question: 'favorite number',
            optionVoterIdsPairs: List.generate(1001, (i) => ('$i', [])),
          );
          checkPoll(message).options.length.equals(1001);
          await handleNewOptionEvent(eg.otherUser, option: 'baz', idx: 1001);
          checkPoll(message).options.length.equals(1001);
        });
      });

      group('vote event', () {
        late Message message;

        Future<void> handleVoteEvent(String key, PollVoteOp op, User voter) async {
          await store.handleEvent(eg.submessageEvent(message.id, voter.userId,
            content: PollVoteEventSubmessage(key: key, op: op)));
          checkPollNotifiedOnce();
        }

        test('add votes', () async {
          message = await preparePollMessage();

          String optionKey(int index) =>
            PollEventSubmessage.optionKey(senderId: null, idx: index);

          await handleVoteEvent(optionKey(0), PollVoteOp.add, eg.otherUser);
          checkPoll(message).options.deepEquals([
            conditionPollOption('foo', voters: [eg.otherUser.userId]),
            conditionPollOption('bar', voters: []),
          ]);

          await handleVoteEvent(optionKey(1), PollVoteOp.add, eg.otherUser);
          checkPoll(message).options.deepEquals([
            conditionPollOption('foo', voters: [eg.otherUser.userId]),
            conditionPollOption('bar', voters: [eg.otherUser.userId]),
          ]);

          await handleVoteEvent(optionKey(0), PollVoteOp.add, eg.selfUser);
          checkPoll(message).options.deepEquals([
            conditionPollOption('foo', voters: [eg.otherUser.userId, eg.selfUser.userId]),
            conditionPollOption('bar', voters: [eg.otherUser.userId]),
          ]);
        });

        test('remove votes', () async {
          message = await preparePollMessage(optionVoterIdsPairs: [
            ('foo', [eg.otherUser.userId, eg.selfUser.userId]),
            ('bar', [eg.selfUser.userId]),
          ]);

          String optionKey(int index) =>
            PollEventSubmessage.optionKey(senderId: null, idx: index);

          await handleVoteEvent(optionKey(0), PollVoteOp.remove, eg.otherUser);
          checkPoll(message).options.deepEquals([
            conditionPollOption('foo', voters: [eg.selfUser.userId]),
            conditionPollOption('bar', voters: [eg.selfUser.userId]),
          ]);

          await handleVoteEvent(optionKey(1), PollVoteOp.remove, eg.selfUser);
          checkPoll(message).options.deepEquals([
            conditionPollOption('foo', voters: [eg.selfUser.userId]),
            conditionPollOption('bar', voters: []),
          ]);
        });

        test('vote for unknown options', () async {
          message = await preparePollMessage(optionVoterIdsPairs: [
            ('foo', [eg.selfUser.userId]),
            ('bar', []),
          ]);

          final unknownOptionKey = PollEventSubmessage.optionKey(
            senderId: eg.selfUser.userId,
            idx: 10,
          );

          await handleVoteEvent(unknownOptionKey, PollVoteOp.remove, eg.selfUser);
          checkPoll(message).options.deepEquals([
            conditionPollOption('foo', voters: [eg.selfUser.userId]),
            conditionPollOption('bar', voters: []),
          ]);

          await handleVoteEvent(unknownOptionKey, PollVoteOp.add, eg.selfUser);
          checkPoll(message).options.deepEquals([
            conditionPollOption('foo', voters: [eg.selfUser.userId]),
            conditionPollOption('bar', voters: []),
          ]);
        });

        test('ignore invalid vote op', () async {
          message = await preparePollMessage(
            optionVoterIdsPairs: [('foo', [])]);
          checkPoll(message).options.deepEquals([conditionPollOption('foo')]);
          await store.handleEvent(eg.submessageEvent(message.id, eg.otherUser.userId,
            content: PollVoteEventSubmessage(
              key: PollEventSubmessage.optionKey(senderId: null, idx: 0),
              op: PollVoteOp.unknown)));
          checkPollNotNotified();
          checkPoll(message).options.deepEquals([conditionPollOption('foo')]);
        });
      });
    });

    group('handleMessageEvent with initial submessages', () {
      late Message message;

      final defaultPollWidgetData = eg.pollWidgetData(
        question: 'example question',
        options: ['foo', 'bar'],
      );

      final defaultOptionConditions = [
        conditionPollOption('foo'),
        conditionPollOption('bar'),
      ];

      Future<void> handlePollMessageEvent({
        SubmessageData? widgetData,
        List<(User sender, PollEventSubmessage event)> events = const [],
      }) async {
        message = eg.streamMessage(sender: eg.otherUser, submessages: [
          eg.submessage(
            content: widgetData ?? defaultPollWidgetData,
            senderId: eg.otherUser.userId),
          for (final (sender, event) in events)
            eg.submessage(content: event, senderId: sender.userId),
        ]);

        await prepare();
        await store.handleEvent(eg.messageEvent(message));
      }

      test('smoke', () async {
        await handlePollMessageEvent();
        checkPoll(message)
          ..question.equals(defaultPollWidgetData.extraData.question)
          ..options.deepEquals(defaultOptionConditions);
      });

      test('contains new question event', () async {
        await handlePollMessageEvent(events: [
          (eg.otherUser, PollQuestionEventSubmessage(question: 'new question')),
        ]);
        checkPoll(message)
          ..question.equals('new question')
          ..options.deepEquals(defaultOptionConditions);
      });

      test('contains new option event', () async {
        await handlePollMessageEvent(events: [
          (eg.otherUser, PollNewOptionEventSubmessage(idx: 3, option: 'baz')),
          (eg.selfUser,  PollNewOptionEventSubmessage(idx: 0, option: 'quz')),
        ]);
        checkPoll(message)
          ..question.equals(defaultPollWidgetData.extraData.question)
          ..options.deepEquals([
            ...defaultOptionConditions,
            conditionPollOption('baz'),
            conditionPollOption('quz'),
          ]);
      });

      test('contains vote events on initial canned options', () async {
        await handlePollMessageEvent(events: [
          (eg.otherUser, PollVoteEventSubmessage(key: 'canned,1', op: PollVoteOp.add)),
          (eg.otherUser, PollVoteEventSubmessage(key: 'canned,2', op: PollVoteOp.add)),
          (eg.otherUser, PollVoteEventSubmessage(key: 'canned,2', op: PollVoteOp.remove)),
          (eg.selfUser,  PollVoteEventSubmessage(key: 'canned,1', op: PollVoteOp.add)),
        ]);
        checkPoll(message)
          ..question.equals(defaultPollWidgetData.extraData.question)
          ..options.deepEquals([
            conditionPollOption('foo'),
            conditionPollOption('bar', voters: [eg.otherUser.userId, eg.selfUser.userId]),
          ]);
      });

      test('contains vote events on post-creation options', () async {
        await handlePollMessageEvent(events: [
          (eg.otherUser, PollNewOptionEventSubmessage(idx: 0, option: 'baz')),
          (eg.otherUser, PollVoteEventSubmessage(key: '${eg.otherUser.userId},0', op: PollVoteOp.add)),
          (eg.selfUser,  PollVoteEventSubmessage(key: '${eg.otherUser.userId},0', op: PollVoteOp.add)),
        ]);
        checkPoll(message)
          ..question.equals(defaultPollWidgetData.extraData.question)
          ..options.deepEquals([
            ...defaultOptionConditions,
            conditionPollOption('baz', voters: [eg.otherUser.userId, eg.selfUser.userId]),
          ]);
      });

      test('content with invalid widget_type', () async {
        message = eg.streamMessage(sender: eg.otherUser, submessages: [
          Submessage(
            msgType: SubmessageType.widget,
            content: jsonEncode({'widget_type': 'other'}),
            senderId: eg.otherUser.userId,
          ),
        ]);
        await prepare();
        await store.handleEvent(eg.messageEvent(message));
        check(store.messages[message.id]).isNotNull().poll.isNull();
      });
    });
  });
}
