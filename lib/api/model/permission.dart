import 'package:json_annotation/json_annotation.dart';

part 'permission.g.dart';

/// Metadata about how to interpret the various group-based permission settings.
///
/// This is the type that [InitialSnapshot.serverSupportedPermissionSettings]
/// would have, according to the API as it exists as of 2025-08;
/// but that API is documented as unstable and subject to change.
///
/// For a useful value of this type, see [SupportedPermissionSettings.fixture].
///
/// For docs, search for "d_perm" in: https://zulip.com/api/register-queue
@JsonSerializable(fieldRename: FieldRename.snake)
class SupportedPermissionSettings {
  final Map<String, PermissionSettingsItem> realm;
  final Map<String, PermissionSettingsItem> stream;
  final Map<String, PermissionSettingsItem> group;

  /// Metadata about how to interpret certain group-based permission settings,
  /// including all those that this client uses, based on "current" servers.
  ///
  /// "Current" here means as of when this code was written, or last updated;
  /// details in comments below.  Naturally it'd be better to have an API to
  /// get this information from the actual server.
  ///
  /// Effectively we're counting on it being uncommon for the metadata for a
  /// given permission to ever change from one server version to the next,
  /// so that the values we take from one server version usually remain valid
  /// for all past and future server versions that have the corresponding
  /// permission at all.
  ///
  /// TODO(server): Stabilize [InitialSnapshot.serverSupportedPermissionSettings]
  ///   or a similar API, and switch to using that.  See thread:
  ///     https://chat.zulip.org/#narrow/channel/378-api-design/topic/server_supported_permission_settings/near/2247549
  // TODO: When we get this data from the server, it will sometimes be missing
  //   items that appear here, because they're for newer permissions that the
  //   server doesn't know about. We'll want reasonable fallback behavior for
  //   those missing items, and as a source for that, we can still record
  //   current-server data somewhere in our codebase. Discussion:
  //     https://github.com/zulip/zulip-flutter/pull/1842#discussion_r2331337006
  static SupportedPermissionSettings fixture = SupportedPermissionSettings(
    realm: {
      // From the server's Realm.REALM_PERMISSION_GROUP_SETTINGS,
      // in zerver/models/realms.py.  Current as of 6ab30fcce, 2025-08.
      'create_multiuse_invite_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.administrators,
      ),
      'can_access_all_users_group': PermissionSettingsItem(
          // require_system_group=True,
          // allow_nobody_group=False,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.everyone,
          // # Note that user_can_access_all_other_users in the web
          // # app is relying on members always have access.
          // allowed_system_groups=[SystemGroups.EVERYONE, SystemGroups.MEMBERS],
      ),
      'can_add_subscribers_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.members,
      ),
      'can_add_custom_emoji_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.members,
      ),
      'can_create_bots_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.members,
      ),
      'can_create_groups': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.members,
      ),
      'can_create_public_channel_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.members,
      ),
      'can_create_private_channel_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.members,
      ),
      'can_create_web_public_channel_group': PermissionSettingsItem(
          // require_system_group=True,
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.owners,
          // allowed_system_groups=[
          //     SystemGroups.MODERATORS,
          //     SystemGroups.ADMINISTRATORS,
          //     SystemGroups.OWNERS,
          //     SystemGroups.NOBODY,
          // ],
      ),
      'can_create_write_only_bots_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.members,
      ),
      'can_delete_any_message_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.administrators,
      ),
      'can_delete_own_message_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.everyone,
      ),
      'can_invite_users_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.members,
      ),
      'can_manage_all_groups': PermissionSettingsItem(
          // allow_nobody_group=False,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.owners,
      ),
      'can_manage_billing_group': PermissionSettingsItem(
          // allow_nobody_group=False,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.administrators,
      ),
      'can_mention_many_users_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.administrators,
      ),
      'can_move_messages_between_channels_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.members,
      ),
      'can_move_messages_between_topics_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.everyone,
      ),
      'can_resolve_topics_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.everyone,
      ),
      'can_set_delete_message_policy_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.moderators,
      ),
      'can_set_topics_policy_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.members,
      ),
      'can_summarize_topics_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.everyone,
      ),
      'direct_message_initiator_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.everyone,
      ),
      'direct_message_permission_group': PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.everyone,
      ),
    },
    group: {}, // Please go ahead and fill this in when we come to need it.
    stream: {
      // From the server's Stream.stream_permission_group_settings,
      // in zerver/models/streams.py.  Current as of f9dc13014, 2025-08.
      "can_add_subscribers_group": PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.nobody,
      ),
      "can_administer_channel_group": PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: PseudoSystemGroupName.streamCreatorOrNobody,
      ),
      "can_delete_any_message_group": PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.nobody,
      ),
      "can_delete_own_message_group": PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.nobody,
      ),
      "can_move_messages_out_of_channel_group": PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.nobody,
      ),
      "can_move_messages_within_channel_group": PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.nobody,
      ),
      "can_remove_subscribers_group": PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.administrators,
      ),
      "can_send_message_group": PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.everyone,
      ),
      "can_subscribe_group": PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: false,
          defaultGroupName: SystemGroupName.nobody,
      ),
      "can_resolve_topics_group": PermissionSettingsItem(
          // allow_nobody_group=True,
          allowEveryoneGroup: true,
          defaultGroupName: SystemGroupName.nobody,
      ),
    },
  );

  SupportedPermissionSettings({required this.realm, required this.stream, required this.group});

  factory SupportedPermissionSettings.fromJson(Map<String, dynamic> json) =>
    _$SupportedPermissionSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SupportedPermissionSettingsToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PermissionSettingsItem {
  final bool allowEveryoneGroup;

  final DefaultGroupName defaultGroupName;

  // also other fields not yet used

  PermissionSettingsItem({
    required this.allowEveryoneGroup,
    required this.defaultGroupName,
  });

  factory PermissionSettingsItem.fromJson(Map<String, dynamic> json) =>
    _$PermissionSettingsItemFromJson(json);

  Map<String, dynamic> toJson() => _$PermissionSettingsItemToJson(this);
}

