import 'package:json_annotation/json_annotation.dart';

import '../../basic.dart';
import '../../model/algorithms.dart';
import 'events.dart';
import 'initial_snapshot.dart';
import 'reaction.dart';
import 'submessage.dart';

export 'json.dart' show JsonNullable;
export 'reaction.dart';

part 'model.g.dart';

/// A Zulip "group-setting value": https://zulip.com/api/group-setting-values
sealed class GroupSettingValue {
  const GroupSettingValue();

  factory GroupSettingValue.fromJson(Object? json) {
    return switch (json) {
      int() => GroupSettingValueNamed.fromJson(json),
      Map<String, dynamic>() => GroupSettingValueNameless.fromJson(json),
      _ => throw FormatException(),
    };
  }

  Object? toJson();
}

class GroupSettingValueNamed extends GroupSettingValue {
  final int groupId;

  const GroupSettingValueNamed(this.groupId);

  factory GroupSettingValueNamed.fromJson(int json) => GroupSettingValueNamed(json);

  @override
  int toJson() => groupId;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GroupSettingValueNameless extends GroupSettingValue {
  // TODO(server): The API docs say these should be "direct_member_ids" and
  //   "direct_subgroup_ids", but empirically they're "direct_members"
  //   and "direct_subgroups".  Discussion:
  //     https://chat.zulip.org/#narrow/channel/378-api-design/topic/groups.20redesign/near/2247218
  final List<int> directMembers;
  final List<int> directSubgroups;

  GroupSettingValueNameless({required this.directMembers, required this.directSubgroups});

  factory GroupSettingValueNameless.fromJson(Map<String, dynamic> json) =>
    _$GroupSettingValueNamelessFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$GroupSettingValueNamelessToJson(this);
}

/// As in [InitialSnapshot.customProfileFields].
///
/// For docs, search for "custom_profile_fields:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class CustomProfileField {
  final int id;
  @JsonKey(unknownEnumValue: CustomProfileFieldType.unknown)
  final CustomProfileFieldType type;
  final int order;
  final String name;
  final String hint;
  final String fieldData;
  final bool? displayInProfileSummary;

  CustomProfileField({
    required this.id,
    required this.type,
    required this.order,
    required this.name,
    required this.hint,
    required this.fieldData,
    required this.displayInProfileSummary,
  });

  factory CustomProfileField.fromJson(Map<String, dynamic> json) =>
    _$CustomProfileFieldFromJson(json);

  Map<String, dynamic> toJson() => _$CustomProfileFieldToJson(this);
}

/// As in [CustomProfileField.type].
@JsonEnum(fieldRename: FieldRename.snake, valueField: "apiValue")
enum CustomProfileFieldType {
  shortText(apiValue: 1),
  longText(apiValue: 2),
  choice(apiValue: 3),
  date(apiValue: 4),
  link(apiValue: 5),
  user(apiValue: 6),
  externalAccount(apiValue: 7),
  pronouns(apiValue: 8),
  unknown(apiValue: null);

  const CustomProfileFieldType({
    required this.apiValue
  });

  final int? apiValue;

  int? toJson() => apiValue;
}

/// An item in the realm-level field data for a "choice" custom profile field.
///
/// The value of [CustomProfileField.fieldData] decodes to a
/// `List<CustomProfileFieldChoiceDataItem>` when
/// the [CustomProfileField.type] is [CustomProfileFieldType.choice].
///
/// TODO(server): This isn't really documented.  But see chat thread:
///   https://chat.zulip.org/#narrow/stream/378-api-design/topic/custom.20profile.20fields/near/1383005
@JsonSerializable(fieldRename: FieldRename.snake)
class CustomProfileFieldChoiceDataItem {
  final String text;

  const CustomProfileFieldChoiceDataItem({required this.text});

  factory CustomProfileFieldChoiceDataItem.fromJson(Map<String, dynamic> json) =>
    _$CustomProfileFieldChoiceDataItemFromJson(json);

  Map<String, dynamic> toJson() => _$CustomProfileFieldChoiceDataItemToJson(this);

  static Map<String, CustomProfileFieldChoiceDataItem> parseFieldDataChoices(Map<String, dynamic> json) =>
    json.map((k, v) => MapEntry(k, CustomProfileFieldChoiceDataItem.fromJson(v as Map<String, dynamic>)));
}

/// The realm-level field data for an "external account" custom profile field.
///
/// This is the decoding of [CustomProfileField.fieldData] when
/// the [CustomProfileField.type] is [CustomProfileFieldType.externalAccount].
///
/// TODO(server): This is undocumented.  See chat thread:
///   https://chat.zulip.org/#narrow/stream/378-api-design/topic/external.20account.20custom.20profile.20fields/near/1387213
@JsonSerializable(fieldRename: FieldRename.snake)
class CustomProfileFieldExternalAccountData {
  final String subtype;
  final String? urlPattern;

  const CustomProfileFieldExternalAccountData({
    required this.subtype,
    required this.urlPattern,
  });

  factory CustomProfileFieldExternalAccountData.fromJson(Map<String, dynamic> json) =>
    _$CustomProfileFieldExternalAccountDataFromJson(json);

  Map<String, dynamic> toJson() => _$CustomProfileFieldExternalAccountDataToJson(this);
}

/// An item in the [InitialSnapshot.mutedUsers] or [MutedUsersEvent].
///
/// For docs, search for "muted_users:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class MutedUserItem {
  final int id;

  // Mobile doesn't use the timestamp; ignore.
  // final int timestamp;

  const MutedUserItem({required this.id});

  factory MutedUserItem.fromJson(Map<String, dynamic> json) =>
    _$MutedUserItemFromJson(json);

  Map<String, dynamic> toJson() => _$MutedUserItemToJson(this);
}

