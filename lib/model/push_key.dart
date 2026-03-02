import 'dart:math';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../api/model/model.dart';
import 'binding.dart';
import 'database.dart';
import 'store.dart';

/// A global substore for all the user's [PushKey] records.
///
/// This substore is accessed through [GlobalStore.pushKeys].
///
/// For the push keys on a given account,
/// use [perAccount] to get a [PushKeyStore].
///
/// This substore isn't a [ChangeNotifier], and no listeners are notified
/// when its data changes.  We could certainly change that
/// if we had any code that would want to listen.
class GlobalPushKeyStore {
  GlobalPushKeyStore({
    required this._backend,
    required Iterable<PushKey> data,
  }) : _pushKeys = Map.fromEntries(data.map((k) => MapEntry(k.pushKeyId, k)));

  final GlobalStoreBackend _backend;

  /// A cache of the [PushKeys] table in the underlying data store, keyed by ID.
  final Map<int, PushKey> _pushKeys;

  /// The push key with the given ID, if any.
  PushKey? getPushKeyById(int pushKeyId) => _pushKeys[pushKeyId];

  /// The existing [PushKeyStore]s, keyed by account ID.
  final Map<int, PushKeyStore> _perAccount = {};

  /// The [PushKeyStore] for the given account's push keys.
  PushKeyStore perAccount(int accountId) {
    return _perAccount[accountId] ??= PushKeyStore(
      globalPushKeys: this, accountId: accountId,
      data: _pushKeys.values.where((k) => k.accountId == accountId));
  }

  /// Remove the given account from this store's data.
  ///
  /// This should be called after the account has already been removed
  /// from the underlying data store.
  void removeAccount(int accountId) {
    // The push keys should be already gone from the database, because
    // we have cascading deletes on the foreign key at [PushKeys.accountId].
    _pushKeys.removeWhere((id, k) => k.accountId == accountId);
    _perAccount.remove(accountId);
  }

  Future<PushKey> _insertPushKey(PushKeysCompanion data) async {
    final pushKey = await _backend.doInsertPushKey(data);
    assert(!_pushKeys.containsKey(pushKey.pushKeyId));
    _pushKeys[pushKey.pushKeyId] = pushKey;
    return pushKey;
  }

  Future<PushKey> _updatePushKey(int pushKeyId, PushKeysCompanion data) async {
    assert(!data.pushKeyId.present && !data.pushKey.present);
    assert(_pushKeys.containsKey(pushKeyId));
    await _backend.doUpdatePushKey(pushKeyId, data);
    return _pushKeys.update(pushKeyId, (value) => value.copyWithCompanion(data));
  }

  Future<void> _removePushKey(int pushKeyId) async {
    assert(_pushKeys.containsKey(pushKeyId));
    await _backend.doRemovePushKey(pushKeyId);
    _pushKeys.remove(pushKeyId);
  }
}

/// A per-account substore for the user's [PushKey] records on a given account.
///
/// This substore is accessed through [PerAccountStoreBase.pushKeys].
///
/// To find push keys regardless of account, see [GlobalPushKeyStore].
///
/// This substore isn't a [ChangeNotifier], and no listeners are notified
/// when its data changes.  We could certainly change that
/// if we had any code that would want to listen.
class PushKeyStore {
  PushKeyStore({
    required this._globalPushKeys,
    required this.accountId,
    required Iterable<PushKey> data,
  }) : _pushKeys = Map.fromEntries(data.map((k) => MapEntry(k.pushKeyId, k)));

  final GlobalPushKeyStore _globalPushKeys;
  final int accountId;

  /// The push keys for this account, keyed by ID.
  ///
  /// This contains a subset of `_globalPushKeys._pushKeys`.
  final Map<int, PushKey> _pushKeys;

  /// The most recently generated push key for this account.
  PushKey? get latestPushKey => maxBy(_pushKeys.values, (k) => k.createdTimestamp);

  /// Add a push key to the store.
  ///
  /// The push key must be for this account.
  @visibleForTesting
  Future<PushKey> insertPushKey(PushKeysCompanion data) async {
    assert(data.accountId.value == accountId);
    final pushKey = await _globalPushKeys._insertPushKey(data);
    assert(!_pushKeys.containsKey(pushKey.pushKeyId));
    _pushKeys[pushKey.pushKeyId] = pushKey;
    return pushKey;
  }

