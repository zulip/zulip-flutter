import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_color_models/flutter_color_models.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../widgets/color.dart';
import 'events.dart';
import 'initial_snapshot.dart';
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
  final String id;
  final String name;
  final String sourceUrl;
  final String? stillUrl;
  final bool deactivated;
  final int? authorId;

  RealmEmojiItem({
    required this.id,
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

  static int? _readCanRemoveSubscribersGroup(Map<dynamic, dynamic> json, String key) {
    return (json[key] as int?)
      ?? (json['can_remove_subscribers_group_id'] as int?);
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
  int get color => _color;
  int _color;
  set color(int value) {
    _color = value;
    _swatch = null;
  }
  static Object? _readColor(Map<dynamic, dynamic> json, String key) {
    final str = (json[key] as String);
    assert(RegExp(r'^#[0-9a-f]{6}$').hasMatch(str));
    return 0xff000000 | int.parse(str.substring(1), radix: 16);
  }

  StreamColorSwatch? _swatch;
  /// A [StreamColorSwatch] for the subscription, memoized.
  // TODO I'm not sure this is the right home for this; it seems like we might
  //   instead have chosen to put it in more UI-centered code, like in a custom
  //   material [ColorScheme] class or something. But it works for now.
  StreamColorSwatch colorSwatch() => _swatch ??= StreamColorSwatch.light(color);

  @visibleForTesting
  @JsonKey(includeToJson: false)
  StreamColorSwatch? get debugCachedSwatchValue => _swatch;

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
    required int color,
  }) : _color = color;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
    _$SubscriptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);
}

/// A [ColorSwatch] with colors related to a base stream color.
///
/// Use this in UI code for colors related to [Subscription.color],
/// such as the background of an unread count badge.
class StreamColorSwatch extends ColorSwatch<StreamColorVariant> {
  StreamColorSwatch.light(int base) : this._(base, _computeLight(base));
  StreamColorSwatch.dark(int base) : this._(base, _computeDark(base));

  const StreamColorSwatch._(int base, this._swatch) : super(base, _swatch);

  final Map<StreamColorVariant, Color> _swatch;

  /// The [Subscription.color] int that the swatch is based on.
  Color get base => this[StreamColorVariant.base]!;

  Color get unreadCountBadgeBackground => this[StreamColorVariant.unreadCountBadgeBackground]!;

  /// The stream icon on a plain-colored surface, such as white.
  ///
  /// For the icon on a [barBackground]-colored surface,
  /// use [iconOnBarBackground] instead.
  Color get iconOnPlainBackground => this[StreamColorVariant.iconOnPlainBackground]!;

  /// The stream icon on a [barBackground]-colored surface.
  ///
  /// For the icon on a plain surface, use [iconOnPlainBackground] instead.
  /// This color is chosen to enhance contrast with [barBackground]:
  ///   <https://github.com/zulip/zulip/pull/27485>
  Color get iconOnBarBackground => this[StreamColorVariant.iconOnBarBackground]!;

  /// The background color of a bar representing a stream, like a recipient bar.
  ///
  /// Use this in the message list, the "Inbox" view, and the "Streams" view.
  Color get barBackground => this[StreamColorVariant.barBackground]!;

