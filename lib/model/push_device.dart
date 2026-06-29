import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import '../api/route/account.dart';
import '../api/route/notifications.dart';
import '../log.dart';
import '../notifications/receive.dart';
import 'binding.dart';
import 'store.dart';

/// Manages telling the server this device's push token,
/// and tracking the server's responses on the status of devices and push tokens.
class PushDeviceManager extends PerAccountStoreBase {
  PushDeviceManager({
    required super.core,
    required this._devices,
  }) {
    _init();
  }

  void _init() async {
    await _maybeRotatePushKeys();
    _registerTokenAndSubscribe();
  }

  bool _disposed = false;

  /// Cleans up resources and tells the instance not to make new API requests.
  ///
  /// After this is called, the instance is not in a usable state
  /// and should be abandoned.
  void dispose() {
    assert(!_disposed);
    NotificationService.instance.token.removeListener(_registerToken);
    _disposed = true;
  }

  /// Like [InitialSnapshot.devices], but updated with events.
  ///
  /// For docs, search for "devices"
  /// in <https://zulip.com/api/register-queue>.
  ///
  /// An absent map in [InitialSnapshot] (from an old server) is treated
  /// as empty, since a server without this feature has none of these records.
  ///
  /// See also [thisDevice].
  // TODO(server-12) simplify doc re an absent map
  late Map<int, ClientDevice> devices = UnmodifiableMapView(_devices);
  final Map<int, ClientDevice> _devices;

  /// The client-device information the server currently reports for
  /// this very install of the app, if any.
  ///
  /// This is an entry in [devices].
  ClientDevice? get thisDevice => _devices[account.deviceId];

  bool get _e2eeAvailable => zulipFeatureLevel >= 468; // TODO(server-12)

  void handleDeviceEvent(DeviceEvent event) {
    switch (event) {
      case DeviceAddEvent():
        _devices[event.deviceId] = ClientDevice(
          pushKeyId: null,
          pushTokenId: null,
          pendingPushTokenId: null,
          pushTokenLastUpdatedTimestamp: null,
          pushRegistrationErrorCode: null,
        );

      case DeviceRemoveEvent():
        _devices.remove(event.deviceId);

      case DeviceUpdateEvent():
        final device = _devices[event.deviceId];
        if (device == null) return; // TODO(log)

        if (event.pushKeyId case final v?) {
          device.pushKeyId = v.value;
          _maybeRotatePushKeys();
        }
        if (event.pushTokenId case final v?) {
          device.pushTokenId = v.value;
        }
        if (event.pendingPushTokenId case final v?) {
          device.pendingPushTokenId = v.value;
        }
        if (event.pushTokenLastUpdatedTimestamp case final v?) {
          device.pushTokenLastUpdatedTimestamp = v.value;
        }
        if (event.pushRegistrationErrorCode case final v?) {
          device.pushRegistrationErrorCode = v.value;
        }
    }
  }

  Future<void> _maybeRotatePushKeys() async {
    if (!_e2eeAvailable) {
      // Forget any existing push keys.  (It's unlikely any exist,
      // but possible if the server has been downgraded.)
      await pushKeys.removePushKeys();
      return;
    }

    await pushKeys.maybeRotatePushKeys(ackedPushKeyId: thisDevice?.pushKeyId);
  }

  /// Send this client's notification token to the server, now and if it changes.
  ///
  /// Also create on the server a device record (per [Account.deviceId]),
  /// if we don't have one already.
  // TODO(#323) track the registerPushDevice/etc request, warn if not succeeding
  void _registerTokenAndSubscribe() async {
    _debugMaybePause();
    if (_debugRegisterTokenProceed != null) {
      await _debugRegisterTokenProceed!.future;
    }

    if (account.deviceId == null
        && zulipFeatureLevel >= 468) { // TODO(server-12)
      // We haven't yet managed registerClientDevice for this account. Do it now.
      // (We'll need this logic here for as long as clients may be upgrading
      // from either old clients, or old servers, that lack this feature.
      // After that, we could set account.deviceId at login time instead.)
      final result = await registerClientDevice(connection);
      if (_disposed) return;
      await updateAccount(AccountsCompanion(
        deviceId: drift.Value(result.deviceId)));
      assert(account.deviceId != null);
    }

    NotificationService.instance.token.addListener(_registerToken);
    await _registerToken();

    _debugRegisterTokenCompleted?.complete();
  }

  Completer<void>? _debugRegisterTokenProceed;
  Completer<void>? _debugRegisterTokenCompleted;

  void _debugMaybePause() {
    assert(() {
      if (debugAutoPause) {
        _debugRegisterTokenProceed = Completer();
        _debugRegisterTokenCompleted = Completer();
      }
      return true;
    }());
  }

  /// Unpause registering the token (after [debugAutoPause]),
  /// returning a future that completes when any immediate request is completed.
  ///
  /// This has no effect if [debugAutoPause] was false
  /// when this instance was constructed,
  /// and therefore no effect outside of debug mode.
  Future<void> debugUnpauseRegisterToken() async {
    await Future<void>.delayed(Duration.zero); // TODO hack to get past _maybeRotateKeys
    _debugRegisterTokenProceed!.complete();
    await _debugRegisterTokenCompleted!.future;
  }

