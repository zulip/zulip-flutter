// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetEventsResult _$GetEventsResultFromJson(Map<String, dynamic> json) =>
    GetEventsResult(
      events: (json['events'] as List<dynamic>)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
      queue_id: json['queue_id'] as String?,
    );

Map<String, dynamic> _$GetEventsResultToJson(GetEventsResult instance) =>
    <String, dynamic>{
      'events': instance.events,
      'queue_id': instance.queue_id,
    };
