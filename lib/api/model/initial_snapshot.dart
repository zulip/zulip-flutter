import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

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

  // TODO etc., etc.

  final List<RecentDmConversation> recentPrivateConversations;

  final List<Subscription> subscriptions;

  final List<ZulipStream> streams;

  // Servers pre-5.0 don't have `user_settings`, and instead provide whatever
  // user settings they support at toplevel in the initial snapshot. Since we're
  // likely to desupport pre-5.0 servers before wide release, we prefer to
  // ignore the toplevel fields and use `user_settings` where present instead,
  // even at the expense of functionality with pre-5.0 servers.
  // TODO(server-5) remove pre-5.0 comment
  final UserSettings? userSettings; // TODO(server-5)

  final int maxFileUploadSizeMib;

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
  static Object? _readUsersIsActiveFallbackTrue(Map json, String key) {
    final list = (json[key] as List<dynamic>);
    for (final Map<String, dynamic> user in list) {
      user.putIfAbsent('is_active', () => true);
    }
    return list;
  }
  static Object? _readUsersIsActiveFallbackFalse(Map json, String key) {
    final list = (json[key] as List<dynamic>);
    for (final Map<String, dynamic> user in list) {
      user.putIfAbsent('is_active', () => false);
    }
    return list;
  }

  InitialSnapshot({
    this.queueId,
    required this.lastEventId,
    required this.zulipFeatureLevel,
    required this.zulipVersion,
    this.zulipMergeBase,
    required this.alertWords,
    required this.customProfileFields,
    required this.recentPrivateConversations,
    required this.subscriptions,
    required this.streams,
    required this.userSettings,
    required this.maxFileUploadSizeMib,
    required this.realmUsers,
    required this.realmNonActiveUsers,
    required this.crossRealmBots,
  });

  factory InitialSnapshot.fromJson(Map<String, dynamic> json) =>
    _$InitialSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$InitialSnapshotToJson(this);
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
  bool? displayEmojiReactionUsers; // TODO(server-6)

  // TODO more, as needed. When adding a setting here, please also:
  // (1) add it to the [UserSettingName] enum below
  // (2) then re-run the command to refresh the .g.dart files
  // (3) handle the event that signals an update to the setting

  UserSettings({
    required this.displayEmojiReactionUsers,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
    _$UserSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);

  /// A list of [UserSettings]'s properties, as strings.
  // _$…FieldMap is thanks to `createFieldMap: true`
  @visibleForTesting
  static final Iterable<String> debugKnownNames = _$UserSettingsFieldMap.keys;
}

/// The name of a user setting that has a property in [UserSettings].
///
/// In Zulip event-handling code (for [UserSettingsUpdateEvent]),
/// we switch exhaustively on a value of this type
/// to ensure that every setting in [UserSettings] responds to the event.
@JsonEnum(fieldRename: FieldRename.snake, alwaysCreate: true)
enum UserSettingName {
  displayEmojiReactionUsers;

  /// Get a [UserSettingName] from a raw, snake-case string we recognize, else null.
  ///
  /// Example:
  ///   'display_emoji_reaction_users' -> UserSettingName.displayEmojiReactionUsers
  static UserSettingName? fromRawString(String raw) => _byRawString[raw];

  // _$…EnumMap is thanks to `alwaysCreate: true` and `fieldRename: FieldRename.snake`
  static final _byRawString = _$UserSettingNameEnumMap
    .map((key, value) => MapEntry(value, key));
}
