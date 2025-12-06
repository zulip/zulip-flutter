import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/color.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/channel_colors.dart';
import 'package:zulip/widgets/theme.dart';
import 'package:zulip/widgets/unread_count_badge.dart';

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
    await store.addUsers(users ?? [eg.selfUser]);

    for (final message in unreadMessages) {
      assert(!message.flags.contains(MessageFlag.read));
      await store.addMessage(message);
    }

    await tester.pumpWidget(TestZulipApp(
      accountId: eg.selfAccount.id,
      navigatorObservers: [if (navigatorObserver != null) navigatorObserver],
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

  /// Find a row with the given label.
  Widget? findRowByLabel(WidgetTester tester, String label) {
    final rowLabel = tester.widgetList(
      find.textContaining(label, findRichText: true),
    ).firstOrNull;
    if (rowLabel == null) {
      return null;
    }

    return tester.widget(
      find.ancestor(
        of: find.byWidget(rowLabel),
        matching: find.byType(Row)));
  }

  /// Find the all-DMs header element.
  Widget? findAllDmsHeaderRow(WidgetTester tester) {
    return findRowByLabel(tester, 'Direct messages');
  }

  Color? allDmsHeaderBackgroundColor(WidgetTester tester) {
    final row = findAllDmsHeaderRow(tester);
    check(row).isNotNull();
    final material = tester.firstWidget<Material>(
      find.ancestor(
        of: find.byWidget(row!),
        matching: find.byType(Material)));
    return material.color;
  }

  /// For the given stream ID, find the stream header element.
  Widget? findStreamHeaderRow(WidgetTester tester, int streamId) {
    final stream = store.streams[streamId]!;
    return findRowByLabel(tester, stream.name);
  }

  Color? streamHeaderBackgroundColor(WidgetTester tester, int streamId) {
    final row = findStreamHeaderRow(tester, streamId);
    check(row).isNotNull();
    final material = tester.firstWidget<Material>(
      find.ancestor(
        of: find.byWidget(row!),
        matching: find.byType(Material)));
    return material.color;
  }

  IconData expectedStreamHeaderIcon(int streamId) {
    final subscription = store.subscriptions[streamId]!;
    return switch (subscription) {
      Subscription(isWebPublic: true) => ZulipIcons.globe,
      Subscription(inviteOnly: true) => ZulipIcons.lock,
      Subscription() => ZulipIcons.hash_sign,
    };
  }

  Icon findStreamHeaderIcon(WidgetTester tester, int streamId) {
    final expectedIcon = expectedStreamHeaderIcon(streamId);
    final headerRow = findStreamHeaderRow(tester, streamId);
    check(headerRow).isNotNull();

    return tester.widget<Icon>(find.descendant(
      of: find.byWidget(headerRow!),
      matching: find.byIcon(expectedIcon),
    ));
  }

  bool hasIcon(WidgetTester tester, {
    required Widget? parent,
    required IconData icon,
  }) {
    check(parent).isNotNull();
    return tester.widgetList(find.descendant(
      of: find.byWidget(parent!),
      matching: find.byIcon(icon),
    )).isNotEmpty;
  }

  group('InboxPage', () {
    testWidgets('page builds; empty', (tester) async {
      await setupPage(tester, unreadMessages: []);
      check(find.textContaining('There are no unread messages in your inbox.')).findsOne();
    });

    // TODO more checks: ordering, etc.
    testWidgets('page builds; not empty', (tester) async {
      await setupVarious(tester);
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
          of: find.byWidget(findRowByLabel(tester, channel.name)!),
          matching: find.descendant(
            of: find.byType(UnreadCountBadge),
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

      bool hasAtSign(WidgetTester tester, Widget? parent) =>
        hasIcon(tester, parent: parent, icon: ZulipIcons.at_sign);

      testWidgets('topic with a mention', (tester) async {
        await setupPage(tester,
          streams: [stream],
          subscriptions: [subscription],
          unreadMessages: [eg.streamMessage(stream: stream, topic: topic,
            flags: [MessageFlag.mentioned])]);

        check(hasAtSign(tester, findStreamHeaderRow(tester, stream.streamId)))
          .isTrue();
        check(hasAtSign(tester, findRowByLabel(tester, topic))).isTrue();
      });

      testWidgets('topic without a mention', (tester) async {
        await setupPage(tester,
          streams: [stream],
          subscriptions: [subscription],
          unreadMessages: [eg.streamMessage(stream: stream, topic: topic,
            flags: [])]);

        check(hasAtSign(tester, findStreamHeaderRow(tester, stream.streamId)))
          .isFalse();
        check(hasAtSign(tester, findRowByLabel(tester, topic))).isFalse();
      });

      testWidgets('dm with a mention', (tester) async {
        await setupPage(tester,
          users: [eg.selfUser, eg.otherUser],
          unreadMessages: [eg.dmMessage(from: eg.otherUser, to: [eg.selfUser],
            flags: [MessageFlag.mentioned])]);

        check(hasAtSign(tester, findAllDmsHeaderRow(tester))).isTrue();
        check(hasAtSign(tester, findRowByLabel(tester, eg.otherUser.fullName))).isTrue();
      });

      testWidgets('dm without mention', (tester) async {
        await setupPage(tester,
          users: [eg.selfUser, eg.otherUser],
          unreadMessages: [eg.dmMessage(from: eg.otherUser, to: [eg.selfUser],
            flags: [])]);

        check(hasAtSign(tester, findAllDmsHeaderRow(tester))).isFalse();
        check(hasAtSign(tester, findRowByLabel(tester, eg.otherUser.fullName))).isFalse();
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
        check(hasIcon(tester,
          parent: findRowByLabel(tester, topic),
          icon: ZulipIcons.follow)).isTrue();
      });

      testWidgets('followed and mentioned', (tester) async {
        await setupPage(tester,
          streams: [channel],
          subscriptions: [eg.subscription(channel)],
          unreadMessages: [eg.streamMessage(stream: channel, topic: topic,
            flags: [MessageFlag.mentioned])]);
        await store.setUserTopic(channel, topic, UserTopicVisibilityPolicy.followed);
        await tester.pump();
        check(hasIcon(tester,
          parent: findRowByLabel(tester, topic),
          icon: ZulipIcons.follow)).isTrue();
        check(hasIcon(tester,
          parent: findRowByLabel(tester, topic),
          icon: ZulipIcons.at_sign)).isTrue();
      });

      testWidgets('unmuted', (tester) async {
        await setupPage(tester,
          users: [eg.selfUser, eg.otherUser],
          streams: [channel],
          subscriptions: [eg.subscription(channel, isMuted: true)],
          unreadMessages: [message]);
        await store.setUserTopic(channel, topic, UserTopicVisibilityPolicy.unmuted);
        await tester.pump();
        check(hasIcon(tester,
          parent: findRowByLabel(tester, topic),
          icon: ZulipIcons.unmute)).isTrue();
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

        check(find.descendant(
          of: find.byWidget(findRowByLabel(tester, 'aaa')!),
          matching: find.widgetWithText(UnreadCountBadge, '1'))).findsOne();

        await store.handleEvent(eg.updateMessageFlagsRemoveEvent(MessageFlag.read, [message2]));
        await tester.pump();
        check(find.descendant(
          of: find.byWidget(findRowByLabel(tester, 'aaa')!),
          matching: find.widgetWithText(UnreadCountBadge, '2'))).findsOne();

        await store.handleEvent(eg.updateMessageFlagsRemoveEvent(MessageFlag.read, [message3]));
        await tester.pump();
        check(find.descendant(
          of: find.byWidget(findRowByLabel(tester, 'aaa')!),
          matching: find.widgetWithText(UnreadCountBadge, '3'))).findsOne();
      });
    });

    group('collapsing', () {
      Icon findHeaderCollapseIcon(WidgetTester tester, Widget headerRow) {
        return tester.widget(
          find.descendant(
            of: find.byWidget(headerRow),
            matching: find.byWidgetPredicate(
              (widget) => widget is Icon
                && (widget.icon == ZulipIcons.arrow_down
                || widget.icon == ZulipIcons.arrow_right))));
      }

      group('all-DMs section', () {
        Future<void> tapCollapseIcon(WidgetTester tester) async {
          final headerRow = findAllDmsHeaderRow(tester);
          check(headerRow).isNotNull();
          final icon = findHeaderCollapseIcon(tester, headerRow!);
          await tester.tap(find.byWidget(icon));
          await tester.pump();
        }

        /// Check that the section appears uncollapsed.
        ///
        /// For [findSectionContent], pass a [Finder] that will find some of
        /// the section's content if it is uncollapsed. The function will
        /// check that it finds something.
        void checkAppearsUncollapsed(
          WidgetTester tester,
          Finder findSectionContent,
        ) {
          final headerRow = findAllDmsHeaderRow(tester);
          check(headerRow).isNotNull();
          final icon = findHeaderCollapseIcon(tester, headerRow!);
          check(icon).icon.equals(ZulipIcons.arrow_down);
          check(allDmsHeaderBackgroundColor(tester))
            .isNotNull().isSameColorAs(const HSLColor.fromAHSL(1, 46, 0.35, 0.93).toColor());
          check(tester.widgetList(findSectionContent)).isNotEmpty();
        }

        /// Check that the section appears collapsed.
        ///
        /// For [findSectionContent], pass a [Finder] that would find some of
        /// the section's content if it were uncollapsed. The function will
        /// check that the finder comes up empty.
        void checkAppearsCollapsed(
          WidgetTester tester,
          Finder findSectionContent,
        ) {
          final headerRow = findAllDmsHeaderRow(tester);
          check(headerRow).isNotNull();
          final icon = findHeaderCollapseIcon(tester, headerRow!);
          check(icon).icon.equals(ZulipIcons.arrow_right);
          check(allDmsHeaderBackgroundColor(tester))
            .isNotNull().isSameColorAs(Colors.white);
          check(tester.widgetList(findSectionContent)).isEmpty();
        }

        testWidgets('appearance', (tester) async {
          await setupVarious(tester);

          final headerRow = findAllDmsHeaderRow(tester);
          check(headerRow).isNotNull();

          final findSectionContent = find.text(eg.otherUser.fullName);

          checkAppearsUncollapsed(tester, findSectionContent);
          await tapCollapseIcon(tester);
          checkAppearsCollapsed(tester, findSectionContent);
          await tapCollapseIcon(tester);
          checkAppearsUncollapsed(tester, findSectionContent);
        });

        testWidgets('collapse all-DMs section when partially offscreen: '
          'header remains sticky at top', (tester) async {
          await setupVarious(tester);

          final listFinder = find.byType(Scrollable);
          final dmFinder = find.text(eg.otherUser.fullName).hitTestable();

          // Scroll part of [_AllDmsSection] offscreen.
          await dragUntilInvisible(
            tester, dmFinder, listFinder, const Offset(0, -50));

          // Check that the header is present (which must therefore
          // be as a sticky header).
          check(findAllDmsHeaderRow(tester)).isNotNull();

          await tapCollapseIcon(tester);

          // Check that the header is still visible even after
          // collapsing the section.
          check(findAllDmsHeaderRow(tester)).isNotNull();
        });

        // TODO check it remains collapsed even if you scroll far away and back

        // TODO check that it's always uncollapsed when it appears after being
        //   absent, even if it was collapsed the last time it was present.
        //   (Could test multiple triggers for its reappearance: it could
        //   reappear because a new unread arrived, but with #296 it could also
        //   reappear because of a change in muted-users state.)
      });

      group('stream section', () {
        Future<void> tapCollapseIcon(WidgetTester tester, int streamId) async {
          final headerRow = findStreamHeaderRow(tester, streamId);
          check(headerRow).isNotNull();
          final icon = findHeaderCollapseIcon(tester, headerRow!);
          await tester.tap(find.byWidget(icon));
          await tester.pump();
        }

        /// Check that the section appears uncollapsed.
        ///
        /// For [findSectionContent], pass a [Finder] that will find some of
        /// the section's content if it is uncollapsed. The function will
        /// check that it finds something.
        void checkAppearsUncollapsed(
          WidgetTester tester,
          int streamId,
          Finder findSectionContent,
        ) {
          final subscription = store.subscriptions[streamId]!;
          final headerRow = findStreamHeaderRow(tester, streamId);
          check(headerRow).isNotNull();
          final collapseIcon = findHeaderCollapseIcon(tester, headerRow!);
          check(collapseIcon).icon.equals(ZulipIcons.arrow_down);
          final streamIcon = findStreamHeaderIcon(tester, streamId);
          check(streamIcon).color.isNotNull().isSameColorAs(
            ChannelColorSwatch.light(subscription.color).iconOnPlainBackground);
          check(streamHeaderBackgroundColor(tester, streamId))
            .isNotNull().isSameColorAs(ChannelColorSwatch.light(subscription.color).barBackground);
          check(tester.widgetList(findSectionContent)).isNotEmpty();
        }

        /// Check that the section appears collapsed.
        ///
        /// For [findSectionContent], pass a [Finder] that would find some of
        /// the section's content if it were uncollapsed. The function will
        /// check that the finder comes up empty.
        void checkAppearsCollapsed(
          WidgetTester tester,
          int streamId,
          Finder findSectionContent,
        ) {
          final subscription = store.subscriptions[streamId]!;
          final headerRow = findStreamHeaderRow(tester, streamId);
          check(headerRow).isNotNull();
          final collapseIcon = findHeaderCollapseIcon(tester, headerRow!);
          check(collapseIcon).icon.equals(ZulipIcons.arrow_right);
          final streamIcon = findStreamHeaderIcon(tester, streamId);
          check(streamIcon).color.isNotNull().isSameColorAs(
            ChannelColorSwatch.light(subscription.color).iconOnPlainBackground);
          check(streamHeaderBackgroundColor(tester, streamId))
            .isNotNull().isSameColorAs(Colors.white);
          check(tester.widgetList(findSectionContent)).isEmpty();
        }

        testWidgets('appearance', (tester) async {
          await setupVarious(tester);

          final headerRow = findStreamHeaderRow(tester, 1);
          check(headerRow).isNotNull();

          final findSectionContent = find.text('specific topic');

          checkAppearsUncollapsed(tester, 1, findSectionContent);
          await tapCollapseIcon(tester, 1);
          checkAppearsCollapsed(tester, 1, findSectionContent);
          await tapCollapseIcon(tester, 1);
          checkAppearsUncollapsed(tester, 1, findSectionContent);
        });

        testWidgets('uncollapsed header changes background color when [subscription.color] changes', (tester) async {
          final initialColor = Colors.indigo.argbInt;

          final stream = eg.stream(streamId: 1);
          await setupPage(tester,
            streams: [stream],
            subscriptions: [eg.subscription(stream, color: initialColor)],
            unreadMessages: [eg.streamMessage(stream: stream, topic: 'specific topic', flags: [])]);

          checkAppearsUncollapsed(tester, stream.streamId, find.text('specific topic'));

          check(streamHeaderBackgroundColor(tester, 1))
            .isNotNull().isSameColorAs(ChannelColorSwatch.light(initialColor).barBackground);

          final newColor = Colors.orange.argbInt;
          await store.handleEvent(SubscriptionUpdateEvent(id: 1, streamId: 1,
            property: SubscriptionProperty.color, value: newColor));
          await tester.pump();

          check(streamHeaderBackgroundColor(tester, 1))
            .isNotNull().isSameColorAs(ChannelColorSwatch.light(newColor).barBackground);
        });

        testWidgets('collapse stream section when partially offscreen: '
          'header remains sticky at top', (tester) async {
          await setupVarious(tester);

          final topicFinder = find.text('stream 1 topic 4').hitTestable();
          final listFinder = find.byType(Scrollable);

          // Scroll part of [_StreamSection] offscreen.
          await dragUntilInvisible(
            tester, topicFinder, listFinder, const Offset(0, -50));

          // Check that the header is present (which must therefore
          // be as a sticky header).
          check(findStreamHeaderRow(tester, 1)).isNotNull();

          await tapCollapseIcon(tester, 1);

          // Check that the header is still visible even after
          // collapsing the section.
          check(findStreamHeaderRow(tester, 1)).isNotNull();
        });

        testWidgets('collapse stream section in middle of screen: '
          'header stays fixed', (tester) async {
          await setupVarious(tester);

          final headerRow = findStreamHeaderRow(tester, 1);
          // Check that the header is present.
          check(headerRow).isNotNull();

          final rectBeforeTap = tester.getRect(find.byWidget(headerRow!));
          final scrollableTop = tester.getRect(find.byType(Scrollable)).top;
          // Check that the header is somewhere in the middle of the screen.
          check(rectBeforeTap.top).isGreaterThan(scrollableTop);

          await tapCollapseIcon(tester, 1);

          final headerRowAfterTap = findStreamHeaderRow(tester, 1);
          final rectAfterTap =
            tester.getRect(find.byWidget(headerRowAfterTap!));

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
