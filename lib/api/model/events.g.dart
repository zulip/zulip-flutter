// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast

part of 'events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertWordsEvent _$AlertWordsEventFromJson(Map<String, dynamic> json) =>
    AlertWordsEvent(
      id: json['id'] as int,
      alertWords: (json['alert_words'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AlertWordsEventToJson(AlertWordsEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'alert_words': instance.alertWords,
    };

HeartbeatEvent _$HeartbeatEventFromJson(Map<String, dynamic> json) =>
    HeartbeatEvent(
      id: json['id'] as int,
    );

Map<String, dynamic> _$HeartbeatEventToJson(HeartbeatEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
    };
