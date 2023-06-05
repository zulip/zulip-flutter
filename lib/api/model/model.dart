import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

/// As in [InitialSnapshot.customProfileFields].
///
/// For docs, search for "custom_profile_fields:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class CustomProfileField {
  final int id;
  final int type; // TODO enum; also TODO(server-6) a value added
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

@JsonSerializable(fieldRename: FieldRename.snake)
class ProfileFieldUserData {
  final String value;
  final String? renderedValue;

  ProfileFieldUserData({required this.value, this.renderedValue});

  factory ProfileFieldUserData.fromJson(Map<String, dynamic> json) =>
    _$ProfileFieldUserDataFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileFieldUserDataToJson(this);
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
  int role; // TODO enum
  String timezone;
  String? avatarUrl; // TODO distinguish null from missing https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20omitted.20vs.2E.20null.20in.20JSON/near/1551759
  int avatarVersion;
  // null for bots, which don't have custom profile fields.
  // If null for a non-bot, equivalent to `{}` (null just written for efficiency.)
  @JsonKey(readValue: _readProfileData)
  Map<int, ProfileFieldUserData>? profileData;
  @JsonKey(readValue: _readIsSystemBot)
  bool? isSystemBot; // TODO(server-5)

  static Map<String, dynamic>? _readProfileData(Map json, String key) {
    final value = (json[key] as Map<String, dynamic>?);
    // Represent `{}` as `null`, to avoid allocating a huge number
    // of LinkedHashMap data structures that we can do without.
    // A hash table is inevitably going to involve some overhead
    // (several words, at minimum), even when nothing's stored in it yet.
    return (value != null && value.isNotEmpty) ? value : null;
  }

  static bool? _readIsSystemBot(Map json, String key) {
    return json[key] ?? json['is_cross_realm_bot'];
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
    this.botType,
    this.botOwnerId,
    required this.role,
    required this.timezone,
    required this.avatarUrl,
    required this.avatarVersion,
    this.profileData,
    this.isSystemBot,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
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

  final int streamPostPolicy; // TODO enum
  // final bool isAnnouncementOnly; // deprecated; ignore

  final int? canRemoveSubscribersGroupId; // TODO(server-6)

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
    required this.canRemoveSubscribersGroupId,
  });

  factory ZulipStream.fromJson(Map<String, dynamic> json) =>
    _$ZulipStreamFromJson(json);

  Map<String, dynamic> toJson() => _$ZulipStreamToJson(this);
}

/// As in `subscriptions` in the initial snapshot.
///
/// For docs, search for "subscriptions:"
/// in <https://zulip.com/api/register-queue>.
@JsonSerializable(fieldRename: FieldRename.snake)
class Subscription {
  // First, fields that are about the stream and not the user's relation to it.
  // These are largely the same as in [ZulipStream].

  final int streamId;
  final String name;
  final String description;
  final String renderedDescription;

  final int dateCreated;
  final int? firstMessageId;
  final int? streamWeeklyTraffic;

  final bool inviteOnly;
  final bool? isWebPublic; // TODO(server-??): doc doesn't say when added
  final bool historyPublicToSubscribers;
  final int? messageRetentionDays;
  // final List<int> subscribers; // we register with includeSubscribers false

  final int streamPostPolicy; // TODO enum
  // final bool? isAnnouncementOnly; // deprecated; ignore
  final String emailAddress;

  final int? canRemoveSubscribersGroupId; // TODO(server-6)

  // Then, fields that are specific to the subscription,
  // i.e. the user's relationship to the stream.

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
    required this.streamId,
    required this.name,
    required this.description,
    required this.renderedDescription,
    required this.dateCreated,
    required this.inviteOnly,
    this.desktopNotifications,
    this.emailNotifications,
    this.wildcardMentionsNotify,
    this.pushNotifications,
    this.audibleNotifications,
    required this.pinToTop,
    required this.emailAddress,
    required this.isMuted,
    this.isWebPublic,
    required this.color,
    required this.streamPostPolicy,
    this.messageRetentionDays,
    required this.historyPublicToSubscribers,
    this.firstMessageId,
    this.streamWeeklyTraffic,
    this.canRemoveSubscribersGroupId,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) =>
    _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);
}

/// As in the get-messages response.
///
/// https://zulip.com/api/get-messages#response
abstract class Message {
  final String? avatarUrl;
  final String client;
  final String content;
  final String contentType;

  // final List<MessageEditHistory> editHistory; // TODO handle
  final int id;
  final bool isMeMessage;
  final int? lastEditTimestamp;

  // final List<Reaction> reactions; // TODO handle
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
  final List<String> flags; // TODO enum
  final String? matchContent;
  final String? matchSubject;

  Message({
    this.avatarUrl,
    required this.client,
    required this.content,
    required this.contentType,
    required this.id,
    required this.isMeMessage,
    this.lastEditTimestamp,
    required this.recipientId,
    required this.senderEmail,
    required this.senderFullName,
    required this.senderId,
    required this.senderRealmStr,
    required this.subject,
    required this.timestamp,
    required this.flags,
    this.matchContent,
    this.matchSubject,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    if (type == 'stream') return StreamMessage.fromJson(json);
    if (type == 'private') return DmMessage.fromJson(json);
    throw Exception("Message.fromJson: unexpected message type $type");
  }

  Map<String, dynamic> toJson();
}

@JsonSerializable(fieldRename: FieldRename.snake)
class StreamMessage extends Message {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'stream';

  final String displayRecipient;
  final int streamId;

  StreamMessage({
    super.avatarUrl,
    required super.client,
    required super.content,
    required super.contentType,
    required super.id,
    required super.isMeMessage,
    super.lastEditTimestamp,
    required super.recipientId,
    required super.senderEmail,
    required super.senderFullName,
    required super.senderId,
    required super.senderRealmStr,
    required super.subject,
    required super.timestamp,
    required super.flags,
    super.matchContent,
    super.matchSubject,
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
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DmMessage extends Message {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'private';

  final List<DmRecipient> displayRecipient;

  DmMessage({
    super.avatarUrl,
    required super.client,
    required super.content,
    required super.contentType,
    required super.id,
    required super.isMeMessage,
    super.lastEditTimestamp,
    required super.recipientId,
    required super.senderEmail,
    required super.senderFullName,
    required super.senderId,
    required super.senderRealmStr,
    required super.subject,
    required super.timestamp,
    required super.flags,
    super.matchContent,
    super.matchSubject,
    required this.displayRecipient,
  });

  factory DmMessage.fromJson(Map<String, dynamic> json) =>
    _$DmMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DmMessageToJson(this);
}
