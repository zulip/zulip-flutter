import 'package:json_annotation/json_annotation.dart';

import 'model.dart';

part 'events.g.dart';

/// A Zulip event.
///
/// See API documentation: https://zulip.com/api/get-events
sealed class Event {
  final int id;
  String get type;

  Event({required this.id});

  factory Event.fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'realm_emoji':
        switch (json['op'] as String) {
          case 'update': return RealmEmojiUpdateEvent.fromJson(json);
          default: return UnexpectedEvent.fromJson(json);
        }
      case 'alert_words': return AlertWordsEvent.fromJson(json);
      case 'user_settings':
        switch (json['op'] as String) {
          case 'update': return UserSettingsUpdateEvent.fromJson(json);
          default: return UnexpectedEvent.fromJson(json);
        }
      case 'custom_profile_fields': return CustomProfileFieldsEvent.fromJson(json);
      case 'realm_user':
        switch (json['op'] as String) {
          case 'add': return RealmUserAddEvent.fromJson(json);
          case 'remove': return RealmUserRemoveEvent.fromJson(json);
          case 'update': return RealmUserUpdateEvent.fromJson(json);
          default: return UnexpectedEvent.fromJson(json);
        }
      case 'stream':
        switch (json['op'] as String) {
          case 'create': return StreamCreateEvent.fromJson(json);
          case 'delete': return StreamDeleteEvent.fromJson(json);
          // TODO(#182): case 'update': …
          default: return UnexpectedEvent.fromJson(json);
        }
      case 'subscription':
        switch (json['op'] as String) {
          case 'add': return SubscriptionAddEvent.fromJson(json);
          case 'remove': return SubscriptionRemoveEvent.fromJson(json);
          case 'update': return SubscriptionUpdateEvent.fromJson(json);
          case 'peer_add': return SubscriptionPeerAddEvent.fromJson(json);
          case 'peer_remove': return SubscriptionPeerRemoveEvent.fromJson(json);
          default: return UnexpectedEvent.fromJson(json);
        }
      // case 'muted_topics': … // TODO(#422) we ignore this feature on older servers
      case 'user_topic': return UserTopicEvent.fromJson(json);
      case 'message': return MessageEvent.fromJson(json);
      case 'update_message': return UpdateMessageEvent.fromJson(json);
      case 'delete_message': return DeleteMessageEvent.fromJson(json);
      case 'update_message_flags':
        switch (json['op'] as String) {
          case 'add': return UpdateMessageFlagsAddEvent.fromJson(json);
          case 'remove': return UpdateMessageFlagsRemoveEvent.fromJson(json);
          default: return UnexpectedEvent.fromJson(json);
        }
      case 'reaction': return ReactionEvent.fromJson(json);
      case 'heartbeat': return HeartbeatEvent.fromJson(json);
      // TODO add many more event types
      default: return UnexpectedEvent.fromJson(json);
    }
  }

  Map<String, dynamic> toJson();
}

/// A Zulip event of a type this client doesn't know about.
class UnexpectedEvent extends Event {
  final Map<String, dynamic> json;

  @override
  String get type => json['type'] as String;

  UnexpectedEvent.fromJson(this.json) : super(id: json['id'] as int);

  @override
  Map<String, dynamic> toJson() => json;
}

/// A Zulip event of type `realm_emoji` with op `update`:
///   https://zulip.com/api/get-events#realm_emoji-update
@JsonSerializable(fieldRename: FieldRename.snake)
class RealmEmojiUpdateEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'realm_emoji';

  @JsonKey(includeToJson: true)
  String get op => 'update';

  final Map<String, RealmEmojiItem> realmEmoji;

  RealmEmojiUpdateEvent({required super.id, required this.realmEmoji});

  factory RealmEmojiUpdateEvent.fromJson(Map<String, dynamic> json) =>
    _$RealmEmojiUpdateEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$RealmEmojiUpdateEventToJson(this);
}

