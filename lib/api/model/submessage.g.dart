// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'submessage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Submessage _$SubmessageFromJson(Map<String, dynamic> json) => Submessage(
  senderId: (json['sender_id'] as num).toInt(),
  msgType: $enumDecode(
    _$SubmessageTypeEnumMap,
    json['msg_type'],
    unknownValue: SubmessageType.unknown,
  ),
  content: json['content'] as String,
);

Map<String, dynamic> _$SubmessageToJson(Submessage instance) =>
    <String, dynamic>{
      'sender_id': instance.senderId,
      'msg_type': instance.msgType,
      'content': instance.content,
    };

const _$SubmessageTypeEnumMap = {
  SubmessageType.widget: 'widget',
  SubmessageType.unknown: 'unknown',
};

PollWidgetData _$PollWidgetDataFromJson(Map<String, dynamic> json) =>
    PollWidgetData(
      extraData: PollWidgetExtraData.fromJson(
        json['extra_data'] as Map<String, dynamic>,
      ),
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
      question: json['question'] as String? ?? '',
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$PollWidgetExtraDataToJson(
  PollWidgetExtraData instance,
) => <String, dynamic>{
  'question': instance.question,
  'options': instance.options,
};

PollNewOptionEventSubmessage _$PollNewOptionEventSubmessageFromJson(
  Map<String, dynamic> json,
) => PollNewOptionEventSubmessage(
  option: json['option'] as String,
  idx: (json['idx'] as num).toInt(),
);

Map<String, dynamic> _$PollNewOptionEventSubmessageToJson(
  PollNewOptionEventSubmessage instance,
) => <String, dynamic>{
  'type': _$PollEventSubmessageTypeEnumMap[instance.type]!,
  'option': instance.option,
  'idx': instance.idx,
};

const _$PollEventSubmessageTypeEnumMap = {
  PollEventSubmessageType.newOption: 'new_option',
  PollEventSubmessageType.question: 'question',
  PollEventSubmessageType.vote: 'vote',
  PollEventSubmessageType.unknown: 'unknown',
};

PollQuestionEventSubmessage _$PollQuestionEventSubmessageFromJson(
  Map<String, dynamic> json,
) => PollQuestionEventSubmessage(question: json['question'] as String);

Map<String, dynamic> _$PollQuestionEventSubmessageToJson(
  PollQuestionEventSubmessage instance,
) => <String, dynamic>{
  'type': _$PollEventSubmessageTypeEnumMap[instance.type]!,
  'question': instance.question,
};

PollVoteEventSubmessage _$PollVoteEventSubmessageFromJson(
  Map<String, dynamic> json,
) => PollVoteEventSubmessage(
  key: json['key'] as String,
  op: $enumDecode(
    _$PollVoteOpEnumMap,
    json['vote'],
    unknownValue: PollVoteOp.unknown,
  ),
);

Map<String, dynamic> _$PollVoteEventSubmessageToJson(
  PollVoteEventSubmessage instance,
) => <String, dynamic>{
  'type': _$PollEventSubmessageTypeEnumMap[instance.type]!,
  'key': instance.key,
  'vote': instance.op,
};

const _$PollVoteOpEnumMap = {
  PollVoteOp.add: 1,
  PollVoteOp.remove: -1,
  PollVoteOp.unknown: null,
};
