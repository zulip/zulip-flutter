import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/widgets/channel_list.dart';

import '../model/binding.dart';
import '../example_data.dart' as eg;
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  Future<void> setupChannelListPage(WidgetTester tester, {
    required List<ZulipStream> streams, required List<Subscription> subscriptions}) async {
    addTearDown(testBinding.reset);
    final initialSnapshot = eg.initialSnapshot(
      subscriptions: subscriptions,
      streams: streams.toList(),
    );
    await testBinding.globalStore.add(eg.selfAccount, initialSnapshot);

    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id, child: const ChannelListPage()));

    // global store, per-account store
    await tester.pumpAndSettle();
  }

  int getItemCount() {
    return find.byType(ChannelItem).evaluate().length;
  }

  testWidgets('smoke', (tester) async {
    await setupChannelListPage(tester, streams: [], subscriptions: []);
    check(getItemCount()).equals(0);
  });

  testWidgets('basic list', (tester) async {
    final streams = List.generate(3, (index) => eg.stream());
    await setupChannelListPage(tester, streams: streams, subscriptions: []);
    check(getItemCount()).equals(3);
  });
}
