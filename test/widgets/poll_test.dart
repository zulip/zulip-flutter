import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/submessage.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/poll.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/message_list_test.dart';
import '../model/test_store.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;

  Future<void> prepare({Iterable<User>? users}) async {
    addTearDown(testBinding.reset);

    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    await store.addUsers(users ?? [eg.selfUser, eg.otherUser]);
  }

  Future<void> prepareZulipWidget(WidgetTester tester,
    Object? submessageContent,
    {Iterable<(User, int)> voterOptionIndexPairs = const []}
  ) async {
    final message = eg.streamMessage(id: 123, sender: eg.selfUser,
      submessages: [
        eg.submessage(messageId: 123, content: submessageContent),
      ]);
    (store.connection as FakeApiConnection).prepare(json:
      newestResult(foundOldest: true, messages: [message]).toJson());
    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
      child: MessageListPage(narrow: TopicNarrow.ofMessage(message))));

    await tester.pumpAndSettle();

    for (final (voter, optionIndex) in voterOptionIndexPairs) {
      await store.handleEvent(eg.submessageEvent(123, voter.userId,
        content: PollVoteEvent(
          key: PollEvent.optionKey(senderId: null, optionIndex: optionIndex),
          op: VoteOp.add).toJson()));
    }
    await tester.pump();
  }

  Finder findInPoll(Finder matching) => find.descendant(
    of: find.byType(PollWidget),
    matching: matching,
  );

  testWidgets('smoke', (tester) async {
    await prepare();
    await prepareZulipWidget(tester,
      eg.pollWidgetDataFavoriteLetter,
      voterOptionIndexPairs: [
        (eg.selfUser, 0),
        (eg.selfUser, 1),
        (eg.otherUser, 1),
      ]
    );

    check(findInPoll(find.text('favorite letter')).evaluate()).single;
    int optionIndex = 0;
    for (final (text, vote, names) in [
      ('A', '1', '(${eg.selfUser.fullName})'),
      ('B', '2', '(${eg.selfUser.fullName}, ${eg.otherUser.fullName})'),
      ('C', '0', ''),
    ]) {
      final optionFinder = findInPoll(find.byType(Row)).at(optionIndex++);
      check(find.descendant(of: optionFinder, matching: find.text(text)).evaluate()).single;
      check(find.descendant(of: optionFinder, matching: find.text(vote)).evaluate()).single;
      if (names.isNotEmpty) {
        check(find.descendant(of: optionFinder, matching: find.text(names)).evaluate()).single;
      }
    }
  });

  testWidgets('a lot of voters', (tester) async {
    final users = List.generate(100, (i) => eg.user(fullName: 'user#$i'));
    await prepare(users: users);
    await prepareZulipWidget(tester, eg.pollWidgetDataFavoriteLetter,
      voterOptionIndexPairs: users.map((user) => (user, 0)),
    );
    final optionFinder = findInPoll(find.byType(Row)).at(0);
    final allUserNames = '(${users.map((user) => user.fullName).join(', ')})';
    check(find.descendant(
      of: optionFinder, matching: find.text(allUserNames)).evaluate()).single;
    check(find.descendant(
      of: optionFinder, matching: find.text('100')).evaluate()).single;
  });

  testWidgets('show unknown voter', (tester) async {
    await prepare();
    await prepareZulipWidget(tester, eg.pollWidgetDataFavoriteLetter);
    await store.handleEvent(eg.submessageEvent(123, eg.thirdUser.userId,
      content: PollVoteEvent(
        key: PollEvent.optionKey(senderId: null, optionIndex: 1),
        op: VoteOp.add).toJson()));
    await tester.pump();
    check(findInPoll(find.text('((unknown user))')).evaluate()).single;
  });

  testWidgets('poll title missing', (tester) async {
    await prepare();
    await prepareZulipWidget(tester, PollWidgetData(
      extraData: const PollWidgetExtraData(question: '', options: ['A', 'B'])));
    check(findInPoll(find.text('No question.')).evaluate()).single;
  });

  testWidgets('poll options missing', (tester) async {
    await prepare();
    await prepareZulipWidget(tester, PollWidgetData(
      extraData: const PollWidgetExtraData(question: 'title', options: [])));
    check(findInPoll(find.text('This poll has no options yet.')).evaluate()).single;
  });
}
