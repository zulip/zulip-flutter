import 'package:get/get.dart';

import '../../model/store.dart';

class StoreService extends GetxService {
  static StoreService get to => Get.find<StoreService>();

  final RxInt currentAccountId = 0.obs;
  final Rx<PerAccountStore?> currentStore = Rx<PerAccountStore?>(null);

  GlobalStore? _globalStore;

  void setGlobalStore(GlobalStore store) {
    _globalStore = store;
    store.addListener(_onGlobalStoreChanged);
  }

  void _onGlobalStoreChanged() {
    if (currentAccountId.value > 0) {
      final store = _globalStore?.perAccountSync(currentAccountId.value);
      currentStore.value = store;
    }
  }

  void setCurrentAccount(int accountId) {
    currentAccountId.value = accountId;
    if (_globalStore != null) {
      final store = _globalStore!.perAccountSync(accountId);
      currentStore.value = store;

      if (store == null) {
        _loadStoreAsync(accountId);
      }
    }
  }

  Future<void> _loadStoreAsync(int accountId) async {
    if (_globalStore == null) return;
    try {
      await _globalStore!.perAccount(accountId);
      final store = _globalStore!.perAccountSync(accountId);
      currentStore.value = store;
    } catch (e) {
      currentStore.value = null;
    }
  }

  PerAccountStore? get store => currentStore.value;

  PerAccountStore get requireStore {
    final store = currentStore.value;
    if (store == null) {
      throw StateError(
        'No PerAccountStore available. Make sure an account is selected.',
      );
    }
    return store;
  }

  bool get hasStore => currentStore.value != null;

  PerAccountStore? getStoreForAccount(int accountId) {
    return _globalStore?.perAccountSync(accountId);
  }

  int? get accountId =>
      currentAccountId.value > 0 ? currentAccountId.value : null;

  @override
  void onClose() {
    _globalStore?.removeListener(_onGlobalStoreChanged);
    super.onClose();
  }
}

PerAccountStore? getPerAccountStore() {
  return StoreService.to.store;
}

PerAccountStore requirePerAccountStore() {
  return StoreService.to.requireStore;
}

bool hasPerAccountStore() {
  return StoreService.to.hasStore;
}

PerAccountStore perAccountStoreOf(dynamic context) {
  return requirePerAccountStore();
}
