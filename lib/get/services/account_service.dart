import 'package:get/get.dart';

import '../../../api/core.dart';

import 'domains/users/users_service.dart';
import 'domains/channels/channels_service.dart';
import 'domains/messages/messages_service.dart';
import 'domains/unreads/unreads_service.dart';
import 'domains/presence/presence_service.dart';
import 'domains/typing/typing_service.dart';
import 'domains/groups/groups_service.dart';
import 'domains/realm/realm_service.dart';
import 'domains/settings/settings_service.dart';

class AccountService extends GetxService {
  static AccountService get to => Get.find<AccountService>();

  final Rx<int?> _accountId = Rx<int?>(null);
  int? get accountId => _accountId.value;

  final Rx<ApiConnection?> _connection = Rx<ApiConnection?>(null);
  ApiConnection? get connection => _connection.value;

  final Rx<int?> _selfUserId = Rx<int?>(null);
  int? get selfUserId => _selfUserId.value;

  UsersService get users => UsersService.to;
  ChannelsService get channels => ChannelsService.to;
  MessagesService get messages => MessagesService.to;
  UnreadsService get unreads => UnreadsService.to;
  PresenceService get presence => PresenceService.to;
  TypingService get typing => TypingService.to;
  GroupsService get groups => GroupsService.to;
  RealmService get realm => RealmService.to;
  SettingsService get settings => SettingsService.to;

  void setAccount(int accountId, ApiConnection connection, int selfUserId) {
    _accountId.value = accountId;
    _connection.value = connection;
    _selfUserId.value = selfUserId;
  }

  void clear() {
    _accountId.value = null;
    _connection.value = null;
    _selfUserId.value = null;
    users.clear();
    channels.clear();
    messages.clear();
    unreads.clear();
    presence.clear();
    typing.clear();
    groups.clear();
    realm.clear();
    settings.clear();
  }

  static Future<void> initServices() async {
    Get.put(UsersService());
    Get.put(ChannelsService());
    Get.put(MessagesService());
    Get.put(UnreadsService());
    Get.put(PresenceService());
    Get.put(TypingService());
    Get.put(GroupsService());
    Get.put(RealmService());
    Get.put(SettingsService());
    Get.put(AccountService());
  }
}
