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

StreamMessage _$StreamMessageFromJson(Map<String, dynamic> json) =>
    StreamMessage(
      avatar_url: json['avatar_url'] as String?,
      client: json['client'] as String,
      content: json['content'] as String,
      content_type: json['content_type'] as String,
      id: json['id'] as int,
      is_me_message: json['is_me_message'] as bool,
      last_edit_timestamp: json['last_edit_timestamp'] as int?,
      recipient_id: json['recipient_id'] as int,
      sender_email: json['sender_email'] as String,
      sender_full_name: json['sender_full_name'] as String,
      sender_id: json['sender_id'] as int,
      sender_realm_str: json['sender_realm_str'] as String,
      subject: json['subject'] as String,
      timestamp: json['timestamp'] as int,
      flags: (json['flags'] as List<dynamic>).map((e) => e as String).toList(),
      match_content: json['match_content'] as String?,
      match_subject: json['match_subject'] as String?,
      display_recipient: json['display_recipient'] as String,
      stream_id: json['stream_id'] as int,
    );

Map<String, dynamic> _$StreamMessageToJson(StreamMessage instance) =>
    <String, dynamic>{
      'avatar_url': instance.avatar_url,
      'client': instance.client,
      'content': instance.content,
      'content_type': instance.content_type,
      'id': instance.id,
      'is_me_message': instance.is_me_message,
      'last_edit_timestamp': instance.last_edit_timestamp,
      'recipient_id': instance.recipient_id,
      'sender_email': instance.sender_email,
      'sender_full_name': instance.sender_full_name,
      'sender_id': instance.sender_id,
      'sender_realm_str': instance.sender_realm_str,
      'subject': instance.subject,
      'timestamp': instance.timestamp,
      'flags': instance.flags,
      'match_content': instance.match_content,
      'match_subject': instance.match_subject,
      'type': instance.type,
      'display_recipient': instance.display_recipient,
      'stream_id': instance.stream_id,
    };

PmRecipient _$PmRecipientFromJson(Map<String, dynamic> json) => PmRecipient(
      id: json['id'] as int,
      email: json['email'] as String,
      full_name: json['full_name'] as String,
    );

Map<String, dynamic> _$PmRecipientToJson(PmRecipient instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.full_name,
    };

PmMessage _$PmMessageFromJson(Map<String, dynamic> json) => PmMessage(
      avatar_url: json['avatar_url'] as String?,
      client: json['client'] as String,
      content: json['content'] as String,
      content_type: json['content_type'] as String,
      id: json['id'] as int,
      is_me_message: json['is_me_message'] as bool,
      last_edit_timestamp: json['last_edit_timestamp'] as int?,
      recipient_id: json['recipient_id'] as int,
      sender_email: json['sender_email'] as String,
      sender_full_name: json['sender_full_name'] as String,
      sender_id: json['sender_id'] as int,
      sender_realm_str: json['sender_realm_str'] as String,
      subject: json['subject'] as String,
      timestamp: json['timestamp'] as int,
      flags: (json['flags'] as List<dynamic>).map((e) => e as String).toList(),
      match_content: json['match_content'] as String?,
      match_subject: json['match_subject'] as String?,
      display_recipient: (json['display_recipient'] as List<dynamic>)
          .map((e) => PmRecipient.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PmMessageToJson(PmMessage instance) => <String, dynamic>{
      'avatar_url': instance.avatar_url,
      'client': instance.client,
      'content': instance.content,
      'content_type': instance.content_type,
      'id': instance.id,
      'is_me_message': instance.is_me_message,
      'last_edit_timestamp': instance.last_edit_timestamp,
      'recipient_id': instance.recipient_id,
      'sender_email': instance.sender_email,
      'sender_full_name': instance.sender_full_name,
      'sender_id': instance.sender_id,
      'sender_realm_str': instance.sender_realm_str,
      'subject': instance.subject,
      'timestamp': instance.timestamp,
      'flags': instance.flags,
      'match_content': instance.match_content,
      'match_subject': instance.match_subject,
      'type': instance.type,
      'display_recipient': instance.display_recipient,
    };

RealmUserEventPerson _$RealmUserEventPersonFromJson(
        Map<String, dynamic> json) =>
    RealmUserEventPerson(
      user_id: json['user_id'] as int,
      full_name: json['full_name'] as String?,
      avatar_url: json['avatar_url'] as String?,
      avatar_url_medium: json['avatar_url_medium'] as String?,
      avatar_source: json['avatar_source'] as String?,
      avatar_version: json['avatar_version'] as String?,
      timezone: json['timezone'] as String?,
      bot_owner_id: json['bot_owner_id'] as int?,
      role: json['role'] as int?,
      is_billing_admin: json['is_billing_admin'] as bool?,
      delivery_email: json['delivery_email'] as String?,
      new_email: json['new_email'] as String?,
    );

Map<String, dynamic> _$RealmUserEventPersonToJson(
        RealmUserEventPerson instance) =>
    <String, dynamic>{
      'user_id': instance.user_id,
      'full_name': instance.full_name,
      'avatar_url': instance.avatar_url,
      'avatar_url_medium': instance.avatar_url_medium,
      'avatar_source': instance.avatar_source,
      'avatar_version': instance.avatar_version,
      'timezone': instance.timezone,
      'bot_owner_id': instance.bot_owner_id,
      'role': instance.role,
      'is_billing_admin': instance.is_billing_admin,
      'delivery_email': instance.delivery_email,
      'new_email': instance.new_email,
    };
