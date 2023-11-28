import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/inbox.dart';
import 'package:zulip/widgets/store.dart';

import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/test_store.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;

  Future<void> setupPage(WidgetTester tester, {
    List<ZulipStream>? streams,
    List<Subscription>? subscriptions,
    List<User>? users,
    required List<Message> unreadMessages,
    NavigatorObserver? navigatorObserver,
  }) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

    store
      ..addStreams(streams ?? [])
      ..addSubscriptions(subscriptions ?? [])
      ..addUsers(users ?? [eg.selfUser]);

    for (final message in unreadMessages) {
      assert(!message.flags.contains(MessageFlag.read));
      store.handleEvent(MessageEvent(id: 1, message: message));
    }

    await tester.pumpWidget(
      GlobalStoreWidget(
        child: MaterialApp(
          navigatorObservers: [if (navigatorObserver != null) navigatorObserver],
          home: PerAccountStoreWidget(
            accountId: eg.selfAccount.id,
            child: const InboxPage()))));

    // global store and per-account store get loaded
    await tester.pumpAndSettle();
  }

  /// Set up an inbox view with lots of interesting content.
  Future<void> setupVarious(WidgetTester tester) async {
    final stream1 = eg.stream(streamId: 1, name: 'stream 1');
    final sub1 = eg.subscription(stream1);
    final stream2 = eg.stream(streamId: 2, name: 'stream 2');
    final sub2 = eg.subscription(stream2);

    await setupPage(tester,
      streams: [stream1, stream2],
      subscriptions: [sub1, sub2],
      users: [eg.selfUser, eg.otherUser, eg.thirdUser],
      unreadMessages: [
        eg.streamMessage(stream: stream1, topic: 'specific topic', flags: []),
        eg.streamMessage(stream: stream2, flags: []),
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser], flags: []),
        eg.dmMessage(from: eg.otherUser, to: [eg.selfUser, eg.thirdUser], flags: []),
      ]);
  }

  /// Find an all-DMs header element.
  // Why "an" all-DMs header element? Because there might be two: one that
  // floats at the top of the screen to give the "sticky header" effect, and one
  // that scrolls normally, the way it would in a regular [ListView].
  // TODO we'll need to find both and run checks on them, knowing which is which.
  Widget? findAllDmsHeaderRow(WidgetTester tester) {
    final rowLabel = tester.widgetList(
      find.text('Direct messages'),
    ).firstOrNull;
    if (rowLabel == null) {
      return null;
    }

    return tester.widget(
      find.ancestor(
        of: find.byWidget(rowLabel),
        matching: find.byType(Row)));
  }

  /// For the given stream ID, find a stream header element.
  // Why "an" all-DMs header element? Because there might be two: one that
  // floats at the top of the screen to give the "sticky header" effect, and one
  // that scrolls normally, the way it would in a regular [ListView].
  // TODO we'll need to find both and run checks on them, knowing which is which.
  Widget? findStreamHeaderRow(WidgetTester tester, int streamId) {
    final stream = store.streams[streamId]!;
    final rowLabel = tester.widgetList(find.text(stream.name)).firstOrNull;
    if (rowLabel == null) {
      return null;
    }

    return tester.widget(
      find.ancestor(
        of: find.byWidget(rowLabel),
        matching: find.byType(Row)));
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

  group('InboxPage', () {
    testWidgets('page builds; empty', (tester) async {
      await setupPage(tester, unreadMessages: []);
    });

    // TODO more checks: ordering, etc.
    testWidgets('page builds; not empty', (tester) async {
      await setupVarious(tester);
    });

    // TODO test that tapping a conversation row opens the message list
    //   for the conversation

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
          // TODO check bar background color
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
          // TODO check bar background color
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
          check(streamIcon).color.equals(subscription.colorSwatch().iconOnBarBackground);
          // TODO check bar background color
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
          check(streamIcon).color.equals(subscription.colorSwatch().iconOnPlainBackground);
          // TODO check bar background color
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
