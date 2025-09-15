// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'permission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportedPermissionSettings _$SupportedPermissionSettingsFromJson(
  Map<String, dynamic> json,
) => SupportedPermissionSettings(
  realm: (json['realm'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry(k, PermissionSettingsItem.fromJson(e as Map<String, dynamic>)),
  ),
  stream: (json['stream'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry(k, PermissionSettingsItem.fromJson(e as Map<String, dynamic>)),
  ),
  group: (json['group'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry(k, PermissionSettingsItem.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$SupportedPermissionSettingsToJson(
  SupportedPermissionSettings instance,
) => <String, dynamic>{
  'realm': instance.realm,
  'stream': instance.stream,
  'group': instance.group,
};

PermissionSettingsItem _$PermissionSettingsItemFromJson(
  Map<String, dynamic> json,
) => PermissionSettingsItem(
  allowEveryoneGroup: json['allow_everyone_group'] as bool,
  defaultGroupName: DefaultGroupName.fromJson(
    json['default_group_name'] as String,
  ),
);

Map<String, dynamic> _$PermissionSettingsItemToJson(
  PermissionSettingsItem instance,
) => <String, dynamic>{
  'allow_everyone_group': instance.allowEveryoneGroup,
  'default_group_name': instance.defaultGroupName,
};

const _$PseudoSystemGroupNameEnumMap = {
  PseudoSystemGroupName.streamCreatorOrNobody: 'stream_creator_or_nobody',
};

const _$SystemGroupNameEnumMap = {
  SystemGroupName.everyoneOnInternet: 'role:internet',
  SystemGroupName.everyone: 'role:everyone',
  SystemGroupName.members: 'role:members',
  SystemGroupName.fullMembers: 'role:fullmembers',
  SystemGroupName.moderators: 'role:moderators',
  SystemGroupName.administrators: 'role:administrators',
  SystemGroupName.owners: 'role:owners',
  SystemGroupName.nobody: 'role:nobody',
};
