import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/sticky_header.dart';
import 'package:zulip/widgets/store.dart';

import '../api/fake_api.dart';
import '../test_images.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import 'content_checks.dart';

Future<void> setupMessageListPage(WidgetTester tester, {
  required Narrow narrow,
}) async {
  addTearDown(TestZulipBinding.instance.reset);
  addTearDown(tester.view.resetPhysicalSize);

  tester.view.physicalSize = const Size(600, 800);

  await TestZulipBinding.instance.globalStore.add(eg.selfAccount, eg.initialSnapshot());
  final store = await TestZulipBinding.instance.globalStore.perAccount(eg.selfAccount.id);
  final connection = store.connection as FakeApiConnection;

  // prepare message list data
  store.addUser(eg.selfUser);
  final List<StreamMessage> messages = List.generate(10, (index) {
    return eg.streamMessage(id: index, sender: eg.selfUser);
  });
  connection.prepare(json: GetMessagesResult(
    anchor: messages[0].id,
    foundNewest: true,
    foundOldest: true,
    foundAnchor: true,
    historyLimited: false,
    messages: messages,
  ).toJson());

  await tester.pumpWidget(
    MaterialApp(
      home: GlobalStoreWidget(
        child: PerAccountStoreWidget(
          accountId: eg.selfAccount.id,
          child: MessageListPage(narrow: narrow)))));

  // global store, per-account store, and message list get loaded
  await tester.pumpAndSettle();
}

void main() {
  TestZulipBinding.ensureInitialized();

  group('ScrollToBottomButton interactions', () {
    ScrollController? findMessageListScrollController(WidgetTester tester) {
      final stickyHeaderListView = tester.widget<StickyHeaderListView>(find.byType(StickyHeaderListView));
      return stickyHeaderListView.controller;
    }

    bool isButtonVisible(WidgetTester tester) {
      return tester.any(find.descendant(
        of: find.byType(ScrollToBottomButton),
        matching: find.byTooltip("Scroll to bottom")));
    }

    testWidgets('scrolling changes visibility', (WidgetTester tester) async {
      final stream = eg.stream();
      await setupMessageListPage(tester, narrow: StreamNarrow(stream.streamId));

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
      final stream = eg.stream();
      await setupMessageListPage(tester, narrow: StreamNarrow(stream.streamId));

      final scrollController = findMessageListScrollController(tester)!;

      // Initial state should be not visible, as the message list renders with latest message in view
      check(isButtonVisible(tester)).equals(false);

      scrollController.jumpTo(600);
      await tester.pump();
      check(isButtonVisible(tester)).equals(true);

      tester.view.physicalSize = const Size(2000, 40000);
      await tester.pump();
      // Dimension changes use NotificationListener<ScrollMetricsNotification
      // which has a one frame lag. If that ever gets resolved this extra pump
      // would ideally be removed
      await tester.pump();
      check(isButtonVisible(tester)).equals(false);
    });

    testWidgets('button functionality', (WidgetTester tester) async {
      final stream = eg.stream();
      await setupMessageListPage(tester, narrow: StreamNarrow(stream.streamId));

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

  group('MessageWithSender', () {
    testWidgets('Updates avatar on RealmUserUpdateEvent', (tester) async {
      addTearDown(TestZulipBinding.instance.reset);

      // TODO recognize avatar more reliably:
      //   https://github.com/zulip/zulip-flutter/pull/246#discussion_r1282516308
      RealmContentNetworkImage? findAvatarImageWidget(WidgetTester tester) {
        return tester.widgetList<RealmContentNetworkImage>(
          find.descendant(
            of: find.byType(MessageWithSender),
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
        final store = await TestZulipBinding.instance.globalStore.perAccount(eg.selfAccount.id);
        store.handleEvent(RealmUserUpdateEvent(id: 1, userId: eg.selfUser.userId, avatarUrl: avatarUrl));
        await tester.pump();
      }

      final httpClient = FakeImageHttpClient();
      debugNetworkImageHttpClientProvider = () => httpClient;
      httpClient.request.response
        ..statusCode = HttpStatus.ok
        ..content = kSolidBlueAvatar;

      await setupMessageListPage(tester, narrow: const AllMessagesNarrow());
      checkResultForSender(eg.selfUser.avatarUrl);

      await handleNewAvatarEventAndPump(tester, '/foo.png');
      checkResultForSender('/foo.png');

      await handleNewAvatarEventAndPump(tester, '/bar.jpg');
      checkResultForSender('/bar.jpg');

      debugNetworkImageHttpClientProvider = null;
    });
  });
}
