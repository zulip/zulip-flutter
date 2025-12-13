import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:crypto/crypto.dart';
import 'package:fake_async/fake_async.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/exception.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
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
import 'binding.dart';
import 'message_checks.dart';
import 'message_list_test.dart';
import 'store_checks.dart';
import 'test_store.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  // These "late" variables are the common state operated on by each test.
  // Each test case calls [prepare] to initialize them.
  late Subscription? subscription;
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
    ZulipStream? stream,
    bool isChannelSubscribed = true,
    int? zulipFeatureLevel,
  }) async {
    stream ??= eg.stream(streamId: eg.defaultStreamMessageStreamId);
    final selfAccount = eg.selfAccount.copyWith(zulipFeatureLevel: zulipFeatureLevel);
    store = eg.store(account: selfAccount,
      initialSnapshot: eg.initialSnapshot(zulipFeatureLevel: zulipFeatureLevel));
    await store.addStream(stream);
    if (isChannelSubscribed) {
      subscription = eg.subscription(stream);
      await store.addSubscription(subscription!);
    } else {
      subscription = null;
    }
    connection = store.connection as FakeApiConnection;
    notifiedCount = 0;
    messageList = MessageListView.init(store: store,
        narrow: const CombinedFeedNarrow(),
        anchor: AnchorCode.newest)
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
  Future<void> prepareMessages(
    List<Message> messages, {
    bool foundOldest = false,
  }) async {
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
      json: SendMessageResult(id: 1).toJson(),
      delay: const Duration(seconds: 1));
    unawaited(store.sendMessage(
      destination: StreamDestination(stream.streamId, eg.t('topic')),
      content: 'content'));
    check(async.pendingTimers).deepEquals(<Condition<Object?>>[
      (it) => it.isA<FakeTimer>().duration.equals(kLocalEchoDebounceDuration),
      (it) => it.isA<FakeTimer>().duration.equals(kSendMessageOfferRestoreWaitPeriod),
      (it) => it.isA<FakeTimer>().duration.equals(const Duration(seconds: 1)),
    ]);

    store.dispose();
    check(async.pendingTimers).single.duration.equals(const Duration(seconds: 1));
  }));

  group('sendMessage', () {
    test('smoke', () async {
      final stream = eg.stream();
      final subscription = eg.subscription(stream);
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        queueId: 'fb67bf8a-c031-47cc-84cf-ed80accacda8'));
      await store.addStream(stream);
      await store.addSubscription(subscription);
      final connection = store.connection as FakeApiConnection;
      connection.prepare(json: SendMessageResult(id: 12345).toJson());
      await store.sendMessage(
        destination: StreamDestination(stream.streamId, eg.t('world')),
        content: 'hello');
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages')
        ..bodyFields.deepEquals({
          'type': 'stream',
          'to': stream.streamId.toString(),
          'topic': 'world',
          'content': 'hello',
          'read_by_sender': 'true',
          'queue_id': 'fb67bf8a-c031-47cc-84cf-ed80accacda8',
          'local_id': store.outboxMessages.keys.single.toString(),
        });
    });

    final stream = eg.stream();
    final streamDestination = StreamDestination(stream.streamId, eg.t('some topic'));
    late StreamMessage message;

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

    Subject<OutboxMessageState> checkState() =>
      check(store.outboxMessages).values.single.state;

    Future<void> prepareOutboxMessage({
      MessageDestination? destination,
      int? zulipFeatureLevel,
    }) async {
      message = eg.streamMessage(stream: stream);
      await prepare(stream: stream, zulipFeatureLevel: zulipFeatureLevel);
      await prepareMessages([eg.streamMessage(stream: stream)]);
      connection.prepare(json: SendMessageResult(id: 1).toJson());
      await store.sendMessage(
        destination: destination ?? streamDestination, content: 'content');
    }

    late Future<void> outboxMessageFailFuture;
    Future<void> prepareOutboxMessageToFailAfterDelay(Duration delay) async {
      message = eg.streamMessage(stream: stream);
      await prepare(stream: stream);
      await prepareMessages([eg.streamMessage(stream: stream)]);
      connection.prepare(httpException: SocketException('failed'), delay: delay);
      outboxMessageFailFuture = store.sendMessage(
        destination: streamDestination, content: 'content');
    }

    Future<void> receiveMessage([Message? messageReceived]) async {
      await store.handleEvent(eg.messageEvent(messageReceived ?? message,
        localMessageId: store.outboxMessages.keys.single));
    }

    test('smoke DM: hidden -> waiting -> (delete)', () => awaitFakeAsync((async) async {
      await prepareOutboxMessage(destination: DmDestination(
        userIds: [eg.selfUser.userId, eg.otherUser.userId]));
      checkState().equals(OutboxMessageState.hidden);
      checkNotNotified();

      async.elapse(kLocalEchoDebounceDuration);
      checkState().equals(OutboxMessageState.waiting);
      checkNotifiedOnce();

      await receiveMessage(eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]));
      check(store.outboxMessages).isEmpty();
      checkNotifiedOnce();
    }));

    test('smoke stream message: hidden -> waiting -> (delete)', () => awaitFakeAsync((async) async {
      await prepareOutboxMessage(destination: StreamDestination(
        stream.streamId, eg.t('foo')));
      checkState().equals(OutboxMessageState.hidden);
      checkNotNotified();

      async.elapse(kLocalEchoDebounceDuration);
      checkState().equals(OutboxMessageState.waiting);
      checkNotifiedOnce();

      await receiveMessage(eg.streamMessage(stream: stream, topic: 'foo'));
      check(store.outboxMessages).isEmpty();
      checkNotifiedOnce();
    }));

    test('hidden -> waiting and never transition to waitPeriodExpired', () => awaitFakeAsync((async) async {
      await prepareOutboxMessage();
      checkState().equals(OutboxMessageState.hidden);
      checkNotNotified();

      async.elapse(kLocalEchoDebounceDuration);
      checkState().equals(OutboxMessageState.waiting);
      checkNotifiedOnce();

      // Wait till we reach at least [kSendMessageOfferRestoreWaitPeriod] after
      // the send request was initiated.
      async.elapse(
        kSendMessageOfferRestoreWaitPeriod - kLocalEchoDebounceDuration);
      async.flushTimers();
      // The outbox message should stay in the waiting state;
      // it should not transition to waitPeriodExpired.
      checkState().equals(OutboxMessageState.waiting);
      checkNotNotified();
    }));

    test('waiting -> waitPeriodExpired', () => awaitFakeAsync((async) async {
      await prepareOutboxMessageToFailAfterDelay(
        kSendMessageOfferRestoreWaitPeriod + Duration(seconds: 1));
      async.elapse(kLocalEchoDebounceDuration);
      checkState().equals(OutboxMessageState.waiting);
      checkNotifiedOnce();

      async.elapse(kSendMessageOfferRestoreWaitPeriod - kLocalEchoDebounceDuration);
      checkState().equals(OutboxMessageState.waitPeriodExpired);
      checkNotifiedOnce();

      await check(outboxMessageFailFuture).throws();
    }));

    test('waiting -> waitPeriodExpired -> waiting and never return to waitPeriodExpired', () => awaitFakeAsync((async) async {
      await prepare(stream: stream);
      await prepareMessages([eg.streamMessage(stream: stream)]);
      // Set up a [sendMessage] request that succeeds after enough delay,
      // for the outbox message to reach the waitPeriodExpired state.
      // TODO extract helper to add prepare an outbox message with a delayed
      //   successful [sendMessage] request if we have more tests like this
      connection.prepare(json: SendMessageResult(id: 1).toJson(),
        delay: kSendMessageOfferRestoreWaitPeriod + Duration(seconds: 1));
      final future = store.sendMessage(
        destination: streamDestination, content: 'content');
      async.elapse(kSendMessageOfferRestoreWaitPeriod);
      checkState().equals(OutboxMessageState.waitPeriodExpired);
      checkNotified(count: 2);

      // Wait till the [sendMessage] request succeeds.
      await future;
      checkState().equals(OutboxMessageState.waiting);
      checkNotifiedOnce();

      // Wait till we reach at least [kSendMessageOfferRestoreWaitPeriod] after
      // returning to the waiting state.
      async.elapse(kSendMessageOfferRestoreWaitPeriod);
      async.flushTimers();
      // The outbox message should stay in the waiting state;
      // it should not transition to waitPeriodExpired.
      checkState().equals(OutboxMessageState.waiting);
      checkNotNotified();
    }));

    group('… -> failed', () {
      test('hidden -> failed', () => awaitFakeAsync((async) async {
        await prepareOutboxMessageToFailAfterDelay(Duration.zero);
        checkState().equals(OutboxMessageState.hidden);
        checkNotNotified();

        await check(outboxMessageFailFuture).throws();
        checkState().equals(OutboxMessageState.failed);
        checkNotifiedOnce();

        // Wait till we reach at least [kSendMessageOfferRestoreWaitPeriod] after
        // the send request was initiated.
        async.elapse(kSendMessageOfferRestoreWaitPeriod);
        async.flushTimers();
        // The outbox message should stay in the failed state;
        // it should not transition to waitPeriodExpired.
        checkState().equals(OutboxMessageState.failed);
        checkNotNotified();
      }));

      test('waiting -> failed', () => awaitFakeAsync((async) async {
        await prepareOutboxMessageToFailAfterDelay(
          kLocalEchoDebounceDuration + Duration(seconds: 1));
        async.elapse(kLocalEchoDebounceDuration);
        checkState().equals(OutboxMessageState.waiting);
        checkNotifiedOnce();

        await check(outboxMessageFailFuture).throws();
        checkState().equals(OutboxMessageState.failed);
        checkNotifiedOnce();
      }));

      test('waitPeriodExpired -> failed', () => awaitFakeAsync((async) async {
        await prepareOutboxMessageToFailAfterDelay(
          kSendMessageOfferRestoreWaitPeriod + Duration(seconds: 1));
        async.elapse(kSendMessageOfferRestoreWaitPeriod);
        checkState().equals(OutboxMessageState.waitPeriodExpired);
        checkNotified(count: 2);

        await check(outboxMessageFailFuture).throws();
        checkState().equals(OutboxMessageState.failed);
        checkNotifiedOnce();
      }));
    });

    group('… -> (delete)', () {
      test('hidden -> (delete) because event received', () => awaitFakeAsync((async) async {
        await prepareOutboxMessage();
        checkState().equals(OutboxMessageState.hidden);
        checkNotNotified();

        await receiveMessage();
        check(store.outboxMessages).isEmpty();
        checkNotifiedOnce();
      }));

      test('hidden -> (delete) when event arrives before send request fails', () => awaitFakeAsync((async) async {
        // Set up an error to fail `sendMessage` with a delay, leaving time for
        // the message event to arrive.
        await prepareOutboxMessageToFailAfterDelay(const Duration(seconds: 1));
        checkState().equals(OutboxMessageState.hidden);
        checkNotNotified();

        // Received the message event while the message is being sent.
        await receiveMessage();
        check(store.outboxMessages).isEmpty();
        checkNotifiedOnce();

        // Complete the send request.  There should be no error despite
        // the send request failure, because the outbox message is not
        // in the store any more.
        await check(outboxMessageFailFuture).completes();
        async.elapse(const Duration(seconds: 1));
        checkNotNotified();
      }));

      test('waiting -> (delete) because event received', () => awaitFakeAsync((async) async {
        await prepareOutboxMessage();
        async.elapse(kLocalEchoDebounceDuration);
        checkState().equals(OutboxMessageState.waiting);
        checkNotifiedOnce();

        await receiveMessage();
        check(store.outboxMessages).isEmpty();
        checkNotifiedOnce();
      }));

      test('waiting -> (delete) when event arrives before send request fails', () => awaitFakeAsync((async) async {
        // Set up an error to fail `sendMessage` with a delay, leaving time for
        // the message event to arrive.
        await prepareOutboxMessageToFailAfterDelay(
          kLocalEchoDebounceDuration + Duration(seconds: 1));
        async.elapse(kLocalEchoDebounceDuration);
        checkState().equals(OutboxMessageState.waiting);
        checkNotifiedOnce();

        // Received the message event while the message is being sent.
        await receiveMessage();
        check(store.outboxMessages).isEmpty();
        checkNotifiedOnce();

        // Complete the send request.  There should be no error despite
        // the send request failure, because the outbox message is not
        // in the store any more.
        await check(outboxMessageFailFuture).completes();
        checkNotNotified();
      }));

      test('waitPeriodExpired -> (delete) when event arrives before send request fails', () => awaitFakeAsync((async) async {
        // Set up an error to fail `sendMessage` with a delay, leaving time for
        // the message event to arrive.
        await prepareOutboxMessageToFailAfterDelay(
          kSendMessageOfferRestoreWaitPeriod + Duration(seconds: 1));
        async.elapse(kSendMessageOfferRestoreWaitPeriod);
        checkState().equals(OutboxMessageState.waitPeriodExpired);
        checkNotified(count: 2);

        // Received the message event while the message is being sent.
        await receiveMessage();
        check(store.outboxMessages).isEmpty();
        checkNotifiedOnce();

        // Complete the send request.  There should be no error despite
        // the send request failure, because the outbox message is not
        // in the store any more.
        await check(outboxMessageFailFuture).completes();
        checkNotNotified();
      }));

      test('waitPeriodExpired -> (delete) because outbox message was taken', () => awaitFakeAsync((async) async {
        // Set up an error to fail `sendMessage` with a delay, leaving time for
        // the outbox message to be taken (by the user, presumably).
        await prepareOutboxMessageToFailAfterDelay(
          kSendMessageOfferRestoreWaitPeriod + Duration(seconds: 1));
        async.elapse(kSendMessageOfferRestoreWaitPeriod);
        checkState().equals(OutboxMessageState.waitPeriodExpired);
        checkNotified(count: 2);

        store.takeOutboxMessage(store.outboxMessages.keys.single);
        check(store.outboxMessages).isEmpty();
        checkNotifiedOnce();
      }));

      test('failed -> (delete) because event received', () => awaitFakeAsync((async) async {
        await prepareOutboxMessageToFailAfterDelay(Duration.zero);
        await check(outboxMessageFailFuture).throws();
        checkState().equals(OutboxMessageState.failed);
        checkNotifiedOnce();

        await receiveMessage();
        check(store.outboxMessages).isEmpty();
        checkNotifiedOnce();
      }));

      test('failed -> (delete) because outbox message was taken', () => awaitFakeAsync((async) async {
        await prepareOutboxMessageToFailAfterDelay(Duration.zero);
        await check(outboxMessageFailFuture).throws();
        checkState().equals(OutboxMessageState.failed);
        checkNotifiedOnce();

        store.takeOutboxMessage(store.outboxMessages.keys.single);
        check(store.outboxMessages).isEmpty();
        checkNotifiedOnce();
      }));
    });

    test('when sending to "(no topic)", process topic like the server does when creating outbox message', () => awaitFakeAsync((async) async {
      await prepareOutboxMessage(
        destination: StreamDestination(stream.streamId, TopicName('(no topic)')),
        zulipFeatureLevel: 370);
      async.elapse(kLocalEchoDebounceDuration);
      check(store.outboxMessages).values.single
        .conversation.isA<StreamConversation>().topic.equals(eg.t(''));
    }));

    test('legacy: when sending to "(no topic)", process topic like the server does when creating outbox message', () => awaitFakeAsync((async) async {
      await prepareOutboxMessage(
        destination: StreamDestination(stream.streamId, TopicName('(no topic)')),
        zulipFeatureLevel: 369);
      async.elapse(kLocalEchoDebounceDuration);
      check(store.outboxMessages).values.single
        .conversation.isA<StreamConversation>().topic.equals(eg.t('(no topic)'));
    }));

    test('set timestamp to now when creating outbox messages', () => awaitFakeAsync(
      initialTime: eg.timeInPast,
      (async) async {
        await prepareOutboxMessage();
        check(store.outboxMessages).values.single
          .timestamp.equals(eg.utcTimestamp(eg.timeInPast));
      },
    ));
  });

  test('takeOutboxMessage', () async {
    final stream = eg.stream();
    await prepare(stream: stream);
    await prepareMessages([]);

    for (int i = 0; i < 10; i++) {
      connection.prepare(apiException: eg.apiBadRequest());
      await check(store.sendMessage(
        destination: StreamDestination(stream.streamId, eg.t('topic')),
        content: 'content')).throws();
      checkNotifiedOnce();
    }

    final localMessageIds = store.outboxMessages.keys.toList();
    store.takeOutboxMessage(localMessageIds.removeAt(5));
    check(store.outboxMessages).keys.deepEquals(localMessageIds);
    checkNotifiedOnce();
  });

  group('reconcileMessages', () {
    Condition<Object?> conditionIdentical<T>(T element) =>
      (it) => it.identicalTo(element);

    test('from empty', () async {
      await prepare();
      check(store.messages).isEmpty();
      final message1 = eg.streamMessage();
      final message2 = eg.streamMessage();
      final message3 = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]);
      final messages = <Message>[message1, message2, message3];
      store.reconcileMessages(messages);
      check(messages).deepEquals(
        [message1, message2, message3].map(conditionIdentical));
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
        [message1, message2, message3].map(conditionIdentical));
      check(store.messages).deepEquals({
        for (final m in messages) m.id: m,
        newMessage.id: newMessage,
      });
    });

    group('fetched message with ID already in store.messages', () {
      /// Makes a copy of the single message in [MessageStore.messages]
      /// by round-tripping through [Message.fromJson] and [Message.toJson].
      ///
      /// If that message's [StreamMessage.conversation.displayRecipient]
      /// is null, callers must provide a non-null [displayRecipient]
      /// to allow [StreamConversation.fromJson] to complete without throwing.
      Message copyStoredMessage({String? displayRecipient}) {
        final message = store.messages.values.single;

        final json = message.toJson();
        if (
          message is StreamMessage
          && message.conversation.displayRecipient == null
        ) {
          if (displayRecipient == null) throw ArgumentError();
          json['display_recipient'] = displayRecipient;
        }

        return Message.fromJson(json);
      }

      /// Checks if the single message in [MessageStore.messages]
      /// is identical to [message].
      void checkStoredMessageIdenticalTo(Message message) {
        check(store.messages)
          .deepEquals({message.id: conditionIdentical(message)});
      }

      void checkClobber({Message? withMessageCopy}) {
        final messageCopy = withMessageCopy ?? copyStoredMessage();
        store.reconcileMessages([messageCopy]);
        checkStoredMessageIdenticalTo(messageCopy);
      }

      void checkNoClobber() {
        final messageBefore = store.messages.values.single;
        store.reconcileMessages([copyStoredMessage()]);
        checkStoredMessageIdenticalTo(messageBefore);
      }

      test('DM', () async {
        await prepare();
        final message = eg.dmMessage(id: 1, from: eg.otherUser, to: [eg.selfUser]);

        store.reconcileMessages([message]);

        // Not clobbering, because the first call didn't mark stale.
        checkNoClobber();
      });

      group('channel message; chooses correctly whether to clobber the stored version', () {
        // Exercise the ways we move the message in and out of the "maybe stale"
        // state. These include reconcileMessage itself, so sometimes we test
        // repeated calls to that with nothing else happening in between.

        test('various conditions', () async {
          final channel = eg.stream();
          await prepare(stream: channel, isChannelSubscribed: true);
          final message = eg.streamMessage(stream: channel);

          store.reconcileMessages([message]);

          // Not clobbering, because the first call didn't mark stale,
          // because the message was in a subscribed channel.
          checkNoClobber();

          await store.removeSubscription(channel.streamId);
          // Clobbering because the unsubscribe event marked the message stale.
          checkClobber();
          // (Check that reconcileMessage itself didn't unmark as stale.)
          checkClobber();

          await store.addSubscription(eg.subscription(channel));
          // The channel became subscribed,
          // but the message's data hasn't been refreshed, so clobber…
          checkClobber();

          // …Now it's been refreshed, by reconcileMessages, so don't clobber.
          checkNoClobber();

          final otherChannel = eg.stream();
          await store.addStream(otherChannel);
          check(store.subscriptions[otherChannel.streamId]).isNull();
          await store.handleEvent(
            eg.updateMessageEventMoveFrom(origMessages: [message],
              newStreamId: otherChannel.streamId));
          // Message was moved to an unsubscribed channel, so clobber.
          checkClobber(
            withMessageCopy: copyStoredMessage(displayRecipient: otherChannel.name));
          // (Check that reconcileMessage itself didn't unmark as stale.)
          checkClobber();

          // Subscribe, to mark message as not-stale, setting up another check…
          await store.addSubscription(eg.subscription(otherChannel));

          await store.handleEvent(ChannelDeleteEvent(id: 1, channelIds: [otherChannel.streamId]));
          // Message was in a channel that became unknown, so clobber.
          checkClobber();
        });

        test('in unsubscribed channel on first call', () async {
          await prepare(isChannelSubscribed: false);
          final message = eg.streamMessage();

          store.reconcileMessages([message]);

          checkClobber();
          checkClobber();
        });

        test('new-message event when in unsubscribed channel', () async {
          await prepare(isChannelSubscribed: false);
          final message = eg.streamMessage();

          await store.handleEvent(eg.messageEvent(message));

          checkClobber();
          checkClobber();
        });

        test('new-message event when in a subscribed channel', () async {
          await prepare(isChannelSubscribed: true);
          final message = eg.streamMessage();

          await store.handleEvent(eg.messageEvent(message));

          checkNoClobber();
          checkNoClobber();
        });
      });
    });

    test('matchContent and matchTopic are removed', () async {
      await prepare();
      final message1 = eg.streamMessage(id: 1, content: '<p>foo</p>');
      await addMessages([message1]);
      check(store.messages).deepEquals({1: message1});
      final otherMessage1 = eg.streamMessage(id: 1, content: '<p>foo</p>',
        matchContent: 'some highlighted content',
        matchTopic: 'some highlighted topic');
      final message2 = eg.streamMessage(id: 2, content: '<p>bar</p>',
        matchContent: 'some highlighted content',
        matchTopic: 'some highlighted topic');
      final messages = [otherMessage1, message2];
      store.reconcileMessages(messages);

      Condition<Object?> conditionIdenticalAndNullMatchFields(Message message) {
        return (it) => it.isA<Message>()
                         ..identicalTo(message)
                         ..matchContent.isNull()..matchTopic.isNull();
      }

      check(messages).deepEquals([
        conditionIdenticalAndNullMatchFields(message1),
        conditionIdenticalAndNullMatchFields(message2),
      ]);

      check(store.messages).deepEquals({
        1: conditionIdenticalAndNullMatchFields(message1),
        2: conditionIdenticalAndNullMatchFields(message2),
      });
    });
  });

  group('edit-message methods', () {
    late StreamMessage message;
    Future<void> prepareEditMessage() async {
      await prepare();
      message = eg.streamMessage();
      await prepareMessages([message]);
      check(connection.takeRequests()).length.equals(1); // message-list fetchInitial
    }

    void checkRequest(int messageId, {
      required String prevContent,
      required String content,
    }) {
      final prevContentSha256 = sha256.convert(utf8.encode(prevContent)).toString();
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('PATCH')
        ..url.path.equals('/api/v1/messages/$messageId')
        ..bodyFields.deepEquals({
          'prev_content_sha256': prevContentSha256,
          'content': content,
        });
    }

    test('smoke', () => awaitFakeAsync((async) async {
      await prepareEditMessage();
      check(store.getEditMessageErrorStatus(message.id)).isNull();

      connection.prepare(
        json: UpdateMessageResult().toJson(), delay: Duration(seconds: 1));
      unawaited(store.editMessage(messageId: message.id,
        originalRawContent: 'old content', newContent: 'new content'));
      checkRequest(message.id,
        prevContent: 'old content',
        content: 'new content');
      checkNotifiedOnce();

      async.elapse(Duration(milliseconds: 500));
      // Mid-request
      check(store.getEditMessageErrorStatus(message.id)).isNotNull().isFalse();

      async.elapse(Duration(milliseconds: 500));
      // Request has succeeded; event hasn't arrived
      check(store.getEditMessageErrorStatus(message.id)).isNotNull().isFalse();
      checkNotNotified();

      await store.handleEvent(eg.updateMessageEditEvent(message));
      check(store.getEditMessageErrorStatus(message.id)).isNull();
      checkNotifiedOnce();
    }));

    test('concurrent edits on different messages', () => awaitFakeAsync((async) async {
      await prepareEditMessage();
      final otherMessage = eg.streamMessage();
      await store.addMessage(otherMessage);
      checkNotifiedOnce();

      check(store.getEditMessageErrorStatus(message.id)).isNull();

      connection.prepare(
        json: UpdateMessageResult().toJson(), delay: Duration(seconds: 1));
      unawaited(store.editMessage(messageId: message.id,
        originalRawContent: 'old content', newContent: 'new content'));
      checkRequest(message.id,
        prevContent: 'old content',
        content: 'new content');
      checkNotifiedOnce();

      async.elapse(Duration(milliseconds: 500));
      // Mid-first request
      check(store.getEditMessageErrorStatus(message.id)).isNotNull().isFalse();
      check(store.getEditMessageErrorStatus(otherMessage.id)).isNull();
      connection.prepare(
        json: UpdateMessageResult().toJson(), delay: Duration(seconds: 1));
      unawaited(store.editMessage(messageId: otherMessage.id,
        originalRawContent: 'other message old content', newContent: 'other message new content'));
      checkRequest(otherMessage.id,
        prevContent: 'other message old content',
        content: 'other message new content');
      checkNotifiedOnce();

      async.elapse(Duration(milliseconds: 500));
      // First request has succeeded; event hasn't arrived
      // Mid-second request
      check(store.getEditMessageErrorStatus(message.id)).isNotNull().isFalse();
      check(store.getEditMessageErrorStatus(otherMessage.id)).isNotNull().isFalse();
      checkNotNotified();

      // First event arrives
      await store.handleEvent(eg.updateMessageEditEvent(message));
      check(store.getEditMessageErrorStatus(message.id)).isNull();
      checkNotifiedOnce();

      async.elapse(Duration(milliseconds: 500));
      // Second request has succeeded; event hasn't arrived
      check(store.getEditMessageErrorStatus(otherMessage.id)).isNotNull().isFalse();
      checkNotNotified();

      // Second event arrives
      await store.handleEvent(eg.updateMessageEditEvent(otherMessage));
      check(store.getEditMessageErrorStatus(otherMessage.id)).isNull();
      checkNotifiedOnce();
    }));

    test('request fails', () => awaitFakeAsync((async) async {
      await prepareEditMessage();
      check(store.getEditMessageErrorStatus(message.id)).isNull();

      connection.prepare(apiException: eg.apiBadRequest(), delay: Duration(seconds: 1));
      unawaited(check(store.editMessage(messageId: message.id,
        originalRawContent: 'old content', newContent: 'new content')).throws<ZulipApiException>());
      checkNotifiedOnce();
      async.elapse(Duration(seconds: 1));
      check(store.getEditMessageErrorStatus(message.id)).isNotNull().isTrue();
      checkNotifiedOnce();
    }));

    test('request fails; take failed edit', () => awaitFakeAsync((async) async {
      await prepareEditMessage();
      check(store.getEditMessageErrorStatus(message.id)).isNull();

      connection.prepare(apiException: eg.apiBadRequest(), delay: Duration(seconds: 1));
      unawaited(check(store.editMessage(messageId: message.id,
        originalRawContent: 'old content', newContent: 'new content')).throws<ZulipApiException>());
      checkNotifiedOnce();
      async.elapse(Duration(seconds: 1));
      check(store.getEditMessageErrorStatus(message.id)).isNotNull().isTrue();
      checkNotifiedOnce();

      check(store.takeFailedMessageEdit(message.id).newContent).equals('new content');
      check(store.getEditMessageErrorStatus(message.id)).isNull();
      checkNotifiedOnce();
    }));

    test('takeFailedMessageEdit throws StateError when nothing to take', () => awaitFakeAsync((async) async {
      await prepareEditMessage();
      check(store.getEditMessageErrorStatus(message.id)).isNull();
      check(() => store.takeFailedMessageEdit(message.id)).throws<StateError>();
    }));

    test('editMessage throws StateError if editMessage already in progress for same message', () => awaitFakeAsync((async) async {
      await prepareEditMessage();

      connection.prepare(
        json: UpdateMessageResult().toJson(), delay: Duration(seconds: 1));
      unawaited(store.editMessage(messageId: message.id,
        originalRawContent: 'old content', newContent: 'new content'));
      async.elapse(Duration(milliseconds: 500));
      check(connection.takeRequests()).length.equals(1);
      checkNotifiedOnce();

      await check(store.editMessage(messageId: message.id,
          originalRawContent: 'old content', newContent: 'newer content'))
        .isA<Future<void>>().throws<StateError>();
      check(connection.takeRequests()).isEmpty();
    }));

    test('event arrives, then request fails', () => awaitFakeAsync((async) async {
      // This can happen with network issues.

      await prepareEditMessage();
      check(store.getEditMessageErrorStatus(message.id)).isNull();

      connection.prepare(
        httpException: const SocketException('failed'), delay: Duration(seconds: 1));
      unawaited(store.editMessage(messageId: message.id,
        originalRawContent: 'old content', newContent: 'new content'));
      checkNotifiedOnce();

      async.elapse(Duration(milliseconds: 500));
      await store.handleEvent(eg.updateMessageEditEvent(message));
      check(store.getEditMessageErrorStatus(message.id)).isNull();
      checkNotifiedOnce();

      async.flushTimers();
      check(store.getEditMessageErrorStatus(message.id)).isNull();
      checkNotNotified();
    }));

    test('request fails, then event arrives', () => awaitFakeAsync((async) async {
      // This can happen with network issues.

      await prepareEditMessage();
      check(store.getEditMessageErrorStatus(message.id)).isNull();

      connection.prepare(
        httpException: const SocketException('failed'), delay: Duration(seconds: 1));
      unawaited(check(store.editMessage(messageId: message.id,
        originalRawContent: 'old content', newContent: 'new content')).throws<NetworkException>());
      checkNotifiedOnce();

      async.elapse(Duration(seconds: 1));
      check(store.getEditMessageErrorStatus(message.id)).isNotNull().isTrue();
      checkNotifiedOnce();

      await store.handleEvent(eg.updateMessageEditEvent(message));
      check(store.getEditMessageErrorStatus(message.id)).isNull();
      checkNotifiedOnce();
    }));

    test('request fails, then event arrives; take failed edit in between', () => awaitFakeAsync((async) async {
      // This can happen with network issues.

      await prepareEditMessage();
      check(store.getEditMessageErrorStatus(message.id)).isNull();

      connection.prepare(
        httpException: const SocketException('failed'), delay: Duration(seconds: 1));
      unawaited(check(store.editMessage(messageId: message.id,
        originalRawContent: 'old content', newContent: 'new content')).throws<NetworkException>());
      checkNotifiedOnce();

      async.elapse(Duration(seconds: 1));
      check(store.getEditMessageErrorStatus(message.id)).isNotNull().isTrue();
      checkNotifiedOnce();
      check(store.takeFailedMessageEdit(message.id).newContent).equals('new content');
      checkNotifiedOnce();

      await store.handleEvent(eg.updateMessageEditEvent(message)); // no error
      check(store.getEditMessageErrorStatus(message.id)).isNull();
      checkNotifiedOnce(); // content updated
    }));

    test('request fails, then message deleted', () => awaitFakeAsync((async) async {
      await prepareEditMessage();
      check(store.getEditMessageErrorStatus(message.id)).isNull();

      connection.prepare(apiException: eg.apiBadRequest(), delay: Duration(seconds: 1));
      unawaited(check(store.editMessage(messageId: message.id,
        originalRawContent: 'old content', newContent: 'new content')).throws<ZulipApiException>());
      checkNotifiedOnce();
      async.elapse(Duration(seconds: 1));
      check(store.getEditMessageErrorStatus(message.id)).isNotNull().isTrue();
      checkNotifiedOnce();

      await store.handleEvent(eg.deleteMessageEvent([message])); // no error
      check(store.getEditMessageErrorStatus(message.id)).isNull();
      checkNotifiedOnce();
    }));

    test('message deleted while request in progress; we get failure response', () => awaitFakeAsync((async) async {
      await prepareEditMessage();
      check(store.getEditMessageErrorStatus(message.id)).isNull();

      connection.prepare(apiException: eg.apiBadRequest(), delay: Duration(seconds: 1));
      unawaited(store.editMessage(messageId: message.id,
        originalRawContent: 'old content', newContent: 'new content'));
      checkNotifiedOnce();

      async.elapse(Duration(milliseconds: 500));
      // Mid-request
      check(store.getEditMessageErrorStatus(message.id)).isNotNull().isFalse();
      checkNotNotified();

      await store.handleEvent(eg.deleteMessageEvent([message]));
      check(store.getEditMessageErrorStatus(message.id)).isNull();
      checkNotifiedOnce();

      async.elapse(Duration(milliseconds: 500));
      // Request failure, but status has already been cleared
      check(store.getEditMessageErrorStatus(message.id)).isNull();
      checkNotNotified();
    }));

    test('message deleted while request in progress but we get success response', () => awaitFakeAsync((async) async {
      await prepareEditMessage();
      check(store.getEditMessageErrorStatus(message.id)).isNull();

      connection.prepare(
        json: UpdateMessageResult().toJson(), delay: Duration(seconds: 1));
      unawaited(store.editMessage(messageId: message.id,
        originalRawContent: 'old content', newContent: 'new content'));
      checkNotifiedOnce();

      async.elapse(Duration(milliseconds: 500));
      // Mid-request
      check(store.getEditMessageErrorStatus(message.id)).isNotNull().isFalse();
      checkNotNotified();

      await store.handleEvent(eg.deleteMessageEvent([message]));
      check(store.getEditMessageErrorStatus(message.id)).isNull();
      checkNotifiedOnce();

      async.elapse(Duration(milliseconds: 500));
      // Request success
      check(store.getEditMessageErrorStatus(message.id)).isNull();
      checkNotNotified();
    }));
  });

  group('selfCanDeleteMessage', () {
    /// Call the method, with setup from [params].
    Future<bool> evaluate(CanDeleteMessageParams params) async {
      final selfUser = eg.user(role: params.selfUserRole);
      final botUserOwnedBySelf = eg.user(isBot: true, botOwnerId: selfUser.userId);
      final botUserNotOwnedBySelf = eg.user(isBot: true, botOwnerId: eg.otherUser.userId);

      final groupWithSelf = eg.userGroup(members: [selfUser.userId]);
      final groupWithoutSelf = eg.userGroup(members: [eg.otherUser.userId]);
      final groupSettingWithSelf = GroupSettingValueNamed(groupWithSelf.id);
      final groupSettingWithoutSelf = GroupSettingValueNamed(groupWithoutSelf.id);

      final GroupSettingValue? realmCanDeleteAnyMessageGroup;
      final GroupSettingValue? realmCanDeleteOwnMessageGroup;
      final RealmDeleteOwnMessagePolicy? realmDeleteOwnMessagePolicy;

      if (params.inRealmCanDeleteAnyMessageGroup != null) {
        realmCanDeleteAnyMessageGroup = params.inRealmCanDeleteAnyMessageGroup!
          ? groupSettingWithSelf : groupSettingWithoutSelf;
      } else {
        realmCanDeleteAnyMessageGroup = null;
      }

      if (params.inRealmCanDeleteOwnMessageGroup != null) {
        assert(params.inRealmCanDeleteAnyMessageGroup != null); // TODO(server-10)
        assert(params.realmDeleteOwnMessagePolicy == null);
        realmCanDeleteOwnMessageGroup = params.inRealmCanDeleteOwnMessageGroup!
          ? groupSettingWithSelf : groupSettingWithoutSelf;
      } else {
        realmCanDeleteOwnMessageGroup = null;
      }

      if (params.realmDeleteOwnMessagePolicy != null) {
        assert(params.inRealmCanDeleteOwnMessageGroup == null);
        realmDeleteOwnMessagePolicy = params.realmDeleteOwnMessagePolicy!;
      } else {
        realmDeleteOwnMessagePolicy = null;
      }

      final sender = switch (params.senderConfig) {
        CanDeleteMessageSenderConfig.unknown => eg.user(),
        CanDeleteMessageSenderConfig.self => selfUser,
        CanDeleteMessageSenderConfig.otherHuman => eg.otherUser,
        CanDeleteMessageSenderConfig.botOwnedBySelf => botUserOwnedBySelf,
        CanDeleteMessageSenderConfig.botNotOwnedBySelf => botUserNotOwnedBySelf,
      };

      final channel = eg.stream();

      final now = testBinding.utcNow();
      final timestamp = (now.millisecondsSinceEpoch ~/ 1000) - 60;
      final Message message;
      if (params.isChannelArchived != null) {
        // testing with a channel message
        message = eg.streamMessage(sender: sender, stream: channel, timestamp: timestamp);
        channel.isArchived = params.isChannelArchived!;
        if (
          params.inChannelCanDeleteAnyMessageGroup != null
          && params.inChannelCanDeleteOwnMessageGroup != null
        ) {
          channel.canDeleteAnyMessageGroup = params.inChannelCanDeleteAnyMessageGroup!
            ? groupSettingWithSelf : groupSettingWithoutSelf;
          channel.canDeleteOwnMessageGroup = params.inChannelCanDeleteOwnMessageGroup!
            ? groupSettingWithSelf : groupSettingWithoutSelf;
        } else {
          assert(params.inChannelCanDeleteAnyMessageGroup == null);
          assert(params.inChannelCanDeleteOwnMessageGroup == null);
          channel.canDeleteAnyMessageGroup = null;
          channel.canDeleteOwnMessageGroup = null;
        }
      } else {
        // testing with a DM message
        final to = sender == selfUser ? <User>[] : [selfUser];
        message = eg.dmMessage(from: sender, to: to, timestamp: timestamp);
      }

      final realmMessageContentDeleteLimitSeconds = switch (params.timeLimitConfig) {
        CanDeleteMessageTimeLimitConfig.notLimited => null,
        CanDeleteMessageTimeLimitConfig.insideLimit => 24 * 60 * 60,
        CanDeleteMessageTimeLimitConfig.outsideLimit => 1,
      };

      final store = eg.store(
        selfUser: selfUser,
        initialSnapshot: eg.initialSnapshot(
          realmUsers: [selfUser, eg.otherUser, botUserOwnedBySelf, botUserNotOwnedBySelf],
          streams: [channel],
          realmUserGroups: [groupWithSelf, groupWithoutSelf],
          realmCanDeleteAnyMessageGroup: realmCanDeleteAnyMessageGroup,
          realmCanDeleteOwnMessageGroup: realmCanDeleteOwnMessageGroup,
          realmMessageContentDeleteLimitSeconds: realmMessageContentDeleteLimitSeconds,
          realmDeleteOwnMessagePolicy: realmDeleteOwnMessagePolicy));

      await store.addMessage(message);

      return store.selfCanDeleteMessage(message.id, atDate: now);
    }

    void doTest(bool expected, CanDeleteMessageParams params) {
      test('params: ${params.describe()}', () async {
        check(await evaluate(params)).equals(expected);
      });
    }

    group('channel message', () {
      doTest(true, CanDeleteMessageParams.permissiveForChannelMessageExcept());
      doTest(false, CanDeleteMessageParams.restrictiveForChannelMessageExcept());

      group('denial conditions', () {
        doTest(false, CanDeleteMessageParams.permissiveForChannelMessageExcept(
          isChannelArchived: true));

        doTest(false, CanDeleteMessageParams.permissiveForChannelMessageExcept(
          inRealmCanDeleteAnyMessageGroup: false,
          inChannelCanDeleteAnyMessageGroup: false,
          senderConfig: CanDeleteMessageSenderConfig.unknown));

        doTest(false, CanDeleteMessageParams.permissiveForChannelMessageExcept(
          inRealmCanDeleteAnyMessageGroup: false,
          inChannelCanDeleteAnyMessageGroup: false,
          senderConfig: CanDeleteMessageSenderConfig.otherHuman));

        doTest(false, CanDeleteMessageParams.permissiveForChannelMessageExcept(
          inRealmCanDeleteAnyMessageGroup: false,
          inChannelCanDeleteAnyMessageGroup: false,
          senderConfig: CanDeleteMessageSenderConfig.botNotOwnedBySelf));

        doTest(false, CanDeleteMessageParams.permissiveForChannelMessageExcept(
          inRealmCanDeleteAnyMessageGroup: false,
          inChannelCanDeleteAnyMessageGroup: false,
          inRealmCanDeleteOwnMessageGroup: false,
          inChannelCanDeleteOwnMessageGroup: false));

        doTest(false, CanDeleteMessageParams.permissiveForChannelMessageExcept(
          inRealmCanDeleteAnyMessageGroup: false,
          inChannelCanDeleteAnyMessageGroup: false,
          inRealmCanDeleteOwnMessageGroup: false,
          timeLimitConfig: CanDeleteMessageTimeLimitConfig.outsideLimit));

        doTest(false, CanDeleteMessageParams.permissiveForChannelMessageExcept(
          inRealmCanDeleteAnyMessageGroup: false,
          inChannelCanDeleteAnyMessageGroup: false,
          timeLimitConfig: CanDeleteMessageTimeLimitConfig.outsideLimit));
      });

      group('approval conditions', () {
        doTest(true, CanDeleteMessageParams.restrictiveForChannelMessageExcept(
          isChannelArchived: false,
          inRealmCanDeleteAnyMessageGroup: true));

        doTest(true, CanDeleteMessageParams.restrictiveForChannelMessageExcept(
          isChannelArchived: false,
          inChannelCanDeleteAnyMessageGroup: true));

        doTest(true, CanDeleteMessageParams.restrictiveForChannelMessageExcept(
          isChannelArchived: false,
          senderConfig: CanDeleteMessageSenderConfig.self,
          inRealmCanDeleteOwnMessageGroup: true,
          timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited));

        doTest(true, CanDeleteMessageParams.restrictiveForChannelMessageExcept(
          isChannelArchived: false,
          senderConfig: CanDeleteMessageSenderConfig.botOwnedBySelf,
          inChannelCanDeleteOwnMessageGroup: true,
          timeLimitConfig: CanDeleteMessageTimeLimitConfig.insideLimit));
      });
    });

    group('dm message', () {
      doTest(true, CanDeleteMessageParams.permissiveForDmMessageExcept());
      doTest(false, CanDeleteMessageParams.restrictiveForDmMessageExcept());

      group('denial conditions', () {
        doTest(false, CanDeleteMessageParams.permissiveForDmMessageExcept(
          inRealmCanDeleteAnyMessageGroup: false,
          senderConfig: CanDeleteMessageSenderConfig.unknown));

        doTest(false, CanDeleteMessageParams.permissiveForDmMessageExcept(
          inRealmCanDeleteAnyMessageGroup: false,
          senderConfig: CanDeleteMessageSenderConfig.otherHuman));

        doTest(false, CanDeleteMessageParams.permissiveForDmMessageExcept(
          inRealmCanDeleteAnyMessageGroup: false,
          senderConfig: CanDeleteMessageSenderConfig.botNotOwnedBySelf));

        doTest(false, CanDeleteMessageParams.permissiveForDmMessageExcept(
          inRealmCanDeleteAnyMessageGroup: false,
          inRealmCanDeleteOwnMessageGroup: false));

        doTest(false, CanDeleteMessageParams.permissiveForDmMessageExcept(
          inRealmCanDeleteAnyMessageGroup: false,
          timeLimitConfig: CanDeleteMessageTimeLimitConfig.outsideLimit));
      });

      group('approval conditions', () {
        doTest(true, CanDeleteMessageParams.restrictiveForDmMessageExcept(
          inRealmCanDeleteAnyMessageGroup: true));

        doTest(true, CanDeleteMessageParams.restrictiveForDmMessageExcept(
          senderConfig: CanDeleteMessageSenderConfig.self,
          inRealmCanDeleteOwnMessageGroup: true,
          timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited));

        doTest(true, CanDeleteMessageParams.restrictiveForDmMessageExcept(
          senderConfig: CanDeleteMessageSenderConfig.self,
          inRealmCanDeleteOwnMessageGroup: true,
          timeLimitConfig: CanDeleteMessageTimeLimitConfig.insideLimit));
      });
    });

    group('legacy behavior', () {
      group('pre-407', () {
        // The channel-level group permissions don't exist,
        // so we act as though they were present with role:nobody,
        // and we don't throw.

        test('denial is not forced just because one of the permissions is absent (the any-message one)', () async {
          check(await evaluate(
            CanDeleteMessageParams.pre407(
              senderConfig: CanDeleteMessageSenderConfig.self,
              timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited,
              inRealmCanDeleteAnyMessageGroup: false,
              inRealmCanDeleteOwnMessageGroup: true,
              isChannelArchived: false,
          )))..equals(await evaluate(
              CanDeleteMessageParams.modern(
                senderConfig: CanDeleteMessageSenderConfig.self,
                timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited,
                inRealmCanDeleteAnyMessageGroup: false,
                inRealmCanDeleteOwnMessageGroup: true,
                isChannelArchived: false,
                inChannelCanDeleteAnyMessageGroup: false,
                inChannelCanDeleteOwnMessageGroup: false)))
            ..isTrue();
        });

        test('exercise both existence checks', () async {
          check(await evaluate(
            CanDeleteMessageParams.pre407(
              senderConfig: CanDeleteMessageSenderConfig.self,
              timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited,
              inRealmCanDeleteAnyMessageGroup: false,
              inRealmCanDeleteOwnMessageGroup: false,
              isChannelArchived: false,
          )))..equals(await evaluate(
              CanDeleteMessageParams.modern(
                senderConfig: CanDeleteMessageSenderConfig.self,
                timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited,
                inRealmCanDeleteAnyMessageGroup: false,
                inRealmCanDeleteOwnMessageGroup: false,
                isChannelArchived: false,
                inChannelCanDeleteAnyMessageGroup: false,
                inChannelCanDeleteOwnMessageGroup: false)))
            ..isFalse();
        });
      });

      group('pre-291', () {
        // The realm-level can-delete-own-message group permission
        // doesn't exist, so we follow realmDeleteOwnMessagePolicy instead,
        // and we don't error.

        test('allowed (permissive policy, low role)', () async {
          check(await evaluate(
            CanDeleteMessageParams.pre291(
              senderConfig: CanDeleteMessageSenderConfig.self,
              timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited,
              inRealmCanDeleteAnyMessageGroup: false,
              isChannelArchived: false,
              realmDeleteOwnMessagePolicy: RealmDeleteOwnMessagePolicy.everyone,
              selfUserRole: UserRole.member,
          )))
            ..equals(await evaluate(
             CanDeleteMessageParams.pre407(
               senderConfig: CanDeleteMessageSenderConfig.self,
               timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited,
               inRealmCanDeleteAnyMessageGroup: false,
               inRealmCanDeleteOwnMessageGroup: true,
               isChannelArchived: false)))
            ..isTrue();
        });

        test('allowed (strict policy, high role)', () async {
          check(await evaluate(
            CanDeleteMessageParams.pre291(
              senderConfig: CanDeleteMessageSenderConfig.self,
              timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited,
              inRealmCanDeleteAnyMessageGroup: false,
              isChannelArchived: false,
              realmDeleteOwnMessagePolicy: RealmDeleteOwnMessagePolicy.admins,
              selfUserRole: UserRole.administrator,
          )))
            ..equals(await evaluate(
             CanDeleteMessageParams.pre407(
               senderConfig: CanDeleteMessageSenderConfig.self,
               timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited,
               inRealmCanDeleteAnyMessageGroup: false,
               inRealmCanDeleteOwnMessageGroup: true,
               isChannelArchived: false)))
            ..isTrue();
        });

        test('denied', () async {
          check(await evaluate(
            CanDeleteMessageParams.pre291(
              senderConfig: CanDeleteMessageSenderConfig.self,
              timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited,
              inRealmCanDeleteAnyMessageGroup: false,
              isChannelArchived: false,
              realmDeleteOwnMessagePolicy: RealmDeleteOwnMessagePolicy.admins,
              selfUserRole: UserRole.moderator,
          )))..equals(await evaluate(
              CanDeleteMessageParams.pre407(
                senderConfig: CanDeleteMessageSenderConfig.self,
                timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited,
                inRealmCanDeleteAnyMessageGroup: false,
                inRealmCanDeleteOwnMessageGroup: false,
                isChannelArchived: false)))
            ..isFalse();
        });
      });

      group('pre-281', () {
        // The realm-level can-delete-any-message permission doesn't exist,
        // so we act as though that's present with role:administrators,
        // and we don't throw.

        test('self-user is not admin', () async {
          check(await evaluate(
            CanDeleteMessageParams.pre281(
              senderConfig: CanDeleteMessageSenderConfig.otherHuman,
              timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited,
              isChannelArchived: false,
              realmDeleteOwnMessagePolicy: RealmDeleteOwnMessagePolicy.everyone,
              selfUserRole: UserRole.member,
          )))..equals(await evaluate(
              CanDeleteMessageParams.pre291(
                senderConfig: CanDeleteMessageSenderConfig.otherHuman,
                timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited,
                inRealmCanDeleteAnyMessageGroup: false,
                isChannelArchived: false,
                realmDeleteOwnMessagePolicy: RealmDeleteOwnMessagePolicy.everyone,
                selfUserRole: UserRole.member)))
            ..isFalse();
        });

        test('self-user is admin', () async {
          check(await evaluate(
            CanDeleteMessageParams.pre281(
              senderConfig: CanDeleteMessageSenderConfig.otherHuman,
              timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited,
              isChannelArchived: false,
              realmDeleteOwnMessagePolicy: RealmDeleteOwnMessagePolicy.everyone,
              selfUserRole: UserRole.administrator,
          )))..equals(await evaluate(
              CanDeleteMessageParams.pre291(
                senderConfig: CanDeleteMessageSenderConfig.otherHuman,
                timeLimitConfig: CanDeleteMessageTimeLimitConfig.notLimited,
                inRealmCanDeleteAnyMessageGroup: true,
                isChannelArchived: false,
                realmDeleteOwnMessagePolicy: RealmDeleteOwnMessagePolicy.everyone,
                selfUserRole: UserRole.administrator)))
            ..isTrue();
        });
      });
    });
  });

  group('handleMessageEvent', () {
    test('from empty', () async {
      await prepare();
      check(store.messages).isEmpty();

      final newMessage = eg.streamMessage();
      await store.addMessage(newMessage);
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
      await store.addMessage(newMessage);
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
      await store.addMessage(newMessage);
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

    test('rendering-only update does not change timestamp', () async {
      final originalMessage = eg.streamMessage(
        lastEditTimestamp: 78492,
        content: "<p>Hello, world</p>");
      final updateEvent = eg.updateMessageEditEvent(originalMessage,
        renderedContent: "<p>Hello, world</p> <div>Some link preview</div>",
        editTimestamp: 99999,
        renderingOnly: true,
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
        await store.addMessage(message);
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
        await store.addMessage(message);
        check(store.messages[message.id]).isNotNull().poll.isNull();
      });
    });
  });
}

