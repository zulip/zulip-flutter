
import 'package:checks/checks.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/route/account.dart';
import 'package:zulip/model/push_device.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/notifications/receive.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../fake_async.dart';
import 'binding.dart';
import 'store_test.dart';
import '../stdlib_checks.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late PushDeviceManager model;
  late FakeApiConnection connection;

  void prepareStore({int? zulipFeatureLevel}) {
    addTearDown(testBinding.reset);
    addTearDown(NotificationService.debugReset);
    PushDeviceManager.debugAutoPause = true;
    addTearDown(() => PushDeviceManager.debugAutoPause = false);
    store = eg.store(
      account: eg.account(user: eg.selfUser, zulipFeatureLevel: zulipFeatureLevel),
      initialSnapshot: eg.initialSnapshot(zulipFeatureLevel: zulipFeatureLevel));
    model = store.pushDevices;
    connection = store.connection as FakeApiConnection;
  }

  group('register device', () {
    test('registers', () => awaitFakeAsync((async) async {
      prepareStore();
      await store.updateAccount(AccountsCompanion(deviceId: drift.Value(null)));
      check(store.account.deviceId).isNull();

      connection.prepare(json: RegisterClientDeviceResult(deviceId: 123).toJson());
      await model.debugUnpauseRegisterToken();
      check(store.account.deviceId).equals(123);
    }));

    test('no register when already done', () => awaitFakeAsync((async) async {
      prepareStore();
      await store.updateAccount(AccountsCompanion(deviceId: drift.Value(123)));

      await model.debugUnpauseRegisterToken();
      check(store.account.deviceId).equals(123);
    }));

    test('no register when server old', () => awaitFakeAsync((async) async {
      prepareStore(zulipFeatureLevel: 468 - 1);
      await store.updateAccount(AccountsCompanion(deviceId: drift.Value(null)));

      await model.debugUnpauseRegisterToken();
      check(store.account.deviceId).isNull();
    }));
  });

  group('register token', () {
    group('legacy', () {
      void prepareStoreLegacy() {
        prepareStore(zulipFeatureLevel: 468 - 1);
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
        testBinding.firebaseMessagingInitialToken = '012abc';
        testBinding.packageInfoResult = eg.packageInfo(packageName: 'com.zulip.flutter');
        await NotificationService.instance.start();

        // On store startup, send the token.
        prepareStoreLegacy();
        connection.prepare(json: {});
        await model.debugUnpauseRegisterToken();
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
        testBinding.firebaseMessagingInitialToken = '012abc';
        testBinding.packageInfoResult = eg.packageInfo(packageName: 'com.zulip.flutter');
        final startFuture = NotificationService.instance.start();

        // TODO this test is a bit brittle in its interaction with asynchrony;
        //   to fix, probably extend TestZulipBinding to control when getToken finishes.
        //
        // The aim here is to first wait for `model.debugUnpauseRegisterToken`
        // to complete whatever it's going to do; then check no request was made;
        // and only after that wait for `NotificationService.start` to finish,
        // including its `getToken` call.

        // On store startup, send nothing (because we have nothing to send).
        prepareStoreLegacy();
        await model.debugUnpauseRegisterToken();
        check(connection.lastRequest).isNull();

        // When the token later appears, send it.
        connection.prepare(json: {});
        await startFuture;
        async.flushMicrotasks();
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

      test('on iOS, use provided app ID from packageInfo', () => awaitFakeAsync((async) async {
        final origTargetPlatform = debugDefaultTargetPlatformOverride;
        addTearDown(() => debugDefaultTargetPlatformOverride = origTargetPlatform);
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        testBinding.firebaseMessagingInitialToken = '012abc';
        testBinding.packageInfoResult = eg.packageInfo(packageName: 'com.example.test');
        await NotificationService.instance.start();

        prepareStoreLegacy();
        connection.prepare(json: {});
        await model.debugUnpauseRegisterToken();
        checkLastRequestApns(token: '012abc', appid: 'com.example.test');
      }));
    });
  });
}
