import 'package:get/get.dart';

import '../../../../api/model/model.dart';

class GroupsService extends GetxService {
  static GroupsService get to => Get.find<GroupsService>();

  final RxMap<int, UserGroup> groups = RxMap<int, UserGroup>();

  void syncFromStore() {
    // Will be implemented when full integration is done
  }

  void updateGroups(List<UserGroup> newGroups) {
    for (final group in newGroups) {
      groups[group.id] = group;
    }
  }

  void updateGroup(UserGroup group) {
    groups[group.id] = group;
  }

  void removeGroup(int groupId) {
    groups.remove(groupId);
  }

  void clear() {
    groups.clear();
  }

  UserGroup? getGroup(int groupId) {
    return groups[groupId];
  }

  List<UserGroup> get sortedGroups =>
      groups.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}
