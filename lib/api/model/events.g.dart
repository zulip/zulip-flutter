// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RealmEmojiUpdateEvent _$RealmEmojiUpdateEventFromJson(
  Map<String, dynamic> json,
) => RealmEmojiUpdateEvent(
  id: (json['id'] as num).toInt(),
  realmEmoji: (json['realm_emoji'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, RealmEmojiItem.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$RealmEmojiUpdateEventToJson(
  RealmEmojiUpdateEvent instance,
) => <String, dynamic>{
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
  Map<String, dynamic> json,
) => UserSettingsUpdateEvent(
  id: (json['id'] as num).toInt(),
  property: $enumDecodeNullable(
    _$UserSettingNameEnumMap,
    json['property'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  value: UserSettingsUpdateEvent._readValue(json, 'value'),
);

Map<String, dynamic> _$UserSettingsUpdateEventToJson(
  UserSettingsUpdateEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'op': instance.op,
  'property': instance.property,
  'value': instance.value,
};

const _$UserSettingNameEnumMap = {
  UserSettingName.twentyFourHourTime: 'twenty_four_hour_time',
  UserSettingName.displayEmojiReactionUsers: 'display_emoji_reaction_users',
  UserSettingName.emojiset: 'emojiset',
  UserSettingName.presenceEnabled: 'presence_enabled',
};

CustomProfileFieldsEvent _$CustomProfileFieldsEventFromJson(
  Map<String, dynamic> json,
) => CustomProfileFieldsEvent(
  id: (json['id'] as num).toInt(),
  fields: (json['fields'] as List<dynamic>)
      .map((e) => CustomProfileField.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CustomProfileFieldsEventToJson(
  CustomProfileFieldsEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'fields': instance.fields,
};

UserGroupAddEvent _$UserGroupAddEventFromJson(Map<String, dynamic> json) =>
    UserGroupAddEvent(
      id: (json['id'] as num).toInt(),
      group: UserGroup.fromJson(json['group'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserGroupAddEventToJson(UserGroupAddEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'op': instance.op,
      'group': instance.group,
    };

UserGroupUpdateEvent _$UserGroupUpdateEventFromJson(
  Map<String, dynamic> json,
) => UserGroupUpdateEvent(
  id: (json['id'] as num).toInt(),
  groupId: (json['group_id'] as num).toInt(),
  data: UserGroupUpdateData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserGroupUpdateEventToJson(
  UserGroupUpdateEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'op': instance.op,
  'group_id': instance.groupId,
  'data': instance.data,
};

UserGroupUpdateData _$UserGroupUpdateDataFromJson(Map<String, dynamic> json) =>
    UserGroupUpdateData(
      name: json['name'] as String?,
      description: json['description'] as String?,
      deactivated: json['deactivated'] as bool?,
    );

Map<String, dynamic> _$UserGroupUpdateDataToJson(
  UserGroupUpdateData instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'deactivated': instance.deactivated,
};

UserGroupAddMembersEvent _$UserGroupAddMembersEventFromJson(
  Map<String, dynamic> json,
) => UserGroupAddMembersEvent(
  id: (json['id'] as num).toInt(),
  groupId: (json['group_id'] as num).toInt(),
  userIds: (json['user_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$UserGroupAddMembersEventToJson(
  UserGroupAddMembersEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'op': instance.op,
  'group_id': instance.groupId,
  'user_ids': instance.userIds,
};

UserGroupRemoveMembersEvent _$UserGroupRemoveMembersEventFromJson(
  Map<String, dynamic> json,
) => UserGroupRemoveMembersEvent(
  id: (json['id'] as num).toInt(),
  groupId: (json['group_id'] as num).toInt(),
  userIds: (json['user_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$UserGroupRemoveMembersEventToJson(
  UserGroupRemoveMembersEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'op': instance.op,
  'group_id': instance.groupId,
  'user_ids': instance.userIds,
};

UserGroupAddSubgroupsEvent _$UserGroupAddSubgroupsEventFromJson(
  Map<String, dynamic> json,
) => UserGroupAddSubgroupsEvent(
  id: (json['id'] as num).toInt(),
  groupId: (json['group_id'] as num).toInt(),
  directSubgroupIds: (json['direct_subgroup_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$UserGroupAddSubgroupsEventToJson(
  UserGroupAddSubgroupsEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'op': instance.op,
  'group_id': instance.groupId,
  'direct_subgroup_ids': instance.directSubgroupIds,
};

UserGroupRemoveSubgroupsEvent _$UserGroupRemoveSubgroupsEventFromJson(
  Map<String, dynamic> json,
) => UserGroupRemoveSubgroupsEvent(
  id: (json['id'] as num).toInt(),
  groupId: (json['group_id'] as num).toInt(),
  directSubgroupIds: (json['direct_subgroup_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$UserGroupRemoveSubgroupsEventToJson(
  UserGroupRemoveSubgroupsEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'op': instance.op,
  'group_id': instance.groupId,
  'direct_subgroup_ids': instance.directSubgroupIds,
};

UserGroupRemoveEvent _$UserGroupRemoveEventFromJson(
  Map<String, dynamic> json,
) => UserGroupRemoveEvent(
  id: (json['id'] as num).toInt(),
  groupId: (json['group_id'] as num).toInt(),
);

Map<String, dynamic> _$UserGroupRemoveEventToJson(
  UserGroupRemoveEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'op': instance.op,
  'group_id': instance.groupId,
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
  Map<String, dynamic> json,
) => RealmUserUpdateCustomProfileField(
  id: (json['id'] as num).toInt(),
  value: json['value'] as String?,
  renderedValue: json['rendered_value'] as String?,
);

Map<String, dynamic> _$RealmUserUpdateCustomProfileFieldToJson(
  RealmUserUpdateCustomProfileField instance,
) => <String, dynamic>{
  'id': instance.id,
  'value': instance.value,
  'rendered_value': instance.renderedValue,
};

RealmUserUpdateEvent _$RealmUserUpdateEventFromJson(
  Map<String, dynamic> json,
) => RealmUserUpdateEvent(
  id: (json['id'] as num).toInt(),
  userId: (RealmUserUpdateEvent._readFromPerson(json, 'user_id') as num)
      .toInt(),
  fullName: RealmUserUpdateEvent._readFromPerson(json, 'full_name') as String?,
  avatarUrl:
      RealmUserUpdateEvent._readFromPerson(json, 'avatar_url') as String?,
  avatarVersion:
      (RealmUserUpdateEvent._readFromPerson(json, 'avatar_version') as num?)
          ?.toInt(),
  timezone: RealmUserUpdateEvent._readFromPerson(json, 'timezone') as String?,
  botOwnerId:
      (RealmUserUpdateEvent._readFromPerson(json, 'bot_owner_id') as num?)
          ?.toInt(),
  role: $enumDecodeNullable(
    _$UserRoleEnumMap,
    RealmUserUpdateEvent._readFromPerson(json, 'role'),
    unknownValue: UserRole.unknown,
  ),
  deliveryEmail:
      _$JsonConverterFromJson<JsonNullable<String>, JsonNullable<String>>(
        RealmUserUpdateEvent._readNullableStringFromPerson(
          json,
          'delivery_email',
        ),
        const NullableStringJsonConverter().fromJson,
      ),
  customProfileField:
      RealmUserUpdateEvent._readFromPerson(json, 'custom_profile_field') == null
      ? null
      : RealmUserUpdateCustomProfileField.fromJson(
          RealmUserUpdateEvent._readFromPerson(json, 'custom_profile_field')
              as Map<String, dynamic>,
        ),
  newEmail: RealmUserUpdateEvent._readFromPerson(json, 'new_email') as String?,
  isActive: RealmUserUpdateEvent._readFromPerson(json, 'is_active') as bool?,
);

Map<String, dynamic> _$RealmUserUpdateEventToJson(
  RealmUserUpdateEvent instance,
) => <String, dynamic>{
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
  'delivery_email':
      _$JsonConverterToJson<JsonNullable<String>, JsonNullable<String>>(
        instance.deliveryEmail,
        const NullableStringJsonConverter().toJson,
      ),
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
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

SavedSnippetsAddEvent _$SavedSnippetsAddEventFromJson(
  Map<String, dynamic> json,
) => SavedSnippetsAddEvent(
  id: (json['id'] as num).toInt(),
  savedSnippet: SavedSnippet.fromJson(
    json['saved_snippet'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$SavedSnippetsAddEventToJson(
  SavedSnippetsAddEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'saved_snippet': instance.savedSnippet,
};

SavedSnippetsUpdateEvent _$SavedSnippetsUpdateEventFromJson(
  Map<String, dynamic> json,
) => SavedSnippetsUpdateEvent(
  id: (json['id'] as num).toInt(),
  savedSnippet: SavedSnippet.fromJson(
    json['saved_snippet'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$SavedSnippetsUpdateEventToJson(
  SavedSnippetsUpdateEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'saved_snippet': instance.savedSnippet,
};

SavedSnippetsRemoveEvent _$SavedSnippetsRemoveEventFromJson(
  Map<String, dynamic> json,
) => SavedSnippetsRemoveEvent(
  id: (json['id'] as num).toInt(),
  savedSnippetId: (json['saved_snippet_id'] as num).toInt(),
);

Map<String, dynamic> _$SavedSnippetsRemoveEventToJson(
  SavedSnippetsRemoveEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'saved_snippet_id': instance.savedSnippetId,
};

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
        _$ChannelPropertyNameEnumMap,
        json['property'],
        unknownValue: JsonKey.nullForUndefinedEnumValue,
      ),
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
  ChannelPropertyName.isArchived: 'is_archived',
  ChannelPropertyName.description: 'description',
  ChannelPropertyName.firstMessageId: 'first_message_id',
  ChannelPropertyName.inviteOnly: 'invite_only',
  ChannelPropertyName.messageRetentionDays: 'message_retention_days',
  ChannelPropertyName.channelPostPolicy: 'stream_post_policy',
  ChannelPropertyName.folderId: 'folder_id',
  ChannelPropertyName.canAddSubscribersGroup: 'can_add_subscribers_group',
  ChannelPropertyName.canDeleteAnyMessageGroup: 'can_delete_any_message_group',
  ChannelPropertyName.canDeleteOwnMessageGroup: 'can_delete_own_message_group',
  ChannelPropertyName.canSendMessageGroup: 'can_send_message_group',
  ChannelPropertyName.canSubscribeGroup: 'can_subscribe_group',
  ChannelPropertyName.isRecentlyActive: 'is_recently_active',
  ChannelPropertyName.streamWeeklyTraffic: 'stream_weekly_traffic',
};

SubscriptionAddEvent _$SubscriptionAddEventFromJson(
  Map<String, dynamic> json,
) => SubscriptionAddEvent(
  id: (json['id'] as num).toInt(),
  subscriptions: (json['subscriptions'] as List<dynamic>)
      .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SubscriptionAddEventToJson(
  SubscriptionAddEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'op': instance.op,
  'subscriptions': instance.subscriptions,
};

SubscriptionRemoveEvent _$SubscriptionRemoveEventFromJson(
  Map<String, dynamic> json,
) => SubscriptionRemoveEvent(
  id: (json['id'] as num).toInt(),
  streamIds:
      (SubscriptionRemoveEvent._readStreamIds(json, 'stream_ids')
              as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
);

Map<String, dynamic> _$SubscriptionRemoveEventToJson(
  SubscriptionRemoveEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'op': instance.op,
  'stream_ids': instance.streamIds,
};

SubscriptionUpdateEvent _$SubscriptionUpdateEventFromJson(
  Map<String, dynamic> json,
) => SubscriptionUpdateEvent(
  id: (json['id'] as num).toInt(),
  streamId: (json['stream_id'] as num).toInt(),
  property: $enumDecode(
    _$SubscriptionPropertyEnumMap,
    json['property'],
    unknownValue: SubscriptionProperty.unknown,
  ),
  value: SubscriptionUpdateEvent._readValue(json, 'value'),
);

Map<String, dynamic> _$SubscriptionUpdateEventToJson(
  SubscriptionUpdateEvent instance,
) => <String, dynamic>{
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
  SubscriptionProperty.pinToTop: 'pin_to_top',
  SubscriptionProperty.desktopNotifications: 'desktop_notifications',
  SubscriptionProperty.audibleNotifications: 'audible_notifications',
  SubscriptionProperty.pushNotifications: 'push_notifications',
  SubscriptionProperty.emailNotifications: 'email_notifications',
  SubscriptionProperty.wildcardMentionsNotify: 'wildcard_mentions_notify',
  SubscriptionProperty.unknown: 'unknown',
};

SubscriptionPeerAddEvent _$SubscriptionPeerAddEventFromJson(
  Map<String, dynamic> json,
) => SubscriptionPeerAddEvent(
  id: (json['id'] as num).toInt(),
  streamIds: (json['stream_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  userIds: (json['user_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$SubscriptionPeerAddEventToJson(
  SubscriptionPeerAddEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'op': instance.op,
  'stream_ids': instance.streamIds,
  'user_ids': instance.userIds,
};

SubscriptionPeerRemoveEvent _$SubscriptionPeerRemoveEventFromJson(
  Map<String, dynamic> json,
) => SubscriptionPeerRemoveEvent(
  id: (json['id'] as num).toInt(),
  streamIds: (json['stream_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  userIds: (json['user_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$SubscriptionPeerRemoveEventToJson(
  SubscriptionPeerRemoveEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'op': instance.op,
  'stream_ids': instance.streamIds,
  'user_ids': instance.userIds,
};

ChannelFolderAddEvent _$ChannelFolderAddEventFromJson(
  Map<String, dynamic> json,
) => ChannelFolderAddEvent(
  id: (json['id'] as num).toInt(),
  channelFolder: ChannelFolder.fromJson(
    json['channel_folder'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ChannelFolderAddEventToJson(
  ChannelFolderAddEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'op': instance.op,
  'channel_folder': instance.channelFolder,
};

ChannelFolderUpdateEvent _$ChannelFolderUpdateEventFromJson(
  Map<String, dynamic> json,
) => ChannelFolderUpdateEvent(
  id: (json['id'] as num).toInt(),
  channelFolderId: (json['channel_folder_id'] as num).toInt(),
  data: ChannelFolderChange.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ChannelFolderUpdateEventToJson(
  ChannelFolderUpdateEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'op': instance.op,
  'channel_folder_id': instance.channelFolderId,
  'data': instance.data,
};

ChannelFolderChange _$ChannelFolderChangeFromJson(Map<String, dynamic> json) =>
    ChannelFolderChange(
      name: json['name'] as String?,
      description: json['description'] as String?,
      renderedDescription: json['rendered_description'] as String?,
      isArchived: json['is_archived'] as bool?,
    );

Map<String, dynamic> _$ChannelFolderChangeToJson(
  ChannelFolderChange instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'rendered_description': instance.renderedDescription,
  'is_archived': instance.isArchived,
};

ChannelFolderReorderEvent _$ChannelFolderReorderEventFromJson(
  Map<String, dynamic> json,
) => ChannelFolderReorderEvent(
  id: (json['id'] as num).toInt(),
  order: (json['order'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$ChannelFolderReorderEventToJson(
  ChannelFolderReorderEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'op': instance.op,
  'order': instance.order,
};

UserStatusEvent _$UserStatusEventFromJson(Map<String, dynamic> json) =>
    UserStatusEvent(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      change: UserStatusChange.fromJson(
        UserStatusEvent._readChange(json, 'change') as Map<String, dynamic>,
      ),
    );

UserTopicEvent _$UserTopicEventFromJson(Map<String, dynamic> json) =>
    UserTopicEvent(
      id: (json['id'] as num).toInt(),
      streamId: (json['stream_id'] as num).toInt(),
      topicName: TopicName.fromJson(json['topic_name'] as String),
      lastUpdated: (json['last_updated'] as num).toInt(),
      visibilityPolicy: $enumDecode(
        _$UserTopicVisibilityPolicyEnumMap,
        json['visibility_policy'],
      ),
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

MutedUsersEvent _$MutedUsersEventFromJson(Map<String, dynamic> json) =>
    MutedUsersEvent(
      id: (json['id'] as num).toInt(),
      mutedUsers: (json['muted_users'] as List<dynamic>)
          .map((e) => MutedUserItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MutedUsersEventToJson(MutedUsersEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'muted_users': instance.mutedUsers,
    };

MessageEvent _$MessageEventFromJson(Map<String, dynamic> json) => MessageEvent(
  id: (json['id'] as num).toInt(),
  message: Message.fromJson(
    MessageEvent._readMessageValue(json, 'message') as Map<String, dynamic>,
  ),
  localMessageId: json['local_message_id'] as String?,
);

Map<String, dynamic> _$MessageEventToJson(MessageEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'local_message_id': instance.localMessageId,
    };

UpdateMessageEvent _$UpdateMessageEventFromJson(Map<String, dynamic> json) =>
    UpdateMessageEvent(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      renderingOnly: json['rendering_only'] as bool,
      messageId: (json['message_id'] as num).toInt(),
      messageIds: (json['message_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      flags: (json['flags'] as List<dynamic>)
          .map((e) => $enumDecode(_$MessageFlagEnumMap, e))
          .toList(),
      editTimestamp: (json['edit_timestamp'] as num).toInt(),
      moveData: UpdateMessageMoveData.tryParseFromJson(
        UpdateMessageEvent._readMoveData(json, 'move_data')
            as Map<String, Object?>,
      ),
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

DeleteMessageEvent _$DeleteMessageEventFromJson(Map<String, dynamic> json) =>
    DeleteMessageEvent(
      id: (json['id'] as num).toInt(),
      messageIds: (json['message_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      messageType: const MessageTypeConverter().fromJson(
        json['message_type'] as String,
      ),
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
  Map<String, dynamic> json,
) => UpdateMessageFlagsAddEvent(
  id: (json['id'] as num).toInt(),
  flag: $enumDecode(
    _$MessageFlagEnumMap,
    json['flag'],
    unknownValue: MessageFlag.unknown,
  ),
  messages: (json['messages'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  all: json['all'] as bool,
);

Map<String, dynamic> _$UpdateMessageFlagsAddEventToJson(
  UpdateMessageFlagsAddEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'flag': instance.flag,
  'messages': instance.messages,
  'op': instance.op,
  'all': instance.all,
};

UpdateMessageFlagsRemoveEvent _$UpdateMessageFlagsRemoveEventFromJson(
  Map<String, dynamic> json,
) => UpdateMessageFlagsRemoveEvent(
  id: (json['id'] as num).toInt(),
  flag: $enumDecode(
    _$MessageFlagEnumMap,
    json['flag'],
    unknownValue: MessageFlag.unknown,
  ),
  messages: (json['messages'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  messageDetails: (json['message_details'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(
      int.parse(k),
      UpdateMessageFlagsMessageDetail.fromJson(e as Map<String, dynamic>),
    ),
  ),
);

Map<String, dynamic> _$UpdateMessageFlagsRemoveEventToJson(
  UpdateMessageFlagsRemoveEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'flag': instance.flag,
  'messages': instance.messages,
  'op': instance.op,
  'message_details': instance.messageDetails?.map(
    (k, e) => MapEntry(k.toString(), e),
  ),
};

UpdateMessageFlagsMessageDetail _$UpdateMessageFlagsMessageDetailFromJson(
  Map<String, dynamic> json,
) => UpdateMessageFlagsMessageDetail(
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
  UpdateMessageFlagsMessageDetail instance,
) => <String, dynamic>{
  'type': const MessageTypeConverter().toJson(instance.type),
  'mentioned': instance.mentioned,
  'user_ids': instance.userIds,
  'stream_id': instance.streamId,
  'topic': instance.topic,
};

SubmessageEvent _$SubmessageEventFromJson(Map<String, dynamic> json) =>
    SubmessageEvent(
      id: (json['id'] as num).toInt(),
      msgType: $enumDecode(
        _$SubmessageTypeEnumMap,
        json['msg_type'],
        unknownValue: SubmessageType.unknown,
      ),
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
  messageType: const MessageTypeConverter().fromJson(
    json['message_type'] as String,
  ),
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

const _$TypingOpEnumMap = {TypingOp.start: 'start', TypingOp.stop: 'stop'};

PresenceEvent _$PresenceEventFromJson(Map<String, dynamic> json) =>
    PresenceEvent(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      serverTimestamp: (json['server_timestamp'] as num).toInt(),
      presence: (json['presence'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, PerClientPresence.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$PresenceEventToJson(PresenceEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'user_id': instance.userId,
      'server_timestamp': instance.serverTimestamp,
      'presence': instance.presence,
    };

PerClientPresence _$PerClientPresenceFromJson(Map<String, dynamic> json) =>
    PerClientPresence(
      client: json['client'] as String,
      status: $enumDecode(_$PresenceStatusEnumMap, json['status']),
      timestamp: (json['timestamp'] as num).toInt(),
      pushable: json['pushable'] as bool,
    );

Map<String, dynamic> _$PerClientPresenceToJson(PerClientPresence instance) =>
    <String, dynamic>{
      'client': instance.client,
      'status': instance.status,
      'timestamp': instance.timestamp,
      'pushable': instance.pushable,
    };

const _$PresenceStatusEnumMap = {
  PresenceStatus.active: 'active',
  PresenceStatus.idle: 'idle',
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
    HeartbeatEvent(id: (json['id'] as num).toInt());

Map<String, dynamic> _$HeartbeatEventToJson(HeartbeatEvent instance) =>
    <String, dynamic>{'id': instance.id, 'type': instance.type};

const _$MessageTypeEnumMap = {
  MessageType.stream: 'stream',
  MessageType.direct: 'direct',
};
