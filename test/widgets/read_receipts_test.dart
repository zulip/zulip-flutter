import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/profile.dart';
import 'package:zulip/widgets/read_receipts.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;
  late TransitionDurationObserver transitionDurationObserver;

  Future<void> setupReceiptsSheet(WidgetTester tester, {
    required int messageId,
    required List<User> users,
    ValueGetter<List<int>>? prepareReceiptsResponseSuccess,
    ValueGetter<Object>? prepareReceiptsResponseError,
  }) async {
    assert((prepareReceiptsResponseSuccess == null) != (prepareReceiptsResponseError == null));

    addTearDown(testBinding.reset);

    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    await store.addUsers(users);

    final message = eg.streamMessage(id: messageId);
    final stream = eg.stream(streamId: message.streamId);
    await store.addStream(stream);
    await store.addSubscription(eg.subscription(stream));

    connection = store.connection as FakeApiConnection;
    connection.prepare(json: eg.newestGetMessagesResult(
      foundOldest: true, messages: [message]).toJson());

    transitionDurationObserver = TransitionDurationObserver();
    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
      navigatorObservers: [transitionDurationObserver],
      child: MessageListPage(initNarrow: CombinedFeedNarrow())));
    // global store, per-account store, and message list get loaded
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(MessageContent));
    await transitionDurationObserver.pumpPastTransition(tester);

    connection.prepare(
      json: prepareReceiptsResponseSuccess == null ? null
        : GetReadReceiptsResult(userIds: prepareReceiptsResponseSuccess()).toJson(),
      httpException: prepareReceiptsResponseError == null ? null
        : prepareReceiptsResponseError(),
      delay: transitionDurationObserver.transitionDuration
             + const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(ZulipIcons.check_check));
    await transitionDurationObserver.pumpPastTransition(tester);

    check(find.ancestor(of: find.byType(ReadReceipts),
      matching: find.byType(BottomSheet))).findsOne(); // receipts sheet opened
    check(find.byType(CircularProgressIndicator)).findsOne();
    check(find.text('Read receipts')).findsOne();
    check(find.text('Close')).findsOne();

    await tester.pumpAndSettle();
  }

  Finder findUserItem(String fullName) =>
    find.widgetWithText(ReadReceiptsUserItem, fullName);

  group('success', () {
    testWidgets('message read by many people', (tester) async {
      final user1 = eg.user(userId: 1, fullName: 'User 1');
      final user2 = eg.user(userId: 2, fullName: 'User 2');
      await setupReceiptsSheet(tester, messageId: 100, users: [user1, user2],
        prepareReceiptsResponseSuccess: () => [1, 2]);

      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('GET')
        ..url.path.equals('/api/v1/messages/100/read_receipts');

      check(find.text('This message has been read by 2 people:',
        findRichText: true)).findsOne();
      check(findUserItem('User 1')).findsOne();
      check(findUserItem('User 2')).findsOne();
    });

    testWidgets('message read by one person', (tester) async {
      final user1 = eg.user(userId: 1, fullName: 'User 1');
      final user2 = eg.user(userId: 2, fullName: 'User 2');
      await setupReceiptsSheet(tester, messageId: 100, users: [user1, user2],
        prepareReceiptsResponseSuccess: () => [1]);

      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('GET')
        ..url.path.equals('/api/v1/messages/100/read_receipts');

      check(find.text('This message has been read by 1 person:',
        findRichText: true)).findsOne();
      check(findUserItem('User 1')).findsOne();
      check(findUserItem('User 2')).findsNothing();
    });

    testWidgets('message read by no one', (tester) async {
      final user1 = eg.user(userId: 1, fullName: 'User 1');
      final user2 = eg.user(userId: 2, fullName: 'User 2');
      await setupReceiptsSheet(tester, messageId: 100, users: [user1, user2],
        prepareReceiptsResponseSuccess: () => []);

      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('GET')
        ..url.path.equals('/api/v1/messages/100/read_receipts');

      check(find.text('No one has read this message yet.')).findsOne();
      check(findUserItem('User 1')).findsNothing();
      check(findUserItem('User 2')).findsNothing();
    });

    testWidgets('tapping user item opens their profile', (tester) async {
      final user = eg.user(userId: 1, fullName: 'User 1');
      await setupReceiptsSheet(tester, messageId: 100, users: [user],
        prepareReceiptsResponseSuccess: () => [1]);

      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('GET')
        ..url.path.equals('/api/v1/messages/100/read_receipts');

      await tester.tap(findUserItem('User 1'));
      await transitionDurationObserver.pumpPastTransition(tester);
      check(find.byWidgetPredicate((widget) => widget is ProfilePage && widget.userId == 1))
        .findsOne();
    });
  });

  testWidgets('failure', (tester) async {
    await setupReceiptsSheet(tester, messageId: 100, users: [],
      prepareReceiptsResponseError: () => SocketException('failed'));

    check(connection.lastRequest).isA<http.Request>()
      ..method.equals('GET')
      ..url.path.equals('/api/v1/messages/100/read_receipts');

    check(find.text('Failed to load read receipts.')).findsOne();
  });
}
