// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupSettingValueNameless _$GroupSettingValueNamelessFromJson(
  Map<String, dynamic> json,
) => GroupSettingValueNameless(
  directMembers: (json['direct_members'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  directSubgroups: (json['direct_subgroups'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$GroupSettingValueNamelessToJson(
  GroupSettingValueNameless instance,
) => <String, dynamic>{
  'direct_members': instance.directMembers,
  'direct_subgroups': instance.directSubgroups,
};

CustomProfileField _$CustomProfileFieldFromJson(Map<String, dynamic> json) =>
    CustomProfileField(
      id: (json['id'] as num).toInt(),
      type: $enumDecode(
        _$CustomProfileFieldTypeEnumMap,
        json['type'],
        unknownValue: CustomProfileFieldType.unknown,
      ),
      order: (json['order'] as num).toInt(),
      name: json['name'] as String,
      hint: json['hint'] as String,
      fieldData: json['field_data'] as String,
      displayInProfileSummary: json['display_in_profile_summary'] as bool?,
    );

Map<String, dynamic> _$CustomProfileFieldToJson(CustomProfileField instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'order': instance.order,
      'name': instance.name,
      'hint': instance.hint,
      'field_data': instance.fieldData,
      'display_in_profile_summary': instance.displayInProfileSummary,
    };

const _$CustomProfileFieldTypeEnumMap = {
  CustomProfileFieldType.shortText: 1,
  CustomProfileFieldType.longText: 2,
  CustomProfileFieldType.choice: 3,
  CustomProfileFieldType.date: 4,
  CustomProfileFieldType.link: 5,
  CustomProfileFieldType.user: 6,
  CustomProfileFieldType.externalAccount: 7,
  CustomProfileFieldType.pronouns: 8,
  CustomProfileFieldType.unknown: null,
};

CustomProfileFieldChoiceDataItem _$CustomProfileFieldChoiceDataItemFromJson(
  Map<String, dynamic> json,
) => CustomProfileFieldChoiceDataItem(text: json['text'] as String);

Map<String, dynamic> _$CustomProfileFieldChoiceDataItemToJson(
  CustomProfileFieldChoiceDataItem instance,
) => <String, dynamic>{'text': instance.text};

CustomProfileFieldExternalAccountData
_$CustomProfileFieldExternalAccountDataFromJson(Map<String, dynamic> json) =>
    CustomProfileFieldExternalAccountData(
      subtype: json['subtype'] as String,
      urlPattern: json['url_pattern'] as String?,
    );

Map<String, dynamic> _$CustomProfileFieldExternalAccountDataToJson(
  CustomProfileFieldExternalAccountData instance,
) => <String, dynamic>{
  'subtype': instance.subtype,
  'url_pattern': instance.urlPattern,
};

MutedUserItem _$MutedUserItemFromJson(Map<String, dynamic> json) =>
    MutedUserItem(id: (json['id'] as num).toInt());

Map<String, dynamic> _$MutedUserItemToJson(MutedUserItem instance) =>
    <String, dynamic>{'id': instance.id};

RealmEmojiItem _$RealmEmojiItemFromJson(Map<String, dynamic> json) =>
    RealmEmojiItem(
      emojiCode: json['id'] as String,
      name: json['name'] as String,
      sourceUrl: json['source_url'] as String,
      stillUrl: json['still_url'] as String?,
      deactivated: json['deactivated'] as bool,
      authorId: (json['author_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RealmEmojiItemToJson(RealmEmojiItem instance) =>
    <String, dynamic>{
      'id': instance.emojiCode,
      'name': instance.name,
      'source_url': instance.sourceUrl,
      'still_url': instance.stillUrl,
      'deactivated': instance.deactivated,
      'author_id': instance.authorId,
    };

UserGroup _$UserGroupFromJson(Map<String, dynamic> json) => UserGroup(
  id: (json['id'] as num).toInt(),
  members: (json['members'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toSet(),
  directSubgroupIds: (json['direct_subgroup_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toSet(),
  name: json['name'] as String,
  description: json['description'] as String,
  isSystemGroup: json['is_system_group'] as bool,
  deactivated: json['deactivated'] as bool? ?? false,
);

Map<String, dynamic> _$UserGroupToJson(UserGroup instance) => <String, dynamic>{
  'id': instance.id,
  'members': instance.members.toList(),
  'direct_subgroup_ids': instance.directSubgroupIds.toList(),
  'name': instance.name,
  'description': instance.description,
  'is_system_group': instance.isSystemGroup,
  'deactivated': instance.deactivated,
};

User _$UserFromJson(Map<String, dynamic> json) => User(
  userId: (json['user_id'] as num).toInt(),
  deliveryEmail: json['delivery_email'] as String?,
  email: json['email'] as String,
  fullName: json['full_name'] as String,
  dateJoined: json['date_joined'] as String,
  isActive: json['is_active'] as bool,
  isBot: json['is_bot'] as bool,
  botType: (json['bot_type'] as num?)?.toInt(),
  botOwnerId: (json['bot_owner_id'] as num?)?.toInt(),
  role: $enumDecode(
    _$UserRoleEnumMap,
    json['role'],
    unknownValue: UserRole.unknown,
  ),
  timezone: json['timezone'] as String,
  avatarUrl: json['avatar_url'] as String?,
  avatarVersion: (json['avatar_version'] as num).toInt(),
  profileData:
      (User._readProfileData(json, 'profile_data') as Map<String, dynamic>?)
          ?.map(
            (k, e) => MapEntry(
              int.parse(k),
              ProfileFieldUserData.fromJson(e as Map<String, dynamic>),
            ),
          ),
  isSystemBot: json['is_system_bot'] as bool? ?? false,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'user_id': instance.userId,
  'delivery_email': instance.deliveryEmail,
  'email': instance.email,
  'full_name': instance.fullName,
  'date_joined': instance.dateJoined,
  'is_active': instance.isActive,
  'is_bot': instance.isBot,
  'bot_type': instance.botType,
  'bot_owner_id': instance.botOwnerId,
  'role': instance.role,
  'timezone': instance.timezone,
  'avatar_url': instance.avatarUrl,
  'avatar_version': instance.avatarVersion,
  'profile_data': instance.profileData?.map(
    (k, e) => MapEntry(k.toString(), e),
  ),
  'is_system_bot': instance.isSystemBot,
};

const _$UserRoleEnumMap = {
  UserRole.owner: 100,
  UserRole.administrator: 200,
  UserRole.moderator: 300,
  UserRole.member: 400,
  UserRole.guest: 600,
  UserRole.unknown: null,
};

ProfileFieldUserData _$ProfileFieldUserDataFromJson(
  Map<String, dynamic> json,
) => ProfileFieldUserData(
  value: json['value'] as String,
  renderedValue: json['rendered_value'] as String?,
);

Map<String, dynamic> _$ProfileFieldUserDataToJson(
  ProfileFieldUserData instance,
) => <String, dynamic>{
  'value': instance.value,
  'rendered_value': instance.renderedValue,
};

PerUserPresence _$PerUserPresenceFromJson(Map<String, dynamic> json) =>
    PerUserPresence(
      activeTimestamp: (json['active_timestamp'] as num).toInt(),
      idleTimestamp: (json['idle_timestamp'] as num).toInt(),
    );

Map<String, dynamic> _$PerUserPresenceToJson(PerUserPresence instance) =>
    <String, dynamic>{
      'active_timestamp': instance.activeTimestamp,
      'idle_timestamp': instance.idleTimestamp,
    };

SavedSnippet _$SavedSnippetFromJson(Map<String, dynamic> json) => SavedSnippet(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  content: json['content'] as String,
  dateCreated: (json['date_created'] as num).toInt(),
);

Map<String, dynamic> _$SavedSnippetToJson(SavedSnippet instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'date_created': instance.dateCreated,
    };

ZulipStream _$ZulipStreamFromJson(Map<String, dynamic> json) => ZulipStream(
  streamId: (json['stream_id'] as num).toInt(),
  name: json['name'] as String,
  isArchived: json['is_archived'] as bool? ?? false,
  description: json['description'] as String,
  renderedDescription: json['rendered_description'] as String,
  dateCreated: (json['date_created'] as num).toInt(),
  firstMessageId: (json['first_message_id'] as num?)?.toInt(),
  inviteOnly: json['invite_only'] as bool,
  isWebPublic: json['is_web_public'] as bool,
  historyPublicToSubscribers: json['history_public_to_subscribers'] as bool,
  messageRetentionDays: (json['message_retention_days'] as num?)?.toInt(),
  channelPostPolicy: $enumDecodeNullable(
    _$ChannelPostPolicyEnumMap,
    json['stream_post_policy'],
  ),
  folderId: (json['folder_id'] as num?)?.toInt(),
  canAddSubscribersGroup: json['can_add_subscribers_group'] == null
      ? null
      : GroupSettingValue.fromJson(json['can_add_subscribers_group']),
  canDeleteAnyMessageGroup: json['can_delete_any_message_group'] == null
      ? null
      : GroupSettingValue.fromJson(json['can_delete_any_message_group']),
  canDeleteOwnMessageGroup: json['can_delete_own_message_group'] == null
      ? null
      : GroupSettingValue.fromJson(json['can_delete_own_message_group']),
  canSendMessageGroup: json['can_send_message_group'] == null
      ? null
      : GroupSettingValue.fromJson(json['can_send_message_group']),
  canSubscribeGroup: json['can_subscribe_group'] == null
      ? null
      : GroupSettingValue.fromJson(json['can_subscribe_group']),
  isRecentlyActive: json['is_recently_active'] as bool?,
  streamWeeklyTraffic: (json['stream_weekly_traffic'] as num?)?.toInt(),
);

Map<String, dynamic> _$ZulipStreamToJson(ZulipStream instance) =>
    <String, dynamic>{
      'stream_id': instance.streamId,
      'name': instance.name,
      'is_archived': instance.isArchived,
      'description': instance.description,
      'rendered_description': instance.renderedDescription,
      'date_created': instance.dateCreated,
      'first_message_id': instance.firstMessageId,
      'folder_id': instance.folderId,
      'invite_only': instance.inviteOnly,
      'is_web_public': instance.isWebPublic,
      'history_public_to_subscribers': instance.historyPublicToSubscribers,
      'message_retention_days': instance.messageRetentionDays,
      'stream_post_policy': instance.channelPostPolicy,
      'can_add_subscribers_group': instance.canAddSubscribersGroup,
      'can_delete_any_message_group': instance.canDeleteAnyMessageGroup,
      'can_delete_own_message_group': instance.canDeleteOwnMessageGroup,
      'can_send_message_group': instance.canSendMessageGroup,
      'can_subscribe_group': instance.canSubscribeGroup,
      'is_recently_active': instance.isRecentlyActive,
      'stream_weekly_traffic': instance.streamWeeklyTraffic,
    };

const _$ChannelPostPolicyEnumMap = {
  ChannelPostPolicy.any: 1,
  ChannelPostPolicy.administrators: 2,
  ChannelPostPolicy.fullMembers: 3,
  ChannelPostPolicy.moderators: 4,
  ChannelPostPolicy.unknown: null,
};

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) => Subscription(
  streamId: (json['stream_id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String,
  isArchived: json['is_archived'] as bool? ?? false,
  renderedDescription: json['rendered_description'] as String,
  dateCreated: (json['date_created'] as num).toInt(),
  firstMessageId: (json['first_message_id'] as num?)?.toInt(),
  inviteOnly: json['invite_only'] as bool,
  isWebPublic: json['is_web_public'] as bool,
  historyPublicToSubscribers: json['history_public_to_subscribers'] as bool,
  messageRetentionDays: (json['message_retention_days'] as num?)?.toInt(),
  channelPostPolicy: $enumDecodeNullable(
    _$ChannelPostPolicyEnumMap,
    json['stream_post_policy'],
  ),
  folderId: (json['folder_id'] as num?)?.toInt(),
  canAddSubscribersGroup: json['can_add_subscribers_group'] == null
      ? null
      : GroupSettingValue.fromJson(json['can_add_subscribers_group']),
  canDeleteAnyMessageGroup: json['can_delete_any_message_group'] == null
      ? null
      : GroupSettingValue.fromJson(json['can_delete_any_message_group']),
  canDeleteOwnMessageGroup: json['can_delete_own_message_group'] == null
      ? null
      : GroupSettingValue.fromJson(json['can_delete_own_message_group']),
  canSendMessageGroup: json['can_send_message_group'] == null
      ? null
      : GroupSettingValue.fromJson(json['can_send_message_group']),
  canSubscribeGroup: json['can_subscribe_group'] == null
      ? null
      : GroupSettingValue.fromJson(json['can_subscribe_group']),
  isRecentlyActive: json['is_recently_active'] as bool?,
  streamWeeklyTraffic: (json['stream_weekly_traffic'] as num?)?.toInt(),
  desktopNotifications: json['desktop_notifications'] as bool?,
  emailNotifications: json['email_notifications'] as bool?,
  wildcardMentionsNotify: json['wildcard_mentions_notify'] as bool?,
  pushNotifications: json['push_notifications'] as bool?,
  audibleNotifications: json['audible_notifications'] as bool?,
  pinToTop: json['pin_to_top'] as bool,
  isMuted: json['is_muted'] as bool,
  color: (Subscription._readColor(json, 'color') as num).toInt(),
);

Map<String, dynamic> _$SubscriptionToJson(Subscription instance) =>
    <String, dynamic>{
      'stream_id': instance.streamId,
      'name': instance.name,
      'is_archived': instance.isArchived,
      'description': instance.description,
      'rendered_description': instance.renderedDescription,
      'date_created': instance.dateCreated,
      'first_message_id': instance.firstMessageId,
      'folder_id': instance.folderId,
      'invite_only': instance.inviteOnly,
      'is_web_public': instance.isWebPublic,
      'history_public_to_subscribers': instance.historyPublicToSubscribers,
      'message_retention_days': instance.messageRetentionDays,
      'stream_post_policy': instance.channelPostPolicy,
      'can_add_subscribers_group': instance.canAddSubscribersGroup,
      'can_delete_any_message_group': instance.canDeleteAnyMessageGroup,
      'can_delete_own_message_group': instance.canDeleteOwnMessageGroup,
      'can_send_message_group': instance.canSendMessageGroup,
      'can_subscribe_group': instance.canSubscribeGroup,
      'is_recently_active': instance.isRecentlyActive,
      'stream_weekly_traffic': instance.streamWeeklyTraffic,
      'desktop_notifications': instance.desktopNotifications,
      'email_notifications': instance.emailNotifications,
      'wildcard_mentions_notify': instance.wildcardMentionsNotify,
      'push_notifications': instance.pushNotifications,
      'audible_notifications': instance.audibleNotifications,
      'pin_to_top': instance.pinToTop,
      'is_muted': instance.isMuted,
      'color': instance.color,
    };

ChannelFolder _$ChannelFolderFromJson(Map<String, dynamic> json) =>
    ChannelFolder(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      order: (json['order'] as num?)?.toInt(),
      dateCreated: (json['date_created'] as num?)?.toInt(),
      creatorId: (json['creator_id'] as num?)?.toInt(),
      description: json['description'] as String,
      renderedDescription: json['rendered_description'] as String,
      isArchived: json['is_archived'] as bool,
    );

Map<String, dynamic> _$ChannelFolderToJson(ChannelFolder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'order': instance.order,
      'date_created': instance.dateCreated,
      'creator_id': instance.creatorId,
      'description': instance.description,
      'rendered_description': instance.renderedDescription,
      'is_archived': instance.isArchived,
    };

StreamConversation _$StreamConversationFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['display_recipient'],
    disallowNullValues: const ['display_recipient'],
  );
  return StreamConversation(
    (json['stream_id'] as num).toInt(),
    TopicName.fromJson(json['subject'] as String),
    displayRecipient: json['display_recipient'] as String?,
  );
}

StreamMessage _$StreamMessageFromJson(Map<String, dynamic> json) =>
    StreamMessage(
      client: json['client'] as String,
      content: json['content'] as String,
      contentType: json['content_type'] as String,
      editState: Message._messageEditStateFromJson(
        MessageEditState._readFromMessage(json, 'edit_state'),
      ),
      id: (json['id'] as num).toInt(),
      isMeMessage: json['is_me_message'] as bool,
      lastEditTimestamp: (json['last_edit_timestamp'] as num?)?.toInt(),
      reactions: Message._reactionsFromJson(json['reactions']),
      recipientId: (json['recipient_id'] as num).toInt(),
      senderEmail: json['sender_email'] as String,
      senderFullName: json['sender_full_name'] as String,
      senderId: (json['sender_id'] as num).toInt(),
      senderRealmStr: json['sender_realm_str'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      flags: Message._flagsFromJson(json['flags']),
      matchContent: json['match_content'] as String?,
      matchTopic: json['match_subject'] as String?,
      conversation: StreamConversation.fromJson(
        StreamMessage._readConversation(json, 'conversation')
            as Map<String, dynamic>,
      ),
    )..poll = Poll.fromJson(Message._readPoll(json, 'submessages'));

Map<String, dynamic> _$StreamMessageToJson(StreamMessage instance) =>
    <String, dynamic>{
      'sender_id': instance.senderId,
      'timestamp': instance.timestamp,
      'client': instance.client,
      'content': instance.content,
      'content_type': instance.contentType,
      'edit_state': _$MessageEditStateEnumMap[instance.editState]!,
      'id': instance.id,
      'is_me_message': instance.isMeMessage,
      'last_edit_timestamp': instance.lastEditTimestamp,
      'reactions': Message._reactionsToJson(instance.reactions),
      'recipient_id': instance.recipientId,
      'sender_email': instance.senderEmail,
      'sender_full_name': instance.senderFullName,
      'sender_realm_str': instance.senderRealmStr,
      'submessages': Poll.toJson(instance.poll),
      'flags': instance.flags,
      'match_content': instance.matchContent,
      'match_subject': instance.matchTopic,
      'type': instance.type,
      'stream_id': instance.streamId,
      'subject': instance.topic,
      'display_recipient': instance.displayRecipient,
    };

const _$MessageEditStateEnumMap = {
  MessageEditState.none: 'none',
  MessageEditState.edited: 'edited',
  MessageEditState.moved: 'moved',
};

DmMessage _$DmMessageFromJson(Map<String, dynamic> json) => DmMessage(
  client: json['client'] as String,
  content: json['content'] as String,
  contentType: json['content_type'] as String,
  editState: Message._messageEditStateFromJson(
    MessageEditState._readFromMessage(json, 'edit_state'),
  ),
  id: (json['id'] as num).toInt(),
  isMeMessage: json['is_me_message'] as bool,
  lastEditTimestamp: (json['last_edit_timestamp'] as num?)?.toInt(),
  reactions: Message._reactionsFromJson(json['reactions']),
  recipientId: (json['recipient_id'] as num).toInt(),
  senderEmail: json['sender_email'] as String,
  senderFullName: json['sender_full_name'] as String,
  senderId: (json['sender_id'] as num).toInt(),
  senderRealmStr: json['sender_realm_str'] as String,
  timestamp: (json['timestamp'] as num).toInt(),
  flags: Message._flagsFromJson(json['flags']),
  matchContent: json['match_content'] as String?,
  matchTopic: json['match_subject'] as String?,
  conversation: DmMessage._conversationFromJson(
    json['display_recipient'] as List,
  ),
)..poll = Poll.fromJson(Message._readPoll(json, 'submessages'));

Map<String, dynamic> _$DmMessageToJson(DmMessage instance) => <String, dynamic>{
  'sender_id': instance.senderId,
  'timestamp': instance.timestamp,
  'client': instance.client,
  'content': instance.content,
  'content_type': instance.contentType,
  'edit_state': _$MessageEditStateEnumMap[instance.editState]!,
  'id': instance.id,
  'is_me_message': instance.isMeMessage,
  'last_edit_timestamp': instance.lastEditTimestamp,
  'reactions': Message._reactionsToJson(instance.reactions),
  'recipient_id': instance.recipientId,
  'sender_email': instance.senderEmail,
  'sender_full_name': instance.senderFullName,
  'sender_realm_str': instance.senderRealmStr,
  'submessages': Poll.toJson(instance.poll),
  'flags': instance.flags,
  'match_content': instance.matchContent,
  'match_subject': instance.matchTopic,
  'type': instance.type,
  'display_recipient': DmMessage._allRecipientIdsToJson(
    instance.allRecipientIds,
  ),
};

const _$UserSettingNameEnumMap = {
  UserSettingName.twentyFourHourTime: 'twenty_four_hour_time',
  UserSettingName.displayEmojiReactionUsers: 'display_emoji_reaction_users',
  UserSettingName.emojiset: 'emojiset',
  UserSettingName.presenceEnabled: 'presence_enabled',
};

const _$EmojisetEnumMap = {
  Emojiset.google: 'google',
  Emojiset.googleBlob: 'google-blob',
  Emojiset.twitter: 'twitter',
  Emojiset.text: 'text',
  Emojiset.unknown: 'unknown',
};

const _$PresenceStatusEnumMap = {
  PresenceStatus.active: 'active',
  PresenceStatus.idle: 'idle',
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
