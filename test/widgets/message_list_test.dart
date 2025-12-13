import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/exception.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/narrow.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/basic.dart';
import 'package:zulip/model/actions.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/message.dart';
import 'package:zulip/model/message_list.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/typing_status.dart';
import 'package:zulip/widgets/app_bar.dart';
import 'package:zulip/widgets/autocomplete.dart';
import 'package:zulip/widgets/color.dart';
import 'package:zulip/widgets/compose_box.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/image.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/store.dart';
import 'package:zulip/widgets/channel_colors.dart';
import 'package:zulip/widgets/theme.dart';
import 'package:zulip/widgets/topic_list.dart';
import 'package:zulip/widgets/user.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/content_test.dart';
import '../model/test_store.dart';
import '../flutter_checks.dart';
import '../stdlib_checks.dart';
import '../test_images.dart';
import '../test_navigation.dart';
import 'checks.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();
  MessageListPage.debugEnableMarkReadOnScroll = false;

  late PerAccountStore store;
  late FakeApiConnection connection;

  Future<void> setupMessageListPage(WidgetTester tester, {
    Narrow narrow = const CombinedFeedNarrow(),
    bool foundOldest = true,
    int? messageCount,
    List<Message>? messages,
    GetMessagesResult? fetchResult,
    List<ZulipStream>? streams,
    List<User>? users,
    List<int>? mutedUserIds,
    List<Subscription>? subscriptions,
    UnreadMessagesSnapshot? unreadMsgs,
    int? zulipFeatureLevel,
    List<NavigatorObserver> navObservers = const [],
    bool skipAssertAccountExists = false,
    bool skipPumpAndSettle = false,
  }) async {
    TypingNotifier.debugEnable = false;
    addTearDown(TypingNotifier.debugReset);
    addTearDown(testBinding.reset);
    streams ??= subscriptions ??= [eg.subscription(eg.stream(streamId: eg.defaultStreamMessageStreamId))];
    zulipFeatureLevel ??= eg.recentZulipFeatureLevel;
    final selfAccount = eg.selfAccount.copyWith(zulipFeatureLevel: zulipFeatureLevel);
    await testBinding.globalStore.add(selfAccount, eg.initialSnapshot(
      zulipFeatureLevel: zulipFeatureLevel,
      streams: streams, subscriptions: subscriptions, unreadMsgs: unreadMsgs));
    store = await testBinding.globalStore.perAccount(selfAccount.id);
    connection = store.connection as FakeApiConnection;

    // prepare message list data
    await store.addUser(eg.selfUser);
    await store.addUsers(users ?? []);
    if (mutedUserIds != null) {
      await store.setMutedUsers(mutedUserIds);
    }
    if (fetchResult != null) {
      assert(foundOldest && messageCount == null && messages == null);
    } else {
      assert((messageCount == null) != (messages == null));
      messages ??= List.generate(messageCount!, (index) {
        return eg.streamMessage(sender: eg.selfUser);
      });
      fetchResult = eg.newestGetMessagesResult(
        foundOldest: foundOldest, messages: messages);
    }
    connection.prepare(json: fetchResult.toJson());

    await tester.pumpWidget(TestZulipApp(accountId: selfAccount.id,
      skipAssertAccountExists: skipAssertAccountExists,
      navigatorObservers: navObservers,
      child: MessageListPage(initNarrow: narrow)));

    if (skipPumpAndSettle) return;
    // global store, per-account store, and message list get loaded
    await tester.pumpAndSettle();
  }

  void checkAppBarChannelTopic(String channelName, String topic) {
    final appBarFinder = find.byType(MessageListAppBarTitle);
    check(appBarFinder).findsOne();
    check(find.descendant(of: appBarFinder, matching: find.text(channelName)))
      .findsOne();
    check(find.descendant(of: appBarFinder, matching: find.text(topic)))
      .findsOne();
  }

  ScrollView findScrollView(WidgetTester tester) =>
    tester.widget<ScrollView>(find.bySubtype<ScrollView>());

  ScrollController? findMessageListScrollController(WidgetTester tester) {
    return findScrollView(tester).controller;
  }

  final contentInputFinder = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.controller is ComposeContentController);

  group('MessageListPage', () {
    testWidgets('ancestorOf finds page state from message', (tester) async {
      await setupMessageListPage(tester,
        messages: [eg.streamMessage(content: "<p>a message</p>")]);
      final expectedState = tester.state<State>(find.byType(MessageListPage));
      check(MessageListPage.ancestorOf(tester.element(find.text("a message"))))
        .identicalTo(expectedState as MessageListPageState);
    });

    testWidgets('ancestorOf throws when not a descendant of MessageListPage', (tester) async {
      await setupMessageListPage(tester,
        messages: [eg.streamMessage(content: "<p>a message</p>")]);
      final element = tester.element(find.byType(PerAccountStoreWidget));
      check(() => MessageListPage.ancestorOf(element))
        .throws<void>();
    });

    testWidgets('MessageListPageState.narrow', (tester) async {
      final stream = eg.stream();
      await setupMessageListPage(tester, narrow: ChannelNarrow(stream.streamId),
        subscriptions: [eg.subscription(stream)],
        messages: [eg.streamMessage(stream: stream, content: "<p>a message</p>")]);
      final state = MessageListPage.ancestorOf(tester.element(find.text("a message")));
      check(state.narrow).equals(ChannelNarrow(stream.streamId));
    });

    testWidgets('narrow gets normalized from "general chat"', (tester) async {
      // Regression test for: https://github.com/zulip/zulip-flutter/issues/1717
      final stream = eg.stream();
      // Open the page on a topic with the literal name "general chat".
      final topic = eg.defaultRealmEmptyTopicDisplayName;
      final topicNarrow = eg.topicNarrow(stream.streamId, topic);
      await setupMessageListPage(tester, narrow: topicNarrow,
        subscriptions: [eg.subscription(stream)],
        messages: [eg.streamMessage(stream: stream, topic: topic, content: "<p>a message</p>")]);
      final state = MessageListPage.ancestorOf(tester.element(find.text("a message")));
      // The page's narrow has been updated; the topic is "", not "general chat".
      check(state.narrow).equals(eg.topicNarrow(stream.streamId, ''));
    });

    testWidgets('composeBoxState finds compose box', (tester) async {
      final stream = eg.stream();
      await setupMessageListPage(tester, narrow: ChannelNarrow(stream.streamId),
        subscriptions: [eg.subscription(stream)],
        messages: [eg.streamMessage(stream: stream, content: "<p>a message</p>")]);
      final state = MessageListPage.ancestorOf(tester.element(find.text("a message")));
      check(state.composeBoxState).isNotNull();
    });

    testWidgets('composeBoxState null when no compose box', (tester) async {
      await setupMessageListPage(tester, narrow: const CombinedFeedNarrow(),
        messages: [eg.streamMessage(content: "<p>a message</p>")]);
      final state = MessageListPage.ancestorOf(tester.element(find.text("a message")));
      check(state.composeBoxState).isNull();
    });

    testWidgets('dispose MessageListView when event queue expired', (tester) async {
      final message = eg.streamMessage();
      await setupMessageListPage(tester, messages: [message]);
      final oldViewModel = store.debugMessageListViews.single;
      final updateMachine = store.updateMachine!;
      updateMachine.debugPauseLoop();
      updateMachine.poll();

      updateMachine.debugPrepareLoopError(
        eg.apiExceptionBadEventQueueId(queueId: store.queueId));
      updateMachine.debugAdvanceLoop();
      await tester.pump();
      // Event queue has been replaced; but the [MessageList] hasn't been
      // rebuilt yet.
      final newStore = testBinding.globalStore.perAccountSync(eg.selfAccount.id)!;
      check(connection.isOpen).isFalse(); // indicates that the old store has been disposed
      check(store.debugMessageListViews).single.equals(oldViewModel);
      check(newStore.debugMessageListViews).isEmpty();

      (newStore.connection as FakeApiConnection).prepare(json: eg.newestGetMessagesResult(
        foundOldest: true, messages: [message]).toJson());
      await tester.pump();
      await tester.pump(Duration.zero);
      // As [MessageList] rebuilds, the old view model gets disposed and
      // replaced with a fresh one.
      check(store.debugMessageListViews).isEmpty();
      check(newStore.debugMessageListViews).single.not((it) => it.equals(oldViewModel));
    });

    testWidgets('dispose MessageListView when logged out', (tester) async {
      await setupMessageListPage(tester,
        messages: [eg.streamMessage()], skipAssertAccountExists: true);
      check(store.debugMessageListViews).single;

      final future = logOutAccount(testBinding.globalStore, eg.selfAccount.id);
      await tester.pump(TestGlobalStore.removeAccountDuration);
      await future;
      check(store.debugMessageListViews).isEmpty();
    });
  });

  group('app bar', () {
    // Tests for the topic action sheet are in test/widgets/action_sheet_test.dart.

    testWidgets('handle empty topics', (tester) async {
      final channel = eg.stream();
      await setupMessageListPage(tester,
        narrow: eg.topicNarrow(channel.streamId, ''),
        subscriptions: [eg.subscription(channel)],
        messageCount: 1);
      checkAppBarChannelTopic(
        channel.name, eg.defaultRealmEmptyTopicDisplayName);
    });

    void testChannelIconInChannelRow(IconData expectedIcon, {
      required bool isWebPublic,
      required bool inviteOnly,
    }) {
      final description = 'channel icon in channel row; '
        'web-public: $isWebPublic, invite-only: $inviteOnly';
      testWidgets(description, (tester) async {
        final color = 0xff95a5fd;

        final channel = eg.stream(isWebPublic: isWebPublic, inviteOnly: inviteOnly);
        final subscription = eg.subscription(channel, color: color);

        await setupMessageListPage(tester,
          narrow: ChannelNarrow(channel.streamId),
          streams: [channel],
          subscriptions: [subscription],
          messages: [eg.streamMessage(stream: channel)]);

        final iconElement = tester.element(find.descendant(
          of: find.byType(ZulipAppBar),
          matching: find.byIcon(expectedIcon)));

        check(Theme.brightnessOf(iconElement)).equals(Brightness.light);
        check(iconElement.widget as Icon).color.equals(Color(0xff5972fc));
      });
    }
    testChannelIconInChannelRow(ZulipIcons.globe, isWebPublic: true, inviteOnly: false);
    testChannelIconInChannelRow(ZulipIcons.lock, isWebPublic: false, inviteOnly: true);
    testChannelIconInChannelRow(ZulipIcons.hash_sign, isWebPublic: false, inviteOnly: false);

    testWidgets('has channel-feed action for topic narrows', (tester) async {
      final pushedRoutes = <Route<void>>[];
      final navObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      final channel = eg.stream();
      await setupMessageListPage(tester, narrow: eg.topicNarrow(channel.streamId, 'hi'),
        navObservers: [navObserver],
        subscriptions: [eg.subscription(channel)], messageCount: 1);

      // Clear out initial route.
      assert(pushedRoutes.length == 1);
      pushedRoutes.clear();

      // Tap button; it works.
      await tester.tap(find.byIcon(ZulipIcons.message_feed));
      check(pushedRoutes).single.isA<WidgetRoute>()
        .page.isA<MessageListPage>().initNarrow
          .equals(ChannelNarrow(channel.streamId));
    });

    testWidgets('has topic-list action for topic narrows', (tester) async {
      final channel = eg.stream(name: 'channel foo');
      await setupMessageListPage(tester,
        narrow: eg.topicNarrow(channel.streamId, 'topic foo'),
        subscriptions: [eg.subscription(channel)],
        messages: [eg.streamMessage(stream: channel, topic: 'topic foo')]);

      connection.prepare(json: GetChannelTopicsResult(topics: [
        eg.getChannelTopicsEntry(name: 'topic foo'),
      ]).toJson());
      await tester.tap(find.byIcon(ZulipIcons.topics));
      await tester.pump(); // tap the button
      await tester.pump(Duration.zero); // wait for request
      check(find.descendant(
        of: find.byType(TopicListPage),
        matching: find.text('channel foo')),
      ).findsOne();
    });

    testWidgets('show topic visibility policy for topic narrows', (tester) async {
      final channel = eg.stream();
      const topic = 'topic';
      await setupMessageListPage(tester,
        narrow: eg.topicNarrow(channel.streamId, topic),
        streams: [channel], subscriptions: [eg.subscription(channel)],
        messageCount: 1);
      await store.handleEvent(eg.userTopicEvent(
        channel.streamId, topic, UserTopicVisibilityPolicy.muted));
      await tester.pump();

      check(find.descendant(
        of: find.byType(MessageListAppBarTitle),
        matching: find.byIcon(ZulipIcons.mute))).findsOne();
    });

    testWidgets('has topic-list action for channel narrows', (tester) async {
      final channel = eg.stream(name: 'channel foo');
      await setupMessageListPage(tester,
        narrow: ChannelNarrow(channel.streamId),
        subscriptions: [eg.subscription(channel)],
        messages: [eg.streamMessage(stream: channel, topic: 'topic foo')]);

      connection.prepare(json: GetChannelTopicsResult(topics: [
        eg.getChannelTopicsEntry(name: 'topic foo'),
      ]).toJson());
      await tester.tap(find.byIcon(ZulipIcons.topics));
      await tester.pump(); // tap the button
      await tester.pump(Duration.zero); // wait for request
      check(find.descendant(
        of: find.byType(TopicListPage),
        matching: find.text('channel foo')),
      ).findsOne();
    });

    testWidgets('shows "Muted user" label for muted users in DM narrow', (tester) async {
      final user1 = eg.user(userId: 1, fullName: 'User 1');
      final user2 = eg.user(userId: 2, fullName: 'User 2');
      final user3 = eg.user(userId: 3, fullName: 'User 3');
      final mutedUsers = [1, 3];

      await setupMessageListPage(tester,
        narrow: DmNarrow.withOtherUsers([1, 2, 3], selfUserId: 10),
        users: [user1, user2, user3],
        mutedUserIds: mutedUsers,
        messageCount: 1,
      );

      check(find.text('DMs with Muted user, User 2, Muted user')).findsOne();
    });
  });

  group('no-messages placeholder', () {
    final findPlaceholder = find.byType(PageBodyEmptyContentPlaceholder);

    Finder findTextInPlaceholder(String text) =>
      find.descendant(of: findPlaceholder, matching: find.textContaining(text));

    Future<void> checkLink(WidgetTester tester, {
        required String linkText, required Uri expectedUrl}) async {
      await tester.tapOnText(find.textRange.ofSubstring(linkText));
      final (url: url, mode: _) = testBinding.takeLaunchUrlCalls().single;
      check(url).equals(expectedUrl);
    }

    testWidgets('Combined feed', (tester) async {
      await setupMessageListPage(tester, narrow: CombinedFeedNarrow(), messages: []);
      check(findPlaceholder).findsOne();
      check(findTextInPlaceholder('combined feed')).findsOne();
    });

    testWidgets('Subscribed channel', (tester) async {
      final channel = eg.stream();
      await setupMessageListPage(tester,
        narrow: ChannelNarrow(channel.streamId), messages: [], streams: [channel],
        skipPumpAndSettle: true);

      // The topic input is autofocused, triggering topic autocomplete.
      connection.prepare(json: GetChannelTopicsResult(topics: []).toJson());
      await tester.pumpAndSettle();

      check(findPlaceholder).findsOne();
      check(findTextInPlaceholder('no messages')).findsOne();
    });

    testWidgets('Channel without content access', (tester) async {
      final channel = eg.stream(inviteOnly: true);
      await setupMessageListPage(tester,
        narrow: ChannelNarrow(channel.streamId), messages: [], streams: [channel],
        skipPumpAndSettle: true);

      // The topic input is autofocused, triggering topic autocomplete.
      connection.prepare(json: GetChannelTopicsResult(topics: []).toJson());
      await tester.pumpAndSettle();

      check(store.selfHasContentAccess(channel)).isFalse();
      check(findPlaceholder).findsOne();
      check(findTextInPlaceholder('content access')).findsOne();
      await checkLink(tester,
        linkText: 'content access',
        expectedUrl: store.tryResolveUrl('/help/channel-permissions')!);
    });

    testWidgets('Unknown channel', (tester) async {
      final channel = eg.stream();
      await setupMessageListPage(tester,
        narrow: ChannelNarrow(channel.streamId), messages: [], streams: []);
      check(findPlaceholder).findsOne();
      check(findTextInPlaceholder('This channel doesn’t exist, or you are not allowed to view it.')).findsOne();
    });

    testWidgets('Topic in unknown channel', (tester) async {
      final channel = eg.stream();
      await setupMessageListPage(tester,
        narrow: TopicNarrow(channel.streamId, eg.t('topic')), messages: [], streams: []);
      check(findPlaceholder).findsOne();
      check(findTextInPlaceholder('This channel doesn’t exist, or you are not allowed to view it.')).findsOne();
    });

    testWidgets('Topic in subscribed channel', (tester) async {
      final channel = eg.stream();
      await setupMessageListPage(tester,
        narrow: TopicNarrow(channel.streamId, eg.t('topic')), messages: [], streams: [channel]);
      check(findPlaceholder).findsOne();
      check(findTextInPlaceholder('no messages')).findsOne();
    });

    testWidgets('Topic in channel without content access', (tester) async {
      final channel = eg.stream(inviteOnly: true);
      await setupMessageListPage(tester,
        narrow: TopicNarrow(channel.streamId, eg.t('topic')), messages: [], streams: [channel],
        skipPumpAndSettle: true);

      // The topic input is autofocused, triggering topic autocomplete.
      connection.prepare(json: GetChannelTopicsResult(topics: []).toJson());
      await tester.pumpAndSettle();

      check(store.selfHasContentAccess(channel)).isFalse();
      check(findPlaceholder).findsOne();
      check(findTextInPlaceholder('content access')).findsOne();
      await checkLink(tester,
        linkText: 'content access',
        expectedUrl: store.tryResolveUrl('/help/channel-permissions')!);
    });

    testWidgets('Self-DM', (tester) async {
      final selfUserId = eg.selfUser.userId;
      await setupMessageListPage(tester,
        narrow: DmNarrow.withUser(selfUserId, selfUserId: selfUserId), messages: [], users: [eg.selfUser]);
      check(findPlaceholder).findsOne();
      check(findTextInPlaceholder('yourself')).findsOne();
      check(findTextInPlaceholder('Use this space')).findsOne();
    });

    testWidgets('1:1 DM', (tester) async {
      final selfUserId = eg.selfUser.userId;
      final user = eg.user();
      await setupMessageListPage(tester,
        narrow: DmNarrow.withUser(user.userId, selfUserId: selfUserId), messages: [], users: [eg.selfUser, user]);
      check(findPlaceholder).findsOne();
      check(findTextInPlaceholder(user.fullName)).findsOne();
      check(findTextInPlaceholder('yet.')).findsOne();
      check(findTextInPlaceholder('Why not start the conversation?')).findsOne();
    });

    testWidgets('1:1 DM, muted user', (tester) async {
      final selfUserId = eg.selfUser.userId;
      final user = eg.user();
      await setupMessageListPage(tester,
        narrow: DmNarrow.withUser(user.userId, selfUserId: selfUserId), messages: [], users: [eg.selfUser, user]);
      await store.handleEvent(MutedUsersEvent(id: 1, mutedUsers: [MutedUserItem(id: user.userId)]));
      await tester.pump();
      check(store.isUserMuted(user.userId)).isTrue();
      check(findPlaceholder).findsOne();

      // Probably want to show their name, not "Muted user";
      // this UI context is very much focused on the one user.
      check(findTextInPlaceholder(user.fullName)).findsOne();
      check(findTextInPlaceholder('Muted user')).findsNothing();

      // No need to encourage starting a conversation though.
      check(findTextInPlaceholder('Why not start the conversation?')).findsNothing();
    });

    testWidgets('1:1 DM, unknown user', (tester) async {
      final selfUserId = eg.selfUser.userId;
      await setupMessageListPage(tester,
        narrow: DmNarrow.withUser(eg.user().userId, selfUserId: selfUserId), messages: [], users: [eg.selfUser]);
      check(findPlaceholder).findsOne();
      check(findTextInPlaceholder('this user')).findsOne();
      check(findTextInPlaceholder('(unknown user)')).findsNothing();

      // No need to encourage starting a conversation...right?
      check(findTextInPlaceholder('yet.')).findsNothing();
      check(findTextInPlaceholder('Why not start the conversation?')).findsNothing();
    });

    testWidgets('1:1 DM, deactivated user', (tester) async {
      final selfUserId = eg.selfUser.userId;
      final user = eg.user(isActive: false);
      await setupMessageListPage(tester,
        narrow: DmNarrow.withUser(user.userId, selfUserId: selfUserId), messages: [], users: [eg.selfUser, user]);
      check(findPlaceholder).findsOne();
      check(findTextInPlaceholder(user.fullName)).findsOne();

      // Sending messages isn't allowed; don't suggest that
      check(findTextInPlaceholder('yet.')).findsNothing();
      check(findTextInPlaceholder('Why not start the conversation?')).findsNothing();
    });

    testWidgets('1:1 DM, muted and deactivated user', (tester) async {
      final selfUserId = eg.selfUser.userId;
      final user = eg.user(isActive: false);
      await setupMessageListPage(tester,
        narrow: DmNarrow.withUser(user.userId, selfUserId: selfUserId), messages: [], users: [eg.selfUser, user]);
      await store.handleEvent(MutedUsersEvent(id: 1, mutedUsers: [MutedUserItem(id: user.userId)]));
      await tester.pump();
      check(store.isUserMuted(user.userId)).isTrue();
      check(findPlaceholder).findsOne();

      // Probably want to show their name, not "Muted user";
      // this UI context is very much focused on the one user.
      check(findTextInPlaceholder(user.fullName)).findsOne();
      check(findTextInPlaceholder('Muted user')).findsNothing();

      // Sending messages isn't allowed; don't suggest that
      check(findTextInPlaceholder('yet.')).findsNothing();
      check(findTextInPlaceholder('Why not start the conversation?')).findsNothing();
    });

    testWidgets('Group DM', (tester) async {
      final selfUserId = eg.selfUser.userId;
      final user1 = eg.user();
      final user2 = eg.user();
      await setupMessageListPage(tester,
        narrow: DmNarrow.withUsers([user1.userId, user2.userId], selfUserId: selfUserId),
        messages: [], users: [eg.selfUser, user1, user2]);
      check(findPlaceholder).findsOne();
      check(findTextInPlaceholder('these users')).findsOne();
      check(findTextInPlaceholder('yet.')).findsOne();
      check(findTextInPlaceholder('Why not start the conversation?')).findsOne();
    });

    testWidgets('Group DM with a deactivated user', (tester) async {
      final selfUserId = eg.selfUser.userId;
      final user1 = eg.user(isActive: false);
      final user2 = eg.user();
      await setupMessageListPage(tester,
        narrow: DmNarrow.withUsers([user1.userId, user2.userId], selfUserId: selfUserId),
        messages: [], users: [eg.selfUser, user1, user2]);
      check(findPlaceholder).findsOne();
      check(findTextInPlaceholder('these users')).findsOne();

      // Sending messages isn't allowed; don't suggest that
      check(findTextInPlaceholder('yet.')).findsNothing();
      check(findTextInPlaceholder('Why not start the conversation?')).findsNothing();
    });

    testWidgets('Mentions', (tester) async {
      await setupMessageListPage(tester, narrow: MentionsNarrow(), messages: []);
      check(findPlaceholder).findsOne();
      check(findTextInPlaceholder('mentioned')).findsOne();
    });

    testWidgets('Starred', (tester) async {
      await setupMessageListPage(tester, narrow: StarredMessagesNarrow(), messages: []);
      check(findPlaceholder).findsOne();
      check(findTextInPlaceholder('starred')).findsOne();
      check(findTextInPlaceholder('tap “Star message.”')).findsOne();
      await checkLink(tester, linkText: 'Starring',
        expectedUrl: store.tryResolveUrl('/help/star-a-message')!);
    });

    testWidgets('Search, empty keyword', (tester) async {
      await setupMessageListPage(tester, narrow: KeywordSearchNarrow(''), messages: []);
      check(findTextInPlaceholder('No search results.')).findsOne();
    });

    testWidgets('Search, non-empty keyword', (tester) async {
      await setupMessageListPage(tester, narrow: KeywordSearchNarrow('hello'), messages: []);
      check(findTextInPlaceholder('No search results.')).findsOne();
    });

    testWidgets('when `messages` empty but `outboxMessages` not empty, show outboxes, not placeholder', (tester) async {
      final channel = eg.stream();
      await setupMessageListPage(tester,
        narrow: TopicNarrow(channel.streamId, eg.t('topic')),
        subscriptions: [eg.subscription(channel)],
        messages: []);
      check(findPlaceholder).findsOne();

      connection.prepare(json: SendMessageResult(id: 1).toJson());
      await tester.enterText(contentInputFinder, 'asdfjkl;');
      await tester.tap(find.byIcon(ZulipIcons.send));
      await tester.pump(kLocalEchoDebounceDuration);

      check(findPlaceholder).findsNothing();
      check(find.text('asdfjkl;')).findsOne();
    });
  });

  group('presents message content appropriately', () {
    testWidgets('content not asked to consume insets (including bottom), even without compose box, in top sliver', (tester) async {
      // Regression test for: https://github.com/zulip/zulip-flutter/issues/1523
      const fakePadding = FakeViewPadding(left: 10, top: 10, right: 10, bottom: 10);
      tester.view.viewInsets = fakePadding;
      tester.view.padding = fakePadding;

      await setupMessageListPage(tester, narrow: const CombinedFeedNarrow(),
        messages: [
          eg.streamMessage(content: ContentExample.codeBlockPlain.html),
          eg.streamMessage(),
        ]);

      // Verify this message list lacks a compose box.
      // (The original bug wouldn't reproduce with a compose box present.)
      final state = MessageListPage.ancestorOf(tester.element(find.text("verb\natim")));
      check(state.composeBoxState).isNull();
      // Also verify that the first message is in the top sliver.
      check(state.model!.middleMessage).equals(1);

      final element = tester.element(find.byType(CodeBlock));
      final padding = MediaQuery.of(element).padding;
      check(padding).equals(EdgeInsets.zero);
    });

    testWidgets('content not asked to consume insets (including bottom), even without compose box, in bottom sliver', (tester) async {
      // Regression test for: https://github.com/zulip/zulip-flutter/issues/736
      const fakePadding = FakeViewPadding(left: 10, top: 10, right: 10, bottom: 10);
      tester.view.viewInsets = fakePadding;
      tester.view.padding = fakePadding;

      await setupMessageListPage(tester, narrow: const CombinedFeedNarrow(),
        messages: [eg.streamMessage(content: ContentExample.codeBlockPlain.html)]);

      // Verify this message list lacks a compose box.
      // (The original bug wouldn't reproduce with a compose box present.)
      final state = MessageListPage.ancestorOf(tester.element(find.text("verb\natim")));
      check(state.composeBoxState).isNull();
      // Also verify that the message is in the bottom sliver.
      check(state.model!.middleMessage).equals(0);

      final element = tester.element(find.byType(CodeBlock));
      final padding = MediaQuery.of(element).padding;
      check(padding).equals(EdgeInsets.zero);
    });
  });

  testWidgets('smoke test for light/dark/lerped', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final message = eg.streamMessage();
    await setupMessageListPage(tester, messages: [message]);

    Color backgroundColor() {
      final coloredBoxFinder = find.descendant(
        of: find.byWidgetPredicate((w) => w is MessageItem && w.item.message.id == message.id),
        matching: find.byType(ColoredBox),
      );
      final widget = tester.widget<ColoredBox>(coloredBoxFinder);
      return widget.color;
    }

    check(backgroundColor()).isSameColorAs(DesignVariables.light.bgMessageRegular);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();

    await tester.pump(kThemeAnimationDuration * 0.4);
    final expectedLerped = DesignVariables.light.lerp(DesignVariables.dark, 0.4);
    check(backgroundColor()).isSameColorAs(expectedLerped.bgMessageRegular);

    await tester.pump(kThemeAnimationDuration * 0.6);
    check(backgroundColor()).isSameColorAs(DesignVariables.dark.bgMessageRegular);
  });

  group('fetch initial batch of messages', () {
    // TODO(#1571): test effect of visitFirstUnread setting
    // TODO(#1569): test effect of initAnchorMessageId
    // TODO(#1569): test that after jumpToEnd, then new store causing new fetch,
    //   new post-jump anchor prevails over initAnchorMessageId

    group('topic permalink', () {
      final someStream = eg.stream();
      final someSubscription = eg.subscription(someStream);
      const someTopic = 'some topic';

      final otherStream = eg.stream();
      final otherSubscription = eg.subscription(otherStream);
      const otherTopic = 'other topic';

      testWidgets('with message move', (tester) async {
        final narrow = TopicNarrow(someStream.streamId, eg.t(someTopic), with_: 1);
        await setupMessageListPage(tester,
          narrow: narrow,
          // server sends the /with/<id> message in its current, different location
          messages: [eg.streamMessage(id: 1, stream: otherStream, topic: otherTopic)],
          subscriptions: [someSubscription, otherSubscription],
          skipPumpAndSettle: true);
        await tester.pump(); // global store loaded
        await tester.pump(); // per-account store loaded

        // Until we learn the conversation was moved,
        // we put the link's stream/topic in the app bar.
        checkAppBarChannelTopic(someStream.name, someTopic);

        await tester.pumpAndSettle(); // initial message fetch plus anything else

        // When we learn the conversation was moved,
        // we put the new stream/topic in the app bar.
        checkAppBarChannelTopic(otherStream.name, otherTopic);

        // We followed the move in just one fetch.
        check(connection.takeRequests()).single.isA<http.Request>()
          ..method.equals('GET')
          ..url.path.equals('/api/v1/messages')
          ..url.queryParameters.deepEquals({
            'narrow': jsonEncode(resolveApiNarrowForServer(narrow.apiEncode(), connection.zulipFeatureLevel!)),
            'anchor': AnchorCode.firstUnread.toJson(),
            'num_before': kMessageListFetchBatchSize.toString(),
            'num_after': kMessageListFetchBatchSize.toString(),
            'allow_empty_topic_name': 'true',
          });
      });

      testWidgets('without message move', (tester) async {
        final narrow = TopicNarrow(someStream.streamId, eg.t(someTopic), with_: 1);
        await setupMessageListPage(tester,
          narrow: narrow,
          // server sends the /with/<id> message in its current, different location
          messages: [eg.streamMessage(id: 1, stream: someStream, topic: someTopic)],
          subscriptions: [someSubscription],
          skipPumpAndSettle: true);
        await tester.pump(); // global store loaded
        await tester.pump(); // per-account store loaded

        // Until we learn if the conversation was moved,
        // we put the link's stream/topic in the app bar.
        checkAppBarChannelTopic(someStream.name, someTopic);

        await tester.pumpAndSettle(); // initial message fetch plus anything else

        // There was no move, so we're still showing the same stream/topic.
        checkAppBarChannelTopic(someStream.name, someTopic);

        // We only made one fetch.
        check(connection.takeRequests()).single.isA<http.Request>()
          ..method.equals('GET')
          ..url.path.equals('/api/v1/messages')
          ..url.queryParameters.deepEquals({
            'narrow': jsonEncode(resolveApiNarrowForServer(narrow.apiEncode(), connection.zulipFeatureLevel!)),
            'anchor': AnchorCode.firstUnread.toJson(),
            'num_before': kMessageListFetchBatchSize.toString(),
            'num_after': kMessageListFetchBatchSize.toString(),
            'allow_empty_topic_name': 'true',
          });
      });
    });
  });

  group('fetch older messages on scroll', () {
    // TODO(#1569): test fetch newer messages on scroll, too;
    //   in particular test it happens even when near top as well as bottom
    //   (because may have haveOldest true but haveNewest false)

    int? itemCount(WidgetTester tester) =>
      findScrollView(tester).semanticChildCount;

    testWidgets('basic', (tester) async {
      await setupMessageListPage(tester, foundOldest: false,
        messages: List.generate(300, (i) => eg.streamMessage(id: 950 + i, sender: eg.selfUser)));
      check(itemCount(tester)).equals(301);

      // Fling-scroll upward...
      await tester.fling(find.byType(MessageListPage), const Offset(0, 300), 8000);
      await tester.pump();

      // ... and we should fetch more messages as we go.
      connection.prepare(json: eg.olderGetMessagesResult(anchor: 950, foundOldest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 850 + i, sender: eg.selfUser))).toJson());
      await tester.pump(const Duration(seconds: 3)); // Fast-forward to end of fling.
      await tester.pump(Duration.zero); // Allow a frame for the response to arrive.

      // Now we have more messages.
      check(itemCount(tester)).equals(401);
    });

    testWidgets('observe double-fetch glitch', (tester) async {
      await setupMessageListPage(tester, foundOldest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 950 + i, sender: eg.selfUser)));
      check(itemCount(tester)).equals(101);

      // Fling-scroll upward...
      await tester.fling(find.byType(MessageListPage), const Offset(0, 300), 8000);
      await tester.pump();

      // ... and we fetch more messages as we go.
      connection.prepare(json: eg.olderGetMessagesResult(anchor: 950, foundOldest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 850 + i, sender: eg.selfUser))).toJson());
      for (int i = 0; i < 30; i++) {
        // Find the point in the fling where the fetch starts.
        await tester.pump(const Duration(milliseconds: 100));
        if (itemCount(tester)! > 101) break; // The loading indicator appeared.
      }
      await tester.pump(Duration.zero); // Allow a frame for the response to arrive.
      check(itemCount(tester)).equals(201);

      // On the next frame, we promptly fetch *another* batch.
      // This is a glitch and it'd be nicer if we didn't.
      connection.prepare(json: eg.olderGetMessagesResult(anchor: 850, foundOldest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 750 + i, sender: eg.selfUser))).toJson());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(Duration.zero);
      check(itemCount(tester)).equals(301);
    }, skip: true); // TODO this still reproduces manually, still needs debugging,
                    // but has become harder to reproduce in a test.

    testWidgets("avoid getting distracted by nested viewports' metrics", (tester) async {
      // Regression test for: https://github.com/zulip/zulip-flutter/issues/507
      await setupMessageListPage(tester, foundOldest: false, messages: [
        ...List.generate(300, (i) => eg.streamMessage(id: 1000 + i)),
        eg.streamMessage(id: 1301, content: ContentExample.codeBlockPlain.html),
        ...List.generate(100, (i) => eg.streamMessage(id: 1302 + i)),
      ]);
      final lastRequest = connection.lastRequest;
      check(itemCount(tester)).equals(402);

      // Fling-scroll upward...
      await tester.fling(find.byType(MessageListPage), const Offset(0, 300), 8000);
      await tester.pump();

      // ... in particular past the message with a [CodeBlockNode]...
      bool sawCodeBlock = false;
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (tester.widgetList(find.byType(CodeBlock)).isNotEmpty) {
          sawCodeBlock = true;
          break;
        }
      }
      check(sawCodeBlock).isTrue();

      // ... and we should attempt no fetches.  (This check isn't strictly
      // necessary; a request would have thrown, as we prepared no response.)
      await tester.pump();
      check(connection.lastRequest).identicalTo(lastRequest);
    });
  });

  group('scroll position', () {
    // The scrolling behavior is tested in more detail in the tests of
    // [MessageListScrollView], in scrolling_test.dart .

    testWidgets('sticks to end upon new message', (tester) async {
      await setupMessageListPage(tester, messages: List.generate(10,
        (i) => eg.streamMessage(content: '<p>message $i</p>')));
      final controller = findMessageListScrollController(tester)!;
      final findMiddleMessage = find.text('message 5');

      // Started out scrolled to the bottom.
      check(controller.position).extentAfter.equals(0);
      final scrollPixels = controller.position.pixels;

      // Note the position of some mid-screen message.
      final messageRect = tester.getRect(findMiddleMessage);
      check(messageRect)..top.isGreaterThan(0)..bottom.isLessThan(600);

      // When a new message arrives, the existing message moves up…
      await store.addMessage(eg.streamMessage(content: '<p>a</p><p>b</p>'));
      await tester.pump();
      check(tester.getRect(findMiddleMessage))
        ..top.isLessThan(messageRect.top)
        ..height.isCloseTo(messageRect.height, Tolerance().distance);
      // … because the position remains at the end…
      check(controller.position)
        ..extentAfter.equals(0)
        // … even though that means a bigger number now.
        ..pixels.isGreaterThan(scrollPixels);
    });

    testWidgets('preserves visible messages upon new message, when not at end', (tester) async {
      await setupMessageListPage(tester, messages: List.generate(10,
        (i) => eg.streamMessage(content: '<p>message $i</p>')));
      final controller = findMessageListScrollController(tester)!;
      final findMiddleMessage = find.text('message 5');

      // Started at bottom.  Scroll up a bit.
      check(controller.position).extentAfter.equals(0);
      controller.position.jumpTo(controller.position.pixels - 100);
      await tester.pump();
      check(controller.position).extentAfter.equals(100);
      final scrollPixels = controller.position.pixels;

      // Note the position of some mid-screen message.
      final messageRect = tester.getRect(findMiddleMessage);
      check(messageRect)..top.isGreaterThan(0)..bottom.isLessThan(600);

      // When a new message arrives, the existing message doesn't shift…
      await store.addMessage(eg.streamMessage(content: '<p>a</p><p>b</p>'));
      await tester.pump();
      check(tester.getRect(findMiddleMessage)).equals(messageRect);
      // … because the scroll position value remained the same…
      check(controller.position)
        ..pixels.equals(scrollPixels)
        // … even though there's now more content off screen below.
        // (This last check relies on the fact that the old extentAfter is small,
        // less than cacheExtent, so that the new content is only barely offscreen,
        // it gets built, and the new extentAfter reflects it.)
        ..extentAfter.isGreaterThan(100);
    });
  });

  group('ScrollToBottomButton interactions', () {
    bool isButtonVisible(WidgetTester tester) {
      return tester.any(find.descendant(
        of: find.byType(ScrollToBottomButton),
        matching: find.byTooltip("Scroll to bottom")));
    }

    testWidgets('scrolling changes visibility', (tester) async {
      await setupMessageListPage(tester, messageCount: 10);
      // Scroll position starts at the end, so button hidden.
      final controller = findMessageListScrollController(tester)!;
      check(controller.position).extentAfter.equals(0);
      check(isButtonVisible(tester)).equals(false);

      // Scrolling up, button becomes visible.
      controller.jumpTo(-600);
      await tester.pump();
      check(controller.position).extentAfter.isGreaterThan(0);
      check(isButtonVisible(tester)).equals(true);

      // Scrolling back down to end, button becomes hidden again.
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      check(controller.position).extentAfter.equals(0);
      check(isButtonVisible(tester)).equals(false);
    });

    testWidgets('dimension updates changes visibility', (tester) async {
      await setupMessageListPage(tester, messageCount: 100);

      // Scroll up, to hide the button.
      final controller = findMessageListScrollController(tester)!;
      controller.jumpTo(-600);
      await tester.pump();
      check(isButtonVisible(tester)).equals(true);

      // Make the view taller, so that the bottom of the list is back in view.
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(2000, 40000);
      await tester.pump();
      // (Dimension changes use NotificationListener<ScrollMetricsNotification>
      // which has a one-frame lag.  If that ever gets resolved,
      // this extra pump would ideally be removed.)
      await tester.pump();
      // Check the button duly disappears again.
      check(isButtonVisible(tester)).equals(false);
    });

    testWidgets('button works', (tester) async {
      await setupMessageListPage(tester, messageCount: 10);
      final controller = findMessageListScrollController(tester)!;
      controller.jumpTo(-600);
      await tester.pump();
      check(controller.position).extentAfter.isGreaterOrEqual(600);

      // Tap button.
      await tester.tap(find.byType(ScrollToBottomButton));
      // The list scrolls to the end…
      await tester.pumpAndSettle();
      check(controller.position).extentAfter.equals(0);
      // … and for good measure confirm the button disappeared.
      check(isButtonVisible(tester)).equals(false);
    });

    // TODO(#1569): test choice of jumpToEnd vs. scrollToEnd

    testWidgets('scrolls at reasonable, constant speed', (tester) async {
      const maxSpeed = 8000.0;
      const distance = 40000.0;
      await setupMessageListPage(tester, messageCount: 1000);
      final controller = findMessageListScrollController(tester)!;

      // Scroll a long distance up, many screenfuls.
      controller.jumpTo(-distance);
      await tester.pump();
      check(controller.position).pixels.equals(-distance);

      // Tap button.
      await tester.tap(find.byType(ScrollToBottomButton));
      await tester.pump();

      // Measure speed.
      final log = <double>[];
      double pos = controller.position.pixels;
      while (pos < 0) {
        check(log.length).isLessThan(30);
        await tester.pump(const Duration(seconds: 1));
        final lastPos = pos;
        pos = controller.position.pixels;
        log.add(pos - lastPos);
      }
      // Check the main question: the speed was as expected throughout.
      check(log.slice(0, log.length-1)).every((it) => it.equals(maxSpeed));
      check(log).last..isGreaterThan(0)..isLessOrEqual(maxSpeed);

      // Also check the test's assumptions: the scroll reached the end…
      check(pos).equals(0);
      // … and scrolled far enough to effectively test the max speed.
      check(log.sum).isGreaterThan(2 * maxSpeed);
    });
  });

  // TODO test markers at start of list (`_buildStartCap`)

  group('markers at end of list', () {
    final findLoadingIndicator = find.byType(CircularProgressIndicator);

    testWidgets('spacer when have newest', (tester) async {
      final messages = List.generate(10,
        (i) => eg.streamMessage(content: '<p>message $i</p>'));
      await setupMessageListPage(tester, narrow: CombinedFeedNarrow(),
        fetchResult: eg.nearGetMessagesResult(anchor: messages.last.id,
          foundOldest: true, foundNewest: true, messages: messages));
      check(findMessageListScrollController(tester)!.position)
        .extentAfter.equals(0);

      // There's no loading indicator.
      check(findLoadingIndicator).findsNothing();
      // The last message is spaced above the bottom of the viewport.
      check(tester.getRect(find.text('message 9')))
        .bottom..isGreaterThan(400)..isLessThan(570);
    });

    testWidgets('loading indicator displaces spacer etc.', (tester) async {
      await setupMessageListPage(tester, narrow: CombinedFeedNarrow(),
        skipPumpAndSettle: true,
        // TODO(#1569) fix realism of this data: foundNewest false should mean
        //   some messages found after anchor (and then we might need to scroll
        //   to cause fetching newer messages).
        fetchResult: eg.nearGetMessagesResult(anchor: 1000,
          foundOldest: true, foundNewest: false,
          messages: List.generate(10,
            (i) => eg.streamMessage(id: 100 + i, content: '<p>message $i</p>'))));
      await tester.pump();

      // The message list will immediately start fetching newer messages.
      connection.prepare(json: eg.newerGetMessagesResult(
        anchor: 109, foundNewest: true, messages: List.generate(100,
          (i) => eg.streamMessage(id: 110 + i))).toJson());
      await tester.pump(Duration(milliseconds: 10));
      await tester.pump();

      // There's a loading indicator.
      check(findLoadingIndicator).findsOne();
      // It's at the bottom.
      check(findMessageListScrollController(tester)!.position)
        .extentAfter.equals(0);
      final loadingIndicatorRect = tester.getRect(findLoadingIndicator);
      check(loadingIndicatorRect).bottom.isGreaterThan(575);
      // The last message is shortly above it; no spacer or anything else.
      check(tester.getRect(find.text('message 9')))
        .bottom.isGreaterThan(loadingIndicatorRect.top - 36); // TODO(#1569) where's this space going?
      await tester.pumpAndSettle();
    });

    // TODO(#1569) test no typing status or mark-read button when not haveNewest
    //   (even without loading indicator)
  });

  group('TypingStatusWidget', () {
    final users = [eg.selfUser, eg.otherUser, eg.thirdUser, eg.fourthUser];
    final finder = find.descendant(
      of: find.byType(TypingStatusWidget),
      matching: find.byType(Text)
    );

    Future<void> checkTyping(WidgetTester tester, TypingEvent event, {required String expected}) async {
      await store.handleEvent(event);
      await tester.pump();
      check(tester.widget<Text>(finder)).data.equals(expected);
    }

    final dmMessage = eg.dmMessage(
      from: eg.selfUser, to: [eg.otherUser, eg.thirdUser, eg.fourthUser]);
    final dmNarrow = DmNarrow.ofMessage(dmMessage, selfUserId: eg.selfUser.userId);

    final streamMessage = eg.streamMessage();
    final topicNarrow = TopicNarrow.ofMessage(streamMessage);

    for (final (description, message, narrow) in <(String, Message, SendableNarrow)>[
      ('typing in dm',    dmMessage,      dmNarrow),
      ('typing in topic', streamMessage,  topicNarrow),
    ]) {
      testWidgets(description, (tester) async {
        await setupMessageListPage(tester,
          narrow: narrow, users: users, messages: [message]);
        await tester.pump();
        check(finder.evaluate()).isEmpty();
        await checkTyping(tester,
          eg.typingEvent(narrow, TypingOp.start, eg.otherUser.userId),
          expected: 'Other User is typing…');
        await checkTyping(tester,
          eg.typingEvent(narrow, TypingOp.start, eg.selfUser.userId),
          expected: 'Other User is typing…');
        await checkTyping(tester,
          eg.typingEvent(narrow, TypingOp.start, eg.thirdUser.userId),
          expected: 'Other User and Third User are typing…');
        await checkTyping(tester,
          eg.typingEvent(narrow, TypingOp.start, eg.fourthUser.userId),
          expected: 'Several people are typing…');
        await checkTyping(tester,
          eg.typingEvent(narrow, TypingOp.stop, eg.otherUser.userId),
          expected: 'Third User and Fourth User are typing…');
        // Verify that typing indicators expire after a set duration.
        await tester.pump(const Duration(seconds: 15));
        check(finder.evaluate()).isEmpty();
      });
    }

    testWidgets('unknown user typing', (tester) async {
      final streamMessage = eg.streamMessage();
      final narrow = TopicNarrow.ofMessage(streamMessage);
      await setupMessageListPage(tester,
        narrow: narrow, users: [], messages: [streamMessage]);
      await checkTyping(tester,
        eg.typingEvent(narrow, TypingOp.start, 1000),
        expected: '(unknown user) is typing…',
      );
      // Wait for the pending timers to end.
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('muted user typing', (tester) async {
      await setupMessageListPage(tester,
        narrow: topicNarrow, users: users, messages: [streamMessage]);

      await checkTyping(tester,
        eg.typingEvent(topicNarrow, TypingOp.start, eg.otherUser.userId),
        expected: 'Other User is typing…');

      await checkTyping(tester,
        eg.typingEvent(topicNarrow, TypingOp.start, eg.thirdUser.userId),
        expected: 'Other User and Third User are typing…');

      await store.setMutedUsers([eg.otherUser.userId]);
      await tester.pump();

      await checkTyping(tester,
        eg.typingEvent(topicNarrow, TypingOp.start, eg.thirdUser.userId),
        expected: 'Third User is typing…', // no "Other User"
      );

      // Wait for the pending timers to end.
      await tester.pump(const Duration(seconds: 15));
    });
  });

  group('MarkAsReadWidget', () {
    bool isMarkAsReadButtonVisible(WidgetTester tester) {
      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
      final finder = find.text(
        zulipLocalizations.markAllAsReadLabel).hitTestable();
      return finder.evaluate().isNotEmpty;
    }

    testWidgets('from read to unread', (tester) async {
      final message = eg.streamMessage(flags: [MessageFlag.read]);
      await setupMessageListPage(tester, messages: [message]);
      check(isMarkAsReadButtonVisible(tester)).isFalse();

      await store.handleEvent(eg.updateMessageFlagsRemoveEvent(
        MessageFlag.read, [message]));
      await tester.pumpAndSettle();
      check(isMarkAsReadButtonVisible(tester)).isTrue();
    });

    testWidgets('from unread to read', (tester) async {
      final message = eg.streamMessage(flags: []);
      final unreadMsgs = eg.unreadMsgs(channels:[
        UnreadChannelSnapshot(topic: message.topic, streamId: message.streamId, unreadMessageIds: [message.id])
      ]);
      await setupMessageListPage(tester, messages: [message], unreadMsgs: unreadMsgs);
      check(isMarkAsReadButtonVisible(tester)).isTrue();

      await store.handleEvent(UpdateMessageFlagsAddEvent(
        id: 1,
        flag: MessageFlag.read,
        messages: [message.id],
        all: false,
      ));
      await tester.pumpAndSettle();
      check(isMarkAsReadButtonVisible(tester)).isFalse();
    });

    testWidgets("messages don't shift position", (tester) async {
      final message = eg.streamMessage(flags: []);
      final unreadMsgs = eg.unreadMsgs(channels:[
        UnreadChannelSnapshot(topic: message.topic, streamId: message.streamId,
          unreadMessageIds: [message.id])
      ]);
      await setupMessageListPage(tester,
        messages: [message], unreadMsgs: unreadMsgs);
      check(isMarkAsReadButtonVisible(tester)).isTrue();
      check(tester.widgetList(find.byType(MessageItem))).length.equals(1);
      final before = tester.getTopLeft(find.byType(MessageItem)).dy;

      await store.handleEvent(UpdateMessageFlagsAddEvent(
        id: 1,
        flag: MessageFlag.read,
        messages: [message.id],
        all: false,
      ));
      await tester.pumpAndSettle();
      check(isMarkAsReadButtonVisible(tester)).isFalse();
      check(tester.widgetList(find.byType(MessageItem))).length.equals(1);
      final after = tester.getTopLeft(find.byType(MessageItem)).dy;
      check(after).equals(before);
    });

    group('onPressed behavior', () {
      // The markNarrowAsRead function has detailed unit tests of its own.
      // These tests cover functionality that's outside that function,
      // and a couple of smoke tests showing this button is wired up to it.

      final message = eg.streamMessage(flags: []);
      final unreadMsgs = eg.unreadMsgs(channels: [
        UnreadChannelSnapshot(streamId: message.streamId, topic: message.topic,
          unreadMessageIds: [message.id]),
      ]);

      group('MarkAsReadAnimation', () {
        void checkAppearsLoading(WidgetTester tester, bool expected) {
          final semantics = tester.firstWidget<Semantics>(find.descendant(
            of: find.byType(MarkAsReadWidget),
            matching: find.byType(Semantics)));
          check(semantics.properties.enabled).equals(!expected);

          final opacity = tester.widget<AnimatedOpacity>(find.descendant(
            of: find.byType(MarkAsReadWidget),
            matching: find.byType(AnimatedOpacity)));
          check(opacity.opacity).equals(expected ? 0.5 : 1.0);
        }

        testWidgets('loading is changed correctly', (tester) async {
          final narrow = TopicNarrow.ofMessage(message);
          await setupMessageListPage(tester,
            narrow: narrow, messages: [message], unreadMsgs: unreadMsgs);
          check(isMarkAsReadButtonVisible(tester)).isTrue();

          connection.prepare(
            delay: const Duration(milliseconds: 2000),
            json: UpdateMessageFlagsForNarrowResult(
              processedCount: 11, updatedCount: 3,
              firstProcessedId: null, lastProcessedId: null,
              foundOldest: true, foundNewest: true).toJson());

          checkAppearsLoading(tester, false);

          await tester.tap(find.byType(MarkAsReadWidget));
          await tester.pump();
          checkAppearsLoading(tester, true);

          await tester.pump(const Duration(milliseconds: 2000));
          checkAppearsLoading(tester, false);
        });

        testWidgets('loading is changed correctly if request fails', (tester) async {
          final narrow = TopicNarrow.ofMessage(message);
          await setupMessageListPage(tester,
            narrow: narrow, messages: [message], unreadMsgs: unreadMsgs);
          check(isMarkAsReadButtonVisible(tester)).isTrue();
          checkAppearsLoading(tester, false);

          connection.prepare(
            apiException: eg.apiBadRequest(message: 'Invalid message(s)'));
          await tester.tap(find.byType(MarkAsReadWidget));
          await tester.pump();
          checkAppearsLoading(tester, true);

          await tester.pump(const Duration(milliseconds: 2000));
          checkAppearsLoading(tester, false);
        });
      });

      testWidgets('smoke test on modern server', (tester) async {
        final narrow = TopicNarrow.ofMessage(message);
        await setupMessageListPage(tester,
          narrow: narrow, messages: [message], unreadMsgs: unreadMsgs);
        check(isMarkAsReadButtonVisible(tester)).isTrue();

        connection.prepare(json: UpdateMessageFlagsForNarrowResult(
          processedCount: 11, updatedCount: 3,
          firstProcessedId: null, lastProcessedId: null,
          foundOldest: true, foundNewest: true).toJson());
        await tester.tap(find.byType(MarkAsReadWidget));
        final apiNarrow = narrow.apiEncode()..add(ApiNarrowIs(IsOperand.unread));
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/messages/flags/narrow')
          ..bodyFields.deepEquals({
              'anchor': 'oldest',
              'include_anchor': 'false',
              'num_before': '0',
              'num_after': '1000',
              'narrow': jsonEncode(resolveApiNarrowForServer(apiNarrow, connection.zulipFeatureLevel!)),
              'op': 'add',
              'flag': 'read',
            });

        await tester.pumpAndSettle(); // process pending timers
      });

      testWidgets('pagination', (tester) async {
        // Check that `lastProcessedId` returned from an initial
        // response is used as `anchorId` for the subsequent request.
        final narrow = TopicNarrow.ofMessage(message);
        await setupMessageListPage(tester,
          narrow: narrow, messages: [message], unreadMsgs: unreadMsgs);
        check(isMarkAsReadButtonVisible(tester)).isTrue();

        connection.prepare(json: UpdateMessageFlagsForNarrowResult(
          processedCount: 1000, updatedCount: 890,
          firstProcessedId: 1, lastProcessedId: 1989,
          foundOldest: true, foundNewest: false).toJson());
        await tester.tap(find.byType(MarkAsReadWidget));
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/messages/flags/narrow')
          ..bodyFields['anchor'].equals('oldest');

        connection.prepare(json: UpdateMessageFlagsForNarrowResult(
          processedCount: 20, updatedCount: 10,
          firstProcessedId: 2000, lastProcessedId: 2023,
          foundOldest: false, foundNewest: true).toJson());
        await tester.pumpAndSettle();
        check(find.bySubtype<SnackBar>().evaluate()).length.equals(1);
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/messages/flags/narrow')
          ..bodyFields['anchor'].equals('1989');
      });

      testWidgets('markNarrowAsRead on mark-all-as-read when Unreads.oldUnreadsMissing: true', (tester) async {
        const narrow = CombinedFeedNarrow();
        await setupMessageListPage(tester,
          narrow: narrow, messages: [message], unreadMsgs: unreadMsgs);
        check(isMarkAsReadButtonVisible(tester)).isTrue();
        store.unreads.oldUnreadsMissing = true;

        connection.prepare(json: UpdateMessageFlagsForNarrowResult(
          processedCount: 11, updatedCount: 3,
          firstProcessedId: null, lastProcessedId: null,
          foundOldest: true, foundNewest: true).toJson());
        await tester.tap(find.byType(MarkAsReadWidget));
        await tester.pumpAndSettle();
        check(store.unreads.oldUnreadsMissing).isFalse();
      });

      testWidgets('catch-all api errors', (tester) async {
        final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
        const narrow = CombinedFeedNarrow();
        await setupMessageListPage(tester,
          narrow: narrow, messages: [message], unreadMsgs: unreadMsgs);
        check(isMarkAsReadButtonVisible(tester)).isTrue();

        connection.prepare(httpException: http.ClientException('Oops'));
        await tester.tap(find.byType(MarkAsReadWidget));
        await tester.pumpAndSettle();
        checkErrorDialog(tester,
          expectedTitle: zulipLocalizations.errorMarkAsReadFailedTitle,
          expectedMessage: 'NetworkException: Oops (ClientException: Oops)');
      });
    });
  });

  group('Update Narrow on message move', () {
    const topic = 'foo';
    final channel = eg.stream();
    final subscription = eg.subscription(channel);
    final otherChannel = eg.stream();
    final otherSubscription = eg.subscription(otherChannel);
    final narrow = eg.topicNarrow(channel.streamId, topic);

    void prepareGetMessageResponse(List<Message> messages) {
      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: false, messages: messages).toJson());
    }

    Future<void> handleMessageMoveEvent(List<StreamMessage> messages, String newTopic, {int? newChannelId}) async {
      await store.handleEvent(eg.updateMessageEventMoveFrom(
        origMessages: messages,
        newTopicStr: newTopic,
        newStreamId: newChannelId,
        propagateMode: PropagateMode.changeAll));
    }

    testWidgets('compose box send message after move', (tester) async {
      final message = eg.streamMessage(stream: channel, topic: topic, content: 'Message to move');
      await setupMessageListPage(tester,
        narrow: narrow,
        messages: [message],
        subscriptions: [subscription, otherSubscription]);

      final channelContentInputFinder = find.descendant(
        of: find.byType(ComposeAutocomplete),
        matching: find.byType(TextField));

      await tester.enterText(channelContentInputFinder, 'Some text');
      check(tester.widget<TextField>(channelContentInputFinder))
        ..decoration.isNotNull().hintText.equals('Message #${channel.name} > $topic')
        ..controller.isNotNull().text.equals('Some text');

      prepareGetMessageResponse([message]);
      await handleMessageMoveEvent([message], 'new topic', newChannelId: otherChannel.streamId);
      await tester.pump(const Duration(seconds: 1));
      check(tester.widget<TextField>(channelContentInputFinder))
        ..decoration.isNotNull().hintText.equals('Message #${otherChannel.name} > new topic')
        ..controller.isNotNull().text.equals('Some text');

      connection.prepare(json: SendMessageResult(id: 1).toJson());
      await tester.tap(find.byIcon(ZulipIcons.send));
      await tester.pump(Duration.zero);
      final localMessageId = store.outboxMessages.keys.single;
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages')
        ..bodyFields.deepEquals({
          'type': 'stream',
          'to': '${otherChannel.streamId}',
          'topic': 'new topic',
          'content': 'Some text',
          'read_by_sender': 'true',
          'queue_id': store.queueId,
          'local_id': localMessageId.toString()});
      // Remove the outbox message and its timers created when sending message.
      await store.handleEvent(
        eg.messageEvent(message, localMessageId: localMessageId));
    });

    testWidgets('Move to narrow with existing messages', (tester) async {
      final message = eg.streamMessage(stream: channel, topic: topic, content: 'Message to move');
      await setupMessageListPage(tester,
        narrow: narrow, messages: [message], subscriptions: [subscription]);
      check(find.textContaining('Existing message').evaluate()).length.equals(0);
      check(find.textContaining('Message to move').evaluate()).length.equals(1);

      final existingMessage = eg.streamMessage(
        stream: eg.stream(), topic: 'new topic', content: 'Existing message');
      prepareGetMessageResponse([existingMessage, message]);
      await handleMessageMoveEvent([message], 'new topic');
      await tester.pump(const Duration(seconds: 1));

      check(find.textContaining('Existing message').evaluate()).length.equals(1);
      check(find.textContaining('Message to move').evaluate()).length.equals(1);
    });

    testWidgets('show new topic in TopicNarrow after move', (tester) async {
      final message = eg.streamMessage(stream: channel, topic: topic, content: 'Message to move');
      await setupMessageListPage(tester,
        narrow: narrow, messages: [message], subscriptions: [subscription]);

      prepareGetMessageResponse([message]);
      await handleMessageMoveEvent([message], 'new topic');
      await tester.pump(const Duration(seconds: 1));

      check(find.descendant(
        of: find.byType(RecipientHeader),
        matching: find.text('new topic')).evaluate()
      ).length.equals(1);
      checkAppBarChannelTopic(channel.name, 'new topic');
    });
  });

  group('recipient headers', () {
    group('StreamMessageRecipientHeader', () {
      // Tests for the topic action sheet are in test/widgets/action_sheet_test.dart.

      final stream = eg.stream(name: 'stream name');
      const topic = 'topic name';
      final message = eg.streamMessage(stream: stream, topic: topic);

      FinderResult<Element> findInMessageList(String text) {
        // Stream name shows up in [AppBar] so need to avoid matching that
        return find.descendant(
          of: find.byType(MessageList),
          matching: find.text(text)).evaluate();
      }

      testWidgets('show stream name in CombinedFeedNarrow', (tester) async {
        await setupMessageListPage(tester,
          narrow: const CombinedFeedNarrow(),
          messages: [message], subscriptions: [eg.subscription(stream)]);
        await tester.pump();
        check(findInMessageList('stream name')).length.equals(1);
        check(findInMessageList('topic name')).length.equals(1);
      });

      testWidgets('show channel name in MentionsNarrow', (tester) async {
        await setupMessageListPage(tester,
          narrow: const MentionsNarrow(),
          messages: [message], subscriptions: [eg.subscription(stream)]);
        await tester.pump();
        check(findInMessageList('stream name')).length.equals(1);
        check(findInMessageList('topic name')).length.equals(1);
      });

      testWidgets('show channel name in StarredMessagesNarrow', (tester) async {
        await setupMessageListPage(tester,
          narrow: const StarredMessagesNarrow(),
          messages: [message], subscriptions: [eg.subscription(stream)]);
        await tester.pump();
        check(findInMessageList('stream name')).length.equals(1);
        check(findInMessageList('topic name')).length.equals(1);
      });

      testWidgets('do not show channel name in ChannelNarrow', (tester) async {
        await setupMessageListPage(tester,
          narrow: ChannelNarrow(stream.streamId),
          messages: [message], subscriptions: [eg.subscription(stream)]);
        await tester.pump();
        check(findInMessageList('stream name')).length.equals(0);
        check(findInMessageList('topic name')).length.equals(1);
      });

      testWidgets('do not show stream name in TopicNarrow', (tester) async {
        await setupMessageListPage(tester,
          narrow: TopicNarrow.ofMessage(message),
          messages: [message], subscriptions: [eg.subscription(stream)]);
        await tester.pump();
        check(findInMessageList('stream name')).length.equals(0);
        check(findInMessageList('topic name')).length.equals(1);
      });

      final messageEmptyTopic = eg.streamMessage(stream: stream, topic: '');

      testWidgets('show general chat for empty topics with channel name', (tester) async {
        await setupMessageListPage(tester,
          narrow: const CombinedFeedNarrow(),
          messages: [messageEmptyTopic], subscriptions: [eg.subscription(stream)]);
        await tester.pump();
        check(findInMessageList('stream name')).single;
        check(findInMessageList(eg.defaultRealmEmptyTopicDisplayName)).single;
      });

      testWidgets('show general chat for empty topics without channel name', (tester) async {
        await setupMessageListPage(tester,
          narrow: TopicNarrow.ofMessage(messageEmptyTopic),
          messages: [messageEmptyTopic]);
        await tester.pump();
        check(findInMessageList('stream name')).isEmpty();
        check(findInMessageList(eg.defaultRealmEmptyTopicDisplayName)).single;
      });

      testWidgets('show topic visibility icon when followed', (tester) async {
        await setupMessageListPage(tester,
          narrow: const CombinedFeedNarrow(),
          messages: [message], subscriptions: [eg.subscription(stream)]);
        await store.handleEvent(eg.userTopicEvent(
          stream.streamId, topic, UserTopicVisibilityPolicy.followed));
        await tester.pump();
        check(find.descendant(
          of: find.byType(MessageList),
          matching: find.byIcon(ZulipIcons.follow))).findsOne();
      });

      testWidgets('show topic visibility icon when unmuted', (tester) async {
        await setupMessageListPage(tester,
          narrow: TopicNarrow.ofMessage(message),
          messages: [message], subscriptions: [eg.subscription(stream, isMuted: true)]);
        await store.handleEvent(eg.userTopicEvent(
          stream.streamId, topic, UserTopicVisibilityPolicy.unmuted));
        await tester.pump();
        check(find.descendant(
          of: find.byType(MessageList),
          matching: find.byIcon(ZulipIcons.unmute))).findsOne();
      });

      testWidgets('color of recipient header background', (tester) async {
        final subscription = eg.subscription(stream, color: Colors.red.argbInt);
        final swatch = ChannelColorSwatch.light(subscription.color);
        await setupMessageListPage(tester,
          messages: [eg.streamMessage(stream: subscription)],
          subscriptions: [subscription]);
        await tester.pump();
        check(tester.widget<ColoredBox>(
          find.descendant(
            of: find.byType(StreamMessageRecipientHeader),
            matching: find.byType(ColoredBox),
        ))).color.isNotNull().isSameColorAs(swatch.barBackground);
      });

      testWidgets('color of stream icon', (tester) async {
        final stream = eg.stream(isWebPublic: true);
        final subscription = eg.subscription(stream, color: Colors.red.argbInt);
        final swatch = ChannelColorSwatch.light(subscription.color);
        await setupMessageListPage(tester,
          messages: [eg.streamMessage(stream: subscription)],
          subscriptions: [subscription]);
        await tester.pump();
        check(tester.widget<Icon>(find.byIcon(ZulipIcons.globe)))
          .color.isNotNull().isSameColorAs(swatch.iconOnBarBackground);
      });

      testWidgets('normal streams show hash icon', (tester) async {
        final stream = eg.stream(isWebPublic: false, inviteOnly: false);
        await setupMessageListPage(tester,
          messages: [eg.streamMessage(stream: stream)],
          subscriptions: [eg.subscription(stream)]);
        await tester.pump();
        check(find.descendant(
          of: find.byType(StreamMessageRecipientHeader),
          matching: find.byIcon(ZulipIcons.hash_sign),
        ).evaluate()).length.equals(1);
      });

      testWidgets('public streams show globe icon', (tester) async {
        final stream = eg.stream(isWebPublic: true);
        await setupMessageListPage(tester,
          messages: [eg.streamMessage(stream: stream)],
          subscriptions: [eg.subscription(stream)]);
        await tester.pump();
        check(find.descendant(
          of: find.byType(StreamMessageRecipientHeader),
          matching: find.byIcon(ZulipIcons.globe),
        ).evaluate()).length.equals(1);
      });

      testWidgets('private streams show lock icon', (tester) async {
        final stream = eg.stream(inviteOnly: true);
        await setupMessageListPage(tester,
          messages: [eg.streamMessage(stream: stream)],
          subscriptions: [eg.subscription(stream)]);
        await tester.pump();
        check(find.descendant(
          of: find.byType(StreamMessageRecipientHeader),
          matching: find.byIcon(ZulipIcons.lock),
        ).evaluate()).length.equals(1);
      });

      testWidgets('show stream name from message when stream unknown', (tester) async {
        // This can perfectly well happen, because message fetches can race
        // with events.
        // … Though not actually with CombinedFeedNarrow, because that shows
        // stream messages only in subscribed streams, hence only known streams.
        // See skip comment below.
        final stream = eg.stream(name: 'stream name');
        await setupMessageListPage(tester,
          narrow: const CombinedFeedNarrow(),
          subscriptions: [],
          messages: [
            eg.streamMessage(stream: stream),
          ]);
        await tester.pump();
        tester.widget(find.text('stream name'));
      }, skip: true); // TODO(#252) could repro this with search narrows, once we have those

      testWidgets('show stream name from stream data when known', (tester) async {
        final streamBefore = eg.stream(name: 'old stream name');
        // TODO(#182) this test would be more realistic using a ChannelUpdateEvent
        final streamAfter = ZulipStream.fromJson({
          ...(deepToJson(streamBefore) as Map<String, dynamic>),
          'name': 'new stream name',
        });
        await setupMessageListPage(tester,
          narrow: const CombinedFeedNarrow(),
          subscriptions: [eg.subscription(streamAfter)],
          messages: [
            eg.streamMessage(stream: streamBefore),
          ]);
        await tester.pump();
        tester.widget(find.text('new stream name'));
      });

      testWidgets('navigates to ChannelNarrow on tapping channel in CombinedFeedNarrow', (tester) async {
        final pushedRoutes = <Route<void>>[];
        final navObserver = TestNavigatorObserver()
          ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
        final channel = eg.stream();
        final subscription = eg.subscription(channel);
        final message = eg.streamMessage(stream: channel, topic: 'topic name');
        await setupMessageListPage(tester,
          narrow: CombinedFeedNarrow(),
          subscriptions: [subscription],
          messages: [message],
          navObservers: [navObserver]);

        assert(pushedRoutes.length == 1);
        pushedRoutes.clear();

        connection.prepare(json: eg.newestGetMessagesResult(
          foundOldest: true, messages: [message]).toJson());
        await tester.tap(find.descendant(
          of: find.byType(StreamMessageRecipientHeader),
          matching: find.text(channel.name)));
        await tester.pump();
        check(pushedRoutes).single.isA<WidgetRoute>().page.isA<MessageListPage>()
          .initNarrow.equals(ChannelNarrow(channel.streamId));
        await tester.pumpAndSettle();
      });

      testWidgets('navigates to TopicNarrow on tapping topic in ChannelNarrow', (tester) async {
        final pushedRoutes = <Route<void>>[];
        final navObserver = TestNavigatorObserver()
          ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
        final channel = eg.stream();
        final message = eg.streamMessage(stream: channel, topic: 'topic name');
        await setupMessageListPage(tester,
          narrow: ChannelNarrow(channel.streamId),
          subscriptions: [eg.subscription(channel)],
          messages: [message],
          navObservers: [navObserver]);

        assert(pushedRoutes.length == 1);
        pushedRoutes.clear();

        connection.prepare(json: eg.newestGetMessagesResult(
          foundOldest: true, messages: [message]).toJson());
        await tester.tap(find.descendant(
          of: find.byType(StreamMessageRecipientHeader),
          matching: find.text('topic name')));
        await tester.pump();
        check(pushedRoutes).single.isA<WidgetRoute>().page.isA<MessageListPage>()
          .initNarrow.equals(TopicNarrow.ofMessage(message));
        await tester.pumpAndSettle();
      });

      testWidgets('does not navigate on tapping topic in TopicNarrow', (tester) async {
        final pushedRoutes = <Route<void>>[];
        final navObserver = TestNavigatorObserver()
          ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
        final channel = eg.stream();
        final message = eg.streamMessage(stream: channel, topic: 'topic name');
        await setupMessageListPage(tester,
          narrow: TopicNarrow.ofMessage(message),
          subscriptions: [eg.subscription(channel)],
          messages: [message],
          navObservers: [navObserver]);

        assert(pushedRoutes.length == 1);
        pushedRoutes.clear();

        await tester.tap(find.descendant(
          of: find.byType(StreamMessageRecipientHeader),
          matching: find.text('topic name')));
        await tester.pump();
        check(pushedRoutes).isEmpty();
      });
    });

    group('DmRecipientHeader', () {
      testWidgets('show names', (tester) async {
        final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
        await setupMessageListPage(tester, messages: [
          eg.dmMessage(from: eg.selfUser, to: []),
          eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]),
          eg.dmMessage(from: eg.thirdUser, to: [eg.selfUser, eg.otherUser]),
        ]);
        await store.addUser(eg.otherUser);
        await store.addUser(eg.thirdUser);
        await tester.pump();
        tester.widget(find.text(zulipLocalizations.messageListGroupYouWithYourself));
        tester.widget(find.text(zulipLocalizations.messageListGroupYouAndOthers(
          eg.otherUser.fullName)));
        tester.widget(find.text(zulipLocalizations.messageListGroupYouAndOthers(
          "${eg.otherUser.fullName}, ${eg.thirdUser.fullName}")));
      });

      testWidgets('show names: smoothly handle unknown users', (tester) async {
        final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
        await setupMessageListPage(tester, messages: [
          eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]),
          eg.dmMessage(from: eg.thirdUser, to: [eg.selfUser, eg.otherUser]),
        ]);
        await store.addUser(eg.thirdUser);
        await tester.pump();
        tester.widget(find.text(zulipLocalizations.messageListGroupYouAndOthers(
          zulipLocalizations.unknownUserName)));
        tester.widget(find.text(zulipLocalizations.messageListGroupYouAndOthers(
          "${zulipLocalizations.unknownUserName}, ${eg.thirdUser.fullName}")));
      });

      testWidgets('show "Muted user" label for muted users', (tester) async {
        final user1 = eg.user(userId: 1, fullName: 'User 1');
        final user2 = eg.user(userId: 2, fullName: 'User 2');
        final user3 = eg.user(userId: 3, fullName: 'User 3');
        final mutedUsers = [1, 3];

        await setupMessageListPage(tester,
          users: [user1, user2, user3],
          mutedUserIds: mutedUsers,
          messages: [eg.dmMessage(from: eg.selfUser, to: [user1, user2, user3])]
        );

        check(find.text('You and Muted user, Muted user, User 2')).findsOne();
      });

      testWidgets('icon color matches text color', (tester) async {
        final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
        await setupMessageListPage(tester, messages: [
          eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]),
        ]);
        await tester.pump();
        final textSpan = tester.renderObject<RenderParagraph>(find.text(
          zulipLocalizations.messageListGroupYouAndOthers(
            zulipLocalizations.unknownUserName))).text;
        final icon = tester.widget<Icon>(find.byIcon(ZulipIcons.two_person));
        check(textSpan).style.isNotNull().color.isNotNull().isSameColorAs(icon.color!);
      });
    });

    testWidgets('show dates', (tester) async {
      await setupMessageListPage(tester, messages: [
        eg.streamMessage(timestamp: 1671409088),
        eg.dmMessage(timestamp: 1661219322, from: eg.selfUser, to: []),
      ]);
      // We show the dates in the user's timezone.  Dart's standard library
      // doesn't give us a way to control which timezone is used — only to
      // choose between UTC and the user's timezone, whatever that may be.
      // So we do the latter, and that means these dates come out differently
      // depending on the timezone in the environment running the tests.
      // Related upstream issues:
      //   https://github.com/dart-lang/sdk/issues/28985 (about DateTime.now, not timezone)
      //   https://github.com/dart-lang/sdk/issues/44928 (about the Dart implementation's own internal tests)
      // For this test, just accept outputs corresponding to any possible timezone.
      tester.widget(find.textContaining(RegExp("Dec 1[89], 2022")));
      tester.widget(find.textContaining(RegExp("Aug 2[23], 2022")));
    });

    testWidgets('navigates to DmNarrow on tapping recipient header in CombinedFeedNarrow', (tester) async {
      final pushedRoutes = <Route<void>>[];
      final navObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      final dmMessage = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]);
      await setupMessageListPage(tester,
        narrow: const CombinedFeedNarrow(),
        messages: [dmMessage],
        navObservers: [navObserver]);

      assert(pushedRoutes.length == 1);
      pushedRoutes.clear();

      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true, messages: [dmMessage]).toJson());
      await tester.tap(find.byType(DmRecipientHeader));
      await tester.pump();
      check(pushedRoutes).single.isA<WidgetRoute>().page.isA<MessageListPage>()
        .initNarrow.equals(DmNarrow.withUser(eg.otherUser.userId, selfUserId: eg.selfUser.userId));
      await tester.pumpAndSettle();
    });

    testWidgets('does not navigate on tapping recipient header in DmNarrow', (tester) async {
      final pushedRoutes = <Route<void>>[];
      final navObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      final dmMessage = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]);
      await setupMessageListPage(tester,
        narrow: DmNarrow.withUser(eg.otherUser.userId, selfUserId: eg.selfUser.userId),
        messages: [dmMessage],
        navObservers: [navObserver]);

      assert(pushedRoutes.length == 1);
      pushedRoutes.clear();

      await tester.tap(find.byType(DmRecipientHeader));
      await tester.pump();
      check(pushedRoutes).isEmpty();
    });
  });

  group('MessageTimestampStyle', () {
    void doTests(
      MessageTimestampStyle style,
      List<(
        String timestampStr,
        String? expectedTwelveHour,
        String? expectedTwentyFourHour,
      )> cases, {
      DateTime? now,
    }) {
      now ??= DateTime.parse("2023-01-10 12:00");
      for (final (timestampStr, expectedTwelveHour, expectedTwentyFourHour) in cases) {
        for (final mode in TwentyFourHourTimeMode.values) {
          final expected = switch (mode) {
            TwentyFourHourTimeMode.twelveHour => expectedTwelveHour,
            TwentyFourHourTimeMode.twentyFourHour => expectedTwentyFourHour,
            // This expectation will hold as long as we're always using the
            // default locale, en_US, which uses the twelve-hour format.
            // TODO(#1727) test with other locales
            TwentyFourHourTimeMode.localeDefault => expectedTwelveHour,
          };

          test('${style.name} in ${mode.name}: $timestampStr returns $expected', () {
            addTearDown(testBinding.reset);
            final zulipLocalizations = GlobalLocalizations.zulipLocalizations;

            withClock(Clock.fixed(now!), () {
              final timestamp = DateTime.parse(timestampStr)
                .millisecondsSinceEpoch ~/ 1000;
              final result = style.format(
                timestamp,
                now: testBinding.utcNow().toLocal(),
                twentyFourHourTimeMode: mode,
                zulipLocalizations: zulipLocalizations);
              check(result).equals(expected);
            });
          });
        }
      }
    }

    for (final style in MessageTimestampStyle.values) {
      switch (style) {
        case MessageTimestampStyle.none:
          doTests(style, [('2023-01-10 12:00', null, null)]);
        case MessageTimestampStyle.dateOnlyRelative:
          final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
          doTests(style,
            now: DateTime.parse("2023-01-10 12:00"),
            [
              ("2023-01-10 12:00", zulipLocalizations.today,     zulipLocalizations.today),
              ("2023-01-10 00:00", zulipLocalizations.today,     zulipLocalizations.today),
              ("2023-01-10 23:59", zulipLocalizations.today,     zulipLocalizations.today),
              ("2023-01-09 23:59", zulipLocalizations.yesterday, zulipLocalizations.yesterday),
              ("2023-01-09 00:00", zulipLocalizations.yesterday, zulipLocalizations.yesterday),
              ("2023-01-08 00:00", "Jan 8", "Jan 8"),
              ("2022-12-31 00:00", "Dec 31, 2022", "Dec 31, 2022"),
              // Future times
              ("2023-01-10 19:00", zulipLocalizations.today, zulipLocalizations.today),
              ("2023-01-11 00:00", "Jan 11, 2023", "Jan 11, 2023"),
            ]);
        case MessageTimestampStyle.timeOnly:
          doTests(style, [('2023-01-10 12:00', '12:00 PM', '12:00')]);
        case MessageTimestampStyle.lightbox:
          doTests(style,
            [('2023-01-10 12:00',
              'Jan 10, 2023 12:00:00 PM',
              'Jan 10, 2023 12:00:00')]);
        case MessageTimestampStyle.full:
          doTests(style,
            [('2023-01-10 12:00',
              'Jan 10, 2023 12:00 PM',
              'Jan 10, 2023 12:00')]);
      }
    }
  });

  group('MessageWithPossibleSender', () {
    testWidgets('known user', (tester) async {
      final user = eg.user(fullName: 'Old Name');
      await setupMessageListPage(tester,
        messages: [eg.streamMessage(sender: user)],
        users: [user]);

      check(find.widgetWithText(MessageWithPossibleSender, 'Old Name')).findsOne();

      // If the user's name changes, the sender row should update.
      await store.handleEvent(RealmUserUpdateEvent(id: 1,
        userId: user.userId, fullName: 'New Name'));
      await tester.pump();
      check(find.widgetWithText(MessageWithPossibleSender, 'New Name')).findsOne();
    });

    testWidgets('unknown user', (tester) async {
      final user = eg.user(fullName: 'Some User');
      await setupMessageListPage(tester, messages: [eg.streamMessage(sender: user)]);
      check(store.getUser(user.userId)).isNull();

      // The sender row should fall back to the name in the message.
      check(find.widgetWithText(MessageWithPossibleSender, 'Some User')).findsOne();
    });

    testWidgets('Updates avatar on RealmUserUpdateEvent', (tester) async {
      addTearDown(testBinding.reset);

      // TODO recognize avatar more reliably:
      //   https://github.com/zulip/zulip-flutter/pull/246#discussion_r1282516308
      RealmContentNetworkImage? findAvatarImageWidget(WidgetTester tester) {
        return tester.widgetList<RealmContentNetworkImage>(
          find.descendant(
            of: find.byType(MessageWithPossibleSender),
            matching: find.byType(RealmContentNetworkImage))).firstOrNull;
      }

      void checkResultForSender(String? avatarUrl) {
        if (avatarUrl == null) {
          check(findAvatarImageWidget(tester)).isNull();
        } else {
          check(findAvatarImageWidget(tester)).isNotNull()
            .src.equals(eg.selfAccount.realmUrl.resolve(avatarUrl));
        }
      }

      final user = eg.user();

      Future<void> handleNewAvatarEventAndPump(WidgetTester tester, String avatarUrl) async {
        await store.handleEvent(RealmUserUpdateEvent(id: 1, userId: user.userId, avatarUrl: avatarUrl));
        await tester.pump();
      }

      prepareBoringImageHttpClient();

      await setupMessageListPage(tester, users: [user],
        messages: [eg.streamMessage(sender: user)]);
      checkResultForSender(user.avatarUrl);

      await handleNewAvatarEventAndPump(tester, '/foo.png');
      checkResultForSender('/foo.png');

      await handleNewAvatarEventAndPump(tester, '/bar.jpg');
      checkResultForSender('/bar.jpg');

      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('Bot user is distinguished by showing an icon', (tester) async {
      // When using this function, provide only one bot user
      // to [PerAccountStore] through [setupMessageListPage] function.
      void checkUser(User user, {required bool isBot}) {
        final nameFinder = find.text(user.fullName);
        final botFinder = find.byIcon(ZulipIcons.bot);

        check(nameFinder.evaluate().singleOrNull).isNotNull();
        check(botFinder.evaluate().singleOrNull).isNotNull();

        final userFinder = find.ancestor(
          of: nameFinder,
          matching: find.ancestor(
            of: botFinder,
            matching: find.byType(Row),
          ));

        isBot
          ? check(userFinder.evaluate()).isNotEmpty()
          : check(userFinder.evaluate()).isEmpty();
      }

      prepareBoringImageHttpClient();

      final users = [
        eg.user(fullName: 'User 1', isBot: true),
        eg.user(fullName: 'User 2', isBot: false),
        eg.user(fullName: 'User 3', isBot: false),
      ];

      await setupMessageListPage(
        tester,
        messages: users.map((user) => eg.streamMessage(sender: user)).toList(),
        users: users,
      );

      checkUser(users[0], isBot: true);
      checkUser(users[1], isBot: false);
      checkUser(users[2], isBot: false);

      debugNetworkImageHttpClientProvider = null;
    });

    group('User status', () {
      void checkFindsStatusEmoji(WidgetTester tester, Finder emojiFinder) {
        final statusEmojiFinder = find.ancestor(of: emojiFinder,
          matching: find.byType(UserStatusEmoji));
        check(statusEmojiFinder).findsOne();
        check(tester.widget<UserStatusEmoji>(statusEmojiFinder)
          .animationMode).equals(ImageAnimationMode.animateNever);
        check(find.ancestor(of: statusEmojiFinder,
          matching: find.byType(SenderRow))).findsOne();
      }

      testWidgets('emoji (unicode) & text are set -> emoji is displayed, text is not', (tester) async {
        final user = eg.user();
        await setupMessageListPage(tester,
          users: [user], messages: [eg.streamMessage(sender: user)]);
        await store.changeUserStatus(user.userId, UserStatusChange(
          text: OptionSome('Busy'),
          emoji: OptionSome(StatusEmoji(emojiName: 'working_on_it',
            emojiCode: '1f6e0', reactionType: ReactionType.unicodeEmoji))));
        await tester.pump();

        checkFindsStatusEmoji(tester, find.text('\u{1f6e0}'));
        check(find.textContaining('Busy')).findsNothing();
      });

      testWidgets('emoji (image) & text are set -> emoji is displayed, text is not', (tester) async {
        prepareBoringImageHttpClient();

        final user = eg.user();
        await setupMessageListPage(tester,
          users: [user], messages: [eg.streamMessage(sender: user)]);
        await store.changeUserStatus(user.userId, UserStatusChange(
          text: OptionSome('Coding'),
          emoji: OptionSome(StatusEmoji(emojiName: 'zulip',
            emojiCode: 'zulip', reactionType: ReactionType.zulipExtraEmoji))));
        await tester.pump();

        checkFindsStatusEmoji(tester, find.byType(Image));
        check(find.textContaining('Coding')).findsNothing();

        debugNetworkImageHttpClientProvider = null;
      });

      testWidgets('longer user name -> emoji stays visible', (tester) async {
        final user = eg.user(fullName: 'User with a very very very long name to check if emoji is still visible');
        await setupMessageListPage(tester,
          users: [user], messages: [eg.streamMessage(sender: user)]);
        await store.changeUserStatus(user.userId, UserStatusChange(
          text: OptionNone(),
          emoji: OptionSome(StatusEmoji(emojiName: 'working_on_it',
            emojiCode: '1f6e0', reactionType: ReactionType.unicodeEmoji))));
        await tester.pump();

        checkFindsStatusEmoji(tester, find.text('\u{1f6e0}'));
      });

      testWidgets('emoji is not set, text is set -> text is not displayed', (tester) async {
        final user = eg.user();
        await setupMessageListPage(tester,
          users: [user], messages: [eg.streamMessage(sender: user)]);
        await store.changeUserStatus(user.userId, UserStatusChange(
          text: OptionSome('Busy'), emoji: OptionNone()));
        await tester.pump();

        check(find.textContaining('Busy')).findsNothing();
      });
    });

    group('Muted sender', () {
      void checkMessage(Message message, {required bool expectIsMuted}) {
        final mutedLabel = 'Muted user';
        final mutedLabelFinder = find.widgetWithText(MessageWithPossibleSender,
          mutedLabel);

        final avatarFinder = find.byWidgetPredicate(
          (widget) => widget is Avatar && widget.userId == message.senderId);
        final mutedAvatarFinder = find.descendant(
          of: avatarFinder,
          matching: find.byIcon(ZulipIcons.person));
        final nonmutedAvatarFinder = find.descendant(
          of: avatarFinder,
          matching: find.byType(RealmContentNetworkImage));

        final senderName = store.senderDisplayName(message, replaceIfMuted: false);
        assert(senderName != mutedLabel);
        final senderNameFinder = find.widgetWithText(MessageWithPossibleSender,
          senderName);

        final contentFinder = find.descendant(
          of: find.byType(MessageContent),
          matching: find.text('A message', findRichText: true));

        check(mutedLabelFinder.evaluate().length).equals(expectIsMuted ? 1 : 0);
        check(senderNameFinder.evaluate().length).equals(expectIsMuted ? 0 : 1);
        check(mutedAvatarFinder.evaluate().length).equals(expectIsMuted ? 1 : 0);
        check(nonmutedAvatarFinder.evaluate().length).equals(expectIsMuted ? 0 : 1);
        check(contentFinder.evaluate().length).equals(expectIsMuted ? 0 : 1);
      }

      final user = eg.user(userId: 1, fullName: 'User', avatarUrl: '/foo.png');
      final message = eg.streamMessage(sender: user,
        content: '<p>A message</p>', reactions: [eg.unicodeEmojiReaction]);

      testWidgets('muted appearance', (tester) async {
        prepareBoringImageHttpClient();
        await setupMessageListPage(tester,
          users: [user], mutedUserIds: [user.userId], messages: [message]);
        checkMessage(message, expectIsMuted: true);
        debugNetworkImageHttpClientProvider = null;
      });

      testWidgets('not-muted appearance', (tester) async {
        prepareBoringImageHttpClient();
        await setupMessageListPage(tester,
          users: [user], mutedUserIds: [], messages: [message]);
        checkMessage(message, expectIsMuted: false);
        debugNetworkImageHttpClientProvider = null;
      });

      testWidgets('"Reveal message" button', (tester) async {
        prepareBoringImageHttpClient();

        await setupMessageListPage(tester,
          users: [user], mutedUserIds: [user.userId], messages: [message]);
        checkMessage(message, expectIsMuted: true);
        await tester.tap(find.text('Reveal message'));
        await tester.pump();
        checkMessage(message, expectIsMuted: false);

        debugNetworkImageHttpClientProvider = null;
      });
    });

    group('Opens conversation on tap?', () {
      // (copied from test/widgets/content_test.dart)
      Future<void> tapText(WidgetTester tester, Finder textFinder) async {
        final height = tester.getSize(textFinder).height;
        final target = tester.getTopLeft(textFinder)
          .translate(height/4, height/2); // aim for middle of first letter
        await tester.tapAt(target);
      }

      final subscription = eg.subscription(eg.stream(streamId: eg.defaultStreamMessageStreamId));
      final topic = 'some topic';

      void doTest(Narrow narrow, {
        required bool expected,
        required Message Function() mkMessage,
      }) {
        testWidgets('${expected ? 'yes' : 'no'}, if in $narrow', (tester) async {
          final message = mkMessage();

          Route<dynamic>? lastPushedRoute;
          final navObserver = TestNavigatorObserver()
            ..onPushed = ((route, prevRoute) => lastPushedRoute = route);

          await setupMessageListPage(
            tester,
            narrow: narrow,
            messages: [message],
            subscriptions: [subscription],
            navObservers: [navObserver]
          );
          lastPushedRoute = null;

          // Tapping interactive content still works.
          await store.handleEvent(eg.updateMessageEditEvent(message,
            renderedContent: '<p><a href="https://example/">link</a></p>'));
          await tester.pump();
          await tapText(tester, find.text('link'));
          await tester.pump(Duration.zero);
          check(lastPushedRoute).isNull();
          final launchUrlCalls = testBinding.takeLaunchUrlCalls();
          check(launchUrlCalls.single.url).equals(Uri.parse('https://example/'));

          // Tapping non-interactive content opens the conversation (if expected).
          await store.handleEvent(eg.updateMessageEditEvent(message,
            renderedContent: '<p>plain content</p>'));
          await tester.pump();
          await tapText(tester, find.text('plain content'));
          if (expected) {
            final expectedNarrow = SendableNarrow.ofMessage(message, selfUserId: store.selfUserId);

            check(lastPushedRoute).isNotNull().isA<MaterialAccountWidgetRoute>()
              .page.isA<MessageListPage>()
                ..initNarrow.equals(expectedNarrow)
                ..initAnchorMessageId.equals(message.id);
          } else {
            check(lastPushedRoute).isNull();
          }

          // TODO test tapping whitespace in message
        });
      }

      doTest(expected: false, CombinedFeedNarrow(),
        mkMessage: () => eg.streamMessage());
      doTest(expected: false, ChannelNarrow(subscription.streamId),
        mkMessage: () => eg.streamMessage(stream: subscription));
      doTest(expected: false, TopicNarrow(subscription.streamId, eg.t(topic)),
        mkMessage: () => eg.streamMessage(stream: subscription));
      doTest(expected: false, DmNarrow.withUsers([], selfUserId: eg.selfUser.userId),
        mkMessage: () => eg.streamMessage(stream: subscription, topic: topic));
      doTest(expected: true, StarredMessagesNarrow(),
        mkMessage: () => eg.streamMessage(flags: [MessageFlag.starred]));
      doTest(expected: true, MentionsNarrow(),
        mkMessage: () => eg.streamMessage(flags: [MessageFlag.mentioned]));
    });
  });

  group('OutboxMessageWithPossibleSender', () {
    final stream = eg.stream();
    final topic = 'topic';
    final topicNarrow = eg.topicNarrow(stream.streamId, topic);
    const content = 'outbox message content';

    Finder outboxMessageFinder = find.widgetWithText(
      OutboxMessageWithPossibleSender, content, skipOffstage: true);

    Finder messageNotSentFinder = find.descendant(
      of: find.byType(OutboxMessageWithPossibleSender),
      matching: find.text('MESSAGE NOT SENT')).hitTestable();
    Finder loadingIndicatorFinder = find.descendant(
      of: find.byType(OutboxMessageWithPossibleSender),
      matching: find.byType(LinearProgressIndicator)).hitTestable();

    Future<void> sendMessageAndSucceed(WidgetTester tester, {
      Duration delay = Duration.zero,
    }) async {
      connection.prepare(json: SendMessageResult(id: 1).toJson(), delay: delay);
      await tester.enterText(contentInputFinder, content);
      await tester.tap(find.byIcon(ZulipIcons.send));
      await tester.pump(Duration.zero);
    }

    Future<void> sendMessageAndFail(WidgetTester tester, {
      Duration delay = Duration.zero,
    }) async {
      connection.prepare(httpException: SocketException('error'), delay: delay);
      await tester.enterText(contentInputFinder, content);
      await tester.tap(find.byIcon(ZulipIcons.send));
      await tester.pump(Duration.zero);
    }

    Future<void> dismissErrorDialog(WidgetTester tester) async {
      await tester.tap(find.byWidget(
        checkErrorDialog(tester, expectedTitle: 'Message not sent')));
      await tester.pump(Duration(milliseconds: 250));
    }

    Future<void> checkTapRestoreMessage(WidgetTester tester) async {
      final state = tester.state<ComposeBoxState>(find.byType(ComposeBox));
      check(store.outboxMessages).values.single;
      check(outboxMessageFinder).findsOne();
      check(messageNotSentFinder).findsOne();
      check(state).controller.content.text.isNotNull().isEmpty();

      // Tap the message.  This should put its content back into the compose box
      // and remove it.
      await tester.tap(outboxMessageFinder);
      await tester.pump();
      check(store.outboxMessages).isEmpty();
      check(outboxMessageFinder).findsNothing();
      check(state).controller.content.text.equals(content);
    }

    Future<void> checkTapNotRestoreMessage(WidgetTester tester) async {
      check(store.outboxMessages).values.single;
      check(outboxMessageFinder).findsOne();

      // the message should ignore the pointer event
      await tester.tap(outboxMessageFinder, warnIfMissed: false);
      await tester.pump();
      check(store.outboxMessages).values.single;
      check(outboxMessageFinder).findsOne();
    }

    // State transitions are tested more thoroughly in
    // test/model/message_test.dart .

    testWidgets('hidden -> waiting', (tester) async {
      await setupMessageListPage(tester,
        narrow: topicNarrow, subscriptions: [eg.subscription(stream)],
        messages: []);

      await sendMessageAndSucceed(tester);
      check(outboxMessageFinder).findsNothing();

      await tester.pump(kLocalEchoDebounceDuration);
      check(outboxMessageFinder).findsOne();
      check(loadingIndicatorFinder).findsOne();
      // The outbox message is still in waiting state;
      // tapping does not restore it.
      await checkTapNotRestoreMessage(tester);
    });

    testWidgets('hidden -> failed, tap to restore message', (tester) async {
      await setupMessageListPage(tester,
        narrow: topicNarrow, subscriptions: [eg.subscription(stream)],
        messages: []);
      // Send a message and fail.  Dismiss the error dialog as it pops up.
      await sendMessageAndFail(tester);
      await dismissErrorDialog(tester);
      check(messageNotSentFinder).findsOne();

      await checkTapRestoreMessage(tester);
    });

    testWidgets('hidden -> failed, tapping does nothing if compose box is not offered', (tester) async {
      final transitionDurationObserver = TransitionDurationObserver();

      final messages = [eg.streamMessage(
        stream: stream, topic: topic, content: content)];
      await setupMessageListPage(tester,
        narrow: const CombinedFeedNarrow(),
        streams: [stream], subscriptions: [eg.subscription(stream)],
        navObservers: [transitionDurationObserver],
        messages: messages);

      // Navigate to a message list page in a topic narrow,
      // which has a compose box.
      connection.prepare(json:
        eg.newestGetMessagesResult(foundOldest: true, messages: messages).toJson());
      await tester.tap(find.widgetWithText(RecipientHeader, topic));
      await tester.pump(); // handle tap
      await transitionDurationObserver.pumpPastTransition(tester);
      check(contentInputFinder).findsOne();

      await sendMessageAndFail(tester);
      await dismissErrorDialog(tester);
      // Navigate back to the message list page without a compose box,
      // where the failed to send message should be visible.

      await tester.pageBack();
      await tester.pump(); // handle tap
      await transitionDurationObserver.pumpPastTransition(tester);
      check(contentInputFinder).findsNothing();
      check(messageNotSentFinder).findsOne();

      // Tap the failed to send message.
      // This should not remove it from the message list.
      await checkTapNotRestoreMessage(tester);
    });

    testWidgets('waiting -> waitPeriodExpired, tap to restore message', (tester) async {
      await setupMessageListPage(tester,
        narrow: topicNarrow, subscriptions: [eg.subscription(stream)],
        messages: []);
      await sendMessageAndFail(tester,
        delay: kSendMessageOfferRestoreWaitPeriod + const Duration(seconds: 1));
      await tester.pump(kSendMessageOfferRestoreWaitPeriod);
      final localMessageId = store.outboxMessages.keys.single;
      check(messageNotSentFinder).findsOne();

      await checkTapRestoreMessage(tester);

      // While `localMessageId` is no longer in store, there should be no error
      // when a message event refers to it.
      await store.handleEvent(eg.messageEvent(
        eg.streamMessage(stream: stream, topic: 'topic'),
        localMessageId: localMessageId));

      // The [sendMessage] request fails; there is no outbox message affected.
      await tester.pump(Duration(seconds: 1));
      check(messageNotSentFinder).findsNothing();
    });
  });

  group('Starred messages', () {
    testWidgets('unstarred message', (tester) async {
      final message = eg.streamMessage(flags: []);
      await setupMessageListPage(tester, messages: [message]);
      check(find.byIcon(ZulipIcons.star_filled).evaluate()).isEmpty();
    });

    testWidgets('starred message', (tester) async {
      final message = eg.streamMessage(flags: [MessageFlag.starred]);
      await setupMessageListPage(tester, messages: [message]);
      check(find.byIcon(ZulipIcons.star_filled).evaluate()).length.equals(1);
    });
  });

  group('EDITED/MOVED label and edit-message error status', () {
    void checkMarkersCount({required int edited, required int moved}) {
      check(find.text('EDITED').evaluate()).length.equals(edited);
      check(find.text('MOVED').evaluate()).length.equals(moved);
    }

    testWidgets('no edited or moved messages', (tester) async {
      final message = eg.streamMessage();
      await setupMessageListPage(tester, messages: [message]);
      checkMarkersCount(edited: 0, moved: 0);
    });

    testWidgets('edited and moved messages from events', (tester) async {
      final message = eg.streamMessage(topic: 'old');
      final message2 = eg.streamMessage(topic: 'old');
      await setupMessageListPage(tester, messages: [message, message2]);
      checkMarkersCount(edited: 0, moved: 0);

      await store.handleEvent(eg.updateMessageEditEvent(message, renderedContent: 'edited'));
      await tester.pump();
      checkMarkersCount(edited: 1, moved: 0);

      await store.handleEvent(eg.updateMessageEventMoveFrom(
        origMessages: [message, message2], newTopicStr: 'new'));
      await tester.pump();
      checkMarkersCount(edited: 1, moved: 1);

      await store.handleEvent(eg.updateMessageEditEvent(message2, renderedContent: 'edited'));
      await tester.pump();
      checkMarkersCount(edited: 2, moved: 0);
    });

    void checkEditInProgress(WidgetTester tester) {
      check(find.text('SAVING EDIT…')).findsOne();
      check(find.byType(LinearProgressIndicator)).findsOne();
      final opacityWidget = tester.widget<Opacity>(find.ancestor(
        of: find.byType(MessageContent),
        matching: find.byType(Opacity)));
      check(opacityWidget.opacity).equals(0.6);
      checkMarkersCount(edited: 0, moved: 0);
    }

    void checkEditNotInProgress(WidgetTester tester) {
      check(find.text('SAVING EDIT…')).findsNothing();
      check(find.byType(LinearProgressIndicator)).findsNothing();
      check(find.ancestor(
        of: find.byType(MessageContent),
        matching: find.byType(Opacity))).findsNothing();
    }

    void checkEditFailed(WidgetTester tester) {
      check(find.text('EDIT NOT SAVED')).findsOne();
      final opacityWidget = tester.widget<Opacity>(find.ancestor(
        of: find.byType(MessageContent),
        matching: find.byType(Opacity)));
      check(opacityWidget.opacity).equals(0.6);
      checkMarkersCount(edited: 0, moved: 0);
    }

    testWidgets('successful edit', (tester) async {
      final message = eg.streamMessage();
      await setupMessageListPage(tester,
        narrow: TopicNarrow.ofMessage(message),
        messages: [message]);

      connection.prepare(json: UpdateMessageResult().toJson());
      unawaited(store.editMessage(messageId: message.id,
        originalRawContent: 'foo',
        newContent: 'bar'));
      await tester.pump(Duration.zero);
      checkEditInProgress(tester);
      await store.handleEvent(eg.updateMessageEditEvent(message));
      await tester.pump();
      checkEditNotInProgress(tester);
    });

    testWidgets('failed edit', (tester) async {
      final message = eg.streamMessage();
      await setupMessageListPage(tester,
        narrow: TopicNarrow.ofMessage(message),
        messages: [message]);

      connection.prepare(apiException: eg.apiBadRequest(), delay: Duration(seconds: 1));
      unawaited(check(store.editMessage(messageId: message.id,
        originalRawContent: 'foo',
        newContent: 'bar')).throws<ZulipApiException>());
      await tester.pump(Duration.zero);
      checkEditInProgress(tester);
      await tester.pump(Duration(seconds: 1));
      // (the error dialog is tested elsewhere;
      // it's triggered in the "Save" tap handler, not store.editMessage)
      checkEditFailed(tester);

      connection.prepare(json: GetMessageResult(
        message: eg.streamMessage(content: 'foo')).toJson(), delay: Duration(milliseconds: 500));
      await tester.tap(find.byType(MessageContent));
      // We don't clear out the failed attempt, with the intended new content…
      checkEditFailed(tester);
      await tester.pump(Duration(milliseconds: 500));
      // …until we have the current content, from a successful message fetch,
      // for prevContentSha256.
      checkEditNotInProgress(tester);

      final state = MessageListPage.ancestorOf(tester.element(find.byType(MessageContent)));
      check(state.composeBoxState).isNotNull().controller
        .isA<EditMessageComposeBoxController>()
        .content.value.text.equals('bar');
    });
  });

  group('_UnreadMarker animations', () {
    // TODO: Improve animation state testing so it is less tied to
    //   implementation details and more focused on output, see:
    //   https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/robust.20widget.20finders.20in.20tests/near/1671738
    Animation<double> getAnimation(WidgetTester tester, int messageId) {
      final widget = tester.widget<FadeTransition>(find.descendant(
        of: find.byKey(ValueKey(messageId)),
        matching: find.byType(FadeTransition)));
      return widget.opacity;
    }

    testWidgets('from read to unread', (tester) async {
      final message = eg.streamMessage(flags: [MessageFlag.read]);
      await setupMessageListPage(tester, messages: [message]);
      check(getAnimation(tester, message.id))
        ..value.equals(0.0)
        ..status.equals(AnimationStatus.dismissed);

      await store.handleEvent(eg.updateMessageFlagsRemoveEvent(
        MessageFlag.read, [message]));
      await tester.pump(); // process handleEvent
      check(getAnimation(tester, message.id))
        ..value.equals(0.0)
        ..status.equals(AnimationStatus.forward);

      await tester.pumpAndSettle();
      check(getAnimation(tester, message.id))
        ..value.equals(1.0)
        ..status.equals(AnimationStatus.completed);
    });

    testWidgets('from unread to read', (tester) async {
      final message = eg.streamMessage(flags: []);
      await setupMessageListPage(tester, messages: [message]);
      check(getAnimation(tester, message.id))
        ..value.equals(1.0)
        ..status.equals(AnimationStatus.dismissed);

      await store.handleEvent(UpdateMessageFlagsAddEvent(
        id: 1,
        flag: MessageFlag.read,
        messages: [message.id],
        all: false,
      ));
      await tester.pump(); // process handleEvent
      check(getAnimation(tester, message.id))
        ..value.equals(1.0)
        ..status.equals(AnimationStatus.forward);

      await tester.pumpAndSettle();
      check(getAnimation(tester, message.id))
        ..value.equals(0.0)
        ..status.equals(AnimationStatus.completed);
    });

    testWidgets('animation state persistence', (tester) async {
      // Check that _UnreadMarker maintains its in-progress animation
      // as the number of items changes in MessageList. See
      // `findChildIndexCallback` passed into [SliverStickyHeaderList]
      // at [_MessageListState._buildListView].
      final message = eg.streamMessage(flags: []);
      await setupMessageListPage(tester, messages: [message]);
      check(getAnimation(tester, message.id))
        ..value.equals(1.0)
        ..status.equals(AnimationStatus.dismissed);

      await store.handleEvent(UpdateMessageFlagsAddEvent(
        id: 0,
        flag: MessageFlag.read,
        messages: [message.id],
        all: false,
      ));
      await tester.pump(); // process handleEvent
      check(getAnimation(tester, message.id))
        ..value.equals(1.0)
        ..status.equals(AnimationStatus.forward);

      // run animation partially
      await tester.pump(const Duration(milliseconds: 30));
      check(getAnimation(tester, message.id))
        ..value.isGreaterThan(0.0)
        ..value.isLessThan(1.0)
        ..status.equals(AnimationStatus.forward);

      // introduce new message
      final newMessage = eg.streamMessage(flags:[MessageFlag.read]);
      await store.addMessage(newMessage);
      await tester.pump(); // process handleEvent
      check(find.byType(MessageItem)).findsExactly(2);
      check(getAnimation(tester, message.id))
        ..value.isGreaterThan(0.0)
        ..value.isLessThan(1.0)
        ..status.equals(AnimationStatus.forward);
      check(getAnimation(tester, newMessage.id))
        ..value.equals(0.0)
        ..status.equals(AnimationStatus.dismissed);

      final frames = await tester.pumpAndSettle();
      check(frames).isGreaterThan(1);
      check(getAnimation(tester, message.id))
        ..value.equals(0.0)
        ..status.equals(AnimationStatus.completed);
      check(getAnimation(tester, newMessage.id))
        ..value.equals(0.0)
        ..status.equals(AnimationStatus.dismissed);
    });
  });
}
