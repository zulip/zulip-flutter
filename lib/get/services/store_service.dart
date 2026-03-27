import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../api/core.dart';
import '../../model/store.dart';
import '../../notifications/push_notification_service.dart';
import 'account_service.dart';
import 'domains/users/users_service.dart';
import 'domains/channels/channels_service.dart';
import 'domains/messages/messages_service.dart';
import 'domains/unreads/unreads_service.dart';
import 'domains/presence/presence_service.dart';
import 'domains/typing/typing_service.dart';
import 'domains/groups/groups_service.dart';
import 'domains/realm/realm_service.dart';
import 'domains/settings/settings_service.dart';

class StoreService extends GetxService {
  static StoreService get to => Get.find<StoreService>();

  final RxInt currentAccountId = 0.obs;
  final Rx<PerAccountStore?> currentStore = Rx<PerAccountStore?>(null);

  ApiConnection? get connection => AccountService.to.connection;

  GlobalStore? _globalStore;

  void setGlobalStore(GlobalStore store) {
    if (_globalStore != null) {
      _globalStore!.removeListener(_onGlobalStoreChanged);
    }
    _globalStore = store;
    store.addListener(_onGlobalStoreChanged);
  }

  void _onGlobalStoreChanged() {
    if (currentAccountId.value > 0) {
      final store = _globalStore?.perAccountSync(currentAccountId.value);
      currentStore.value = store;
      if (store != null) {
        _syncAllServices();
      }
    }
  }

  void setCurrentAccount(int accountId) {
    currentAccountId.value = accountId;
    if (_globalStore != null) {
      final store = _globalStore!.perAccountSync(accountId);
      currentStore.value = store;

      if (store != null) {
        _syncAllServices();
      } else {
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
      if (store != null) {
        _syncAllServices();
      }
    } catch (e) {
      currentStore.value = null;
    }
  }

  void _syncAllServices() {
    if (AccountService.to.accountId == null) return;
    UsersService.to.syncFromStore();
    ChannelsService.to.syncFromStore();
    MessagesService.to.syncFromStore();
    UnreadsService.to.syncFromStore();
    PresenceService.to.syncFromStore();
    TypingService.to.syncFromStore();
    GroupsService.to.syncFromStore();
    RealmService.to.syncFromStore();
    SettingsService.to.syncFromStore();

    // Register for push notifications
    try {
      PushNotificationService.to.registerDeviceForPushNotifications(
        currentAccountId.value,
      );
    } catch (e) {
      debugPrint('Failed to register push notifications: $e');
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

  UsersService get users => UsersService.to;
  ChannelsService get channels => ChannelsService.to;
  MessagesService get messages => MessagesService.to;
  UnreadsService get unreads => UnreadsService.to;
  PresenceService get presence => PresenceService.to;
  TypingService get typing => TypingService.to;
  GroupsService get groups => GroupsService.to;
  RealmService get realm => RealmService.to;
  SettingsService get settings => SettingsService.to;

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
