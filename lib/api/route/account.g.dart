// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FetchApiKeyResult _$FetchApiKeyResultFromJson(Map<String, dynamic> json) =>
    FetchApiKeyResult(
      apiKey: json['api_key'] as String,
      email: json['email'] as String,
      userId: json['user_id'] as int?,
    );

Map<String, dynamic> _$FetchApiKeyResultToJson(FetchApiKeyResult instance) =>
    <String, dynamic>{
      'api_key': instance.apiKey,
      'email': instance.email,
      'user_id': instance.userId,
    };
