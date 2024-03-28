import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/widgets/store.dart';
import 'package:zulip/widgets/subscription_list.dart';
import 'package:zulip/widgets/unread_count_badge.dart';

import '../flutter_checks.dart';
import '../model/binding.dart';
import '../example_data.dart' as eg;

void main() {
  TestZulipBinding.ensureInitialized();

  Future<void> setupStreamListPage(WidgetTester tester, {
    required List<Subscription> subscriptions,
    List<UserTopicItem> userTopics = const [],
    UnreadMessagesSnapshot? unreadMsgs,
  }) async {
    addTearDown(testBinding.reset);
    final initialSnapshot = eg.initialSnapshot(
      subscriptions: subscriptions,
      streams: subscriptions.toList(),
      userTopics: userTopics,
      unreadMsgs: unreadMsgs,
    );
    await testBinding.globalStore.add(eg.selfAccount, initialSnapshot);

    await tester.pumpWidget(
      MaterialApp(
        home: GlobalStoreWidget(
          child: PerAccountStoreWidget(
            accountId: eg.selfAccount.id,
            child: const SubscriptionListPage()))));

    // global store, per-account store
    await tester.pumpAndSettle();
  }

  bool isPinnedHeaderInTree() {
    return find.text('Pinned').evaluate().isNotEmpty;
  }

  bool isUnpinnedHeaderInTree() {
    return find.text('Unpinned').evaluate().isNotEmpty;
  }

  int getItemCount() {
    return find.byType(SubscriptionItem).evaluate().length;
  }

  testWidgets('smoke', (tester) async {
    await setupStreamListPage(tester, subscriptions: []);
    check(getItemCount()).equals(0);
    check(isPinnedHeaderInTree()).isFalse();
    check(isUnpinnedHeaderInTree()).isFalse();
  });

  testWidgets('basic subscriptions', (tester) async {
    await setupStreamListPage(tester, subscriptions: [
      eg.subscription(eg.stream(streamId: 1), pinToTop: true),
      eg.subscription(eg.stream(streamId: 2), pinToTop: true),
      eg.subscription(eg.stream(streamId: 3), pinToTop: false),
    ]);
    check(getItemCount()).equals(3);
    check(isPinnedHeaderInTree()).isTrue();
    check(isUnpinnedHeaderInTree()).isTrue();
  });

  testWidgets('only pinned subscriptions', (tester) async {
    await setupStreamListPage(tester, subscriptions: [
      eg.subscription(eg.stream(streamId: 1), pinToTop: true),
      eg.subscription(eg.stream(streamId: 2), pinToTop: true),
    ]);
    check(getItemCount()).equals(2);
    check(isPinnedHeaderInTree()).isTrue();
    check(isUnpinnedHeaderInTree()).isFalse();
  });

  testWidgets('only unpinned subscriptions', (tester) async {
    await setupStreamListPage(tester, subscriptions: [
      eg.subscription(eg.stream(streamId: 1), pinToTop: false),
      eg.subscription(eg.stream(streamId: 2), pinToTop: false),
    ]);
    check(getItemCount()).equals(2);
    check(isPinnedHeaderInTree()).isFalse();
    check(isUnpinnedHeaderInTree()).isTrue();
  });

  testWidgets('subscription sort', (tester) async {
    await setupStreamListPage(tester, subscriptions: [
      eg.subscription(eg.stream(streamId: 1, name: 'd'), pinToTop: true),
      eg.subscription(eg.stream(streamId: 2, name: 'c'), pinToTop: false),
      eg.subscription(eg.stream(streamId: 3, name: 'b'), pinToTop: true),
      eg.subscription(eg.stream(streamId: 4, name: 'a'), pinToTop: false),
    ]);
    check(isPinnedHeaderInTree()).isTrue();
    check(isUnpinnedHeaderInTree()).isTrue();

    final streamListItems = tester.widgetList<SubscriptionItem>(find.byType(SubscriptionItem)).toList();
    check(streamListItems.map((e) => e.subscription.streamId)).deepEquals([3, 1, 4, 2]);
  });

  testWidgets('unread badge shows with unreads', (tester) async {
    final stream = eg.stream();
    final unreadMsgs = eg.unreadMsgs(streams: [
      UnreadStreamSnapshot(streamId: stream.streamId, topic: 'a', unreadMessageIds: [1, 2]),
    ]);
    await setupStreamListPage(tester, subscriptions: [
      eg.subscription(stream),
    ], unreadMsgs: unreadMsgs);
    check(find.byType(UnreadCountBadge).evaluate()).length.equals(1);
  });

  testWidgets('unread badge counts unmuted only', (tester) async {
    final stream = eg.stream();
    final unreadMsgs = eg.unreadMsgs(streams: [
      UnreadStreamSnapshot(streamId: stream.streamId, topic: 'a', unreadMessageIds: [1, 2]),
      UnreadStreamSnapshot(streamId: stream.streamId, topic: 'b', unreadMessageIds: [3]),
    ]);
    await setupStreamListPage(tester,
      subscriptions: [eg.subscription(stream, isMuted: true)],
        userTopics: [UserTopicItem(
          streamId: stream.streamId,
          topicName: 'b',
          lastUpdated: 1234567890,
          visibilityPolicy: UserTopicVisibilityPolicy.unmuted,
        )],
        unreadMsgs: unreadMsgs);
    check(tester.widget<Text>(find.descendant(
        of: find.byType(UnreadCountBadge), matching: find.byType(Text))))
      .data.equals('1');
  });

  testWidgets('unread badge does not show with no unreads', (tester) async {
    final stream = eg.stream();
    final unreadMsgs = eg.unreadMsgs(streams: []);
    await setupStreamListPage(tester, subscriptions: [
      eg.subscription(stream),
    ], unreadMsgs: unreadMsgs);
    check(find.byType(UnreadCountBadge).evaluate()).length.equals(0);
  });

  testWidgets('color propagates to icon and badge', (tester) async {
    final stream = eg.stream();
    final unreadMsgs = eg.unreadMsgs(streams: [
      UnreadStreamSnapshot(streamId: stream.streamId, topic: 'a', unreadMessageIds: [1, 2]),
    ]);
    final subscription = eg.subscription(stream, color: Colors.red.value);
    final swatch = subscription.colorSwatch();
    await setupStreamListPage(tester, subscriptions: [
      subscription,
    ], unreadMsgs: unreadMsgs);
    check(getItemCount()).equals(1);
    final scaffoldBody = tester.widget<Scaffold>(find.byType(Scaffold)).body;
    check(tester.widget<Icon>(find.descendant(of:
      find.byWidget(scaffoldBody!), matching: find.byType(Icon))).color)
      .equals(swatch.iconOnPlainBackground);
    check(tester.widget<UnreadCountBadge>(find.byType(UnreadCountBadge)).backgroundColor)
      .equals(swatch);
  });
}
