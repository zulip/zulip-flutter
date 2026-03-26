import 'package:get/get.dart';

import '../../../../api/model/model.dart';
import '../../store_service.dart';

class UsersService extends GetxService {
  static UsersService get to => Get.find<UsersService>();

  void syncFromStore() {
    // Data is accessed directly from store via StoreService
    // This method exists for potential future caching optimization
  }

  User? getUser(int userId) {
    return StoreService.to.store?.getUser(userId);
  }

  User? get selfUser {
    return StoreService.to.store?.selfUser;
  }

  int get selfUserId {
    return StoreService.to.store?.selfUserId ?? 0;
  }

  Iterable<User> get allUsers {
    return StoreService.to.store?.allUsers ?? [];
  }

  bool isUserMuted(int userId) {
    return StoreService.to.store?.isUserMuted(userId) ?? false;
  }

  UserStatus getUserStatus(int userId) {
    return StoreService.to.store?.getUserStatus(userId) ?? UserStatus.zero;
  }

  String userDisplayName(int userId, {bool replaceIfMuted = true}) {
    final store = StoreService.to.store;
    return store?.userDisplayName(userId, replaceIfMuted: replaceIfMuted) ??
        'Unknown';
  }

  String senderDisplayName(Message message, {bool replaceIfMuted = true}) {
    final store = StoreService.to.store;
    return store?.senderDisplayName(message, replaceIfMuted: replaceIfMuted) ??
        message.senderFullName;
  }

  List<User> get sortedUsers {
    final users = allUsers.toList();
    users.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return users;
  }

  List<User> get sortedActiveUsers {
    final users = allUsers.where((u) => u.isActive).toList();
    users.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return users;
  }

  User? findByEmail(String email) {
    try {
      return allUsers.firstWhere((u) => u.email == email);
    } catch (_) {
      return null;
    }
  }

  bool isUserActive(int userId) {
    return StoreService.to.store?.getUser(userId)?.isActive ?? false;
  }

  String userName(int userId) {
    return StoreService.to.store?.getUser(userId)?.fullName ?? 'Unknown';
  }

  String? userAvatarUrl(int userId) {
    return StoreService.to.store?.getUser(userId)?.avatarUrl;
  }

  void clear() {
    // No local state to clear - delegating to store
  }
}