/// A Zulip event of type `alert_words`: https://zulip.com/api/get-events#alert_words
@JsonSerializable(fieldRename: FieldRename.snake)
class AlertWordsEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'alert_words';

  final List<String> alertWords;

  AlertWordsEvent({required super.id, required this.alertWords});

  factory AlertWordsEvent.fromJson(Map<String, dynamic> json) =>
    _$AlertWordsEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AlertWordsEventToJson(this);
}

/// A Zulip event of type `user_settings` with op `update`.
@JsonSerializable(fieldRename: FieldRename.snake)
class UserSettingsUpdateEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'user_settings';

  @JsonKey(includeToJson: true)
  String get op => 'update';

  /// The name of the setting, or null if we don't recognize it.
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final UserSettingName? property;

  /// The new value, or null if we don't recognize the setting.
  ///
  /// This will have the type appropriate for [property]; for example,
  /// if the setting is boolean, then `value is bool` will always be true.
  /// This invariant is enforced by [UserSettingsUpdateEvent.fromJson].
  @JsonKey(readValue: _readValue)
  final Object? value;

  /// [value], with a check that its type corresponds to [property]
  /// (e.g., `value as bool`).
  static Object? _readValue(Map<dynamic, dynamic> json, String key) {
    final value = json['value'];
    switch (UserSettingName.fromRawString(json['property'] as String)) {
      case UserSettingName.twentyFourHourTime:
      case UserSettingName.displayEmojiReactionUsers:
        return value as bool;
      case UserSettingName.emojiset:
        return Emojiset.fromRawString(value as String);
      case null:
        return null;
    }
  }

  UserSettingsUpdateEvent({
    required super.id,
    required this.property,
    required this.value,
  });

  factory UserSettingsUpdateEvent.fromJson(Map<String, dynamic> json) =>
    _$UserSettingsUpdateEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UserSettingsUpdateEventToJson(this);
}

/// A Zulip event of type `custom_profile_fields`: https://zulip.com/api/get-events#custom_profile_fields
@JsonSerializable(fieldRename: FieldRename.snake)
class CustomProfileFieldsEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'custom_profile_fields';

  final List<CustomProfileField> fields;

  CustomProfileFieldsEvent({required super.id, required this.fields});

  factory CustomProfileFieldsEvent.fromJson(Map<String, dynamic> json) =>
    _$CustomProfileFieldsEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CustomProfileFieldsEventToJson(this);
}

/// A Zulip event of type `realm_user`.
///
/// The corresponding API docs are in several places for
/// different values of `op`; see subclasses.
sealed class RealmUserEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'realm_user';

  String get op;

  RealmUserEvent({required super.id});
}

/// A [RealmUserEvent] with op `add`: https://zulip.com/api/get-events#realm_user-add
@JsonSerializable(fieldRename: FieldRename.snake)
class RealmUserAddEvent extends RealmUserEvent {
  @override
  String get op => 'add';

  final User person;

  RealmUserAddEvent({required super.id, required this.person});

  factory RealmUserAddEvent.fromJson(Map<String, dynamic> json) =>
    _$RealmUserAddEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$RealmUserAddEventToJson(this);
}

/// A [RealmUserEvent] with op `remove`: https://zulip.com/api/get-events#realm_user-remove
class RealmUserRemoveEvent extends RealmUserEvent {
  @override
  String get op => 'remove';

  final int userId;

  RealmUserRemoveEvent({required super.id, required this.userId});

  factory RealmUserRemoveEvent.fromJson(Map<String, dynamic> json) {
    return RealmUserRemoveEvent(
      id: json['id'] as int,
      userId: (json['person'] as Map<String, dynamic>)['user_id'] as int);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type, 'op': op, 'person': {'user_id': userId}};
  }
}

