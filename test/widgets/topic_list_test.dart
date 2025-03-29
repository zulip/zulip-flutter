import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/topic_list.dart';

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
    final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    final connection = store.connection as FakeApiConnection;
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

      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      await store.addUser(eg.selfUser);

      final connection = store.connection as FakeApiConnection;
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

      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      await store.addUser(eg.selfUser);

      final connection = store.connection as FakeApiConnection;
      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true,
        messages: [message],
      ).toJson());

      await tester.pumpAndSettle();
      pushedRoutes.clear();

      await tester.tap(find.byIcon(ZulipIcons.message_feed));
      await tester.pumpAndSettle();

      check(pushedRoutes).single
        .isA<MaterialAccountWidgetRoute>()
        .page.isA<MessageListPage>()
        .initNarrow.equals(ChannelNarrow(stream.streamId));
    });
  });
}
