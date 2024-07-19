import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'submessage.g.dart';

/// Data used for certain experimental Zulip widgets including polls and todo
/// lists.
///
/// See:
///   https://zulip.com/api/get-messages#response
///   https://zulip.readthedocs.io/en/stable/subsystems/widgets.html
@JsonSerializable(fieldRename: FieldRename.snake)
class Submessage {
  const Submessage({
    required this.msgType,
    required this.content,
    required this.messageId,
    required this.senderId,
    required this.id,
  });

  @JsonKey(unknownEnumValue: SubmessageType.unknown)
  final SubmessageType msgType;
  /// [SubmessageData] encoded in JSON.
  @JsonKey(readValue: readContent, toJson: contentToJson)
  final Object? content;
  final int messageId;
  final int senderId;
  final int id;

  static Object? readContent(Map<Object?, Object?> json, String key) {
    try {
      final res = jsonDecode(json[key] as String) as Object?;
      return res;
    } on FormatException {
        return null;
    }
  }

  static Object? contentToJson(Object? content) =>
    jsonEncode(content);

  factory Submessage.fromJson(Map<String, Object?> json) =>
    _$SubmessageFromJson(json);

  Map<String, Object?> toJson() => _$SubmessageToJson(this);
}

/// As in [Submessage.msgType].
enum SubmessageType {
  widget,
  unknown,
}

sealed class SubmessageData {}

/// The data encoded in a submessage to make the message a Zulip widget.
///
/// Expected from the first [Submessage.content] in the "submessages" field on
/// the message when there is an widget.
///
/// See https://zulip.readthedocs.io/en/stable/subsystems/widgets.html
sealed class WidgetData extends SubmessageData {
  WidgetType get widgetType;

  WidgetData();

  factory WidgetData.fromJson(Object? json) {
    if (json is! Map) return UnsupportedWidgetData(json: json);
    final map = json as Map<String, Object?>;
    final rawWidgetType = map['widget_type'];
    if (rawWidgetType == null) return UnsupportedWidgetData(json: json);
    return switch (WidgetType.fromJson(rawWidgetType)) {
      WidgetType.poll => PollWidgetData.fromJson(map),
      WidgetType.unknown => UnsupportedWidgetData(json: map),
    };
  }

  Object? toJson();
}

/// As in [WidgetData.widgetType].
@JsonEnum(alwaysCreate: true)
enum WidgetType {
  poll,
  unknown;

  factory WidgetType.fromJson(Object value) {
    return $enumDecode<WidgetType, String>(
      _$WidgetTypeEnumMap,
      value,
      unknownValue: WidgetType.unknown
    );
  }
}

/// The data encoded in a submessage to make the message a poll widget.
@JsonSerializable(fieldRename: FieldRename.snake)
class PollWidgetData extends WidgetData {
  @override
  @JsonKey(includeToJson: true)
  WidgetType get widgetType => WidgetType.poll;

  /// The initial question and options on the poll.
  final PollWidgetExtraData extraData;

  PollWidgetData({required this.extraData});

  factory PollWidgetData.fromJson(Map<String, Object?> json) =>
    _$PollWidgetDataFromJson(json);

  @override
  Map<String, Object?> toJson() => _$PollWidgetDataToJson(this);
}

/// As in [PollWidgetData.extraData].
@JsonSerializable(fieldRename: FieldRename.snake)
class PollWidgetExtraData {
  final String question;
  final List<String> options;

  const PollWidgetExtraData({required this.question, required this.options});

  factory PollWidgetExtraData.fromJson(Map<String, Object?> json) =>
    _$PollWidgetExtraDataFromJson(json);

  Map<String, Object?> toJson() => _$PollWidgetExtraDataToJson(this);
}

class UnsupportedWidgetData extends WidgetData {
  @override
  @JsonKey(includeToJson: true)
  WidgetType get widgetType => WidgetType.unknown;

  UnsupportedWidgetData({required this.json});

  final Object? json;

  @override
  Object? toJson() => json;
}

/// The data encoded in a submessage that acts on a poll.
sealed class PollEvent extends SubmessageData {
  PollEventType get type;