/// Params for testing the logic for
/// whether the self-user has permission to delete a message.
class CanDeleteMessageParams {
  final CanDeleteMessageSenderConfig senderConfig;
  final CanDeleteMessageTimeLimitConfig timeLimitConfig;
  final bool? inRealmCanDeleteAnyMessageGroup;
  final bool? inRealmCanDeleteOwnMessageGroup;
  final bool? isChannelArchived;
  final bool? inChannelCanDeleteAnyMessageGroup;
  final bool? inChannelCanDeleteOwnMessageGroup;
  final RealmDeleteOwnMessagePolicy? realmDeleteOwnMessagePolicy;
  final UserRole? selfUserRole;

  CanDeleteMessageParams._({
    required this.senderConfig,
    required this.timeLimitConfig,
    required this.inRealmCanDeleteAnyMessageGroup,
    required this.inRealmCanDeleteOwnMessageGroup,
    required this.isChannelArchived,
    required this.inChannelCanDeleteAnyMessageGroup,
    required this.inChannelCanDeleteOwnMessageGroup,
    required this.realmDeleteOwnMessagePolicy,
    required this.selfUserRole,
  });

  CanDeleteMessageParams.modern({
    required this.senderConfig,
    required this.timeLimitConfig,
    required this.inRealmCanDeleteAnyMessageGroup,
    required this.inRealmCanDeleteOwnMessageGroup,
    required this.isChannelArchived,
    required this.inChannelCanDeleteAnyMessageGroup,
    required this.inChannelCanDeleteOwnMessageGroup,
  }) :
    realmDeleteOwnMessagePolicy = null,
    selfUserRole = null;

