// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'submessage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Submessage _$SubmessageFromJson(Map<String, dynamic> json) => Submessage(
      msgType: $enumDecode(_$SubmessageTypeEnumMap, json['msg_type'],
          unknownValue: SubmessageType.unknown),
      content: json['content'] as String,
      senderId: (json['sender_id'] as num).toInt(),
    );

Map<String, dynamic> _$SubmessageToJson(Submessage instance) =>
    <String, dynamic>{
      'msg_type': _$SubmessageTypeEnumMap[instance.msgType]!,
      'content': instance.content,
      'sender_id': instance.senderId,
    };

const _$SubmessageTypeEnumMap = {
  SubmessageType.widget: 'widget',
  SubmessageType.unknown: 'unknown',
};
