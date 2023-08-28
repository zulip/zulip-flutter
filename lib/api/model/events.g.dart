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

UserSettingsUpdateEvent _$UserSettingsUpdateEventFromJson(
        Map<String, dynamic> json) =>
    UserSettingsUpdateEvent(
      id: json['id'] as int,
      property: $enumDecodeNullable(_$UserSettingNameEnumMap, json['property'],
          unknownValue: JsonKey.nullForUndefinedEnumValue),
      value: UserSettingsUpdateEvent._readValue(json, 'value'),
    );

Map<String, dynamic> _$UserSettingsUpdateEventToJson(
        UserSettingsUpdateEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'op': instance.op,
      'property': _$UserSettingNameEnumMap[instance.property],
      'value': instance.value,
    };

const _$UserSettingNameEnumMap = {
  UserSettingName.twentyFourHourTime: 'twenty_four_hour_time',
  UserSettingName.displayEmojiReactionUsers: 'display_emoji_reaction_users',
  UserSettingName.emojiset: 'emojiset',
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
      role: $enumDecodeNullable(
          _$UserRoleEnumMap, RealmUserUpdateEvent._readFromPerson(json, 'role'),
          unknownValue: UserRole.unknown),
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

const _$UserRoleEnumMap = {
  UserRole.owner: 100,
  UserRole.administrator: 200,
  UserRole.moderator: 300,
  UserRole.member: 400,
  UserRole.guest: 600,
  UserRole.unknown: null,
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

UpdateMessageEvent _$UpdateMessageEventFromJson(Map<String, dynamic> json) =>
    UpdateMessageEvent(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      renderingOnly: json['rendering_only'] as bool?,
      messageId: json['message_id'] as int,
      messageIds:
          (json['message_ids'] as List<dynamic>).map((e) => e as int).toList(),
      flags: (json['flags'] as List<dynamic>)
          .map((e) => $enumDecode(_$MessageFlagEnumMap, e))
          .toList(),
      editTimestamp: json['edit_timestamp'] as int?,
      streamName: json['stream_name'] as String?,
      streamId: json['stream_id'] as int?,
      newStreamId: json['new_stream_id'] as int?,
      propagateMode:
          $enumDecodeNullable(_$PropagateModeEnumMap, json['propagate_mode']),
      origSubject: json['orig_subject'] as String?,
      subject: json['subject'] as String?,
      origContent: json['orig_content'] as String?,
      origRenderedContent: json['orig_rendered_content'] as String?,
      content: json['content'] as String?,
      renderedContent: json['rendered_content'] as String?,
      isMeMessage: json['is_me_message'] as bool?,
    );

Map<String, dynamic> _$UpdateMessageEventToJson(UpdateMessageEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'rendering_only': instance.renderingOnly,
      'message_id': instance.messageId,
      'message_ids': instance.messageIds,
      'flags': instance.flags,
      'edit_timestamp': instance.editTimestamp,
      'stream_name': instance.streamName,
      'stream_id': instance.streamId,
      'new_stream_id': instance.newStreamId,
      'propagate_mode': _$PropagateModeEnumMap[instance.propagateMode],
      'orig_subject': instance.origSubject,
      'subject': instance.subject,
      'orig_content': instance.origContent,
      'orig_rendered_content': instance.origRenderedContent,
      'content': instance.content,
      'rendered_content': instance.renderedContent,
      'is_me_message': instance.isMeMessage,
    };

const _$MessageFlagEnumMap = {
  MessageFlag.read: 'read',
  MessageFlag.starred: 'starred',
  MessageFlag.collapsed: 'collapsed',
  MessageFlag.mentioned: 'mentioned',
  MessageFlag.wildcardMentioned: 'wildcard_mentioned',
  MessageFlag.hasAlertWord: 'has_alert_word',
  MessageFlag.historical: 'historical',
  MessageFlag.unknown: 'unknown',
};

const _$PropagateModeEnumMap = {
  PropagateMode.changeOne: 'change_one',
  PropagateMode.changeLater: 'change_later',
  PropagateMode.changeAll: 'change_all',
};

DeleteMessageEvent _$DeleteMessageEventFromJson(Map<String, dynamic> json) =>
    DeleteMessageEvent(
      id: json['id'] as int,
      messageIds:
          (json['message_ids'] as List<dynamic>).map((e) => e as int).toList(),
      messageType: $enumDecode(_$MessageTypeEnumMap, json['message_type']),
      streamId: json['stream_id'] as int?,
      topic: json['topic'] as String?,
    );

Map<String, dynamic> _$DeleteMessageEventToJson(DeleteMessageEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message_ids': instance.messageIds,
      'message_type': _$MessageTypeEnumMap[instance.messageType]!,
      'stream_id': instance.streamId,
      'topic': instance.topic,
    };

const _$MessageTypeEnumMap = {
  MessageType.stream: 'stream',
  MessageType.private: 'private',
};

ReactionEvent _$ReactionEventFromJson(Map<String, dynamic> json) =>
    ReactionEvent(
      id: json['id'] as int,
      op: $enumDecode(_$ReactionOpEnumMap, json['op']),
      emojiName: json['emoji_name'] as String,
      emojiCode: json['emoji_code'] as String,
      reactionType: $enumDecode(_$ReactionTypeEnumMap, json['reaction_type']),
      userId: json['user_id'] as int,
      messageId: json['message_id'] as int,
    );

Map<String, dynamic> _$ReactionEventToJson(ReactionEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'op': _$ReactionOpEnumMap[instance.op]!,
      'emoji_name': instance.emojiName,
      'emoji_code': instance.emojiCode,
      'reaction_type': instance.reactionType,
      'user_id': instance.userId,
      'message_id': instance.messageId,
    };

const _$ReactionOpEnumMap = {
  ReactionOp.add: 'add',
  ReactionOp.remove: 'remove',
};

const _$ReactionTypeEnumMap = {
  ReactionType.unicodeEmoji: 'unicode_emoji',
  ReactionType.realmEmoji: 'realm_emoji',
  ReactionType.zulipExtraEmoji: 'zulip_extra_emoji',
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
