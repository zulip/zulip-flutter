// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'initial_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitialSnapshot _$InitialSnapshotFromJson(Map<String, dynamic> json) =>
    InitialSnapshot(
      queueId: json['queue_id'] as String?,
      lastEventId: (json['last_event_id'] as num).toInt(),
      zulipFeatureLevel: (json['zulip_feature_level'] as num).toInt(),
      zulipVersion: json['zulip_version'] as String,
      zulipMergeBase: json['zulip_merge_base'] as String?,
      alertWords: (json['alert_words'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      customProfileFields: (json['custom_profile_fields'] as List<dynamic>)
          .map((e) => CustomProfileField.fromJson(e as Map<String, dynamic>))
          .toList(),
      emailAddressVisibility: $enumDecodeNullable(
          _$EmailAddressVisibilityEnumMap, json['email_address_visibility']),
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
      realmEmoji: (json['realm_emoji'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, RealmEmojiItem.fromJson(e as Map<String, dynamic>)),
      ),
      recentPrivateConversations: (json['recent_private_conversations']
              as List<dynamic>)
          .map((e) => RecentDmConversation.fromJson(e as Map<String, dynamic>))
          .toList(),
      subscriptions: (json['subscriptions'] as List<dynamic>)
          .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadMsgs: UnreadMessagesSnapshot.fromJson(
          json['unread_msgs'] as Map<String, dynamic>),
      streams: (json['streams'] as List<dynamic>)
          .map((e) => ZulipStream.fromJson(e as Map<String, dynamic>))
          .toList(),
      userSettings: json['user_settings'] == null
          ? null
          : UserSettings.fromJson(
              json['user_settings'] as Map<String, dynamic>),
      userTopics: (json['user_topics'] as List<dynamic>?)
          ?.map((e) => UserTopicItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      realmWaitingPeriodThreshold:
          (json['realm_waiting_period_threshold'] as num).toInt(),
      realmDefaultExternalAccounts:
          (json['realm_default_external_accounts'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k, RealmDefaultExternalAccount.fromJson(e as Map<String, dynamic>)),
      ),
      maxFileUploadSizeMib: (json['max_file_upload_size_mib'] as num).toInt(),
      serverEmojiDataUrl: json['server_emoji_data_url'] == null
          ? null
          : Uri.parse(json['server_emoji_data_url'] as String),
      realmUsers:
          (InitialSnapshot._readUsersIsActiveFallbackTrue(json, 'realm_users')
                  as List<dynamic>)
              .map((e) => User.fromJson(e as Map<String, dynamic>))
              .toList(),
      realmNonActiveUsers: (InitialSnapshot._readUsersIsActiveFallbackFalse(
              json, 'realm_non_active_users') as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
      crossRealmBots: (InitialSnapshot._readUsersIsActiveFallbackTrue(
              json, 'cross_realm_bots') as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$InitialSnapshotToJson(InitialSnapshot instance) =>
    <String, dynamic>{
      'queue_id': instance.queueId,
      'last_event_id': instance.lastEventId,
      'zulip_feature_level': instance.zulipFeatureLevel,
      'zulip_version': instance.zulipVersion,
      'zulip_merge_base': instance.zulipMergeBase,
      'alert_words': instance.alertWords,
      'custom_profile_fields': instance.customProfileFields,
      'email_address_visibility':
          _$EmailAddressVisibilityEnumMap[instance.emailAddressVisibility],
      'server_typing_started_expiry_period_milliseconds':
          instance.serverTypingStartedExpiryPeriodMilliseconds,
      'server_typing_stopped_wait_period_milliseconds':
          instance.serverTypingStoppedWaitPeriodMilliseconds,
      'server_typing_started_wait_period_milliseconds':
          instance.serverTypingStartedWaitPeriodMilliseconds,
      'realm_emoji': instance.realmEmoji,
      'recent_private_conversations': instance.recentPrivateConversations,
      'subscriptions': instance.subscriptions,
      'unread_msgs': instance.unreadMsgs,
      'streams': instance.streams,
      'user_settings': instance.userSettings,
      'user_topics': instance.userTopics,
      'realm_waiting_period_threshold': instance.realmWaitingPeriodThreshold,
      'realm_default_external_accounts': instance.realmDefaultExternalAccounts,
      'max_file_upload_size_mib': instance.maxFileUploadSizeMib,
      'server_emoji_data_url': instance.serverEmojiDataUrl?.toString(),
      'realm_users': instance.realmUsers,
      'realm_non_active_users': instance.realmNonActiveUsers,
      'cross_realm_bots': instance.crossRealmBots,
    };

const _$EmailAddressVisibilityEnumMap = {
  EmailAddressVisibility.everyone: 1,
  EmailAddressVisibility.members: 2,
  EmailAddressVisibility.admins: 3,
  EmailAddressVisibility.nobody: 4,
  EmailAddressVisibility.moderators: 5,
};

RealmDefaultExternalAccount _$RealmDefaultExternalAccountFromJson(
        Map<String, dynamic> json) =>
    RealmDefaultExternalAccount(
      name: json['name'] as String,
      text: json['text'] as String,
      hint: json['hint'] as String,
      urlPattern: json['url_pattern'] as String,
    );

Map<String, dynamic> _$RealmDefaultExternalAccountToJson(
        RealmDefaultExternalAccount instance) =>
    <String, dynamic>{
      'name': instance.name,
      'text': instance.text,
      'hint': instance.hint,
      'url_pattern': instance.urlPattern,
    };

RecentDmConversation _$RecentDmConversationFromJson(
        Map<String, dynamic> json) =>
    RecentDmConversation(
      maxMessageId: (json['max_message_id'] as num).toInt(),
      userIds: (json['user_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$RecentDmConversationToJson(
        RecentDmConversation instance) =>
    <String, dynamic>{
      'max_message_id': instance.maxMessageId,
      'user_ids': instance.userIds,
    };

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) => UserSettings(
      twentyFourHourTime: json['twenty_four_hour_time'] as bool,
      displayEmojiReactionUsers: json['display_emoji_reaction_users'] as bool?,
      emojiset: $enumDecode(_$EmojisetEnumMap, json['emojiset']),
    );

const _$UserSettingsFieldMap = <String, String>{
  'twentyFourHourTime': 'twenty_four_hour_time',
  'displayEmojiReactionUsers': 'display_emoji_reaction_users',
  'emojiset': 'emojiset',
};

Map<String, dynamic> _$UserSettingsToJson(UserSettings instance) =>
    <String, dynamic>{
      'twenty_four_hour_time': instance.twentyFourHourTime,
      'display_emoji_reaction_users': instance.displayEmojiReactionUsers,
      'emojiset': _$EmojisetEnumMap[instance.emojiset]!,
    };

const _$EmojisetEnumMap = {
  Emojiset.google: 'google',
  Emojiset.googleBlob: 'google-blob',
  Emojiset.twitter: 'twitter',
  Emojiset.text: 'text',
};

UserTopicItem _$UserTopicItemFromJson(Map<String, dynamic> json) =>
    UserTopicItem(
      streamId: (json['stream_id'] as num).toInt(),
      topicName: TopicName.fromJson(json['topic_name'] as String),
      lastUpdated: (json['last_updated'] as num).toInt(),
      visibilityPolicy: $enumDecode(
          _$UserTopicVisibilityPolicyEnumMap, json['visibility_policy'],
          unknownValue: UserTopicVisibilityPolicy.unknown),
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
        Map<String, dynamic> json) =>
    UnreadMessagesSnapshot(
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
        UnreadMessagesSnapshot instance) =>
    <String, dynamic>{
      'count': instance.count,
      'pms': instance.dms,
      'streams': instance.channels,
      'huddles': instance.huddles,
      'mentions': instance.mentions,
      'old_unreads_missing': instance.oldUnreadsMissing,
    };

UnreadDmSnapshot _$UnreadDmSnapshotFromJson(Map<String, dynamic> json) =>
    UnreadDmSnapshot(
      otherUserId:
          (UnreadDmSnapshot._readOtherUserId(json, 'other_user_id') as num)
              .toInt(),
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
        Map<String, dynamic> json) =>
    UnreadChannelSnapshot(
      topic: TopicName.fromJson(json['topic'] as String),
      streamId: (json['stream_id'] as num).toInt(),
      unreadMessageIds: (json['unread_message_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$UnreadChannelSnapshotToJson(
        UnreadChannelSnapshot instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'stream_id': instance.streamId,
      'unread_message_ids': instance.unreadMessageIds,
    };

UnreadHuddleSnapshot _$UnreadHuddleSnapshotFromJson(
        Map<String, dynamic> json) =>
    UnreadHuddleSnapshot(
      userIdsString: json['user_ids_string'] as String,
      unreadMessageIds: (json['unread_message_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$UnreadHuddleSnapshotToJson(
        UnreadHuddleSnapshot instance) =>
    <String, dynamic>{
      'user_ids_string': instance.userIdsString,
      'unread_message_ids': instance.unreadMessageIds,
    };