/// An item in [InitialSnapshot.realmEmoji] or [RealmEmojiUpdateEvent].
///
/// For docs, search for "realm_emoji:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class RealmEmojiItem {
  @JsonKey(name: 'id')
  final String emojiCode;
  final String name;
  final String sourceUrl;

  /// The non-animated version, if this is an animated emoji.
  ///
  /// As of 2025-10, this will be missing on animated emoji
  /// that were uploaded before Zulip Server 5 when this was added;
  /// see https://github.com/zulip/zulip/issues/36339 .
  // TODO(server-future) Update dartdoc once all supported servers
  //   have a fix for https://github.com/zulip/zulip/issues/36339
  //   i.e. that have run a migration to fill this in for animated emoji.
  final String? stillUrl;

  final bool deactivated;
  final int? authorId;

  RealmEmojiItem({
    required this.emojiCode,
    required this.name,
    required this.sourceUrl,
    required this.stillUrl,
    required this.deactivated,
    required this.authorId,
  });

  factory RealmEmojiItem.fromJson(Map<String, dynamic> json) =>
    _$RealmEmojiItemFromJson(json);

  Map<String, dynamic> toJson() => _$RealmEmojiItemToJson(this);
}

/// A user's status, with [text] and [emoji] parts.
///
/// If a part is null, that part is empty/unset.
/// For a [UserStatus] with all parts empty, see [zero].
class UserStatus {
  /// The text part (e.g. 'Working remotely'), or null if unset.
  ///
  /// This won't be the empty string.
  final String? text;

  /// The emoji part, or null if unset.
  final StatusEmoji? emoji;

  const UserStatus({required this.text, required this.emoji}) : assert(text != '');

  static const UserStatus zero = UserStatus(text: null, emoji: null);

  @override
  bool operator ==(Object other) {
    if (other is! UserStatus) return false;
    return (text, emoji) == (other.text, other.emoji);
  }

  @override
  int get hashCode => Object.hash(text, emoji);
}

/// A user's status emoji, as in [UserStatus.emoji].
class StatusEmoji {
  final String emojiName;
  final String emojiCode;
  final ReactionType reactionType;

  const StatusEmoji({
    required this.emojiName,
    required this.emojiCode,
    required this.reactionType,
  }) : assert(emojiName != ''), assert(emojiCode != '');

  @override
  bool operator ==(Object other) {
    if (other is! StatusEmoji) return false;
    return (emojiName, emojiCode, reactionType) ==
      (other.emojiName, other.emojiCode, other.reactionType);
  }

  @override
  int get hashCode => Object.hash(emojiName, emojiCode, reactionType);
}

/// A change to part or all of a user's status.
///
/// The absence of one of these means there is no change.
class UserStatusChange {
  final Option<String?> text;
  final Option<StatusEmoji?> emoji;

  const UserStatusChange({required this.text, required this.emoji});

  UserStatus apply(UserStatus old) {
    return UserStatus(text: text.or(old.text), emoji: emoji.or(old.emoji));
  }

  UserStatusChange copyWith({Option<String?>? text, Option<StatusEmoji?>? emoji}) {
    return UserStatusChange(text: text ?? this.text, emoji: emoji ?? this.emoji);
  }

  factory UserStatusChange.fromJson(Map<String, dynamic> json) {
    return UserStatusChange(
      text: _textFromJson(json), emoji: _emojiFromJson(json));
  }

  static Option<String?> _textFromJson(Map<String, dynamic> json) {
    return switch (json['status_text'] as String?) {
      null => OptionNone(),
      '' => OptionSome(null),
      final apiValue => OptionSome(apiValue),
    };
  }

  static Option<StatusEmoji?> _emojiFromJson(Map<String, dynamic> json) {
    final emojiName = json['emoji_name'] as String?;
    final emojiCode = json['emoji_code'] as String?;
    final reactionType = json['reaction_type'] as String?;

    if (emojiName == null || emojiCode == null || reactionType == null) {
      return OptionNone();
    } else if (emojiName == '' || emojiCode == '' || reactionType == '') {
      // Sometimes `reaction_type` is 'unicode_emoji' when the emoji is cleared.
      // This is an accident, to be handled by looking at `emoji_code` instead:
      //   https://chat.zulip.org/#narrow/channel/378-api-design/topic/user.20status/near/2203132
      return OptionSome(null);
    } else {
      return OptionSome(StatusEmoji(
        emojiName: emojiName,
        emojiCode: emojiCode,
        reactionType: ReactionType.fromApiValue(reactionType)));
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (text case OptionSome<String?>(:var value))
        'status_text': value ?? '',
      if (emoji case OptionSome<StatusEmoji?>(:var value))
        ...value == null
          ? {'emoji_name': '', 'emoji_code': '', 'reaction_type': ''}
          : {
              'emoji_name': value.emojiName,
              'emoji_code': value.emojiCode,
              'reaction_type': value.reactionType,
            },
    };
  }
}

/// The name of a user setting that has a property in [UserSettings].
///
/// In Zulip event-handling code (for [UserSettingsUpdateEvent]),
/// we switch exhaustively on a value of this type
/// to ensure that every setting in [UserSettings] responds to the event.
@JsonEnum(fieldRename: FieldRename.snake, alwaysCreate: true)
enum UserSettingName {
  twentyFourHourTime,
  displayEmojiReactionUsers,
  emojiset,
  presenceEnabled,
  ;

  /// Get a [UserSettingName] from a raw, snake-case string we recognize, else null.
  ///
  /// Example:
  ///   'display_emoji_reaction_users' -> UserSettingName.displayEmojiReactionUsers
  static UserSettingName? fromRawString(String raw) => _byRawString[raw];

  // _$…EnumMap is thanks to `alwaysCreate: true` and `fieldRename: FieldRename.snake`
  static final _byRawString = _$UserSettingNameEnumMap
    .map((key, value) => MapEntry(value, key));

  String toJson() => _$UserSettingNameEnumMap[this]!;
}

/// A value from [UserSettings.twentyFourHourTime].
enum TwentyFourHourTimeMode {
  twelveHour(apiValue: false),
  twentyFourHour(apiValue: true),

