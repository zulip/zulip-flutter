import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/channel_list.dart';

import '../api/fake_api.dart';
import '../model/binding.dart';
import '../example_data.dart' as eg;
import '../stdlib_checks.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();
  late FakeApiConnection connection;
  late PerAccountStore store;

  Future<void> setupChannelListPage(WidgetTester tester, {
    required List<ZulipStream> streams,
    required List<Subscription> subscriptions
  }) async {
    addTearDown(testBinding.reset);
    final initialSnapshot = eg.initialSnapshot(
      subscriptions: subscriptions,
      streams: streams,
      realmUsers: [eg.selfUser]);
    await testBinding.globalStore.add(eg.selfAccount, initialSnapshot);
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    connection = store.connection as FakeApiConnection;

    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id, child: const ChannelListPage()));

    // global store, per-account store
    await tester.pumpAndSettle();
  }

  void checkItemCount(int expectedCount) {
    check(find.byType(ChannelItem).evaluate()).length.equals(expectedCount);
  }

  testWidgets('smoke', (tester) async {
    await setupChannelListPage(tester, streams: [], subscriptions: []);
    checkItemCount(0);
    check(find.text('There are no channels you can view in this organization.').evaluate()).single;
  });

  testWidgets('basic list', (tester) async {
    final streams = List.generate(3, (index) => eg.stream());
    await setupChannelListPage(tester, streams: streams, subscriptions: []);
    checkItemCount(3);
  });

  group('list ordering', () {
    Iterable<String> listedStreamNames(WidgetTester tester) => tester
      .widgetList<ChannelItem>(find.byType(ChannelItem))
      .map((e) => e.stream.name);

    List<ZulipStream> streamsFromNames(List<String> names) {
      return names.map((name) => eg.stream(name: name)).toList();
    }

    testWidgets('is alphabetically case-insensitive', (tester) async {
      final streams = streamsFromNames(['b', 'C', 'A']);
      await setupChannelListPage(tester, streams: streams, subscriptions: []);

      check(listedStreamNames(tester)).deepEquals(['A', 'b', 'C']);
    });

    testWidgets('is insensitive of user subscription', (tester) async {
      final streams = streamsFromNames(['b', 'c', 'a']);
      await setupChannelListPage(tester, streams: streams,
        subscriptions: [eg.subscription(streams[0])]);

      check(listedStreamNames(tester)).deepEquals(['a', 'b', 'c']);
    });
  });

  group('subscription toggle', () {
    final zulipLocalizations = GlobalLocalizations.zulipLocalizations;

    Future<ZulipStream> prepareSingleStream(WidgetTester tester) async {
        final stream = eg.stream();
        await setupChannelListPage(tester, streams: [stream], subscriptions: []);
        return stream;
    }

    Future<Subscription> prepareSingleSubscription(WidgetTester tester) async {
        final stream = eg.subscription(eg.stream());
        await setupChannelListPage(tester, streams: [stream], subscriptions: [stream]);
        return stream;
    }

    Future<void> tapSubscribeButton(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.add));
    }

    Future<void> tapUnsubscribeButton(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.check));
    }

    Future<void> waitAndCheckSnackbarIsShown(WidgetTester tester, String message) async {
      await tester.pump(Duration.zero);
      await tester.pumpAndSettle();
      check(find.text(message).evaluate()).isNotEmpty();
    }

    testWidgets('is affected by subscription events', (WidgetTester tester) async {
      final stream = await prepareSingleStream(tester);
      connection.prepare(json: SubscribeToChannelsResult(
        subscribed: {eg.selfUser.email: [stream.name]},
        alreadySubscribed: {}).toJson());

      check(find.byIcon(Icons.add).evaluate()).isNotEmpty();
      check(find.byIcon(Icons.check).evaluate()).isEmpty();

      await store.handleEvent(SubscriptionAddEvent(id: 1,
        subscriptions: [eg.subscription(stream)]));
      await tester.pumpAndSettle();

      check(find.byIcon(Icons.add).evaluate()).isEmpty();
      check(find.byIcon(Icons.check).evaluate()).isNotEmpty();

      await store.handleEvent(SubscriptionRemoveEvent(id: 2, streamIds: [stream.streamId]));
      await tester.pumpAndSettle();

      check(find.byIcon(Icons.add).evaluate()).isNotEmpty();
      check(find.byIcon(Icons.check).evaluate()).isEmpty();
    });

    testWidgets('is disabled while loading', (WidgetTester tester) async {
      final stream = eg.stream();
      await setupChannelListPage(tester, streams: [stream], subscriptions: []);
      connection.prepare(json: SubscribeToChannelsResult(
        subscribed: {eg.selfUser.email: [stream.name]},
        alreadySubscribed: {}).toJson());
      await tapSubscribeButton(tester);
      await tester.pump();

      check(tester.widget<IconButton>(
        find.byType(IconButton)).onPressed).isNull();

      await tester.pump(const Duration(seconds: 2));

      check(tester.widget<IconButton>(
        find.byType(IconButton)).onPressed).isNotNull();
    });

    testWidgets('is disabled while loading and enabled back when loading fails', (WidgetTester tester) async {
      final stream = eg.stream();
      await setupChannelListPage(tester, streams: [stream], subscriptions: []);
      connection.prepare(exception: http.ClientException('Oops'), delay: const Duration(seconds: 2));
      await tapSubscribeButton(tester);
      await tester.pump();

      check(tester.widget<IconButton>(
        find.byType(IconButton)).onPressed).isNull();

      await tester.pump(const Duration(seconds: 2));

      check(tester.widget<IconButton>(
        find.byType(IconButton)).onPressed).isNotNull();
    });

    group('subscribe', () {
      testWidgets('is shown only for streams that user is not subscribed to', (tester) async {
        final streams = [eg.stream(), eg.stream(), eg.subscription(eg.stream())];
        final subscriptions = [streams[2] as Subscription];
        await setupChannelListPage(tester, streams: streams, subscriptions: subscriptions);

        check(find.byIcon(Icons.add).evaluate().length).equals(2);
      });

      testWidgets('smoke api', (tester) async {
        final stream = await prepareSingleStream(tester);
        connection.prepare(json: SubscribeToChannelsResult(
          subscribed: {eg.selfUser.email: [stream.name]},
          alreadySubscribed: {}).toJson());
        await tapSubscribeButton(tester);

        await tester.pump(Duration.zero);
        await tester.pumpAndSettle();
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/users/me/subscriptions')
          ..bodyFields.deepEquals({
              'subscriptions':  jsonEncode([{'name': stream.name}])
            });
      });

      testWidgets('shows a snackbar when subscription passes', (WidgetTester tester) async {
        final stream = await prepareSingleStream(tester);
        connection.prepare(json: SubscribeToChannelsResult(
          subscribed: {eg.selfUser.email: [stream.name]},
          alreadySubscribed: {}).toJson());
        await tapSubscribeButton(tester);

        await waitAndCheckSnackbarIsShown(tester,
          zulipLocalizations.messageSubscribedToChannel(stream.name));
      });

      testWidgets('shows a snackbar when already subscribed', (WidgetTester tester) async {
        final stream = await prepareSingleStream(tester);
        connection.prepare(json: SubscribeToChannelsResult(
          subscribed: {},
          alreadySubscribed: {eg.selfUser.email: [stream.name]}).toJson());
        await tapSubscribeButton(tester);

        await waitAndCheckSnackbarIsShown(tester,
          zulipLocalizations.messageAlreadySubscribedToChannel(stream.name));
      });

      testWidgets('shows a snackbar when subscription fails', (WidgetTester tester) async {
        final stream = await prepareSingleStream(tester);
        connection.prepare(json: SubscribeToChannelsResult(
          subscribed: {},
          alreadySubscribed: {},
          unauthorized: [stream.name]).toJson());
        await tapSubscribeButton(tester);

        await waitAndCheckSnackbarIsShown(tester,
          zulipLocalizations.errorFailedToSubscribedToChannel(stream.name));
      });

      testWidgets('catch-all api errors', (WidgetTester tester) async {
        final stream = await prepareSingleStream(tester);
        connection.prepare(exception: http.ClientException('Oops'));
        await tapSubscribeButton(tester);
        await tester.pump(Duration.zero);
        await tester.pumpAndSettle();

        checkErrorDialog(tester,
          expectedTitle: zulipLocalizations.errorFailedToSubscribedToChannel(stream.name),
          expectedMessage: 'NetworkException: Oops (ClientException: Oops)');
      });
    });

    group('unsubscribe', () {
      testWidgets('is shown only for streams that user is subscribed to', (tester) async {
        final streams = [eg.stream(), eg.stream(), eg.subscription(eg.stream())];
        final subscriptions = [streams[2] as Subscription];
        await setupChannelListPage(tester, streams: streams, subscriptions: subscriptions);

        check(find.byIcon(Icons.check).evaluate().length).equals(1);
      });

      testWidgets('smoke api', (tester) async {
        final stream = await prepareSingleSubscription(tester);
        connection.prepare(json: UnsubscribeFromChannelsResult(
          removed: [stream.name],
          notRemoved: []).toJson());
        await tapUnsubscribeButton(tester);

        await tester.pump(Duration.zero);
        await tester.pumpAndSettle();
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('DELETE')
          ..url.path.equals('/api/v1/users/me/subscriptions')
          ..bodyFields.deepEquals({
              'subscriptions':  jsonEncode([stream.name])
            });
      });

      testWidgets('shows a snackbar when subscription passes', (WidgetTester tester) async {
        final stream = await prepareSingleSubscription(tester);
        connection.prepare(json: UnsubscribeFromChannelsResult(
          removed: [stream.name],
          notRemoved: []).toJson());
        await tapUnsubscribeButton(tester);

        await waitAndCheckSnackbarIsShown(tester,
          zulipLocalizations.messageUnsubscribedFromChannel(stream.name));
      });

      testWidgets('shows a snackbar when subscription fails', (WidgetTester tester) async {
        final stream = await prepareSingleSubscription(tester);
        connection.prepare(json: UnsubscribeFromChannelsResult(
          removed: [],
          notRemoved: [stream.name]).toJson());
        await tapUnsubscribeButton(tester);

        await waitAndCheckSnackbarIsShown(tester,
          zulipLocalizations.errorFailedToUnsubscribedFromChannel(stream.name));
      });

      testWidgets('catch-all api errors', (WidgetTester tester) async {
        final stream = await prepareSingleSubscription(tester);
        connection.prepare(exception: http.ClientException('Oops'));
        await tapUnsubscribeButton(tester);
        await tester.pump(Duration.zero);
        await tester.pumpAndSettle();

        checkErrorDialog(tester,
          expectedTitle: zulipLocalizations.errorFailedToUnsubscribedFromChannel(stream.name),
          expectedMessage: 'NetworkException: Oops (ClientException: Oops)');
      });
    });
  });
}
