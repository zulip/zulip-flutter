import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/narrow.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/typing_status.dart';
import 'package:zulip/widgets/autocomplete.dart';
import 'package:zulip/widgets/color.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/store.dart';
import 'package:zulip/widgets/channel_colors.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/content_test.dart';
import '../model/test_store.dart';
import '../flutter_checks.dart';
import '../stdlib_checks.dart';
import '../test_images.dart';
import '../test_navigation.dart';
import 'content_checks.dart';
import 'dialog_checks.dart';
import 'message_list_checks.dart';
import 'page_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;

  Future<void> setupMessageListPage(WidgetTester tester, {
    Narrow narrow = const CombinedFeedNarrow(),
    bool foundOldest = true,
    int? messageCount,
    List<Message>? messages,
    List<ZulipStream>? streams,
    List<User>? users,
    List<Subscription>? subscriptions,
    UnreadMessagesSnapshot? unreadMsgs,
    List<NavigatorObserver> navObservers = const [],
  }) async {
    TypingNotifier.debugEnable = false;
    addTearDown(TypingNotifier.debugReset);
    addTearDown(testBinding.reset);
    streams ??= subscriptions ??= [eg.subscription(eg.stream(streamId: eg.defaultStreamMessageStreamId))];
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot(
      streams: streams, subscriptions: subscriptions, unreadMsgs: unreadMsgs));
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    connection = store.connection as FakeApiConnection;

    // prepare message list data
    await store.addUser(eg.selfUser);
    await store.addUsers(users ?? []);
    assert((messageCount == null) != (messages == null));
    messages ??= List.generate(messageCount!, (index) {
      return eg.streamMessage(sender: eg.selfUser);
    });
    connection.prepare(json:
      eg.newestGetMessagesResult(foundOldest: foundOldest, messages: messages).toJson());

    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
      navigatorObservers: navObservers,
      child: MessageListPage(initNarrow: narrow)));

    // global store, per-account store, and message list get loaded
    await tester.pumpAndSettle();
  }

  ScrollController? findMessageListScrollController(WidgetTester tester) {
    final scrollView = tester.widget<CustomScrollView>(find.byType(CustomScrollView));
    return scrollView.controller;
  }

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
        streams: [stream],
        messages: [eg.streamMessage(stream: stream, content: "<p>a message</p>")]);
      final state = MessageListPage.ancestorOf(tester.element(find.text("a message")));
      check(state.narrow).equals(ChannelNarrow(stream.streamId));
    });

    testWidgets('composeBoxController finds compose box', (tester) async {
      final stream = eg.stream();
      await setupMessageListPage(tester, narrow: ChannelNarrow(stream.streamId),
        streams: [stream],
        messages: [eg.streamMessage(stream: stream, content: "<p>a message</p>")]);
      final state = MessageListPage.ancestorOf(tester.element(find.text("a message")));
      check(state.composeBoxController).isNotNull();
    });

    testWidgets('composeBoxController null when no compose box', (tester) async {
      await setupMessageListPage(tester, narrow: const CombinedFeedNarrow(),
        messages: [eg.streamMessage(content: "<p>a message</p>")]);
      final state = MessageListPage.ancestorOf(tester.element(find.text("a message")));
      check(state.composeBoxController).isNull();
    });
  });

  group('app bar', () {
    testWidgets('has channel-feed action for topic narrows', (tester) async {
      final pushedRoutes = <Route<void>>[];
      final navObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      final channel = eg.stream();
      await setupMessageListPage(tester, narrow: eg.topicNarrow(channel.streamId, 'hi'),
        navObservers: [navObserver],
        streams: [channel], messageCount: 1);

      // Clear out initial route.
      assert(pushedRoutes.length == 1);
      pushedRoutes.clear();

      // Tap button; it works.
      await tester.tap(find.byIcon(ZulipIcons.message_feed));
      check(pushedRoutes).single.isA<WidgetRoute>()
        .page.isA<MessageListPage>().initNarrow
          .equals(ChannelNarrow(channel.streamId));
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
  });

  group('presents message content appropriately', () {
    testWidgets('content not asked to consume insets (including bottom), even without compose box', (tester) async {
      // Regression test for: https://github.com/zulip/zulip-flutter/issues/736
      const fakePadding = FakeViewPadding(left: 10, top: 10, right: 10, bottom: 10);
      tester.view.viewInsets = fakePadding;
      tester.view.padding = fakePadding;

      await setupMessageListPage(tester, narrow: const CombinedFeedNarrow(),
        messages: [eg.streamMessage(content: ContentExample.codeBlockPlain.html)]);

      // Verify this message list lacks a compose box.
      // (The original bug wouldn't reproduce with a compose box present.)
      final state = MessageListPage.ancestorOf(tester.element(find.text("verb\natim")));
      check(state.composeBoxController).isNull();

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

    check(backgroundColor()).isSameColorAs(MessageListTheme.light().streamMessageBgDefault);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();

    await tester.pump(kThemeAnimationDuration * 0.4);
    final expectedLerped = MessageListTheme.light().lerp(MessageListTheme.dark(), 0.4);
    check(backgroundColor()).isSameColorAs(expectedLerped.streamMessageBgDefault);

    await tester.pump(kThemeAnimationDuration * 0.6);
    check(backgroundColor()).isSameColorAs(MessageListTheme.dark().streamMessageBgDefault);
  });

  group('fetch older messages on scroll', () {
    int? itemCount(WidgetTester tester) =>
      tester.widget<CustomScrollView>(find.byType(CustomScrollView)).semanticChildCount;

    testWidgets('basic', (tester) async {
      await setupMessageListPage(tester, foundOldest: false,
        messages: List.generate(300, (i) => eg.streamMessage(id: 950 + i, sender: eg.selfUser)));
      check(itemCount(tester)).equals(303);

      // Fling-scroll upward...
      await tester.fling(find.byType(MessageListPage), const Offset(0, 300), 8000);
      await tester.pump();

      // ... and we should fetch more messages as we go.
      connection.prepare(json: eg.olderGetMessagesResult(anchor: 950, foundOldest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 850 + i, sender: eg.selfUser))).toJson());
      await tester.pump(const Duration(seconds: 3)); // Fast-forward to end of fling.
      await tester.pump(Duration.zero); // Allow a frame for the response to arrive.

      // Now we have more messages.
      check(itemCount(tester)).equals(403);
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
      check(itemCount(tester)).equals(404);

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

  group('ScrollToBottomButton interactions', () {
    bool isButtonVisible(WidgetTester tester) {
      return tester.any(find.descendant(
        of: find.byType(ScrollToBottomButton),
        matching: find.byTooltip("Scroll to bottom")));
    }

    testWidgets('scrolling changes visibility', (tester) async {
      await setupMessageListPage(tester, messageCount: 10);

      final scrollController = findMessageListScrollController(tester)!;

      // Initial state should be not visible, as the message list renders with latest message in view
      check(isButtonVisible(tester)).equals(false);

      scrollController.jumpTo(-600);
      await tester.pump();
      check(isButtonVisible(tester)).equals(true);

      scrollController.jumpTo(0);
      await tester.pump();
      check(isButtonVisible(tester)).equals(false);
    });

    testWidgets('dimension updates changes visibility', (tester) async {
      await setupMessageListPage(tester, messageCount: 100);

      final scrollController = findMessageListScrollController(tester)!;

      // Initial state should be not visible, as the message list renders with latest message in view
      check(isButtonVisible(tester)).equals(false);

      scrollController.jumpTo(-600);
      await tester.pump();
      check(isButtonVisible(tester)).equals(true);

      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(2000, 40000);
      await tester.pump();
      // Dimension changes use NotificationListener<ScrollMetricsNotification
      // which has a one frame lag. If that ever gets resolved this extra pump
      // would ideally be removed
      await tester.pump();
      check(isButtonVisible(tester)).equals(false);
    });

    testWidgets('button functionality', (tester) async {
      await setupMessageListPage(tester, messageCount: 10);

      final scrollController = findMessageListScrollController(tester)!;

      // Initial state should be not visible, as the message list renders with latest message in view
      check(isButtonVisible(tester)).equals(false);

      scrollController.jumpTo(-600);
      await tester.pump();
      check(isButtonVisible(tester)).equals(true);

      await tester.tap(find.byType(ScrollToBottomButton));
      await tester.pumpAndSettle();
      check(isButtonVisible(tester)).equals(false);
      check(scrollController.position.pixels).equals(0);
    });
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

    for (final (description, message, narrow) in [
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

          connection.prepare(httpStatus: 400, json: {
            'code': 'BAD_REQUEST',
            'msg': 'Invalid message(s)',
            'result': 'error',
          });

          checkAppearsLoading(tester, false);

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
              'narrow': jsonEncode(apiNarrow),
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

        connection.prepare(exception: http.ClientException('Oops'));
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
    final otherChannel = eg.stream();
    final narrow = eg.topicNarrow(channel.streamId, topic);

    void prepareGetMessageResponse(List<Message> messages) {
      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: false, messages: messages).toJson());
    }

    void handleMessageMoveEvent(List<StreamMessage> messages, String newTopic, {int? newChannelId}) {
      store.handleEvent(eg.updateMessageEventMoveFrom(
        origMessages: messages,
        newTopicStr: newTopic,
        newStreamId: newChannelId,
        propagateMode: PropagateMode.changeAll));
    }

    testWidgets('compose box send message after move', (tester) async {
      final message = eg.streamMessage(stream: channel, topic: topic, content: 'Message to move');
      await setupMessageListPage(tester, narrow: narrow, messages: [message], streams: [channel, otherChannel]);

      final channelContentInputFinder = find.descendant(
        of: find.byType(ComposeAutocomplete),
        matching: find.byType(TextField));

      await tester.enterText(channelContentInputFinder, 'Some text');
      check(tester.widget<TextField>(channelContentInputFinder))
        ..decoration.isNotNull().hintText.equals('Message #${channel.name} > $topic')
        ..controller.isNotNull().text.equals('Some text');

      prepareGetMessageResponse([message]);
      handleMessageMoveEvent([message], 'new topic', newChannelId: otherChannel.streamId);
      await tester.pump(const Duration(seconds: 1));
      check(tester.widget<TextField>(channelContentInputFinder))
        ..decoration.isNotNull().hintText.equals('Message #${otherChannel.name} > new topic')
        ..controller.isNotNull().text.equals('Some text');

      connection.prepare(json: SendMessageResult(id: 1).toJson());
      await tester.tap(find.byIcon(ZulipIcons.send));
      await tester.pump();
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages')
        ..bodyFields.deepEquals({
          'type': 'stream',
          'to': '${otherChannel.streamId}',
          'topic': 'new topic',
          'content': 'Some text',
          'read_by_sender': 'true'});
      await tester.pumpAndSettle();
    });

    testWidgets('Move to narrow with existing messages', (tester) async {
      final message = eg.streamMessage(stream: channel, topic: topic, content: 'Message to move');
      await setupMessageListPage(tester, narrow: narrow, messages: [message], streams: [channel]);
      check(find.textContaining('Existing message').evaluate()).length.equals(0);
      check(find.textContaining('Message to move').evaluate()).length.equals(1);

      final existingMessage = eg.streamMessage(
        stream: eg.stream(), topic: 'new topic', content: 'Existing message');
      prepareGetMessageResponse([existingMessage, message]);
      handleMessageMoveEvent([message], 'new topic');
      await tester.pump(const Duration(seconds: 1));

      check(find.textContaining('Existing message').evaluate()).length.equals(1);
      check(find.textContaining('Message to move').evaluate()).length.equals(1);
    });

    testWidgets('show new topic in TopicNarrow after move', (tester) async {
      final message = eg.streamMessage(stream: channel, topic: topic, content: 'Message to move');
      await setupMessageListPage(tester, narrow: narrow, messages: [message], streams: [channel]);

      prepareGetMessageResponse([message]);
      handleMessageMoveEvent([message], 'new topic');
      await tester.pump(const Duration(seconds: 1));

      check(find.descendant(
        of: find.byType(RecipientHeader),
        matching: find.text('new topic')).evaluate()
      ).length.equals(1);
      check(find.descendant(
        of: find.byType(MessageListAppBarTitle),
        matching: find.text('new topic')).evaluate()
      ).length.equals(1);
    });
  });

  group('recipient headers', () {
    group('StreamMessageRecipientHeader', () {
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
          messages: [message], streams: [stream]);
        await tester.pump();
        check(findInMessageList('stream name')).length.equals(0);
        check(findInMessageList('topic name')).length.equals(1);
      });

      testWidgets('do not show stream name in TopicNarrow', (tester) async {
        await setupMessageListPage(tester,
          narrow: TopicNarrow.ofMessage(message),
          messages: [message], streams: [stream]);
        await tester.pump();
        check(findInMessageList('stream name')).length.equals(0);
        check(findInMessageList('topic name')).length.equals(1);
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

      testWidgets('icon color matches text color', (tester) async {
        final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
        await setupMessageListPage(tester, messages: [
          eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]),
        ]);
        await tester.pump();
        final textSpan = tester.renderObject<RenderParagraph>(find.text(
          zulipLocalizations.messageListGroupYouAndOthers(
            zulipLocalizations.unknownUserName))).text;
        final icon = tester.widget<Icon>(find.byIcon(ZulipIcons.user));
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
  });

  group('formatHeaderDate', () {
    final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
    final now = DateTime.parse("2023-01-10 12:00");
    final testCases = [
      ("2023-01-10 12:00", zulipLocalizations.today),
      ("2023-01-10 00:00", zulipLocalizations.today),
      ("2023-01-10 23:59", zulipLocalizations.today),
      ("2023-01-09 23:59", zulipLocalizations.yesterday),
      ("2023-01-09 00:00", zulipLocalizations.yesterday),
      ("2023-01-08 00:00", "Jan 8"),
      ("2022-12-31 00:00", "Dec 31, 2022"),
      // Future times
      ("2023-01-10 19:00", zulipLocalizations.today),
      ("2023-01-11 00:00", "Jan 11, 2023"),
    ];
    for (final (dateTime, expected) in testCases) {
      test('$dateTime returns $expected', () {
        check(formatHeaderDate(zulipLocalizations, DateTime.parse(dateTime), now: now))
          .equals(expected);
      });
    }
  });

  group('MessageWithPossibleSender', () {
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

      Future<void> handleNewAvatarEventAndPump(WidgetTester tester, String avatarUrl) async {
        await store.handleEvent(RealmUserUpdateEvent(id: 1, userId: eg.selfUser.userId, avatarUrl: avatarUrl));
        await tester.pump();
      }

      prepareBoringImageHttpClient();

      await setupMessageListPage(tester, messageCount: 10);
      checkResultForSender(eg.selfUser.avatarUrl);

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

  group('edit state label', () {
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
      await store.handleEvent(MessageEvent(id: 0, message: newMessage));
      await tester.pump(); // process handleEvent
      check(find.byType(MessageItem).evaluate()).length.equals(2);
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
