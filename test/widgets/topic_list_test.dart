import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/app_bar.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/topic_list.dart';

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

  Future<void> prepare(WidgetTester tester, {
    ZulipStream? channel,
    List<GetChannelTopicsEntry>? topics,
    List<UserTopicItem> userTopics = const [],
    List<StreamMessage>? messages,
  }) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    connection = store.connection as FakeApiConnection;

    await store.addUser(eg.selfUser);
    channel ??= eg.stream();
    await store.addStream(channel);
    await store.addSubscription(eg.subscription(channel));
    for (final userTopic in userTopics) {
      await store.setUserTopic(
        channel, userTopic.topicName.apiName, userTopic.visibilityPolicy);
    }
    topics ??= [eg.getStreamTopicsEntry()];
    messages ??= [eg.streamMessage(stream: channel, topic: topics.first.name.apiName)];
    await store.addMessages(messages);

    connection.prepare(json: GetStreamTopicsResult(topics: topics).toJson());
    await tester.pumpWidget(TestZulipApp(
      accountId: eg.selfAccount.id,
      child: TopicListPage(streamId: channel.streamId)));
    await tester.pump();
    await tester.pump(Duration.zero);
    check(connection.takeRequests()).single.isA<http.Request>()
      ..method.equals('GET')
      ..url.path.equals('/api/v1/users/me/${channel.streamId}/topics')
      ..url.queryParameters.deepEquals({'allow_empty_topic_name': 'true'});
  }

  group('app bar', () {
    testWidgets('unknown channel name', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final channel = eg.stream();

      (store.connection as FakeApiConnection).prepare(
        json: GetStreamTopicsResult(topics: []).toJson());
      await tester.pumpWidget(TestZulipApp(
        accountId: eg.selfAccount.id,
        child: TopicListPage(streamId: channel.streamId)));
      await tester.pump();
      await tester.pump(Duration.zero);
      check(find.widgetWithText(ZulipAppBar, '(unknown channel)')).findsOne();
    });

    testWidgets('navigate to channel feed', (tester) async {
      final channel = eg.stream(name: 'channel foo');
      await prepare(tester, channel: channel);

      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true, messages: [eg.streamMessage(stream: channel)]).toJson());
      await tester.tap(find.byIcon(ZulipIcons.message_feed));
      await tester.pump();
      await tester.pump(Duration.zero);
      check(find.descendant(
        of: find.byType(MessageListPage),
        matching: find.text('channel foo')),
      ).findsOne();
    });

    testWidgets('show channel action sheet', (tester) async {
      final channel = eg.stream(name: 'channel foo');
      await prepare(tester, channel: channel,
        messages: [eg.streamMessage(stream: channel)]);

      await tester.longPress(find.text('channel foo'));
      await tester.pump(Duration(milliseconds: 100)); // bottom-sheet animation
      check(find.text('Mark channel as read')).findsOne();
    });
  });

  testWidgets('show loading indicator', (tester) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    final channel = eg.stream();

    (store.connection as FakeApiConnection).prepare(
      json: GetStreamTopicsResult(topics: []).toJson(),
      delay: Duration(seconds: 1),
    );
    await tester.pumpWidget(TestZulipApp(
      accountId: eg.selfAccount.id,
      child: TopicListPage(streamId: channel.streamId)));
    await tester.pump();
    check(find.byType(CircularProgressIndicator)).findsOne();

    await tester.pump(Duration(seconds: 1));
    check(find.byType(CircularProgressIndicator)).findsNothing();
  });

  testWidgets('fetch again when navigating away and back', (tester) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    final connection = store.connection as FakeApiConnection;
    final channel = eg.stream();

    // Start from a message list page in a channel narrow.
    connection.prepare(json: eg.newestGetMessagesResult(
      foundOldest: true, messages: []).toJson());
    await tester.pumpWidget(TestZulipApp(
      accountId: eg.selfAccount.id,
      child: MessageListPage(initNarrow: ChannelNarrow(channel.streamId))));
    await tester.pump();

    // Tap "TOPICS" button navigating to the topic-list page…
    connection.prepare(json: GetStreamTopicsResult(
      topics: [eg.getStreamTopicsEntry(name: 'topic A')]).toJson());
    await tester.tap(find.byIcon(ZulipIcons.topics));
    await tester.pump();
    await tester.pump(Duration.zero);
    check(find.text('topic A')).findsOne();

    // … go back to the message list page…
    await tester.pageBack();
    await tester.pump();

    // … then back to the topic-list page, expecting to fetch again.
    connection.prepare(json: GetStreamTopicsResult(
      topics: [eg.getStreamTopicsEntry(name: 'topic B')]).toJson());
    await tester.tap(find.byIcon(ZulipIcons.topics));
    await tester.pump();
    await tester.pump(Duration.zero);
    check(find.text('topic A')).findsNothing();
    check(find.text('topic B')).findsOne();
  });

  Finder topicItemFinder = find.descendant(
    of: find.byType(ListView),
    matching: find.byType(Material));

  Finder findInTopicItemAt(int index, Finder finder) => find.descendant(
    of: topicItemFinder.at(index),
    matching: finder);

  testWidgets('show topic action sheet', (tester) async {
    final channel = eg.stream();
    await prepare(tester, channel: channel,
      topics: [eg.getStreamTopicsEntry(name: 'topic foo')]);
    await tester.longPress(topicItemFinder);
    await tester.pump(Duration(milliseconds: 150)); // bottom-sheet animation

    connection.prepare(json: {});
    await tester.tap(find.text('Mute topic'));
    await tester.pump();
    await tester.pump(Duration.zero);
    check(connection.takeRequests()).single.isA<http.Request>()
      ..method.equals('POST')
      ..url.path.equals('/api/v1/user_topics')
      ..bodyFields.deepEquals({
        'stream_id': channel.streamId.toString(),
        'topic': 'topic foo',
        'visibility_policy': UserTopicVisibilityPolicy.muted.apiValue.toString(),
      });
  });

  testWidgets('sort topics by maxId', (tester) async {
    await prepare(tester, topics: [
      eg.getStreamTopicsEntry(name: 'A', maxId: 3),
      eg.getStreamTopicsEntry(name: 'B', maxId: 2),
      eg.getStreamTopicsEntry(name: 'C', maxId: 4),
    ]);

    check(findInTopicItemAt(0, find.text('C'))).findsOne();
    check(findInTopicItemAt(1, find.text('A'))).findsOne();
    check(findInTopicItemAt(2, find.text('B'))).findsOne();
  });

  testWidgets('resolved and unresolved topics', (tester) async {
    final resolvedTopic = TopicName('resolved').resolve();
    final unresolvedTopic = TopicName('unresolved');
    await prepare(tester, topics: [
      eg.getStreamTopicsEntry(maxId: 2, name: resolvedTopic.apiName),
      eg.getStreamTopicsEntry(maxId: 1, name: unresolvedTopic.apiName),
    ]);

    assert(resolvedTopic.displayName == '✔ resolved', resolvedTopic.displayName);
    check(findInTopicItemAt(0, find.text('✔ resolved'))).findsNothing();

    check(findInTopicItemAt(0, find.text('resolved'))).findsOne();
    check(findInTopicItemAt(0, find.byIcon(ZulipIcons.check).hitTestable()))
      .findsOne();

    check(findInTopicItemAt(1, find.text('unresolved'))).findsOne();
    check(findInTopicItemAt(1, find.byType(Icon)).hitTestable())
      .findsNothing();
  });

  testWidgets('handle empty topics', (tester) async {
    await prepare(tester, topics: [
      eg.getStreamTopicsEntry(name: ''),
    ]);
    check(findInTopicItemAt(0,
      find.text(eg.defaultRealmEmptyTopicDisplayName))).findsOne();
  });

  group('unreads', () {
    testWidgets('muted and non-muted topics', (tester) async {
      final channel = eg.stream();
      await prepare(tester, channel: channel,
        topics: [
          eg.getStreamTopicsEntry(maxId: 2, name: 'muted'),
          eg.getStreamTopicsEntry(maxId: 1, name: 'non-muted'),
        ],
        userTopics: [
          eg.userTopicItem(channel, 'muted', UserTopicVisibilityPolicy.muted),
        ],
        messages: [
          eg.streamMessage(stream: channel, topic: 'muted'),
          eg.streamMessage(stream: channel, topic: 'non-muted'),
          eg.streamMessage(stream: channel, topic: 'non-muted'),
        ]);

      check(findInTopicItemAt(0, find.text('1'))).findsOne();
      check(findInTopicItemAt(0, find.text('muted'))).findsOne();
      check(findInTopicItemAt(0, find.byIcon(ZulipIcons.mute).hitTestable()))
        .findsOne();

      check(findInTopicItemAt(1, find.text('2'))).findsOne();
      check(findInTopicItemAt(1, find.text('non-muted'))).findsOne();
      check(findInTopicItemAt(1, find.byType(Icon).hitTestable()))
        .findsNothing();
    });

    testWidgets('with and without unread mentions', (tester) async {
      final channel = eg.stream();
      await prepare(tester, channel: channel,
        topics: [
          eg.getStreamTopicsEntry(maxId: 2, name: 'not mentioned'),
          eg.getStreamTopicsEntry(maxId: 1, name: 'mentioned'),
        ],
        messages: [
          eg.streamMessage(stream: channel, topic: 'not mentioned'),
          eg.streamMessage(stream: channel, topic: 'not mentioned'),
          eg.streamMessage(stream: channel, topic: 'not mentioned',
            flags: [MessageFlag.mentioned, MessageFlag.read]),
          eg.streamMessage(stream: channel, topic: 'mentioned',
            flags: [MessageFlag.mentioned]),
        ]);

      check(findInTopicItemAt(0, find.text('2'))).findsOne();
      check(findInTopicItemAt(0, find.text('not mentioned'))).findsOne();
      check(findInTopicItemAt(0, find.byType(Icons))).findsNothing();

      check(findInTopicItemAt(1, find.text('1'))).findsOne();
      check(findInTopicItemAt(1, find.text('mentioned'))).findsOne();
      check(findInTopicItemAt(1, find.byIcon(ZulipIcons.at_sign))).findsOne();
    });
  });

  group('topic visibility', () {
    testWidgets('default', (tester) async {
      final channel = eg.stream();
      await prepare(tester, channel: channel,
        topics: [eg.getStreamTopicsEntry(name: 'topic')]);

      check(find.descendant(of: topicItemFinder,
        matching: find.byType(Icons))).findsNothing();
    });

    testWidgets('muted', (tester) async {
      final channel = eg.stream();
      await prepare(tester, channel: channel,
        topics: [eg.getStreamTopicsEntry(name: 'topic')],
        userTopics: [
          eg.userTopicItem(channel, 'topic', UserTopicVisibilityPolicy.muted),
        ]);
      check(find.descendant(of: topicItemFinder,
        matching: find.byIcon(ZulipIcons.mute))).findsOne();
    });

    testWidgets('unmuted', (tester) async {
      final channel = eg.stream();
      await prepare(tester, channel: channel,
        topics: [eg.getStreamTopicsEntry(name: 'topic')],
        userTopics: [
          eg.userTopicItem(channel, 'topic', UserTopicVisibilityPolicy.unmuted),
        ]);
      check(find.descendant(of: topicItemFinder,
        matching: find.byIcon(ZulipIcons.unmute))).findsOne();
    });

    testWidgets('followed', (tester) async {
      final channel = eg.stream();
      await prepare(tester, channel: channel,
        topics: [eg.getStreamTopicsEntry(name: 'topic')],
        userTopics: [
          eg.userTopicItem(channel, 'topic', UserTopicVisibilityPolicy.followed),
        ]);
      check(find.descendant(of: topicItemFinder,
        matching: find.byIcon(ZulipIcons.follow))).findsOne();
    });
  });
}