/// A value of [PermissionSettingsItem.defaultGroupName].
///
/// Can be any of these:
/// - a known system group [SystemGroupName]
/// - a known special string [PseudoSystemGroupName]
/// - an unknown system group or special string [DefaultGroupNameUnknown]
sealed class DefaultGroupName {
  DefaultGroupName();

  factory DefaultGroupName.fromJson(String json) {
    final DefaultGroupName? maybeResult = json.startsWith('role:')
      ? SystemGroupName.fromJson(json)
      : PseudoSystemGroupName.fromJson(json);
    return maybeResult ?? DefaultGroupNameUnknown(json);
  }

  String toJson();
}

class DefaultGroupNameUnknown extends DefaultGroupName {
  DefaultGroupNameUnknown(this.apiValue);
  final String apiValue;

  @override
  String toJson() => apiValue;
}

/// A known special string
/// that [PermissionSettingsItem.defaultGroupName] might be.
///
/// See server implementation, e.g.
/// `can_administer_channel_group` in zerver/models/streams.py.
@JsonEnum(valueField: 'apiValue', alwaysCreate: true)
enum PseudoSystemGroupName implements DefaultGroupName {
  // Discussion on this; it looks like it might get renamed:
  //   https://chat.zulip.org/#narrow/channel/378-api-design/topic/stream_creator_or_nobody/near/2258637
  streamCreatorOrNobody(apiValue: 'stream_creator_or_nobody'),
  ;

  const PseudoSystemGroupName({required this.apiValue});

  final String apiValue;

  /// Get a [PseudoSystemGroupName] from an [apiValue],
  /// or null if it's not recognized.
  ///
  /// Example:
  ///   'stream_creator_or_nobody' -> PseudoSystemGroupName.streamCreatorOrNobody
  static PseudoSystemGroupName? fromJson(String json) => _byApiValue[json];

  // _$…EnumMap is thanks to `alwaysCreate: true`
  static final _byApiValue = _$PseudoSystemGroupNameEnumMap
    .map((key, value) => MapEntry(value, key));

  @override
  String toJson() => _$PseudoSystemGroupNameEnumMap[this]!;
}

/// A known canonical name for a system group.
///
/// Doc: https://zulip.com/api/group-setting-values#system-groups
@JsonEnum(valueField: 'apiValue', alwaysCreate: true)
enum SystemGroupName implements DefaultGroupName {
  // TODO(#1096) audit all references when implementing public-access option
  everyoneOnInternet(apiValue: 'role:internet'),

  everyone(apiValue: 'role:everyone'),
  members(apiValue: 'role:members'),
  fullMembers(apiValue: 'role:fullmembers'),
  moderators(apiValue: 'role:moderators'),
  administrators(apiValue: 'role:administrators'),
  owners(apiValue: 'role:owners'),
  nobody(apiValue: 'role:nobody'),
  ;

  const SystemGroupName({required this.apiValue});

  final String apiValue;

  /// Get a [SystemGroupName] from an [apiValue],
  /// or null if it's not recognized.
  ///
  /// Example:
  ///   'role:administrators' -> SystemGroupName.administrators
  static SystemGroupName? fromJson(String json) => _byApiValue[json];

  // _$…EnumMap is thanks to `alwaysCreate: true`
  static final _byApiValue = _$SystemGroupNameEnumMap
    .map((key, value) => MapEntry(value, key));

  @override
  String toJson() => _$SystemGroupNameEnumMap[this]!;
}