  /// In debug mode, controls whether new instances should pause
  /// before registering the token with the server.
  ///
  /// When paused, token registration can be unpaused
  /// with [debugUnpauseRegisterToken].
  ///
  /// Outside of debug mode, this is always false and the setter has no effect.
  static bool get debugAutoPause {
    bool result = false;
    assert(() {
      result = _debugAutoPause;
      return true;
    }());
    return result;
  }
  static bool _debugAutoPause = false;
  static set debugAutoPause(bool value) {
    assert(() {
      _debugAutoPause = value;
      return true;
    }());
  }

  Future<void> _registerToken() async {
    if (!_e2eeAvailable) {
      return _legacyRegisterToken();
    }

    assert(account.deviceId != null);

    final token = NotificationService.instance.token.value;
    if (token == null) {
      // Nothing to register.
      // (We'll show the user a warning; see [pushRegistrationStatus].)
      return;
    }

    final now = ZulipBinding.instance.utcNow();
    final timestamp = now.millisecondsSinceEpoch ~/ 1000;

    // A push key should already exist, thanks to _maybeRotatePushKeys.
    final latestPushKey = pushKeys.latestPushKey!;

    final tokenId = NotificationService.computeTokenId(token);

    final fromServer = thisDevice;

    RegisterPushDeviceKey? keyArgs;
    if (fromServer == null
        || fromServer.pushKeyId != latestPushKey.pushKeyId) {
      keyArgs = RegisterPushDeviceKey(pushKeyId: latestPushKey.pushKeyId,
        pushKey: base64Encode(latestPushKey.pushKey));
    }

    RegisterPushDeviceToken? tokenArgs;
    if (fromServer == null
        || fromServer.pushRegistrationErrorCode != null
        || (fromServer.pendingPushTokenId ?? fromServer.pushTokenId)
           != tokenId
        // This case should be impossible: if pendingPushTokenId or pushTokenId
        // is non-null, then so should the timestamp be.
        || fromServer.pushTokenLastUpdatedTimestamp == null
        || now.difference(dateTimeFromTimestamp(
             fromServer.pushTokenLastUpdatedTimestamp!))
           >= _tokenRepeatInterval) {
      final tokenKind = switch (defaultTargetPlatform) {
        TargetPlatform.android => PushTokenKind.fcm,
        TargetPlatform.iOS => PushTokenKind.apns,
        _ => throw StateError('unexpected platform: $defaultTargetPlatform'),
      };

      String? iosAppId;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final packageInfo = await ZulipBinding.instance.packageInfo;
        iosAppId = packageInfo!.packageName;
      }
      final pushRegistration = PushRegistration(
        iosAppId: iosAppId,
        tokenKind: tokenKind,
        token: token,
        timestamp: timestamp);
      final encryptedPushRegistration = await _encryptToBouncer(
        bouncerPublicKey, jsonEncode(pushRegistration));

      tokenArgs = RegisterPushDeviceToken(
        tokenKind: tokenKind,
        tokenId: tokenId,
        bouncerPublicKey: base64Encode(bouncerPublicKey),
        encryptedPushRegistration: base64Encode(encryptedPushRegistration),
      );
    }

    if (keyArgs == null && tokenArgs == null) {
      // The server is already up to date with our data.
      return;
    }

    try {
      await registerPushDevice(connection,
        deviceId: account.deviceId!, key: keyArgs, token: tokenArgs);
      assert(debugLog('registerPushDevice: success'));
    } catch (e) {
      // TODO(#1764) handle errors
    }
  }

  /// The interval at which the client should repeat telling the server
  /// its push token.
  ///
  /// This repetition is recommended in the FCM docs to do once a month:
  ///   https://firebase.google.com/docs/cloud-messaging/manage-tokens#ensuring-registration-token-freshness
  static const _tokenRepeatInterval = Duration(days: 30);

  @visibleForTesting
  static final bouncerPublicKey = base64Decode('mm4F/3WLqECY637NulC5j/ZeHkmpwmtlfIxwt8MfREM='); // generated 2026-02-24

  static Future<Uint8List> _encryptToBouncer(Uint8List publicKey, String plaintext) async {
    final sodium = await ZulipBinding.instance.sodiumInit();
    return sodium.crypto.box.seal(publicKey: publicKey,
      message: utf8.encode(plaintext));
  }

  Future<void> _legacyRegisterToken() async {
    assert(!_e2eeAvailable);

    final token = NotificationService.instance.token.value;
    if (token == null) return;

    await updateAccount(AccountsCompanion(
      possibleLegacyPushToken: drift.Value(true)));

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await addFcmToken(connection, token: token);

      case TargetPlatform.iOS:
        final packageInfo = await ZulipBinding.instance.packageInfo;
        await addApnsToken(connection,
          token: token,
          appid: packageInfo!.packageName);

      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        assert(false);
    }
  }
}
