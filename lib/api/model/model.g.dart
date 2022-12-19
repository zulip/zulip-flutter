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

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) => Subscription(
      stream_id: json['stream_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      rendered_description: json['rendered_description'] as String,
      date_created: json['date_created'] as int,
      invite_only: json['invite_only'] as bool,
      desktop_notifications: json['desktop_notifications'] as bool?,
      email_notifications: json['email_notifications'] as bool?,
      wildcard_mentions_notify: json['wildcard_mentions_notify'] as bool?,
      push_notifications: json['push_notifications'] as bool?,
      audible_notifications: json['audible_notifications'] as bool?,
      pin_to_top: json['pin_to_top'] as bool,
      email_address: json['email_address'] as String,
      is_muted: json['is_muted'] as bool,
      is_web_public: json['is_web_public'] as bool?,
      color: json['color'] as String,
      stream_post_policy: json['stream_post_policy'] as int,
      message_retention_days: json['message_retention_days'] as int?,
      history_public_to_subscribers:
          json['history_public_to_subscribers'] as bool,
      first_message_id: json['first_message_id'] as int?,
      stream_weekly_traffic: json['stream_weekly_traffic'] as int?,
      can_remove_subscribers_group_id:
          json['can_remove_subscribers_group_id'] as int?,
    );

Map<String, dynamic> _$SubscriptionToJson(Subscription instance) =>
    <String, dynamic>{
      'stream_id': instance.stream_id,
      'name': instance.name,
      'description': instance.description,
      'rendered_description': instance.rendered_description,
      'date_created': instance.date_created,
      'invite_only': instance.invite_only,
      'desktop_notifications': instance.desktop_notifications,
      'email_notifications': instance.email_notifications,
      'wildcard_mentions_notify': instance.wildcard_mentions_notify,
      'push_notifications': instance.push_notifications,
      'audible_notifications': instance.audible_notifications,
      'pin_to_top': instance.pin_to_top,
      'email_address': instance.email_address,
      'is_muted': instance.is_muted,
      'is_web_public': instance.is_web_public,
      'color': instance.color,
      'stream_post_policy': instance.stream_post_policy,
      'message_retention_days': instance.message_retention_days,
      'history_public_to_subscribers': instance.history_public_to_subscribers,
      'first_message_id': instance.first_message_id,
      'stream_weekly_traffic': instance.stream_weekly_traffic,
      'can_remove_subscribers_group_id':
          instance.can_remove_subscribers_group_id,
    };