  factory CanDeleteMessageParams.restrictiveForChannelMessageExcept({
    CanDeleteMessageSenderConfig? senderConfig,
    CanDeleteMessageTimeLimitConfig? timeLimitConfig,
    bool? inRealmCanDeleteAnyMessageGroup,
    bool? inRealmCanDeleteOwnMessageGroup,
    bool? isChannelArchived,
    bool? inChannelCanDeleteAnyMessageGroup,
    bool? inChannelCanDeleteOwnMessageGroup,
  }) => CanDeleteMessageParams.modern(
    senderConfig: senderConfig ?? CanDeleteMessageSenderConfig.unknown,
    timeLimitConfig: timeLimitConfig ?? CanDeleteMessageTimeLimitConfig.outsideLimit,
    inRealmCanDeleteAnyMessageGroup: inRealmCanDeleteAnyMessageGroup ?? false,
    inRealmCanDeleteOwnMessageGroup: inRealmCanDeleteOwnMessageGroup ?? false,
    isChannelArchived: isChannelArchived ?? true,
    inChannelCanDeleteAnyMessageGroup: inChannelCanDeleteAnyMessageGroup ?? false,
    inChannelCanDeleteOwnMessageGroup: inChannelCanDeleteOwnMessageGroup ?? false,
  );

