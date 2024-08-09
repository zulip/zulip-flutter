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

PollWidgetData _$PollWidgetDataFromJson(Map<String, dynamic> json) =>
    PollWidgetData(
      extraData: PollWidgetExtraData.fromJson(
          json['extra_data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PollWidgetDataToJson(PollWidgetData instance) =>
    <String, dynamic>{
      'widget_type': _$WidgetTypeEnumMap[instance.widgetType]!,
      'extra_data': instance.extraData,
    };

const _$WidgetTypeEnumMap = {
  WidgetType.poll: 'poll',
  WidgetType.unknown: 'unknown',
};

PollWidgetExtraData _$PollWidgetExtraDataFromJson(Map<String, dynamic> json) =>
    PollWidgetExtraData(
      question: json['question'] as String,
      options:
          (json['options'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$PollWidgetExtraDataToJson(
        PollWidgetExtraData instance) =>
    <String, dynamic>{
      'question': instance.question,
      'options': instance.options,
    };

PollOptionEvent _$PollOptionEventFromJson(Map<String, dynamic> json) =>
    PollOptionEvent(
      option: json['option'] as String,
      latestOptionIndex: (json['idx'] as num).toInt(),
    );

Map<String, dynamic> _$PollOptionEventToJson(PollOptionEvent instance) =>
    <String, dynamic>{
      'type': _$PollEventTypeEnumMap[instance.type]!,
      'option': instance.option,
      'idx': instance.latestOptionIndex,
    };

const _$PollEventTypeEnumMap = {
  PollEventType.newOption: 'new_option',
  PollEventType.question: 'question',
  PollEventType.vote: 'vote',
  PollEventType.unknown: 'unknown',
};

PollQuestionEvent _$PollQuestionEventFromJson(Map<String, dynamic> json) =>
    PollQuestionEvent(
      question: json['question'] as String,
    );

Map<String, dynamic> _$PollQuestionEventToJson(PollQuestionEvent instance) =>
    <String, dynamic>{
      'type': _$PollEventTypeEnumMap[instance.type]!,
      'question': instance.question,
    };

PollVoteEvent _$PollVoteEventFromJson(Map<String, dynamic> json) =>
    PollVoteEvent(
      key: json['key'] as String,
      op: $enumDecode(_$VoteOpEnumMap, json['vote'],
          unknownValue: VoteOp.unknown),
    );

Map<String, dynamic> _$PollVoteEventToJson(PollVoteEvent instance) =>
    <String, dynamic>{
      'type': _$PollEventTypeEnumMap[instance.type]!,
      'key': instance.key,
      'vote': instance.op,
    };

const _$VoteOpEnumMap = {
  VoteOp.add: 1,
  VoteOp.remove: -1,
  VoteOp.unknown: null,
};
