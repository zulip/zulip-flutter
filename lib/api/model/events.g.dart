// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertWordsEvent _$AlertWordsEventFromJson(Map<String, dynamic> json) =>
    AlertWordsEvent(
      id: json['id'] as int,
      alert_words: (json['alert_words'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AlertWordsEventToJson(AlertWordsEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'alert_words': instance.alert_words,
    };