  factory CanDeleteMessageParams.permissiveForChannelMessageExcept({
    CanDeleteMessageSenderConfig? senderConfig,
    CanDeleteMessageTimeLimitConfig? timeLimitConfig,
    bool? inRealmCanDeleteAnyMessageGroup,
    bool? inRealmCanDeleteOwnMessageGroup,
    bool? isChannelArchived,
    bool? inChannelCanDeleteAnyMessageGroup,
    bool? inChannelCanDeleteOwnMessageGroup,
  }) => CanDeleteMessageParams.modern(
    senderConfig: senderConfig ?? CanDeleteMessageSenderConfig.self,
    timeLimitConfig: timeLimitConfig ?? CanDeleteMessageTimeLimitConfig.notLimited,
    inRealmCanDeleteAnyMessageGroup: inRealmCanDeleteAnyMessageGroup ?? true,
    inRealmCanDeleteOwnMessageGroup: inRealmCanDeleteOwnMessageGroup ?? true,
    isChannelArchived: isChannelArchived ?? false,
    inChannelCanDeleteAnyMessageGroup: inChannelCanDeleteAnyMessageGroup ?? true,
    inChannelCanDeleteOwnMessageGroup: inChannelCanDeleteOwnMessageGroup ?? true,
  );

  factory CanDeleteMessageParams.restrictiveForDmMessageExcept({
    CanDeleteMessageSenderConfig? senderConfig,
    CanDeleteMessageTimeLimitConfig? timeLimitConfig,
    bool? inRealmCanDeleteAnyMessageGroup,
    bool? inRealmCanDeleteOwnMessageGroup,
  }) => CanDeleteMessageParams.modern(
    senderConfig: senderConfig ?? CanDeleteMessageSenderConfig.unknown,
    timeLimitConfig: timeLimitConfig ?? CanDeleteMessageTimeLimitConfig.outsideLimit,
    inRealmCanDeleteAnyMessageGroup: inRealmCanDeleteAnyMessageGroup ?? false,
    inRealmCanDeleteOwnMessageGroup: inRealmCanDeleteOwnMessageGroup ?? false,
    isChannelArchived: null,
    inChannelCanDeleteAnyMessageGroup: null,
    inChannelCanDeleteOwnMessageGroup: null,
  );

