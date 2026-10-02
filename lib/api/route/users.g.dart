// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'users.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePresenceResult _$UpdatePresenceResultFromJson(
  Map<String, dynamic> json,
) => UpdatePresenceResult(
  presenceLastUpdateId: (json['presence_last_update_id'] as num?)?.toInt(),
  serverTimestamp: (json['server_timestamp'] as num?)?.toDouble(),
  presences: (json['presences'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(
      int.parse(k),
      PerUserPresence.fromJson(e as Map<String, dynamic>),
    ),
  ),
);

Map<String, dynamic> _$UpdatePresenceResultToJson(
  UpdatePresenceResult instance,
) => <String, dynamic>{
  'presence_last_update_id': instance.presenceLastUpdateId,
  'server_timestamp': instance.serverTimestamp,
  'presences': instance.presences?.map((k, e) => MapEntry(k.toString(), e)),
};
