import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/message_list.dart';

import '../test/api/fake_api.dart';
import '../test/example_data.dart' as eg;
import '../test/model/binding.dart';
import '../test/widgets/test_app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;

  Future<List<Message>> setupMessageListPage(WidgetTester tester, int messageCount) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    connection = store.connection as FakeApiConnection;

    // prepare message list data
    final messages = List.generate(messageCount,
      (i) => eg.streamMessage(flags: [MessageFlag.read]));
    connection.prepare(json:
      eg.newestGetMessagesResult(foundOldest: true, messages: messages).toJson());

    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
      child: const MessageListPage(initNarrow: CombinedFeedNarrow())));
    await tester.pumpAndSettle();
    return messages;
  }

  testWidgets('_UnreadMarker animation performance test', (tester) async {
    // This integration test is meant for measuring performance.
    // See docs/integration_test.md for how to use it.

    final messages = await setupMessageListPage(tester, 500);
    await binding.traceAction(() async {
      await store.handleEvent(eg.updateMessageFlagsRemoveEvent(
        MessageFlag.read,
        messages));
      await tester.pumpAndSettle();
      await store.handleEvent(UpdateMessageFlagsAddEvent(
        id: 1,
        flag: MessageFlag.read,
        messages: messages.map((e) => e.id).toList(),
        all: false));
      await tester.pumpAndSettle();
    });
  });
}