  /// The locale's default format (12-hour for en_US, 24-hour for fr_FR, etc.).
  // TODO(#1727) actually follow this
  // Not sent by current servers, but planned when most client installs accept it:
  //   https://chat.zulip.org/#narrow/channel/378-api-design/topic/.60user_settings.2Etwenty_four_hour_time.60/near/2220696
  // TODO(server-future) Write down what server N starts sending null;
  //   adjust the comment; leave a TODO(server-N) to delete the comment
  localeDefault(apiValue: null),
  ;

  const TwentyFourHourTimeMode({required this.apiValue});

  final bool? apiValue;

  static bool? staticToJson(TwentyFourHourTimeMode instance) => instance.apiValue;

  bool? toJson() => TwentyFourHourTimeMode.staticToJson(this);

  static TwentyFourHourTimeMode fromApiValue(bool? value) => switch (value) {
    false => twelveHour,
    true => twentyFourHour,
    null => localeDefault,
  };
}

/// As in [UserSettings.emojiset].
@JsonEnum(fieldRename: FieldRename.kebab, alwaysCreate: true)
enum Emojiset {
  google,
  googleBlob,
  twitter,
  text,
  unknown;

  /// Get an [Emojiset] from a raw string. Throws if the string is unrecognized.
  ///
  /// Example:
  ///   'google-blob' -> Emojiset.googleBlob
  static Emojiset fromRawString(String raw) => _byRawString[raw] ?? unknown;

  // _$…EnumMap is thanks to `alwaysCreate: true` and `fieldRename: FieldRename.kebab`
  static final _byRawString = _$EmojisetEnumMap
    .map((key, value) => MapEntry(value, key));

  String toJson() => _$EmojisetEnumMap[this]!;
}

/// As in [InitialSnapshot.realmUserGroups] or [UserGroupAddEvent].
@JsonSerializable(fieldRename: FieldRename.snake)
class UserGroup {
  final int id;

  final Set<int> members;
  final Set<int> directSubgroupIds;

  String name;
  String description;

  // final int? dateCreated; // not using; ignore
  // final int? creatorId; // not using; ignore

  final bool isSystemGroup;

  // TODO(server-10): [deactivated] new in FL 290; previously no groups were deactivated
  @JsonKey(defaultValue: false)
  bool deactivated;

  // TODO(#814): GroupSettingValue canAddMembersGroup, etc.; add to update event too

  UserGroup({
    required this.id,
    required this.members,
    required this.directSubgroupIds,
    required this.name,
    required this.description,
    required this.isSystemGroup,
    required this.deactivated,
  });

  factory UserGroup.fromJson(Map<String, dynamic> json) => _$UserGroupFromJson(json);

  Map<String, dynamic> toJson() => _$UserGroupToJson(this);
}

/// As in [InitialSnapshot.realmUsers], [InitialSnapshot.realmNonActiveUsers], and [InitialSnapshot.crossRealmBots].
///
/// In the Zulip API, the items in realm_users, realm_non_active_users, and
/// cross_realm_bots are all extremely similar. They differ only in that
/// cross_realm_bots has is_system_bot.
///
/// For docs, search for "realm_users:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  // When adding a field to this class:
  //  * If a [RealmUserUpdateEvent] can update it, be sure to add
  //    that case to [RealmUserUpdateEvent] and its handler.
  //  * If the field can never change for a given Zulip user, mark it final.
  //  * (If it can change but [RealmUserUpdateEvent] doesn't cover that,
  //    then that's a bug in the API; raise it in `#api design`.)

  final int userId;
  String? deliveryEmail;
  String email;
  String fullName;
  final String dateJoined;
  bool isActive; // Really sometimes absent in /register, but we normalize that away; see [InitialSnapshot.realmUsers].
  // bool isOwner; // obsoleted by [role]; ignore
  // bool isAdmin; // obsoleted by [role]; ignore
  // bool isGuest; // obsoleted by [role]; ignore
  final bool isBot;
  final int? botType; // TODO enum
  int? botOwnerId;
  @JsonKey(unknownEnumValue: UserRole.unknown)
  UserRole role;
  String timezone;
  String? avatarUrl; // TODO(#255) distinguish null from missing, as a `JsonNullable<String>?`
  int avatarVersion;

  // null for bots, which don't have custom profile fields.
  // If null for a non-bot, equivalent to `{}` (null just written for efficiency.)
  // TODO(json_serializable): keys use plain `int.parse`, permitting hexadecimal
  @JsonKey(readValue: _readProfileData)
  Map<int, ProfileFieldUserData>? profileData;

  // This field is absent in `realm_users` and `realm_non_active_users`,
  // which contain no system bots; it's present in `cross_realm_bots`.
  @JsonKey(defaultValue: false)
  final bool isSystemBot;

  static Map<String, dynamic>? _readProfileData(Map<dynamic, dynamic> json, String key) {
    final value = (json[key] as Map<String, dynamic>?);
    // Represent `{}` as `null`, to avoid allocating a huge number
    // of LinkedHashMap data structures that we can do without.
    // A hash table is inevitably going to involve some overhead
    // (several words, at minimum), even when nothing's stored in it yet.
    return (value != null && value.isNotEmpty) ? value : null;
  }

  User({
    required this.userId,
    required this.deliveryEmail,
    required this.email,
    required this.fullName,
    required this.dateJoined,
    required this.isActive,
    required this.isBot,
    required this.botType,
    required this.botOwnerId,
    required this.role,
    required this.timezone,
    required this.avatarUrl,
    required this.avatarVersion,
    required this.profileData,
    required this.isSystemBot,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

/// As in [User.profileData].
@JsonSerializable(fieldRename: FieldRename.snake)
class ProfileFieldUserData {
  final String value;
  final String? renderedValue;

  ProfileFieldUserData({
    required this.value,
    // Unlike in most of the API bindings, we leave this constructor argument
    // optional.  That's because for most types of custom profile fields,
    // this property is always indeed absent, and because this constructor is
    // otherwise convenient to write many calls to in our test code.
    this.renderedValue,
  });

  factory ProfileFieldUserData.fromJson(Map<String, dynamic> json) =>
    _$ProfileFieldUserDataFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileFieldUserDataToJson(this);
}

/// As in [User.role].
@JsonEnum(valueField: "apiValue")
enum UserRole{
  owner(apiValue: 100),
  administrator(apiValue: 200),
  moderator(apiValue: 300),
  member(apiValue: 400),
  guest(apiValue: 600),
  unknown(apiValue: null);

  const UserRole({
    required this.apiValue,
  });

  final int? apiValue;

  int? toJson() => apiValue;

  bool isAtLeast(UserRole threshold) {
    // Roles with more privilege have lower [apiValue].
    return apiValue! <= threshold.apiValue!;
  }
}

/// A value in [InitialSnapshot.presences].
///
/// For docs, search for "presences:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class PerUserPresence {
  final int activeTimestamp;
  final int idleTimestamp;

  PerUserPresence({
    required this.activeTimestamp,
    required this.idleTimestamp,
  });

  factory PerUserPresence.fromJson(Map<String, dynamic> json) =>
    _$PerUserPresenceFromJson(json);

  Map<String, dynamic> toJson() => _$PerUserPresenceToJson(this);
}

/// As in [PerClientPresence.status] and [updatePresence].
@JsonEnum(fieldRename: FieldRename.snake, alwaysCreate: true)
enum PresenceStatus {
  active,
  idle;

  String toJson() => _$PresenceStatusEnumMap[this]!;
}

/// An item in `saved_snippets` from the initial snapshot.
///
/// For docs, search for "saved_snippets:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class SavedSnippet {
  SavedSnippet({
    required this.id,
    required this.title,
    required this.content,
    required this.dateCreated,
  });

  final int id;
  final String title;
  final String content;
  final int dateCreated;

  factory SavedSnippet.fromJson(Map<String, Object?> json) =>
    _$SavedSnippetFromJson(json);

  Map<String, dynamic> toJson() => _$SavedSnippetToJson(this);
}

