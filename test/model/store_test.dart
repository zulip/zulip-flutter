import 'dart:async';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/events.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/api/route/realm.dart';
import 'package:zulip/model/message_list.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/log.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/notifications/receive.dart';

import '../api/fake_api.dart';
import '../api/model/model_checks.dart';
import '../example_data.dart' as eg;
import '../fake_async.dart';
import '../stdlib_checks.dart';
import 'binding.dart';
import 'store_checks.dart';
import 'test_store.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  final account1 = eg.selfAccount.copyWith(id: 1);
  final account2 = eg.otherAccount.copyWith(id: 2);

  test('GlobalStore.perAccount sequential case', () async {
    final accounts = [account1, account2];
    final globalStore = LoadingTestGlobalStore(accounts: accounts);
    List<Completer<PerAccountStore>> completers(int accountId) =>
      globalStore.completers[accountId]!;

    final future1 = globalStore.perAccount(1);
    final store1 = PerAccountStore.fromInitialSnapshot(
      globalStore: globalStore,
      accountId: 1,
      initialSnapshot: eg.initialSnapshot(),
    );
    completers(1).single.complete(store1);
    check(await future1).identicalTo(store1);
    check(await globalStore.perAccount(1)).identicalTo(store1);
    check(completers(1)).length.equals(1);

    final future2 = globalStore.perAccount(2);
    final store2 = PerAccountStore.fromInitialSnapshot(
      globalStore: globalStore,
      accountId: 2,
      initialSnapshot: eg.initialSnapshot(),
    );
    completers(2).single.complete(store2);
    check(await future2).identicalTo(store2);
    check(await globalStore.perAccount(2)).identicalTo(store2);
    check(await globalStore.perAccount(1)).identicalTo(store1);

    // Only one loadPerAccount call was made per account.
    check(completers(1)).length.equals(1);
    check(completers(2)).length.equals(1);
  });

  test('GlobalStore.perAccount concurrent case', () async {
    final accounts = [account1, account2];
    final globalStore = LoadingTestGlobalStore(accounts: accounts);
    List<Completer<PerAccountStore>> completers(int accountId) =>
      globalStore.completers[accountId]!;

    final future1a = globalStore.perAccount(1);
    final future1b = globalStore.perAccount(1);
    // These should produce just one loadPerAccount call.
    check(completers(1)).length.equals(1);

    final future2 = globalStore.perAccount(2);
    final store1 = PerAccountStore.fromInitialSnapshot(
      globalStore: globalStore,
      accountId: 1,
      initialSnapshot: eg.initialSnapshot(),
    );
    final store2 = PerAccountStore.fromInitialSnapshot(
      globalStore: globalStore,
      accountId: 2,
      initialSnapshot: eg.initialSnapshot(),
    );
    completers(1).single.complete(store1);
    completers(2).single.complete(store2);
    check(await future1a).identicalTo(store1);
    check(await future1b).identicalTo(store1);
    check(await future2).identicalTo(store2);
    check(await globalStore.perAccount(1)).identicalTo(store1);
    check(await globalStore.perAccount(2)).identicalTo(store2);
    check(completers(1)).length.equals(1);
    check(completers(2)).length.equals(1);
  });

  test('GlobalStore.perAccountSync', () async {
    final accounts = [account1, account2];
    final globalStore = LoadingTestGlobalStore(accounts: accounts);
    List<Completer<PerAccountStore>> completers(int accountId) =>
      globalStore.completers[accountId]!;

    check(globalStore.perAccountSync(1)).isNull();
    final future1 = globalStore.perAccount(1);
    check(globalStore.perAccountSync(1)).isNull();
    final store1 = PerAccountStore.fromInitialSnapshot(
      globalStore: globalStore,
      accountId: 1,
      initialSnapshot: eg.initialSnapshot(),
    );
    completers(1).single.complete(store1);
    await pumpEventQueue();
    check(globalStore.perAccountSync(1)).identicalTo(store1);
    check(await future1).identicalTo(store1);
    check(globalStore.perAccountSync(1)).identicalTo(store1);
    check(await globalStore.perAccount(1)).identicalTo(store1);
    check(completers(1)).length.equals(1);
  });

  // TODO test insertAccount

  group('GlobalStore.updateAccount', () {
    test('basic', () async {
      // Update a nullable field, and a non-nullable one.
      final account = eg.selfAccount.copyWith(
        zulipFeatureLevel: 123,
        ackedPushToken: const Value('asdf'),
      );
      final globalStore = eg.globalStore(accounts: [account]);
      final updated = await globalStore.updateAccount(account.id,
        const AccountsCompanion(
          zulipFeatureLevel: Value(234),
          ackedPushToken: Value(null),
        ));
      check(globalStore.getAccount(account.id)).identicalTo(updated);
      check(updated).equals(account.copyWith(
        zulipFeatureLevel: 234,
        ackedPushToken: const Value(null),
      ));
    });

    test('notifyListeners called', () async {
      final globalStore = eg.globalStore(accounts: [eg.selfAccount]);
      int updateCount = 0;
      globalStore.addListener(() => updateCount++);
      check(updateCount).equals(0);

      await globalStore.updateAccount(eg.selfAccount.id, const AccountsCompanion(
        zulipFeatureLevel: Value(234),
      ));
      check(updateCount).equals(1);
    });

    test('reject changing id, realmUrl, or userId', () async {
      final globalStore = eg.globalStore(accounts: [eg.selfAccount]);
      await check(globalStore.updateAccount(eg.selfAccount.id, const AccountsCompanion(
        id: Value(1234)))).throws();
      await check(globalStore.updateAccount(eg.selfAccount.id, AccountsCompanion(
        realmUrl: Value(Uri.parse('https://other.example'))))).throws();
      await check(globalStore.updateAccount(eg.selfAccount.id, const AccountsCompanion(
        userId: Value(1234)))).throws();
    });

    // TODO test database gets updated correctly (an integration test with sqlite?)
  });

  group('GlobalStore.removeAccount', () {
    void checkGlobalStore(GlobalStore store, int accountId, {
      required bool expectAccount,
      required bool expectStore,
    }) {
      expectAccount
        ? check(store.getAccount(accountId)).isNotNull()
        : check(store.getAccount(accountId)).isNull();
      expectStore
        ? check(store.perAccountSync(accountId)).isNotNull()
        : check(store.perAccountSync(accountId)).isNull();
    }

    test('when store loaded', () async {
      final globalStore = eg.globalStore();
      await globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await globalStore.perAccount(eg.selfAccount.id);

      checkGlobalStore(globalStore, eg.selfAccount.id,
        expectAccount: true, expectStore: true);
      int notifyCount = 0;
      globalStore.addListener(() => notifyCount++);

      await globalStore.removeAccount(eg.selfAccount.id);

      // TODO test that the removed store got disposed and its connection closed
      checkGlobalStore(globalStore, eg.selfAccount.id,
        expectAccount: false, expectStore: false);
      check(notifyCount).equals(1);
    });

    test('when store not loaded', () async {
      final globalStore = eg.globalStore();
      await globalStore.add(eg.selfAccount, eg.initialSnapshot());

      checkGlobalStore(globalStore, eg.selfAccount.id,
        expectAccount: true, expectStore: false);
      int notifyCount = 0;
      globalStore.addListener(() => notifyCount++);

      await globalStore.removeAccount(eg.selfAccount.id);

      checkGlobalStore(globalStore, eg.selfAccount.id,
        expectAccount: false, expectStore: false);
      check(notifyCount).equals(1);
    });

    test('when store loading', () async {
      final globalStore = LoadingTestGlobalStore(accounts: [eg.selfAccount]);
      checkGlobalStore(globalStore, eg.selfAccount.id,
        expectAccount: true, expectStore: false);

      // don't await; we'll complete/await it manually after removeAccount
      final loadingFuture = globalStore.perAccount(eg.selfAccount.id);

      checkGlobalStore(globalStore, eg.selfAccount.id,
        expectAccount: true, expectStore: false);
      int notifyCount = 0;
      globalStore.addListener(() => notifyCount++);

      await globalStore.removeAccount(eg.selfAccount.id);

      checkGlobalStore(globalStore, eg.selfAccount.id,
        expectAccount: false, expectStore: false);
      check(notifyCount).equals(1);

      globalStore.completers[eg.selfAccount.id]!.single
        .complete(eg.store(account: eg.selfAccount, initialSnapshot: eg.initialSnapshot()));
      // TODO test that the never-used store got disposed and its connection closed
      await check(loadingFuture).throws<AccountNotFoundException>();
      checkGlobalStore(globalStore, eg.selfAccount.id,
        expectAccount: false, expectStore: false);
      check(notifyCount).equals(1); // no extra notify

      check(globalStore.debugNumPerAccountStoresLoading).equals(0);
    });
  });

  group('PerAccountStore.hasPassedWaitingPeriod', () {
    final store = eg.store(initialSnapshot:
      eg.initialSnapshot(realmWaitingPeriodThreshold: 2));

    final testCases = [
      ('2024-11-25T10:00+00:00', DateTime.utc(2024, 11, 25 + 0, 10, 00), false),
      ('2024-11-25T10:00+00:00', DateTime.utc(2024, 11, 25 + 1, 10, 00), false),
      ('2024-11-25T10:00+00:00', DateTime.utc(2024, 11, 25 + 2, 09, 59), false),
      ('2024-11-25T10:00+00:00', DateTime.utc(2024, 11, 25 + 2, 10, 00), true),
      ('2024-11-25T10:00+00:00', DateTime.utc(2024, 11, 25 + 1000, 07, 00), true),
    ];

    for (final (String dateJoined, DateTime currentDate, bool hasPassedWaitingPeriod) in testCases) {
      test('user joined at $dateJoined ${hasPassedWaitingPeriod ? 'has' : "hasn't"} '
          'passed waiting period by $currentDate', () {
        final user = eg.user(dateJoined: dateJoined);
        check(store.hasPassedWaitingPeriod(user, byDate: currentDate))
          .equals(hasPassedWaitingPeriod);
      });
    }
  });

  group('PerAccountStore.handleEvent', () {
    // Mostly this method just dispatches to ChannelStore and MessageStore etc.,
    // and so most of the tests live in the test files for those
    // (but they call the handleEvent method because it's the entry point).

    group('RealmUserUpdateEvent', () {
      // TODO write more tests for handling RealmUserUpdateEvent

      test('deliveryEmail', () {
        final user = eg.user(deliveryEmail: 'a@mail.example');
        final store = eg.store(initialSnapshot: eg.initialSnapshot(
          realmUsers: [eg.selfUser, user]));

        User getUser() => store.users[user.userId]!;

        store.handleEvent(RealmUserUpdateEvent(id: 1, userId: user.userId,
          deliveryEmail: null));
        check(getUser()).deliveryEmail.equals('a@mail.example');

        store.handleEvent(RealmUserUpdateEvent(id: 1, userId: user.userId,
          deliveryEmail: const JsonNullable(null)));
        check(getUser()).deliveryEmail.isNull();

        store.handleEvent(RealmUserUpdateEvent(id: 1, userId: user.userId,
          deliveryEmail: const JsonNullable('b@mail.example')));
        check(getUser()).deliveryEmail.equals('b@mail.example');

        store.handleEvent(RealmUserUpdateEvent(id: 1, userId: user.userId,
          deliveryEmail: const JsonNullable('c@mail.example')));
        check(getUser()).deliveryEmail.equals('c@mail.example');
      });
    });
  });

  group('PerAccountStore.sendMessage', () {
    test('smoke', () async {
      final store = eg.store();
      final connection = store.connection as FakeApiConnection;
      final stream = eg.stream();
      connection.prepare(json: SendMessageResult(id: 12345).toJson());
      await store.sendMessage(
        destination: StreamDestination(stream.streamId, 'world'),
        content: 'hello');
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages')
        ..bodyFields.deepEquals({
          'type': 'stream',
          'to': stream.streamId.toString(),
          'topic': 'world',
          'content': 'hello',
          'read_by_sender': 'true',
        });
    });
  });

  group('UpdateMachine.load', () {
    late TestGlobalStore globalStore;
    late FakeApiConnection connection;

    Future<void> prepareStore({Account? account}) async {
      globalStore = TestGlobalStore(accounts: []);
      account ??= eg.selfAccount;
      await globalStore.insertAccount(account.toCompanion(false));
      connection = (globalStore.apiConnectionFromAccount(account)
        as FakeApiConnection);
      UpdateMachine.debugEnableFetchEmojiData = false;
      addTearDown(() => UpdateMachine.debugEnableFetchEmojiData = true);
      UpdateMachine.debugEnableRegisterNotificationToken = false;
      addTearDown(() => UpdateMachine.debugEnableRegisterNotificationToken = true);
    }

    void checkLastRequest() {
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/register');
    }

    test('smoke', () => awaitFakeAsync((async) async {
      await prepareStore();
      final users = [eg.selfUser, eg.otherUser];

      globalStore.useCachedApiConnections = true;
      connection.prepare(json: eg.initialSnapshot(realmUsers: users).toJson());
      final updateMachine = await UpdateMachine.load(
        globalStore, eg.selfAccount.id);
      updateMachine.debugPauseLoop();

      // TODO UpdateMachine.debugPauseLoop is too late to prevent first poll attempt;
      //    the polling retry catches the resulting NetworkException from lack of
      //    `connection.prepare`, so that doesn't fail the test, but it does
      //    clobber the recorded registerQueue request so we can't check it.
      // checkLastRequest();

      check(updateMachine.store.users.values).unorderedMatches(
        users.map((expected) => (it) => it.fullName.equals(expected.fullName)));
    }));

    test('updates account from snapshot', () => awaitFakeAsync((async) async {
      final account = eg.account(user: eg.selfUser,
        zulipVersion: '6.0+gabcd',
        zulipMergeBase: '6.0',
        zulipFeatureLevel: 123,
      );
      await prepareStore(account: account);
      check(globalStore.getAccount(account.id)).isNotNull()
        ..zulipVersion.equals('6.0+gabcd')
        ..zulipMergeBase.equals('6.0')
        ..zulipFeatureLevel.equals(123);

      globalStore.useCachedApiConnections = true;
      connection.prepare(json: eg.initialSnapshot(
        zulipVersion: '8.0+g9876',
        zulipMergeBase: '8.0',
        zulipFeatureLevel: 234,
      ).toJson());
      final updateMachine = await UpdateMachine.load(globalStore, account.id);
      updateMachine.debugPauseLoop();
      check(globalStore.getAccount(account.id)).isNotNull()
        ..identicalTo(updateMachine.store.account)
        ..zulipVersion.equals('8.0+g9876')
        ..zulipMergeBase.equals('8.0')
        ..zulipFeatureLevel.equals(234);
    }));

    test('retries registerQueue on NetworkError', () => awaitFakeAsync((async) async {
      await prepareStore();

      // Try to load, inducing an error in the request.
      globalStore.useCachedApiConnections = true;
      connection.prepare(exception: Exception('failed'));
      final future = UpdateMachine.load(globalStore, eg.selfAccount.id);
      bool complete = false;
      unawaited(future.whenComplete(() => complete = true));
      async.flushMicrotasks();
      checkLastRequest();
      check(complete).isFalse();

      // The retry doesn't happen immediately; there's a timer.
      check(async.pendingTimers).length.equals(1);
      async.elapse(Duration.zero);
      check(connection.lastRequest).isNull();
      check(async.pendingTimers).length.equals(1);

      // After a timer, we retry.
      final users = [eg.selfUser, eg.otherUser];
      connection.prepare(json: eg.initialSnapshot(realmUsers: users).toJson());
      final updateMachine = await future;
      updateMachine.debugPauseLoop();
      check(complete).isTrue();
      // checkLastRequest(); TODO UpdateMachine.debugPauseLoop was too late; see comment above
      check(updateMachine.store.users.values).unorderedMatches(
        users.map((expected) => (it) => it.fullName.equals(expected.fullName)));
    }));

    // TODO test UpdateMachine.load starts polling loop
    // TODO test UpdateMachine.load calls registerNotificationToken
  });

  group('UpdateMachine.fetchEmojiData', () {
    late UpdateMachine updateMachine;
    late PerAccountStore store;
    late FakeApiConnection connection;

    void prepareStore() {
      updateMachine = eg.updateMachine();
      store = updateMachine.store;
      connection = store.connection as FakeApiConnection;
    }

    final emojiDataUrl = Uri.parse('https://cdn.example/emoji.json');
    final data = {
      '1f642': ['smile'],
      '1f34a': ['orange', 'tangerine', 'mandarin'],
    };

    void checkLastRequest() {
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('GET')
        ..url.equals(emojiDataUrl)
        ..headers.deepEquals(kFallbackUserAgentHeader);
    }

    test('happy case', () => awaitFakeAsync((async) async {
      prepareStore();
      check(store.debugServerEmojiData).isNull();

      connection.prepare(json: ServerEmojiData(codeToNames: data).toJson());
      await updateMachine.fetchEmojiData(emojiDataUrl);
      checkLastRequest();
      check(store.debugServerEmojiData).deepEquals(data);
    }));

    test('retries on failure', () => awaitFakeAsync((async) async {
      prepareStore();
      check(store.debugServerEmojiData).isNull();

      // Try to fetch, inducing an error in the request.
      connection.prepare(exception: Exception('failed'));
      final future = updateMachine.fetchEmojiData(emojiDataUrl);
      bool complete = false;
      unawaited(future.whenComplete(() => complete = true));
      async.flushMicrotasks();
      checkLastRequest();
      check(complete).isFalse();
      check(store.debugServerEmojiData).isNull();

      // The retry doesn't happen immediately; there's a timer.
      check(async.pendingTimers).length.equals(1);
      async.elapse(Duration.zero);
      check(connection.lastRequest).isNull();
      check(async.pendingTimers).length.equals(1);

      // After a timer, we retry.
      connection.prepare(json: ServerEmojiData(codeToNames: data).toJson());
      await future;
      check(complete).isTrue();
      checkLastRequest();
      check(store.debugServerEmojiData).deepEquals(data);
    }));
  });

  group('UpdateMachine.poll', () {
    late TestGlobalStore globalStore;
    late UpdateMachine updateMachine;
    late PerAccountStore store;
    late FakeApiConnection connection;

    void updateFromGlobalStore() {
      updateMachine = globalStore.updateMachines[eg.selfAccount.id]!;
      store = updateMachine.store;
      assert(identical(store, globalStore.perAccountSync(eg.selfAccount.id)));
      connection = store.connection as FakeApiConnection;
    }

    Future<void> prepareStore({int? lastEventId}) async {
      globalStore = TestGlobalStore(accounts: []);
      await globalStore.add(eg.selfAccount, eg.initialSnapshot(
        lastEventId: lastEventId));
      await globalStore.perAccount(eg.selfAccount.id);
      updateFromGlobalStore();
    }

    void checkLastRequest({required int lastEventId}) {
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('GET')
        ..url.path.equals('/api/v1/events')
        ..url.queryParameters.deepEquals({
          'queue_id': updateMachine.queueId,
          'last_event_id': lastEventId.toString(),
        });
    }

    test('loops on success', () => awaitFakeAsync((async) async {
      await prepareStore(lastEventId: 1);
      check(updateMachine.lastEventId).equals(1);

      updateMachine.debugPauseLoop();
      updateMachine.poll();

      // Loop makes first request, and processes result.
      connection.prepare(json: GetEventsResult(events: [
        HeartbeatEvent(id: 2),
      ], queueId: null).toJson());
      updateMachine.debugAdvanceLoop();
      async.flushMicrotasks();
      checkLastRequest(lastEventId: 1);
      await Future<void>.delayed(Duration.zero);
      check(updateMachine.lastEventId).equals(2);

      // Loop makes second request, and processes result.
      connection.prepare(json: GetEventsResult(events: [
        HeartbeatEvent(id: 3),
      ], queueId: null).toJson());
      updateMachine.debugAdvanceLoop();
      async.flushMicrotasks();
      checkLastRequest(lastEventId: 2);
      await Future<void>.delayed(Duration.zero);
      check(updateMachine.lastEventId).equals(3);
    }));

    test('handles events', () => awaitFakeAsync((async) async {
      await prepareStore();
      updateMachine.debugPauseLoop();
      updateMachine.poll();

      // Pick some arbitrary event and check it gets processed on the store.
      check(store.userSettings!.twentyFourHourTime).isFalse();
      connection.prepare(json: GetEventsResult(events: [
        UserSettingsUpdateEvent(id: 2,
          property: UserSettingName.twentyFourHourTime, value: true),
      ], queueId: null).toJson());
      updateMachine.debugAdvanceLoop();
      async.flushMicrotasks();
      await Future<void>.delayed(Duration.zero);
      check(store.userSettings!.twentyFourHourTime).isTrue();
    }));

    test('handles expired queue', () => awaitFakeAsync((async) async {
      await prepareStore();
      updateMachine.debugPauseLoop();
      updateMachine.poll();
      check(globalStore.perAccountSync(store.accountId)).identicalTo(store);

      // Let the server expire the event queue.
      connection.prepare(httpStatus: 400, json: {
        'result': 'error', 'code': 'BAD_EVENT_QUEUE_ID',
        'queue_id': updateMachine.queueId,
        'msg': 'Bad event queue ID: ${updateMachine.queueId}',
      });
      updateMachine.debugAdvanceLoop();
      async.flushMicrotasks();
      await Future<void>.delayed(Duration.zero);
      check(store).isLoading.isTrue();

      // The global store has a new store.
      check(globalStore.perAccountSync(store.accountId)).not((it) => it.identicalTo(store));
      updateFromGlobalStore();
      check(store).isLoading.isFalse();

      // The new UpdateMachine updates the new store.
      updateMachine.debugPauseLoop();
      updateMachine.poll();
      check(store.userSettings!.twentyFourHourTime).isFalse();
      connection.prepare(json: GetEventsResult(events: [
        UserSettingsUpdateEvent(id: 2,
          property: UserSettingName.twentyFourHourTime, value: true),
      ], queueId: null).toJson());
      updateMachine.debugAdvanceLoop();
      async.flushMicrotasks();
      await Future<void>.delayed(Duration.zero);
      check(store.userSettings!.twentyFourHourTime).isTrue();
    }));

    test('expired queue disposes registered MessageListView instances', () => awaitFakeAsync((async) async {
      // Regression test for: https://github.com/zulip/zulip-flutter/issues/810
      await prepareStore();
      updateMachine.debugPauseLoop();
      updateMachine.poll();

      // Make sure there are [MessageListView]s in the message store.
      MessageListView.init(store: store, narrow: const MentionsNarrow());
      MessageListView.init(store: store, narrow: const StarredMessagesNarrow());
      check(store.debugMessageListViews).length.equals(2);

      // Let the server expire the event queue.
      connection.prepare(httpStatus: 400, json: {
        'result': 'error', 'code': 'BAD_EVENT_QUEUE_ID',
        'queue_id': updateMachine.queueId,
        'msg': 'Bad event queue ID: ${updateMachine.queueId}',
      });
      updateMachine.debugAdvanceLoop();
      async.flushMicrotasks();
      await Future<void>.delayed(Duration.zero);

      // The old store's [MessageListView]s have been disposed.
      // (And no exception was thrown; that was #810.)
      check(store.debugMessageListViews).isEmpty();
    }));

    void checkRetry(void Function() prepareError) {
      awaitFakeAsync((async) async {
        await prepareStore(lastEventId: 1);
        updateMachine.debugPauseLoop();
        updateMachine.poll();
        check(async.pendingTimers).length.equals(0);

        // Make the request, inducing an error in it.
        prepareError();
        updateMachine.debugAdvanceLoop();
        async.elapse(Duration.zero);
        checkLastRequest(lastEventId: 1);
        check(store).isLoading.isTrue();

        // Polling doesn't resume immediately; there's a timer.
        check(async.pendingTimers).length.equals(1);
        updateMachine.debugAdvanceLoop();
        async.flushMicrotasks();
        check(connection.lastRequest).isNull();
        check(async.pendingTimers).length.equals(1);

        // Polling continues after a timer.
        connection.prepare(json: GetEventsResult(events: [
          HeartbeatEvent(id: 2),
        ], queueId: null).toJson());
        async.flushTimers();
        checkLastRequest(lastEventId: 1);
        check(updateMachine.lastEventId).equals(2);
        check(store).isLoading.isFalse();
      });
    }

    test('retries on Server5xxException', () {
      checkRetry(() => connection.prepare(httpStatus: 500, body: 'splat'));
    });

    test('retries on NetworkException', () {
      checkRetry(() => connection.prepare(exception: Exception("failed")));
    });

    test('retries on ZulipApiException', () {
      checkRetry(() => connection.prepare(httpStatus: 400, json: {
        'result': 'error', 'code': 'BAD_REQUEST', 'msg': 'Bad request'}));
    });

    test('retries on MalformedServerResponseException', () {
      checkRetry(() => connection.prepare(httpStatus: 200, body: 'nonsense'));
    });

    group('report error', () {
      String? lastReportedError;
      String? takeLastReportedError() {
        final result = lastReportedError;
        lastReportedError = null;
        return result;
      }

      /// This is an alternative to [ZulipApp]'s implementation of
      /// [reportErrorToUserBriefly] for testing.
      Future<void> logAndReportErrorToUserBriefly(String? message, {
        String? details,
      }) async {
        if (message == null) return;
        lastReportedError = '$message\n$details';
      }

      Future<void> prepare() async {
        reportErrorToUserBriefly = logAndReportErrorToUserBriefly;
        addTearDown(() => reportErrorToUserBriefly = defaultReportErrorToUserBriefly);

        await prepareStore(lastEventId: 1);
        updateMachine.debugPauseLoop();
        updateMachine.poll();
      }

      void pollAndFail(FakeAsync async) {
        updateMachine.debugAdvanceLoop();
        async.elapse(Duration.zero);
        checkLastRequest(lastEventId: 1);
        check(store).isLoading.isTrue();
      }

      test('report non-transient errors', () => awaitFakeAsync((async) async {
        await prepare();

        connection.prepare(httpStatus: 400, json: {
          'result': 'error', 'code': 'BAD_REQUEST', 'msg': 'Bad request'});
        pollAndFail(async);
        check(takeLastReportedError()).isNotNull().startsWith(
          "Error connecting to Zulip. Retrying…\n"
          "Error connecting to Zulip at");
      }));

      test('report transient errors', () => awaitFakeAsync((async) async {
        await prepare();

        // There should be no user visible error messages during these retries.
        for (int i = 0; i < UpdateMachine.transientFailureCountNotifyThreshold; i++) {
          connection.prepare(httpStatus: 500, body: 'splat');
          pollAndFail(async);
          check(takeLastReportedError()).isNull();
          // This skips the pending polling backoff.
          async.flushTimers();
        }

        connection.prepare(httpStatus: 500, body: 'splat');
        pollAndFail(async);
        check(takeLastReportedError()).isNotNull().startsWith(
          "Error connecting to Zulip. Retrying…\n"
          "Error connecting to Zulip at");
      }));

      test('ignore boring errors', () => awaitFakeAsync((async) async {
        await prepare();

        for (int i = 0; i < UpdateMachine.transientFailureCountNotifyThreshold; i++) {
          connection.prepare(exception: const SocketException('failed'));
          pollAndFail(async);
          check(takeLastReportedError()).isNull();
          // This skips the pending polling backoff.
          async.flushTimers();
        }

        connection.prepare(exception: const SocketException('failed'));
        pollAndFail(async);
        // Normally we start showing user visible error messages for transient
        // errors after enough number of retries.
        check(takeLastReportedError()).isNull();
      }));
    });
  });

  group('UpdateMachine.registerNotificationToken', () {
    late UpdateMachine updateMachine;
    late FakeApiConnection connection;

    void prepareStore() {
      updateMachine = eg.updateMachine();
      connection = updateMachine.store.connection as FakeApiConnection;
    }

    void checkLastRequestApns({required String token, required String appid}) {
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/users/me/apns_device_token')
        ..bodyFields.deepEquals({'token': token, 'appid': appid});
    }

    void checkLastRequestFcm({required String token}) {
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/users/me/android_gcm_reg_id')
        ..bodyFields.deepEquals({'token': token});
    }

    testAndroidIos('token already known', () => awaitFakeAsync((async) async {
      // This tests the case where [NotificationService.start] has already
      // learned the token before the store is created.
      // (This is probably the common case.)
      addTearDown(testBinding.reset);
      testBinding.firebaseMessagingInitialToken = '012abc';
      addTearDown(NotificationService.debugReset);
      await NotificationService.instance.start();

      // On store startup, send the token.
      prepareStore();
      connection.prepare(json: {});
      await updateMachine.registerNotificationToken();
      if (defaultTargetPlatform == TargetPlatform.android) {
        checkLastRequestFcm(token: '012abc');
      } else {
        checkLastRequestApns(token: '012abc', appid: 'com.zulip.flutter');
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        // If the token changes, send it again.
        testBinding.firebaseMessaging.setToken('456def');
        connection.prepare(json: {});
        async.flushMicrotasks();
        checkLastRequestFcm(token: '456def');
      }
    }));

    testAndroidIos('token initially unknown', () => awaitFakeAsync((async) async {
      // This tests the case where the store is created while our
      // request for the token is still pending.
      addTearDown(testBinding.reset);
      testBinding.firebaseMessagingInitialToken = '012abc';
      addTearDown(NotificationService.debugReset);
      final startFuture = NotificationService.instance.start();

      // TODO this test is a bit brittle in its interaction with asynchrony;
      //   to fix, probably extend TestZulipBinding to control when getToken finishes.
      //
      // The aim here is to first wait for `store.registerNotificationToken`
      // to complete whatever it's going to do; then check no request was made;
      // and only after that wait for `NotificationService.start` to finish,
      // including its `getToken` call.

      // On store startup, send nothing (because we have nothing to send).
      prepareStore();
      await updateMachine.registerNotificationToken();
      check(connection.lastRequest).isNull();

      // When the token later appears, send it.
      connection.prepare(json: {});
      await startFuture;
      if (defaultTargetPlatform == TargetPlatform.android) {
        checkLastRequestFcm(token: '012abc');
      } else {
        checkLastRequestApns(token: '012abc', appid: 'com.zulip.flutter');
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        // If the token subsequently changes, send it again.
        testBinding.firebaseMessaging.setToken('456def');
        connection.prepare(json: {});
        async.flushMicrotasks();
        checkLastRequestFcm(token: '456def');
      }
    }));
  });
}

class LoadingTestGlobalStore extends TestGlobalStore {
  LoadingTestGlobalStore({required super.accounts});

  Map<int, List<Completer<PerAccountStore>>> completers = {};

  @override
  Future<PerAccountStore> doLoadPerAccount(int accountId) {
    final completer = Completer<PerAccountStore>();
    (completers[accountId] ??= []).add(completer);
    return completer.future;
  }
}

void testAndroidIos(String description, FutureOr<void> Function() body) {
  test('$description (Android)', body);
  test('$description (iOS)', () async {
    final origTargetPlatform = debugDefaultTargetPlatformOverride;
    addTearDown(() => debugDefaultTargetPlatformOverride = origTargetPlatform);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await body();
  });
}
