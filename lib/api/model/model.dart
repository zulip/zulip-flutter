import 'package:json_annotation/json_annotation.dart';

import 'events.dart';
import 'initial_snapshot.dart';
import 'reaction.dart';
import 'submessage.dart';

export 'json.dart' show JsonNullable;
export 'reaction.dart';

part 'model.g.dart';

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
  final bool? displayInProfileSummary; // TODO(server-6)

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
  pronouns(apiValue: 8), // TODO(server-6) newly added
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

/// The name of a user setting that has a property in [UserSettings].
///
/// In Zulip event-handling code (for [UserSettingsUpdateEvent]),
/// we switch exhaustively on a value of this type
/// to ensure that every setting in [UserSettings] responds to the event.
@JsonEnum(fieldRename: FieldRename.snake, alwaysCreate: true)
enum UserSettingName {
  twentyFourHourTime,
  displayEmojiReactionUsers,
  emojiset;

  /// Get a [UserSettingName] from a raw, snake-case string we recognize, else null.
  ///
  /// Example:
  ///   'display_emoji_reaction_users' -> UserSettingName.displayEmojiReactionUsers
  static UserSettingName? fromRawString(String raw) => _byRawString[raw];

  // _$…EnumMap is thanks to `alwaysCreate: true` and `fieldRename: FieldRename.snake`
  static final _byRawString = _$UserSettingNameEnumMap
    .map((key, value) => MapEntry(value, key));
}

/// As in [UserSettings.emojiset].
@JsonEnum(fieldRename: FieldRename.kebab, alwaysCreate: true)
enum Emojiset {
  google,
  googleBlob,
  twitter,
  text;

  /// Get an [Emojiset] from a raw string. Throws if the string is unrecognized.
  ///
  /// Example:
  ///   'google-blob' -> Emojiset.googleBlob
  static Emojiset fromRawString(String raw) => _byRawString[raw]!;

  // _$…EnumMap is thanks to `alwaysCreate: true` and `fieldRename: FieldRename.kebab`
  static final _byRawString = _$EmojisetEnumMap
    .map((key, value) => MapEntry(value, key));
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
  bool? isBillingAdmin; // TODO(server-5)
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

  @JsonKey(readValue: _readIsSystemBot)
  final bool isSystemBot;

  static Map<String, dynamic>? _readProfileData(Map<dynamic, dynamic> json, String key) {
    final value = (json[key] as Map<String, dynamic>?);
    // Represent `{}` as `null`, to avoid allocating a huge number
    // of LinkedHashMap data structures that we can do without.
    // A hash table is inevitably going to involve some overhead
    // (several words, at minimum), even when nothing's stored in it yet.
    return (value != null && value.isNotEmpty) ? value : null;
  }

  static bool _readIsSystemBot(Map<dynamic, dynamic> json, String key) {
    // This field is absent in `realm_users` and `realm_non_active_users`,
    // which contain no system bots; it's present in `cross_realm_bots`.
    return (json[key] as bool?)
        ?? (json['is_cross_realm_bot'] as bool?) // TODO(server-5): renamed to `is_system_bot`
        ?? false;
  }