/// As in [RealmUserUpdateEvent.customProfileField].
@JsonSerializable(fieldRename: FieldRename.snake)
class RealmUserUpdateCustomProfileField {
  final int id;
  final String? value;
  final String? renderedValue;

  RealmUserUpdateCustomProfileField({required this.id, required this.value, required this.renderedValue});

  factory RealmUserUpdateCustomProfileField.fromJson(Map<String, dynamic> json) =>
    _$RealmUserUpdateCustomProfileFieldFromJson(json);

  Map<String, dynamic> toJson() => _$RealmUserUpdateCustomProfileFieldToJson(this);
}

/// A [RealmUserEvent] with op `update`: https://zulip.com/api/get-events#realm_user-update
@JsonSerializable(fieldRename: FieldRename.snake)
class RealmUserUpdateEvent extends RealmUserEvent {
  @override
  String get op => 'update';

  @JsonKey(readValue: _readFromPerson) final int userId;
  @JsonKey(readValue: _readFromPerson) final String? fullName;
  @JsonKey(readValue: _readFromPerson) final String? avatarUrl;
  // @JsonKey(readValue: _readFromPerson) final String? avatarSource; // TODO obsolete?
  // @JsonKey(readValue: _readFromPerson) final String? avatarUrlMedium; // TODO obsolete?
  @JsonKey(readValue: _readFromPerson) final int? avatarVersion;
  @JsonKey(readValue: _readFromPerson) final String? timezone;
  @JsonKey(readValue: _readFromPerson) final int? botOwnerId;
  @JsonKey(readValue: _readFromPerson, unknownEnumValue: UserRole.unknown) final UserRole? role;
  @JsonKey(readValue: _readFromPerson) final bool? isBillingAdmin;
  @JsonKey(readValue: _readFromPerson) final String? deliveryEmail; // TODO handle JSON `null`
  @JsonKey(readValue: _readFromPerson) final RealmUserUpdateCustomProfileField? customProfileField;
  @JsonKey(readValue: _readFromPerson) final String? newEmail;

  static Object? _readFromPerson(Map<dynamic, dynamic> json, String key) {
    return (json['person'] as Map<String, dynamic>)[key];
  }

  RealmUserUpdateEvent({
    required super.id,
    required this.userId,
    // Unlike in most of the API bindings, we leave these constructor arguments
    // optional.  That's because in these events only one or a handful of these
    // will appear in a given event value.
    this.fullName,
    this.avatarUrl,
    this.avatarVersion,
    this.timezone,
    this.botOwnerId,
    this.role,
    this.isBillingAdmin,
    this.deliveryEmail,
    this.customProfileField,
    this.newEmail,
  });

  factory RealmUserUpdateEvent.fromJson(Map<String, dynamic> json) =>
    _$RealmUserUpdateEventFromJson(json);

  // TODO make round-trip (see _readFromPerson)
  @override
  Map<String, dynamic> toJson() => _$RealmUserUpdateEventToJson(this);
}

/// A Zulip event of type `stream`.
///
/// The corresponding API docs are in several places for
/// different values of `op`; see subclasses.
sealed class StreamEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'stream';

  String get op;

  StreamEvent({required super.id});
}

/// A [StreamEvent] with op `create`: https://zulip.com/api/get-events#stream-create
@JsonSerializable(fieldRename: FieldRename.snake)
class StreamCreateEvent extends StreamEvent {
  @override
  String get op => 'create';

  final List<ZulipStream> streams;

  StreamCreateEvent({required super.id, required this.streams});

  factory StreamCreateEvent.fromJson(Map<String, dynamic> json) =>
    _$StreamCreateEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StreamCreateEventToJson(this);
}

/// A [StreamEvent] with op `delete`: https://zulip.com/api/get-events#stream-delete
@JsonSerializable(fieldRename: FieldRename.snake)
class StreamDeleteEvent extends StreamEvent {
  @override
  String get op => 'delete';

  final List<ZulipStream> streams;

