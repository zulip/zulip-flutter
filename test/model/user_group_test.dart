import 'package:checks/checks.dart';
import 'package:test_api/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
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