  User({
    required this.userId,
    required this.deliveryEmail,
    required this.email,
    required this.fullName,
    required this.dateJoined,
    required this.isActive,
    required this.isBillingAdmin,
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
  String description;
  String renderedDescription;

  final int dateCreated;
  int? firstMessageId;

  bool inviteOnly;
  bool isWebPublic; // present since 2.1, according to /api/changelog
  bool historyPublicToSubscribers;
  int? messageRetentionDays;
  @JsonKey(name: 'stream_post_policy')
  ChannelPostPolicy channelPostPolicy;
  // final bool isAnnouncementOnly; // deprecated for `channelPostPolicy`; ignore

  // GroupSettingsValue canRemoveSubscribersGroup; // TODO(#814)

  // TODO(server-8): added in FL 199, was previously only on [Subscription] objects
  int? streamWeeklyTraffic;

  ZulipStream({
    required this.streamId,
    required this.name,
    required this.description,
    required this.renderedDescription,
    required this.dateCreated,
    required this.firstMessageId,
    required this.inviteOnly,
    required this.isWebPublic,
    required this.historyPublicToSubscribers,
    required this.messageRetentionDays,
    required this.channelPostPolicy,
    required this.streamWeeklyTraffic,
  });

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
  // canRemoveSubscribersGroup, // TODO(#814)
  // canRemoveSubscribersGroupId, // TODO(#814) handle // TODO(server-8) remove
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
  // final bool? inHomeView; // deprecated; ignore

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
    required super.renderedDescription,
    required super.dateCreated,
    required super.firstMessageId,
    required super.inviteOnly,
    required super.isWebPublic,
    required super.historyPublicToSubscribers,
    required super.messageRetentionDays,
    required super.channelPostPolicy,
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

/// As in the get-messages response.
///
/// https://zulip.com/api/get-messages#response
sealed class Message {
  // final String? avatarUrl; // Use [User.avatarUrl] instead; will live-update
  final String client;
  String content;
  final String contentType;

  // final List<MessageEditHistory> editHistory; // TODO handle
  @JsonKey(readValue: MessageEditState._readFromMessage, fromJson: Message._messageEditStateFromJson)
  MessageEditState editState;

  final int id;
  bool isMeMessage;
  int? lastEditTimestamp;

  @JsonKey(fromJson: _reactionsFromJson, toJson: _reactionsToJson)
  Reactions? reactions; // null is equivalent to an empty [Reactions]

  final int recipientId;
  final String senderEmail;
  final String senderFullName;
  final int senderId;
  final String senderRealmStr;

  /// Poll data if "submessages" describe a poll, `null` otherwise.
  @JsonKey(name: 'submessages', readValue: _readPoll, fromJson: Poll.fromJson, toJson: Poll.toJson)
  Poll? poll;

  final int timestamp;
  String get type;

  // final List<TopicLink> topicLinks; // TODO handle
  // final string type; // handled by runtime type of object
  @JsonKey(fromJson: _flagsFromJson)
  List<MessageFlag> flags; // Unrecognized flags won't roundtrip through {to,from}Json.
  final String? matchContent;
  @JsonKey(name: 'match_subject')
  final String? matchTopic;

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
    required this.senderId,
    required this.senderRealmStr,
    required this.timestamp,
    required this.flags,
    required this.matchContent,
    required this.matchTopic,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
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

/// The name of a Zulip topic.
// TODO(dart): Can we forbid calling Object members on this extension type?
//   (The lack of "implements Object" ought to do that, but doesn't.)
//   In particular an interpolation "foo > $topic" is a bug we'd like to catch.
// TODO(dart): Can we forbid using this extension type as a key in a Map?
//   (The lack of "implements Object" arguably should do that, but doesn't.)
//   Using as a Map key is almost certainly a bug because it won't case-fold;
//   see for example #739, #980, #1205.
extension type const TopicName(String _value) {
  /// The string this topic is identified by in the Zulip API.
  ///
  /// This should be used in constructing HTTP requests to the server,
  /// but rarely for other purposes.  See [displayName] and [canonicalize].
  String get apiName => _value;

  /// The string this topic is displayed as to the user in our UI.
  ///
  /// At the moment this always equals [apiName].
  /// In the future this will become null for the "general chat" topic (#1250),
  /// so that UI code can identify when it needs to represent the topic
  /// specially in the way prescribed for "general chat".
  // TODO(#1250) carry out that plan
  String get displayName => _value;

  /// The key to use for "same topic as" comparisons.
  String canonicalize() => apiName.toLowerCase();

  TopicName.fromJson(this._value);

  String toJson() => apiName;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class StreamMessage extends Message {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'stream';

  // This is not nullable API-wise, but if the message moves across channels,
  // [displayRecipient] still refers to the original channel and it has to be
  // invalidated.
  @JsonKey(required: true, disallowNullValue: true)
  String? displayRecipient;

  int streamId;

  // The topic/subject is documented to be present on DMs too, just empty.
  // We ignore it on DMs; if a future server introduces distinct topics in DMs,
  // that will need new UI that we'll design then as part of that feature,
  // and ignoring the topics seems as good a fallback behavior as any.
  @JsonKey(name: 'subject')
  TopicName topic;

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
    required this.displayRecipient,
    required this.streamId,
    required this.topic,
  });

  factory StreamMessage.fromJson(Map<String, dynamic> json) =>
    _$StreamMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StreamMessageToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DmRecipient {
  final int id;
  final String email;
  final String fullName;

  // final String? shortName; // obsolete, ignore
  // final bool? isMirrorDummy; // obsolete, ignore

  DmRecipient({required this.id, required this.email, required this.fullName});

  factory DmRecipient.fromJson(Map<String, dynamic> json) =>
    _$DmRecipientFromJson(json);

  Map<String, dynamic> toJson() => _$DmRecipientToJson(this);

  @override
  String toString() => 'DmRecipient(id: $id, email: $email, fullName: $fullName)';

  @override
  bool operator ==(Object other) {
    if (other is! DmRecipient) return false;
    return other.id == id && other.email == email && other.fullName == fullName;
  }

  @override
  int get hashCode => Object.hash('DmRecipient', id, email, fullName);
}

class DmRecipientListConverter extends JsonConverter<List<DmRecipient>, List<dynamic>> {
  const DmRecipientListConverter();

  @override
  List<DmRecipient> fromJson(List<dynamic> json) {
    return json.map((e) => DmRecipient.fromJson(e as Map<String, dynamic>))
      .toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  List<dynamic> toJson(List<DmRecipient> object) => object;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DmMessage extends Message {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'private';

  /// The `display_recipient` from the server, sorted by user ID numerically.
  ///
  /// This lists the sender as well as all (other) recipients, and it
  /// lists each user just once.  In particular the self-user is always
  /// included.
  ///
  /// Note the data here is not updated on changes to the users, so everything
  /// other than the user IDs may be stale.
  /// Consider using [allRecipientIds] instead, and getting user details
  /// from the store.
  // TODO(server): Document that it's all users.  That statement is based on
  //   reverse-engineering notes in zulip-mobile:src/api/modelTypes.js at PmMessage.
  @DmRecipientListConverter()
  final List<DmRecipient> displayRecipient;

  /// The user IDs of all users in the thread, sorted numerically.
  ///
  /// This lists the sender as well as all (other) recipients, and it
  /// lists each user just once.  In particular the self-user is always
  /// included.
  ///
  /// This is a result of [List.map], so it has an efficient `length`.
  Iterable<int> get allRecipientIds => displayRecipient.map((e) => e.id);

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
    required this.displayRecipient,
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

  // Adapted from the shared code:
  //   https://github.com/zulip/zulip/blob/1fac99733/web/shared/src/resolved_topic.ts
  // The canonical resolved-topic prefix.
  static const String _resolvedTopicPrefix = '✔ ';

  /// Whether the given topic move reflected either a "resolve topic"
  /// or "unresolve topic" operation.
  ///
  /// The Zulip "resolved topics" feature is implemented by renaming the topic;
  /// but for purposes of [Message.editState], we want to ignore such renames.
  /// This method identifies topic moves that should be ignored in that context.
  static bool topicMoveWasResolveOrUnresolve(TopicName topic, TopicName prevTopic) {
    if (topic.apiName.startsWith(_resolvedTopicPrefix)
        && topic.apiName.substring(_resolvedTopicPrefix.length) == prevTopic.apiName) {
      return true;
    }

    if (prevTopic.apiName.startsWith(_resolvedTopicPrefix)
        && prevTopic.apiName.substring(_resolvedTopicPrefix.length) == topic.apiName) {
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

      // TODO(server-5) prev_subject was the old name of prev_topic on pre-5.0 servers
      final prevTopicStr = (entry['prev_topic'] ?? entry['prev_subject']) as String?;
      final prevTopic = prevTopicStr == null ? null : TopicName.fromJson(prevTopicStr);
      final topicStr = entry['topic'] as String?;
      final topic = topicStr == null ? null : TopicName.fromJson(topicStr);
      if (prevTopic != null) {
        // TODO(server-5) pre-5.0 servers do not have the 'topic' field
        if (topic == null) {
          hasMoved = true;
        } else {
          hasMoved |= !topicMoveWasResolveOrUnresolve(topic, prevTopic);
        }
      }
    }

    if (hasMoved) return MessageEditState.moved;

    // This can happen when a topic is resolved but nothing else has been edited
    return MessageEditState.none;
  }
}
