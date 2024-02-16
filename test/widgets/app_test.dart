import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/page.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../test_navigation.dart';
import 'page_checks.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('ZulipApp initial navigation', () {
    late List<Route<dynamic>> pushedRoutes = [];

    Future<List<Route<dynamic>>> initialRoutes(WidgetTester tester) async {
      pushedRoutes = [];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
      await tester.pump();
      return pushedRoutes;
    }

    testWidgets('when no accounts, go to choose account', (tester) async {
      addTearDown(testBinding.reset);
      check(await initialRoutes(tester)).deepEquals([
        (Subject it) => it.isA<WidgetRoute>().page.isA<ChooseAccountPage>(),
      ]);
    });

    testWidgets('when have accounts, go to home page for first account', (tester) async {
      addTearDown(testBinding.reset);

      // We'll need per-account data for the account that a page will be opened
      // for, but not for the other account.
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await testBinding.globalStore.insertAccount(eg.otherAccount.toCompanion(false));

      check(await initialRoutes(tester)).deepEquals([
        (Subject it) => it.isA<WidgetRoute>().page.isA<ChooseAccountPage>(),
        (Subject it) => it.isA<MaterialAccountWidgetRoute>()
          ..accountId.equals(eg.selfAccount.id)
          ..page.isA<HomePage>(),
      ]);
    });
  });
}
