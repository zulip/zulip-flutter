import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../model/algorithms.dart';
import 'model.dart';

part 'initial_snapshot.g.dart';

// https://zulip.com/api/register-queue#response
@JsonSerializable(fieldRename: FieldRename.snake)
class InitialSnapshot {
  // Keep these fields in the order they appear in the API docs.
  // (For many API types we choose a more logical order than the docs.
  // But this one is so long that that'd make it become impossible to
  // compare the lists by hand.)

  final String? queueId;
  final int lastEventId;
  final int zulipFeatureLevel;
  final String zulipVersion;
  final String zulipMergeBase;

  final List<String> alertWords;

  final List<CustomProfileField> customProfileFields;

  @JsonKey(name: 'max_stream_name_length')
  final int maxChannelNameLength;
  final int maxTopicLength;

  final int serverPresencePingIntervalSeconds;
  final int serverPresenceOfflineThresholdSeconds;

  // TODO(server-8): Remove the default values.
  @JsonKey(defaultValue: 15000)
  final int serverTypingStartedExpiryPeriodMilliseconds;
  @JsonKey(defaultValue: 5000)
  final int serverTypingStoppedWaitPeriodMilliseconds;
  @JsonKey(defaultValue: 10000)
  final int serverTypingStartedWaitPeriodMilliseconds;

  final List<MutedUserItem> mutedUsers;

  // In the modern format because we pass `slim_presence`.
  // TODO(#1611) stop passing and mentioning the deprecated slim_presence;
  //   presence_last_update_id will be why we get the modern format.
  final Map<int, PerUserPresence> presences;

  final Map<String, RealmEmojiItem> realmEmoji;

  final List<UserGroup> realmUserGroups;

  final List<RecentDmConversation> recentPrivateConversations;

  final List<SavedSnippet>? savedSnippets; // TODO(server-10)

  final List<Subscription> subscriptions;

  final List<ChannelFolder>? channelFolders; // TODO(server-11)

  final UnreadMessagesSnapshot unreadMsgs;

  final List<ZulipStream> streams;

  // In register-queue, the name of this field is the singular "user_status",
  // even though it actually contains user status information for all the users
  // that the self-user has access to. Therefore, we prefer to use the plural form.
  //
  // The API expresses each status as a change from the "zero status" (see
  // [UserStatus.zero]), with entries omitted for users whose status is the
  // zero status.
  @JsonKey(name: 'user_status')
  final Map<int, UserStatusChange> userStatuses;

  final UserSettings userSettings;

  final List<UserTopicItem> userTopics;

  final GroupSettingValue? realmCanDeleteAnyMessageGroup; // TODO(server-10)

  final GroupSettingValue? realmCanDeleteOwnMessageGroup; // TODO(server-10)

  /// The policy for who can delete their own messages,
  /// on supported servers below version 10.
  ///
  /// Removed in FL 291, so absent in the current API doc;
  /// see zulip/zulip@0cd51f2fe.
  final RealmDeleteOwnMessagePolicy? realmDeleteOwnMessagePolicy; // TODO(server-10)

  /// The policy for who can use wildcard mentions in large channels.
  ///
  /// Search for "realm_wildcard_mention_policy" in https://zulip.com/api/register-queue.
  final RealmWildcardMentionPolicy realmWildcardMentionPolicy;

  final bool realmMandatoryTopics;

  final String realmName;

  /// The number of days until a user's account is treated as a full member.
  ///
  /// Search for "realm_waiting_period_threshold" in https://zulip.com/api/register-queue.
  ///
  /// For how to determine if a user is a full member, see:
  ///   https://zulip.com/api/roles-and-permissions#determining-if-a-user-is-a-full-member
  final int realmWaitingPeriodThreshold;

  final int? realmMessageContentDeleteLimitSeconds;

  final bool realmAllowMessageEditing;
  final int? realmMessageContentEditLimitSeconds;

  final bool realmEnableReadReceipts;

  final Uri realmIconUrl;

  final bool realmPresenceDisabled;

  final Map<String, RealmDefaultExternalAccount> realmDefaultExternalAccounts;

  final int maxFileUploadSizeMib;

  final Uri serverEmojiDataUrl;

  final String? realmEmptyTopicDisplayName; // TODO(server-10)

  @JsonKey(readValue: _readUsersIsActiveFallbackTrue)
  final List<User> realmUsers;
  @JsonKey(readValue: _readUsersIsActiveFallbackFalse)
  final List<User> realmNonActiveUsers;
  @JsonKey(readValue: _readUsersIsActiveFallbackTrue)
  final List<User> crossRealmBots;

  // TODO(server): Get this API stabilized, to replace [SupportedPermissionSettings.fixture].
  // final SupportedPermissionSettings? serverSupportedPermissionSettings;

