import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/page.dart';

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

    testWidgets('go to choose-account page', (tester) async {
      addTearDown(testBinding.reset);
      check(await initialRoutes(tester)).deepEquals([
        (Subject it) => it.isA<WidgetRoute>().page.isA<ChooseAccountPage>(),
      ]);
    });
  });
}
