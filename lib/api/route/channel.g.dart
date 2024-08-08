// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
