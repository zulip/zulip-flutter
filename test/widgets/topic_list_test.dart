import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/topic_list.dart';
import 'package:zulip/widgets/unread_count_badge.dart';

import '../api/fake_api.dart';
import '../model/binding.dart';
import '../example_data.dart' as eg;
import '../model/test_store.dart';
import '../test_navigation.dart';
import 'message_list_checks.dart';
import 'page_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;

  Future<void> setupTopicListPage(WidgetTester tester, {
    required List<GetStreamTopicsEntry> topics,
    ZulipStream? stream,
    Subscription? subscription,
    UnreadMessagesSnapshot? unreadMsgs,
    List<NavigatorObserver> navObservers = const [],
  }) async {
    addTearDown(testBinding.reset);
    final effectiveStream = stream ?? eg.stream();
    final initialSnapshot = eg.initialSnapshot(
      streams: [effectiveStream],
      subscriptions: subscription != null ? [subscription] : null,
      unreadMsgs: unreadMsgs,
    );
    await testBinding.globalStore.add(eg.selfAccount, initialSnapshot);
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    await store.addUser(eg.selfUser);
    connection = store.connection as FakeApiConnection;
    connection.prepare(json: GetStreamTopicsResult(topics: topics).toJson());

    await tester.pumpWidget(TestZulipApp(
      accountId: eg.selfAccount.id,
      navigatorObservers: navObservers,
      child: TopicListPage(streamId: effectiveStream.streamId)));
  }

  group('TopicListPage', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await setupTopicListPage(tester, topics: []);
      check(find.byType(CircularProgressIndicator)).findsOne();
    });

    testWidgets('shows empty state when no topics', (tester) async {
      await setupTopicListPage(tester, topics: []);
      await tester.pumpAndSettle();
      check(find.text('No topics in the channel')).findsOne();
    });

    testWidgets('shows topics sorted by maxId', (tester) async {
      final topics = [
        eg.getStreamTopicsEntry(maxId: 1, name: 'Topic A'),
        eg.getStreamTopicsEntry(maxId: 3, name: 'Topic B'),
        eg.getStreamTopicsEntry(maxId: 2, name: 'Topic C'),
      ];
      await setupTopicListPage(tester, topics: topics);
      await tester.pumpAndSettle();

      final topicWidgets = tester.widgetList<Text>(find.byType(Text))
        .where((widget) => ['Topic A', 'Topic B', 'Topic C']
          .contains(widget.data)).toList();

      check(topicWidgets.map((w) => w.data))
        .deepEquals(['Topic B', 'Topic C', 'Topic A']);
    });

    testWidgets('navigates to message list on topic tap', (tester) async {
      final pushedRoutes = <Route<void>>[];
      final navObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      final stream = eg.stream();
      final topic = eg.getStreamTopicsEntry(name: 'test topic');
      final message = eg.streamMessage(stream: stream, topic: 'test topic');

      await setupTopicListPage(tester,
        stream: stream,
        topics: [topic],
        subscription: eg.subscription(stream),
        navObservers: [navObserver]);

      connection.prepare(json:
        eg.newestGetMessagesResult(foundOldest: true, messages: [message]).toJson());

      await tester.pumpAndSettle();
      pushedRoutes.clear();

      await tester.tap(find.text('test topic'));
      await tester.pumpAndSettle();

      check(pushedRoutes).single
        .isA<MaterialAccountWidgetRoute>()
        .page.isA<MessageListPage>()
        .initNarrow.equals(TopicNarrow(stream.streamId, topic.name));
    });

    testWidgets('shows unread count badge', (tester) async {
      final stream = eg.stream();
      final topic = eg.getStreamTopicsEntry(name: 'test topic');

      await setupTopicListPage(tester,
        stream: stream,
        topics: [topic],
        unreadMsgs: eg.unreadMsgs(channels: [
          eg.unreadChannelMsgs(
            streamId: stream.streamId,
            topic: 'test topic',
            unreadMessageIds: [1, 2, 3]),
        ]));
      await tester.pumpAndSettle();

      check(find.text('3')).findsOne();
    });

    testWidgets('shows channel name in app bar', (tester) async {
      final stream = eg.stream(name: 'Test Stream');
      await setupTopicListPage(tester,
        stream: stream,
        topics: [],
        subscription: eg.subscription(stream));
      await tester.pumpAndSettle();

      check(find.text('Test Stream')).findsOne();
    });

    testWidgets('shows channel feed button in app bar', (tester) async {
      final stream = eg.stream();

      await setupTopicListPage(tester,
        stream: stream,
        topics: [],
        subscription: eg.subscription(stream));
      await tester.pumpAndSettle();

      check(find.byIcon(ZulipIcons.message_feed)).findsOne();
    });

    testWidgets('navigates to channel narrow on channel feed button tap', (tester) async {
      final pushedRoutes = <Route<void>>[];
      final navObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      final stream = eg.stream();
      final message = eg.streamMessage(stream: stream);

      await setupTopicListPage(tester,
        stream: stream,
        topics: [],
        subscription: eg.subscription(stream),
        navObservers: [navObserver]);

      connection.prepare(json:
        eg.newestGetMessagesResult(foundOldest: true, messages: [message]).toJson());

      await tester.pumpAndSettle();
      pushedRoutes.clear();

      await tester.tap(find.byIcon(ZulipIcons.message_feed));
      await tester.pumpAndSettle();

      check(pushedRoutes).single
        .isA<MaterialAccountWidgetRoute>()
        .page.isA<MessageListPage>()
        .initNarrow.equals(ChannelNarrow(stream.streamId));
    });

    Finder findIconInRow(WidgetTester tester, {
      required String label,
      required IconData icon,
    }) {
      return find.descendant(
        of: find.descendant(
          of: find.byType(TopicListItem),
          matching: find.widgetWithText(Row, label),
        ),
        matching: find.byIcon(icon),
      );
    }

    group('mentions', () {
      final stream = eg.stream();
      final topic = eg.getStreamTopicsEntry(name: 'test topic');

      testWidgets('topic with a mention', (tester) async {
        final message = eg.streamMessage(
          stream: stream,
          topic: 'test topic',
          flags: [MessageFlag.mentioned]);
        await setupTopicListPage(tester,
          stream: stream,
          topics: [topic],
          subscription: eg.subscription(stream),
          unreadMsgs: eg.unreadMsgs(
            mentions: [message.id],
            channels: [eg.unreadChannelMsgs(
                streamId: stream.streamId,
                topic: 'test topic',
                unreadMessageIds: [message.id]),
            ]));
        await tester.pumpAndSettle();

        check(findIconInRow(tester,
          label: topic.name.unresolve().displayName,
          icon: ZulipIcons.at_sign)).findsOne();
      });

      testWidgets('topic without a mention', (tester) async {
        await setupTopicListPage(tester,
          stream: stream,
          topics: [topic],
          subscription: eg.subscription(stream),
          unreadMsgs: eg.unreadMsgs(channels: [
            eg.unreadChannelMsgs(
              streamId: stream.streamId,
              topic: 'test topic',
              unreadMessageIds: [1]),
          ]));
        await tester.pumpAndSettle();

        check(findIconInRow(tester,
          label: topic.name.unresolve().displayName,
          icon: ZulipIcons.at_sign)).findsNothing();
      });

      testWidgets('topic with a mention that is already read', (tester) async {
        await setupTopicListPage(tester,
          stream: stream,
          topics: [topic],
          subscription: eg.subscription(stream),
          unreadMsgs: eg.unreadMsgs(
            mentions: [eg.streamMessage(
              stream: stream,
              topic: 'test topic',
              flags: [MessageFlag.mentioned]).id],
            channels: [eg.unreadChannelMsgs(
              streamId: stream.streamId,
              topic: 'test topic',
              unreadMessageIds: []),
            ]));
        await tester.pumpAndSettle();

        check(find.byType(UnreadCountBadge)).findsNothing();
        check(findIconInRow(tester,
          label: topic.name.unresolve().displayName,
          icon: ZulipIcons.at_sign)).findsNothing();
      });
    });

    group('topic visibility', () {
      final stream = eg.stream();
      final topic = eg.getStreamTopicsEntry(name: 'test topic');

      testWidgets('followed', (tester) async {
        await setupTopicListPage(tester,
          stream: stream,
          topics: [topic],
          subscription: eg.subscription(stream),
          unreadMsgs: eg.unreadMsgs(channels: [
            eg.unreadChannelMsgs(
              streamId: stream.streamId,
              topic: 'test topic',
              unreadMessageIds: [1]),
          ]));
        await tester.pumpAndSettle();

        final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
        await store.addUserTopic(stream, 'test topic', UserTopicVisibilityPolicy.followed);
        await tester.pump();

        check(findIconInRow(tester,
          label: topic.name.unresolve().displayName,
          icon: ZulipIcons.follow)).findsOne();
      });

      testWidgets('followed and mentioned', (tester) async {
        final message = eg.streamMessage(
          stream: stream,
          topic: 'test topic',
          flags: [MessageFlag.mentioned]);
        await setupTopicListPage(tester,
          stream: stream,
          topics: [topic],
          subscription: eg.subscription(stream),
          unreadMsgs: eg.unreadMsgs(
            mentions: [message.id],
            channels: [eg.unreadChannelMsgs(
                streamId: stream.streamId,
                topic: 'test topic',
                unreadMessageIds: [message.id]),
            ]));
        await tester.pumpAndSettle();

        final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
        await store.addUserTopic(stream, 'test topic', UserTopicVisibilityPolicy.followed);
        await tester.pump();

        check(findIconInRow(tester,
          label: topic.name.unresolve().displayName,
          icon: ZulipIcons.follow)).findsOne();
        check(findIconInRow(tester,
          label: topic.name.unresolve().displayName,
          icon: ZulipIcons.at_sign)).findsOne();
      });

      testWidgets('unmuted', (tester) async {
        await setupTopicListPage(tester,
          stream: stream,
          topics: [topic],
          subscription: eg.subscription(stream, isMuted: true),
          unreadMsgs: eg.unreadMsgs(channels: [
            eg.unreadChannelMsgs(
              streamId: stream.streamId,
              topic: 'test topic',
              unreadMessageIds: [1]),
          ]));
        await tester.pumpAndSettle();

        final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
        await store.addUserTopic(stream, 'test topic', UserTopicVisibilityPolicy.unmuted);
        await tester.pump();

        check(findIconInRow(tester,
          label: topic.name.unresolve().displayName,
          icon: ZulipIcons.unmute)).findsOne();
      });
    });

    group('unread badge', () {
      final stream = eg.stream();
      final topic = eg.getStreamTopicsEntry(name: 'test topic');

      testWidgets('shows unread count badge with correct count', (tester) async {
        await setupTopicListPage(tester,
          stream: stream,
          topics: [topic],
          unreadMsgs: eg.unreadMsgs(channels: [
            eg.unreadChannelMsgs(
              streamId: stream.streamId,
              topic: 'test topic',
              unreadMessageIds: [1, 2, 3, 4, 5]),
          ]));
        await tester.pumpAndSettle();

        check(find.text('5')).findsOne();
      });

      testWidgets('does not show unread badge when no unreads', (tester) async {
        await setupTopicListPage(tester,
          stream: stream,
          topics: [topic]);
        await tester.pumpAndSettle();

        check(find.byType(UnreadCountBadge)).findsNothing();
      });
    });
  });
}

extension TopicListPageChecks on Subject<TopicListPage> {
  Subject<int> get streamId => has((page) => page.streamId, 'streamId');
}
