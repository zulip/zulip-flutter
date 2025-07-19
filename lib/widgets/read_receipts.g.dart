// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'read_receipts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetReadReceiptsResult _$GetReadReceiptsResultFromJson(
  Map<String, dynamic> json,
) => GetReadReceiptsResult(
  userIds: (json['user_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$GetReadReceiptsResultToJson(
  GetReadReceiptsResult instance,
) => <String, dynamic>{'user_ids': instance.userIds};
