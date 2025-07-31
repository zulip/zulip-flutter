// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'messages.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetMessageResult _$GetMessageResultFromJson(Map<String, dynamic> json) =>
    GetMessageResult(
      message: Message.fromJson(json['message'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetMessageResultToJson(GetMessageResult instance) =>
    <String, dynamic>{'message': instance.message};

GetMessagesResult _$GetMessagesResultFromJson(Map<String, dynamic> json) =>
    GetMessagesResult(
      anchor: (json['anchor'] as num).toInt(),
      foundNewest: json['found_newest'] as bool,
      foundOldest: json['found_oldest'] as bool,
      foundAnchor: json['found_anchor'] as bool,
      historyLimited: json['history_limited'] as bool,
      messages: GetMessagesResult._messagesFromJson(json['messages'] as Object),
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
    SendMessageResult(id: (json['id'] as num).toInt());

Map<String, dynamic> _$SendMessageResultToJson(SendMessageResult instance) =>
    <String, dynamic>{'id': instance.id};

UpdateMessageResult _$UpdateMessageResultFromJson(Map<String, dynamic> json) =>
    UpdateMessageResult();

Map<String, dynamic> _$UpdateMessageResultToJson(
  UpdateMessageResult instance,
) => <String, dynamic>{};

UploadFileResult _$UploadFileResultFromJson(Map<String, dynamic> json) =>
    UploadFileResult(url: json['uri'] as String);

Map<String, dynamic> _$UploadFileResultToJson(UploadFileResult instance) =>
    <String, dynamic>{'uri': instance.url};

UpdateMessageFlagsResult _$UpdateMessageFlagsResultFromJson(
  Map<String, dynamic> json,
) => UpdateMessageFlagsResult(
  messages: (json['messages'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$UpdateMessageFlagsResultToJson(
  UpdateMessageFlagsResult instance,
) => <String, dynamic>{'messages': instance.messages};

UpdateMessageFlagsForNarrowResult _$UpdateMessageFlagsForNarrowResultFromJson(
  Map<String, dynamic> json,
) => UpdateMessageFlagsForNarrowResult(
  processedCount: (json['processed_count'] as num).toInt(),
  updatedCount: (json['updated_count'] as num).toInt(),
  firstProcessedId: (json['first_processed_id'] as num?)?.toInt(),
  lastProcessedId: (json['last_processed_id'] as num?)?.toInt(),
  foundOldest: json['found_oldest'] as bool,
  foundNewest: json['found_newest'] as bool,
);

Map<String, dynamic> _$UpdateMessageFlagsForNarrowResultToJson(
  UpdateMessageFlagsForNarrowResult instance,
) => <String, dynamic>{
  'processed_count': instance.processedCount,
  'updated_count': instance.updatedCount,
  'first_processed_id': instance.firstProcessedId,
  'last_processed_id': instance.lastProcessedId,
  'found_oldest': instance.foundOldest,
  'found_newest': instance.foundNewest,
};

const _$AnchorCodeEnumMap = {
  AnchorCode.newest: 'newest',
  AnchorCode.oldest: 'oldest',
  AnchorCode.firstUnread: 'first_unread',
};

const _$UpdateMessageFlagsOpEnumMap = {
  UpdateMessageFlagsOp.add: 'add',
  UpdateMessageFlagsOp.remove: 'remove',
};
