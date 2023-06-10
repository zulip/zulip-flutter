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
}
