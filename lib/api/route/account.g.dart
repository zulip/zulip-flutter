// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FetchApiKeyResult _$FetchApiKeyResultFromJson(Map<String, dynamic> json) =>
    FetchApiKeyResult(
      apiKey: json['api_key'] as String,
      email: json['email'] as String,
      userId: (json['user_id'] as num).toInt(),
    );

Map<String, dynamic> _$FetchApiKeyResultToJson(FetchApiKeyResult instance) =>
    <String, dynamic>{
      'api_key': instance.apiKey,
      'email': instance.email,
      'user_id': instance.userId,
    };

DevListUsersResult _$DevListUsersResultFromJson(Map<String, dynamic> json) =>
    DevListUsersResult(
      directAdmins: (json['direct_admins'] as List<dynamic>)
          .map((e) => DevListUsersEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      directUsers: (json['direct_users'] as List<dynamic>)
          .map((e) => DevListUsersEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DevListUsersResultToJson(DevListUsersResult instance) =>
    <String, dynamic>{
      'direct_admins': instance.directAdmins,
      'direct_users': instance.directUsers,
    };

DevListUsersEntry _$DevListUsersEntryFromJson(Map<String, dynamic> json) =>
    DevListUsersEntry(
      email: json['email'] as String,
      realmUrl: Uri.parse(json['realm_url'] as String),
    );

Map<String, dynamic> _$DevListUsersEntryToJson(DevListUsersEntry instance) =>
    <String, dynamic>{
      'email': instance.email,
      'realm_url': instance.realmUrl.toString(),
    };

RegisterClientDeviceResult _$RegisterClientDeviceResultFromJson(
  Map<String, dynamic> json,
) => RegisterClientDeviceResult(deviceId: (json['device_id'] as num).toInt());

Map<String, dynamic> _$RegisterClientDeviceResultToJson(
  RegisterClientDeviceResult instance,
) => <String, dynamic>{'device_id': instance.deviceId};
