// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FetchApiKeyResult _$FetchApiKeyResultFromJson(Map<String, dynamic> json) =>
    FetchApiKeyResult(
      apiKey: json['api_key'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$FetchApiKeyResultToJson(FetchApiKeyResult instance) =>
    <String, dynamic>{
      'api_key': instance.apiKey,
      'email': instance.email,
    };
