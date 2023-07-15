import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/sticky_header.dart';
import 'package:zulip/widgets/store.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/message_list_test.dart';
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import '../test_images.dart';
import 'content_checks.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;

  Future<void> setupMessageListPage(WidgetTester tester, {
    Narrow narrow = const AllMessagesNarrow(),
    bool foundOldest = true,
    int? messageCount,
    List<Message>? messages,
  }) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    connection = store.connection as FakeApiConnection;

    // prepare message list data
    store.addUser(eg.selfUser);
    assert((messageCount == null) != (messages == null));
    messages ??= List.generate(messageCount!, (index) {
      return eg.streamMessage(id: index, sender: eg.selfUser);
    });
    connection.prepare(json:
      newestResult(foundOldest: foundOldest, messages: messages).toJson());

    await tester.pumpWidget(
      MaterialApp(
        home: GlobalStoreWidget(
          child: PerAccountStoreWidget(
            accountId: eg.selfAccount.id,
            child: MessageListPage(narrow: narrow)))));

    // global store, per-account store, and message list get loaded
    await tester.pumpAndSettle();
  }

  ScrollController? findMessageListScrollController(WidgetTester tester) {
    final stickyHeaderListView = tester.widget<StickyHeaderListView>(find.byType(StickyHeaderListView));
    return stickyHeaderListView.controller;
  }

  group('fetch older messages on scroll', () {
    int? itemCount(WidgetTester tester) =>
      tester.widget<StickyHeaderListView>(find.byType(StickyHeaderListView)).semanticChildCount;

    testWidgets('basic', (tester) async {
      await setupMessageListPage(tester, foundOldest: false,
        messages: List.generate(200, (i) => eg.streamMessage(id: 950 + i, sender: eg.selfUser)));
      check(itemCount(tester)).equals(201);

      // Fling-scroll upward...
      await tester.fling(find.byType(MessageListPage), const Offset(0, 300), 8000);
      await tester.pump();

      // ... and we should fetch more messages as we go.
      connection.prepare(json: olderResult(anchor: 950, foundOldest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 850 + i, sender: eg.selfUser))).toJson());
      await tester.pump(const Duration(seconds: 3)); // Fast-forward to end of fling.
      await tester.pump(Duration.zero); // Allow a frame for the response to arrive.

      // Now we have more messages.
      check(itemCount(tester)).equals(301);
    });

    testWidgets('observe double-fetch glitch', (tester) async {
      await setupMessageListPage(tester, foundOldest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 950 + i, sender: eg.selfUser)));
      check(itemCount(tester)).equals(101);

      // Fling-scroll upward...
      await tester.fling(find.byType(MessageListPage), const Offset(0, 300), 8000);
      await tester.pump();

      // ... and we fetch more messages as we go.
      connection.prepare(json: olderResult(anchor: 950, foundOldest: false,
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
      connection.prepare(json: olderResult(anchor: 850, foundOldest: false,
        messages: List.generate(100, (i) => eg.streamMessage(id: 750 + i, sender: eg.selfUser))).toJson());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(Duration.zero);
      check(itemCount(tester)).equals(301);
    }, skip: true); // TODO this still reproduces manually, still needs debugging,
                    // but has become harder to reproduce in a test.
  });

  group('ScrollToBottomButton interactions', () {
    bool isButtonVisible(WidgetTester tester) {
      return tester.any(find.descendant(
        of: find.byType(ScrollToBottomButton),
        matching: find.byTooltip("Scroll to bottom")));
    }

    testWidgets('scrolling changes visibility', (WidgetTester tester) async {
      await setupMessageListPage(tester, messageCount: 10);

      final scrollController = findMessageListScrollController(tester)!;

      // Initial state should be not visible, as the message list renders with latest message in view
      check(isButtonVisible(tester)).equals(false);

      scrollController.jumpTo(600);
      await tester.pump();
      check(isButtonVisible(tester)).equals(true);

      scrollController.jumpTo(0);
      await tester.pump();
      check(isButtonVisible(tester)).equals(false);
    });

    testWidgets('dimension updates changes visibility', (WidgetTester tester) async {
      await setupMessageListPage(tester, messageCount: 100);

      final scrollController = findMessageListScrollController(tester)!;

      // Initial state should be not visible, as the message list renders with latest message in view
      check(isButtonVisible(tester)).equals(false);

      scrollController.jumpTo(600);
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

    testWidgets('button functionality', (WidgetTester tester) async {
      await setupMessageListPage(tester, messageCount: 10);

      final scrollController = findMessageListScrollController(tester)!;

      // Initial state should be not visible, as the message list renders with latest message in view
      check(isButtonVisible(tester)).equals(false);

      scrollController.jumpTo(600);
      await tester.pump();
      check(isButtonVisible(tester)).equals(true);

      await tester.tap(find.byType(ScrollToBottomButton));
      await tester.pumpAndSettle();
      check(isButtonVisible(tester)).equals(false);
      check(scrollController.position.pixels).equals(0);
    });
  });

  group('recipient headers', () {
    testWidgets('show stream name from message when stream unknown', (tester) async {
      // This can perfectly well happen, because message fetches can race
      // with events.
      final stream = eg.stream(name: 'stream name');
      await setupMessageListPage(tester, messages: [
        eg.streamMessage(stream: stream),
      ]);
      await tester.pump();
      tester.widget(find.text('stream name'));
    });

    testWidgets('show stream name from stream data when known', (tester) async {
      final stream = eg.stream(name: 'old stream name');
      await setupMessageListPage(tester, messages: [
        eg.streamMessage(stream: stream),
      ]);
      // TODO(#182) this test would be more realistic using a StreamUpdateEvent
      store.handleEvent(StreamCreateEvent(id: stream.streamId, streams: [
        ZulipStream.fromJson({
          ...(deepToJson(stream) as Map<String, dynamic>),
          'name': 'new stream name',
        }),
      ]));
      await tester.pump();
      tester.widget(find.text('new stream name'));
    });

    testWidgets('show names on DMs', (tester) async {
      await setupMessageListPage(tester, messages: [
        eg.dmMessage(from: eg.selfUser, to: []),
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]),
        eg.dmMessage(from: eg.thirdUser, to: [eg.selfUser, eg.otherUser]),
      ]);
      store.addUser(eg.otherUser);
      store.addUser(eg.thirdUser);
      await tester.pump();
      tester.widget(find.text("You with yourself"));
      tester.widget(find.text("You and ${eg.otherUser.fullName}"));
      tester.widget(find.text("You and ${eg.otherUser.fullName}, ${eg.thirdUser.fullName}"));
    });

    testWidgets('show names on DMs: smoothly handle unknown users', (tester) async {
      await setupMessageListPage(tester, messages: [
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]),
        eg.dmMessage(from: eg.thirdUser, to: [eg.selfUser, eg.otherUser]),
      ]);
      store.addUser(eg.thirdUser);
      await tester.pump();
      tester.widget(find.text("You and (unknown user)"));
      tester.widget(find.text("You and (unknown user), ${eg.thirdUser.fullName}"));
    });

    testWidgets('show dates', (tester) async {
      await setupMessageListPage(tester, messages: [
        eg.streamMessage(timestamp: 1671409088),
        eg.dmMessage(timestamp: 1692755322, from: eg.selfUser, to: []),
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
      tester.widget(find.textContaining(RegExp("2022-12-1[89]")));
      tester.widget(find.textContaining(RegExp("2023-08-2[23]")));
    });
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
            .src.equals(resolveUrl(avatarUrl, eg.selfAccount));
        }
      }

      Future<void> handleNewAvatarEventAndPump(WidgetTester tester, String avatarUrl) async {
        final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
        store.handleEvent(RealmUserUpdateEvent(id: 1, userId: eg.selfUser.userId, avatarUrl: avatarUrl));
        await tester.pump();
      }

      final httpClient = FakeImageHttpClient();
      debugNetworkImageHttpClientProvider = () => httpClient;
      httpClient.request.response
        ..statusCode = HttpStatus.ok
        ..content = kSolidBlueAvatar;

      await setupMessageListPage(tester, messageCount: 10);
      checkResultForSender(eg.selfUser.avatarUrl);

      await handleNewAvatarEventAndPump(tester, '/foo.png');
      checkResultForSender('/foo.png');

      await handleNewAvatarEventAndPump(tester, '/bar.jpg');
      checkResultForSender('/bar.jpg');

      debugNetworkImageHttpClientProvider = null;
    });
  });
}