  StreamDeleteEvent({required super.id, required this.streams});

  factory StreamDeleteEvent.fromJson(Map<String, dynamic> json) =>
    _$StreamDeleteEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StreamDeleteEventToJson(this);
}

// TODO(#182) StreamUpdateEvent, for a [StreamEvent] with op `update`:
//   https://zulip.com/api/get-events#stream-update

/// A Zulip event of type `subscription`.
///
/// The corresponding API docs are in several places for
/// different values of `op`; see subclasses.
sealed class SubscriptionEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'subscription';

  String get op;

  SubscriptionEvent({required super.id});
}

/// A [SubscriptionEvent] with op `add`: https://zulip.com/api/get-events#subscription-add
@JsonSerializable(fieldRename: FieldRename.snake)
class SubscriptionAddEvent extends SubscriptionEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'add';

  final List<Subscription> subscriptions;

  SubscriptionAddEvent({required super.id, required this.subscriptions});

  factory SubscriptionAddEvent.fromJson(Map<String, dynamic> json) =>
    _$SubscriptionAddEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SubscriptionAddEventToJson(this);
}

/// A [SubscriptionEvent] with op `remove`: https://zulip.com/api/get-events#subscription-remove
@JsonSerializable(fieldRename: FieldRename.snake)
class SubscriptionRemoveEvent extends SubscriptionEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'remove';

  @JsonKey(readValue: _readStreamIds)
  final List<int> streamIds;

  static List<int> _readStreamIds(Map<dynamic, dynamic> json, String key) {
    return (json['subscriptions'] as List<dynamic>)
      .map((e) => (e as Map<String, dynamic>)['stream_id'] as int)
      .toList();
  }

  SubscriptionRemoveEvent({required super.id, required this.streamIds});

  factory SubscriptionRemoveEvent.fromJson(Map<String, dynamic> json) =>
    _$SubscriptionRemoveEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SubscriptionRemoveEventToJson(this);
}

/// A [SubscriptionEvent] with op `update`: https://zulip.com/api/get-events#subscription-update
@JsonSerializable(fieldRename: FieldRename.snake)
class SubscriptionUpdateEvent extends SubscriptionEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'update';

  final int streamId;

  final SubscriptionProperty property;

  /// The new value, or null if we don't recognize the setting.
  ///
  /// This will have the type appropriate for [property]; for example,
  /// if the setting is boolean, then `value is bool` will always be true.
  /// This invariant is enforced by [SubscriptionUpdateEvent.fromJson].
  @JsonKey(readValue: _readValue)
  final Object? value;

  /// [value], with a check that its type corresponds to [property]
  /// (e.g., `value as bool`).
  static Object? _readValue(Map<dynamic, dynamic> json, String key) {
    final value = json['value'];
    switch (SubscriptionProperty.fromRawString(json['property'] as String)) {
      case SubscriptionProperty.color:
        final str = value as String;
        assert(RegExp(r'^#[0-9a-f]{6}$').hasMatch(str));
        return 0xff000000 | int.parse(str.substring(1), radix: 16);
      case SubscriptionProperty.isMuted:
      case SubscriptionProperty.inHomeView:
      case SubscriptionProperty.pinToTop:
      case SubscriptionProperty.desktopNotifications:
      case SubscriptionProperty.audibleNotifications:
      case SubscriptionProperty.pushNotifications:
      case SubscriptionProperty.emailNotifications:
      case SubscriptionProperty.wildcardMentionsNotify:
        return value as bool;
      case SubscriptionProperty.unknown:
        return null;
    }
  }

  SubscriptionUpdateEvent({
    required super.id,
    required this.streamId,
    required this.property,
    required this.value,
  });

  factory SubscriptionUpdateEvent.fromJson(Map<String, dynamic> json) =>
    _$SubscriptionUpdateEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SubscriptionUpdateEventToJson(this);
}

