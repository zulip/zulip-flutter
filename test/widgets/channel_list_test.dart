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
    required List<ZulipStream> streams,
    required List<Subscription> subscriptions
  }) async {
    addTearDown(testBinding.reset);
    final initialSnapshot = eg.initialSnapshot(
      subscriptions: subscriptions,
      streams: streams,
    );
    await testBinding.globalStore.add(eg.selfAccount, initialSnapshot);

    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id, child: const ChannelListPage()));

    // global store, per-account store
    await tester.pumpAndSettle();
  }

  void checkItemCount(int expectedCount) {
    check(find.byType(ChannelItem).evaluate()).length.equals(expectedCount);
  }

  testWidgets('smoke', (tester) async {
    await setupChannelListPage(tester, streams: [], subscriptions: []);
    checkItemCount(0);
    check(find.text('There are no channels you can view in this organization.').evaluate()).single;
  });

  testWidgets('basic list', (tester) async {
    final streams = List.generate(3, (index) => eg.stream());
    await setupChannelListPage(tester, streams: streams, subscriptions: []);
    checkItemCount(3);
  });

  group('list ordering', () {
    Iterable<String> listedStreamNames(WidgetTester tester) => tester
      .widgetList<ChannelItem>(find.byType(ChannelItem))
      .map((e) => e.stream.name);

    List<ZulipStream> streamsFromNames(List<String> names) {
      return names.map((name) => eg.stream(name: name)).toList();
    }

    testWidgets('is alphabetically case-insensitive', (tester) async {
      final streams = streamsFromNames(['b', 'C', 'A']);
      await setupChannelListPage(tester, streams: streams, subscriptions: []);

      check(listedStreamNames(tester)).deepEquals(['A', 'b', 'C']);
    });

    testWidgets('is insensitive of user subscription', (tester) async {
      final streams = streamsFromNames(['b', 'c', 'a']);
      await setupChannelListPage(tester, streams: streams,
        subscriptions: [eg.subscription(streams[0])]);

      check(listedStreamNames(tester)).deepEquals(['a', 'b', 'c']);
    });
  });
}
