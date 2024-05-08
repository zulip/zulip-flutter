import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/message_list.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import 'message_list_test.dart';
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
  Future<void> prepare({Narrow narrow = const CombinedFeedNarrow()}) async {
    final stream = eg.stream();
    subscription = eg.subscription(stream);
    store = eg.store();
    await store.addStream(stream);
    await store.addSubscription(subscription);
    connection = store.connection as FakeApiConnection;
    notifiedCount = 0;
    messageList = MessageListView.init(store: store, narrow: narrow)
      ..addListener(() {
        notifiedCount++;
      });
    check(messageList).fetched.isFalse();
    checkNotNotified();
  }

  /// Perform the initial message fetch for [messageList].
  ///
  /// The test case must have already called [prepare] to initialize the state.
  // ignore: unused_element
  Future<void> prepareMessages(
    List<Message> messages, {
    bool foundOldest = false,
  }) async {
    connection.prepare(json:
      newestResult(foundOldest: foundOldest, messages: messages).toJson());
    await messageList.fetchInitial();
    checkNotifiedOnce();
  }

  Future<void> addMessages(Iterable<Message> messages) async {
    for (final m in messages) {
      await store.handleEvent(MessageEvent(id: 0, message: m));
    }
    checkNotified(count: messageList.fetched ? messages.length : 0);
  }

  group('reconcileMessages', () {
    test('from empty', () async {
      await prepare();
      check(store.messages).isEmpty();
      final message1 = eg.streamMessage();
      final message2 = eg.streamMessage();
      final message3 = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]);
      final messages = [message1, message2, message3];
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
      final messages = [message1, message2, message3];
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
      await store.handleEvent(MessageEvent(id: 1, message: newMessage));
      check(store.messages).deepEquals({
        newMessage.id: newMessage,
      });
    });

    test('from not-empty', () async {
      await prepare();
      final messages = [
        eg.streamMessage(),
        eg.streamMessage(),
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]),
      ];
      await addMessages(messages);
      check(store.messages).deepEquals({
        for (final m in messages) m.id: m,
      });

      final newMessage = eg.streamMessage();
      await store.handleEvent(MessageEvent(id: 1, message: newMessage));
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
      await store.handleEvent(MessageEvent(id: 1, message: newMessage));
      check(store.messages).deepEquals({1: newMessage});
    });
  });
}