  static Map<StreamColorVariant, Color> _computeLight(int base) {
    final baseAsColor = Color(base);

    final clamped20to75 = clampLchLightness(baseAsColor, 20, 75);
    final clamped20to75AsHsl = HSLColor.fromColor(clamped20to75);

    return {
      StreamColorVariant.base: baseAsColor,

      // Follows `.unread-count` in Vlad's replit:
      //   <https://replit.com/@VladKorobov/zulip-sidebar#script.js>
      //   <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/design.3A.20.23F117.20.22Inbox.22.20screen/near/1624484>
      //
      // TODO fix bug where our results differ from the replit's (see unit tests)
      StreamColorVariant.unreadCountBadgeBackground:
        clampLchLightness(baseAsColor, 30, 70)
          .withOpacity(0.3),

      // Follows `.sidebar-row__icon` in Vlad's replit:
      //   <https://replit.com/@VladKorobov/zulip-sidebar#script.js>
      //
      // TODO fix bug where our results differ from the replit's (see unit tests)
      StreamColorVariant.iconOnPlainBackground: clamped20to75,

      // Follows `.recepeient__icon` in Vlad's replit:
      //   <https://replit.com/@VladKorobov/zulip-topic-feed-colors#script.js>
      //   <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/design.3A.20.23F117.20.22Inbox.22.20screen/near/1624484>
      //
      // TODO fix bug where our results differ from the replit's (see unit tests)
      StreamColorVariant.iconOnBarBackground:
        clamped20to75AsHsl
          .withLightness(clampDouble(clamped20to75AsHsl.lightness - 0.12, 0.0, 1.0))
          .toColor(),

      // Follows `.recepient` in Vlad's replit:
      //   <https://replit.com/@VladKorobov/zulip-topic-feed-colors#script.js>
      //
      // TODO I think [LabColor.interpolate] doesn't actually do LAB mixing;
      //   it just calls up to the superclass method [ColorModel.interpolate]:
      //     <https://pub.dev/documentation/flutter_color_models/latest/flutter_color_models/ColorModel/interpolate.html>
      //   which does ordinary RGB mixing. Investigate and send a PR?
      // TODO fix bug where our results differ from the replit's (see unit tests)
      StreamColorVariant.barBackground:
        LabColor.fromColor(const Color(0xfff9f9f9))
          .interpolate(LabColor.fromColor(clamped20to75), 0.22)
          .toColor(),
    };
  }

  static Map<StreamColorVariant, Color> _computeDark(int base) {
    final baseAsColor = Color(base);

    final clamped20to75 = clampLchLightness(baseAsColor, 20, 75);

    return {
      // See comments in [_computeLight] about what these computations are based
      // on, and how the resulting values are a little off sometimes. The
      // comments mostly apply here too.

      StreamColorVariant.base: baseAsColor,
      StreamColorVariant.unreadCountBadgeBackground:
        clampLchLightness(baseAsColor, 30, 70)
          .withOpacity(0.3),
      StreamColorVariant.iconOnPlainBackground: clamped20to75,

      // Follows the web app (as of zulip/zulip@db03369ac); see
      // get_stream_privacy_icon_color in web/src/stream_color.ts.
      //
      // `.recepeient__icon` in Vlad's replit gives something different so we
      // don't use that:
      //   <https://replit.com/@VladKorobov/zulip-topic-feed-colors#script.js>
      //   <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/design.3A.20.23F117.20.22Inbox.22.20screen/near/1624484>
      // But that's OK because Vlad said "I feel like current dark theme contrast
      // is fine", and when he said that, this had been the web app's icon color
      // for 6+ months (since zulip/zulip@023584e04):
      //   https://chat.zulip.org/#narrow/stream/101-design/topic/UI.20redesign.3A.20recipient.20bar.20colors/near/1675786
      //
      // TODO fix bug where our results are unexpected (see unit tests)
      StreamColorVariant.iconOnBarBackground: clamped20to75,

      StreamColorVariant.barBackground:
        LabColor.fromColor(const Color(0xff000000))
          .interpolate(LabColor.fromColor(clamped20to75), 0.38)
          .toColor(),
    };
  }

  /// Copied from [ColorSwatch.lerp].
  static StreamColorSwatch? lerp(StreamColorSwatch? a, StreamColorSwatch? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    final Map<StreamColorVariant, Color> swatch;
    if (b == null) {
      swatch = a!._swatch.map((key, color) => MapEntry(key, Color.lerp(color, null, t)!));
    } else {
      if (a == null) {
        swatch = b._swatch.map((key, color) => MapEntry(key, Color.lerp(null, color, t)!));
      } else {
        swatch = a._swatch.map((key, color) => MapEntry(key, Color.lerp(color, b[key], t)!));
      }
    }
    return StreamColorSwatch._(Color.lerp(a, b, t)!.value, swatch);
  }
}

@visibleForTesting
enum StreamColorVariant {
  base,
  unreadCountBadgeBackground,
  iconOnPlainBackground,
  iconOnBarBackground,
  barBackground,
}

@JsonEnum(fieldRename: FieldRename.snake, valueField: "apiValue")
enum UserTopicVisibilityPolicy {
  none(apiValue: 0),
  muted(apiValue: 1),
  unmuted(apiValue: 2), // TODO(server-7) newly added
  followed(apiValue: 3), // TODO(server-8) newly added
  unknown(apiValue: null);

  const UserTopicVisibilityPolicy({required this.apiValue});

  final int? apiValue;

  int? toJson() => apiValue;
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