  factory CanDeleteMessageParams.permissiveForDmMessageExcept({
    CanDeleteMessageSenderConfig? senderConfig,
    CanDeleteMessageTimeLimitConfig? timeLimitConfig,
    bool? inRealmCanDeleteAnyMessageGroup,
    bool? inRealmCanDeleteOwnMessageGroup,
  }) => CanDeleteMessageParams.modern(
    senderConfig: senderConfig ?? CanDeleteMessageSenderConfig.self,
    timeLimitConfig: timeLimitConfig ?? CanDeleteMessageTimeLimitConfig.notLimited,
    inRealmCanDeleteAnyMessageGroup: inRealmCanDeleteAnyMessageGroup ?? true,
    inRealmCanDeleteOwnMessageGroup: inRealmCanDeleteOwnMessageGroup ?? true,
    isChannelArchived: null,
    inChannelCanDeleteAnyMessageGroup: null,
    inChannelCanDeleteOwnMessageGroup: null,
  );

  // TODO(server-11) delete
  factory CanDeleteMessageParams.pre407({
    required CanDeleteMessageSenderConfig senderConfig,
    required CanDeleteMessageTimeLimitConfig timeLimitConfig,
    required bool inRealmCanDeleteAnyMessageGroup,
    required bool inRealmCanDeleteOwnMessageGroup,
    required bool? isChannelArchived,
  }) => CanDeleteMessageParams._(
    senderConfig: senderConfig,
    timeLimitConfig: timeLimitConfig,
    inRealmCanDeleteAnyMessageGroup: inRealmCanDeleteAnyMessageGroup,
    inRealmCanDeleteOwnMessageGroup: inRealmCanDeleteOwnMessageGroup,
    isChannelArchived: isChannelArchived,
    inChannelCanDeleteAnyMessageGroup: null,
    inChannelCanDeleteOwnMessageGroup: null,
    realmDeleteOwnMessagePolicy: null,
    selfUserRole: null,
  );