/// As in `streams` in the initial snapshot.
///
/// Not called `Stream` because dart:async uses that name.
///
/// For docs, search for "if stream"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class ZulipStream {
  // When adding a field to this class:
  //  * Add it to [ChannelPropertyName] too, or add a comment there explaining
  //    why there isn't a corresponding value in that enum.
  //  * If the field can never change for a given Zulip stream, mark it final.
  //    Otherwise, make sure it gets updated on [ChannelUpdateEvent].
  //  * (If it can change but [ChannelUpdateEvent] doesn't cover that,
  //    then that's a bug in the API; raise it in `#api design`.)

  final int streamId;
  String name;

  // We don't expect `true` for this until we declare the `archived_channels`
  // client capability.
  //
  // Servers that don't send this property will only send non-archived channels;
  // default to false for those servers.
  // TODO(server-10) remove default and its comment
  // TODO(#800) remove comment about `archived_channels` client capability.
  @JsonKey(defaultValue: false)
  bool isArchived;

  String description;
  String renderedDescription;

  final int dateCreated;
  int? firstMessageId;

  int? folderId;

  bool inviteOnly;
  bool isWebPublic; // present since 2.1, according to /api/changelog
  bool historyPublicToSubscribers;
  int? messageRetentionDays;
  @JsonKey(name: 'stream_post_policy')
  ChannelPostPolicy? channelPostPolicy; // TODO(server-10) remove
  // final bool isAnnouncementOnly; // deprecated for `channelPostPolicy`; ignore

  GroupSettingValue? canAddSubscribersGroup; // TODO(server-10)
  GroupSettingValue? canDeleteAnyMessageGroup; // TODO(server-11)
  GroupSettingValue? canDeleteOwnMessageGroup; // TODO(server-11)
  GroupSettingValue? canSendMessageGroup; // TODO(server-10)
  GroupSettingValue? canSubscribeGroup; // TODO(server-10)

  bool? isRecentlyActive; // TODO(server-10)
  // TODO(server-8): added in FL 199, was previously only on [Subscription] objects
  int? streamWeeklyTraffic;

  ZulipStream({
    required this.streamId,
    required this.name,
    required this.isArchived,
    required this.description,
    required this.renderedDescription,
    required this.dateCreated,
    required this.firstMessageId,
    required this.inviteOnly,
    required this.isWebPublic,
    required this.historyPublicToSubscribers,
    required this.messageRetentionDays,
    required this.channelPostPolicy,
    required this.folderId,
    required this.canAddSubscribersGroup,
    required this.canDeleteAnyMessageGroup,
    required this.canDeleteOwnMessageGroup,
    required this.canSendMessageGroup,
    required this.canSubscribeGroup,
    required this.isRecentlyActive,
    required this.streamWeeklyTraffic,
  });

  /// Construct a plain [ZulipStream] from [subscription].
  factory ZulipStream.fromSubscription(Subscription subscription) {
    return ZulipStream(
      streamId: subscription.streamId,
      name: subscription.name,
      description: subscription.description,
      isArchived: subscription.isArchived,
      renderedDescription: subscription.renderedDescription,
      dateCreated: subscription.dateCreated,
      firstMessageId: subscription.firstMessageId,
      inviteOnly: subscription.inviteOnly,
      isWebPublic: subscription.isWebPublic,
      historyPublicToSubscribers: subscription.historyPublicToSubscribers,
      messageRetentionDays: subscription.messageRetentionDays,
      channelPostPolicy: subscription.channelPostPolicy,
      folderId: subscription.folderId,
      canAddSubscribersGroup: subscription.canAddSubscribersGroup,
      canDeleteAnyMessageGroup: subscription.canDeleteAnyMessageGroup,
      canDeleteOwnMessageGroup: subscription.canDeleteOwnMessageGroup,
      canSendMessageGroup: subscription.canSendMessageGroup,
      canSubscribeGroup: subscription.canSubscribeGroup,
      isRecentlyActive: subscription.isRecentlyActive,
      streamWeeklyTraffic: subscription.streamWeeklyTraffic,
    );
  }

  factory ZulipStream.fromJson(Map<String, dynamic> json) =>
    _$ZulipStreamFromJson(json);

  Map<String, dynamic> toJson() => _$ZulipStreamToJson(this);
}

