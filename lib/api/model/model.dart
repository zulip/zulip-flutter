// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

/// As in `custom_profile_fields` in the initial snapshot.
///
/// https://zulip.com/api/register-queue#response
@JsonSerializable()
class CustomProfileField {
  final int id;
  final int type; // TODO enum; also TODO(server-6) a value added
  final int order;
  final String name;
  final String hint;
  final String field_data;
  final bool? display_in_profile_summary; // TODO(server-6)

  CustomProfileField({
    required this.id,
    required this.type,
    required this.order,
    required this.name,
    required this.hint,
    required this.field_data,
    required this.display_in_profile_summary,
  });

  factory CustomProfileField.fromJson(Map<String, dynamic> json) =>
      _$CustomProfileFieldFromJson(json);
}
