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
