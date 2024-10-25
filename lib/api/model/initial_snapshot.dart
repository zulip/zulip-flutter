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
  final String? zulipMergeBase; // TODO(server-5)

  final List<String> alertWords;

  final List<CustomProfileField> customProfileFields;

  /// The realm-level policy, on pre-FL 163 servers, for visibility of real email addresses.
  ///
  /// Search for "email_address_visibility" in https://zulip.com/api/register-queue.
  ///
  /// This field is removed in Zulip 7.0 (FL 163) and replaced with a user-level
  /// setting:
  ///   * https://zulip.com/api/update-settings#parameter-email_address_visibility
  ///   * https://zulip.com/api/update-realm-user-settings-defaults#parameter-email_address_visibility
  final EmailAddressVisibility? emailAddressVisibility; // TODO(server-7): remove

  // TODO(server-8): Remove the default values.
  @JsonKey(defaultValue: 15000)
  final int serverTypingStartedExpiryPeriodMilliseconds;
  @JsonKey(defaultValue: 5000)
  final int serverTypingStoppedWaitPeriodMilliseconds;
  @JsonKey(defaultValue: 10000)
  final int serverTypingStartedWaitPeriodMilliseconds;

  // final List<…> mutedTopics; // TODO(#422) we ignore this feature on older servers

  final Map<String, RealmEmojiItem> realmEmoji;

  final List<RecentDmConversation> recentPrivateConversations;

  final List<Subscription> subscriptions;

  final UnreadMessagesSnapshot unreadMsgs;

  final List<ZulipStream> streams;

  // Servers pre-5.0 don't have `user_settings`, and instead provide whatever
  // user settings they support at toplevel in the initial snapshot. Since we're
  // likely to desupport pre-5.0 servers before wide release, we prefer to
  // ignore the toplevel fields and use `user_settings` where present instead,
  // even at the expense of functionality with pre-5.0 servers.
  // TODO(server-5) remove pre-5.0 comment
  final UserSettings? userSettings; // TODO(server-5)

  final List<UserTopicItem>? userTopics; // TODO(server-6)

  final Map<String, RealmDefaultExternalAccount> realmDefaultExternalAccounts;

  final int maxFileUploadSizeMib;

  final Uri? serverEmojiDataUrl; // TODO(server-6)

  @JsonKey(readValue: _readUsersIsActiveFallbackTrue)
  final List<User> realmUsers;
  @JsonKey(readValue: _readUsersIsActiveFallbackFalse)
  final List<User> realmNonActiveUsers;
  @JsonKey(readValue: _readUsersIsActiveFallbackTrue)
  final List<User> crossRealmBots;

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
    required this.emailAddressVisibility,
    required this.serverTypingStartedExpiryPeriodMilliseconds,
    required this.serverTypingStoppedWaitPeriodMilliseconds,
    required this.serverTypingStartedWaitPeriodMilliseconds,
    required this.realmEmoji,
    required this.recentPrivateConversations,
    required this.subscriptions,
    required this.unreadMsgs,
    required this.streams,
    required this.userSettings,
    required this.userTopics,
    required this.realmDefaultExternalAccounts,
    required this.maxFileUploadSizeMib,
    required this.serverEmojiDataUrl,
    required this.realmUsers,
    required this.realmNonActiveUsers,
    required this.crossRealmBots,
  });

  factory InitialSnapshot.fromJson(Map<String, dynamic> json) =>
    _$InitialSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$InitialSnapshotToJson(this);
}

enum EmailAddressVisibility {
  @JsonValue(1) everyone,
  @JsonValue(2) members,
  @JsonValue(3) admins,
  @JsonValue(4) nobody,
  @JsonValue(5) moderators,
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
  bool twentyFourHourTime;
  bool? displayEmojiReactionUsers; // TODO(server-6)
  Emojiset emojiset;

  // TODO more, as needed. When adding a setting here, please also:
  // (1) add it to the [UserSettingName] enum
  // (2) then re-run the command to refresh the .g.dart files
  // (3) handle the event that signals an update to the setting

  UserSettings({
    required this.twentyFourHourTime,
    required this.displayEmojiReactionUsers,
    required this.emojiset,
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
  final String topicName;
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
  @JsonKey(readValue: _readOtherUserId)
  final int otherUserId;
  final List<int> unreadMessageIds;

  // TODO(server-5): Simplify away.
  static dynamic _readOtherUserId(Map<dynamic, dynamic> json, String key) {
    return json[key] ?? json['sender_id'];
  }

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
  final String topic;
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
