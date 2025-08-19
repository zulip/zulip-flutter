import 'package:checks/checks.dart';
import 'package:test_api/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/user_group.dart';

import '../api/model/model_checks.dart';
import '../example_data.dart' as eg;
import '../stdlib_checks.dart';

void main() {
  List<UserGroup> sorted(Iterable<UserGroup> groups) {
    return groups.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  void checkGroupsEqual(UserGroupStore store, Iterable<Object?> expected) {
    check(sorted(store.allGroups)).jsonEquals(expected);
  }

  test('initialize', () {
    final groups = [eg.userGroup(), eg.userGroup()];
    final store = eg.store(initialSnapshot: eg.initialSnapshot(
      realmUserGroups: groups));
    checkGroupsEqual(store, groups);
  });

  test('getGroup', () {
    final group1 = eg.userGroup();
    final group2 = eg.userGroup();
    final store = eg.store(initialSnapshot: eg.initialSnapshot(
      realmUserGroups: [group1, group2]));
    check(store.getGroup(group1.id)).jsonEquals(group1);
    check(store.getGroup(group2.id)).jsonEquals(group2);
    check(store.getGroup(eg.userGroup().id)).isNull();
  });

  test('activeGroups, allGroups', () async {
    final group1 = eg.userGroup(deactivated: false);
    final group2 = eg.userGroup(deactivated: true);
    final group3 = eg.userGroup(deactivated: false);
    final store = eg.store(initialSnapshot: eg.initialSnapshot(
      realmUserGroups: [group1, group2, group3]));
    check(sorted(store.allGroups)).jsonEquals([group1, group2, group3]);
    check(sorted(store.activeGroups)).jsonEquals([group1, group3]);

    await store.handleEvent(UserGroupUpdateEvent(id: 1, groupId: group1.id,
      data: UserGroupUpdateData(name: null, description: null, deactivated: true)));
    check(sorted(store.activeGroups)).jsonEquals([group3]);
  });

  test('UserGroupAddEvent, UserGroupRemoveEvent', () async {
    final group1 = eg.userGroup();
    final store = eg.store(initialSnapshot: eg.initialSnapshot(
      realmUserGroups: [group1]));
    checkGroupsEqual(store, [group1]);

    final group2 = eg.userGroup();
    await store.handleEvent(UserGroupAddEvent(id: 1, group: group2));
    checkGroupsEqual(store, [group1, group2]);

    await store.handleEvent(UserGroupRemoveEvent(id: 2, groupId: group1.id));
    checkGroupsEqual(store, [group2]);
  });

  test('UserGroupUpdateEvent', () async {
    final store = eg.store();
    final group = eg.userGroup(
      name: 'a group', description: 'is a group', deactivated: false);
    await store.handleEvent(UserGroupAddEvent(id: 1, group: group));
    checkGroupsEqual(store, [group]);

    // Handles all the properties being updated at once.
    await store.handleEvent(UserGroupUpdateEvent(id: 2, groupId: group.id,
      data: UserGroupUpdateData(name: 'revised group',
        description: 'different description', deactivated: true)));
    checkGroupsEqual(store, [{
      ...group.toJson(),
      'name': 'revised group',
      'description': 'different description',
      'deactivated': true,
    }]);

    // Handles some properties being null, still updating the one that's present.
    await store.handleEvent(UserGroupUpdateEvent(id: 2, groupId: group.id,
      data: UserGroupUpdateData(name: null,
        description: null, deactivated: false)));
    checkGroupsEqual(store, [{
      ...group.toJson(),
      'name': 'revised group',
      'description': 'different description',
      'deactivated': false,
    }]);
  });

  group('membership', () {
    // These tests exercise membership via selfInGroupSetting, because that's
    // the main interface the app uses to consume group membership.

    late PerAccountStore store;

    void prepare(List<UserGroup> groups, {List<User>? users}) {
      store = eg.store(initialSnapshot: eg.initialSnapshot(
        realmUsers: users, realmUserGroups: groups));
    }

    bool isMember(UserGroup group) {
      return store.selfInGroupSetting(GroupSettingValueNamed(group.id));
    }

    test('initial', () {
      final groups = <UserGroup>[];
      groups.add(eg.userGroup(members: [eg.selfUser.userId]));
      groups.add(eg.userGroup(members: [eg.user().userId]));
      groups.add(eg.userGroup(directSubgroupIds: [groups[0].id]));
      groups.add(eg.userGroup(directSubgroupIds: [groups[2].id]));
      groups.add(eg.userGroup(directSubgroupIds: [groups[1].id]));

      prepare(groups);
      check(groups.map(isMember)).deepEquals([
        true,
        false,
        true,
        true,
        false,
      ]);
    });

    test('UserGroupEvent', () async {
      final groups = List.generate(4, (_) => eg.userGroup());
      prepare(groups);
      check(groups.map(isMember)).deepEquals([false, false, false, false]);

      // Add a membership.
      await store.handleEvent(UserGroupAddMembersEvent(id: 0,
        groupId: groups[0].id, userIds: [eg.selfUser.userId]));
      check(groups.map(isMember)).deepEquals([true, false, false, false]);

      // Add a chain of transitive memberships.
      await store.handleEvent(UserGroupAddSubgroupsEvent(id: 0,
        groupId: groups[1].id, directSubgroupIds: [groups[0].id]));
      check(groups.map(isMember)).deepEquals([true, true, false, false]);
      await store.handleEvent(UserGroupAddSubgroupsEvent(id: 0,
        groupId: groups[2].id, directSubgroupIds: [groups[1].id]));
      check(groups.map(isMember)).deepEquals([true, true, true, false]);

      // Cut the middle link of the chain.
      await store.handleEvent(UserGroupRemoveSubgroupsEvent(id: 0,
        groupId: groups[1].id, directSubgroupIds: [groups[0].id]));
      check(groups.map(isMember)).deepEquals([true, false, false, false]);

      // Restore the middle link; cut the bottom link.
      await store.handleEvent(UserGroupAddSubgroupsEvent(id: 0,
        groupId: groups[1].id, directSubgroupIds: [groups[0].id]));
      check(groups.map(isMember)).deepEquals([true, true, true, false]);
      await store.handleEvent(UserGroupRemoveMembersEvent(id: 0,
        groupId: groups[0].id, userIds: [eg.selfUser.userId]));
      check(groups.map(isMember)).deepEquals([false, false, false, false]);
    });

    test('RealmUserUpdateEvent', () async {
      // This test uses the membership data structure directly, because
      // selfInGroupSetting would only be affected if the self-user were
      // deactivated, and in that case we wouldn't be getting an event.

      final user = eg.user();
      final group = eg.userGroup(members: [user.userId]);
      prepare(users: [eg.selfUser, user], [group]);
      check(store.getGroup(group.id)!.members).deepEquals([user.userId]);

      // An update to a random irrelevant field has no effect.
      await store.handleEvent(RealmUserUpdateEvent(id: 0,
        userId: user.userId, fullName: 'New Name'));
      check(store.getGroup(group.id)!.members).deepEquals([user.userId]);

      // But deactivating the user removes them from groups.
      await store.handleEvent(RealmUserUpdateEvent(id: 0,
        userId: user.userId, isActive: false));
      check(store.getGroup(group.id)!.members).isEmpty();
    });
  });

  test('various fields make it through', () async {
    final store = eg.store(initialSnapshot: eg.initialSnapshot(
      realmUserGroups: [
        eg.userGroup(id: 3, name: 'some group', description: 'this is a group',
          isSystemGroup: true, deactivated: false),
      ]));
    await store.handleEvent(UserGroupAddEvent(id: 1, group: eg.userGroup(
      id: 5, name: 'a different group', description: 'also a group',
      isSystemGroup: false, deactivated: true)));
    check(sorted(store.allGroups)).deepEquals(<Condition<Object?>>[
      (it) => it.isA<UserGroup>()
        ..id.equals(3)
        ..name.equals('some group')
        ..description.equals('this is a group')
        ..isSystemGroup.isTrue()
        ..deactivated.isFalse(),
      (it) => it.isA<UserGroup>()
        ..id.equals(5)
        ..name.equals('a different group')
        ..description.equals('also a group')
        ..isSystemGroup.isFalse()
        ..deactivated.isTrue(),
    ]);
  });
}
