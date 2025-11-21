// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'channels.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetChannelTopicsResult _$GetChannelTopicsResultFromJson(
  Map<String, dynamic> json,
) => GetChannelTopicsResult(
  topics: (json['topics'] as List<dynamic>)
      .map((e) => GetChannelTopicsEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetChannelTopicsResultToJson(
  GetChannelTopicsResult instance,
) => <String, dynamic>{'topics': instance.topics};

GetChannelTopicsEntry _$GetChannelTopicsEntryFromJson(
  Map<String, dynamic> json,
) => GetChannelTopicsEntry(
  maxId: (json['max_id'] as num).toInt(),
  name: TopicName.fromJson(json['name'] as String),
);

Map<String, dynamic> _$GetChannelTopicsEntryToJson(
  GetChannelTopicsEntry instance,
) => <String, dynamic>{'max_id': instance.maxId, 'name': instance.name};
