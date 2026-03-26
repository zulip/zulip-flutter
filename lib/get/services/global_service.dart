import 'dart:async';

import 'package:get/get.dart';

import '../../api/core.dart';
import '../../api/route/realm.dart';
import '../../model/settings.dart';
import '../../model/server_support.dart';
import '../../model/store.dart';
import '../../model/binding.dart';

class GlobalService extends GetxService {
  static GlobalService get to => Get.find<GlobalService>();

  final Rx<GlobalStore?> currentGlobalStore = Rx<GlobalStore?>(null);
  final Rx<GlobalSettingsStore?> currentSettingsStore =
      Rx<GlobalSettingsStore?>(null);
  final RxBool isInitialized = false.obs;

  Future<void> initialize() async {
    final store = await ZulipBinding.instance.getGlobalStoreUniquely();
    currentGlobalStore.value = store;
    currentSettingsStore.value = store.settings;
    isInitialized.value = true;
  }

  void setGlobalStore(GlobalStore store) {
    currentGlobalStore.value = store;
    currentSettingsStore.value = store.settings;
    isInitialized.value = true;
  }

  GlobalStore? get globalStore => currentGlobalStore.value;
  GlobalSettingsStore? get settingsStore => currentSettingsStore.value;

  ApiConnection createConnection({
    required Uri realmUrl,
    required int? zulipFeatureLevel,
    String? email,
    String? apiKey,
  }) {
    return globalStore?.apiConnection(
          realmUrl: realmUrl,
          zulipFeatureLevel: zulipFeatureLevel,
          email: email,
          apiKey: apiKey,
        ) ??
        (throw StateError('GlobalStore not initialized'));
  }

  ApiConnection createConnectionFromAccount(Account account) {
    return globalStore?.apiConnectionFromAccount(account) ??
        (throw StateError('GlobalStore not initialized'));
  }

  Future<PerAccountStore?> loadPerAccountStore(int accountId) async {
    final store = globalStore?.perAccountSync(accountId);
    if (store != null) return store;

    return await globalStore?.perAccount(accountId);
  }

  PerAccountStore? getPerAccountStoreSync(int accountId) {
    return globalStore?.perAccountSync(accountId);
  }

  Account? getAccount(int accountId) {
    return globalStore?.getAccount(accountId);
  }

  Iterable<Account> get accounts => globalStore?.accounts ?? [];

  Iterable<int> get accountIds => globalStore?.accountIds ?? [];

  Account? get lastVisitedAccount => globalStore?.lastVisitedAccount;

  int? get lastVisitedAccountId =>
      globalStore?.settings.getInt(IntGlobalSetting.lastVisitedAccountId);

  Future<void> setLastVisitedAccount(int accountId) async {
    await globalStore?.setLastVisitedAccount(accountId);
  }

  Future<int> insertAccount(AccountsCompanion data) async {
    return await globalStore!.insertAccount(data);
  }

  Future<Account> updateAccount(int accountId, AccountsCompanion data) async {
    return await globalStore!.updateAccount(accountId, data);
  }

  Future<Account> updateZulipVersionData(
    int accountId,
    ZulipVersionData data,
  ) async {
    return await globalStore!.updateZulipVersionData(accountId, data);
  }

  Future<Account> updateRealmData(
    int accountId, {
    required String realmName,
    required Uri realmIcon,
  }) async {
    return await globalStore!.updateRealmData(
      accountId,
      realmName: realmName,
      realmIcon: realmIcon,
    );
  }

  Future<GetServerSettingsResult> fetchServerSettings(Uri realmUrl) async {
    return await globalStore!.fetchServerSettings(realmUrl);
  }

  void refreshRealmMetadata() {
    globalStore?.refreshRealmMetadata();
  }

  Future<void> logOutAccount(int accountId) async {
    if (globalStore == null) return;

    final account = globalStore!.getAccount(accountId);
    if (account == null) return;

    unawaited(() async {
      final connection = createConnectionFromAccount(account);
      try {
        await connection.get(
          'unregisterDevice',
          (json) => null,
          'users/me/android_gcm_reg_id',
          null,
        );
      } finally {
        connection.close();
      }
    }());

    await globalStore!.removeAccount(accountId);
  }

  void clear() {
    currentGlobalStore.value = null;
    currentSettingsStore.value = null;
    isInitialized.value = false;
  }
}
