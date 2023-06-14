// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast

part of 'events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertWordsEvent _$AlertWordsEventFromJson(Map<String, dynamic> json) =>
    AlertWordsEvent(
      id: json['id'] as int,
      alertWords: (json['alert_words'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AlertWordsEventToJson(AlertWordsEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'alert_words': instance.alertWords,
    };

RealmUserAddEvent _$RealmUserAddEventFromJson(Map<String, dynamic> json) =>
    RealmUserAddEvent(
      id: json['id'] as int,
      person: User.fromJson(json['person'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RealmUserAddEventToJson(RealmUserAddEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'person': instance.person,
    };

RealmUserUpdateCustomProfileField _$RealmUserUpdateCustomProfileFieldFromJson(
        Map<String, dynamic> json) =>
    RealmUserUpdateCustomProfileField(
      id: json['id'] as int,
      value: json['value'] as String?,
      renderedValue: json['rendered_value'] as String?,
    );

Map<String, dynamic> _$RealmUserUpdateCustomProfileFieldToJson(
        RealmUserUpdateCustomProfileField instance) =>
    <String, dynamic>{
      'id': instance.id,
      'value': instance.value,
      'rendered_value': instance.renderedValue,
    };

RealmUserUpdateEvent _$RealmUserUpdateEventFromJson(
        Map<String, dynamic> json) =>
    RealmUserUpdateEvent(
      id: json['id'] as int,
      userId: RealmUserUpdateEvent._readFromPerson(json, 'user_id') as int,
      fullName:
          RealmUserUpdateEvent._readFromPerson(json, 'full_name') as String?,
      avatarUrl:
          RealmUserUpdateEvent._readFromPerson(json, 'avatar_url') as String?,
      avatarVersion:
          RealmUserUpdateEvent._readFromPerson(json, 'avatar_version') as int?,
      timezone:
          RealmUserUpdateEvent._readFromPerson(json, 'timezone') as String?,
      botOwnerId:
          RealmUserUpdateEvent._readFromPerson(json, 'bot_owner_id') as int?,
      role: RealmUserUpdateEvent._readFromPerson(json, 'role') as int?,
      isBillingAdmin:
          RealmUserUpdateEvent._readFromPerson(json, 'is_billing_admin')
              as bool?,
      deliveryEmail:
          RealmUserUpdateEvent._readFromPerson(json, 'delivery_email')
              as String?,
      customProfileField: RealmUserUpdateEvent._readFromPerson(
                  json, 'custom_profile_field') ==
              null
          ? null
          : RealmUserUpdateCustomProfileField.fromJson(
              RealmUserUpdateEvent._readFromPerson(json, 'custom_profile_field')
                  as Map<String, dynamic>),
      newEmail:
          RealmUserUpdateEvent._readFromPerson(json, 'new_email') as String?,
    );

Map<String, dynamic> _$RealmUserUpdateEventToJson(
        RealmUserUpdateEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'user_id': instance.userId,
      'full_name': instance.fullName,
      'avatar_url': instance.avatarUrl,
      'avatar_version': instance.avatarVersion,
      'timezone': instance.timezone,
      'bot_owner_id': instance.botOwnerId,
      'role': instance.role,
      'is_billing_admin': instance.isBillingAdmin,
      'delivery_email': instance.deliveryEmail,
      'custom_profile_field': instance.customProfileField,
      'new_email': instance.newEmail,
    };

StreamCreateEvent _$StreamCreateEventFromJson(Map<String, dynamic> json) =>
    StreamCreateEvent(
      id: json['id'] as int,
      streams: (json['streams'] as List<dynamic>)
          .map((e) => ZulipStream.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StreamCreateEventToJson(StreamCreateEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'streams': instance.streams,
    };

StreamDeleteEvent _$StreamDeleteEventFromJson(Map<String, dynamic> json) =>
    StreamDeleteEvent(
      id: json['id'] as int,
      streams: (json['streams'] as List<dynamic>)
          .map((e) => ZulipStream.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StreamDeleteEventToJson(StreamDeleteEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'streams': instance.streams,
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