/// The name of a property of [ZulipStream] that gets updated
/// through [ChannelUpdateEvent.property].
///
/// In Zulip event-handling code (for [ChannelUpdateEvent]),
/// we switch exhaustively on a value of this type
/// to ensure that every property in [ZulipStream] responds to the event.
@JsonEnum(fieldRename: FieldRename.snake, alwaysCreate: true)
enum ChannelPropertyName {
  // streamId is immutable
  name,
  isArchived,
  description,
  // renderedDescription is updated via its own [ChannelUpdateEvent] field
  // dateCreated is immutable
  firstMessageId,
  inviteOnly,
  // isWebPublic is updated via its own [ChannelUpdateEvent] field
  // historyPublicToSubscribers is updated via its own [ChannelUpdateEvent] field
  messageRetentionDays,
  @JsonValue('stream_post_policy')
  channelPostPolicy,
  folderId,
  canAddSubscribersGroup,
  canDeleteAnyMessageGroup,
  canDeleteOwnMessageGroup,
  canSendMessageGroup,
  canSubscribeGroup,
  isRecentlyActive,
  streamWeeklyTraffic;

  /// Get a [ChannelPropertyName] from a raw, snake-case string we recognize, else null.
  ///
  /// Example:
  ///   'invite_only' -> ChannelPropertyName.inviteOnly
  static ChannelPropertyName? fromRawString(String raw) => _byRawString[raw];

  // _$…EnumMap is thanks to `alwaysCreate: true` and `fieldRename: FieldRename.snake`
  static final _byRawString = _$ChannelPropertyNameEnumMap
    .map((key, value) => MapEntry(value, key));
}

/// Policy for which users can post to the stream.
///
/// For docs, search for "stream_post_policy"
/// in <https://zulip.com/api/get-stream-by-id>
@JsonEnum(valueField: 'apiValue')
enum ChannelPostPolicy {
  any(apiValue: 1),
  administrators(apiValue: 2),
  fullMembers(apiValue: 3),
  moderators(apiValue: 4),
  unknown(apiValue: null);

  const ChannelPostPolicy({
    required this.apiValue,
  });

  final int? apiValue;

  int? toJson() => apiValue;

  static ChannelPostPolicy fromApiValue(int value) => _byApiValue[value]!;

  static final _byApiValue = _$ChannelPostPolicyEnumMap
    .map((key, value) => MapEntry(value, key));
}

/// As in `subscriptions` in the initial snapshot.
///
/// For docs, search for "subscriptions:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class Subscription extends ZulipStream {
  // final List<int> subscribers; // we register with includeSubscribers false

  bool? desktopNotifications;
  bool? emailNotifications;
  bool? wildcardMentionsNotify;
  bool? pushNotifications;
  bool? audibleNotifications;

  bool pinToTop;
  bool isMuted;

  /// As an int that dart:ui's Color constructor will take:
  ///   <https://api.flutter.dev/flutter/dart-ui/Color/Color.html>
  @JsonKey(readValue: _readColor)
  int color;
  static Object? _readColor(Map<dynamic, dynamic> json, String key) {
    final str = (json[key] as String);
    assert(RegExp(r'^#[0-9a-f]{6}$').hasMatch(str));
    return 0xff000000 | int.parse(str.substring(1), radix: 16);
  }

  Subscription({
    required super.streamId,
    required super.name,
    required super.description,
    required super.isArchived,
    required super.renderedDescription,
    required super.dateCreated,
    required super.firstMessageId,
    required super.inviteOnly,
    required super.isWebPublic,
    required super.historyPublicToSubscribers,
    required super.messageRetentionDays,
    required super.channelPostPolicy,
    required super.folderId,
    required super.canAddSubscribersGroup,
    required super.canDeleteAnyMessageGroup,
    required super.canDeleteOwnMessageGroup,
    required super.canSendMessageGroup,
    required super.canSubscribeGroup,
    required super.isRecentlyActive,
    required super.streamWeeklyTraffic,
    required this.desktopNotifications,
    required this.emailNotifications,
    required this.wildcardMentionsNotify,
    required this.pushNotifications,
    required this.audibleNotifications,
    required this.pinToTop,
    required this.isMuted,
    required this.color,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) =>
    _$SubscriptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);
}

/// As in `channel_folders` in the initial snapshot.
///
/// For docs, search for "channel_folders:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class ChannelFolder {
  final int id;
  String name;
  int? order; // TODO(server-11); added in a later FL than the rest
  final int? dateCreated;
  final int? creatorId;
  String description;
  String renderedDescription;
  bool isArchived;

  ChannelFolder({
    required this.id,
    required this.name,
    required this.order,
    required this.dateCreated,
    required this.creatorId,
    required this.description,
    required this.renderedDescription,
    required this.isArchived,
  });

  factory ChannelFolder.fromJson(Map<String, dynamic> json) =>
    _$ChannelFolderFromJson(json);

  Map<String, dynamic> toJson() => _$ChannelFolderToJson(this);
}

@JsonEnum(fieldRename: FieldRename.snake, valueField: "apiValue")
enum UserTopicVisibilityPolicy {
  none(apiValue: 0),
  muted(apiValue: 1),
  unmuted(apiValue: 2), // TODO(server-7) newly added
  followed(apiValue: 3), // TODO(server-8) newly added
  unknown(apiValue: null); // TODO(#1074) remove this

  const UserTopicVisibilityPolicy({required this.apiValue});

  final int? apiValue;

  int? toJson() => apiValue;
}

