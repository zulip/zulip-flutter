import 'package:json_annotation/json_annotation.dart';

part 'attachment.g.dart';

/// An uploaded file, as returned by https://zulip.com/api/update-message.
@JsonSerializable(fieldRename: FieldRename.snake)
class Attachment {
  final int id;
  final String name;

  Attachment({
    required this.id,
    required this.name,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) =>
    _$AttachmentFromJson(json);

  Map<String, dynamic> toJson() => _$AttachmentToJson(this);
}