  // TODO etc., etc.
  // If adding fields, keep them all in the order they appear in the API docs.

  // `is_active` is sometimes absent:
  //   https://chat.zulip.org/#narrow/stream/412-api-documentation/topic/.60is_active.60.20in.20.60.2Fregister.60.20response/near/1371603
  // But for our model it's convenient to always have it; so, fill it in.
  static Object? _readUsersIsActiveFallbackTrue(Map<dynamic, dynamic> json, String key) {
    final list = (json[key] as List<dynamic>);
    for (final user in list) {
      (user as Map<String, dynamic>).putIfAbsent('is_active', () => true);
    }
    return list;
  }
  static Object? _readUsersIsActiveFallbackFalse(Map<dynamic, dynamic> json, String key) {
    final list = (json[key] as List<dynamic>);
    for (final user in list) {
      (user as Map<String, dynamic>).putIfAbsent('is_active', () => false);
    }
    return list;
  }

  InitialSnapshot({
    required this.queueId,
    required this.lastEventId,
    required this.zulipFeatureLevel,
    required this.zulipVersion,
    required this.zulipMergeBase,
    required this.alertWords,
    required this.customProfileFields,
    required this.maxChannelNameLength,
    required this.maxTopicLength,
    required this.serverPresencePingIntervalSeconds,
    required this.serverPresenceOfflineThresholdSeconds,
    required this.serverTypingStartedExpiryPeriodMilliseconds,
    required this.serverTypingStoppedWaitPeriodMilliseconds,
    required this.serverTypingStartedWaitPeriodMilliseconds,
    required this.mutedUsers,
    required this.presences,
    required this.realmEmoji,
    required this.realmUserGroups,
    required this.recentPrivateConversations,
    required this.savedSnippets,
    required this.subscriptions,
    required this.channelFolders,
    required this.unreadMsgs,
    required this.streams,
    required this.userStatuses,
    required this.userSettings,
    required this.userTopics,
    required this.realmCanDeleteAnyMessageGroup,
    required this.realmCanDeleteOwnMessageGroup,
    required this.realmDeleteOwnMessagePolicy,
    required this.realmWildcardMentionPolicy,
    required this.realmMandatoryTopics,
    required this.realmName,
    required this.realmWaitingPeriodThreshold,
    required this.realmMessageContentDeleteLimitSeconds,
    required this.realmAllowMessageEditing,
    required this.realmMessageContentEditLimitSeconds,
    required this.realmEnableReadReceipts,
    required this.realmIconUrl,
    required this.realmPresenceDisabled,
    required this.realmDefaultExternalAccounts,
    required this.maxFileUploadSizeMib,
    required this.serverEmojiDataUrl,
    required this.realmEmptyTopicDisplayName,
    required this.realmUsers,
    required this.realmNonActiveUsers,
    required this.crossRealmBots,
  });

  factory InitialSnapshot.fromJson(Map<String, dynamic> json) =>
    _$InitialSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$InitialSnapshotToJson(this);
}

@JsonEnum(valueField: 'apiValue')
enum RealmWildcardMentionPolicy {
  everyone(apiValue: 1),
  members(apiValue: 2),
  fullMembers(apiValue: 3),
  admins(apiValue: 5),
  nobody(apiValue: 6),
  moderators(apiValue: 7);

  const RealmWildcardMentionPolicy({required this.apiValue});

  final int? apiValue;

  int? toJson() => apiValue;
}

@JsonEnum(valueField: 'apiValue')
enum RealmDeleteOwnMessagePolicy {
  members(apiValue: 1),
  admins(apiValue: 2),
  fullMembers(apiValue: 3),
  moderators(apiValue: 4),
  everyone(apiValue: 5);

  const RealmDeleteOwnMessagePolicy({required this.apiValue});

  final int apiValue;

  int toJson() => apiValue;
}

/// An item in `realm_default_external_accounts`.
///
/// For docs, search for "realm_default_external_accounts:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class RealmDefaultExternalAccount {
  final String name;
  final String text;
  final String hint;
  final String urlPattern;

  RealmDefaultExternalAccount({
    required this.name,
    required this.text,
    required this.hint,
    required this.urlPattern,
  });

  factory RealmDefaultExternalAccount.fromJson(Map<String, dynamic> json) =>
    _$RealmDefaultExternalAccountFromJson(json);

  Map<String, dynamic> toJson() => _$RealmDefaultExternalAccountToJson(this);
}

/// An item in `recent_private_conversations`.
///
/// For docs, search for "recent_private_conversations:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class RecentDmConversation {
  final int maxMessageId;
  final List<int> userIds;

  RecentDmConversation({
    required this.maxMessageId,
    required this.userIds,
  });

  factory RecentDmConversation.fromJson(Map<String, dynamic> json) =>
    _$RecentDmConversationFromJson(json);

  Map<String, dynamic> toJson() => _$RecentDmConversationToJson(this);
}

