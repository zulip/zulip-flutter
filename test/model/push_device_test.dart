import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:drift/drift.dart' as drift;
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/account.dart';
import 'package:zulip/model/push_device.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/notifications/receive.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../fake_async.dart';
import 'binding.dart';
import 'store_checks.dart';
import 'store_test.dart';
import '../stdlib_checks.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late PushDeviceManager model;
  late FakeApiConnection connection;

  Future<void> prepareStore({
    int? zulipFeatureLevel,
    List<PushKey>? pushKeys,
    ClientDevice? device,
  }) async {
    addTearDown(testBinding.reset);
    addTearDown(NotificationService.debugReset);
    PushDeviceManager.debugAutoPause = true;
    addTearDown(() => PushDeviceManager.debugAutoPause = false);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot(
      zulipFeatureLevel: zulipFeatureLevel,
      devices: {eg.selfAccount.deviceId!: ?device},
    ));
    for (final pushKey in pushKeys ?? <PushKey>[]) {
      await testBinding.globalStore.pushKeys.perAccount(eg.selfAccount.id)
        .insertPushKey(pushKey.toCompanion(false));
    }
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    model = store.pushDevices;
    connection = store.connection as FakeApiConnection;
  }

  group('register device', () {
    test('registers', () => awaitFakeAsync((async) async {
      await prepareStore();
      await store.updateAccount(AccountsCompanion(deviceId: drift.Value(null)));
      check(store.account.deviceId).isNull();

      connection.prepare(json: RegisterClientDeviceResult(deviceId: 123).toJson());
      await model.debugUnpauseRegisterToken();
      check(store.account.deviceId).equals(123);
    }));

    test('no register when already done', () => awaitFakeAsync((async) async {
      await prepareStore();
      await store.updateAccount(AccountsCompanion(deviceId: drift.Value(123)));

      await model.debugUnpauseRegisterToken();
      check(store.account.deviceId).equals(123);
    }));

    test('no register when server old', () => awaitFakeAsync((async) async {
      await prepareStore(zulipFeatureLevel: 468 - 1);
      await store.updateAccount(AccountsCompanion(deviceId: drift.Value(null)));

      await model.debugUnpauseRegisterToken();
      check(store.account.deviceId).isNull();
    }));
  });

  group('register token', () {
    group('e2ee', () { // TODO(server-12) un-nest this when legacy version gone
      const someToken = '012abc';
      const otherToken = '345def';

      late int now;

      // This prepares the case where [NotificationService.start] has already
      // learned the token before the store is created.
      // (This is probably the common case.)
      Future<void> prepareToken(String token) async {
        now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        testBinding.firebaseMessagingInitialToken = token;
        testBinding.packageInfoResult = eg.packageInfo(packageName: 'com.zulip.flutter');
        await NotificationService.instance.start();
      }

      PushKey mkKey({int? age}) {
        return eg.pushKey(account: eg.selfAccount,
          createdTimestamp: now - (age ?? Duration.secondsPerDay));
      }

      ClientDevice mkClientDevice({
        PushKey? key,
        String? token, String? pendingToken, int? age, String? errorCode,
      }) {
        return eg.clientDevice(
          pushKeyId: key?.pushKeyId,
          pushTokenId: token == null ? null :
            NotificationService.computeTokenId(token),
          pendingPushTokenId: pendingToken == null ? null :
            NotificationService.computeTokenId(pendingToken),
          pushTokenLastUpdatedTimestamp:
            (token == null && pendingToken == null) ? null
              : now - (age ?? Duration.secondsPerDay),
          pushRegistrationErrorCode: errorCode,
        );
      }

      Future<Object?> decodeAsBouncer(String encrypted) async {
        final sodium = await testBinding.sodiumInit();
        final decrypted = sodium.crypto.box.sealOpen(
          cipherText: base64Decode(encrypted),
          publicKey: PushDeviceManager.bouncerPublicKey,
          secretKey: sodium.secureCopy(Uint8List(0)));
        return jsonUtf8Decoder.convert(decrypted);
      }

      Future<void> checkLastRequest({required PushKey? key, required String? token}) async {
        assert(key != null || token != null);

        final request = connection.takeRequests().single as http.Request;
        check(request)
          ..method.equals('POST')
          ..url.path.equals('/api/v1/mobile_push/register')
          ..bodyFields.keys.deepEquals([
            'device_id',
            if (key != null) ...['push_key_id', 'push_key'],
            if (token != null) ...[
              'token_kind', 'token_id',
              'bouncer_public_key', 'encrypted_push_registration',
            ],
          ]);
        if (key != null) {
          check(request).bodyFields
            ..['push_key_id'].equals(key.pushKeyId.toString())
            ..['push_key'].equals(base64Encode(key.pushKey));
        }
        if (token != null) {
          final tokenKind = (defaultTargetPlatform == TargetPlatform.android)
            ? 'fcm' : 'apns';
          final tokenId = NotificationService.computeTokenId(token);
          check(request).bodyFields
            ..['token_kind'].equals(tokenKind)
            ..['token_id'].equals(tokenId)
            ..['bouncer_public_key'].equals(base64Encode(PushDeviceManager.bouncerPublicKey));
          final encrypted = request.bodyFields['encrypted_push_registration']!;
          check(await decodeAsBouncer(encrypted))
            .isA<Map<String, Object?>>().deepEquals({
              'token_kind': tokenKind,
              'token': token,
              'timestamp': testBinding.utcNow().millisecondsSinceEpoch ~/ 1000,
              'ios_app_id': defaultTargetPlatform == TargetPlatform.iOS
                ? (await testBinding.packageInfo)!.packageName
                : null,
            });
        }
      }

      Future<void> checkRegister(FakeAsync async,
          {required PushKey? key, required String? token}) async {
        final expectRequest = (key != null || token != null);
        if (expectRequest) {
          connection.prepare(json: {});
        }
        await model.debugUnpauseRegisterToken();
        async.flushMicrotasks();
        if (expectRequest) {
          await checkLastRequest(key: key, token: token);
        } else {
          check(connection.takeRequests()).isEmpty();
        }
      }

      // TODO(#1764) run some of these tests for iOS too, once e2ee enabled there

      test('initial run: send key and token', () => awaitFakeAsync((async) async {
        await prepareToken(someToken);
        // Start with no key and no ClientDevice ack from the server.
        await prepareStore();
        // (A key is generated when the store is created.)
        final key = store.pushKeys.latestPushKey!;
        await checkRegister(async, key: key, token: someToken);
      }));

      test('do nothing when all set', () => awaitFakeAsync((async) async {
        await prepareToken(someToken);
        final pushKey = mkKey();
        await prepareStore(pushKeys: [pushKey],
          device: mkClientDevice(key: pushKey, token: someToken));
        await checkRegister(async, key: null, token: null);
      }));

      test('have key but no ack: send key and token', () => awaitFakeAsync((async) async {
        await prepareToken(someToken);
        final pushKey = mkKey();
        await prepareStore(pushKeys: [pushKey]);
        await checkRegister(async, key: pushKey, token: someToken);
      }));

      test('update key on rotate', () => awaitFakeAsync((async) async {
        await prepareToken(someToken);
        // Start out registered, but with an old key.
        final oldKey = mkKey(age: 31 * Duration.secondsPerDay);
        await prepareStore(pushKeys: [oldKey],
          device: mkClientDevice(key: oldKey, token: someToken));
        // The store will generate a new key.
        final newKey = store.pushKeys.latestPushKey!;
        check(newKey).pushKeyId.not((it) => it.equals(oldKey.pushKeyId));
        // The new key gets sent to the server, without a token.
        await checkRegister(async, key: newKey, token: null);
      }));

      test('resend token on error', () => awaitFakeAsync((async) async {
        await prepareToken(someToken);
        final pushKey = mkKey();
        await prepareStore(pushKeys: [pushKey],
          device: mkClientDevice(key: pushKey, token: someToken,
            errorCode: 'ERROR_OCCURRED'));
        await checkRegister(async, key: null, token: someToken);
      }));

      test('update token when server has old token', () => awaitFakeAsync((async) async {
        await prepareToken(someToken);
        final pushKey = mkKey();
        await prepareStore(pushKeys: [pushKey],
          device: mkClientDevice(key: pushKey, token: otherToken));
        await checkRegister(async, key: null, token: someToken);
      }));

      test('update token when server has old token pending', () => awaitFakeAsync((async) async {
        await prepareToken(someToken);
        final pushKey = mkKey();
        await prepareStore(pushKeys: [pushKey],
          device: mkClientDevice(key: pushKey,
            // The server even has the new/current token as pushTokenId.
            // We nevertheless resend, because it has an old/wrong token pending.
            token: someToken, pendingToken: otherToken));
        await checkRegister(async, key: null, token: someToken);
      }));

      test('resend token when old', () => awaitFakeAsync((async) async {
        await prepareToken(someToken);
        final pushKey = mkKey();
        await prepareStore(pushKeys: [pushKey],
          device: mkClientDevice(key: pushKey, token: someToken,
            age: 31 * Duration.secondsPerDay));
        await checkRegister(async, key: null, token: someToken);
      }));

      test('update when token changes', () => awaitFakeAsync((async) async {
        // At startup, everything's up to date.
        await prepareToken(someToken);
        final pushKey = mkKey();
        await prepareStore(pushKeys: [pushKey],
          device: mkClientDevice(key: pushKey, token: someToken));
        await checkRegister(async, key: null, token: null);

        // Then the token changes.  Send it to the server.
        testBinding.firebaseMessaging.setToken(otherToken);
        connection.prepare(json: {});
        async.flushMicrotasks();
        await checkLastRequest(key: null, token: otherToken);
      }));

      test('token initially unknown; send when known', () => awaitFakeAsync((async) async {
        // This tests the case where the store is created while our
        // request for the token is still pending.
        testBinding.firebaseMessagingInitialToken = someToken;
        testBinding.packageInfoResult = eg.packageInfo(packageName: 'com.zulip.flutter');
        final startFuture = Future<void>.delayed(Duration(milliseconds: 100))
          .then((_) => NotificationService.instance.start());

        // TODO this test is a bit brittle in its interaction with asynchrony;
        //   to fix, probably extend TestZulipBinding to control when getToken finishes.
        //
        // The aim here is to first wait for `model.debugUnpauseRegisterToken`
        // to complete whatever it's going to do; then check no request was made;
        // and only after that wait for `NotificationService.start` to finish,
        // including its `getToken` call.

        // On store startup, send nothing (because we have nothing to send).
        await prepareStore();
        final key = store.pushKeys.latestPushKey!;
        await model.debugUnpauseRegisterToken();
        check(connection.lastRequest).isNull();

        // When the token later appears, send it.
        connection.prepare(json: {});
        await startFuture;
        async.flushMicrotasks();
        await checkLastRequest(key: key, token: someToken);

        // If the token subsequently changes, send it again.
        testBinding.firebaseMessaging.setToken(otherToken);
        connection.prepare(json: {});
        async.flushMicrotasks();
        await checkLastRequest(key: key, token: otherToken);
      }));
    });

    group('legacy', () {
      Future<void> prepareStoreLegacy() async {
        await prepareStore(zulipFeatureLevel: 468 - 1);
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
        await prepareStoreLegacy();
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
        final startFuture = Future<void>.delayed(Duration(milliseconds: 100))
          .then((_) => NotificationService.instance.start());

        // TODO this test is a bit brittle in its interaction with asynchrony;
        //   to fix, probably extend TestZulipBinding to control when getToken finishes.
        //
        // The aim here is to first wait for `model.debugUnpauseRegisterToken`
        // to complete whatever it's going to do; then check no request was made;
        // and only after that wait for `NotificationService.start` to finish,
        // including its `getToken` call.

        // On store startup, send nothing (because we have nothing to send).
        await prepareStoreLegacy();
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

        await prepareStoreLegacy();
        connection.prepare(json: {});
        await model.debugUnpauseRegisterToken();
        checkLastRequestApns(token: '012abc', appid: 'com.example.test');
      }));

      test('set possibleLegacyPushToken', () => awaitFakeAsync((async) async {
        testBinding.firebaseMessagingInitialToken = '012abc';
        await NotificationService.instance.start();

        await prepareStoreLegacy();
        check(store.account).possibleLegacyPushToken.isFalse();

        // Start registering the token.  Make the request take a while.
        connection.prepare(json: {}, delay: Duration(seconds: 1));
        final future = model.debugUnpauseRegisterToken();
        await Future<void>.delayed(Duration.zero);

        // The possibleLegacyPushToken flag is now true,
        // even before the register request completes.
        check(store.account).possibleLegacyPushToken.isTrue();

        await Future<void>.delayed(Duration(seconds: 1));
        await future;
        checkLastRequestFcm(token: '012abc');
      }));
    });
  });

  // For tests of _maybeRotatePushKeys and its call sites, see push_key_test.dart.
}
