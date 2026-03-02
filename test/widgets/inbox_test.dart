import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_checks/legacy_checks.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/color.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/inbox.dart';
import 'package:zulip/widgets/theme.dart';
import 'package:zulip/widgets/counter_badge.dart';

import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/test_store.dart';
import 'test_app.dart';

/// Repeatedly drags `view` by `moveStep` until `finder` is invisible.
///
/// Between each drag, advances the clock by `duration`.
///
/// Throws a [StateError] if `finder` is still visible after `maxIteration`
/// drags.
///
/// See also:
///  * [WidgetController.dragUntilVisible], which does the inverse.
Future<void> dragUntilInvisible(
  WidgetTester tester,
  FinderBase<Element> finder,
  FinderBase<Element> view,
  Offset moveStep, {
  int maxIteration = 50,
  Duration duration = const Duration(milliseconds: 50),
}) {
  return TestAsyncUtils.guard<void>(() async {
    final iteration = maxIteration;
    while (maxIteration > 0 && finder.evaluate().isNotEmpty) {
      await tester.drag(view, moveStep);
      await tester.pump(duration);
      maxIteration -= 1;
    }
    if (maxIteration <= 0 && finder.evaluate().isNotEmpty) {
      throw StateError(
        'Finder is still visible after $iteration iterations.'
        ' Consider increasing the number of iterations.');
    }
  });
}

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;

  Future<void> setupPage(WidgetTester tester, {
    List<ZulipStream>? streams,
    List<Subscription>? subscriptions,
    List<ChannelFolder>? channelFolders,
    List<User>? users,
    required List<Message> unreadMessages,
    List<Message>? otherMessages,
    NavigatorObserver? navigatorObserver,
  }) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

    await store.addStreams(streams ?? []);
    await store.addSubscriptions(subscriptions ?? []);
    await store.addChannelFolders(channelFolders ?? []);
    await store.addUsers(users ?? [eg.selfUser]);

    for (final message in unreadMessages) {
      assert(!message.flags.contains(MessageFlag.read));
      await store.addMessage(message);
    }

    await tester.pumpWidget(TestZulipApp(
      accountId: eg.selfAccount.id,
      navigatorObservers: [?navigatorObserver],
      child: const HomePage(),
    ));
    await tester.pump();

    // global store and per-account store get loaded
    await tester.pumpAndSettle();
  }

  List<StreamMessage> generateStreamMessages({
    required ZulipStream stream,
    required int count,
    required List<MessageFlag> flags,
  }) {
    return List.generate(count, (index) => eg.streamMessage(
      stream: stream, topic: '${stream.name} topic $index', flags: flags));
  }

  /// Set up an inbox view with lots of interesting content.
  Future<void> setupVarious(WidgetTester tester, {int? sub1Color}) async {
    final stream1 = eg.stream(streamId: 1, name: 'stream 1');
    final sub1 = eg.subscription(stream1, color: sub1Color);
    final stream2 = eg.stream(streamId: 2, name: 'stream 2');
    final sub2 = eg.subscription(stream2);

    await setupPage(tester,
      streams: [stream1, stream2],
      subscriptions: [sub1, sub2],
      users: [eg.selfUser, eg.otherUser, eg.thirdUser, eg.fourthUser],
      unreadMessages: [
        eg.streamMessage(stream: stream1, topic: 'specific topic', flags: []),
        ...generateStreamMessages(stream: stream1, count: 10, flags: []),
        eg.streamMessage(stream: stream2, flags: []),
        ...generateStreamMessages(stream: stream2, count: 40, flags: []),
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser], flags: []),
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser, eg.thirdUser], flags: []),
        eg.dmMessage(from: eg.thirdUser, to: [eg.selfUser], flags: []),
        eg.dmMessage(from: eg.fourthUser, to: [eg.selfUser], flags: []),
      ]);
  }

  void checkFolderHeader(String label) {
    check(find.widgetWithText(InboxFolderHeaderItem, label.toUpperCase()))
      .findsOne();
  }

  void checkNoFolderHeader(String label) {
    check(find.widgetWithText(InboxFolderHeaderItem, label.toUpperCase()))
      .findsNothing();
  }

  void checkDm(Pattern expectLabelContains, {
    bool expectAtSignIcon = false,
    String? expectCounterBadgeText,
  }) {
    final findRow = find.ancestor(
      of: find.textContaining(expectLabelContains),
      matching: find.byType(InboxDmItem));
    check(findRow).findsOne();

    check(find.descendant(of: findRow, matching: find.byIcon(ZulipIcons.at_sign)))
      .findsExactly(expectAtSignIcon ? 1 : 0);

    if (expectCounterBadgeText != null) {
      check(find.descendant(
        of: findRow,
        matching: find.widgetWithText(CounterBadge, expectCounterBadgeText))
      ).findsOne();
    }
  }

  // TODO instead of .first, could look for both the row in the list *and*
  //   in the sticky-header position, or at least target one or the other
  //   intentionally.
  Finder findChannelHeader(int channelId) => find.byWidgetPredicate((widget) =>
    widget is InboxChannelHeaderItem && widget.subscription.streamId == channelId).first;

  /// Check details of a channel header.
  ///
  /// For [findSectionContent], optionally pass a [Finder]
  /// that will find some of the section's content if it is uncollapsed.
  /// It will be expected to find something or nothing,
  /// depending on [expectCollapsed].
  void checkChannelHeader(WidgetTester tester, Subscription subscription, {
    bool? expectAtSignIcon,
    bool? expectCollapsed,
    Finder? findSectionContent,
    bool? expectFolderName,
  }) {
    final findHeader = findChannelHeader(subscription.streamId);
    final element = tester.element(findHeader);

    if (expectAtSignIcon != null) {
      check(find.descendant(of: findHeader, matching: find.byIcon(ZulipIcons.at_sign)))
        .findsExactly(expectAtSignIcon ? 1 : 0);
    }

    final expectedChannelIcon = switch (subscription) {
      Subscription(isWebPublic: true) => ZulipIcons.globe,
      Subscription(inviteOnly: true) => ZulipIcons.lock,
      Subscription() => ZulipIcons.hash_sign,
    };
    final channelIcon = tester.widget<Icon>(
      find.descendant(of: findHeader, matching: find.byIcon(expectedChannelIcon)));

    if (expectCollapsed != null) {
      check(find.descendant(
        of: findHeader,
        matching: find.byIcon(
          expectCollapsed ? ZulipIcons.arrow_right : ZulipIcons.arrow_down))).findsOne();

      final swatch = colorSwatchFor(element, subscription);

      check(channelIcon).color.isNotNull()
        .isSameColorAs(expectCollapsed
          ? swatch.iconOnPlainBackground
          : swatch.iconOnBarBackground);

      final renderObject = tester.renderObject<RenderBox>(findHeader);
      final paintBounds = renderObject.paintBounds;

      // `paints` isn't a [Matcher] so we wrap it with `equals`;
      // awkward but it works
      check(renderObject).legacyMatcher(equals(paints..rrect(
        rrect: RRect.fromRectAndRadius(paintBounds, Radius.zero),
        style: .fill,
        color: expectCollapsed
          ? Colors.white
          : swatch.barBackground)));

      if (findSectionContent != null) {
        check(findSectionContent).findsExactly(expectCollapsed ? 0 : 1);
      }
    }

    if (expectFolderName != null) {
      check((element.widget as InboxChannelHeaderItem).showChannelFolderName)
        .equals(expectFolderName);
    }
  }

  void checkTopic(String topicDisplayName, {
    bool expectFollowIcon = false,
    bool expectAtSignIcon = false,
    bool expectUnmuteIcon = false,
    String? expectCounterBadgeText,
  }) {
    final findRow = find.widgetWithText(InboxTopicItem, topicDisplayName);
    check(findRow).findsOne();

    check(find.widgetWithIcon(InboxTopicItem, ZulipIcons.follow))
      .findsExactly(expectFollowIcon ? 1 : 0);

    check(find.widgetWithIcon(InboxTopicItem, ZulipIcons.at_sign))
      .findsExactly(expectAtSignIcon ? 1 : 0);

    check(find.widgetWithIcon(InboxTopicItem, ZulipIcons.unmute))
      .findsExactly(expectUnmuteIcon ? 1 : 0);

    if (expectCounterBadgeText != null) {
      check(find.descendant(
        of: findRow,
        matching: find.widgetWithText(CounterBadge, expectCounterBadgeText))
      ).findsOne();
    }
  }

  group('InboxPage', () {
    testWidgets('page builds; empty', (tester) async {
      await setupPage(tester, unreadMessages: []);
      check(find.textContaining('There are no unread messages in your inbox.')).findsOne();
    });

    testWidgets('page builds; not empty', (tester) async {
      await setupVarious(tester);
    });

    group('channel sorting', () {
      testWidgets('channels with names starting with an emoji sort before others', (tester) async {
        final channelBeta   = eg.stream(name: 'Beta Stream');
        final channelRocket = eg.stream(name: '🚀 Rocket Stream');
        final channelAlpha  = eg.stream(name: 'Alpha Stream');
        await setupPage(tester,
          users: [eg.selfUser, eg.otherUser],
          streams: [channelBeta, channelRocket, channelAlpha],
          subscriptions: [
            eg.subscription(channelBeta),
            eg.subscription(channelRocket),
            eg.subscription(channelAlpha),
          ],
          unreadMessages: [
            // Add an unread DM to shift the channel headers downward,
            // preventing a channel header being duplicated in the widget tree
            // as a sticky header.
            eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]),

            eg.streamMessage(stream: channelBeta),
            eg.streamMessage(stream: channelRocket),
            eg.streamMessage(stream: channelAlpha),
          ]);

        final listedChannelIds =
          tester.widgetList<InboxChannelHeaderItem>(find.byType(InboxChannelHeaderItem))
            .map((item) => item.subscription.streamId).toList();
        check(listedChannelIds).deepEquals([
          channelRocket.streamId,
          channelAlpha.streamId,
          channelBeta.streamId,
        ]);
      });
    });

    group('folder headers', () {
      testWidgets('DMs header', (tester) async {
        await setupPage(tester,
          users: [eg.selfUser, eg.otherUser],
          unreadMessages: [eg.dmMessage(from: eg.otherUser, to: [eg.selfUser])]);
        checkFolderHeader('Direct messages');
      });

      testWidgets('only pinned channels: shows pinned header, no other header', (tester) async {
        final channel = eg.stream();
        await setupPage(tester,
          streams: [channel],
          subscriptions: [eg.subscription(channel, pinToTop: true)],
          unreadMessages: [eg.streamMessage(stream: channel)]);
        checkFolderHeader('Pinned channels');
        checkNoFolderHeader('Other channels');
      });

      testWidgets('only unpinned channels: shows other header, no pinned header', (tester) async {
        final channel = eg.stream();
        await setupPage(tester,
          streams: [channel],
          subscriptions: [eg.subscription(channel, pinToTop: false)],
          unreadMessages: [eg.streamMessage(stream: channel)]);
        checkNoFolderHeader('Pinned channels');
        checkFolderHeader('Other channels');
      });

      testWidgets('both pinned and unpinned channels: shows both headers', (tester) async {
        final pinned = eg.stream();
        final unpinned = eg.stream();
        await setupPage(tester,
          streams: [pinned, unpinned],
          subscriptions: [
            eg.subscription(pinned, pinToTop: true),
            eg.subscription(unpinned, pinToTop: false),
          ],
          unreadMessages: [
            eg.streamMessage(stream: pinned),
            eg.streamMessage(stream: unpinned),
          ]);
        checkFolderHeader('Pinned channels');
        checkFolderHeader('Other channels');
      });

      testWidgets('channel in a realm folder: shows folder name as header', (tester) async {
        final folder = eg.channelFolder(name: 'Engineering');
        final channel = eg.stream(folderId: folder.id);
        await setupPage(tester,
          streams: [channel],
          subscriptions: [eg.subscription(channel)],
          channelFolders: [folder],
          unreadMessages: [eg.streamMessage(stream: channel)]);
        checkFolderHeader('Engineering');
        checkNoFolderHeader('Pinned channels');
        checkNoFolderHeader('Other channels');
      });

      testWidgets('channels in different realm folders: each gets its own header', (tester) async {
        final folder1 = eg.channelFolder(name: 'Engineering', order: 0);
        final folder2 = eg.channelFolder(name: 'Marketing', order: 1);
        final channel1 = eg.stream(folderId: folder1.id);
        final channel2 = eg.stream(folderId: folder2.id);
        await setupPage(tester,
          streams: [channel1, channel2],
          subscriptions: [
            eg.subscription(channel1),
            eg.subscription(channel2),
          ],
          channelFolders: [folder1, folder2],
          unreadMessages: [
            eg.streamMessage(stream: channel1),
            eg.streamMessage(stream: channel2),
          ]);
        checkFolderHeader('Engineering');
        checkFolderHeader('Marketing');
      });

      testWidgets('mix of pinned, realm folder, and other channels', (tester) async {
        final folder = eg.channelFolder(name: 'Design');
        final pinned = eg.stream();
        final inFolder = eg.stream(folderId: folder.id);
        final other = eg.stream();
        await setupPage(tester,
          streams: [pinned, inFolder, other],
          subscriptions: [
            eg.subscription(pinned, pinToTop: true),
            eg.subscription(inFolder),
            eg.subscription(other),
          ],
          channelFolders: [folder],
          unreadMessages: [
            eg.streamMessage(stream: pinned),
            eg.streamMessage(stream: inFolder),
            eg.streamMessage(stream: other),
          ]);
        checkFolderHeader('Pinned channels');
        checkFolderHeader('Design');
        checkFolderHeader('Other channels');
      });

      testWidgets('pinned channel in a realm folder: goes under pinned, not the folder', (tester) async {
        final folder = eg.channelFolder(name: 'Engineering');
        final channel = eg.stream(folderId: folder.id);
        await setupPage(tester,
          streams: [channel],
          subscriptions: [eg.subscription(channel, pinToTop: true)],
          channelFolders: [folder],
          unreadMessages: [eg.streamMessage(stream: channel)]);
        checkFolderHeader('Pinned channels');
        checkNoFolderHeader('Engineering');
      });

      testWidgets('DMs, pinned, realm folders in order, other', (tester) async {
        final folder1 = eg.channelFolder(name: 'Zebra', order: 1);
        final folder2 = eg.channelFolder(name: 'Alpha', order: 0);
        final pinned = eg.stream();
        final inFolder1 = eg.stream(folderId: folder1.id);
        final inFolder2 = eg.stream(folderId: folder2.id);
        final other = eg.stream();
        await setupPage(tester,
          users: [eg.selfUser, eg.otherUser],
          streams: [pinned, inFolder1, inFolder2, other],
          subscriptions: [
            eg.subscription(pinned, pinToTop: true),
            eg.subscription(inFolder1),
            eg.subscription(inFolder2),
            eg.subscription(other),
          ],
          channelFolders: [folder1, folder2],
          unreadMessages: [
            eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]),
            eg.streamMessage(stream: pinned),
            eg.streamMessage(stream: inFolder1),
            eg.streamMessage(stream: inFolder2),
            eg.streamMessage(stream: other),
          ]);

        final headers = tester.widgetList<InboxFolderHeaderItem>(
          find.byType(InboxFolderHeaderItem)).toList();
        check(headers.map((h) => h.label)).deepEquals([
          'Direct messages',
          'Pinned channels',
          'Alpha',
          'Zebra',
          'Other channels',
        ]);
      });
    });

    testWidgets('UnreadCountBadge text color for a channel', (tester) async {
      // Regression test for a bug where
      // DesignVariables.labelCounterUnread was used for the text instead of
      // DesignVariables.unreadCountBadgeTextForChannel.
      final channel = eg.stream();
      final subscription  = eg.subscription(channel);
      await setupPage(tester,
        streams: [channel],
        subscriptions: [subscription],
        unreadMessages: generateStreamMessages(stream: channel, count: 1, flags: []));

      final text = tester.widget<Text>(
        find.descendant(
          of: findChannelHeader(channel.streamId),
          matching: find.descendant(
            of: find.byType(CounterBadge),
            matching: find.text('1'))));

      final expectedTextColor = DesignVariables.light.unreadCountBadgeTextForChannel;
      check(text).style.isNotNull().color.isNotNull().isSameColorAs(expectedTextColor);
    });

    // TODO test that tapping a conversation row opens the message list
    //   for the conversation

    // Tests for the topic action sheet are in test/widgets/action_sheet_test.dart.

    group('muting', () { // aka topic visibility
      testWidgets('baseline', (tester) async {
        final stream = eg.stream();
        final subscription = eg.subscription(stream);
        await setupPage(tester,
          streams: [stream],
          subscriptions: [subscription],
          unreadMessages: [eg.streamMessage(stream: stream, topic: 'lunch')]);
        check(tester.widgetList(find.text('lunch'))).length.equals(1);
      });

      testWidgets('muted topic', (tester) async {
        final stream = eg.stream();
        final subscription = eg.subscription(stream);
        await setupPage(tester,
          streams: [stream],
          subscriptions: [subscription],
          unreadMessages: [eg.streamMessage(stream: stream, topic: 'lunch')]);
        await store.setUserTopic(stream, 'lunch', UserTopicVisibilityPolicy.muted);
        await tester.pump();
        check(tester.widgetList(find.text('lunch'))).length.equals(0);
      });

      testWidgets('muted stream', (tester) async {
        final stream = eg.stream();
        final subscription = eg.subscription(stream, isMuted: true);
        await setupPage(tester,
          streams: [stream],
          subscriptions: [subscription],
          unreadMessages: [eg.streamMessage(stream: stream, topic: 'lunch')]);
        check(tester.widgetList(find.text('lunch'))).length.equals(0);
      });

      testWidgets('unmuted topic in muted stream', (tester) async {
        final stream = eg.stream();
        final subscription = eg.subscription(stream, isMuted: true);
        await setupPage(tester,
          streams: [stream],
          subscriptions: [subscription],
          unreadMessages: [eg.streamMessage(stream: stream, topic: 'lunch')]);
        await store.setUserTopic(stream, 'lunch', UserTopicVisibilityPolicy.unmuted);
        await tester.pump();
        check(tester.widgetList(find.text('lunch'))).length.equals(1);
      });
    });

    group('mentions', () {
      final stream = eg.stream();
      final subscription = eg.subscription(stream);
      const topic = 'lunch';

      testWidgets('topic with a mention', (tester) async {
        await setupPage(tester,
          streams: [stream],
          subscriptions: [subscription],
          unreadMessages: [eg.streamMessage(stream: stream, topic: topic,
            flags: [MessageFlag.mentioned])]);

        checkChannelHeader(tester, subscription, expectAtSignIcon: true);
        checkTopic(topic, expectAtSignIcon: true);
      });

      testWidgets('topic without a mention', (tester) async {
        await setupPage(tester,
          streams: [stream],
          subscriptions: [subscription],
          unreadMessages: [eg.streamMessage(stream: stream, topic: topic,
            flags: [])]);

        checkChannelHeader(tester, subscription, expectAtSignIcon: false);
        checkTopic(topic, expectAtSignIcon: false);
      });

      testWidgets('dm with a mention', (tester) async {
        await setupPage(tester,
          users: [eg.selfUser, eg.otherUser],
          unreadMessages: [eg.dmMessage(from: eg.otherUser, to: [eg.selfUser],
            flags: [MessageFlag.mentioned])]);

        checkFolderHeader('Direct messages');
        checkDm(eg.otherUser.fullName, expectAtSignIcon: true);
      });

      testWidgets('dm without mention', (tester) async {
        await setupPage(tester,
          users: [eg.selfUser, eg.otherUser],
          unreadMessages: [eg.dmMessage(from: eg.otherUser, to: [eg.selfUser],
            flags: [])]);

        checkFolderHeader('Direct messages');
        checkDm(eg.otherUser.fullName, expectAtSignIcon: false);
      });
    });

    testWidgets('empty topic', (tester) async {
      final channel = eg.stream();
      await setupPage(tester,
        streams: [channel],
        subscriptions: [(eg.subscription(channel))],
        unreadMessages: [eg.streamMessage(stream: channel, topic: '')]);
      check(find.text(eg.defaultRealmEmptyTopicDisplayName)).findsOne();
    });

    group('topic visibility', () {
      final channel = eg.stream();
      const topic = 'topic';
      final message = eg.streamMessage(stream: channel, topic: topic);

      testWidgets('followed', (tester) async {
        await setupPage(tester,
          streams: [channel],
          subscriptions: [eg.subscription(channel)],
          unreadMessages: [message]);
        await store.setUserTopic(channel, topic, UserTopicVisibilityPolicy.followed);
        await tester.pump();
        checkTopic(topic, expectFollowIcon: true);
      });

      testWidgets('followed and mentioned', (tester) async {
        await setupPage(tester,
          streams: [channel],
          subscriptions: [eg.subscription(channel)],
          unreadMessages: [eg.streamMessage(stream: channel, topic: topic,
            flags: [MessageFlag.mentioned])]);
        await store.setUserTopic(channel, topic, UserTopicVisibilityPolicy.followed);
        await tester.pump();
        checkTopic(topic, expectAtSignIcon: true, expectFollowIcon: true);
      });

      testWidgets('unmuted', (tester) async {
        await setupPage(tester,
          users: [eg.selfUser, eg.otherUser],
          streams: [channel],
          subscriptions: [eg.subscription(channel, isMuted: true)],
          unreadMessages: [message]);
        await store.setUserTopic(channel, topic, UserTopicVisibilityPolicy.unmuted);
        await tester.pump();
        checkTopic(topic, expectUnmuteIcon: true);
      });

      testWidgets('unmuted (topics treated case-insensitively)', (tester) async {
        // Case-insensitivity of both topic-visibility and unreads data
        // TODO(#1065) this belongs in test/model/ once the inbox page has
        //   its own view-model

        final message1 = eg.streamMessage(stream: channel, topic: 'aaa');
        final message2 = eg.streamMessage(stream: channel, topic: 'AaA', flags: [MessageFlag.read]);
        final message3 = eg.streamMessage(stream: channel, topic: 'aAa', flags: [MessageFlag.read]);
        await setupPage(tester,
          users: [eg.selfUser, eg.otherUser],
          streams: [channel],
          subscriptions: [eg.subscription(channel, isMuted: true)],
          unreadMessages: [message1]);
        await store.setUserTopic(channel, 'aaa', UserTopicVisibilityPolicy.unmuted);
        await tester.pump();

        checkTopic('aaa', expectUnmuteIcon: true, expectCounterBadgeText: '1');

        await store.handleEvent(eg.updateMessageFlagsRemoveEvent(MessageFlag.read, [message2]));
        await tester.pump();
        checkTopic('aaa', expectUnmuteIcon: true, expectCounterBadgeText: '2');

        await store.handleEvent(eg.updateMessageFlagsRemoveEvent(MessageFlag.read, [message3]));
        await tester.pump();
        checkTopic('aaa', expectUnmuteIcon: true, expectCounterBadgeText: '3');
      });
    });

    group('collapsing', () {
      group('stream section', () {
        Future<void> tapCollapseIcon(WidgetTester tester, Subscription subscription) async {
          checkChannelHeader(tester, subscription);
          await tester.tap(find.descendant(
            of: findChannelHeader(subscription.streamId),
            matching: find.byWidgetPredicate((widget) =>
              widget is Icon
              && (widget.icon == ZulipIcons.arrow_down
                  || widget.icon == ZulipIcons.arrow_right))));
          await tester.pump();
        }

        testWidgets('appearance', (tester) async {
          await setupVarious(tester);
          final subscription = store.subscriptions[1]!;

          final findSectionContent = find.text('specific topic');

          checkChannelHeader(tester, subscription,
            expectCollapsed: false, findSectionContent: findSectionContent);
          await tapCollapseIcon(tester, subscription);
          checkChannelHeader(tester, subscription,
            expectCollapsed: true, findSectionContent: findSectionContent);
          await tapCollapseIcon(tester, subscription);
          checkChannelHeader(tester, subscription,
            expectCollapsed: false, findSectionContent: findSectionContent);
        });

        testWidgets('uncollapsed header changes background color when [subscription.color] changes', (tester) async {
          final stream = eg.stream(streamId: 1);
          final subscription = eg.subscription(stream, color: Colors.indigo.argbInt);
          await setupPage(tester,
            streams: [stream],
            subscriptions: [subscription],
            unreadMessages: [eg.streamMessage(stream: stream, topic: 'specific topic', flags: [])]);

          final findSectionContent = find.text('specific topic');

          // helper will expect indigo
          checkChannelHeader(tester, subscription,
            expectCollapsed: false, findSectionContent: findSectionContent);

          final newColor = Colors.orange.argbInt;
          await store.handleEvent(SubscriptionUpdateEvent(id: 1, streamId: 1,
            property: SubscriptionProperty.color, value: newColor));
          check(subscription.color).equals(Colors.orange.argbInt);
          await tester.pump();

          // helper will expect orange
          checkChannelHeader(tester, subscription,
            expectCollapsed: false, findSectionContent: findSectionContent);
        });

        testWidgets('collapse stream section when partially offscreen: '
          'header remains sticky at top', (tester) async {
          await setupVarious(tester);
          final subscription = store.subscriptions[1]!;

          final topicFinder = find.text('stream 1 topic 4').hitTestable();
          final listFinder = find.byType(Scrollable);

          // Scroll part of [_StreamSection] offscreen.
          await dragUntilInvisible(
            tester, topicFinder, listFinder, const Offset(0, -50));

          // Check that the header is present (which must therefore
          // be as a sticky header).
          checkChannelHeader(tester, subscription,
            expectCollapsed: false,
            expectFolderName: true);

          await tapCollapseIcon(tester, subscription);

          // Check that the header is still visible even after
          // collapsing the section.
          checkChannelHeader(tester, subscription, expectCollapsed: true);
        });

        testWidgets('collapse stream section in middle of screen: '
          'header stays fixed', (tester) async {
          await setupVarious(tester);
          final subscription = store.subscriptions[1]!;

          checkChannelHeader(tester, subscription);

          final rectBeforeTap = tester.getRect(findChannelHeader(1));
          final scrollableTop = tester.getRect(find.byType(Scrollable)).top;
          // Check that the header is somewhere in the middle of the screen.
          check(rectBeforeTap.top).isGreaterThan(scrollableTop);

          await tapCollapseIcon(tester, subscription);

          final rectAfterTap =
            tester.getRect(findChannelHeader(1));

          // Check that the position of the header before and after
          // collapsing is the same.
          check(rectAfterTap).equals(rectBeforeTap);
        });

        // TODO check it remains collapsed even if you scroll far away and back

        // TODO check that it's always uncollapsed when it appears after being
        //   absent, even if it was collapsed the last time it was present.
        //   (Could test multiple triggers for its reappearance: it could
        //   reappear because a new unread arrived, but with #346 it could also
        //   reappear because you unmuted a conversation.)
      });
    });
  });
}
