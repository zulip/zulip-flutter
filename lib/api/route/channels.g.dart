// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'channels.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetStreamTopicsResult _$GetStreamTopicsResultFromJson(
  Map<String, dynamic> json,
) => GetStreamTopicsResult(
  topics: (json['topics'] as List<dynamic>)
      .map((e) => GetStreamTopicsEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetStreamTopicsResultToJson(
  GetStreamTopicsResult instance,
) => <String, dynamic>{'topics': instance.topics};

GetStreamTopicsEntry _$GetStreamTopicsEntryFromJson(
  Map<String, dynamic> json,
) => GetStreamTopicsEntry(
  maxId: (json['max_id'] as num).toInt(),
  name: TopicName.fromJson(json['name'] as String),
);

Map<String, dynamic> _$GetStreamTopicsEntryToJson(
  GetStreamTopicsEntry instance,
) => <String, dynamic>{'max_id': instance.maxId, 'name': instance.name};

GetSubscribersResult _$GetSubscribersResultFromJson(
  Map<String, dynamic> json,
) => GetSubscribersResult(
  subscribers: (json['subscribers'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$GetSubscribersResultToJson(
  GetSubscribersResult instance,
) => <String, dynamic>{'subscribers': instance.subscribers};
