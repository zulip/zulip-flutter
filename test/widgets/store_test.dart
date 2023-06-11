import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/store.dart';

import '../model/binding.dart';
import '../example_data.dart' as eg;
import '../model/store_checks.dart';

void main() {
  TestDataBinding.ensureInitialized();

  testWidgets('GlobalStoreWidget', (WidgetTester tester) async {
    addTearDown(TestDataBinding.instance.reset);

    GlobalStore? globalStore;
    await tester.pumpWidget(
      GlobalStoreWidget(
        child: Builder(
          builder: (context) {
            globalStore = GlobalStoreWidget.of(context);
            return const SizedBox.shrink();
          })));
    // First, shows a loading page instead of child.
    check(tester.any(find.byType(CircularProgressIndicator))).isTrue();
    check(globalStore).isNull();

    await tester.pump();
    // Then after loading, mounts child instead, with provided store.
    check(tester.any(find.byType(CircularProgressIndicator))).isFalse();
    check(globalStore).identicalTo(TestDataBinding.instance.globalStore);

    await TestDataBinding.instance.globalStore.add(eg.selfAccount, eg.initialSnapshot);
    check(globalStore).isNotNull()
      .accountEntries.single
      .equals((accountId: eg.selfAccount.id, account: eg.selfAccount));
  });

  testWidgets('PerAccountStoreWidget basic', (tester) async {
    final globalStore = TestDataBinding.instance.globalStore;
    addTearDown(TestDataBinding.instance.reset);
    await globalStore.add(eg.selfAccount, eg.initialSnapshot);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GlobalStoreWidget(
          child: PerAccountStoreWidget(
            accountId: eg.selfAccount.id,
            child: Builder(
              builder: (context) {
                final store = PerAccountStoreWidget.of(context);
                return Text('found store, account: ${store.account.id}');
              })))));
    await tester.pump();
    await tester.pump();

    tester.widget(find.text('found store, account: ${eg.selfAccount.id}'));
  });

  testWidgets('PerAccountStoreWidget immediate data after first loaded', (tester) async {
    final globalStore = TestDataBinding.instance.globalStore;
    addTearDown(TestDataBinding.instance.reset);
    await globalStore.add(eg.selfAccount, eg.initialSnapshot);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GlobalStoreWidget(
          child: PerAccountStoreWidget(
            key: const ValueKey(1),
            accountId: eg.selfAccount.id,
            child: Builder(
              builder: (context) {
                final store = PerAccountStoreWidget.of(context);
                return Text('found store, account: ${store.account.id}');
              })))));

    // First, the global store has to load.
    check(tester.any(find.byType(PerAccountStoreWidget))).isFalse();
    await tester.pump();
    check(tester.any(find.byType(PerAccountStoreWidget))).isTrue();

    // Then the per-account store has to load.
    check(tester.any(find.textContaining('found store'))).isFalse();
    await tester.pump();
    check(tester.any(find.textContaining('found store'))).isTrue();

    // Specifically it has the expected data.
    tester.widget(find.text('found store, account: ${eg.selfAccount.id}'));

    // But then if we mount a separate PerAccountStoreWidget...
    final oldState = tester.state(find.byType(PerAccountStoreWidget));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GlobalStoreWidget(
          child: PerAccountStoreWidget(
            key: const ValueKey(2),
            accountId: eg.selfAccount.id,
            child: Builder(
              builder: (context) {
                final store = PerAccountStoreWidget.of(context);
                return Text('found store, account: ${store.account.id}');
              })))));

    // (... even one that really is separate, with its own fresh state node ...)
    check(tester.state(find.byType(PerAccountStoreWidget)))
      .not(it()..identicalTo(oldState));

    // ... then its child appears immediately, without waiting to load.
    check(tester.any(find.textContaining('found store'))).isTrue();
    tester.widget(find.text('found store, account: ${eg.selfAccount.id}'));
  });
}
