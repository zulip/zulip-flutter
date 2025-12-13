import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/submessage.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/poll.dart';

import '../stdlib_checks.dart';
import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;
  late Message message;

  Future<void> preparePollWidget(
    WidgetTester tester,
    SubmessageData? submessageContent, {
    Iterable<User>? users,
    List<int>? mutedUserIds,
    Iterable<(User, int)> voterIdxPairs = const [],
  }) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    await store.addUsers(users ?? [eg.selfUser, eg.otherUser]);
    if (mutedUserIds != null) {
      await store.setMutedUsers(mutedUserIds);
    }
    connection = store.connection as FakeApiConnection;

    message = eg.streamMessage(
      sender: eg.selfUser,
      submessages: [eg.submessage(content: submessageContent)]);
    await store.addMessage(message);
    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
      child: PollWidget(messageId: message.id, poll: message.poll!)));
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

  testWidgets('muted voters', (tester) async {
    final user1 = eg.user(userId: 1, fullName: 'User 1');
    final user2 = eg.user(userId: 2, fullName: 'User 2');
    await preparePollWidget(tester, pollWidgetData,
      users: [user1, user2],
      mutedUserIds: [user2.userId],
      voterIdxPairs: [(user1, 0), (user2, 0), (user2, 1)]);

    check(findTextAtRow('(User 1, Muted user)', index: 0)).findsOne();
    check(findTextAtRow('(Muted user)', index: 1)).findsOne();
  });

  testWidgets('show unknown voter', (tester) async {
    await preparePollWidget(tester, pollWidgetData,
      users: [eg.selfUser], voterIdxPairs: [(eg.thirdUser, 1)]);
    check(findInPoll(find.text('(unknown user)'))).findsOne();
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

  void checkVoteRequest(PollOptionKey key, PollVoteOp op) {
    check(connection.takeRequests()).single.isA<http.Request>()
      ..method.equals('POST')
      ..url.path.equals('/api/v1/submessage')
      ..bodyFields.deepEquals({
        'message_id': jsonEncode(message.id),
        'msg_type': 'widget',
        'content': jsonEncode(PollVoteEventSubmessage(key: key, op: op)),
      });
  }

  testWidgets('tap to toggle vote', (tester) async {
    await preparePollWidget(tester, eg.pollWidgetData(
      question: 'title', options: ['A']), voterIdxPairs: [(eg.otherUser, 0)]);
    final optionKey = PollEventSubmessage.optionKey(senderId: null, idx: 0);

    // Because eg.selfUser didn't vote for the option, add their vote.
    connection.prepare(json: {});
    await tester.tap(findTextAtRow('1', index: 0));
    await tester.pump(Duration.zero);
    checkVoteRequest(optionKey, PollVoteOp.add);

    // We don't local echo right now,
    // so wait to hear from the server to get the poll updated.
    await store.handleEvent(
      eg.submessageEvent(message.id, eg.selfUser.userId,
        content: PollVoteEventSubmessage(key: optionKey, op: PollVoteOp.add)));
    // Wait for the poll widget rebuild
    await tester.pump(Duration.zero);

    // Because eg.selfUser did vote for the option, remove their vote.
    connection.prepare(json: {});
    await tester.tap(findTextAtRow('2', index: 0));
    await tester.pump(Duration.zero);
    checkVoteRequest(optionKey, PollVoteOp.remove);
  });
}
