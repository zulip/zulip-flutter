import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/permission.dart';
import 'package:zulip/model/realm.dart';
import 'package:zulip/model/store.dart';

import '../example_data.dart' as eg;

void main() {
  test('processTopicLikeServer', () {
    final emptyTopicDisplayName = eg.defaultRealmEmptyTopicDisplayName;

    TopicName process(TopicName topic, int zulipFeatureLevel) {
      final account = eg.selfAccount.copyWith(zulipFeatureLevel: zulipFeatureLevel);
      final store = eg.store(account: account, initialSnapshot: eg.initialSnapshot(
        zulipFeatureLevel: zulipFeatureLevel,
        realmEmptyTopicDisplayName: emptyTopicDisplayName));
      return store.processTopicLikeServer(topic);
    }

    void doCheck(TopicName topic, TopicName expected, int zulipFeatureLevel) {
      check(process(topic, zulipFeatureLevel)).equals(expected);
    }

    check(() => process(eg.t(''), 333)).throws<void>();
    doCheck(eg.t('(no topic)'),          eg.t('(no topic)'),          333);
    doCheck(eg.t(emptyTopicDisplayName), eg.t(emptyTopicDisplayName), 333);
    doCheck(eg.t('other topic'),         eg.t('other topic'),         333);

    doCheck(eg.t(''),                    eg.t(''),                    334);
    doCheck(eg.t('(no topic)'),          eg.t('(no topic)'),          334);
    doCheck(eg.t(emptyTopicDisplayName), eg.t(''),                    334);
    doCheck(eg.t('other topic'),         eg.t('other topic'),         334);

    doCheck(eg.t('(no topic)'),          eg.t(''),                    370);
  });

  group('selfHasPassedWaitingPeriod', () {
    final testCases = [
      ('2024-11-25T10:00+00:00', DateTime.utc(2024, 11, 25 + 0, 10, 00), false),
      ('2024-11-25T10:00+00:00', DateTime.utc(2024, 11, 25 + 1, 10, 00), false),
      ('2024-11-25T10:00+00:00', DateTime.utc(2024, 11, 25 + 2, 09, 59), false),
      ('2024-11-25T10:00+00:00', DateTime.utc(2024, 11, 25 + 2, 10, 00), true),
      ('2024-11-25T10:00+00:00', DateTime.utc(2024, 11, 25 + 1000, 07, 00), true),
    ];

    for (final (String dateJoined, DateTime currentDate, bool expected) in testCases) {
      test('self-user joined at $dateJoined ${expected ? 'has' : "hasn't"} '
          'passed waiting period by $currentDate', () {
        final selfUser = eg.user(dateJoined: dateJoined);
        final store = eg.store(
          selfUser: selfUser,
          initialSnapshot: eg.initialSnapshot(
            realmWaitingPeriodThreshold: 2,
            realmUsers: [selfUser],
          ),
        );
        check(store.selfHasPassedWaitingPeriod(byDate: currentDate))
          .equals(expected);
      });
    }
  });

  group('selfHasPermissionForGroupSetting', () {
    // Most of the implementation of this is in [UserGroupStore.selfInGroupSetting],
    // and is tested in more detail in user_group_test.dart .

    bool hasPermission(User selfUser, UserGroup group, String permissionName) {
      final store = eg.store(selfUser: selfUser,
        initialSnapshot: eg.initialSnapshot(
          realmUsers: [selfUser], realmUserGroups: [group]));
      return store.selfHasPermissionForGroupSetting(
        GroupSettingValueNamed(group.id),
        GroupSettingType.stream, permissionName);
    }

    test('not in group -> no permission', () {
      final selfUser = eg.user();
      final group = eg.userGroup(members: []);
      check(hasPermission(selfUser, group, 'can_subscribe_group'))
        .isFalse();
    });

    test('in group -> has permission', () {
      final selfUser = eg.user();
      final group = eg.userGroup(members: [selfUser.userId]);
      check(hasPermission(selfUser, group, 'can_subscribe_group'))
        .isTrue();
    });

    test('guest -> no permission, despite group', () {
      final selfUser = eg.user(role: UserRole.guest);
      final group = eg.userGroup(members: [selfUser.userId]);
      check(hasPermission(selfUser, group, 'can_subscribe_group'))
        .isFalse();
    });

    test('guest -> still has permission, if allowEveryoneGroup', () {
      final selfUser = eg.user(role: UserRole.guest);
      final group = eg.userGroup(members: [selfUser.userId]);
      check(hasPermission(selfUser, group, 'can_send_message_group'))
        .isTrue();
    });

    test('guest not in group -> no permission, even if allowEveryoneGroup', () {
      final selfUser = eg.user(role: UserRole.guest);
      final group = eg.userGroup(members: []);
      check(hasPermission(selfUser, group, 'can_send_message_group'))
        .isFalse();
    });

    group('fallbacks for permissions not known to the server', () {
      late PerAccountStore store;

      void prepare({UserRole? selfUserRole}) {
        final selfUser = eg.user(role: selfUserRole);
        store = eg.store(selfUser: selfUser,
          initialSnapshot: eg.initialSnapshot(realmUsers: [selfUser]));
      }

      void doCheck(GroupSettingType type, String name, bool expected) {
        check(store.selfHasPermissionForGroupSetting(null, type, name)).equals(expected);
      }

      for (final pseudoSystemGroupName in PseudoSystemGroupName.values) {
        switch (pseudoSystemGroupName) {
          case PseudoSystemGroupName.streamCreatorOrNobody:
            // TODO implement and test
        }
      }

      for (final systemGroupName in SystemGroupName.values) {
        switch (systemGroupName) {
          case SystemGroupName.everyoneOnInternet:
            // (No permissions where we use this default value; continue.)
            break;
          case SystemGroupName.everyone:
            test('everyone', () {
              prepare(selfUserRole: UserRole.guest);
              doCheck(GroupSettingType.realm, 'can_access_all_users_group', true);
            });
          case SystemGroupName.members:
            test('members, is guest', () {
              prepare(selfUserRole: UserRole.guest);
              doCheck(GroupSettingType.realm, 'can_add_custom_emoji_group', false);
            });
            test('members, is member', () {
              prepare(selfUserRole: UserRole.member);
              doCheck(GroupSettingType.realm, 'can_add_custom_emoji_group', true);
            });
          case SystemGroupName.fullMembers:
            // (No permissions where we use this default value; continue.)
            break;
          case SystemGroupName.moderators:
            test('moderators, is member', () {
              prepare(selfUserRole: UserRole.member);
              doCheck(GroupSettingType.realm, 'can_set_delete_message_policy_group', false);
            });
            test('moderators, is moderator', () {
              prepare(selfUserRole: UserRole.moderator);
              doCheck(GroupSettingType.realm, 'can_set_delete_message_policy_group', true);
            });
          case SystemGroupName.administrators:
            test('administrators, is moderator', () {
              prepare(selfUserRole: UserRole.moderator);
              doCheck(GroupSettingType.stream, 'can_remove_subscribers_group', false);
            });
            test('administrators, is administrator', () {
              prepare(selfUserRole: UserRole.administrator);
              doCheck(GroupSettingType.stream, 'can_remove_subscribers_group', true);
            });
          case SystemGroupName.owners:
            test('owners, is administrator', () {
              prepare(selfUserRole: UserRole.administrator);
              doCheck(GroupSettingType.realm, 'can_create_web_public_channel_group', false);
            });
            test('owners, is owner', () {
              prepare(selfUserRole: UserRole.owner);
              doCheck(GroupSettingType.realm, 'can_create_web_public_channel_group', true);
            });
          case SystemGroupName.nobody:
            test('nobody', () {
              prepare(selfUserRole: UserRole.owner);
              doCheck(GroupSettingType.stream, 'can_delete_own_message_group', false);
            });
        }
      }

      test('throw on unknown name', () {
        // We should know about all the permissions we're trying to implement,
        // even the ones old servers don't know about.
        prepare(selfUserRole: UserRole.member);
        check(() => store.selfHasPermissionForGroupSetting(null,
          GroupSettingType.realm, 'example_future_permission_name'),
        ).throws<Error>();
      });
    });
  });

  group('customProfileFields', () {
    test('update clobbers old list', () async {
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        customProfileFields: [
          eg.customProfileField(0, CustomProfileFieldType.shortText),
          eg.customProfileField(1, CustomProfileFieldType.shortText),
        ]));
      check(store.customProfileFields.map((f) => f.id)).deepEquals([0, 1]);

      await store.handleEvent(CustomProfileFieldsEvent(id: 0, fields: [
        eg.customProfileField(0, CustomProfileFieldType.shortText),
        eg.customProfileField(2, CustomProfileFieldType.shortText),
      ]));
      check(store.customProfileFields.map((f) => f.id)).deepEquals([0, 2]);
    });

    test('sorts by displayInProfile', () async {
      // Sorts both the data from the initial snapshot…
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        customProfileFields: [
          eg.customProfileField(0, CustomProfileFieldType.shortText,
            displayInProfileSummary: false),
          eg.customProfileField(1, CustomProfileFieldType.shortText,
            displayInProfileSummary: true),
          eg.customProfileField(2, CustomProfileFieldType.shortText,
            displayInProfileSummary: false),
        ]));
      check(store.customProfileFields.map((f) => f.id)).deepEquals([1, 0, 2]);

      // … and from an event.
      await store.handleEvent(CustomProfileFieldsEvent(id: 0, fields: [
        eg.customProfileField(0, CustomProfileFieldType.shortText,
          displayInProfileSummary: false),
        eg.customProfileField(1, CustomProfileFieldType.shortText,
          displayInProfileSummary: false),
        eg.customProfileField(2, CustomProfileFieldType.shortText,
          displayInProfileSummary: true),
      ]));
      check(store.customProfileFields.map((f) => f.id)).deepEquals([2, 0, 1]);
    });
  });
}
