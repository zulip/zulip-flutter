// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'streams.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetTopicsResult _$GetTopicsResultFromJson(Map<String, dynamic> json) =>
    GetTopicsResult(
      topics: (json['topics'] as List<dynamic>?)
          ?.map((e) => Topic.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetTopicsResultToJson(GetTopicsResult instance) =>
    <String, dynamic>{
      'topics': instance.topics,
    };

Topic _$TopicFromJson(Map<String, dynamic> json) => Topic(
      maxId: (json['max_id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$TopicToJson(Topic instance) => <String, dynamic>{
      'max_id': instance.maxId,
      'name': instance.name,
    };
