import 'package:json_annotation/json_annotation.dart';

import 'reaction.dart';

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
    json.map((k, v) => MapEntry(k, CustomProfileFieldChoiceDataItem.fromJson(v)));
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
  final int userId;
  @JsonKey(name: 'delivery_email')
  String? deliveryEmailStaleDoNotUse; // TODO see [RealmUserUpdateEvent.deliveryEmail]
  String email;
  String fullName;
  String dateJoined;
  bool isActive; // Really sometimes absent in /register, but we normalize that away; see [InitialSnapshot.realmUsers].
  bool isOwner;
  bool isAdmin;
  bool isGuest;
  bool? isBillingAdmin; // TODO(server-5)
  bool isBot;
  int? botType; // TODO enum
  int? botOwnerId;
  @JsonKey(unknownEnumValue: UserRole.unknown)
  UserRole role;
  String timezone;
  String? avatarUrl; // TODO distinguish null from missing https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20omitted.20vs.2E.20null.20in.20JSON/near/1551759
  int avatarVersion;

  // null for bots, which don't have custom profile fields.
  // If null for a non-bot, equivalent to `{}` (null just written for efficiency.)
  // TODO(json_serializable): keys use plain `int.parse`, permitting hexadecimal
  @JsonKey(readValue: _readProfileData)
  Map<int, ProfileFieldUserData>? profileData;

  @JsonKey(readValue: _readIsSystemBot)
  bool isSystemBot;

  static Map<String, dynamic>? _readProfileData(Map json, String key) {
    final value = (json[key] as Map<String, dynamic>?);
    // Represent `{}` as `null`, to avoid allocating a huge number
    // of LinkedHashMap data structures that we can do without.
    // A hash table is inevitably going to involve some overhead
    // (several words, at minimum), even when nothing's stored in it yet.
    return (value != null && value.isNotEmpty) ? value : null;
  }

  static bool _readIsSystemBot(Map json, String key) {
    // This field is absent in `realm_users` and `realm_non_active_users`,
    // which contain no system bots; it's present in `cross_realm_bots`.
    return json[key]
        ?? json['is_cross_realm_bot'] // TODO(server-5): renamed to `is_system_bot`
        ?? false;
  }

  User({
    required this.userId,
    required this.deliveryEmailStaleDoNotUse,
    required this.email,
    required this.fullName,
    required this.dateJoined,
    required this.isActive,
    required this.isOwner,
    required this.isAdmin,
    required this.isGuest,
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
}

/// As in `streams` in the initial snapshot.
///
/// Not called `Stream` because dart:async uses that name.
///
/// For docs, search for "if stream"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class ZulipStream {
  final int streamId;
  final String name;
  final String description;
  final String renderedDescription;

  final int dateCreated;
  final int? firstMessageId;

  final bool inviteOnly;
  final bool isWebPublic; // present since 2.1, according to /api/changelog
  final bool historyPublicToSubscribers;
  final int? messageRetentionDays;

  final StreamPostPolicy streamPostPolicy;
  // final bool isAnnouncementOnly; // deprecated for `streamPostPolicy`; ignore

  // TODO(server-6): `canRemoveSubscribersGroupId` added in FL 142
  // TODO(server-8): in FL 197 renamed to `canRemoveSubscribersGroup`
  @JsonKey(readValue: _readCanRemoveSubscribersGroup)
  final int? canRemoveSubscribersGroup;

  // TODO(server-8): added in FL 199, was previously only on [Subscription] objects
  final int? streamWeeklyTraffic;

  static int? _readCanRemoveSubscribersGroup(Map json, String key) {
    return json[key] ?? json['can_remove_subscribers_group_id'];
  }

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
    required this.streamPostPolicy,
    required this.canRemoveSubscribersGroup,
    required this.streamWeeklyTraffic,
  });

  factory ZulipStream.fromJson(Map<String, dynamic> json) =>
    _$ZulipStreamFromJson(json);

  Map<String, dynamic> toJson() => _$ZulipStreamToJson(this);
}

