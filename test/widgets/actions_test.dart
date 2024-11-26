import 'dart:async';
import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/exception.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/narrow.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/notifications/receive.dart';
import 'package:zulip/widgets/actions.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/inbox.dart';
import 'package:zulip/widgets/page.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/store_checks.dart';
import '../model/test_store.dart';
import '../model/unreads_checks.dart';
import '../stdlib_checks.dart';
import '../test_navigation.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;
  late BuildContext context;

  Future<void> prepare(WidgetTester tester, {
    UnreadMessagesSnapshot? unreadMsgs,
    String? ackedPushToken = '123',
  }) async {
    addTearDown(testBinding.reset);
    final selfAccount = eg.selfAccount.copyWith(ackedPushToken: Value(ackedPushToken));
    await testBinding.globalStore.add(selfAccount, eg.initialSnapshot(
      unreadMsgs: unreadMsgs));
    store = await testBinding.globalStore.perAccount(selfAccount.id);
    connection = store.connection as FakeApiConnection;

    await tester.pumpWidget(TestZulipApp(accountId: selfAccount.id,
      child: const Scaffold(body: Placeholder())));
    await tester.pump();
    context = tester.element(find.byType(Placeholder));
  }

  /// Creates and caches a new [FakeApiConnection] in [TestGlobalStore].
  ///
  /// In live code, [unregisterToken] makes a new [ApiConnection] for the
  /// unregister-token request instead of reusing the store's connection.
  /// To enable callers to prepare responses for that request, this function
  /// creates a new [FakeApiConnection] and caches it in [TestGlobalStore]
  /// for [unregisterToken] to pick up.
  ///
  /// Call this instead of just turning on
  /// [TestGlobalStore.useCachedApiConnections] so that [unregisterToken]
  /// doesn't try to call `close` twice on the same connection instance,
  /// which isn't allowed. (Once by the unregister-token code
  /// and once as part of removing the account.)
  FakeApiConnection separateConnection() {
    testBinding.globalStore
      ..clearCachedApiConnections()
      ..useCachedApiConnections = true;
    return testBinding.globalStore
      .apiConnectionFromAccount(eg.selfAccount) as FakeApiConnection;
  }

  String unregisterApiPathForPlatform(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android => '/api/v1/users/me/android_gcm_reg_id',
      TargetPlatform.iOS     => '/api/v1/users/me/apns_device_token',
      _                      => throw Error(),
    };
  }

  void checkSingleUnregisterRequest(
    FakeApiConnection connection, {
    String? expectedToken,
  }) {
    final subject = check(connection.takeRequests()).single.isA<http.Request>()
      ..method.equals('DELETE')
      ..url.path.equals(unregisterApiPathForPlatform(defaultTargetPlatform));
    if (expectedToken != null) {
      subject.bodyFields.deepEquals({'token': expectedToken});
    }
  }

  group('logOutAccount', () {
    testWidgets('smoke', (tester) async {
      await prepare(tester);
      check(testBinding.globalStore).accountIds.single.equals(eg.selfAccount.id);
      const unregisterDelay = Duration(seconds: 5);
      assert(unregisterDelay > TestGlobalStore.removeAccountDuration);
      final newConnection = separateConnection()
        ..prepare(delay: unregisterDelay, json: {'msg': '', 'result': 'success'});

      final future = logOutAccount(context, eg.selfAccount.id);
      // Unregister-token request and account removal dispatched together
      checkSingleUnregisterRequest(newConnection);
      check(testBinding.globalStore.takeDoRemoveAccountCalls())
        .single.equals(eg.selfAccount.id);

      await tester.pump(TestGlobalStore.removeAccountDuration);
      await future;
      // Account removal not blocked on unregister-token response
      check(testBinding.globalStore).accountIds.isEmpty();
      check(connection.isOpen).isFalse();
      check(newConnection.isOpen).isTrue(); // still busy with unregister-token

      await tester.pump(unregisterDelay - TestGlobalStore.removeAccountDuration);
      check(newConnection.isOpen).isFalse();
    });

    testWidgets('unregister request has an error', (tester) async {
      await prepare(tester);
      check(testBinding.globalStore).accountIds.single.equals(eg.selfAccount.id);
      const unregisterDelay = Duration(seconds: 5);
      assert(unregisterDelay > TestGlobalStore.removeAccountDuration);
      final exception = ZulipApiException(
        httpStatus: 401,
        code: 'UNAUTHORIZED',
        data: {"result": "error", "msg": "Invalid API key", "code": "UNAUTHORIZED"},
        routeName: 'removeEtcEtcToken',
        message: 'Invalid API key',
      );
      final newConnection = separateConnection()
        ..prepare(delay: unregisterDelay, exception: exception);

      final future = logOutAccount(context, eg.selfAccount.id);
      // Unregister-token request and account removal dispatched together
      checkSingleUnregisterRequest(newConnection);
      check(testBinding.globalStore.takeDoRemoveAccountCalls())
        .single.equals(eg.selfAccount.id);

      await tester.pump(TestGlobalStore.removeAccountDuration);
      await future;
      // Account removal not blocked on unregister-token response
      check(testBinding.globalStore).accountIds.isEmpty();
      check(connection.isOpen).isFalse();
      check(newConnection.isOpen).isTrue(); // for the unregister-token request

      await tester.pump(unregisterDelay - TestGlobalStore.removeAccountDuration);
      check(newConnection.isOpen).isFalse();
    });

    testWidgets("logged-out account's routes removed from nav; other accounts' remain", (tester) async {
      Future<void> makeUnreadTopicInInbox(int accountId, String topic) async {
        final stream = eg.stream();
        final message = eg.streamMessage(stream: stream, topic: topic);
        final store = await testBinding.globalStore.perAccount(accountId);
        await store.addStream(stream);
        await store.addSubscription(eg.subscription(stream));
        await store.addMessage(message);
        await tester.pump();
      }

      addTearDown(testBinding.reset);

      final account1 = eg.account(id: 1, user: eg.user());
      final account2 = eg.account(id: 2, user: eg.user());
      await testBinding.globalStore.add(account1, eg.initialSnapshot());
      await testBinding.globalStore.add(account2, eg.initialSnapshot());

      final testNavObserver = TestNavigatorObserver();
      await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
      await tester.pump();
      final navigator = await ZulipApp.navigator;
      navigator.popUntil((_) => false); // clear starting routes
      await tester.pumpAndSettle();

      final pushedRoutes = <Route<dynamic>>[];
      testNavObserver.onPushed = (route, prevRoute) => pushedRoutes.add(route);
      // TODO(#737): switch to a realistic setup:
      //   https://github.com/zulip/zulip-flutter/pull/1076#discussion_r1874124363
      final account1Route = MaterialAccountWidgetRoute(
        accountId: account1.id, page: const InboxPageBody());
      final account2Route = MaterialAccountWidgetRoute(
        accountId: account2.id, page: const InboxPageBody());
      unawaited(navigator.push(account1Route));
      unawaited(navigator.push(account2Route));
      await tester.pumpAndSettle();
      check(pushedRoutes).deepEquals([account1Route, account2Route]);

      await makeUnreadTopicInInbox(account1.id, 'topic in account1');
      final findAccount1PageContent = find.text('topic in account1', skipOffstage: false);

      await makeUnreadTopicInInbox(account2.id, 'topic in account2');
      final findAccount2PageContent = find.text('topic in account2', skipOffstage: false);

      final findLoadingPage = find.byType(LoadingPlaceholderPage, skipOffstage: false);

      check(findAccount1PageContent).findsOne();
      check(findLoadingPage).findsNothing();

      final removedRoutes = <Route<dynamic>>[];
      testNavObserver.onRemoved = (route, prevRoute) => removedRoutes.add(route);

      final context = tester.element(find.byType(MaterialApp));
      final future = logOutAccount(context, account1.id);
      await tester.pump(TestGlobalStore.removeAccountDuration);
      await future;
      check(removedRoutes).single.identicalTo(account1Route);
      check(findAccount1PageContent).findsNothing();
      check(findLoadingPage).findsOne();

      await tester.pump();
      check(findAccount1PageContent).findsNothing();
      check(findLoadingPage).findsNothing();
      check(findAccount2PageContent).findsOne();
    });
  });

  group('unregisterToken', () {
    testWidgets('smoke, happy path', (tester) async {
      await prepare(tester, ackedPushToken: '123');

      final newConnection = separateConnection()
        ..prepare(json: {'msg': '', 'result': 'success'});
      final future = unregisterToken(testBinding.globalStore, eg.selfAccount.id);
      await tester.pump(Duration.zero);
      await future;
      checkSingleUnregisterRequest(newConnection, expectedToken: '123');
      check(newConnection.isOpen).isFalse();
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('fallback to current token if acked is missing', (tester) async {
      await prepare(tester, ackedPushToken: null);
      NotificationService.instance.token = ValueNotifier('asdf');

      final newConnection = separateConnection()
        ..prepare(json: {'msg': '', 'result': 'success'});
      final future = unregisterToken(testBinding.globalStore, eg.selfAccount.id);
      await tester.pump(Duration.zero);
      await future;
      checkSingleUnregisterRequest(newConnection, expectedToken: 'asdf');
      check(newConnection.isOpen).isFalse();
    });

    testWidgets('no error if acked token and current token both missing', (tester) async {
      await prepare(tester, ackedPushToken: null);
      NotificationService.instance.token = ValueNotifier(null);

      final newConnection = separateConnection();
      final future = unregisterToken(testBinding.globalStore, eg.selfAccount.id);
      await tester.pumpAndSettle();
      await future;
      check(newConnection.takeRequests()).isEmpty();
    });

    testWidgets('connection closed if request errors', (tester) async {
      await prepare(tester, ackedPushToken: '123');

      final newConnection = separateConnection()
        ..prepare(exception: ZulipApiException(
            httpStatus: 401,
            code: 'UNAUTHORIZED',
            data: {"result": "error", "msg": "Invalid API key", "code": "UNAUTHORIZED"},
            routeName: 'removeEtcEtcToken',
            message: 'Invalid API key',
          ));
      final future = unregisterToken(testBinding.globalStore, eg.selfAccount.id);
      await tester.pump(Duration.zero);
      await future;
      checkSingleUnregisterRequest(newConnection, expectedToken: '123');
      check(newConnection.isOpen).isFalse();
    });
  });

  group('markNarrowAsRead', () {
    testWidgets('smoke test on modern server', (tester) async {
      final narrow = TopicNarrow.ofMessage(eg.streamMessage());
      await prepare(tester);
      connection.prepare(json: UpdateMessageFlagsForNarrowResult(
        processedCount: 11, updatedCount: 3,
        firstProcessedId: null, lastProcessedId: null,
        foundOldest: true, foundNewest: true).toJson());
      final future = markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
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
    });

    testWidgets('use is:unread optimization', (tester) async {
      const narrow = CombinedFeedNarrow();
      await prepare(tester);
      connection.prepare(json: UpdateMessageFlagsForNarrowResult(
        processedCount: 11, updatedCount: 3,
        firstProcessedId: null, lastProcessedId: null,
        foundOldest: true, foundNewest: true).toJson());
      final future = markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/flags/narrow')
        ..bodyFields.deepEquals({
            'anchor': 'oldest',
            'include_anchor': 'false',
            'num_before': '0',
            'num_after': '1000',
            'narrow': json.encode([{'operator': 'is', 'operand': 'unread'}]),
            'op': 'add',
            'flag': 'read',
          });
    });

    testWidgets('on mark-all-as-read when Unreads.oldUnreadsMissing: true', (tester) async {
      const narrow = CombinedFeedNarrow();
      await prepare(tester);
      store.unreads.oldUnreadsMissing = true;

      connection.prepare(json: UpdateMessageFlagsForNarrowResult(
        processedCount: 11, updatedCount: 3,
        firstProcessedId: null, lastProcessedId: null,
        foundOldest: true, foundNewest: true).toJson());
      final future = markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
      check(store.unreads.oldUnreadsMissing).isFalse();
    });

    testWidgets('CombinedFeedNarrow on legacy server', (tester) async {
      const narrow = CombinedFeedNarrow();
      await prepare(tester);
      // Might as well test with oldUnreadsMissing: true.
      store.unreads.oldUnreadsMissing = true;

      connection.zulipFeatureLevel = 154;
      connection.prepare(json: {});
      final future = markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/mark_all_as_read')
        ..bodyFields.deepEquals({});

      // Check that [Unreads.handleAllMessagesReadSuccess] wasn't called;
      // in the legacy protocol, that'd be redundant with the mark-read event.
      check(store.unreads).oldUnreadsMissing.isTrue();
    });

    testWidgets('ChannelNarrow on legacy server', (tester) async {
      final stream = eg.stream();
      final narrow = ChannelNarrow(stream.streamId);
      await prepare(tester);
      connection.zulipFeatureLevel = 154;
      connection.prepare(json: {});
      final future = markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/mark_stream_as_read')
        ..bodyFields.deepEquals({
            'stream_id': stream.streamId.toString(),
          });
    });

    testWidgets('TopicNarrow on legacy server', (tester) async {
      final narrow = TopicNarrow.ofMessage(eg.streamMessage());
      await prepare(tester);
      connection.zulipFeatureLevel = 154;
      connection.prepare(json: {});
      final future = markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/mark_topic_as_read')
        ..bodyFields.deepEquals({
            'stream_id': narrow.streamId.toString(),
            'topic_name': narrow.topic,
          });
    });

    testWidgets('DmNarrow on legacy server', (tester) async {
      final message = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]);
      final narrow = DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId);
      final unreadMsgs = eg.unreadMsgs(dms: [
        UnreadDmSnapshot(otherUserId: eg.otherUser.userId,
          unreadMessageIds: [message.id]),
      ]);
      await prepare(tester, unreadMsgs: unreadMsgs);
      connection.zulipFeatureLevel = 154;
      connection.prepare(json:
        UpdateMessageFlagsResult(messages: [message.id]).toJson());
      final future = markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/flags')
        ..bodyFields.deepEquals({
            'messages': jsonEncode([message.id]),
            'op': 'add',
            'flag': 'read',
          });
    });

    testWidgets('MentionsNarrow on legacy server', (tester) async {
      const narrow = MentionsNarrow();
      final message = eg.streamMessage(flags: [MessageFlag.mentioned]);
      final unreadMsgs = eg.unreadMsgs(mentions: [message.id]);
      await prepare(tester, unreadMsgs: unreadMsgs);
      connection.zulipFeatureLevel = 154;
      connection.prepare(json:
        UpdateMessageFlagsResult(messages: [message.id]).toJson());
      final future = markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/flags')
        ..bodyFields.deepEquals({
            'messages': jsonEncode([message.id]),
            'op': 'add',
            'flag': 'read',
          });
    });
  });

  group('updateMessageFlagsStartingFromAnchor', () {
    String onCompletedMessage(int count) => 'onCompletedMessage($count)';
    const progressMessage = 'progressMessage';
    const onFailedTitle = 'onFailedTitle';
    final narrow = TopicNarrow.ofMessage(eg.streamMessage());
    final apiNarrow = narrow.apiEncode()..add(ApiNarrowIs(IsOperand.unread));

    Future<bool> invokeUpdateMessageFlagsStartingFromAnchor() =>
      updateMessageFlagsStartingFromAnchor(
        context: context,
        apiNarrow: apiNarrow,
        op: UpdateMessageFlagsOp.add,
        flag: MessageFlag.read,
        includeAnchor: false,
        anchor: AnchorCode.oldest,
        onCompletedMessage: onCompletedMessage,
        onFailedTitle: onFailedTitle,
        progressMessage: progressMessage);

    testWidgets('smoke test', (tester) async {
      await prepare(tester);
      connection.prepare(json: UpdateMessageFlagsForNarrowResult(
        processedCount: 11, updatedCount: 3,
        firstProcessedId: 1, lastProcessedId: 1980,
        foundOldest: true, foundNewest: true).toJson());
      final didPass = invokeUpdateMessageFlagsStartingFromAnchor();
      await tester.pump(Duration.zero);
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
      check(await didPass).isTrue();
    });

    testWidgets('pagination', (tester) async {
      // Check that `lastProcessedId` returned from an initial
      // response is used as `anchorId` for the subsequent request.
      await prepare(tester);

      connection.prepare(json: UpdateMessageFlagsForNarrowResult(
        processedCount: 1000, updatedCount: 890,
        firstProcessedId: 1, lastProcessedId: 1989,
        foundOldest: true, foundNewest: false).toJson());
      final didPass = invokeUpdateMessageFlagsStartingFromAnchor();
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

      connection.prepare(json: UpdateMessageFlagsForNarrowResult(
        processedCount: 20, updatedCount: 10,
        firstProcessedId: 2000, lastProcessedId: 2023,
        foundOldest: false, foundNewest: true).toJson());
      await tester.pump(Duration.zero);
      check(find.bySubtype<SnackBar>().evaluate()).length.equals(1);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/flags/narrow')
        ..bodyFields.deepEquals({
            'anchor': '1989',
            'include_anchor': 'false',
            'num_before': '0',
            'num_after': '1000',
            'narrow': jsonEncode(apiNarrow),
            'op': 'add',
            'flag': 'read',
          });
      check(await didPass).isTrue();
    });

    testWidgets('on invalid response', (tester) async {
      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
      await prepare(tester);
      connection.prepare(json: UpdateMessageFlagsForNarrowResult(
        processedCount: 1000, updatedCount: 0,
        firstProcessedId: null, lastProcessedId: null,
        foundOldest: true, foundNewest: false).toJson());
      final didPass = invokeUpdateMessageFlagsStartingFromAnchor();
      await tester.pump(Duration.zero);
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
      checkErrorDialog(tester,
        expectedTitle: onFailedTitle,
        expectedMessage: zulipLocalizations.errorInvalidResponse);
      check(await didPass).isFalse();
    });

    testWidgets('catch-all api errors', (tester) async {
      await prepare(tester);
      connection.prepare(exception: http.ClientException('Oops'));
      final didPass = invokeUpdateMessageFlagsStartingFromAnchor();
      await tester.pump(Duration.zero);
      checkErrorDialog(tester,
        expectedTitle: onFailedTitle,
        expectedMessage: 'NetworkException: Oops (ClientException: Oops)');
      check(await didPass).isFalse();
    });
  });
}