  // TODO(server-10) delete
  factory CanDeleteMessageParams.pre291({
    required CanDeleteMessageSenderConfig senderConfig,
    required CanDeleteMessageTimeLimitConfig timeLimitConfig,
    required bool inRealmCanDeleteAnyMessageGroup,
    required bool? isChannelArchived,
    required RealmDeleteOwnMessagePolicy realmDeleteOwnMessagePolicy,
    required UserRole selfUserRole,
  }) => CanDeleteMessageParams._(
    senderConfig: senderConfig,
    timeLimitConfig: timeLimitConfig,
    inRealmCanDeleteAnyMessageGroup: inRealmCanDeleteAnyMessageGroup,
    inRealmCanDeleteOwnMessageGroup: null,
    isChannelArchived: isChannelArchived,
    inChannelCanDeleteAnyMessageGroup: null,
    inChannelCanDeleteOwnMessageGroup: null,
    realmDeleteOwnMessagePolicy: realmDeleteOwnMessagePolicy,
    selfUserRole: selfUserRole,
  );

  // TODO(server-10) delete
  factory CanDeleteMessageParams.pre281({
    required CanDeleteMessageSenderConfig senderConfig,
    required CanDeleteMessageTimeLimitConfig timeLimitConfig,
    required bool? isChannelArchived,
    required RealmDeleteOwnMessagePolicy realmDeleteOwnMessagePolicy,
    required UserRole selfUserRole,
  }) => CanDeleteMessageParams._(
    senderConfig: senderConfig,
    timeLimitConfig: timeLimitConfig,
    inRealmCanDeleteAnyMessageGroup: null,
    inRealmCanDeleteOwnMessageGroup: null,
    isChannelArchived: isChannelArchived,
    inChannelCanDeleteAnyMessageGroup: null,
    inChannelCanDeleteOwnMessageGroup: null,
    realmDeleteOwnMessagePolicy: realmDeleteOwnMessagePolicy,
    selfUserRole: selfUserRole,
  );

  String describe() {
    return [
      'sender: ${senderConfig.name}',
      'time limit: ${timeLimitConfig.name}',
      'in realmCanDeleteAnyMessageGroup?: ${inRealmCanDeleteAnyMessageGroup ?? 'N/A'}',
      'in realmCanDeleteOwnMessageGroup?: ${inRealmCanDeleteOwnMessageGroup ?? 'N/A'}',
      'channel is archived?: ${isChannelArchived ?? 'N/A'}',
      'in channel.canDeleteAnyMessageGroup?: ${inChannelCanDeleteAnyMessageGroup ?? 'N/A'}',
      'in channel.canDeleteOwnMessageGroup?: ${inChannelCanDeleteOwnMessageGroup ?? 'N/A'}',
      'realmDeleteOwnMessagePolicy: ${realmDeleteOwnMessagePolicy ?? 'N/A'}',
    ].join(', ');
  }
}

enum CanDeleteMessageSenderConfig {
  unknown,
  self,
  otherHuman,
  botOwnedBySelf,
  botNotOwnedBySelf,
}

enum CanDeleteMessageTimeLimitConfig {
  notLimited,
  insideLimit,
  outsideLimit,
}
