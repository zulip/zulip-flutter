// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetMessagesResult _$GetMessagesResultFromJson(Map<String, dynamic> json) =>
    GetMessagesResult(
      anchor: json['anchor'] as int,
      found_newest: json['found_newest'] as bool,
      found_oldest: json['found_oldest'] as bool,
      found_anchor: json['found_anchor'] as bool,
      history_limited: json['history_limited'] as bool,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetMessagesResultToJson(GetMessagesResult instance) =>
    <String, dynamic>{
      'anchor': instance.anchor,
      'found_newest': instance.found_newest,
      'found_oldest': instance.found_oldest,
      'found_anchor': instance.found_anchor,
      'history_limited': instance.history_limited,
      'messages': instance.messages,
    };

SendMessageResult _$SendMessageResultFromJson(Map<String, dynamic> json) =>
    SendMessageResult(
      id: json['id'] as int,
      deliver_at: json['deliver_at'] as String?,
    );

Map<String, dynamic> _$SendMessageResultToJson(SendMessageResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deliver_at': instance.deliver_at,
    };
