import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/typing_status.dart';
import 'package:zulip/widgets/compose_box.dart';
import 'package:zulip/widgets/icons.dart';

import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/test_store.dart';
import 'test_app.dart';

import '../example_data.dart' as eg;

void main() {
  TestZulipBinding.ensureInitialized();

  Future<void> prepare(WidgetTester tester, {
    required List<SavedSnippet> savedSnippets,
  }) async {
    addTearDown(testBinding.reset);
    final account = eg.account(
      user: eg.selfUser, zulipFeatureLevel: eg.futureZulipFeatureLevel);
    await testBinding.globalStore.add(account, eg.initialSnapshot(
      savedSnippets: savedSnippets,
      zulipFeatureLevel: eg.futureZulipFeatureLevel,
    ));
    final store = await testBinding.globalStore.perAccount(account.id);
    final channel = eg.stream();
    await store.addStream(channel);
    await store.addSubscription(eg.subscription(channel));
    await store.addUser(eg.selfUser);

    await tester.pumpWidget(TestZulipApp(
      accountId: account.id,
      child: ComposeBox(narrow: eg.topicNarrow(channel.streamId, 'test'))));
    await tester.pumpAndSettle();
  }

  Future<void> tapShowSavedSnippets(WidgetTester tester) async {
    await tester.tap(find.byIcon(ZulipIcons.message_square_text));
    await tester.pump();
    await tester.pump(Duration(milliseconds: 250)); // bottom-sheet animation
  }

  testWidgets('show placeholder when empty', (tester) async {
    await prepare(tester, savedSnippets: []);

    await tapShowSavedSnippets(tester);
    check(find.text('No saved snippets')).findsOne();
  });

  testWidgets('sort saved snippets by title', (tester) async {
    const content = 'saved snippet content';
    await prepare(tester, savedSnippets: [
      eg.savedSnippet(title: 'zzz',  content: content),
      eg.savedSnippet(title: '1abc', content: content),
      eg.savedSnippet(title: '1b',   content: content),
    ]);
    Finder findTitleAt(int index) => find.descendant(
      of: find.ancestor(of: find.text(content).at(index),
                        matching: find.byType(Column)),
      matching: find.byType(Text)).first;

    await tapShowSavedSnippets(tester);
    check(
      List.generate(3, (i) => tester.widget<Text>(findTitleAt(i))),
    ).deepEquals(<Condition<Object?>>[
      (it) => it.isA<Text>().data.equals('1abc'),
      (it) => it.isA<Text>().data.equals('1b'),
      (it) => it.isA<Text>().data.equals('zzz'),
    ]);
  });

  testWidgets('insert into content input', (tester) async {
    addTearDown(TypingNotifier.debugReset);
    TypingNotifier.debugEnable = false;
    await prepare(tester, savedSnippets: [
      eg.savedSnippet(
        title: 'saved snippet title',
        content: 'saved snippet content'),
    ]);

    await tapShowSavedSnippets(tester);
    check(find.text('saved snippet title')).findsOne();
    check(find.text('saved snippet content')).findsOne();

    await tester.tap(find.text('saved snippet content'));
    await tester.pump();
    await tester.pump(Duration(milliseconds: 250)); // bottom-sheet animation
    check(find.descendant(
      of: find.byType(ComposeBox),
      matching: find.textContaining('saved snippet content')),
    ).findsOne();
  });

  testWidgets('insert into non-empty content input', (tester) async {
    addTearDown(TypingNotifier.debugReset);
    TypingNotifier.debugEnable = false;
    await prepare(tester, savedSnippets: [
      eg.savedSnippet(content: 'saved snippet content'),
    ]);
    await tester.enterText(find.byType(TextField), 'some existing content');

    await tapShowSavedSnippets(tester);
    await tester.tap(find.text('saved snippet content'));
    await tester.pump();
    await tester.pump(Duration(milliseconds: 250)); // bottom-sheet animation
    check(find.descendant(
      of: find.byType(ComposeBox),
      matching: find.textContaining('some existing content\n\n'
                                    'saved snippet content')),
    ).findsOne();
  });
}
