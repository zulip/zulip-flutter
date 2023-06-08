// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast

part of 'messages.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetMessageResult _$GetMessageResultFromJson(Map<String, dynamic> json) =>
    GetMessageResult(
      message: Message.fromJson(json['message'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetMessageResultToJson(GetMessageResult instance) =>
    <String, dynamic>{
      'message': instance.message,
    };

GetMessagesResult _$GetMessagesResultFromJson(Map<String, dynamic> json) =>
    GetMessagesResult(
      anchor: json['anchor'] as int,
      foundNewest: json['found_newest'] as bool,
      foundOldest: json['found_oldest'] as bool,
      foundAnchor: json['found_anchor'] as bool,
      historyLimited: json['history_limited'] as bool,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetMessagesResultToJson(GetMessagesResult instance) =>
    <String, dynamic>{
      'anchor': instance.anchor,
      'found_newest': instance.foundNewest,
      'found_oldest': instance.foundOldest,
      'found_anchor': instance.foundAnchor,
      'history_limited': instance.historyLimited,
      'messages': instance.messages,
    };

SendMessageResult _$SendMessageResultFromJson(Map<String, dynamic> json) =>
    SendMessageResult(
      id: json['id'] as int,
      deliverAt: json['deliver_at'] as String?,
    );

Map<String, dynamic> _$SendMessageResultToJson(SendMessageResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deliver_at': instance.deliverAt,
    };

UploadFileResult _$UploadFileResultFromJson(Map<String, dynamic> json) =>
    UploadFileResult(
      uri: json['uri'] as String,
    );

Map<String, dynamic> _$UploadFileResultToJson(UploadFileResult instance) =>
    <String, dynamic>{
      'uri': instance.uri,
    };
