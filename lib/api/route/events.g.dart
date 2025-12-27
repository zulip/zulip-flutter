// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetEventsResult _$GetEventsResultFromJson(Map<String, dynamic> json) =>
    GetEventsResult(
      events: (json['events'] as List<dynamic>)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
      queueId: json['queue_id'] as String?,
    );

Map<String, dynamic> _$GetEventsResultToJson(GetEventsResult instance) =>
    <String, dynamic>{'events': instance.events, 'queue_id': instance.queueId};
