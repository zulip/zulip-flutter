// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'users.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetOwnUserResult _$GetOwnUserResultFromJson(Map<String, dynamic> json) =>
    GetOwnUserResult(
      userId: (json['user_id'] as num).toInt(),
    );

Map<String, dynamic> _$GetOwnUserResultToJson(GetOwnUserResult instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
    };
