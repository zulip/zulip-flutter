import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/submessage.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/poll.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;

  Future<void> preparePollWidget(
    WidgetTester tester,
    SubmessageData? submessageContent, {
    Iterable<User>? users,
    Iterable<(User, int)> voterIdxPairs = const [],
  }) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    await store.addUsers(users ?? [eg.selfUser, eg.otherUser]);

    Message message = eg.streamMessage(
      sender: eg.selfUser,
      submessages: [eg.submessage(content: submessageContent)]);
    await store.handleEvent(MessageEvent(id: 0, message: message));
    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
      child: PollWidget(poll: message.poll!)));
    await tester.pump();

    for (final (voter, idx) in voterIdxPairs) {
      await store.handleEvent(eg.submessageEvent(message.id, voter.userId,
        content: PollVoteEventSubmessage(
          key: PollEventSubmessage.optionKey(senderId: null, idx: idx),
          op: PollVoteOp.add)));
    }
    await tester.pump();
  }

  Finder findInPoll(Finder matching) =>
    find.descendant(of: find.byType(PollWidget), matching: matching);

  Finder findTextAtRow(String text, {required int index}) =>
    find.descendant(
      of: findInPoll(find.byType(Row)).at(index), matching: find.text(text));

  testWidgets('smoke', (tester) async {
    await preparePollWidget(tester,
      eg.pollWidgetData(question: 'favorite letter', options: ['A', 'B', 'C']),
      voterIdxPairs: [
        (eg.selfUser, 0),
        (eg.selfUser, 1),
        (eg.otherUser, 1),
      ]);

    check(findInPoll(find.text('favorite letter'))).findsOne();

    check(findTextAtRow('A', index: 0)).findsOne();
    check(findTextAtRow('1', index: 0)).findsOne();
    check(findTextAtRow('(${eg.selfUser.fullName})', index: 0)).findsOne();

    check(findTextAtRow('B', index: 1)).findsOne();
    check(findTextAtRow('2', index: 1)).findsOne();
    check(findTextAtRow(
      '(${eg.selfUser.fullName}, ${eg.otherUser.fullName})', index: 1)).findsOne();

    check(findTextAtRow('C', index: 2)).findsOne();
    check(findTextAtRow('0', index: 2)).findsOne();
  });

  final pollWidgetData = eg.pollWidgetData(question: 'poll', options: ['A', 'B']);

  testWidgets('a lot of voters', (tester) async {
    final users = List.generate(100, (i) => eg.user(fullName: 'user#$i'));
    await preparePollWidget(tester, pollWidgetData,
      users: users, voterIdxPairs: users.map((user) => (user, 0)));

    final allUserNames = '(${users.map((user) => user.fullName).join(', ')})';
    check(findTextAtRow(allUserNames, index: 0)).findsOne();
    check(findTextAtRow('100', index: 0)).findsOne();
  });

  testWidgets('show unknown voter', (tester) async {
    await preparePollWidget(tester, pollWidgetData,
      users: [eg.selfUser], voterIdxPairs: [(eg.thirdUser, 1)]);
    check(findInPoll(find.text('((unknown user))'))).findsOne();
  });

  testWidgets('poll title missing', (tester) async {
    await preparePollWidget(tester, eg.pollWidgetData(
      question: '', options: ['A']));
    check(findInPoll(find.text('No question.'))).findsOne();
  });

  testWidgets('poll options missing', (tester) async {
    await preparePollWidget(tester, eg.pollWidgetData(
      question: 'title', options: []));
    check(findInPoll(find.text('This poll has no options yet.'))).findsOne();
  });
}