/// Convert a Unicode emoji's Zulip "emoji code" into the
/// actual Unicode code points.
///
/// The argument corresponds to [Reaction.emojiCode] when [Reaction.emojiType]
/// is [ReactionType.unicodeEmoji].  For docs, see:
///   https://zulip.com/api/add-reaction#parameter-reaction_type
///
/// In addition to reactions, these appear in Zulip content HTML;
/// see [UnicodeEmojiNode.emojiUnicode].
String? tryParseEmojiCodeToUnicode(String emojiCode) {
  // Ported from: https://github.com/zulip/zulip-mobile/blob/c979530d6804db33310ed7d14a4ac62017432944/src/emoji/data.js#L108-L112
  // which refers to a comment in the server implementation:
  //   https://github.com/zulip/zulip/blob/63c9296d5339517450f79f176dc02d77b08020c8/zerver/models.py#L3235-L3242
  // In addition to what's in the doc linked above, that comment adds:
  //
  // > For examples, see "non_qualified" or "unified" in the following data,
  // > with "non_qualified" taking precedence when both present:
  // >   https://raw.githubusercontent.com/iamcal/emoji-data/a8174c74675355c8c6a9564516b2e961fe7257ef/emoji_pretty.json
  // > [link fixed to permalink; original comment says "master" for the commit]
  try {
    return String.fromCharCodes(emojiCode.split('-')
      .map((hex) => int.parse(hex, radix: 16)));
  } on FormatException { // thrown by `int.parse`
    return null;
  } on ArgumentError { // thrown by `String.fromCharCodes`
    return null;
  }
}

/// The topic servers understand to mean "there is no topic".
///
/// This should match
///   https://github.com/zulip/zulip/blob/6.0/zerver/actions/message_edit.py#L940
/// or similar logic at the latest `main`.
// This is hardcoded in the server, and therefore untranslated; that's
// zulip/zulip#3639.
const String kNoTopicTopic = '(no topic)';

/// The name of a Zulip topic.
// TODO(dart): Can we forbid calling Object members on this extension type?
//   (The lack of "implements Object" ought to do that, but doesn't.)
//   In particular an interpolation "foo > $topic" is a bug we'd like to catch.
// TODO(dart): Can we forbid using this extension type as a key in a Map?
//   (The lack of "implements Object" arguably should do that, but doesn't.)
//   Using as a Map key is almost certainly a bug because it won't case-fold;
//   see for example #739, #980, #1205.
extension type const TopicName(String _value) {
  /// The canonical form of the resolved-topic prefix.
  // This is RESOLVED_TOPIC_PREFIX in web:
  //   https://github.com/zulip/zulip/blob/1fac99733/web/shared/src/resolved_topic.ts
  static const resolvedTopicPrefix = '✔ ';

  /// Pattern for an arbitrary resolved-topic prefix.
  ///
  /// These always begin with [resolvedTopicPrefix]
  /// but can be weird and go on longer, like "✔ ✔✔ ".
  // This is RESOLVED_TOPIC_PREFIX_RE in web:
  //   https://github.com/zulip/zulip/blob/1fac99733/web/shared/src/resolved_topic.ts#L4-L12
  static final resolvedTopicPrefixRegexp = RegExp(r'^✔ [ ✔]*');

  /// The string this topic is identified by in the Zulip API.
  ///
  /// This should be used in constructing HTTP requests to the server,
  /// but rarely for other purposes.  See [displayName] and [canonicalize].
  String get apiName => _value;

  /// The string this topic is displayed as to the user in our UI.
  ///
  /// At the moment this always equals [apiName].
  String? get displayName => _value.isEmpty ? null : _value;

  /// The key to use for "same topic as" comparisons.
  String canonicalize() => apiName.toLowerCase();

  /// Whether the topic starts with [resolvedTopicPrefix].
  bool get isResolved => _value.startsWith(resolvedTopicPrefix);

  /// This [TopicName] plus the [resolvedTopicPrefix] prefix.
  TopicName resolve() => TopicName(resolvedTopicPrefix + _value);

  /// A [TopicName] with [resolvedTopicPrefixRegexp] stripped if present.
  TopicName unresolve() =>
    TopicName(_value.replaceFirst(resolvedTopicPrefixRegexp, ''));

  /// Whether [this] and [other] have the same canonical form,
  /// using [canonicalize].
  bool isSameAs(TopicName other) => canonicalize() == other.canonicalize();

  TopicName.fromJson(this._value);

  String toJson() => apiName;
}

/// As in [MessageBase.conversation].
///
/// Different from [MessageDestination], this information comes from
/// [getMessages] or [getEvents], identifying the conversation that contains a
/// message.
sealed class Conversation {
  /// Whether [this] and [other] refer to the same Zulip conversation.
  bool isSameAs(Conversation other);
}

/// The conversation a stream message is in.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class StreamConversation extends Conversation {
  int streamId;

  @JsonKey(name: 'subject')
  TopicName topic;

  /// The name of the channel with ID [streamId] when the message was sent.
  ///
  /// The primary reference for the name of the channel is
  /// the client's data structures about channels, at [streamId].
  /// This value may be used as a fallback when the channel is unknown.
  ///
  /// This is non-null when found in a [StreamMessage] object in the API,
  /// but may become null in the client's data structures,
  /// e.g. if the message gets moved between channels.
  @JsonKey(required: true, disallowNullValue: true)
  String? displayRecipient;

  StreamConversation(this.streamId, this.topic, {required this.displayRecipient});

  factory StreamConversation.fromJson(Map<String, dynamic> json) =>
    _$StreamConversationFromJson(json);

  @override
  bool isSameAs(Conversation other) {
    return other is StreamConversation
      && streamId == other.streamId
      && topic.isSameAs(other.topic);
  }
}

/// The conversation a DM message is in.
class DmConversation extends Conversation {
  /// The user IDs of all users in the conversation, sorted numerically.
  ///
  /// This lists the sender as well as all (other) recipients, and it
  /// lists each user just once.  In particular the self-user is always
  /// included.
  final List<int> allRecipientIds;

  DmConversation({required this.allRecipientIds})
    : assert(isSortedWithoutDuplicates(allRecipientIds.toList()));

  bool _equalIdSequences(Iterable<int> xs, Iterable<int> ys) {
    if (xs.length != ys.length) return false;
    final xs_ = xs.iterator; final ys_ = ys.iterator;
    while (xs_.moveNext() && ys_.moveNext()) {
      if (xs_.current != ys_.current) return false;
    }
    return true;
  }

