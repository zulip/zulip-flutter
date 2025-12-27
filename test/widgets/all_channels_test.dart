import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/all_channels.dart';
import 'package:zulip/widgets/app_bar.dart';
import 'package:zulip/widgets/button.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/remote_settings.dart';
import 'package:zulip/widgets/theme.dart';

import '../api/fake_api.dart';
import '../api/model/model_checks.dart';
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../example_data.dart' as eg;
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import 'checks.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;
  late TransitionDurationObserver transitionDurationObserver;

  final groupSettingWithSelf = eg.groupSetting(members: [eg.selfUser.userId]);

  /// Sets up the page, with [channels], any of which may be [Subscription]s.
  Future<void> setupAllChannelsPage(WidgetTester tester, {
    required List<ZulipStream> channels,
  }) async {
    addTearDown(testBinding.reset);
    final subscriptions = channels.whereType<Subscription>().toList();
    final initialSnapshot = eg.initialSnapshot(
      subscriptions: subscriptions,
      streams: channels,
    );
    await testBinding.globalStore.add(eg.selfAccount, initialSnapshot);
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    connection = store.connection as FakeApiConnection;

    transitionDurationObserver = TransitionDurationObserver();
    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
      navigatorObservers: [transitionDurationObserver],
      child: const AllChannelsPage()));

    // global store, per-account store
    await tester.pumpAndSettle();

    check(find.byType(AllChannelsPageBody)).findsOne();
    check(find.widgetWithText(ZulipAppBar, 'All channels')).findsOne();
  }

  Future<ZulipStream> addPrivateChannelWithContentAccess(String? name) async {
    final channel = eg.stream(
      name: name,
      inviteOnly: true,
      canSubscribeGroup: groupSettingWithSelf,
      canAddSubscribersGroup: groupSettingWithSelf);
    await store.addStream(channel);
    check(store.selfHasContentAccess(channel)).isTrue();
    return channel;
  }

  testWidgets('navigate to page', (tester) async {
    addTearDown(testBinding.reset);

    final channel = eg.stream();
    final initialSnapshot = eg.initialSnapshot(
      subscriptions: [eg.subscription(channel)],
      streams: [channel],
    );
    await testBinding.globalStore.add(eg.selfAccount, initialSnapshot);
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

    transitionDurationObserver = TransitionDurationObserver();
    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
      navigatorObservers: [transitionDurationObserver],
      child: const HomePage()));

    // global store, per-account store
    await tester.pumpAndSettle();

    // Switch to channels tab.
    await tester.tap(find.byIcon(ZulipIcons.hash_italic));
    await tester.pump();

    // expect menu button at the end of the list
    final finder = find.widgetWithText(
      ZulipMenuItemButton, 'All channels', skipOffstage: false);
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
    await transitionDurationObserver.pumpPastTransition(tester);

    check(find.byType(AllChannelsPageBody)).findsOne();
    check(find.widgetWithText(ZulipAppBar, 'All channels')).findsOne();
  });

  testWidgets('navigate to page from empty subscription list', (tester) async {
    addTearDown(testBinding.reset);

    final initialSnapshot = eg.initialSnapshot(
      subscriptions: [],
      streams: [],
    );
    await testBinding.globalStore.add(eg.selfAccount, initialSnapshot);
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

    transitionDurationObserver = TransitionDurationObserver();
    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
      navigatorObservers: [transitionDurationObserver],
      child: const HomePage()));

    // global store, per-account store
    await tester.pumpAndSettle();

    // Switch to channels tab.
    await tester.tap(find.byIcon(ZulipIcons.hash_italic));
    await tester.pump();

    // expect empty-content placeholder with link
    await tester.tapOnText(find.textRange.ofSubstring('All channels'));
    await tester.pump();
    await transitionDurationObserver.pumpPastTransition(tester);

    check(find.byType(AllChannelsPageBody)).findsOne();
    check(find.widgetWithText(ZulipAppBar, 'All channels')).findsOne();
  });

  testWidgets('empty', (tester) async {
    await setupAllChannelsPage(tester, channels: []);
    check(find.widgetWithText(PageBodyEmptyContentPlaceholder,
      'There are no channels you can view in this organization.')).findsOne();
  });

  testWidgets('sorting/appearance', (tester) async {
    final channel1 = eg.subscription(eg.stream(name: 'e', inviteOnly: true));
    final channel2 = eg.subscription(eg.stream(name: 'A', inviteOnly: false, isWebPublic: false));
    final channel3 = eg.subscription(eg.stream(name: 'b', inviteOnly: false, isWebPublic: true));
    final channel4 = eg.stream(name: '😀 a', inviteOnly: true);
    final channel5 = eg.stream(name: '😀 b', inviteOnly: false, isWebPublic: false);
    final channel6 = eg.stream(name: 'f', inviteOnly: false, isWebPublic: true);

    await setupAllChannelsPage(tester,
      channels: [channel1, channel2, channel3, channel4, channel5, channel6]);

    final channel7 = await addPrivateChannelWithContentAccess('d');
    check(store.streams.length).equals(7);
    await tester.pump();

    final channelsInUiOrder =
      [channel4, channel5, channel2, channel3, channel7, channel1, channel6];

    // Check that the UI list shows exactly the intended channels, in order.
    //
    // …It seems like the list-building optimization (saving resources for
    // offscreen items) would break this if there's much more than a screenful
    // of channels. For expediency we just test with less than a screenful.
    check(
      tester.widgetList(find.byType(AllChannelsListEntry))
    ).deepEquals(
      channelsInUiOrder.map<Condition<Object?>>((channel) =>
        (it) => it.isA<AllChannelsListEntry>().channel
                  .streamId.equals(channel.streamId))
    );

    // Check details of the channels.
    for (final channel in channelsInUiOrder) {
      final findElement = find.byElementPredicate((element) {
        final widget = element.widget;
        return widget is AllChannelsListEntry && widget.channel.streamId == channel.streamId;
      }, skipOffstage: false);
      final element = tester.element(findElement);
      Finder findInRow(Finder finder) =>
        find.descendant(of: findElement, matching: finder);

      final icon = tester.widget<Icon>(findInRow(find.byIcon(iconDataForStream(channel))));
      final maybeSubscription = channel is Subscription ? channel : null;
      final colorSwatch = colorSwatchFor(element, maybeSubscription);
      check(icon).color.equals(colorSwatch.iconOnPlainBackground);

      check(findInRow(find.text(channel.name))).findsOne();

      final maybeToggle = tester.widgetList<Toggle>(
        findInRow(find.byType(Toggle))).singleOrNull;
      if (store.selfHasContentAccess(channel)) {
        final isSubscribed = channel is Subscription;
        check(maybeToggle).isNotNull().value.equals(isSubscribed);
      } else {
        check(maybeToggle).isNull();
      }

      final touchTargetSize = tester.getSize(findElement);
      check(touchTargetSize.height).equals(44);
    }
  });

  testWidgets('open channel action sheet on long press', (tester) async {
    await setupAllChannelsPage(tester, channels: [eg.stream()]);

    await tester.longPress(find.byType(AllChannelsListEntry));
    await tester.pump();
    await transitionDurationObserver.pumpPastTransition(tester);

    check(find.byType(BottomSheet)).findsOne();
  });

  testWidgets('navigate to channel feed on tap', (tester) async {
    final channel = eg.stream(name: 'some-channel');
    await setupAllChannelsPage(tester, channels: [channel]);

    connection.prepare(json: eg.newestGetMessagesResult(
      foundOldest: true, messages: [eg.streamMessage(stream: channel)]).toJson());
    await tester.tap(find.byType(AllChannelsListEntry));
    await tester.pump();
    await transitionDurationObserver.pumpPastTransition(tester);

    check(find.descendant(
      of: find.byType(MessageListPage),
      matching: find.text('some-channel')),
    ).findsOne();
  });

  testWidgets('use toggle switch to subscribe/unsubscribe', (tester) async {
    final channel = eg.stream();
    await setupAllChannelsPage(tester, channels: [channel]);

    await tester.tap(find.byType(Toggle));
    check(connection.lastRequest).isA<http.Request>()
      ..method.equals('POST')
      ..url.path.equals('/api/v1/users/me/subscriptions')
      ..bodyFields.deepEquals({
        'subscriptions': jsonEncode([{'name': channel.name}]),
      });

    await store.addSubscription(eg.subscription(channel));
    await tester.pump(); // Toggle changes state

    await tester.tap(find.byType(Toggle));
    check(connection.lastRequest).isA<http.Request>()
      ..method.equals('DELETE')
      ..url.path.equals('/api/v1/users/me/subscriptions')
      ..bodyFields.deepEquals({
        'subscriptions': jsonEncode([channel.name]),
      });
  });

  testWidgets('Toggle "off" to unsubscribe, public channel', (tester) async {
    final channel = eg.stream(inviteOnly: false);
    final subscription = eg.subscription(channel);

    await setupAllChannelsPage(tester, channels: [subscription]);

    connection.prepare(json: {});
    await tester.tap(find.byType(Toggle));
    await tester.pump(Duration.zero);
    checkNoDialog(tester);
    check(connection.lastRequest).isA<http.Request>()
      ..method.equals('DELETE')
      ..url.path.equals('/api/v1/users/me/subscriptions')
      ..bodyFields.deepEquals({
        'subscriptions': jsonEncode([channel.name]),
      });
  });

  testWidgets('Toggle "off" to unsubscribe, but without resubscribe permission', (tester) async {
    final channel = eg.stream(
      inviteOnly: true, canSubscribeGroup: eg.groupSetting(members: []));
    final subscription = eg.subscription(channel);

    (Widget, Widget) checkConfirmDialog() => checkSuggestedActionDialog(tester,
      expectedTitle: 'Unsubscribe from #${channel.name}?',
      expectedMessage: 'Once you leave this channel, you will not be able to rejoin.',
      expectDestructiveActionButton: true,
      expectedActionButtonText: 'Unsubscribe');

    await setupAllChannelsPage(tester, channels: [subscription]);

    await tester.tap(find.byType(Toggle));
    await tester.pump();
    final (_, cancelButton) = checkConfirmDialog();
    await tester.tap(find.byWidget(cancelButton));
    await tester.pumpAndSettle();
    check(connection.lastRequest).isNull();
    await tester.pump(RemoteSettingBuilder.localEchoIdleTimeout);

    await tester.tap(find.byType(Toggle));
    await tester.pump();
    final (unsubscribeButton, _) = checkConfirmDialog();
    await tester.tap(find.byWidget(unsubscribeButton));
    check(connection.lastRequest).isA<http.Request>()
      ..method.equals('DELETE')
      ..url.path.equals('/api/v1/users/me/subscriptions')
      ..bodyFields.deepEquals({
        'subscriptions': jsonEncode([channel.name]),
      });
  });
}
