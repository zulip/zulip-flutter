// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'initial_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitialSnapshot _$InitialSnapshotFromJson(
  Map<String, dynamic> json,
) => InitialSnapshot(
  queueId: json['queue_id'] as String?,
  lastEventId: (json['last_event_id'] as num).toInt(),
  zulipFeatureLevel: (json['zulip_feature_level'] as num).toInt(),
  zulipVersion: json['zulip_version'] as String,
  zulipMergeBase: json['zulip_merge_base'] as String,
  alertWords: (json['alert_words'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  customProfileFields: (json['custom_profile_fields'] as List<dynamic>)
      .map((e) => CustomProfileField.fromJson(e as Map<String, dynamic>))
      .toList(),
  maxChannelNameLength: (json['max_stream_name_length'] as num).toInt(),
  maxTopicLength: (json['max_topic_length'] as num).toInt(),
  serverPresencePingIntervalSeconds:
      (json['server_presence_ping_interval_seconds'] as num).toInt(),
  serverPresenceOfflineThresholdSeconds:
      (json['server_presence_offline_threshold_seconds'] as num).toInt(),
  serverTypingStartedExpiryPeriodMilliseconds:
      (json['server_typing_started_expiry_period_milliseconds'] as num?)
          ?.toInt() ??
      15000,
  serverTypingStoppedWaitPeriodMilliseconds:
      (json['server_typing_stopped_wait_period_milliseconds'] as num?)
          ?.toInt() ??
      5000,
  serverTypingStartedWaitPeriodMilliseconds:
      (json['server_typing_started_wait_period_milliseconds'] as num?)
          ?.toInt() ??
      10000,
  mutedUsers: (json['muted_users'] as List<dynamic>)
      .map((e) => MutedUserItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  presences: (json['presences'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      int.parse(k),
      PerUserPresence.fromJson(e as Map<String, dynamic>),
    ),
  ),
  realmEmoji: (json['realm_emoji'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, RealmEmojiItem.fromJson(e as Map<String, dynamic>)),
  ),
  realmUserGroups: (json['realm_user_groups'] as List<dynamic>)
      .map((e) => UserGroup.fromJson(e as Map<String, dynamic>))
      .toList(),
  recentPrivateConversations:
      (json['recent_private_conversations'] as List<dynamic>)
          .map((e) => RecentDmConversation.fromJson(e as Map<String, dynamic>))
          .toList(),
  savedSnippets: (json['saved_snippets'] as List<dynamic>?)
      ?.map((e) => SavedSnippet.fromJson(e as Map<String, dynamic>))
      .toList(),
  subscriptions: (json['subscriptions'] as List<dynamic>)
      .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
      .toList(),
  channelFolders: (json['channel_folders'] as List<dynamic>?)
      ?.map((e) => ChannelFolder.fromJson(e as Map<String, dynamic>))
      .toList(),
  unreadMsgs: UnreadMessagesSnapshot.fromJson(
    json['unread_msgs'] as Map<String, dynamic>,
  ),
  streams: (json['streams'] as List<dynamic>)
      .map((e) => ZulipStream.fromJson(e as Map<String, dynamic>))
      .toList(),
  userStatuses: (json['user_status'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      int.parse(k),
      UserStatusChange.fromJson(e as Map<String, dynamic>),
    ),
  ),
  userSettings: UserSettings.fromJson(
    json['user_settings'] as Map<String, dynamic>,
  ),
  userTopics: (json['user_topics'] as List<dynamic>)
      .map((e) => UserTopicItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  realmCanDeleteAnyMessageGroup:
      json['realm_can_delete_any_message_group'] == null
      ? null
      : GroupSettingValue.fromJson(json['realm_can_delete_any_message_group']),
  realmCanDeleteOwnMessageGroup:
      json['realm_can_delete_own_message_group'] == null
      ? null
      : GroupSettingValue.fromJson(json['realm_can_delete_own_message_group']),
  realmDeleteOwnMessagePolicy: $enumDecodeNullable(
    _$RealmDeleteOwnMessagePolicyEnumMap,
    json['realm_delete_own_message_policy'],
  ),
  realmWildcardMentionPolicy: $enumDecode(
    _$RealmWildcardMentionPolicyEnumMap,
    json['realm_wildcard_mention_policy'],
  ),
  realmMandatoryTopics: json['realm_mandatory_topics'] as bool,
  realmName: json['realm_name'] as String,
  realmWaitingPeriodThreshold: (json['realm_waiting_period_threshold'] as num)
      .toInt(),
  realmMessageContentDeleteLimitSeconds:
      (json['realm_message_content_delete_limit_seconds'] as num?)?.toInt(),
  realmAllowMessageEditing: json['realm_allow_message_editing'] as bool,
  realmMessageContentEditLimitSeconds:
      (json['realm_message_content_edit_limit_seconds'] as num?)?.toInt(),
  realmEnableReadReceipts: json['realm_enable_read_receipts'] as bool,
  realmIconUrl: Uri.parse(json['realm_icon_url'] as String),
  realmPresenceDisabled: json['realm_presence_disabled'] as bool,
  realmDefaultExternalAccounts:
      (json['realm_default_external_accounts'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          k,
          RealmDefaultExternalAccount.fromJson(e as Map<String, dynamic>),
        ),
      ),
  maxFileUploadSizeMib: (json['max_file_upload_size_mib'] as num).toInt(),
  serverEmojiDataUrl: Uri.parse(json['server_emoji_data_url'] as String),
  realmEmptyTopicDisplayName: json['realm_empty_topic_display_name'] as String?,
  realmUsers:
      (InitialSnapshot._readUsersIsActiveFallbackTrue(json, 'realm_users')
              as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
  realmNonActiveUsers:
      (InitialSnapshot._readUsersIsActiveFallbackFalse(
                json,
                'realm_non_active_users',
              )
              as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
  crossRealmBots:
      (InitialSnapshot._readUsersIsActiveFallbackTrue(json, 'cross_realm_bots')
              as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$InitialSnapshotToJson(
  InitialSnapshot instance,
) => <String, dynamic>{
  'queue_id': instance.queueId,
  'last_event_id': instance.lastEventId,
  'zulip_feature_level': instance.zulipFeatureLevel,
  'zulip_version': instance.zulipVersion,
  'zulip_merge_base': instance.zulipMergeBase,
  'alert_words': instance.alertWords,
  'custom_profile_fields': instance.customProfileFields,
  'max_stream_name_length': instance.maxChannelNameLength,
  'max_topic_length': instance.maxTopicLength,
  'server_presence_ping_interval_seconds':
      instance.serverPresencePingIntervalSeconds,
  'server_presence_offline_threshold_seconds':
      instance.serverPresenceOfflineThresholdSeconds,
  'server_typing_started_expiry_period_milliseconds':
      instance.serverTypingStartedExpiryPeriodMilliseconds,
  'server_typing_stopped_wait_period_milliseconds':
      instance.serverTypingStoppedWaitPeriodMilliseconds,
  'server_typing_started_wait_period_milliseconds':
      instance.serverTypingStartedWaitPeriodMilliseconds,
  'muted_users': instance.mutedUsers,
  'presences': instance.presences.map((k, e) => MapEntry(k.toString(), e)),
  'realm_emoji': instance.realmEmoji,
  'realm_user_groups': instance.realmUserGroups,
  'recent_private_conversations': instance.recentPrivateConversations,
  'saved_snippets': instance.savedSnippets,
  'subscriptions': instance.subscriptions,
  'channel_folders': instance.channelFolders,
  'unread_msgs': instance.unreadMsgs,
  'streams': instance.streams,
  'user_status': instance.userStatuses.map((k, e) => MapEntry(k.toString(), e)),
  'user_settings': instance.userSettings,
  'user_topics': instance.userTopics,
  'realm_can_delete_any_message_group': instance.realmCanDeleteAnyMessageGroup,
  'realm_can_delete_own_message_group': instance.realmCanDeleteOwnMessageGroup,
  'realm_delete_own_message_policy': instance.realmDeleteOwnMessagePolicy,
  'realm_wildcard_mention_policy': instance.realmWildcardMentionPolicy,
  'realm_mandatory_topics': instance.realmMandatoryTopics,
  'realm_name': instance.realmName,
  'realm_waiting_period_threshold': instance.realmWaitingPeriodThreshold,
  'realm_message_content_delete_limit_seconds':
      instance.realmMessageContentDeleteLimitSeconds,
  'realm_allow_message_editing': instance.realmAllowMessageEditing,
  'realm_message_content_edit_limit_seconds':
      instance.realmMessageContentEditLimitSeconds,
  'realm_enable_read_receipts': instance.realmEnableReadReceipts,
  'realm_icon_url': instance.realmIconUrl.toString(),
  'realm_presence_disabled': instance.realmPresenceDisabled,
  'realm_default_external_accounts': instance.realmDefaultExternalAccounts,
  'max_file_upload_size_mib': instance.maxFileUploadSizeMib,
  'server_emoji_data_url': instance.serverEmojiDataUrl.toString(),
  'realm_empty_topic_display_name': instance.realmEmptyTopicDisplayName,
  'realm_users': instance.realmUsers,
  'realm_non_active_users': instance.realmNonActiveUsers,
  'cross_realm_bots': instance.crossRealmBots,
};

const _$RealmDeleteOwnMessagePolicyEnumMap = {
  RealmDeleteOwnMessagePolicy.members: 1,
  RealmDeleteOwnMessagePolicy.admins: 2,
  RealmDeleteOwnMessagePolicy.fullMembers: 3,
  RealmDeleteOwnMessagePolicy.moderators: 4,
  RealmDeleteOwnMessagePolicy.everyone: 5,
};

const _$RealmWildcardMentionPolicyEnumMap = {
  RealmWildcardMentionPolicy.everyone: 1,
  RealmWildcardMentionPolicy.members: 2,
  RealmWildcardMentionPolicy.fullMembers: 3,
  RealmWildcardMentionPolicy.admins: 5,
  RealmWildcardMentionPolicy.nobody: 6,
  RealmWildcardMentionPolicy.moderators: 7,
};

RealmDefaultExternalAccount _$RealmDefaultExternalAccountFromJson(
  Map<String, dynamic> json,
) => RealmDefaultExternalAccount(
  name: json['name'] as String,
  text: json['text'] as String,
  hint: json['hint'] as String,
  urlPattern: json['url_pattern'] as String,
);

Map<String, dynamic> _$RealmDefaultExternalAccountToJson(
  RealmDefaultExternalAccount instance,
) => <String, dynamic>{
  'name': instance.name,
  'text': instance.text,
  'hint': instance.hint,
  'url_pattern': instance.urlPattern,
};

RecentDmConversation _$RecentDmConversationFromJson(
  Map<String, dynamic> json,
) => RecentDmConversation(
  maxMessageId: (json['max_message_id'] as num).toInt(),
  userIds: (json['user_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$RecentDmConversationToJson(
  RecentDmConversation instance,
) => <String, dynamic>{
  'max_message_id': instance.maxMessageId,
  'user_ids': instance.userIds,
};

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) => UserSettings(
  twentyFourHourTime: TwentyFourHourTimeMode.fromApiValue(
    json['twenty_four_hour_time'] as bool?,
  ),
  displayEmojiReactionUsers: json['display_emoji_reaction_users'] as bool,
  emojiset: $enumDecode(
    _$EmojisetEnumMap,
    json['emojiset'],
    unknownValue: Emojiset.unknown,
  ),
  presenceEnabled: json['presence_enabled'] as bool,
);

const _$UserSettingsFieldMap = <String, String>{
  'twentyFourHourTime': 'twenty_four_hour_time',
  'displayEmojiReactionUsers': 'display_emoji_reaction_users',
  'emojiset': 'emojiset',
  'presenceEnabled': 'presence_enabled',
};

Map<String, dynamic> _$UserSettingsToJson(UserSettings instance) =>
    <String, dynamic>{
      'twenty_four_hour_time': TwentyFourHourTimeMode.staticToJson(
        instance.twentyFourHourTime,
      ),
      'display_emoji_reaction_users': instance.displayEmojiReactionUsers,
      'emojiset': instance.emojiset,
      'presence_enabled': instance.presenceEnabled,
    };

const _$EmojisetEnumMap = {
  Emojiset.google: 'google',
  Emojiset.googleBlob: 'google-blob',
  Emojiset.twitter: 'twitter',
  Emojiset.text: 'text',
  Emojiset.unknown: 'unknown',
};

UserTopicItem _$UserTopicItemFromJson(Map<String, dynamic> json) =>
    UserTopicItem(
      streamId: (json['stream_id'] as num).toInt(),
      topicName: TopicName.fromJson(json['topic_name'] as String),
      lastUpdated: (json['last_updated'] as num).toInt(),
      visibilityPolicy: $enumDecode(
        _$UserTopicVisibilityPolicyEnumMap,
        json['visibility_policy'],
        unknownValue: UserTopicVisibilityPolicy.unknown,
      ),
    );

Map<String, dynamic> _$UserTopicItemToJson(UserTopicItem instance) =>
    <String, dynamic>{
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

UnreadMessagesSnapshot _$UnreadMessagesSnapshotFromJson(
  Map<String, dynamic> json,
) => UnreadMessagesSnapshot(
  count: (json['count'] as num).toInt(),
  dms: (json['pms'] as List<dynamic>)
      .map((e) => UnreadDmSnapshot.fromJson(e as Map<String, dynamic>))
      .toList(),
  channels: (json['streams'] as List<dynamic>)
      .map((e) => UnreadChannelSnapshot.fromJson(e as Map<String, dynamic>))
      .toList(),
  huddles: (json['huddles'] as List<dynamic>)
      .map((e) => UnreadHuddleSnapshot.fromJson(e as Map<String, dynamic>))
      .toList(),
  mentions: (json['mentions'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  oldUnreadsMissing: json['old_unreads_missing'] as bool,
);

Map<String, dynamic> _$UnreadMessagesSnapshotToJson(
  UnreadMessagesSnapshot instance,
) => <String, dynamic>{
  'count': instance.count,
  'pms': instance.dms,
  'streams': instance.channels,
  'huddles': instance.huddles,
  'mentions': instance.mentions,
  'old_unreads_missing': instance.oldUnreadsMissing,
};

UnreadDmSnapshot _$UnreadDmSnapshotFromJson(Map<String, dynamic> json) =>
    UnreadDmSnapshot(
      otherUserId: (json['other_user_id'] as num).toInt(),
      unreadMessageIds: (json['unread_message_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$UnreadDmSnapshotToJson(UnreadDmSnapshot instance) =>
    <String, dynamic>{
      'other_user_id': instance.otherUserId,
      'unread_message_ids': instance.unreadMessageIds,
    };

UnreadChannelSnapshot _$UnreadChannelSnapshotFromJson(
  Map<String, dynamic> json,
) => UnreadChannelSnapshot(
  topic: TopicName.fromJson(json['topic'] as String),
  streamId: (json['stream_id'] as num).toInt(),
  unreadMessageIds: (json['unread_message_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$UnreadChannelSnapshotToJson(
  UnreadChannelSnapshot instance,
) => <String, dynamic>{
  'topic': instance.topic,
  'stream_id': instance.streamId,
  'unread_message_ids': instance.unreadMessageIds,
};

UnreadHuddleSnapshot _$UnreadHuddleSnapshotFromJson(
  Map<String, dynamic> json,
) => UnreadHuddleSnapshot(
  userIdsString: json['user_ids_string'] as String,
  unreadMessageIds: (json['unread_message_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$UnreadHuddleSnapshotToJson(
  UnreadHuddleSnapshot instance,
) => <String, dynamic>{
  'user_ids_string': instance.userIdsString,
  'unread_message_ids': instance.unreadMessageIds,
};
