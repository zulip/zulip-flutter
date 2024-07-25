import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/app_bar.dart';
import 'package:zulip/widgets/profile.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  testWidgets('show progress indicator when loading', (tester) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

    final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    await store.addUser(eg.selfUser);

    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
      child: ProfilePage(userId: eg.selfUser.userId)));

    final finder = find.descendant(
      of: find.byType(ZulipAppBar),
      matching: find.byType(LinearProgressIndicator));

    await tester.pumpAndSettle();
    final rectBefore = tester.getRect(find.byType(ZulipAppBar));
    check(finder.evaluate()).isEmpty();
    store.isLoading = true;

    await tester.pump();
    check(tester.getRect(find.byType(ZulipAppBar))).equals(rectBefore);
    check(finder.evaluate()).single;
  });
}
