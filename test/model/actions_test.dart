import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/model/actions.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/notifications/receive.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../fake_async.dart';
import '../model/binding.dart';
import '../model/store_checks.dart';
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import 'store_test.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;

  Future<void> prepare({String? ackedPushToken = '123'}) async {
    addTearDown(testBinding.reset);
    final selfAccount = eg.selfAccount.copyWith(ackedPushToken: Value(ackedPushToken));
    await testBinding.globalStore.add(selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(selfAccount.id);
    connection = store.connection as FakeApiConnection;
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
    test('smoke', () => awaitFakeAsync((async) async {
      await prepare();
      check(testBinding.globalStore).accountIds.single.equals(eg.selfAccount.id);
      const unregisterDelay = Duration(seconds: 5);
      assert(unregisterDelay > TestGlobalStore.removeAccountDuration);
      final newConnection = separateConnection()
        ..prepare(delay: unregisterDelay, json: {'msg': '', 'result': 'success'});

      final future = logOutAccount(testBinding.globalStore, eg.selfAccount.id);
      // Unregister-token request and account removal dispatched together
      checkSingleUnregisterRequest(newConnection);
      check(testBinding.globalStore.takeDoRemoveAccountCalls())
        .single.equals(eg.selfAccount.id);

      async.elapse(TestGlobalStore.removeAccountDuration);
      await future;
      // Account removal not blocked on unregister-token response
      check(testBinding.globalStore).accountIds.isEmpty();
      check(connection.isOpen).isFalse();
      check(newConnection.isOpen).isTrue(); // still busy with unregister-token

      async.elapse(unregisterDelay - TestGlobalStore.removeAccountDuration);
      check(newConnection.isOpen).isFalse();
    }));

    test('unregister request has an error', () => awaitFakeAsync((async) async {
      await prepare();
      check(testBinding.globalStore).accountIds.single.equals(eg.selfAccount.id);
      const unregisterDelay = Duration(seconds: 5);
      assert(unregisterDelay > TestGlobalStore.removeAccountDuration);
      final exception = eg.apiExceptionUnauthorized(routeName: 'removeEtcEtcToken');
      final newConnection = separateConnection()
        ..prepare(delay: unregisterDelay, apiException: exception);

      final future = logOutAccount(testBinding.globalStore, eg.selfAccount.id);
      // Unregister-token request and account removal dispatched together
      checkSingleUnregisterRequest(newConnection);
      check(testBinding.globalStore.takeDoRemoveAccountCalls())
        .single.equals(eg.selfAccount.id);

      async.elapse(TestGlobalStore.removeAccountDuration);
      await future;
      // Account removal not blocked on unregister-token response
      check(testBinding.globalStore).accountIds.isEmpty();
      check(connection.isOpen).isFalse();
      check(newConnection.isOpen).isTrue(); // for the unregister-token request

      async.elapse(unregisterDelay - TestGlobalStore.removeAccountDuration);
      check(newConnection.isOpen).isFalse();
    }));
  });

  group('unregisterToken', () {
    testAndroidIos('smoke, happy path', () => awaitFakeAsync((async) async {
      await prepare(ackedPushToken: '123');

      final newConnection = separateConnection()
        ..prepare(json: {'msg': '', 'result': 'success'});
      final future = unregisterToken(testBinding.globalStore, eg.selfAccount.id);
      async.elapse(Duration.zero);
      await future;
      checkSingleUnregisterRequest(newConnection, expectedToken: '123');
      check(newConnection.isOpen).isFalse();
    }));

    test('fallback to current token if acked is missing', () => awaitFakeAsync((async) async {
      await prepare(ackedPushToken: null);
      NotificationService.instance.token = ValueNotifier('asdf');

      final newConnection = separateConnection()
        ..prepare(json: {'msg': '', 'result': 'success'});
      final future = unregisterToken(testBinding.globalStore, eg.selfAccount.id);
      async.elapse(Duration.zero);
      await future;
      checkSingleUnregisterRequest(newConnection, expectedToken: 'asdf');
      check(newConnection.isOpen).isFalse();
    }));

    test('no error if acked token and current token both missing', () => awaitFakeAsync((async) async {
      await prepare(ackedPushToken: null);
      NotificationService.instance.token = ValueNotifier(null);

      final newConnection = separateConnection();
      final future = unregisterToken(testBinding.globalStore, eg.selfAccount.id);
      async.flushTimers();
      await future;
      check(newConnection.takeRequests()).isEmpty();
    }));

    test('connection closed if request errors', () => awaitFakeAsync((async) async {
      await prepare(ackedPushToken: '123');

      final exception = eg.apiExceptionUnauthorized(routeName: 'removeEtcEtcToken');
      final newConnection = separateConnection()
        ..prepare(apiException: exception);
      final future = unregisterToken(testBinding.globalStore, eg.selfAccount.id);
      async.elapse(Duration.zero);
      await future;
      checkSingleUnregisterRequest(newConnection, expectedToken: '123');
      check(newConnection.isOpen).isFalse();
    }));
  });
}
