// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'legacy_app_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegacyAppData _$LegacyAppDataFromJson(Map<String, dynamic> json) =>
    LegacyAppData(
      settings: json['settings'] == null
          ? null
          : LegacyAppGlobalSettingsState.fromJson(
              json['settings'] as Map<String, dynamic>,
            ),
      accounts: (json['accounts'] as List<dynamic>?)
          ?.map((e) => LegacyAppAccount.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LegacyAppDataToJson(LegacyAppData instance) =>
    <String, dynamic>{
      'settings': instance.settings,
      'accounts': instance.accounts,
    };

LegacyAppMigrationsState _$LegacyAppMigrationsStateFromJson(
  Map<String, dynamic> json,
) => LegacyAppMigrationsState(version: (json['version'] as num?)?.toInt());

Map<String, dynamic> _$LegacyAppMigrationsStateToJson(
  LegacyAppMigrationsState instance,
) => <String, dynamic>{'version': instance.version};

LegacyAppGlobalSettingsState _$LegacyAppGlobalSettingsStateFromJson(
  Map<String, dynamic> json,
) => LegacyAppGlobalSettingsState(
  language: json['language'] as String,
  theme: $enumDecode(_$LegacyAppThemeSettingEnumMap, json['theme']),
  browser: $enumDecode(_$LegacyAppBrowserPreferenceEnumMap, json['browser']),
  markMessagesReadOnScroll: $enumDecode(
    _$LegacyAppMarkMessagesReadOnScrollEnumMap,
    json['markMessagesReadOnScroll'],
  ),
);

Map<String, dynamic> _$LegacyAppGlobalSettingsStateToJson(
  LegacyAppGlobalSettingsState instance,
) => <String, dynamic>{
  'language': instance.language,
  'theme': _$LegacyAppThemeSettingEnumMap[instance.theme]!,
  'browser': _$LegacyAppBrowserPreferenceEnumMap[instance.browser]!,
  'markMessagesReadOnScroll':
      _$LegacyAppMarkMessagesReadOnScrollEnumMap[instance
          .markMessagesReadOnScroll]!,
};

const _$LegacyAppThemeSettingEnumMap = {
  LegacyAppThemeSetting.default_: 'default',
  LegacyAppThemeSetting.night: 'night',
};

const _$LegacyAppBrowserPreferenceEnumMap = {
  LegacyAppBrowserPreference.embedded: 'embedded',
  LegacyAppBrowserPreference.external: 'external',
  LegacyAppBrowserPreference.default_: 'default',
};

const _$LegacyAppMarkMessagesReadOnScrollEnumMap = {
  LegacyAppMarkMessagesReadOnScroll.always: 'always',
  LegacyAppMarkMessagesReadOnScroll.never: 'never',
  LegacyAppMarkMessagesReadOnScroll.conversationViewsOnly:
      'conversation-views-only',
};

LegacyAppAccount _$LegacyAppAccountFromJson(Map<String, dynamic> json) =>
    LegacyAppAccount(
      realm: const _LegacyAppUrlJsonConverter().fromJson(
        json['realm'] as Map<String, dynamic>,
      ),
      apiKey: json['apiKey'] as String,
      email: json['email'] as String,
      userId: (json['userId'] as num?)?.toInt(),
      zulipVersion: _$JsonConverterFromJson<Map<String, dynamic>, String>(
        json['zulipVersion'],
        const _LegacyAppZulipVersionJsonConverter().fromJson,
      ),
      zulipFeatureLevel: (json['zulipFeatureLevel'] as num?)?.toInt(),
      ackedPushToken: json['ackedPushToken'] as String?,
    );

Map<String, dynamic> _$LegacyAppAccountToJson(LegacyAppAccount instance) =>
    <String, dynamic>{
      'realm': const _LegacyAppUrlJsonConverter().toJson(instance.realm),
      'apiKey': instance.apiKey,
      'email': instance.email,
      'userId': instance.userId,
      'zulipVersion': _$JsonConverterToJson<Map<String, dynamic>, String>(
        instance.zulipVersion,
        const _LegacyAppZulipVersionJsonConverter().toJson,
      ),
      'zulipFeatureLevel': instance.zulipFeatureLevel,
      'ackedPushToken': instance.ackedPushToken,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
