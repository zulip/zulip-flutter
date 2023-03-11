// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertWordsEvent _$AlertWordsEventFromJson(Map<String, dynamic> json) =>
    AlertWordsEvent(
      id: json['id'] as int,
      alert_words: (json['alert_words'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AlertWordsEventToJson(AlertWordsEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'alert_words': instance.alert_words,
    };

RealmUserEvent _$RealmUserEventFromJson(Map<String, dynamic> json) =>
    RealmUserEvent(
      id: json['id'] as int,
      person: RealmUserUpdateEventPerson.fromJson(
          json['person'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RealmUserEventToJson(RealmUserEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'person': instance.person,
    };

RealmUserUpdateEventPerson _$RealmUserUpdateEventPersonFromJson(
        Map<String, dynamic> json) =>
    RealmUserUpdateEventPerson(
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

Map<String, dynamic> _$RealmUserUpdateEventPersonToJson(
        RealmUserUpdateEventPerson instance) =>
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

HeartbeatEvent _$HeartbeatEventFromJson(Map<String, dynamic> json) =>
    HeartbeatEvent(
      id: json['id'] as int,
    );

Map<String, dynamic> _$HeartbeatEventToJson(HeartbeatEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
    };
