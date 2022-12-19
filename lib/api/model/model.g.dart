// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomProfileField _$CustomProfileFieldFromJson(Map<String, dynamic> json) =>
    CustomProfileField(
      id: json['id'] as int,
      type: json['type'] as int,
      order: json['order'] as int,
      name: json['name'] as String,
      hint: json['hint'] as String,
      field_data: json['field_data'] as String,
      display_in_profile_summary: json['display_in_profile_summary'] as bool?,
    );

Map<String, dynamic> _$CustomProfileFieldToJson(CustomProfileField instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'order': instance.order,
      'name': instance.name,
      'hint': instance.hint,
      'field_data': instance.field_data,
      'display_in_profile_summary': instance.display_in_profile_summary,
    };
