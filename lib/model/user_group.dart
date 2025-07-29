import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import 'store.dart';

/// The portion of [PerAccountStore] describing user groups.
mixin UserGroupStore on PerAccountStoreBase {
  /// The user group with the given ID, if any.
  UserGroup? getGroup(int userGroupId);

  /// All non-deactivated user groups in the realm.
  ///
  /// For when deactivated groups are desired too, see [allGroups].
  Iterable<UserGroup> get activeGroups;

  /// All user groups in the realm, even those deactivated.
  ///
  /// Consider using [activeGroups] instead.
  Iterable<UserGroup> get allGroups;
}

mixin ProxyUserGroupStore on UserGroupStore {
  @protected
  UserGroupStore get userGroupStore;

  @override
  UserGroup? getGroup(int userGroupId) => userGroupStore.getGroup(userGroupId);
  @override
  Iterable<UserGroup> get activeGroups => userGroupStore.activeGroups;
  @override
  Iterable<UserGroup> get allGroups => userGroupStore.allGroups;
}

/// The implementation of [UserGroupStore] that does the work.
class UserGroupStoreImpl extends PerAccountStoreBase with UserGroupStore {
  UserGroupStoreImpl({required super.core, required List<UserGroup> groups})
    : _groups = {
        for (final group in groups)
          group.id: group,
      };

  @override
  UserGroup? getGroup(int userGroupId) {
    return _groups[userGroupId];
  }

  @override
  Iterable<UserGroup> get activeGroups {
    return _groups.values.where((group) => !group.deactivated);
  }

  @override
  Iterable<UserGroup> get allGroups {
    return _groups.values;
  }

  final Map<int, UserGroup> _groups;

  void handleUserGroupEvent(UserGroupEvent event) {
    switch (event) {
      case UserGroupAddEvent():
        _groups[event.group.id] = event.group;

      case UserGroupRemoveEvent():
        _groups.remove(event.groupId);

      case UserGroupUpdateEvent():
        final group = _groups[event.groupId];
        if (group == null) {
          return; // TODO log
        }
        final data = event.data;
        if (data.name != null)        group.name        = data.name!;
        if (data.description != null) group.description = data.description!;
        if (data.deactivated != null) group.deactivated = data.deactivated!;

      case UserGroupAddMembersEvent():
      case UserGroupRemoveMembersEvent():
      case UserGroupAddSubgroupsEvent():
      case UserGroupRemoveSubgroupsEvent():
        break; // TODO(#1687): update group memberships on event
    }
  }
}
