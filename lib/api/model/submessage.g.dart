// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'submessage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Submessage _$SubmessageFromJson(Map<String, dynamic> json) => Submessage(
      msgType: $enumDecode(_$SubmessageTypeEnumMap, json['msg_type'],
          unknownValue: SubmessageType.unknown),
      content: Submessage.readContent(json, 'content'),
      messageId: (json['message_id'] as num).toInt(),
      senderId: (json['sender_id'] as num).toInt(),
      id: (json['id'] as num).toInt(),
    );

Map<String, dynamic> _$SubmessageToJson(Submessage instance) =>
    <String, dynamic>{
      'msg_type': _$SubmessageTypeEnumMap[instance.msgType]!,
      'content': Submessage.contentToJson(instance.content),
      'message_id': instance.messageId,
      'sender_id': instance.senderId,
      'id': instance.id,
    };

const _$SubmessageTypeEnumMap = {
  SubmessageType.widget: 'widget',
  SubmessageType.unknown: 'unknown',
};