  @override
  bool isSameAs(Conversation other) {
    if (other is! DmConversation) return false;
    return _equalIdSequences(allRecipientIds, other.allRecipientIds);
  }
}

/// A message or message-like object, for showing in a message list.
///
/// Other than [Message], we use this for "outbox messages",
/// representing outstanding [sendMessage] requests.
abstract class MessageBase<T extends Conversation> {
  /// The Zulip message ID.
  ///
  /// If null, the message doesn't have an ID acknowledged by the server
  /// (e.g.: a locally-echoed message).
  int? get id;

  final int senderId;
  final int timestamp;

  /// The conversation that contains this message.
  ///
  /// When implementing this, the return type should be either
  /// [StreamConversation] or [DmConversation]; it should never be
  /// [Conversation], because we expect a concrete subclass of [MessageBase]
  /// to represent either a channel message or a DM message, not both.
  T get conversation;

  const MessageBase({required this.senderId, required this.timestamp});
}

/// As in the get-messages response.
///
/// https://zulip.com/api/get-messages#response
sealed class Message<T extends Conversation> extends MessageBase<T> {
  // final String? avatarUrl; // Use [User.avatarUrl] instead; will live-update
  final String client;
  String content;
  final String contentType;

  // final List<MessageEditHistory> editHistory; // TODO handle
  @JsonKey(readValue: MessageEditState._readFromMessage, fromJson: Message._messageEditStateFromJson)
  MessageEditState editState;

  @override
  final int id;
  bool isMeMessage;
  int? lastEditTimestamp;

  @JsonKey(fromJson: _reactionsFromJson, toJson: _reactionsToJson)
  Reactions? reactions; // null is equivalent to an empty [Reactions]

  final int recipientId;
  final String senderEmail;
  final String senderFullName;
  final String senderRealmStr;

  /// Poll data if "submessages" describe a poll, `null` otherwise.
  @JsonKey(name: 'submessages', readValue: _readPoll, fromJson: Poll.fromJson, toJson: Poll.toJson)
  Poll? poll;

  String get type;

  // final List<TopicLink> topicLinks; // TODO handle
  // final string type; // handled by runtime type of object
  @JsonKey(fromJson: _flagsFromJson)
  List<MessageFlag> flags; // Unrecognized flags won't roundtrip through {to,from}Json.
  String? matchContent;
  @JsonKey(name: 'match_subject')
  String? matchTopic;

  static MessageEditState _messageEditStateFromJson(Object? json) {
    // This is a no-op so that [MessageEditState._readFromMessage]
    // can return the enum value directly.
    return json as MessageEditState;
  }

  static Reactions? _reactionsFromJson(Object? json) {
    final list = (json as List<Object?>);
    return list.isNotEmpty ? Reactions.fromJson(list) : null;
  }

  static Object _reactionsToJson(Reactions? value) {
    return value ?? [];
  }

  static List<MessageFlag> _flagsFromJson(Object? json) {
    final list = json as List<Object?>;
    return list.map((raw) => MessageFlag.fromRawString(raw as String)).toList();
  }

  static Poll? _readPoll(Map<Object?, Object?> json, String key) {
    return Submessage.parseSubmessagesJson(
      json['submessages'] as List<Object?>? ?? [],
      messageSenderId: (json['sender_id'] as num).toInt(),
    );
  }

  Message({
    required this.client,
    required this.content,
    required this.contentType,
    required this.editState,
    required this.id,
    required this.isMeMessage,
    required this.lastEditTimestamp,
    required this.reactions,
    required this.recipientId,
    required this.senderEmail,
    required this.senderFullName,
    required super.senderId,
    required this.senderRealmStr,
    required super.timestamp,
    required this.flags,
    required this.matchContent,
    required this.matchTopic,
  });

  // TODO(dart): This has to be a static method, because factories/constructors
  //   do not support type parameters: https://github.com/dart-lang/language/issues/647
  static Message fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    if (type == 'stream') return StreamMessage.fromJson(json);
    if (type == 'private') return DmMessage.fromJson(json);
    throw Exception("Message.fromJson: unexpected message type $type");
  }

  Map<String, dynamic> toJson();
}

/// https://zulip.com/api/update-message-flags#available-flags
@JsonEnum(fieldRename: FieldRename.snake, alwaysCreate: true)
enum MessageFlag {
  read,
  starred,
  collapsed,
  mentioned,
  wildcardMentioned,
  hasAlertWord,
  historical,
  unknown;

  /// Get a [MessageFlag] from a raw, snake-case string.
  ///
  /// Will be [MessageFlag.unknown] if we don't recognize the string.
  ///
  /// Example:
  ///   'wildcard_mentioned' -> Flag.wildcardMentioned
  static MessageFlag fromRawString(String raw) => _byRawString[raw] ?? unknown;

  // _$…EnumMap is thanks to `alwaysCreate: true` and `fieldRename: FieldRename.snake`
  static final _byRawString = _$MessageFlagEnumMap.map((key, value) => MapEntry(value, key));

