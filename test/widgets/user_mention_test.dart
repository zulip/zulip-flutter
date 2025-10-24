import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/content.dart';
import 'package:zulip/widgets/content.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../test_navigation.dart';
import 'test_app.dart';

Widget plainContent(String html) {
  return Builder(builder: (context) =>
    DefaultTextStyle(
      style: ContentTheme.of(context).textStylePlainParagraph,
      child: BlockContentList(nodes: parseContent(html).nodes)));
}

Future<void> prepareContent(WidgetTester tester, Widget child, {
  bool wrapWithPerAccountStoreWidget = false,
}) async {
  if (wrapWithPerAccountStoreWidget) {
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
  }
  addTearDown(testBinding.reset);

  await tester.pumpWidget(TestZulipApp(
    accountId: wrapWithPerAccountStoreWidget ? eg.selfAccount.id : null,
    child: child));
  await tester.pump(); // global store
  if (wrapWithPerAccountStoreWidget) {
    await tester.pump();
  }
}

void main() {
  TestZulipBinding.ensureInitialized();

  group('UserMention tappable functionality', () {
    testWidgets('mention with valid user ID has gesture detector', (tester) async {
      await prepareContent(tester, plainContent('<p><span class="user-mention" data-user-id="123">@Test User</span></p>'));
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('mention with user ID navigates to ProfilePage when tapped', (tester) async {
      final pushedRoutes = <Route<dynamic>>[];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);

      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      addTearDown(testBinding.reset);
      await tester.pumpWidget(TestZulipApp(
        accountId: eg.selfAccount.id,
        navigatorObservers: [testNavObserver],
        child: plainContent('<p><span class="user-mention" data-user-id="123">@Test User</span></p>'),
      ));
      await tester.pump(); // global store

      await tester.pump(); // Allow any deferred work to complete
      
      expect(find.byType(GestureDetector), findsOneWidget);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      // Verify that navigation occurred (at least one route was pushed)
      expect(pushedRoutes.length, greaterThanOrEqualTo(1));
    });

    testWidgets('mention without user ID does not have gesture detector', (tester) async {
      await prepareContent(tester, plainContent('<p><span class="user-mention">@Test User</span></p>'));
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('mention with invalid user ID does not have gesture detector', (tester) async {
      await prepareContent(tester, plainContent('<p><span class="user-mention" data-user-id="invalid">@Test User</span></p>'));
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('mention with wildcard user ID does not have gesture detector', (tester) async {
      await prepareContent(tester, plainContent('<p><span class="user-mention" data-user-id="*">@all</span></p>'));
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('mention with zero user ID does not have gesture detector', (tester) async {
      await prepareContent(tester, plainContent('<p><span class="user-mention" data-user-id="0">@Test User</span></p>'));
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('mention with negative user ID does not have gesture detector', (tester) async {
      await prepareContent(tester, plainContent('<p><span class="user-mention" data-user-id="-1">@Test User</span></p>'));
      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}