  /// Update a push key in the store, returning the new version.
  ///
  /// The push key must already exist in the store and belong to this account.
  ///
  /// Some fields should never change on a push key, and must not be present
  /// in `data`: namely `pushKeyId`, `accountId`, `pushKey`, `createdTimestamp`.
  @visibleForTesting
  Future<PushKey> updatePushKey(int pushKeyId, PushKeysCompanion data) async {
    assert(_pushKeys.containsKey(pushKeyId));
    assert(!data.pushKeyId.present && !data.accountId.present
      && !data.pushKey.present && !data.createdTimestamp.present);
    final result = await _globalPushKeys._updatePushKey(pushKeyId, data);
    _pushKeys[pushKeyId] = result;
    return result;
  }

  /// Remove a push key from the store.
  ///
  /// The push key must exist in the store and belong to this account.
  @visibleForTesting
  Future<void> removePushKey(int pushKeyId) async {
    assert(_pushKeys.containsKey(pushKeyId));
    await _globalPushKeys._removePushKey(pushKeyId);
    _pushKeys.remove(pushKeyId);
  }

  /// Remove all this account's push keys from the store.
  Future<void> removePushKeys() async {
    for (final key in _pushKeys.values.toList()) {
      await removePushKey(key.pushKeyId);
    }
  }

  /// See if it's time to perform any of the steps of rotating push keys,
  /// and do those.
  Future<void> maybeRotatePushKeys({required int? ackedPushKeyId}) async {
    final now = ZulipBinding.instance.utcNow();
    final nowTimestamp = now.millisecondsSinceEpoch ~/ 1000;

    // For a given rotation of the keys, each of these steps will happen
    // in a separate call to this function.

    // Step 1: Generate a new key.
    final latestPushKey = this.latestPushKey;
    if (latestPushKey == null
        || now.difference(dateTimeFromTimestamp(latestPushKey.createdTimestamp))
           >= _keyRotationInterval) {
      // We either have no push key yet for this account,
      // or it's time to rotate the push key.  Make a new one.
      await insertPushKey(PushKeysCompanion.insert(
        pushKeyId: generatePushKeyId(),
        pushKey: generatePushKey(),
        accountId: accountId,
        createdTimestamp: nowTimestamp,
      ));
    }

    // Step 2: Send new key to the server.
    // This is done separately, in [PushDeviceManager._registerToken].

    // Step 3: Mark superseded keys as superseded.
    // 3a: A key is superseded when the server acks a newer key.
    // (The ack might come in either an event or a later initial snapshot,
    // which is why we handle it here.)
    final ackedKey = _pushKeys.values.where((k) => k.pushKeyId == ackedPushKeyId)
      .singleOrNull;
    if (ackedKey != null) {
      for (final oldKey in _pushKeys.values.where((k) =>
             k.createdTimestamp < ackedKey.createdTimestamp
             && k.supersededTimestamp == null).toList()) {
        await updatePushKey(oldKey.pushKeyId, PushKeysCompanion(
          supersededTimestamp: drift.Value(nowTimestamp)));
      }
    }

    // 3b: A key is also superseded when a newer key has existed long enough.
    // (This way, even if the server has notifications disabled and so
    // refuses to accept new keys, we eventually delete old keys.)
    final newestOldKey = maxBy(
      _pushKeys.values.where((k) =>
        now.difference(dateTimeFromTimestamp(k.createdTimestamp))
        >= _autoSupersedeDuration),
      (k) => k.createdTimestamp);
    if (newestOldKey != null) {
      for (final oldKey in _pushKeys.values.where((k) =>
             k.createdTimestamp < newestOldKey.createdTimestamp
             && k.supersededTimestamp == null).toList()) {
        await updatePushKey(oldKey.pushKeyId, PushKeysCompanion(
          supersededTimestamp: drift.Value(nowTimestamp)));
      }
    }

    // Step 4: Delete obsolete keys: those superseded far enough in the past.
    for (final obsoleteKey in _pushKeys.values.where((k) =>
           k.supersededTimestamp != null
           && now.difference(dateTimeFromTimestamp(k.supersededTimestamp!))
              >= _oldKeyRetentionDuration).toList()) {
      await removePushKey(obsoleteKey.pushKeyId);
    }
  }

