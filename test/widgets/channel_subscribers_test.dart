import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/channel_subscribers.dart';
import 'package:zulip/widgets/profile.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../stdlib_checks.dart';
import 'test_app.dart';

late PerAccountStore store;
late FakeApiConnection connection;

Future<void> setupChannelMembersPage(WidgetTester tester, {
  required int streamId,
  required List<int> subscriberIds,
  List<User>? users,
  bool simulateError = false,
}) async {
  addTearDown(testBinding.reset);

  final stream = eg.stream(streamId: streamId);
  await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot(
    streams: [stream],
    subscriptions: [eg.subscription(stream)],
    realmUsers: [eg.selfUser, ...?users],
  ));
  store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
  connection = store.connection as FakeApiConnection;

  if (simulateError) {
    connection.prepare(httpException: Exception('Network error'));
  } else {
    connection.prepare(json: GetSubscribersResult(
      subscribers: subscriberIds,
    ).toJson());
  }

  await tester.pumpWidget(TestZulipApp(
    accountId: eg.selfAccount.id,
    child: ChannelMembersPage(streamId: streamId),
  ));

  await tester.pump();
}

void main() {
  TestZulipBinding.ensureInitialized();

  group('ChannelMembersPage', () {
    testWidgets('shows loading state initially', (tester) async {
      await setupChannelMembersPage(tester,
        streamId: 1,
        subscriberIds: [1, 2, 3]);

      check(find.byType(CircularProgressIndicator)).findsOne();
      check(find.byType(TextField)).findsNothing();

      await tester.pumpAndSettle();
    });

    testWidgets('displays members after loading', (tester) async {
      final user1 = eg.user(userId: 1, fullName: 'Alice');
      final user2 = eg.user(userId: 2, fullName: 'Bob');

      await setupChannelMembersPage(tester,
        streamId: 1,
        subscriberIds: [1, 2],
        users: [user1, user2]);

      await tester.pumpAndSettle();

      check(find.text('Alice')).findsOne();
      check(find.text('Bob')).findsOne();
      check(find.byType(CircularProgressIndicator)).findsNothing();
    });

    testWidgets('shows member count in app bar', (tester) async {
      await setupChannelMembersPage(tester,
        streamId: 1,
        subscriberIds: [1, 2, 3]);

      await tester.pumpAndSettle();

      check(find.text('3 members')).findsOne();
    });

    group('sorting', () {
      testWidgets('self user appears first', (tester) async {
        final user1 = eg.user(userId: 1, fullName: 'Alice');
        final user2 = eg.user(userId: 2, fullName: 'Bob');

        await setupChannelMembersPage(tester,
          streamId: 1,
          subscriberIds: [1, 2, eg.selfUser.userId],
          users: [user1, user2]);

        await tester.pumpAndSettle();

        final listItems = tester.widgetList<Widget>(
          find.byType(InkWell)).toList();

        final firstItem = listItems.first;
        check(find.descendant(
          of: find.byWidget(firstItem),
          matching: find.text('(you)'))).findsOne();
      });

      testWidgets('other members sorted alphabetically', (tester) async {
        final user1 = eg.user(userId: 1, fullName: 'Charlie');
        final user2 = eg.user(userId: 2, fullName: 'Alice');
        final user3 = eg.user(userId: 3, fullName: 'Bob');

        await setupChannelMembersPage(
          tester,
          streamId: 1,
          subscriberIds: [1, 2, 3],
          users: [user1, user2, user3],
        );

        await tester.pumpAndSettle();

        final textWidgets = tester.widgetList<Text>(find.byType(Text));

        final names = textWidgets
            .map((w) => w.data)
            .where((text) => text == 'Alice' || text == 'Bob' || text == 'Charlie')
            .toList();
        check(names).deepEquals(['Alice', 'Bob', 'Charlie']);
      });
    });

    group('search', () {
      testWidgets('filters by name', (tester) async {
        final user1 = eg.user(userId: 1, fullName: 'Alice Smith');
        final user2 = eg.user(userId: 2, fullName: 'Bob Jones');

        await setupChannelMembersPage(tester,
          streamId: 1,
          subscriberIds: [1, 2],
          users: [user1, user2]);

        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Alice');
        await tester.pumpAndSettle();

        check(find.text('Alice Smith')).findsOne();
        check(find.text('Bob Jones')).findsNothing();
      });

      testWidgets('filters by email', (tester) async {
        final user1 = eg.user(userId: 1, fullName: 'Alice',
          email: 'alice@example.com');
        final user2 = eg.user(userId: 2, fullName: 'Bob',
          email: 'bob@example.com');

        await setupChannelMembersPage(tester,
          streamId: 1,
          subscriberIds: [1, 2],
          users: [user1, user2]);

        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'alice@');
        await tester.pumpAndSettle();

        check(find.text('Alice')).findsOne();
        check(find.text('Bob')).findsNothing();
      });

      testWidgets('search is case-insensitive', (tester) async {
        final user1 = eg.user(userId: 1, fullName: 'Alice');

        await setupChannelMembersPage(tester,
          streamId: 1,
          subscriberIds: [1],
          users: [user1]);

        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'ALICE');
        await tester.pumpAndSettle();

        check(find.text('Alice')).findsOne();
      });

      testWidgets('clear button clears search', (tester) async {
        final user1 = eg.user(userId: 1, fullName: 'Alice');
        final user2 = eg.user(userId: 2, fullName: 'Bob');

        await setupChannelMembersPage(tester,
          streamId: 1,
          subscriberIds: [1, 2],
          users: [user1, user2]);

        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Alice');
        await tester.pumpAndSettle();
        check(find.text('Bob')).findsNothing();

        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        check(find.text('Alice')).findsOne();
        check(find.text('Bob')).findsOne();
      });

      testWidgets('shows "no members found" message', (tester) async {
        final user1 = eg.user(userId: 1, fullName: 'Alice');

        await setupChannelMembersPage(tester,
          streamId: 1,
          subscriberIds: [1],
          users: [user1]);

        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Nonexistent');
        await tester.pumpAndSettle();

        check(find.text('No members found')).findsOne();
      });
    });

    group('user display', () {
      testWidgets('shows "(you)" for self', (tester) async {
        await setupChannelMembersPage(tester,
          streamId: 1,
          subscriberIds: [eg.selfUser.userId]);

        await tester.pumpAndSettle();

        check(find.text('(you)')).findsOne();
      });

      testWidgets('shows "Deactivated" for inactive users', (tester) async {
        final inactiveUser = eg.user(userId: 1, fullName: 'Alice',
          isActive: false);

        await setupChannelMembersPage(tester,
          streamId: 1,
          subscriberIds: [1],
          users: [inactiveUser]);

        await tester.pumpAndSettle();

        check(find.text('Deactivated')).findsOne();
      });
    });

    testWidgets('tapping member opens profile page', (tester) async {
      final user1 = eg.user(userId: 1, fullName: 'Alice');

      await setupChannelMembersPage(tester,
        streamId: 1,
        subscriberIds: [1],
        users: [user1]);

      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();

      check(find.byType(ProfilePage)).findsOne();
    });

    testWidgets('handles unknown users gracefully', (tester) async {
      await setupChannelMembersPage(tester,
        streamId: 1,
        subscriberIds: [999]);

      await tester.pumpAndSettle();
      check(find.byType(InkWell)).findsNothing();
    });

    testWidgets('makes API request on mount', (tester) async {
      await setupChannelMembersPage(tester,
        streamId: 123,
        subscriberIds: [1, 2]);

      await tester.pump(Duration.zero);

      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('GET')
        ..url.path.equals('/api/v1/streams/123/members');
    });
  });
}
