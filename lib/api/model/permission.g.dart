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
);

Map<String, dynamic> _$PermissionSettingsItemToJson(
  PermissionSettingsItem instance,
) => <String, dynamic>{'allow_everyone_group': instance.allowEveryoneGroup};
