// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'channels.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetStreamTopicsResult _$GetStreamTopicsResultFromJson(
        Map<String, dynamic> json) =>
    GetStreamTopicsResult(
      topics: (json['topics'] as List<dynamic>)
          .map((e) => GetStreamTopicsEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetStreamTopicsResultToJson(
        GetStreamTopicsResult instance) =>
    <String, dynamic>{
      'topics': instance.topics,
    };

GetStreamTopicsEntry _$GetStreamTopicsEntryFromJson(
        Map<String, dynamic> json) =>
    GetStreamTopicsEntry(
      maxId: (json['max_id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$GetStreamTopicsEntryToJson(
        GetStreamTopicsEntry instance) =>
    <String, dynamic>{
      'max_id': instance.maxId,
      'name': instance.name,
    };

SubscribeToChannelsResult _$SubscribeToChannelsResultFromJson(
        Map<String, dynamic> json) =>
    SubscribeToChannelsResult(
      subscribed: (json['subscribed'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
      alreadySubscribed:
          (json['already_subscribed'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
      unauthorized: (json['unauthorized'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SubscribeToChannelsResultToJson(
        SubscribeToChannelsResult instance) =>
    <String, dynamic>{
      'subscribed': instance.subscribed,
      'already_subscribed': instance.alreadySubscribed,
      'unauthorized': instance.unauthorized,
    };
