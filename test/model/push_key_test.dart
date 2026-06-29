import 'package:checks/checks.dart';
import 'package:drift/drift.dart' as drift;
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/database.dart';
import 'package:zulip/model/store.dart';

import '../example_data.dart' as eg;
import '../fake_async.dart';
import 'binding.dart';
import 'store_checks.dart';
import 'test_store.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  test('initial load, getPushKeyById', () {
    final pushKey1 = eg.pushKey(account: eg.selfAccount, pushKeyId: 1);
    final pushKey2 = eg.pushKey(account: eg.selfAccount, pushKeyId: 2);
    final globalStore = eg.globalStore(accounts: [eg.selfAccount],
      pushKeys: [pushKey1, pushKey2]);
    final globalModel = globalStore.pushKeys;

    check(globalModel.getPushKeyById(1)).equals(pushKey1);
    check(globalModel.getPushKeyById(2)).equals(pushKey2);
    check(globalModel.getPushKeyById(3)).isNull();
  });

  test('perAccount, latestPushKey: keys exist', () {
    final time1 = 1772513819;
    final pushKey1 = eg.pushKey(account: eg.selfAccount,
      pushKeyId: 234, createdTimestamp: time1);
    final pushKey2 = eg.pushKey(account: eg.selfAccount,
      pushKeyId: 123, createdTimestamp: time1 + 300);
    final globalStore = eg.globalStore(accounts: [eg.selfAccount],
      pushKeys: [pushKey1, pushKey2]);
    final globalModel = globalStore.pushKeys;
    final model = globalModel.perAccount(eg.selfAccount.id);

    // Gets the one with latest timestamp, not greatest ID.
    // (The IDs are random.)
    assert(pushKey1.pushKeyId > pushKey2.pushKeyId);
    check(model.latestPushKey).equals(pushKey2);
  });

  test('perAccount, latestPushKey: no keys', () {
    final globalStore = eg.globalStore(accounts: [eg.selfAccount],
      pushKeys: []);
    final globalModel = globalStore.pushKeys;
    final model = globalModel.perAccount(eg.selfAccount.id);

    check(model.latestPushKey).isNull();
  });

  test('perAccount: repeated calls get same PushKeyStore', () {
    final globalStore = eg.globalStore(accounts: [eg.selfAccount]);
    final globalModel = globalStore.pushKeys;
    final model = globalModel.perAccount(eg.selfAccount.id);
    check(globalModel.perAccount(eg.selfAccount.id)).identicalTo(model);
  });

  test('removeAccount, via global store', () async {
    final globalStore = eg.globalStore(
      accounts: [eg.selfAccount, eg.otherAccount],
      pushKeys: [
        eg.pushKey(account: eg.selfAccount, pushKeyId: 1),
        eg.pushKey(account: eg.otherAccount, pushKeyId: 2),
      ]);
    final globalModel = globalStore.pushKeys;
    final model1 = globalModel.perAccount(eg.selfAccount.id);
    final model2 = globalModel.perAccount(eg.otherAccount.id);
    check(globalModel.getPushKeyById(1)).isNotNull();
    check(model1.latestPushKey?.pushKeyId).equals(1);

    await globalStore.removeAccount(eg.selfAccount.id);

    // Push key on that account is gone.
    check(globalModel.getPushKeyById(1)).isNull();
    // So is the [PushKeyStore].  To demonstrate that, (artificially)
    // request a new one and note it's different from the old.
    final newModel = globalModel.perAccount(eg.selfAccount.id);
    check(newModel).not((it) => it.identicalTo(model1));
    // The new [PushKeyStore] also shows the push key is gone.
    check(newModel.latestPushKey).isNull();

    // The other account, meanwhile, is unaffected.
    check(globalModel.perAccount(eg.otherAccount.id)).identicalTo(model2);
    check(globalModel.getPushKeyById(2)).isNotNull();
    check(model2.latestPushKey?.pushKeyId).equals(2);
  });

  test('insertPushKey, removePushKey', () async {
    final globalModel = eg.globalStore(accounts: [eg.selfAccount]).pushKeys;
    final model = globalModel.perAccount(eg.selfAccount.id);
    check(model.latestPushKey).isNull();

    final time1 = 1772513819;
    final pushKey1 = eg.pushKey(account: eg.selfAccount,
      createdTimestamp: time1);
    await model.insertPushKey(pushKey1.toCompanion(false));
    check(model.latestPushKey).equals(pushKey1);
    check(globalModel.getPushKeyById(pushKey1.pushKeyId)).equals(pushKey1);

    final pushKey2 = eg.pushKey(account: eg.selfAccount,
      createdTimestamp: time1 + 1);
    await model.insertPushKey(pushKey2.toCompanion(false));
    check(model.latestPushKey).equals(pushKey2);
    check(globalModel.getPushKeyById(pushKey1.pushKeyId)).equals(pushKey1);
    check(globalModel.getPushKeyById(pushKey2.pushKeyId)).equals(pushKey2);

    await model.removePushKey(pushKey1.pushKeyId);
    check(model.latestPushKey).equals(pushKey2);
    check(globalModel.getPushKeyById(pushKey1.pushKeyId)).isNull();
    check(globalModel.getPushKeyById(pushKey2.pushKeyId)).equals(pushKey2);

    await model.removePushKey(pushKey2.pushKeyId);
    check(model.latestPushKey).isNull();
    check(globalModel.getPushKeyById(pushKey2.pushKeyId)).isNull();
  });

  test('updatePushKey', () async {
    final globalModel = eg.globalStore(accounts: [eg.selfAccount]).pushKeys;
    final model = globalModel.perAccount(eg.selfAccount.id);

    final time1 = 1772513819;
    final pushKey1 = eg.pushKey(account: eg.selfAccount,
      createdTimestamp: time1);
    await model.insertPushKey(pushKey1.toCompanion(false));
    final pushKey2 = eg.pushKey(account: eg.selfAccount,
      createdTimestamp: time1 + 30);
    await model.insertPushKey(pushKey2.toCompanion(false));
    check(model.latestPushKey).equals(pushKey2);

    // Update one push key.
    final timeLater = 1772515410;
    await model.updatePushKey(pushKey2.pushKeyId, PushKeysCompanion(
      supersededTimestamp: drift.Value(timeLater)));
    // It's indeed updated.
    check(globalModel.getPushKeyById(pushKey2.pushKeyId))
      ..equals(pushKey2.copyWith(supersededTimestamp: drift.Value(timeLater)))
      ..identicalTo(model.latestPushKey);
    // The other push key is unaffected.
    check(globalModel.getPushKeyById(pushKey1.pushKeyId))
      ..equals(pushKey1)
      ..isNotNull().supersededTimestamp.isNull();
  });

  group('maybeRotatePushKeys', () {
    late TestGlobalStore globalStore;
    late PerAccountStore store;

    /// Set up the store, ultimately calling [PushKeyStore.maybeRotatePushKeys].
    Future<void> initStore(FakeAsync async, {
      List<PushKey>? pushKeys,
      int? ackedPushKeyId,
      int? zulipFeatureLevel,
    }) async {
      globalStore = eg.globalStore(pushKeys: pushKeys);
      await globalStore.add(eg.selfAccount, eg.initialSnapshot(
        zulipFeatureLevel: zulipFeatureLevel,
        devices: {
          eg.selfAccount.deviceId!: eg.clientDevice(pushKeyId: ackedPushKeyId),
        }));
      store = await globalStore.perAccount(eg.selfAccount.id);
      async.flushMicrotasks(); // let `maybeRotatePushKeys` complete
    }

    PushKey mkKey(int createdTimestamp, {int? supersededTimestamp}) {
      return eg.pushKey(
        account: eg.selfAccount,
        createdTimestamp: createdTimestamp,
        supersededTimestamp: supersededTimestamp,
      );
    }

    PushKey? getPushKeyById(int id) => globalStore.pushKeys.getPushKeyById(id);

    const secondsPerDay = 86400;

    group('generate new key', () {
      test('generate key when no keys exist', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        await initStore(async);
        check(store.pushKeys.latestPushKey).isNotNull()
          .createdTimestamp.equals(now);
      }));

      test('generate key when latest is old enough', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final oldKey = mkKey(now - 30 * secondsPerDay);
        await initStore(async, pushKeys: [oldKey]);
        check(store.pushKeys.latestPushKey).isNotNull()
          .createdTimestamp.equals(now);
        // The old key is still there.
        check(getPushKeyById(oldKey.pushKeyId)).isNotNull()
          ..equals(oldKey)
          ..createdTimestamp.equals(now - 30 * secondsPerDay);
      }));

      test('no new key when latest is recent', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final key = mkKey(now - 15 * secondsPerDay);
        await initStore(async, pushKeys: [key]);
        check(store.pushKeys.latestPushKey).equals(key);
      }));

      test('on old server, generate no key', () => awaitFakeAsync((async) async {
        await initStore(async, zulipFeatureLevel: 468 - 1);
        check(store.pushKeys.latestPushKey).isNull();
      }));

      test('on old server, delete any existing keys', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final key = mkKey(now - secondsPerDay);
        await initStore(async, zulipFeatureLevel: 468 - 1, pushKeys: [key]);
        check(store.pushKeys.latestPushKey).isNull();
        check(getPushKeyById(key.pushKeyId)).isNull();
      }));
    });

    group('mark superseded keys', () {
      test('mark older keys when server has acked newer key', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final oldKey = mkKey(now - 32 * secondsPerDay);
        final newKey = mkKey(now - 2 * secondsPerDay);
        await initStore(async, pushKeys: [oldKey, newKey],
          ackedPushKeyId: newKey.pushKeyId);
        check(getPushKeyById(oldKey.pushKeyId)!).supersededTimestamp.equals(now);
        check(getPushKeyById(newKey.pushKeyId)!).supersededTimestamp.isNull();
      }));

      test('act on device event', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final oldKey = mkKey(now - 31 * secondsPerDay);
        final newKey = mkKey(now - secondsPerDay);
        await initStore(async, pushKeys: [oldKey, newKey]);
        check(getPushKeyById(oldKey.pushKeyId)!).supersededTimestamp.isNull();

        // A device-update event acks the new key.
        await store.handleEvent(eg.deviceUpdateEvent(store.account.deviceId!,
          pushKeyId: JsonNullable(newKey.pushKeyId)));
        async.flushMicrotasks();
        // The older key is superseded.
        check(getPushKeyById(oldKey.pushKeyId)!).supersededTimestamp.equals(now);
        check(getPushKeyById(newKey.pushKeyId)!).supersededTimestamp.isNull();
      }));

      test('no re-mark already-superseded keys on acked new key', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final oldKey = mkKey(now - 32 * secondsPerDay,
          supersededTimestamp: now - secondsPerDay);
        final newKey = mkKey(now - 2 * secondsPerDay);
        await initStore(async, pushKeys: [oldKey, newKey],
          ackedPushKeyId: newKey.pushKeyId);
        // The already-superseded key keeps its original timestamp.
        check(getPushKeyById(oldKey.pushKeyId)!).supersededTimestamp.equals(now - secondsPerDay);
      }));

      test('mark older keys when newer key already old', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final oldKey = mkKey(now - 32 * secondsPerDay);
        final newKey = mkKey(now - 16 * secondsPerDay);
        await initStore(async, pushKeys: [oldKey, newKey]);
        check(getPushKeyById(oldKey.pushKeyId)!).supersededTimestamp.equals(now);
        check(getPushKeyById(newKey.pushKeyId)!).supersededTimestamp.isNull();
      }));

      test('no re-mark already-superseded keys on old new key', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final oldKey = mkKey(now - 32 * secondsPerDay,
          supersededTimestamp: now - secondsPerDay);
        final newKey = mkKey(now - 16 * secondsPerDay);
        await initStore(async, pushKeys: [oldKey, newKey]);
        // The already-superseded key keeps its original timestamp.
        check(getPushKeyById(oldKey.pushKeyId)!)
          .supersededTimestamp.equals(now - secondsPerDay);
      }));

      test('no superseding when newer key is new and unacked', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final oldKey = mkKey(now - 32 * secondsPerDay);
        final newKey = mkKey(now - 2 * secondsPerDay);
        await initStore(async, pushKeys: [oldKey, newKey]);
        check(getPushKeyById(oldKey.pushKeyId)!).supersededTimestamp.isNull();
        check(getPushKeyById(newKey.pushKeyId)!).supersededTimestamp.isNull();
      }));
    });

    group('delete obsolete keys', () {
      test('delete key superseded for long enough', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final oldKey = mkKey(now - 32 * secondsPerDay,
          supersededTimestamp: now - 30 * secondsPerDay);
        final currentKey = mkKey(now - 31 * secondsPerDay);
        await initStore(async, pushKeys: [oldKey, currentKey]);
        check(getPushKeyById(oldKey.pushKeyId)).isNull();
        check(getPushKeyById(currentKey.pushKeyId)).isNotNull();
      }));

      test('no delete key more recently superseded', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final oldKey = mkKey(now - 32 * secondsPerDay,
          supersededTimestamp: now - 30 * secondsPerDay + 1);
        final currentKey = mkKey(now - 31 * secondsPerDay);
        await initStore(async, pushKeys: [oldKey, currentKey]);
        check(getPushKeyById(oldKey.pushKeyId)).isNotNull();
      }));

      test('no delete non-superseded keys', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final key = mkKey(now - 32 * secondsPerDay);
        await initStore(async, pushKeys: [key]);
        check(getPushKeyById(key.pushKeyId)!).supersededTimestamp.isNull();
      }));
    });
  });
}
