import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';

import '../example_data.dart' as eg;

void main() {
  // These variables are the common state operated on by each test.
  // Each test case calls [prepare] to initialize them.
  late PerAccountStore store;

  /// Initialize [store] and the rest of the test state.
  void prepare() {
    store = eg.store();
  }

  Future<void> addMessages(Iterable<Message> messages) async {
    for (final m in messages) {
      await store.handleEvent(MessageEvent(id: 0, message: m));
    }
  }

  group('reconcileMessages', () {
    test('from empty', () async {
      prepare();
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
      prepare();
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
      prepare();
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
      prepare();
      check(store.messages).isEmpty();

      final newMessage = eg.streamMessage();
      await store.handleEvent(MessageEvent(id: 1, message: newMessage));
      check(store.messages).deepEquals({
        newMessage.id: newMessage,
      });
    });

    test('from not-empty', () async {
      prepare();
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
      prepare();
      final message = eg.streamMessage(id: 1, content: '<p>foo</p>');
      await addMessages([message]);
      check(store.messages).deepEquals({1: message});

      final newMessage = eg.streamMessage(id: 1, content: '<p>bar</p>');
      await store.handleEvent(MessageEvent(id: 1, message: newMessage));
      check(store.messages).deepEquals({1: newMessage});
    });
  });
}
