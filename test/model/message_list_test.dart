import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/message_list.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';

import '../api/fake_api.dart';
import '../api/model/model_checks.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';

const int userId = 1;

Future<PerAccountStore> setupStore(ZulipStream stream) async {
  addTearDown(TestZulipBinding.instance.reset);

  await TestZulipBinding.instance.globalStore.add(eg.selfAccount, eg.initialSnapshot());

  final store = await TestZulipBinding.instance.globalStore.perAccount(eg.selfAccount.id);
  store.addUser(eg.user(userId: userId));
  store.addStream(stream);

  return store;
}

Future<MessageListView> messageListViewWithMessages(List<Message> messages, PerAccountStore store, Narrow narrow) async {
  final messageList = MessageListView.init(store: store, narrow: narrow);

  final connection = store.connection as FakeApiConnection;
  connection.prepare(json: GetMessagesResult(
    anchor: messages.first.id,
    foundNewest: true,
    foundOldest: true,
    foundAnchor: true,
    historyLimited: false,
    messages: messages,
  ).toJson());
  await messageList.fetch();

  return messageList;
}

void main() async {
  TestZulipBinding.ensureInitialized();

  final stream = eg.stream();
  final narrow = StreamNarrow(stream.streamId);

  test('findMessageWithId', () async {
    final store = await setupStore(stream);
    final m1 = eg.streamMessage(id: 2, stream: stream);
    final m2 = eg.streamMessage(id: 4, stream: stream);
    final m3 = eg.streamMessage(id: 6, stream: stream);
    final messageList = await messageListViewWithMessages([m1, m2, m3], store, narrow);

    // Exercise the binary search before, at, and after each element of the list.
    check(messageList.findMessageWithId(1)).equals(-1);
    check(messageList.findMessageWithId(2)).equals(0);
    check(messageList.findMessageWithId(3)).equals(-1);
    check(messageList.findMessageWithId(4)).equals(1);
    check(messageList.findMessageWithId(5)).equals(-1);
    check(messageList.findMessageWithId(6)).equals(2);
    check(messageList.findMessageWithId(7)).equals(-1);
  });

  group('maybeUpdateMessage', () {
    test('update a message', () async {
      final store = await setupStore(stream);

      final originalMessage = eg.streamMessage(id: 243, stream: stream,
        content: "<p>Hello, world</p>",
        flags: [],
      );
      final messageList = await messageListViewWithMessages([originalMessage], store, narrow);

      final newFlags = ["starred"];
      const newContent = "<p>Hello, edited</p>";
      const editTimestamp = 99999;
      final updateEvent = UpdateMessageEvent(
        id: 1,
        messageId: originalMessage.id,
        messageIds: [originalMessage.id],
        flags: newFlags,
        renderedContent: newContent,
        editTimestamp: editTimestamp,
        isMeMessage: true,
        userId: userId,
        renderingOnly: false,
      );

      final message = messageList.messages.single;
      check(message)
        ..content.not(it()..equals(newContent))
        ..lastEditTimestamp.isNull()
        ..flags.not(it()..deepEquals(newFlags))
        ..isMeMessage.isFalse();

      bool listenersNotified = false;
      messageList.addListener(() { listenersNotified = true; });

      messageList.maybeUpdateMessage(updateEvent);
      check(listenersNotified).isTrue();
      check(messageList.messages.single)
        ..identicalTo(message)
        ..content.equals(newContent)
        ..lastEditTimestamp.equals(editTimestamp)
        ..flags.equals(newFlags)
        ..isMeMessage.isTrue();
    });

    test('ignore when message not present', () async {
      final store = await setupStore(stream);

      const oldContent = "<p>Hello, world</p>";
      const newContent = "<p>Hello, edited</p>";
      const newTimestamp = 99999;

      final originalMessage = eg.streamMessage(id: 243, stream: stream, content: oldContent);
      final messageList = await messageListViewWithMessages([originalMessage], store, narrow);

      final updateEvent = UpdateMessageEvent(
        id: 1,
        messageId: originalMessage.id + 1,
        messageIds: [originalMessage.id + 1],
        flags: originalMessage.flags,
        renderedContent: newContent,
        editTimestamp: newTimestamp,
        userId: userId,
        renderingOnly: false,
      );

      final message = messageList.messages.single;
      check(message).content.equals(oldContent);

      bool listenersNotified = false;
      messageList.addListener(() { listenersNotified = true; });

      messageList.maybeUpdateMessage(updateEvent);
      check(listenersNotified).isFalse();
      check(message).content.equals(oldContent);
    });

    test('rendering-only update does not change timestamp', () async {
      final store = await setupStore(stream);

      const oldContent = "<p>Hello, world</p>";
      const oldTimestamp = 78492;
      const newContent = "<p>Hello, world</p> <div>Some link preview</div>";
      const newTimestamp = 99999;

      final originalMessage = eg.streamMessage(id: 972, stream: stream, content: oldContent);
      originalMessage.lastEditTimestamp = oldTimestamp;

      final messageList = await messageListViewWithMessages([originalMessage], store, narrow);

      final updateEvent = UpdateMessageEvent(
        id: 1,
        messageId: originalMessage.id,
        messageIds: [originalMessage.id],
        flags: originalMessage.flags,
        renderedContent: newContent,
        editTimestamp: newTimestamp,
        renderingOnly: true,
        userId: null,
      );

      final message = messageList.messages[0];
      messageList.maybeUpdateMessage(updateEvent);
      check(message)
        ..content.equals(newContent)
        ..lastEditTimestamp.equals(oldTimestamp);
    });

    // TODO(server-5): Cut this test; rely on renderingOnly from FL 114
    test('rendering-only update does not change timestamp (for old server versions)', () async {
      final store = await setupStore(stream);

      const oldContent = "<p>Hello, world</p>";
      const oldTimestamp = 78492;
      const newContent = "<p>Hello, world</p> <div>Some link preview</div>";
      const newTimestamp = 99999;

      final originalMessage = eg.streamMessage(id: 972, stream: stream, content: oldContent);
      originalMessage.lastEditTimestamp = oldTimestamp;

      final messageList = await messageListViewWithMessages([originalMessage], store, narrow);

      final updateEvent = UpdateMessageEvent(
        id: 1,
        messageId: originalMessage.id,
        messageIds: [originalMessage.id],
        flags: originalMessage.flags,
        renderedContent: newContent,
        editTimestamp: newTimestamp,
        renderingOnly: null,
        userId: null,
      );

      final message = messageList.messages.single;
      messageList.maybeUpdateMessage(updateEvent);
      check(message)
        ..content.equals(newContent)
        ..lastEditTimestamp.equals(oldTimestamp);
    });
  });
}
