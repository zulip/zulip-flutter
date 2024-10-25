import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/widgets/color.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/channel_colors.dart';
import 'package:zulip/widgets/subscription_list.dart';
import 'package:zulip/widgets/text.dart';
import 'package:zulip/widgets/unread_count_badge.dart';

import '../flutter_checks.dart';
import '../model/binding.dart';
import '../example_data.dart' as eg;
import 'test_app.dart';

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

    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
      child: const SubscriptionListPage()));

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

  group('subscription sorting', () {
    Iterable<int> listedStreamIds(WidgetTester tester) => tester
      .widgetList<SubscriptionItem>(find.byType(SubscriptionItem))
      .map((e) => e.subscription.streamId);

    testWidgets('pinned are shown on the top', (tester) async {
      await setupStreamListPage(tester, subscriptions: [
        eg.subscription(eg.stream(streamId: 1, name: 'a'), pinToTop: false),
        eg.subscription(eg.stream(streamId: 2, name: 'b'), pinToTop: true),
        eg.subscription(eg.stream(streamId: 3, name: 'c'), pinToTop: false),
      ]);
      check(listedStreamIds(tester)).deepEquals([2, 1, 3]);
    });

    testWidgets('pinned subscriptions are sorted', (tester) async {
      await setupStreamListPage(tester, subscriptions: [
        eg.subscription(eg.stream(streamId: 3, name: 'b'), pinToTop: true),
        eg.subscription(eg.stream(streamId: 1, name: 'c'), pinToTop: true),
        eg.subscription(eg.stream(streamId: 2, name: 'a'), pinToTop: true),
      ]);
      check(listedStreamIds(tester)).deepEquals([2, 3, 1]);
    });

    testWidgets('unpinned subscriptions are sorted', (tester) async {
      await setupStreamListPage(tester, subscriptions: [
        eg.subscription(eg.stream(streamId: 3, name: 'b'), pinToTop: false),
        eg.subscription(eg.stream(streamId: 1, name: 'c'), pinToTop: false),
        eg.subscription(eg.stream(streamId: 2, name: 'a'), pinToTop: false),
      ]);
      check(listedStreamIds(tester)).deepEquals([2, 3, 1]);
    });

    testWidgets('subscriptions sorting is case insensitive', (tester) async {
      await setupStreamListPage(tester, subscriptions: [
        eg.subscription(eg.stream(streamId: 1, name: 'a'), pinToTop: true),
        eg.subscription(eg.stream(streamId: 2, name: 'B'), pinToTop: true),
        eg.subscription(eg.stream(streamId: 3, name: 'c'), pinToTop: true),
        eg.subscription(eg.stream(streamId: 4, name: 'D'), pinToTop: false),
        eg.subscription(eg.stream(streamId: 5, name: 'e'), pinToTop: false),
        eg.subscription(eg.stream(streamId: 6, name: 'F'), pinToTop: false),
      ]);
      check(listedStreamIds(tester)).deepEquals([1, 2, 3, 4, 5, 6]);
    });

    testWidgets('muted subscriptions come last among pinned streams and among unpinned streams', (tester) async {
      await setupStreamListPage(tester, subscriptions: [
        eg.subscription(eg.stream(streamId: 1, name: 'a'), isMuted: true, pinToTop: true),
        eg.subscription(eg.stream(streamId: 2, name: 'b'), isMuted: false, pinToTop: true),
        eg.subscription(eg.stream(streamId: 3, name: 'c'), isMuted: true, pinToTop: true),
        eg.subscription(eg.stream(streamId: 4, name: 'd'), isMuted: false, pinToTop: false),
        eg.subscription(eg.stream(streamId: 5, name: 'e'), isMuted: true, pinToTop: false),
        eg.subscription(eg.stream(streamId: 6, name: 'f'), isMuted: false, pinToTop: false),
      ]);
      check(listedStreamIds(tester)).deepEquals([2, 1, 3, 4, 6, 5]);
    });
  });

  testWidgets('unread badge shows with unreads', (tester) async {
    final stream = eg.stream();
    final unreadMsgs = eg.unreadMsgs(channels: [
      UnreadChannelSnapshot(streamId: stream.streamId, topic: 'a', unreadMessageIds: [1, 2]),
    ]);
    await setupStreamListPage(tester, subscriptions: [
      eg.subscription(stream),
    ], unreadMsgs: unreadMsgs);
    check(find.byType(UnreadCountBadge).evaluate()).length.equals(1);
    check(find.byType(MutedUnreadBadge).evaluate().length).equals(0);
  });

  testWidgets('unread badge counts unmuted only', (tester) async {
    final stream = eg.stream();
    final unreadMsgs = eg.unreadMsgs(channels: [
      UnreadChannelSnapshot(streamId: stream.streamId, topic: 'a', unreadMessageIds: [1, 2]),
      UnreadChannelSnapshot(streamId: stream.streamId, topic: 'b', unreadMessageIds: [3]),
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
    check(find.byType(MutedUnreadBadge).evaluate().length).equals(0);
  });

  testWidgets('unread badge does not show with no unreads', (tester) async {
    final stream = eg.stream();
    final unreadMsgs = eg.unreadMsgs(channels: []);
    await setupStreamListPage(tester, subscriptions: [
      eg.subscription(stream),
    ], unreadMsgs: unreadMsgs);
    check(find.byType(UnreadCountBadge).evaluate()).length.equals(0);
    check(find.byType(MutedUnreadBadge).evaluate().length).equals(0);
  });

  testWidgets('muted unread badge shows when unreads are visible in channel but not inbox', (tester) async {
    final stream = eg.stream();
    final unreadMsgs = eg.unreadMsgs(channels: [
      UnreadChannelSnapshot(streamId: stream.streamId, topic: 'b', unreadMessageIds: [3]),
    ]);
    await setupStreamListPage(tester,
      subscriptions: [eg.subscription(stream, isMuted: true)],
      userTopics: [eg.userTopicItem(stream, 'b', UserTopicVisibilityPolicy.none)],
      unreadMsgs: unreadMsgs);

    check(find.byType(MutedUnreadBadge).evaluate().length).equals(1);
  });

  testWidgets('muted unread badge does not show when unreads are visible in both channel & inbox', (tester) async {
    final stream = eg.stream();
    final unreadMsgs = eg.unreadMsgs(channels: [
      UnreadChannelSnapshot(streamId: stream.streamId, topic: 'b', unreadMessageIds: [3]),
    ]);
    await setupStreamListPage(tester,
      subscriptions: [eg.subscription(stream, isMuted: false)],
      userTopics: [eg.userTopicItem(stream, 'b', UserTopicVisibilityPolicy.none)],
      unreadMsgs: unreadMsgs);

    check(find.byType(MutedUnreadBadge).evaluate().length).equals(0);
  });

  testWidgets('muted unread badge does not show when unreads are not visible in channel nor inbox', (tester) async {
    final stream = eg.stream();
    final unreadMsgs = eg.unreadMsgs(channels: [
      UnreadChannelSnapshot(streamId: stream.streamId, topic: 'b', unreadMessageIds: [3]),
    ]);
    await setupStreamListPage(tester,
      subscriptions: [eg.subscription(stream, isMuted: true)],
      userTopics: [eg.userTopicItem(stream, 'b', UserTopicVisibilityPolicy.muted)],
      unreadMsgs: unreadMsgs);

    check(find.byType(MutedUnreadBadge).evaluate().length).equals(0);
  });

  testWidgets('color propagates to icon and badge', (tester) async {
    final stream = eg.stream();
    final unreadMsgs = eg.unreadMsgs(channels: [
      UnreadChannelSnapshot(streamId: stream.streamId, topic: 'a', unreadMessageIds: [1, 2]),
    ]);
    final subscription = eg.subscription(stream, color: Colors.red.argbInt);
    final swatch = ChannelColorSwatch.light(subscription.color);
    await setupStreamListPage(tester, subscriptions: [
      subscription,
    ], unreadMsgs: unreadMsgs);
    check(getItemCount()).equals(1);
    check(tester.widget<Icon>(find.byIcon(iconDataForStream(stream))).color)
      .isNotNull().isSameColorAs(swatch.iconOnPlainBackground);
    check(tester.widget<UnreadCountBadge>(find.byType(UnreadCountBadge)).backgroundColor)
      .isNotNull().isSameColorAs(swatch);
  });

  testWidgets('muted streams are displayed as faded', (tester) async {
    void checkOpacityForStreamAndBadge(String streamName, int unreadCount, double opacity) {
      final streamFinder = find.text(streamName);
      final streamOpacity = tester.widget<Opacity>(
        find.ancestor(of: streamFinder, matching: find.byType(Opacity)));
      final badgeFinder = find.text('$unreadCount');
      final badgeOpacity = tester.widget<Opacity>(
        find.ancestor(of: badgeFinder, matching: find.byType(Opacity)));
      check(streamOpacity.opacity).equals(opacity);
      check(badgeOpacity.opacity).equals(opacity);
    }

    final stream1 = eg.stream(name: 'Stream 1');
    final stream2 = eg.stream(name: 'Stream 2');
    await setupStreamListPage(tester,
      subscriptions: [
        eg.subscription(stream1, isMuted: true),
        eg.subscription(stream2, isMuted: false),
      ],
      userTopics: [
        eg.userTopicItem(stream1, 'a', UserTopicVisibilityPolicy.unmuted),
        eg.userTopicItem(stream2, 'b', UserTopicVisibilityPolicy.unmuted),
      ],
      unreadMsgs: eg.unreadMsgs(channels: [
        UnreadChannelSnapshot(streamId: stream1.streamId, topic: 'a', unreadMessageIds: [1, 2]),
        UnreadChannelSnapshot(streamId: stream2.streamId, topic: 'b', unreadMessageIds: [3]),
      ]),
    );

    checkOpacityForStreamAndBadge('Stream 1', 2, 0.55);
    checkOpacityForStreamAndBadge('Stream 2', 1, 1.0);
  });

  testWidgets('stream name of unmuted streams with unmuted unreads is bold', (tester) async {
    void checkStreamNameWght(String streamName, double? expectedWght) {
      final streamFinder = find.text(streamName);
      final wght = wghtFromTextStyle(tester.widget<Text>(streamFinder).style!);
      check(wght).equals(expectedWght);
    }

    final unmutedStreamWithUnmutedUnreads =   eg.stream();
    final unmutedStreamWithNoUnmutedUnreads = eg.stream();
    final mutedStreamWithUnmutedUnreads =     eg.stream();
    final mutedStreamWithNoUnmutedUnreads =   eg.stream();

    await setupStreamListPage(tester,
      subscriptions: [
        eg.subscription(unmutedStreamWithUnmutedUnreads,   isMuted: false),
        eg.subscription(unmutedStreamWithNoUnmutedUnreads, isMuted: false),
        eg.subscription(mutedStreamWithUnmutedUnreads,     isMuted: true),
        eg.subscription(mutedStreamWithNoUnmutedUnreads,   isMuted: true),
      ],
      userTopics: [
        eg.userTopicItem(unmutedStreamWithUnmutedUnreads,   'a', UserTopicVisibilityPolicy.unmuted),
        eg.userTopicItem(unmutedStreamWithNoUnmutedUnreads, 'b', UserTopicVisibilityPolicy.muted),
        eg.userTopicItem(mutedStreamWithUnmutedUnreads,     'c', UserTopicVisibilityPolicy.unmuted),
        eg.userTopicItem(mutedStreamWithNoUnmutedUnreads,   'd', UserTopicVisibilityPolicy.muted),
      ],
      unreadMsgs: eg.unreadMsgs(channels: [
        UnreadChannelSnapshot(streamId: unmutedStreamWithUnmutedUnreads.streamId,   topic: 'a', unreadMessageIds: [1]),
        UnreadChannelSnapshot(streamId: unmutedStreamWithNoUnmutedUnreads.streamId, topic: 'b', unreadMessageIds: [2]),
        UnreadChannelSnapshot(streamId: mutedStreamWithUnmutedUnreads.streamId,     topic: 'c', unreadMessageIds: [3]),
        UnreadChannelSnapshot(streamId: mutedStreamWithNoUnmutedUnreads.streamId,   topic: 'd', unreadMessageIds: [4]),
      ]),
    );

    checkStreamNameWght(unmutedStreamWithUnmutedUnreads.name,   600);
    checkStreamNameWght(unmutedStreamWithNoUnmutedUnreads.name, 400);
    checkStreamNameWght(mutedStreamWithUnmutedUnreads.name,     400);
    checkStreamNameWght(mutedStreamWithNoUnmutedUnreads.name,   400);
  });
}
