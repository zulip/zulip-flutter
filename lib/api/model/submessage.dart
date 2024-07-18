import 'package:json_annotation/json_annotation.dart';

part 'submessage.g.dart';

/// Data used for certain experimental Zulip widgets including polls and todo
/// lists.
///
/// See:
///   https://zulip.com/api/get-messages#response
///   https://zulip.readthedocs.io/en/latest/subsystems/widgets.html
@JsonSerializable(fieldRename: FieldRename.snake)
class Submessage {
  const Submessage({
    required this.msgType,
    required this.content,
    required this.senderId,
  });

  @JsonKey(unknownEnumValue: SubmessageType.unknown)
  final SubmessageType msgType;
  final String content;
  // final int messageId;  // ignored; redundant with [Message.id]
  final int senderId;
  // final int id;  // ignored because it is unused

  factory Submessage.fromJson(Map<String, Object?> json) =>
    _$SubmessageFromJson(json);

  Map<String, Object?> toJson() => _$SubmessageToJson(this);
}

/// As in [Submessage.msgType].
enum SubmessageType {
  widget,
  unknown,
}
