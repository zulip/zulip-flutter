import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

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
    required GlobalStoreBackend backend,
    required Iterable<PushKey> data,
  }) : _backend = backend,
       _pushKeys = Map.fromEntries(data.map((k) => MapEntry(k.pushKeyId, k)));

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
    required GlobalPushKeyStore globalPushKeys,
    required this.accountId,
    required Iterable<PushKey> data,
  }) : _globalPushKeys = globalPushKeys,
       _pushKeys = Map.fromEntries(data.map((k) => MapEntry(k.pushKeyId, k)));

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
}
