import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_checks/legacy_checks.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/widgets/color.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/channel_colors.dart';
import 'package:zulip/widgets/subscription_list.dart';
import 'package:zulip/widgets/text.dart';
import 'package:zulip/widgets/counter_badge.dart';

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
      child: const HomePage()));

    // global store, per-account store
    await tester.pumpAndSettle();

    // Switch to channels tab.
    await tester.tap(find.byIcon(ZulipIcons.hash_italic));
    await tester.pump();
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

  testWidgets('empty', (tester) async {
    await setupStreamListPage(tester, subscriptions: []);
    check(getItemCount()).equals(0);
    check(isPinnedHeaderInTree()).isFalse();
    check(isUnpinnedHeaderInTree()).isFalse();
    check(find.text('You’re not subscribed to any channels yet.')).findsOne();
    check(find.text('Try going to All channels and joining some of them.')).findsOne();
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

    testWidgets('channels with names starting with an emoji are above channel names that do not start with an emoji', (tester) async {
      await setupStreamListPage(tester, subscriptions: [
        eg.subscription(eg.stream(streamId: 1, name: 'Happy 😊 Stream')),
        eg.subscription(eg.stream(streamId: 2, name: 'Alpha Stream')),
        eg.subscription(eg.stream(streamId: 3, name: '🚀 Rocket Stream')),
      ]);
      check(listedStreamIds(tester)).deepEquals([3, 2, 1]);
    });

    testWidgets('channels with names starting with an emoji, pinned, unpinned, muted, and unmuted are sorted correctly', (tester) async {
      await setupStreamListPage(tester, subscriptions: [
        eg.subscription(eg.stream(streamId: 1, name: '😊 Happy Stream'), pinToTop: true, isMuted: false),
        eg.subscription(eg.stream(streamId: 2, name: '🚀 Rocket Stream'), pinToTop: true, isMuted: true),
        eg.subscription(eg.stream(streamId: 3, name: 'Alpha Stream'), pinToTop: true, isMuted: false),
        eg.subscription(eg.stream(streamId: 4, name: 'Beta Stream'), pinToTop: true, isMuted: true),
        eg.subscription(eg.stream(streamId: 5, name: '🌟 Star Stream'), pinToTop: false, isMuted: false),
        eg.subscription(eg.stream(streamId: 6, name: '🔥 Fire Stream'), pinToTop: false, isMuted: true),
        eg.subscription(eg.stream(streamId: 7, name: 'Gamma Stream'), pinToTop: false, isMuted: false),
        eg.subscription(eg.stream(streamId: 8, name: 'Delta Stream'), pinToTop: false, isMuted: true),
      ]);
      check(listedStreamIds(tester)).deepEquals([1, 3, 2, 4, 5, 7, 6, 8]);
    });
  });

  testWidgets('unread badge shows with unreads', (tester) async {
    final stream = eg.stream();
    final unreadMsgs = eg.unreadMsgs(channels: [
      eg.unreadChannelMsgs(streamId: stream.streamId, topic: 'a', unreadMessageIds: [1, 2]),
    ]);
    await setupStreamListPage(tester, subscriptions: [
      eg.subscription(stream),
    ], unreadMsgs: unreadMsgs);
    check(find.byType(CounterBadge).evaluate()).length.equals(1);
    check(find.byType(MutedUnreadBadge).evaluate().length).equals(0);
  });

  testWidgets('unread badge counts unmuted only', (tester) async {
    final stream = eg.stream();
    final unreadMsgs = eg.unreadMsgs(channels: [
      eg.unreadChannelMsgs(streamId: stream.streamId, topic: 'a', unreadMessageIds: [1, 2]),
      eg.unreadChannelMsgs(streamId: stream.streamId, topic: 'b', unreadMessageIds: [3]),
    ]);
    await setupStreamListPage(tester,
      subscriptions: [eg.subscription(stream, isMuted: true)],
        userTopics: [UserTopicItem(
          streamId: stream.streamId,
          topicName: eg.t('b'),
          lastUpdated: 1234567890,
          visibilityPolicy: UserTopicVisibilityPolicy.unmuted,
        )],
        unreadMsgs: unreadMsgs);
    check(tester.widget<Text>(find.descendant(
        of: find.byType(CounterBadge), matching: find.byType(Text))))
      .data.equals('1');
    check(find.byType(MutedUnreadBadge).evaluate().length).equals(0);
  });

  testWidgets('unread badge does not show with no unreads', (tester) async {
    final stream = eg.stream();
    final unreadMsgs = eg.unreadMsgs(channels: []);
    await setupStreamListPage(tester, subscriptions: [
      eg.subscription(stream),
    ], unreadMsgs: unreadMsgs);
    check(find.byType(CounterBadge).evaluate()).length.equals(0);
    check(find.byType(MutedUnreadBadge).evaluate().length).equals(0);
  });

  testWidgets('muted unread badge shows when unreads are visible in channel but not inbox', (tester) async {
    final stream = eg.stream();
    final unreadMsgs = eg.unreadMsgs(channels: [
      eg.unreadChannelMsgs(streamId: stream.streamId, topic: 'b', unreadMessageIds: [3]),
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
      eg.unreadChannelMsgs(streamId: stream.streamId, topic: 'b', unreadMessageIds: [3]),
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
      eg.unreadChannelMsgs(streamId: stream.streamId, topic: 'b', unreadMessageIds: [3]),
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
      eg.unreadChannelMsgs(streamId: stream.streamId, topic: 'a', unreadMessageIds: [1, 2]),
    ]);
    final subscription = eg.subscription(stream, color: Colors.red.argbInt);
    final swatch = ChannelColorSwatch.light(subscription.color);
    await setupStreamListPage(tester, subscriptions: [
      subscription,
    ], unreadMsgs: unreadMsgs);
    check(getItemCount()).equals(1);
    check(tester.widget<Icon>(find.byIcon(iconDataForStream(stream))).color)
      .isNotNull().isSameColorAs(swatch.iconOnPlainBackground);

    final unreadCountBadgeRenderBox = tester.renderObject<RenderBox>(find.byType(CounterBadge));
    check(unreadCountBadgeRenderBox).legacyMatcher(
      // `paints` isn't a [Matcher] so we wrap it with `equals`;
      // awkward but it works
      equals(paints..rrect(color: swatch.unreadCountBadgeBackground)));
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
        eg.unreadChannelMsgs(streamId: stream1.streamId, topic: 'a', unreadMessageIds: [1, 2]),
        eg.unreadChannelMsgs(streamId: stream2.streamId, topic: 'b', unreadMessageIds: [3]),
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
        eg.unreadChannelMsgs(streamId: unmutedStreamWithUnmutedUnreads.streamId,   topic: 'a', unreadMessageIds: [1]),
        eg.unreadChannelMsgs(streamId: unmutedStreamWithNoUnmutedUnreads.streamId, topic: 'b', unreadMessageIds: [2]),
        eg.unreadChannelMsgs(streamId: mutedStreamWithUnmutedUnreads.streamId,     topic: 'c', unreadMessageIds: [3]),
        eg.unreadChannelMsgs(streamId: mutedStreamWithNoUnmutedUnreads.streamId,   topic: 'd', unreadMessageIds: [4]),
      ]),
    );

    checkStreamNameWght(unmutedStreamWithUnmutedUnreads.name,   600);
    checkStreamNameWght(unmutedStreamWithNoUnmutedUnreads.name, 400);
    checkStreamNameWght(mutedStreamWithUnmutedUnreads.name,     400);
    checkStreamNameWght(mutedStreamWithNoUnmutedUnreads.name,   400);
  });

  group('filter channels', () {
    testWidgets('search box is rendered', (tester) async {
      await setupStreamListPage(tester, subscriptions: [
        eg.subscription(eg.stream(name: 'general')),
      ]);
      check(find.byType(TextField)).findsOne();
      check(find.text('Filter channels')).findsOne();
    });

    testWidgets('filters channels by name', (tester) async {
      await setupStreamListPage(tester, subscriptions: [
        eg.subscription(eg.stream(streamId: 1, name: 'general')),
        eg.subscription(eg.stream(streamId: 2, name: 'engineering')),
        eg.subscription(eg.stream(streamId: 3, name: 'design')),
      ]);
      check(getItemCount()).equals(3);

      // Type search query
      await tester.enterText(find.byType(TextField), 'eng');
      await tester.pump();

      // Only engineering should be visible
      check(getItemCount()).equals(1);
      check(find.text('engineering')).findsOne();
      check(find.text('general')).findsNothing();
      check(find.text('design')).findsNothing();
    });

    testWidgets('filter is case-insensitive', (tester) async {
      await setupStreamListPage(tester, subscriptions: [
        eg.subscription(eg.stream(streamId: 1, name: 'General')),
        eg.subscription(eg.stream(streamId: 2, name: 'ENGINEERING')),
        eg.subscription(eg.stream(streamId: 3, name: 'DeSiGn')),
      ]);

      await tester.enterText(find.byType(TextField), 'GENERAL');
      await tester.pump();
      check(getItemCount()).equals(1);
      check(find.text('General')).findsOne();

      await tester.enterText(find.byType(TextField), 'engineering');
      await tester.pump();
      check(getItemCount()).equals(1);
      check(find.text('ENGINEERING')).findsOne();

      await tester.enterText(find.byType(TextField), 'design');
      await tester.pump();
      check(getItemCount()).equals(1);
      check(find.text('DeSiGn')).findsOne();
    });

    testWidgets('filters both pinned and unpinned channels', (tester) async {
      await setupStreamListPage(tester, subscriptions: [
        eg.subscription(eg.stream(streamId: 1, name: 'announcements'), pinToTop: true),
        eg.subscription(eg.stream(streamId: 2, name: 'general'), pinToTop: false),
        eg.subscription(eg.stream(streamId: 3, name: 'engineering'), pinToTop: true),
        eg.subscription(eg.stream(streamId: 4, name: 'design'), pinToTop: false),
      ]);
      check(getItemCount()).equals(4);

      await tester.enterText(find.byType(TextField), 'eng');
      await tester.pump();

      // Only engineering should be visible (it's pinned)
      check(getItemCount()).equals(1);
      check(find.text('engineering')).findsOne();
      check(isPinnedHeaderInTree()).isTrue();
    });

    testWidgets('shows no results when filter matches nothing', (tester) async {
      await setupStreamListPage(tester, subscriptions: [
        eg.subscription(eg.stream(streamId: 1, name: 'general')),
        eg.subscription(eg.stream(streamId: 2, name: 'engineering')),
      ]);
      check(getItemCount()).equals(2);

      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pump();

      check(getItemCount()).equals(0);
      check(isPinnedHeaderInTree()).isFalse();
      check(isUnpinnedHeaderInTree()).isFalse();
      // Should NOT show the "You're not subscribed" placeholder
      check(find.text("You're not subscribed to any channels yet.")).findsNothing();
    });

    testWidgets('clearing search shows all channels', (tester) async {
      await setupStreamListPage(tester, subscriptions: [
        eg.subscription(eg.stream(streamId: 1, name: 'general')),
        eg.subscription(eg.stream(streamId: 2, name: 'engineering')),
        eg.subscription(eg.stream(streamId: 3, name: 'design')),
      ]);

      // Filter channels
      await tester.enterText(find.byType(TextField), 'eng');
      await tester.pump();
      check(getItemCount()).equals(1);

      // Clear the filter
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      check(getItemCount()).equals(3);
    });

    testWidgets('partial match filters correctly', (tester) async {
      await setupStreamListPage(tester, subscriptions: [
        eg.subscription(eg.stream(streamId: 1, name: 'general')),
        eg.subscription(eg.stream(streamId: 2, name: 'engineering')),
        eg.subscription(eg.stream(streamId: 3, name: 'general-announcements')),
        eg.subscription(eg.stream(streamId: 4, name: 'design')),
      ]);

      await tester.enterText(find.byType(TextField), 'general');
      await tester.pump();

      // Both 'general' and 'general-announcements' should match
      check(getItemCount()).equals(2);
      final items = tester.widgetList<SubscriptionItem>(find.byType(SubscriptionItem));
      check(items.map((e) => e.subscription.name).toSet())
        .deepEquals({'general', 'general-announcements'});
    });

    testWidgets('filter works with special characters in channel names', (tester) async {
      await setupStreamListPage(tester, subscriptions: [
        eg.subscription(eg.stream(streamId: 1, name: 'test-channel')),
        eg.subscription(eg.stream(streamId: 2, name: 'test_channel_2')),
        eg.subscription(eg.stream(streamId: 3, name: 'test.channel.3')),
      ]);

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();
      check(getItemCount()).equals(3);

      await tester.enterText(find.byType(TextField), '-');
      await tester.pump();
      check(getItemCount()).equals(1);
      check(find.text('test-channel')).findsOne();

      await tester.enterText(find.byType(TextField), '_');
      await tester.pump();
      check(getItemCount()).equals(1);
      check(find.text('test_channel_2')).findsOne();
    });
  });
}
