import 'package:checks/checks.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/widgets/channel_colors.dart';
import 'package:zulip/widgets/counter_badge.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('CounterBadge', () {
    Future<void> prepare(WidgetTester tester, {
      required Widget child,
      Subscription? subscription,
    }) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      if (subscription != null) {
        await store.addStream(ZulipStream.fromSubscription(subscription));
        await store.addSubscription(subscription);
      }
      await tester.pumpWidget(TestZulipApp(
        accountId: eg.selfAccount.id,
        child: child));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('smoke test; no crash', (tester) async {
      await prepare(tester,
        child: const CounterBadge(count: 1, channelIdForBackground: null));
      tester.widget(find.text("1"));
    });

    group('background', () {
      Color? findBackgroundColor(WidgetTester tester) {
        final widget = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
        final decoration = widget.decoration as BoxDecoration;
        return decoration.color;
      }

      testWidgets('default color', (tester) async {
        await prepare(tester,
          child: CounterBadge(count: 1, channelIdForBackground: null));
        check(findBackgroundColor(tester)).isNotNull().isSameColorAs(const Color(0x26666699));
      });

      testWidgets('stream color', (tester) async {
        final subscription = eg.subscription(eg.stream(), color: 0xff76ce90);
        await prepare(tester,
          subscription: subscription,
          child: CounterBadge(
            count: 1,
            channelIdForBackground: subscription.streamId));
        check(findBackgroundColor(tester)).isNotNull()
          .isSameColorAs(ChannelColorSwatch.light(0xff76ce90).unreadCountBadgeBackground);
      });
    });
  });
}