  /// The age at which a push key should be replaced with a new one.
  ///
  /// Rotating the push key allows both the client and the server to
  /// eventually delete the old key (though see [_oldKeyRetentionDuration]),
  /// which is helpful in case of a later compromise of either client or server.
  static const _keyRotationInterval = Duration(days: 30);

  /// The age of a new push key at which to call old keys superseded,
  /// even if the server hasn't acknowledged the new key.
  ///
  /// This exists to ensure old keys are eventually deleted
  /// (at least provided the app is getting occasionally opened).
  ///
  /// This value is meant to be long enough that it will rarely apply unless
  /// the server can't be reached at all, or doesn't support notifications,
  /// and so in either case the old key is unlikely to be useful.
  /// In addition, after being marked superseded, the old key will
  /// be kept for [_oldKeyRetentionDuration] thereafter.
  static const _autoSupersedeDuration = Duration(days: 15);

  /// The length of time we want to retain a superseded push key.
  ///
  /// After a push key is superseded by a new key, there might still be
  /// notifications in flight that the server sent with the old key.
  ///
  /// We keep the old key around as long as it might still be possible
  /// for some such notifications to be delivered.
  //
  // FCM may store a notification-message up to 28 days while it retries
  // delivering it to the device:
  //   https://firebase.google.com/docs/cloud-messaging/customize-messages/setting-message-lifespan
  //
  // APNs may do so for up to 30 days:
  //   https://developer.apple.com/documentation/usernotifications/viewing-the-status-of-push-notifications-using-metrics-and-apns#Interpret-data-about-stored-notifications
  static const _oldKeyRetentionDuration = Duration(days: 30);

  /// Generate a suitable value to pass as `pushKeyId` to [registerPushDevice].
  static int generatePushKeyId() {
    final rand = Random.secure();
    return rand.nextInt(1 << 32);
  }

  /// Generate a suitable value to pass as `pushKey` to [registerPushDevice].
  static Uint8List generatePushKey() {
    final rand = Random.secure();
    return Uint8List.fromList([
      pushKeyTagSecretbox,
      ...Iterable.generate(32, (_) => rand.nextInt(1 << 8)),
    ]);
  }

  /// The tag byte for a libsodium secretbox-based `pushKey` value.
  ///
  /// See API doc: https://zulip.com/api/register-push-device#parameter-push_key
  @visibleForTesting
  static const pushKeyTagSecretbox = 0x31;

  @visibleForTesting
  static Uint8List secretboxKeyFromPushKey(Uint8List pushKey) {
    const keyLengthBytes = 32;
    if (pushKey.length != 1 + keyLengthBytes) {
      throw ArgumentError("Bad push key: length ${pushKey.length}");
    }
    if (pushKey[0] != pushKeyTagSecretbox) {
      throw ArgumentError("Bad push key: tag 0x${pushKey[0].toRadixString(16)}");
    }
    return Uint8List.sublistView(pushKey, 1);
  }

  static Future<Uint8List> decryptNotification(Uint8List pushKey, Uint8List cryptotext) async {
    final keyBytes = secretboxKeyFromPushKey(pushKey);

    // TODO(#1764) document how the nonce and cryptotext are packed; https://chat.zulip.org/#narrow/channel/378-api-design/topic/E2EE.20-.20cryptography/near/2352462
    const nonceLength = 24;
    final nonce = Uint8List.sublistView(cryptotext, 0, nonceLength);
    final actualCryptotext = Uint8List.sublistView(cryptotext, nonceLength);

    // The Sodium docs say to call `WidgetsFlutterBinding.ensureInitialized()`
    // before `SodiumInit.init()` (and so this `sodiumInit()`).
    // But empirically things seem to work fine without, including
    // when the app was in the background or not running.
    final sodium = await ZulipBinding.instance.sodiumInit();

    final key = sodium.secureCopy(keyBytes);
    return sodium.crypto.secretBox.openEasy(key: key,
      cipherText: actualCryptotext, nonce: nonce);
  }
}
