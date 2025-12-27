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

  /// Whether the self-user is a (transitive) member of the given group,
  /// a group-setting value.
  bool selfInGroupSetting(GroupSettingValue value);
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
  @override
  bool selfInGroupSetting(GroupSettingValue value)
    => userGroupStore.selfInGroupSetting(value);
}

abstract class HasUserGroupStore extends PerAccountStoreBase with UserGroupStore, ProxyUserGroupStore {
  HasUserGroupStore({required UserGroupStore groups})
    : userGroupStore = groups, super(core: groups.core);

  @protected
  @override
  final UserGroupStore userGroupStore;
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

  @override
  bool selfInGroupSetting(GroupSettingValue value) {
    return switch (value) {
      GroupSettingValueNamed() =>
        _selfInGroup(value.groupId),
      GroupSettingValueNameless() =>
        value.directMembers.contains(selfUserId)
          || value.directSubgroups.any(_selfInGroup),
    };
  }

  bool _selfInGroup(int groupId) {
    final group = _groups[groupId];
    if (group == null) return false; // TODO(log); should know all groups
    // TODO(perf), TODO(#814): memoize which groups the self-user is in,
    //   to save doing this depth-first search on each permission check
    return group.members.contains(selfUserId)
      || group.directSubgroupIds.any(_selfInGroup);
  }

  final Map<int, UserGroup> _groups;

  UserGroup? _expectGroup(int groupId) {
    final group = _groups[groupId];
    // TODO(log) if group not found
    return group;
  }

  void handleUserGroupEvent(UserGroupEvent event) {
    switch (event) {
      case UserGroupAddEvent():
        _groups[event.group.id] = event.group;

      case UserGroupRemoveEvent():
        _groups.remove(event.groupId);

      case UserGroupUpdateEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        final data = event.data;
        if (data.name != null)        group.name        = data.name!;
        if (data.description != null) group.description = data.description!;
        if (data.deactivated != null) group.deactivated = data.deactivated!;

      case UserGroupAddMembersEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        group.members.addAll(event.userIds);

      case UserGroupRemoveMembersEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        group.members.removeAll(event.userIds);

      case UserGroupAddSubgroupsEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        group.directSubgroupIds.addAll(event.directSubgroupIds);

      case UserGroupRemoveSubgroupsEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        group.directSubgroupIds.removeAll(event.directSubgroupIds);
    }
  }

  void handleRealmUserUpdateEvent(RealmUserUpdateEvent event) {
    if (event.isActive == false) {
      for (final group in _groups.values) {
        group.members.remove(event.userId);
      }
    }
  }
}