  String toJson() => _$MessageFlagEnumMap[this]!;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class StreamMessage extends Message<StreamConversation> {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'stream';

  @JsonKey(includeToJson: true)
  int get streamId => conversation.streamId;

  // The topic/subject is documented to be present on DMs too, just empty.
  // We ignore it on DMs; if a future server introduces distinct topics in DMs,
  // that will need new UI that we'll design then as part of that feature,
  // and ignoring the topics seems as good a fallback behavior as any.
  @JsonKey(name: 'subject', includeToJson: true)
  TopicName get topic => conversation.topic;

  @JsonKey(includeToJson: true)
  String? get displayRecipient => conversation.displayRecipient;

  @override
  @JsonKey(readValue: _readConversation, includeToJson: false)
  StreamConversation conversation;

  static Map<String, dynamic> _readConversation(Map<dynamic, dynamic> json, String key) {
    return json as Map<String, dynamic>;
  }

  StreamMessage({
    required super.client,
    required super.content,
    required super.contentType,
    required super.editState,
    required super.id,
    required super.isMeMessage,
    required super.lastEditTimestamp,
    required super.reactions,
    required super.recipientId,
    required super.senderEmail,
    required super.senderFullName,
    required super.senderId,
    required super.senderRealmStr,
    required super.timestamp,
    required super.flags,
    required super.matchContent,
    required super.matchTopic,
    required this.conversation,
  });

  factory StreamMessage.fromJson(Map<String, dynamic> json) =>
    _$StreamMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StreamMessageToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DmMessage extends Message<DmConversation> {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'private';

  /// The user IDs of all users in the thread, sorted numerically, as in
  /// `display_recipient` from the server.
  ///
  /// The other fields on `display_recipient` are ignored and won't roundtrip.
  ///
  /// This lists the sender as well as all (other) recipients, and it
  /// lists each user just once.  In particular the self-user is always
  /// included.
  // TODO(server): Document that it's all users.  That statement is based on
  //   reverse-engineering notes in zulip-mobile:src/api/modelTypes.js at PmMessage.
  @JsonKey(name: 'display_recipient', toJson: _allRecipientIdsToJson, includeToJson: true)
  List<int> get allRecipientIds => conversation.allRecipientIds;

  @override
  @JsonKey(name: 'display_recipient', fromJson: _conversationFromJson, includeToJson: false)
  final DmConversation conversation;

  static List<Map<String, dynamic>> _allRecipientIdsToJson(List<int> allRecipientIds) {
    return allRecipientIds.map((element) => {'id': element}).toList();
  }

  static DmConversation _conversationFromJson(List<dynamic> json) {
    return DmConversation(allRecipientIds: json.map(
      (element) => ((element as Map<String, dynamic>)['id'] as num).toInt()
    ).toList(growable: false)
     ..sort());
  }

  DmMessage({
    required super.client,
    required super.content,
    required super.contentType,
    required super.editState,
    required super.id,
    required super.isMeMessage,
    required super.lastEditTimestamp,
    required super.reactions,
    required super.recipientId,
    required super.senderEmail,
    required super.senderFullName,
    required super.senderId,
    required super.senderRealmStr,
    required super.timestamp,
    required super.flags,
    required super.matchContent,
    required super.matchTopic,
    required this.conversation,
  });

  factory DmMessage.fromJson(Map<String, dynamic> json) =>
    _$DmMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DmMessageToJson(this);
}

enum MessageEditState {
  none,
  edited,
  moved;

  /// Whether the given topic move reflected either a "resolve topic"
  /// or "unresolve topic" operation.
  ///
  /// The Zulip "resolved topics" feature is implemented by renaming the topic;
  /// but for purposes of [Message.editState], we want to ignore such renames.
  /// This method identifies topic moves that should be ignored in that context.
  static bool topicMoveWasResolveOrUnresolve(TopicName topic, TopicName prevTopic) {
    // Implemented to match web; see analyze_edit_history in zulip/zulip's
    // web/src/message_list_view.ts.
    //
    // Also, this is a hot codepath (decoding messages, a high-volume type of
    // data we get from the server), so we avoid calling [canonicalize] and
    // using [TopicName.resolvedTopicPrefixRegexp], to be performance-sensitive.
    // Discussion:
    //   https://github.com/zulip/zulip-flutter/pull/1242#discussion_r1917592157
    if (topic.apiName.startsWith(TopicName.resolvedTopicPrefix)
        && topic.apiName.substring(TopicName.resolvedTopicPrefix.length) == prevTopic.apiName) {
      return true;
    }

    if (prevTopic.apiName.startsWith(TopicName.resolvedTopicPrefix)
        && prevTopic.apiName.substring(TopicName.resolvedTopicPrefix.length) == topic.apiName) {
      return true;
    }

    return false;
  }

  static MessageEditState _readFromMessage(Map<dynamic, dynamic> json, String key) {
    // Adapted from `analyze_edit_history` in the web app:
    //   https://github.com/zulip/zulip/blob/c31cebbf68a93927d41e9947427c2dd4d46503e3/web/src/message_list_view.js#L68-L118
    final editHistory = json['edit_history'] as List<dynamic>?;
    final lastEditTimestamp = json['last_edit_timestamp'] as int?;
    if (editHistory == null) {
      return (lastEditTimestamp != null)
        ? MessageEditState.edited
        : MessageEditState.none;
    }

    // Edit history should never be empty whenever it is present
    assert(editHistory.isNotEmpty);

    bool hasMoved = false;
    for (final entry in editHistory) {
      if (entry['prev_content'] != null) {
        return MessageEditState.edited;
      }

      if (entry['prev_stream'] != null) {
        hasMoved = true;
        continue;
      }

      final prevTopicStr = entry['prev_topic'] as String?;
      if (prevTopicStr != null) {
        final prevTopic = TopicName.fromJson(prevTopicStr);
        final topic = TopicName.fromJson(entry['topic'] as String);
        hasMoved |= !topicMoveWasResolveOrUnresolve(topic, prevTopic);
      }
    }

    if (hasMoved) return MessageEditState.moved;

    // This can happen when a topic is resolved but nothing else has been edited
    return MessageEditState.none;
  }
}

/// As in [updateMessage] or [UpdateMessageEvent.propagateMode].
@JsonEnum(fieldRename: FieldRename.snake, alwaysCreate: true)
enum PropagateMode {
  changeOne,
  changeLater,
  changeAll;

  String toJson() => _$PropagateModeEnumMap[this]!;

  /// Get a [PropagateMode] from a raw string. Throws if the string is
  /// unrecognized.
  ///
  /// Example:
  ///   'change_one' -> PropagateMode.changeOne
  static PropagateMode fromRawString(String raw) => _byRawString[raw]!;

  // _$…EnumMap is thanks to `alwaysCreate: true` and `fieldRename: FieldRename.snake`
  static final _byRawString = _$PropagateModeEnumMap
    .map((key, value) => MapEntry(value, key));
}
