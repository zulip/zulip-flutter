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

      final updateEvent = UpdateMessageEvent(
        id: 1,
        messageId: originalMessage.id,
        messageIds: [originalMessage.id],
        flags: ["starred"],
        renderedContent: "<p>Hello, edited</p>",
        editTimestamp: 99999,
        isMeMessage: true,
        userId: userId,
        renderingOnly: false,
      );

      final message = messageList.messages.single;
      check(message)
        ..content.not(it()..equals(updateEvent.renderedContent!))
        ..lastEditTimestamp.isNull()
        ..flags.not(it()..deepEquals(updateEvent.flags))
        ..isMeMessage.not(it()..equals(updateEvent.isMeMessage!));

      bool listenersNotified = false;
      messageList.addListener(() { listenersNotified = true; });

      messageList.maybeUpdateMessage(updateEvent);
      check(listenersNotified).isTrue();
      check(messageList.messages.single)
        ..identicalTo(message)
        ..content.equals(updateEvent.renderedContent!)
        ..lastEditTimestamp.equals(updateEvent.editTimestamp)
        ..flags.equals(updateEvent.flags)
        ..isMeMessage.equals(updateEvent.isMeMessage!);
    });

    test('ignore when message not present', () async {
      final store = await setupStore(stream);

      final originalMessage = eg.streamMessage(id: 243, stream: stream,
        content: "<p>Hello, world</p>");
      final messageList = await messageListViewWithMessages([originalMessage], store, narrow);

      final updateEvent = UpdateMessageEvent(
        id: 1,
        messageId: originalMessage.id + 1,
        messageIds: [originalMessage.id + 1],
        flags: originalMessage.flags,
        renderedContent: "<p>Hello, edited</p>",
        editTimestamp: 99999,
        userId: userId,
        renderingOnly: false,
      );

      bool listenersNotified = false;
      messageList.addListener(() { listenersNotified = true; });

      messageList.maybeUpdateMessage(updateEvent);
      check(listenersNotified).isFalse();
      check(messageList.messages.single)
        ..content.equals(originalMessage.content)
        ..content.not(it()..equals(updateEvent.renderedContent!));
    });

    // TODO(server-5): Cut legacy case for rendering-only message update
    Future<void> checkRenderingOnly({required bool legacy}) async {
      final store = await setupStore(stream);

      final originalMessage = eg.streamMessage(id: 972, stream: stream,
        lastEditTimestamp: 78492,
        content: "<p>Hello, world</p>");
      final messageList = await messageListViewWithMessages([originalMessage], store, narrow);

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

      final message = messageList.messages.single;
      messageList.maybeUpdateMessage(updateEvent);
      check(messageList.messages.single)
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
  });
}
