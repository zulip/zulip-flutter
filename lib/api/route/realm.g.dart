// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'realm.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetServerSettingsResult _$GetServerSettingsResultFromJson(
  Map<String, dynamic> json,
) => GetServerSettingsResult(
  authenticationMethods: Map<String, bool>.from(
    json['authentication_methods'] as Map,
  ),
  externalAuthenticationMethods:
      (json['external_authentication_methods'] as List<dynamic>)
          .map(
            (e) => ExternalAuthenticationMethod.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
  zulipFeatureLevel: (json['zulip_feature_level'] as num).toInt(),
  zulipVersion: json['zulip_version'] as String,
  zulipMergeBase: json['zulip_merge_base'] as String,
  pushNotificationsEnabled: json['push_notifications_enabled'] as bool,
  isIncompatible: json['is_incompatible'] as bool,
  emailAuthEnabled: json['email_auth_enabled'] as bool,
  requireEmailFormatUsernames: json['require_email_format_usernames'] as bool,
  realmUrl: Uri.parse(json['realm_uri'] as String),
  realmName: json['realm_name'] as String,
  realmIcon: Uri.parse(json['realm_icon'] as String),
  realmDescription: json['realm_description'] as String,
  realmWebPublicAccessEnabled: json['realm_web_public_access_enabled'] as bool,
);

Map<String, dynamic> _$GetServerSettingsResultToJson(
  GetServerSettingsResult instance,
) => <String, dynamic>{
  'authentication_methods': instance.authenticationMethods,
  'external_authentication_methods': instance.externalAuthenticationMethods,
  'zulip_feature_level': instance.zulipFeatureLevel,
  'zulip_version': instance.zulipVersion,
  'zulip_merge_base': instance.zulipMergeBase,
  'push_notifications_enabled': instance.pushNotificationsEnabled,
  'is_incompatible': instance.isIncompatible,
  'email_auth_enabled': instance.emailAuthEnabled,
  'require_email_format_usernames': instance.requireEmailFormatUsernames,
  'realm_uri': instance.realmUrl.toString(),
  'realm_name': instance.realmName,
  'realm_icon': instance.realmIcon.toString(),
  'realm_description': instance.realmDescription,
  'realm_web_public_access_enabled': instance.realmWebPublicAccessEnabled,
};

ExternalAuthenticationMethod _$ExternalAuthenticationMethodFromJson(
  Map<String, dynamic> json,
) => ExternalAuthenticationMethod(
  name: json['name'] as String,
  displayName: json['display_name'] as String,
  displayIcon: json['display_icon'] as String?,
  loginUrl: json['login_url'] as String,
  signupUrl: json['signup_url'] as String,
);

Map<String, dynamic> _$ExternalAuthenticationMethodToJson(
  ExternalAuthenticationMethod instance,
) => <String, dynamic>{
  'name': instance.name,
  'display_name': instance.displayName,
  'display_icon': instance.displayIcon,
  'login_url': instance.loginUrl,
  'signup_url': instance.signupUrl,
};

ServerEmojiData _$ServerEmojiDataFromJson(Map<String, dynamic> json) =>
    ServerEmojiData(
      codeToNames: (json['code_to_names'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    );

Map<String, dynamic> _$ServerEmojiDataToJson(ServerEmojiData instance) =>
    <String, dynamic>{'code_to_names': instance.codeToNames};