/// The name of a property in [Subscription].
///
/// Used in handling of [SubscriptionUpdateEvent].
@JsonEnum(fieldRename: FieldRename.snake, alwaysCreate: true)
enum SubscriptionProperty {
  /// As an int that dart:ui's Color constructor will take:
  ///   <https://api.flutter.dev/flutter/dart-ui/Color/Color.html>
  color,

  isMuted,
  inHomeView,
  pinToTop,
  desktopNotifications,
  audibleNotifications,
  pushNotifications,
  emailNotifications,
  wildcardMentionsNotify,
  unknown;

  static SubscriptionProperty fromRawString(String raw) => _byRawString[raw] ?? unknown;

  static final _byRawString = _$SubscriptionPropertyEnumMap
    .map((key, value) => MapEntry(value, key));
}

/// A [SubscriptionEvent] with op `peer_add`: https://zulip.com/api/get-events#subscription-peer_add
@JsonSerializable(fieldRename: FieldRename.snake)
class SubscriptionPeerAddEvent extends SubscriptionEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'peer_add';

  List<int> streamIds;
  List<int> userIds;

  SubscriptionPeerAddEvent({
    required super.id,
    required this.streamIds,
    required this.userIds,
  });

  factory SubscriptionPeerAddEvent.fromJson(Map<String, dynamic> json) =>
    _$SubscriptionPeerAddEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SubscriptionPeerAddEventToJson(this);
}

/// A [SubscriptionEvent] with op `peer_remove`: https://zulip.com/api/get-events#subscription-peer_remove
@JsonSerializable(fieldRename: FieldRename.snake)
class SubscriptionPeerRemoveEvent extends SubscriptionEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'peer_remove';

  List<int> streamIds;
  List<int> userIds;

  SubscriptionPeerRemoveEvent({
    required super.id,
    required this.streamIds,
    required this.userIds,
  });

  factory SubscriptionPeerRemoveEvent.fromJson(Map<String, dynamic> json) =>
    _$SubscriptionPeerRemoveEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SubscriptionPeerRemoveEventToJson(this);
}

/// A Zulip event of type `user_topic`: https://zulip.com/api/get-events#user_topic
@JsonSerializable(fieldRename: FieldRename.snake)
class UserTopicEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'user_topic';

  final int streamId;
  final String topicName;
  final int lastUpdated;
  final UserTopicVisibilityPolicy visibilityPolicy;

  UserTopicEvent({
    required super.id,
    required this.streamId,
    required this.topicName,
    required this.lastUpdated,
    required this.visibilityPolicy,
  });

  factory UserTopicEvent.fromJson(Map<String, dynamic> json) =>
    _$UserTopicEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UserTopicEventToJson(this);
}

/// A Zulip event of type `message`: https://zulip.com/api/get-events#message
// TODO use [JsonSerializable] here too, using its customization features,
//   in order to skip the boilerplate in [fromJson] and [toJson].
class MessageEvent extends Event {
  @override
  String get type => 'message';

  // In the server API, the `flags` field appears directly on the event rather
  // than on the message object.  To avoid proliferating message types, we
  // normalize that away in deserialization.
  //
  // The other difference in the server API between message objects in these
  // events and in the get-messages results is that `matchContent` and
  // `matchSubject` are absent here.  Already [Message.matchContent] and
  // [Message.matchSubject] are optional, so no action is needed on that.
  final Message message;

  MessageEvent({required super.id, required this.message});

  factory MessageEvent.fromJson(Map<String, dynamic> json) => MessageEvent(
    id: json['id'] as int,
    message: Message.fromJson({
      ...json['message'] as Map<String, dynamic>,
      'flags': (json['flags'] as List<dynamic>).map((e) => e as String).toList(),
    }),
  );

  @override
  Map<String, dynamic> toJson() {
    final messageJson = message.toJson();
    final flags = messageJson['flags'];
    messageJson.remove('flags');
    return {'id': id, 'type': type, 'message': messageJson, 'flags': flags};
  }
}

