import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/model/push_device.dart';
import 'package:zulip/notifications/receive.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../fake_async.dart';
import 'binding.dart';
import 'store_test.dart';
import '../stdlib_checks.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('register token', () {
    late PushDeviceManager model;
    late FakeApiConnection connection;

    void prepareStore() {
      PushDeviceManager.debugAutoPause = true;
      addTearDown(() => PushDeviceManager.debugAutoPause = false);
      final store = eg.store();
      model = store.pushDevices;
      connection = store.connection as FakeApiConnection;
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
      testBinding.packageInfoResult = eg.packageInfo(packageName: 'com.zulip.flutter');
      addTearDown(NotificationService.debugReset);
      await NotificationService.instance.start();

      // On store startup, send the token.
      prepareStore();
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
      addTearDown(testBinding.reset);
      testBinding.firebaseMessagingInitialToken = '012abc';
      testBinding.packageInfoResult = eg.packageInfo(packageName: 'com.zulip.flutter');
      addTearDown(NotificationService.debugReset);
      final startFuture = NotificationService.instance.start();

      // TODO this test is a bit brittle in its interaction with asynchrony;
      //   to fix, probably extend TestZulipBinding to control when getToken finishes.
      //
      // The aim here is to first wait for `model.debugUnpauseRegisterToken`
      // to complete whatever it's going to do; then check no request was made;
      // and only after that wait for `NotificationService.start` to finish,
      // including its `getToken` call.

      // On store startup, send nothing (because we have nothing to send).
      prepareStore();
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
      addTearDown(testBinding.reset);
      testBinding.firebaseMessagingInitialToken = '012abc';
      testBinding.packageInfoResult = eg.packageInfo(packageName: 'com.example.test');
      addTearDown(NotificationService.debugReset);
      await NotificationService.instance.start();

      prepareStore();
      connection.prepare(json: {});
      await model.debugUnpauseRegisterToken();
      checkLastRequestApns(token: '012abc', appid: 'com.example.test');
    }));
  });
}
