// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RealmEmojiUpdateEvent _$RealmEmojiUpdateEventFromJson(
        Map<String, dynamic> json) =>
    RealmEmojiUpdateEvent(
      id: (json['id'] as num).toInt(),
      realmEmoji: (json['realm_emoji'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, RealmEmojiItem.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$RealmEmojiUpdateEventToJson(
        RealmEmojiUpdateEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'op': instance.op,
      'realm_emoji': instance.realmEmoji,
    };

AlertWordsEvent _$AlertWordsEventFromJson(Map<String, dynamic> json) =>
    AlertWordsEvent(
      id: (json['id'] as num).toInt(),
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
      id: (json['id'] as num).toInt(),
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

CustomProfileFieldsEvent _$CustomProfileFieldsEventFromJson(
        Map<String, dynamic> json) =>
    CustomProfileFieldsEvent(
      id: (json['id'] as num).toInt(),
      fields: (json['fields'] as List<dynamic>)
          .map((e) => CustomProfileField.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CustomProfileFieldsEventToJson(
        CustomProfileFieldsEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'fields': instance.fields,
    };

RealmUserAddEvent _$RealmUserAddEventFromJson(Map<String, dynamic> json) =>
    RealmUserAddEvent(
      id: (json['id'] as num).toInt(),
      person: User.fromJson(json['person'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RealmUserAddEventToJson(RealmUserAddEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'op': instance.op,
      'person': instance.person,
    };

RealmUserUpdateCustomProfileField _$RealmUserUpdateCustomProfileFieldFromJson(
        Map<String, dynamic> json) =>
    RealmUserUpdateCustomProfileField(
      id: (json['id'] as num).toInt(),
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
      id: (json['id'] as num).toInt(),
      userId: (RealmUserUpdateEvent._readFromPerson(json, 'user_id') as num)
          .toInt(),
      fullName:
          RealmUserUpdateEvent._readFromPerson(json, 'full_name') as String?,
      avatarUrl:
          RealmUserUpdateEvent._readFromPerson(json, 'avatar_url') as String?,
      avatarVersion:
          (RealmUserUpdateEvent._readFromPerson(json, 'avatar_version') as num?)
              ?.toInt(),
      timezone:
          RealmUserUpdateEvent._readFromPerson(json, 'timezone') as String?,
      botOwnerId:
          (RealmUserUpdateEvent._readFromPerson(json, 'bot_owner_id') as num?)
              ?.toInt(),
      role: $enumDecodeNullable(
          _$UserRoleEnumMap, RealmUserUpdateEvent._readFromPerson(json, 'role'),
          unknownValue: UserRole.unknown),
      isBillingAdmin:
          RealmUserUpdateEvent._readFromPerson(json, 'is_billing_admin')
              as bool?,
      deliveryEmail:
          _$JsonConverterFromJson<JsonNullable<String>, JsonNullable<String>>(
              RealmUserUpdateEvent._readNullableStringFromPerson(
                  json, 'delivery_email'),
              const NullableStringJsonConverter().fromJson),
      customProfileField: RealmUserUpdateEvent._readFromPerson(
                  json, 'custom_profile_field') ==
              null
          ? null
          : RealmUserUpdateCustomProfileField.fromJson(
              RealmUserUpdateEvent._readFromPerson(json, 'custom_profile_field')
                  as Map<String, dynamic>),
      newEmail:
          RealmUserUpdateEvent._readFromPerson(json, 'new_email') as String?,
      isActive:
          RealmUserUpdateEvent._readFromPerson(json, 'is_active') as bool?,
    );

Map<String, dynamic> _$RealmUserUpdateEventToJson(
        RealmUserUpdateEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'op': instance.op,
      'user_id': instance.userId,
      'full_name': instance.fullName,
      'avatar_url': instance.avatarUrl,
      'avatar_version': instance.avatarVersion,
      'timezone': instance.timezone,
      'bot_owner_id': instance.botOwnerId,
      'role': instance.role,
      'is_billing_admin': instance.isBillingAdmin,
      'delivery_email':
          _$JsonConverterToJson<JsonNullable<String>, JsonNullable<String>>(
              instance.deliveryEmail,
              const NullableStringJsonConverter().toJson),
      'custom_profile_field': instance.customProfileField,
      'new_email': instance.newEmail,
      'is_active': instance.isActive,
    };

const _$UserRoleEnumMap = {
  UserRole.owner: 100,
  UserRole.administrator: 200,
  UserRole.moderator: 300,
  UserRole.member: 400,
  UserRole.guest: 600,
  UserRole.unknown: null,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);

ChannelCreateEvent _$ChannelCreateEventFromJson(Map<String, dynamic> json) =>
    ChannelCreateEvent(
      id: (json['id'] as num).toInt(),
      streams: (json['streams'] as List<dynamic>)
          .map((e) => ZulipStream.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ChannelCreateEventToJson(ChannelCreateEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'op': instance.op,
      'streams': instance.streams,
    };

ChannelDeleteEvent _$ChannelDeleteEventFromJson(Map<String, dynamic> json) =>
    ChannelDeleteEvent(
      id: (json['id'] as num).toInt(),
      streams: (json['streams'] as List<dynamic>)
          .map((e) => ZulipStream.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ChannelDeleteEventToJson(ChannelDeleteEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'op': instance.op,
      'streams': instance.streams,
    };

ChannelUpdateEvent _$ChannelUpdateEventFromJson(Map<String, dynamic> json) =>
    ChannelUpdateEvent(
      id: (json['id'] as num).toInt(),
      streamId: (json['stream_id'] as num).toInt(),
      name: json['name'] as String,
      property: $enumDecodeNullable(
          _$ChannelPropertyNameEnumMap, json['property'],
          unknownValue: JsonKey.nullForUndefinedEnumValue),
      value: ChannelUpdateEvent._readValue(json, 'value'),
      renderedDescription: json['rendered_description'] as String?,
      historyPublicToSubscribers:
          json['history_public_to_subscribers'] as bool?,
      isWebPublic: json['is_web_public'] as bool?,
    );

Map<String, dynamic> _$ChannelUpdateEventToJson(ChannelUpdateEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'op': instance.op,
      'stream_id': instance.streamId,
      'name': instance.name,
      'property': _$ChannelPropertyNameEnumMap[instance.property],
      'value': instance.value,
      'rendered_description': instance.renderedDescription,
      'history_public_to_subscribers': instance.historyPublicToSubscribers,
      'is_web_public': instance.isWebPublic,
    };

const _$ChannelPropertyNameEnumMap = {
  ChannelPropertyName.name: 'name',
  ChannelPropertyName.description: 'description',
  ChannelPropertyName.firstMessageId: 'first_message_id',
  ChannelPropertyName.inviteOnly: 'invite_only',
  ChannelPropertyName.messageRetentionDays: 'message_retention_days',
  ChannelPropertyName.channelPostPolicy: 'stream_post_policy',
  ChannelPropertyName.streamWeeklyTraffic: 'stream_weekly_traffic',
};

SubscriptionAddEvent _$SubscriptionAddEventFromJson(
        Map<String, dynamic> json) =>
    SubscriptionAddEvent(
      id: (json['id'] as num).toInt(),
      subscriptions: (json['subscriptions'] as List<dynamic>)
          .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SubscriptionAddEventToJson(
        SubscriptionAddEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'op': instance.op,
      'subscriptions': instance.subscriptions,
    };

SubscriptionRemoveEvent _$SubscriptionRemoveEventFromJson(
        Map<String, dynamic> json) =>
    SubscriptionRemoveEvent(
      id: (json['id'] as num).toInt(),
      streamIds: (SubscriptionRemoveEvent._readStreamIds(json, 'stream_ids')
              as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$SubscriptionRemoveEventToJson(
        SubscriptionRemoveEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'op': instance.op,
      'stream_ids': instance.streamIds,
    };

SubscriptionUpdateEvent _$SubscriptionUpdateEventFromJson(
        Map<String, dynamic> json) =>
    SubscriptionUpdateEvent(
      id: (json['id'] as num).toInt(),
      streamId: (json['stream_id'] as num).toInt(),
      property: $enumDecode(_$SubscriptionPropertyEnumMap, json['property']),
      value: SubscriptionUpdateEvent._readValue(json, 'value'),
    );

Map<String, dynamic> _$SubscriptionUpdateEventToJson(
        SubscriptionUpdateEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'op': instance.op,
      'stream_id': instance.streamId,
      'property': _$SubscriptionPropertyEnumMap[instance.property]!,
      'value': instance.value,
    };

const _$SubscriptionPropertyEnumMap = {
  SubscriptionProperty.color: 'color',
  SubscriptionProperty.isMuted: 'is_muted',
  SubscriptionProperty.inHomeView: 'in_home_view',
  SubscriptionProperty.pinToTop: 'pin_to_top',
  SubscriptionProperty.desktopNotifications: 'desktop_notifications',
  SubscriptionProperty.audibleNotifications: 'audible_notifications',
  SubscriptionProperty.pushNotifications: 'push_notifications',
  SubscriptionProperty.emailNotifications: 'email_notifications',
  SubscriptionProperty.wildcardMentionsNotify: 'wildcard_mentions_notify',
  SubscriptionProperty.unknown: 'unknown',
};

SubscriptionPeerAddEvent _$SubscriptionPeerAddEventFromJson(
        Map<String, dynamic> json) =>
    SubscriptionPeerAddEvent(
      id: (json['id'] as num).toInt(),
      streamIds: (json['stream_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      userIds: (json['user_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$SubscriptionPeerAddEventToJson(
        SubscriptionPeerAddEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'op': instance.op,
      'stream_ids': instance.streamIds,
      'user_ids': instance.userIds,
    };

SubscriptionPeerRemoveEvent _$SubscriptionPeerRemoveEventFromJson(
        Map<String, dynamic> json) =>
    SubscriptionPeerRemoveEvent(
      id: (json['id'] as num).toInt(),
      streamIds: (json['stream_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      userIds: (json['user_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$SubscriptionPeerRemoveEventToJson(
        SubscriptionPeerRemoveEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'op': instance.op,
      'stream_ids': instance.streamIds,
      'user_ids': instance.userIds,
    };

UserTopicEvent _$UserTopicEventFromJson(Map<String, dynamic> json) =>
    UserTopicEvent(
      id: (json['id'] as num).toInt(),
      streamId: (json['stream_id'] as num).toInt(),
      topicName: TopicName.fromJson(json['topic_name'] as String),
      lastUpdated: (json['last_updated'] as num).toInt(),
      visibilityPolicy: $enumDecode(
          _$UserTopicVisibilityPolicyEnumMap, json['visibility_policy']),
    );

Map<String, dynamic> _$UserTopicEventToJson(UserTopicEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'stream_id': instance.streamId,
      'topic_name': instance.topicName,
      'last_updated': instance.lastUpdated,
      'visibility_policy': instance.visibilityPolicy,
    };

const _$UserTopicVisibilityPolicyEnumMap = {
  UserTopicVisibilityPolicy.none: 0,
  UserTopicVisibilityPolicy.muted: 1,
  UserTopicVisibilityPolicy.unmuted: 2,
  UserTopicVisibilityPolicy.followed: 3,
  UserTopicVisibilityPolicy.unknown: null,
};

UpdateMessageEvent _$UpdateMessageEventFromJson(Map<String, dynamic> json) =>
    UpdateMessageEvent(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      renderingOnly: json['rendering_only'] as bool?,
      messageId: (json['message_id'] as num).toInt(),
      messageIds: (json['message_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      flags: (json['flags'] as List<dynamic>)
          .map((e) => $enumDecode(_$MessageFlagEnumMap, e))
          .toList(),
      editTimestamp: (json['edit_timestamp'] as num?)?.toInt(),
      origStreamId: (json['stream_id'] as num?)?.toInt(),
      newStreamId: (json['new_stream_id'] as num?)?.toInt(),
      propagateMode:
          $enumDecodeNullable(_$PropagateModeEnumMap, json['propagate_mode']),
      origTopic: json['orig_subject'] == null
          ? null
          : TopicName.fromJson(json['orig_subject'] as String),
      newTopic: json['subject'] == null
          ? null
          : TopicName.fromJson(json['subject'] as String),
      origContent: json['orig_content'] as String?,
      origRenderedContent: json['orig_rendered_content'] as String?,
      content: json['content'] as String?,
      renderedContent: json['rendered_content'] as String?,
      isMeMessage: json['is_me_message'] as bool?,
    );

Map<String, dynamic> _$UpdateMessageEventToJson(UpdateMessageEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'user_id': instance.userId,
      'rendering_only': instance.renderingOnly,
      'message_id': instance.messageId,
      'message_ids': instance.messageIds,
      'flags': instance.flags,
      'edit_timestamp': instance.editTimestamp,
      'stream_id': instance.origStreamId,
      'new_stream_id': instance.newStreamId,
      'propagate_mode': _$PropagateModeEnumMap[instance.propagateMode],
      'orig_subject': instance.origTopic,
      'subject': instance.newTopic,
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
      id: (json['id'] as num).toInt(),
      messageIds: (json['message_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      messageType:
          const MessageTypeConverter().fromJson(json['message_type'] as String),
      streamId: (json['stream_id'] as num?)?.toInt(),
      topic: json['topic'] == null
          ? null
          : TopicName.fromJson(json['topic'] as String),
    );

Map<String, dynamic> _$DeleteMessageEventToJson(DeleteMessageEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'message_ids': instance.messageIds,
      'message_type': const MessageTypeConverter().toJson(instance.messageType),
      'stream_id': instance.streamId,
      'topic': instance.topic,
    };

UpdateMessageFlagsAddEvent _$UpdateMessageFlagsAddEventFromJson(
        Map<String, dynamic> json) =>
    UpdateMessageFlagsAddEvent(
      id: (json['id'] as num).toInt(),
      flag: $enumDecode(_$MessageFlagEnumMap, json['flag'],
          unknownValue: MessageFlag.unknown),
      messages: (json['messages'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      all: json['all'] as bool,
    );

Map<String, dynamic> _$UpdateMessageFlagsAddEventToJson(
        UpdateMessageFlagsAddEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'flag': instance.flag,
      'messages': instance.messages,
      'op': instance.op,
      'all': instance.all,
    };

UpdateMessageFlagsRemoveEvent _$UpdateMessageFlagsRemoveEventFromJson(
        Map<String, dynamic> json) =>
    UpdateMessageFlagsRemoveEvent(
      id: (json['id'] as num).toInt(),
      flag: $enumDecode(_$MessageFlagEnumMap, json['flag'],
          unknownValue: MessageFlag.unknown),
      messages: (json['messages'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      messageDetails: (json['message_details'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            int.parse(k),
            UpdateMessageFlagsMessageDetail.fromJson(
                e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$UpdateMessageFlagsRemoveEventToJson(
        UpdateMessageFlagsRemoveEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'flag': instance.flag,
      'messages': instance.messages,
      'op': instance.op,
      'message_details':
          instance.messageDetails?.map((k, e) => MapEntry(k.toString(), e)),
    };

UpdateMessageFlagsMessageDetail _$UpdateMessageFlagsMessageDetailFromJson(
        Map<String, dynamic> json) =>
    UpdateMessageFlagsMessageDetail(
      type: const MessageTypeConverter().fromJson(json['type'] as String),
      mentioned: json['mentioned'] as bool?,
      userIds: (json['user_ids'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      streamId: (json['stream_id'] as num?)?.toInt(),
      topic: json['topic'] == null
          ? null
          : TopicName.fromJson(json['topic'] as String),
    );

Map<String, dynamic> _$UpdateMessageFlagsMessageDetailToJson(
        UpdateMessageFlagsMessageDetail instance) =>
    <String, dynamic>{
      'type': const MessageTypeConverter().toJson(instance.type),
      'mentioned': instance.mentioned,
      'user_ids': instance.userIds,
      'stream_id': instance.streamId,
      'topic': instance.topic,
    };

SubmessageEvent _$SubmessageEventFromJson(Map<String, dynamic> json) =>
    SubmessageEvent(
      id: (json['id'] as num).toInt(),
      msgType: $enumDecode(_$SubmessageTypeEnumMap, json['msg_type'],
          unknownValue: SubmessageType.unknown),
      content: json['content'] as String,
      messageId: (json['message_id'] as num).toInt(),
      senderId: (json['sender_id'] as num).toInt(),
      submessageId: (json['submessage_id'] as num).toInt(),
    );

Map<String, dynamic> _$SubmessageEventToJson(SubmessageEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'msg_type': instance.msgType,
      'content': instance.content,
      'message_id': instance.messageId,
      'sender_id': instance.senderId,
      'submessage_id': instance.submessageId,
    };

const _$SubmessageTypeEnumMap = {
  SubmessageType.widget: 'widget',
  SubmessageType.unknown: 'unknown',
};

TypingEvent _$TypingEventFromJson(Map<String, dynamic> json) => TypingEvent(
      id: (json['id'] as num).toInt(),
      op: $enumDecode(_$TypingOpEnumMap, json['op']),
      messageType:
          const MessageTypeConverter().fromJson(json['message_type'] as String),
      senderId: (TypingEvent._readSenderId(json, 'sender_id') as num).toInt(),
      recipientIds: TypingEvent._recipientIdsFromJson(json['recipients']),
      streamId: (json['stream_id'] as num?)?.toInt(),
      topic: json['topic'] == null
          ? null
          : TopicName.fromJson(json['topic'] as String),
    );

Map<String, dynamic> _$TypingEventToJson(TypingEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'op': instance.op,
      'message_type': const MessageTypeConverter().toJson(instance.messageType),
      'sender_id': instance.senderId,
      'recipients': instance.recipientIds,
      'stream_id': instance.streamId,
      'topic': instance.topic,
    };

const _$TypingOpEnumMap = {
  TypingOp.start: 'start',
  TypingOp.stop: 'stop',
};

ReactionEvent _$ReactionEventFromJson(Map<String, dynamic> json) =>
    ReactionEvent(
      id: (json['id'] as num).toInt(),
      op: $enumDecode(_$ReactionOpEnumMap, json['op']),
      emojiName: json['emoji_name'] as String,
      emojiCode: json['emoji_code'] as String,
      reactionType: $enumDecode(_$ReactionTypeEnumMap, json['reaction_type']),
      userId: (json['user_id'] as num).toInt(),
      messageId: (json['message_id'] as num).toInt(),
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
      id: (json['id'] as num).toInt(),
    );

Map<String, dynamic> _$HeartbeatEventToJson(HeartbeatEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
    };

const _$MessageTypeEnumMap = {
  MessageType.stream: 'stream',
  MessageType.direct: 'direct',
};