/// A Zulip event of type `update_message`: https://zulip.com/api/get-events#update_message
@JsonSerializable(fieldRename: FieldRename.snake)
class UpdateMessageEvent extends Event {
  @override
  String get type => 'update_message';

  final int? userId; // TODO(server-5)
  final bool? renderingOnly; // TODO(server-5)
  final int messageId;
  final List<int> messageIds;
  final List<MessageFlag> flags;
  final int? editTimestamp; // TODO(server-5)
  final String? streamName;
  final int? streamId;
  final int? newStreamId;
  final PropagateMode? propagateMode;
  final String? origSubject;
  final String? subject;
  // final List<TopicLink> topicLinks; // TODO handle
  final String? origContent;
  final String? origRenderedContent;
  // final int? prevRenderedContentVersion; // deprecated
  final String? content;
  final String? renderedContent;
  final bool? isMeMessage;

  UpdateMessageEvent({
    required super.id,
    required this.userId,
    required this.renderingOnly,
    required this.messageId,
    required this.messageIds,
    required this.flags,
    required this.editTimestamp,
    required this.streamName,
    required this.streamId,
    required this.newStreamId,
    required this.propagateMode,
    required this.origSubject,
    required this.subject,
    required this.origContent,
    required this.origRenderedContent,
    required this.content,
    required this.renderedContent,
    required this.isMeMessage,
  });

  factory UpdateMessageEvent.fromJson(Map<String, dynamic> json) =>
    _$UpdateMessageEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UpdateMessageEventToJson(this);
}

/// As in [UpdateMessageEvent.propagateMode].
@JsonEnum(fieldRename: FieldRename.snake)
enum PropagateMode {
  changeOne,
  changeLater,
  changeAll;
}

/// A Zulip event of type `delete_message`: https://zulip.com/api/get-events#delete_message
@JsonSerializable(fieldRename: FieldRename.snake)
class DeleteMessageEvent extends Event {
  @override
  String get type => 'delete_message';

  final List<int> messageIds;
  // final int messageId; // Not present; we support the bulk_message_deletion capability
  final MessageType messageType;
  final int? streamId;
  final String? topic;

  DeleteMessageEvent({
    required super.id,
    required this.messageIds,
    required this.messageType,
    required this.streamId,
    required this.topic,
  });

  factory DeleteMessageEvent.fromJson(Map<String, dynamic> json) {
    final result = _$DeleteMessageEventFromJson(json);
    // Crunchy-shell validation
    if (result.messageType == MessageType.stream) {
      result.streamId as int;
      result.topic as String;
    }
    return result;
  }

  @override
  Map<String, dynamic> toJson() => _$DeleteMessageEventToJson(this);
}

/// As in [DeleteMessageEvent.messageType]
/// or [UpdateMessageFlagsMessageDetail.type].
@JsonEnum(fieldRename: FieldRename.snake)
enum MessageType {
  stream,
  private;
}

/// A Zulip event of type `update_message_flags`.
///
/// For the corresponding API docs, see subclasses.
sealed class UpdateMessageFlagsEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'update_message_flags';

  String get op;

  @JsonKey(unknownEnumValue: MessageFlag.unknown)
  final MessageFlag flag;
  final List<int> messages;

  UpdateMessageFlagsEvent({
    required super.id,
    required this.flag,
    required this.messages,
  });
}

/// An [UpdateMessageFlagsEvent] with op `add`: https://zulip.com/api/get-events#update_message_flags-add
@JsonSerializable(fieldRename: FieldRename.snake)
class UpdateMessageFlagsAddEvent extends UpdateMessageFlagsEvent {
  @override
  String get op => 'add';

  final bool all;

  UpdateMessageFlagsAddEvent({
    required super.id,
    required super.flag,
    required super.messages,
    required this.all,
  });