  PollEvent();

  /// The key for identifying the [optionIndex]'th option added by user
  /// [senderId] to a poll.
  ///
  /// For options that are a part of the initial [PollWidgetData], the
  /// [senderId] should be `null`.
  static String optionKey({required int? senderId, required int optionIndex}) =>
    // "canned" is a canonical constant coined by the web client.
    '${senderId ?? 'canned'},$optionIndex';

  factory PollEvent.fromJson(Map<String, Object?> json) {
    final rawPollEventType = json['type'];
    if (rawPollEventType == null) return UnknownPollEvent(json: json);
    switch ($enumDecode(
      _$PollEventTypeEnumMap,
      rawPollEventType,
      unknownValue: PollEventType.unknown,
    )) {
      case PollEventType.newOption: return PollOptionEvent.fromJson(json);
      case PollEventType.question: return PollQuestionEvent.fromJson(json);
      case PollEventType.vote: return PollVoteEvent.fromJson(json);
      case PollEventType.unknown: return UnknownPollEvent(json: json);
    }
  }

  Map<String, Object?> toJson();
}

/// A poll event when an option is added.
@JsonSerializable(fieldRename: FieldRename.snake)
class PollOptionEvent extends PollEvent {
  @override
  @JsonKey(includeToJson: true)
  PollEventType get type => PollEventType.newOption;

  final String option;
  /// The index of last [option] added by the sender.
  @JsonKey(name: 'idx')
  final int latestOptionIndex;

  PollOptionEvent({required this.option, required this.latestOptionIndex});

  @override
  factory PollOptionEvent.fromJson(Map<String, Object?> json) =>
    _$PollOptionEventFromJson(json);

  @override
  Map<String, Object?> toJson() => _$PollOptionEventToJson(this);
}

/// A poll event when the question has been edited.
@JsonSerializable(fieldRename: FieldRename.snake)
class PollQuestionEvent extends PollEvent {
  @override
  @JsonKey(includeToJson: true)
  PollEventType get type => PollEventType.question;

  final String question;

  PollQuestionEvent({required this.question});

  @override
  factory PollQuestionEvent.fromJson(Map<String, Object?> json) =>
    _$PollQuestionEventFromJson(json);

  @override
  Map<String, Object?> toJson() => _$PollQuestionEventToJson(this);
}

/// A poll event when a vote has been cast or removed.
@JsonSerializable(fieldRename: FieldRename.snake)
class PollVoteEvent extends PollEvent {
  @override
  @JsonKey(includeToJson: true)
  PollEventType get type => PollEventType.vote;

  /// The key of the affected option.
  ///
  /// See [PollEvent.optionKey].
  final String key;
  @JsonKey(name: 'vote', unknownEnumValue: VoteOp.unknown)
  final VoteOp op;

  PollVoteEvent({required this.key, required this.op});

  @override
  factory PollVoteEvent.fromJson(Map<String, Object?> json) {
    final result = _$PollVoteEventFromJson(json);
    // Crunchy-shell validation
    final segments = result.key.split(',');
    final [senderId, optionIndex] = segments;
    if (senderId != 'canned') {
      int.parse(senderId, radix: 10);
    }
    int.parse(optionIndex, radix: 10);
    return result;
  }

  @override
  Map<String, Object?> toJson() => _$PollVoteEventToJson(this);
}

/// As in [PollVoteEvent.op].
@JsonEnum(valueField: 'apiValue')
enum VoteOp {
  add(apiValue: 1),
  remove(apiValue: -1),
  unknown(apiValue: null);

  const VoteOp({required this.apiValue});

  final int? apiValue;

  int? toJson() => apiValue;
}

class UnknownPollEvent extends PollEvent {
  @override
  @JsonKey(includeToJson: true)
  PollEventType get type => PollEventType.unknown;

  final Map<String, Object?> json;

  UnknownPollEvent({required this.json});

  @override
  Map<String, Object?> toJson() => json;
}

/// As in [PollEvent.type].
@JsonEnum(fieldRename: FieldRename.snake)
enum PollEventType {
  newOption,
  question,
  vote,
  unknown,
}
