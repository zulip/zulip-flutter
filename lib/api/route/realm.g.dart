// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetServerSettingsResult _$GetServerSettingsResultFromJson(
        Map<String, dynamic> json) =>
    GetServerSettingsResult(
      authenticationMethods:
          Map<String, bool>.from(json['authentication_methods'] as Map),
      zulipFeatureLevel: json['zulip_feature_level'] as int,
      zulipVersion: json['zulip_version'] as String,
      zulipMergeBase: json['zulip_merge_base'] as String?,
      pushNotificationsEnabled: json['push_notifications_enabled'] as bool,
      isIncompatible: json['is_incompatible'] as bool,
      emailAuthEnabled: json['email_auth_enabled'] as bool,
      requireEmailFormatUsernames:
          json['require_email_format_usernames'] as bool,
      realmUri: Uri.parse(json['realm_uri'] as String),
      realmName: json['realm_name'] as String,
      realmIcon: json['realm_icon'] as String,
      realmDescription: json['realm_description'] as String,
      realmWebPublicAccessEnabled:
          json['realm_web_public_access_enabled'] as bool?,
    );

Map<String, dynamic> _$GetServerSettingsResultToJson(
        GetServerSettingsResult instance) =>
    <String, dynamic>{
      'authentication_methods': instance.authenticationMethods,
      'zulip_feature_level': instance.zulipFeatureLevel,
      'zulip_version': instance.zulipVersion,
      'zulip_merge_base': instance.zulipMergeBase,
      'push_notifications_enabled': instance.pushNotificationsEnabled,
      'is_incompatible': instance.isIncompatible,
      'email_auth_enabled': instance.emailAuthEnabled,
      'require_email_format_usernames': instance.requireEmailFormatUsernames,
      'realm_uri': instance.realmUri.toString(),
      'realm_name': instance.realmName,
      'realm_icon': instance.realmIcon,
      'realm_description': instance.realmDescription,
      'realm_web_public_access_enabled': instance.realmWebPublicAccessEnabled,
    };