  factory UpdateMessageFlagsAddEvent.fromJson(Map<String, dynamic> json) =>
    _$UpdateMessageFlagsAddEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UpdateMessageFlagsAddEventToJson(this);
}

/// An [UpdateMessageFlagsEvent] with op `remove`: https://zulip.com/api/get-events#update_message_flags-remove
@JsonSerializable(fieldRename: FieldRename.snake)
class UpdateMessageFlagsRemoveEvent extends UpdateMessageFlagsEvent {
  @override
  String get op => 'remove';

  // final bool all; // deprecated, ignore
  // TODO(json_serializable): keys use plain `int.parse`, permitting hexadecimal
  final Map<int, UpdateMessageFlagsMessageDetail>? messageDetails;

  UpdateMessageFlagsRemoveEvent({
    required super.id,
    required super.flag,
    required super.messages,
    required this.messageDetails,
  });

  factory UpdateMessageFlagsRemoveEvent.fromJson(Map<String, dynamic> json) {
    final result = _$UpdateMessageFlagsRemoveEventFromJson(json);
    // Crunchy-shell validation
    if (
      result.flag == MessageFlag.read
      && true // (we assume `event_types` has `message` and `update_message_flags`)
    ) {
      result.messageDetails as Map<int, UpdateMessageFlagsMessageDetail>;
    }
    return result;
  }

  @override
  Map<String, dynamic> toJson() => _$UpdateMessageFlagsRemoveEventToJson(this);
}

/// As in [UpdateMessageFlagsRemoveEvent.messageDetails].
@JsonSerializable(fieldRename: FieldRename.snake)
class UpdateMessageFlagsMessageDetail {
  final MessageType type;
  final bool? mentioned;
  final List<int>? userIds;
  final int? streamId;
  final String? topic;

  UpdateMessageFlagsMessageDetail({
    required this.type,
    required this.mentioned,
    required this.userIds,
    required this.streamId,
    required this.topic,
  });

  factory UpdateMessageFlagsMessageDetail.fromJson(Map<String, dynamic> json) {
    final result = _$UpdateMessageFlagsMessageDetailFromJson(json);
    // Crunchy-shell validation
    switch (result.type) {
      case MessageType.stream:
        result.streamId as int;
        result.topic as String;
      case MessageType.private:
        result.userIds as List<int>;
    }
    return result;
  }

  Map<String, dynamic> toJson() => _$UpdateMessageFlagsMessageDetailToJson(this);
}

/// A Zulip event of type `reaction`, with op `add` or `remove`.
///
/// See:
///   https://zulip.com/api/get-events#reaction-add
///   https://zulip.com/api/get-events#reaction-remove
@JsonSerializable(fieldRename: FieldRename.snake)
class ReactionEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'reaction';

  final ReactionOp op;

  final String emojiName;
  final String emojiCode;
  final ReactionType reactionType;
  final int userId;
  // final Map<String, dynamic> user; // deprecated; ignore
  final int messageId;

  ReactionEvent({
    required super.id,
    required this.op,
    required this.emojiName,
    required this.emojiCode,
    required this.reactionType,
    required this.userId,
    required this.messageId,
  });

  factory ReactionEvent.fromJson(Map<String, dynamic> json) =>
    _$ReactionEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ReactionEventToJson(this);
}

/// The type of [ReactionEvent.op].
@JsonEnum(fieldRename: FieldRename.snake)
enum ReactionOp {
  add,
  remove,
}

/// A Zulip event of type `heartbeat`: https://zulip.com/api/get-events#heartbeat
@JsonSerializable(fieldRename: FieldRename.snake)
class HeartbeatEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'heartbeat';

  HeartbeatEvent({required super.id});

  factory HeartbeatEvent.fromJson(Map<String, dynamic> json) =>
    _$HeartbeatEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$HeartbeatEventToJson(this);
}