/// Policy for which users can post to the stream.
///
/// For docs, search for "stream_post_policy"
/// in <https://zulip.com/api/get-stream-by-id>
@JsonEnum(valueField: 'apiValue')
enum StreamPostPolicy {
  any(apiValue: 1),
  administrators(apiValue: 2),
  fullMembers(apiValue: 3),
  moderators(apiValue: 4),
  unknown(apiValue: null);

  const StreamPostPolicy({
    required this.apiValue,
  });

  final int? apiValue;

  int? toJson() => apiValue;
}

/// As in `subscriptions` in the initial snapshot.
///
/// For docs, search for "subscriptions:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class Subscription extends ZulipStream {
  // final List<int> subscribers; // we register with includeSubscribers false

  final bool? desktopNotifications;
  final bool? emailNotifications;
  final bool? wildcardMentionsNotify;
  final bool? pushNotifications;
  final bool? audibleNotifications;

  final bool pinToTop;
  final bool isMuted;
  // final bool? inHomeView; // deprecated; ignore

  final String color;

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
    required super.streamPostPolicy,
    required super.canRemoveSubscribersGroup,
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

/// As in the get-messages response.
///
/// https://zulip.com/api/get-messages#response
sealed class Message {
  // final String? avatarUrl; // Use [User.avatarUrl] instead; will live-update
  final String client;
  String content;
  final String contentType;

  // final List<MessageEditHistory> editHistory; // TODO handle
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
  final String subject; // TODO call it "topic" internally; also similar others
  // final List<string> submessages; // TODO handle
  final int timestamp;
  String get type;

  // final List<TopicLink> topicLinks; // TODO handle
  // final string type; // handled by runtime type of object
  @JsonKey(fromJson: _flagsFromJson)
  List<MessageFlag> flags; // Unrecognized flags won't roundtrip through {to,from}Json.
  final String? matchContent;
  final String? matchSubject;

  static Reactions? _reactionsFromJson(dynamic json) {
    final list = (json as List<dynamic>);
    return list.isNotEmpty ? Reactions.fromJson(list) : null;
  }

  static Object _reactionsToJson(Reactions? value) {
    return value ?? [];
  }

  static List<MessageFlag> _flagsFromJson(dynamic json) {
    final list = json as List<dynamic>;
    return list.map((raw) => MessageFlag.fromRawString(raw as String)).toList();
  }

  Message({
    required this.client,
    required this.content,
    required this.contentType,
    required this.id,
    required this.isMeMessage,
    required this.lastEditTimestamp,
    required this.reactions,
    required this.recipientId,
    required this.senderEmail,
    required this.senderFullName,
    required this.senderId,
    required this.senderRealmStr,
    required this.subject,
    required this.timestamp,
    required this.flags,
    required this.matchContent,
    required this.matchSubject,
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

@JsonSerializable(fieldRename: FieldRename.snake)
class StreamMessage extends Message {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'stream';

  final String displayRecipient;
  final int streamId;

  StreamMessage({
    required super.client,
    required super.content,
    required super.contentType,
    required super.id,
    required super.isMeMessage,
    required super.lastEditTimestamp,
    required super.reactions,
    required super.recipientId,
    required super.senderEmail,
    required super.senderFullName,
    required super.senderId,
    required super.senderRealmStr,
    required super.subject,
    required super.timestamp,
    required super.flags,
    required super.matchContent,
    required super.matchSubject,
    required this.displayRecipient,
    required this.streamId,
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
  List<DmRecipient> fromJson(List json) {
    return json.map((e) => DmRecipient.fromJson(e as Map<String, dynamic>))
      .toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  List toJson(List<DmRecipient> object) => object;
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
    required super.id,
    required super.isMeMessage,
    required super.lastEditTimestamp,
    required super.reactions,
    required super.recipientId,
    required super.senderEmail,
    required super.senderFullName,
    required super.senderId,
    required super.senderRealmStr,
    required super.subject,
    required super.timestamp,
    required super.flags,
    required super.matchContent,
    required super.matchSubject,
    required this.displayRecipient,
  });

  factory DmMessage.fromJson(Map<String, dynamic> json) =>
    _$DmMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DmMessageToJson(this);
}