/// The `user_settings` dictionary.
///
/// For docs, search for "user_settings:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake, createFieldMap: true)
class UserSettings {
  @JsonKey(
    fromJson: TwentyFourHourTimeMode.fromApiValue,
    toJson: TwentyFourHourTimeMode.staticToJson,
  )
  TwentyFourHourTimeMode twentyFourHourTime;

  bool displayEmojiReactionUsers;
  @JsonKey(unknownEnumValue: Emojiset.unknown)
  Emojiset emojiset;
  bool presenceEnabled;

  // TODO more, as needed. When adding a setting here, please also:
  // (1) add it to the [UserSettingName] enum
  // (2) then re-run the command to refresh the .g.dart files
  // (3) handle the event that signals an update to the setting
  // (4) add the setting to the [updateSettings] route binding

  UserSettings({
    required this.twentyFourHourTime,
    required this.displayEmojiReactionUsers,
    required this.emojiset,
    required this.presenceEnabled,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
    _$UserSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);

  /// A list of [UserSettings]'s properties, as strings.
  // _$…FieldMap is thanks to `createFieldMap: true`
  @visibleForTesting
  static final Iterable<String> debugKnownNames = _$UserSettingsFieldMap.keys;
}

/// An item in the `user_topics` snapshot.
///
/// For docs, search for "user_topics:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class UserTopicItem {
  final int streamId;
  final TopicName topicName;
  final int lastUpdated;
  @JsonKey(unknownEnumValue: UserTopicVisibilityPolicy.unknown)
  final UserTopicVisibilityPolicy visibilityPolicy;

  UserTopicItem({
    required this.streamId,
    required this.topicName,
    required this.lastUpdated,
    required this.visibilityPolicy,
  });

  factory UserTopicItem.fromJson(Map<String, dynamic> json) =>
    _$UserTopicItemFromJson(json);

  Map<String, dynamic> toJson() => _$UserTopicItemToJson(this);
}

/// The `unread_msgs` snapshot.
///
/// For docs, search for "unread_msgs:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class UnreadMessagesSnapshot {
  final int count;

  @JsonKey(name: 'pms')
  final List<UnreadDmSnapshot> dms;

  @JsonKey(name: 'streams')
  final List<UnreadChannelSnapshot> channels;
  final List<UnreadHuddleSnapshot> huddles;

  // Unlike other lists of message IDs here, [mentions] is *not* sorted.
  final List<int> mentions;

  final bool oldUnreadsMissing;

  const UnreadMessagesSnapshot({
    required this.count,
    required this.dms,
    required this.channels,
    required this.huddles,
    required this.mentions,
    required this.oldUnreadsMissing,
  });

  factory UnreadMessagesSnapshot.fromJson(Map<String, dynamic> json) =>
    _$UnreadMessagesSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$UnreadMessagesSnapshotToJson(this);
}

/// An item in [UnreadMessagesSnapshot.dms].
@JsonSerializable(fieldRename: FieldRename.snake)
class UnreadDmSnapshot {
  final int otherUserId;
  final List<int> unreadMessageIds;

  UnreadDmSnapshot({
    required this.otherUserId,
    required this.unreadMessageIds,
  }) : assert(isSortedWithoutDuplicates(unreadMessageIds));

  factory UnreadDmSnapshot.fromJson(Map<String, dynamic> json) =>
    _$UnreadDmSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$UnreadDmSnapshotToJson(this);
}

/// An item in [UnreadMessagesSnapshot.channels].
@JsonSerializable(fieldRename: FieldRename.snake)
class UnreadChannelSnapshot {
  final TopicName topic;
  final int streamId;
  final List<int> unreadMessageIds;

  UnreadChannelSnapshot({
    required this.topic,
    required this.streamId,
    required this.unreadMessageIds,
  }) : assert(isSortedWithoutDuplicates(unreadMessageIds));

  factory UnreadChannelSnapshot.fromJson(Map<String, dynamic> json) =>
    _$UnreadChannelSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$UnreadChannelSnapshotToJson(this);
}

/// An item in [UnreadMessagesSnapshot.huddles].
@JsonSerializable(fieldRename: FieldRename.snake)
class UnreadHuddleSnapshot {
  final String userIdsString;
  final List<int> unreadMessageIds;

  UnreadHuddleSnapshot({
    required this.userIdsString,
    required this.unreadMessageIds,
  }) : assert(isSortedWithoutDuplicates(unreadMessageIds));

  factory UnreadHuddleSnapshot.fromJson(Map<String, dynamic> json) =>
    _$UnreadHuddleSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$UnreadHuddleSnapshotToJson(this);
}
