import 'package:json_annotation/json_annotation.dart';

import '../../model/algorithms.dart';
import 'json.dart';
import 'model.dart';
import 'submessage.dart';

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
      case 'user_group':
        switch (json['op'] as String) {
          case 'add': return UserGroupAddEvent.fromJson(json);
          case 'update': return UserGroupUpdateEvent.fromJson(json);
          case 'add_members': return UserGroupAddMembersEvent.fromJson(json);
          case 'remove_members': return UserGroupRemoveMembersEvent.fromJson(json);
          case 'add_subgroups': return UserGroupAddSubgroupsEvent.fromJson(json);
          case 'remove_subgroups': return UserGroupRemoveSubgroupsEvent.fromJson(json);
          case 'remove': return UserGroupRemoveEvent.fromJson(json);
          default: return UnexpectedEvent.fromJson(json);
        }
      case 'realm_user':
        switch (json['op'] as String) {
          case 'add': return RealmUserAddEvent.fromJson(json);
          case 'remove': return RealmUserRemoveEvent.fromJson(json);
          case 'update': return RealmUserUpdateEvent.fromJson(json);
          default: return UnexpectedEvent.fromJson(json);
        }
      case 'saved_snippets':
        switch (json['op'] as String) {
          case 'add': return SavedSnippetsAddEvent.fromJson(json);
          case 'update': return SavedSnippetsUpdateEvent.fromJson(json);
          case 'remove': return SavedSnippetsRemoveEvent.fromJson(json);
          default: return UnexpectedEvent.fromJson(json);
        }
      case 'stream':
        switch (json['op'] as String) {
          case 'create': return ChannelCreateEvent.fromJson(json);
          case 'delete': return ChannelDeleteEvent.fromJson(json);
          case 'update': return ChannelUpdateEvent.fromJson(json);
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
      case 'channel_folder':
        switch (json['op'] as String) {
          case 'add': return ChannelFolderAddEvent.fromJson(json);
          case 'reorder': return ChannelFolderReorderEvent.fromJson(json);
          case 'update': return ChannelFolderUpdateEvent.fromJson(json);
          default: return UnexpectedEvent.fromJson(json);
        }
      case 'user_status': return UserStatusEvent.fromJson(json);
      case 'user_topic': return UserTopicEvent.fromJson(json);
      case 'muted_users': return MutedUsersEvent.fromJson(json);
      case 'message': return MessageEvent.fromJson(json);
      case 'update_message': return UpdateMessageEvent.fromJson(json);
      case 'delete_message': return DeleteMessageEvent.fromJson(json);
      case 'update_message_flags':
        switch (json['op'] as String) {
          case 'add': return UpdateMessageFlagsAddEvent.fromJson(json);
          case 'remove': return UpdateMessageFlagsRemoveEvent.fromJson(json);
          default: return UnexpectedEvent.fromJson(json);
        }
      case 'submessage': return SubmessageEvent.fromJson(json);
      case 'typing': return TypingEvent.fromJson(json);
      case 'presence': return PresenceEvent.fromJson(json);
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
        return TwentyFourHourTimeMode.fromApiValue(value as bool?);
      case UserSettingName.displayEmojiReactionUsers:
        return value as bool;
      case UserSettingName.emojiset:
        return Emojiset.fromRawString(value as String);
      case UserSettingName.presenceEnabled:
        return value as bool;
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

/// A Zulip event of type `user_group`.
///
/// See API docs starting at:
///   https://zulip.com/api/get-events#user_group-add
sealed class UserGroupEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'user_group';

  String get op;

  UserGroupEvent({required super.id});
}

/// A [UserGroupEvent] with op `add`: https://zulip.com/api/get-events#user_group-add
@JsonSerializable(fieldRename: FieldRename.snake)
class UserGroupAddEvent extends UserGroupEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'add';

  final UserGroup group;

  UserGroupAddEvent({required super.id, required this.group});

  factory UserGroupAddEvent.fromJson(Map<String, dynamic> json) => _$UserGroupAddEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UserGroupAddEventToJson(this);
}

/// A [UserGroupEvent] with op `update`: https://zulip.com/api/get-events#user_group-update
@JsonSerializable(fieldRename: FieldRename.snake)
class UserGroupUpdateEvent extends UserGroupEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'update';

  final int groupId;
  final UserGroupUpdateData data;

  UserGroupUpdateEvent({required super.id, required this.groupId, required this.data});

  factory UserGroupUpdateEvent.fromJson(Map<String, dynamic> json) => _$UserGroupUpdateEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UserGroupUpdateEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UserGroupUpdateData {
  final String? name;
  final String? description;
  final bool? deactivated;

  UserGroupUpdateData({required this.name, required this.description, required this.deactivated});

  factory UserGroupUpdateData.fromJson(Map<String, dynamic> json) => _$UserGroupUpdateDataFromJson(json);

  Map<String, dynamic> toJson() => _$UserGroupUpdateDataToJson(this);
}

/// A [UserGroupEvent] with op `add_members`: https://zulip.com/api/get-events#user_group-add_members
@JsonSerializable(fieldRename: FieldRename.snake)
class UserGroupAddMembersEvent extends UserGroupEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'add_members';

  final int groupId;
  final List<int> userIds;

  UserGroupAddMembersEvent({required super.id, required this.groupId, required this.userIds});

  factory UserGroupAddMembersEvent.fromJson(Map<String, dynamic> json) => _$UserGroupAddMembersEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UserGroupAddMembersEventToJson(this);
}

/// A [UserGroupEvent] with op `remove_members`: https://zulip.com/api/get-events#user_group-remove_members
@JsonSerializable(fieldRename: FieldRename.snake)
class UserGroupRemoveMembersEvent extends UserGroupEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'remove_members';

  final int groupId;
  final List<int> userIds;

  UserGroupRemoveMembersEvent({required super.id, required this.groupId, required this.userIds});

  factory UserGroupRemoveMembersEvent.fromJson(Map<String, dynamic> json) => _$UserGroupRemoveMembersEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UserGroupRemoveMembersEventToJson(this);
}

/// A [UserGroupEvent] with op `add_subgroups`: https://zulip.com/api/get-events#user_group-add_subgroups
@JsonSerializable(fieldRename: FieldRename.snake)
class UserGroupAddSubgroupsEvent extends UserGroupEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'add_subgroups';

  final int groupId;
  final List<int> directSubgroupIds;

  UserGroupAddSubgroupsEvent({required super.id, required this.groupId, required this.directSubgroupIds});

  factory UserGroupAddSubgroupsEvent.fromJson(Map<String, dynamic> json) => _$UserGroupAddSubgroupsEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UserGroupAddSubgroupsEventToJson(this);
}

/// A [UserGroupEvent] with op `remove_subgroups`: https://zulip.com/api/get-events#user_group-remove_subgroups
@JsonSerializable(fieldRename: FieldRename.snake)
class UserGroupRemoveSubgroupsEvent extends UserGroupEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'remove_subgroups';

  final int groupId;
  final List<int> directSubgroupIds;

  UserGroupRemoveSubgroupsEvent({required super.id, required this.groupId, required this.directSubgroupIds});

  factory UserGroupRemoveSubgroupsEvent.fromJson(Map<String, dynamic> json) => _$UserGroupRemoveSubgroupsEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UserGroupRemoveSubgroupsEventToJson(this);
}

/// A [UserGroupEvent] with op `remove`: https://zulip.com/api/get-events#user_group-remove
@JsonSerializable(fieldRename: FieldRename.snake)
class UserGroupRemoveEvent extends UserGroupEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'remove';

  final int groupId;

  UserGroupRemoveEvent({required super.id, required this.groupId});

  factory UserGroupRemoveEvent.fromJson(Map<String, dynamic> json) => _$UserGroupRemoveEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UserGroupRemoveEventToJson(this);
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
  @JsonKey(includeToJson: true)
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
  @JsonKey(includeToJson: true)
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
  @JsonKey(includeToJson: true)
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

  @JsonKey(readValue: _readNullableStringFromPerson)
  @NullableStringJsonConverter()
  final JsonNullable<String>? deliveryEmail;

  @JsonKey(readValue: _readFromPerson) final RealmUserUpdateCustomProfileField? customProfileField;
  @JsonKey(readValue: _readFromPerson) final String? newEmail;
  @JsonKey(readValue: _readFromPerson) final bool? isActive;

  static Object? _readFromPerson(Map<dynamic, dynamic> json, String key) {
    return (json['person'] as Map<String, dynamic>)[key];
  }

  static JsonNullable<String>? _readNullableStringFromPerson(
      Map<dynamic, dynamic> json, String key) {
    // We can't just say `readValue: _readNullableFromPerson<String>`,
    // because json_serializable drops the type argument in the generated code.
    return _readNullableFromPerson<String>(json, key);
  }

  static JsonNullable<T>? _readNullableFromPerson<T extends Object>(
      Map<dynamic, dynamic> json, String key) {
    return JsonNullable.readFromJson(json['person'] as Map<String, dynamic>, key);
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
    this.deliveryEmail,
    this.customProfileField,
    this.newEmail,
    this.isActive,
  });

  factory RealmUserUpdateEvent.fromJson(Map<String, dynamic> json) =>
    _$RealmUserUpdateEventFromJson(json);

  // TODO make round-trip (see _readFromPerson)
  @override
  Map<String, dynamic> toJson() => _$RealmUserUpdateEventToJson(this);
}

/// A Zulip event of type `saved_snippets`: https://zulip.com/api/get-events#saved_snippets-add
sealed class SavedSnippetsEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'saved_snippets';

  String get op;

  SavedSnippetsEvent({required super.id});
}

/// A [SavedSnippetsEvent] with op `add`: https://zulip.com/api/get-events#saved_snippets-add
@JsonSerializable(fieldRename: FieldRename.snake)
class SavedSnippetsAddEvent extends SavedSnippetsEvent {
  @override
  String get op => 'add';

  final SavedSnippet savedSnippet;

  SavedSnippetsAddEvent({required super.id, required this.savedSnippet});

  factory SavedSnippetsAddEvent.fromJson(Map<String, dynamic> json) =>
    _$SavedSnippetsAddEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SavedSnippetsAddEventToJson(this);
}

/// A [SavedSnippetsEvent] with op `update`: https://zulip.com/api/get-events#saved_snippets-update
@JsonSerializable(fieldRename: FieldRename.snake)
class SavedSnippetsUpdateEvent extends SavedSnippetsEvent {
  @override
  String get op => 'update';

  final SavedSnippet savedSnippet;

  SavedSnippetsUpdateEvent({required super.id, required this.savedSnippet});

  factory SavedSnippetsUpdateEvent.fromJson(Map<String, dynamic> json) =>
    _$SavedSnippetsUpdateEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SavedSnippetsUpdateEventToJson(this);
}

/// A [SavedSnippetsEvent] with op `remove`: https://zulip.com/api/get-events#saved_snippets-remove
@JsonSerializable(fieldRename: FieldRename.snake)
class SavedSnippetsRemoveEvent extends SavedSnippetsEvent {
  @override
  String get op => 'remove';

  final int savedSnippetId;

  SavedSnippetsRemoveEvent({required super.id, required this.savedSnippetId});

  factory SavedSnippetsRemoveEvent.fromJson(Map<String, dynamic> json) =>
    _$SavedSnippetsRemoveEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SavedSnippetsRemoveEventToJson(this);
}

/// A Zulip event of type `stream`.
///
/// The corresponding API docs are in several places for
/// different values of `op`; see subclasses.
sealed class ChannelEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'stream';

  String get op;

  ChannelEvent({required super.id});
}

/// A [ChannelEvent] with op `create`: https://zulip.com/api/get-events#stream-create
@JsonSerializable(fieldRename: FieldRename.snake)
class ChannelCreateEvent extends ChannelEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'create';

  final List<ZulipStream> streams;

  ChannelCreateEvent({required super.id, required this.streams});

  factory ChannelCreateEvent.fromJson(Map<String, dynamic> json) =>
    _$ChannelCreateEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ChannelCreateEventToJson(this);
}

/// A [ChannelEvent] with op `delete`: https://zulip.com/api/get-events#stream-delete
@JsonSerializable(fieldRename: FieldRename.snake)
class ChannelDeleteEvent extends ChannelEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'delete';

  @JsonKey(name: 'stream_ids', readValue: _readChannelIds)
  final List<int> channelIds;

  // TODO(server-10) simplify away; rely on stream_ids
  static List<int> _readChannelIds(Map<dynamic, dynamic> json, String key) {
    final channelIds = json['stream_ids'] as List<dynamic>?;
    if (channelIds != null) return channelIds.map((id) => id as int).toList();

    final channels = json['streams'] as List<dynamic>;
    return channels
      .map((c) => (c as Map<String, dynamic>)['stream_id'] as int)
      .toList();
  }

  ChannelDeleteEvent({required super.id, required this.channelIds});

  factory ChannelDeleteEvent.fromJson(Map<String, dynamic> json) =>
    _$ChannelDeleteEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ChannelDeleteEventToJson(this);
}

/// A [ChannelEvent] with op `update`: https://zulip.com/api/get-events#stream-update
@JsonSerializable(fieldRename: FieldRename.snake)
class ChannelUpdateEvent extends ChannelEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'update';

  final int streamId;
  final String name;

  /// The name of the channel property, or null if we don't recognize it.
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final ChannelPropertyName? property;

  /// The new value, or null if we don't recognize the property.
  ///
  /// This will have the type appropriate for [property]; for example,
  /// if the property is boolean, then `value is bool` will always be true.
  /// This invariant is enforced by [ChannelUpdateEvent.fromJson].
  @JsonKey(readValue: _readValue)
  final Object? value;

  final String? renderedDescription;
  final bool? historyPublicToSubscribers;
  final bool? isWebPublic;

  ChannelUpdateEvent({
    required super.id,
    required this.streamId,
    required this.name,
    required this.property,
    required this.value,
    this.renderedDescription,
    this.historyPublicToSubscribers,
    this.isWebPublic,
  });

  /// [value], with a check that its type corresponds to [property]
  /// (e.g., `value as bool`).
  static Object? _readValue(Map<dynamic, dynamic> json, String key) {
    final value = json['value'];
    switch (ChannelPropertyName.fromRawString(json['property'] as String)) {
      case ChannelPropertyName.name:
        return value as String;
      case ChannelPropertyName.isArchived:
        return value as bool;
      case ChannelPropertyName.description:
        return value as String;
      case ChannelPropertyName.firstMessageId:
        return value as int?;
      case ChannelPropertyName.inviteOnly:
        return value as bool;
      case ChannelPropertyName.messageRetentionDays:
        return value as int?;
      case ChannelPropertyName.channelPostPolicy:
        return ChannelPostPolicy.fromApiValue(value as int);
      case ChannelPropertyName.folderId:
        return value as int?;
      case ChannelPropertyName.canAddSubscribersGroup:
      case ChannelPropertyName.canDeleteAnyMessageGroup:
      case ChannelPropertyName.canDeleteOwnMessageGroup:
      case ChannelPropertyName.canSendMessageGroup:
      case ChannelPropertyName.canSubscribeGroup:
        return GroupSettingValue.fromJson(value);
      case ChannelPropertyName.isRecentlyActive:
        return value as bool;
      case ChannelPropertyName.streamWeeklyTraffic:
        return value as int?;
      case null:
        return null;
    }
  }

  factory ChannelUpdateEvent.fromJson(Map<String, dynamic> json) =>
    _$ChannelUpdateEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ChannelUpdateEventToJson(this);
}

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

  @JsonKey(unknownEnumValue: SubscriptionProperty.unknown)
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
  pinToTop,
  desktopNotifications,
  audibleNotifications,
  pushNotifications,
  emailNotifications,
  wildcardMentionsNotify,

  /// A new, unrecognized property, or a deprecated one we don't use.
  ///
  /// Could be `in_home_view`, deprecated in FL 139 (Server 6) but still sent
  /// as of CZO on 2025-10-03.
  // TODO(server-future) Remove `in_home_view` comment once it stops being sent.
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

/// A Zulip event of type `channel_folder`.
///
/// The corresponding API docs are in several places for
/// different values of `op`; see subclasses.
sealed class ChannelFolderEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'channel_folder';

  String get op;

  ChannelFolderEvent({required super.id});
}

/// A [ChannelFolderEvent] with op `add`:
///   https://zulip.com/api/get-events#channel_folder-add
@JsonSerializable(fieldRename: FieldRename.snake)
class ChannelFolderAddEvent extends ChannelFolderEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'add';

  final ChannelFolder channelFolder;

  ChannelFolderAddEvent({required super.id, required this.channelFolder});

  factory ChannelFolderAddEvent.fromJson(Map<String, dynamic> json) =>
    _$ChannelFolderAddEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ChannelFolderAddEventToJson(this);
}

/// A [ChannelFolderEvent] with op `update`:
///   https://zulip.com/api/get-events#channel_folder-update
@JsonSerializable(fieldRename: FieldRename.snake)
class ChannelFolderUpdateEvent extends ChannelFolderEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'update';

  final int channelFolderId;
  final ChannelFolderChange data;

  ChannelFolderUpdateEvent({
    required super.id,
    required this.channelFolderId,
    required this.data,
  });

  factory ChannelFolderUpdateEvent.fromJson(Map<String, dynamic> json) =>
    _$ChannelFolderUpdateEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ChannelFolderUpdateEventToJson(this);
}

/// Details of a channel-folder change, as in [ChannelFolderUpdateEvent.data].
@JsonSerializable(fieldRename: FieldRename.snake)
class ChannelFolderChange {
  final String? name;
  final String? description;
  final String? renderedDescription;
  final bool? isArchived;

  ChannelFolderChange({
    required this.name,
    required this.description,
    required this.renderedDescription,
    required this.isArchived,
  });

  factory ChannelFolderChange.fromJson(Map<String, dynamic> json) =>
    _$ChannelFolderChangeFromJson(json);

  Map<String, dynamic> toJson() => _$ChannelFolderChangeToJson(this);
}

/// A [ChannelFolderEvent] with op `update`:
///   https://zulip.com/api/get-events#channel_folder-update
@JsonSerializable(fieldRename: FieldRename.snake)
class ChannelFolderReorderEvent extends ChannelFolderEvent {
  @override
  @JsonKey(includeToJson: true)
  String get op => 'reorder';

  final List<int> order;

  ChannelFolderReorderEvent({required super.id, required this.order});

  factory ChannelFolderReorderEvent.fromJson(Map<String, dynamic> json) =>
    _$ChannelFolderReorderEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ChannelFolderReorderEventToJson(this);
}

/// A Zulip event of type `user_status`: https://zulip.com/api/get-events#user_status
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class UserStatusEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'user_status';

  final int userId;

  @JsonKey(readValue: _readChange)
  final UserStatusChange change;

  static Object? _readChange(Map<dynamic, dynamic> json, String key) {
    assert(json is Map<String, dynamic>); // value came through `fromJson` with this type
    return json;
  }

  UserStatusEvent({
    required super.id,
    required this.userId,
    required this.change,
  });

  factory UserStatusEvent.fromJson(Map<String, dynamic> json) =>
    _$UserStatusEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'user_id': userId,
    ...change.toJson(),
  };
}

/// A Zulip event of type `user_topic`: https://zulip.com/api/get-events#user_topic
@JsonSerializable(fieldRename: FieldRename.snake)
class UserTopicEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'user_topic';

  final int streamId;
  final TopicName topicName;
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

/// A Zulip event of type `muted_users`: https://zulip.com/api/get-events#muted_users
@JsonSerializable(fieldRename: FieldRename.snake)
class MutedUsersEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'muted_users';

  final List<MutedUserItem> mutedUsers;

  MutedUsersEvent({required super.id, required this.mutedUsers});

  factory MutedUsersEvent.fromJson(Map<String, dynamic> json) =>
    _$MutedUsersEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MutedUsersEventToJson(this);
}

/// A Zulip event of type `message`: https://zulip.com/api/get-events#message
@JsonSerializable(fieldRename: FieldRename.snake)
class MessageEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'message';

  // In the server API, the `flags` field appears directly on the event rather
  // than on the message object.  To avoid proliferating message types, we
  // normalize that away in deserialization.
  //
  // The other difference in the server API between message objects in these
  // events and in the get-messages results is that `matchContent` and
  // `matchTopic` are absent here.  Already [Message.matchContent] and
  // [Message.matchTopic] are optional, so no action is needed on that.
  @JsonKey(readValue: _readMessageValue, fromJson: Message.fromJson, includeToJson: false)
  final Message message;

  // When present, this equals the "local_id" parameter
  // from a previous [sendMessage] call by us.
  //
  // This is not yet fully documented.  See CZO discussion for reference:
  //   https://chat.zulip.org/#narrow/channel/412-api-documentation/topic/local_id.2C.20queue_id.2Fsender_queue_id/near/2135340
  final String? localMessageId;

  MessageEvent({required super.id, required this.message, required this.localMessageId});

  static Map<String, dynamic> _readMessageValue(Map<dynamic, dynamic> json, String key) =>
    {...json['message'] as Map<String, dynamic>, 'flags': json['flags']};

  factory MessageEvent.fromJson(Map<String, dynamic> json) =>
    _$MessageEventFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final messageJson = message.toJson();
    final flags = messageJson['flags'];
    messageJson.remove('flags');
    return {..._$MessageEventToJson(this), 'message': messageJson, 'flags': flags};
  }
}

/// A Zulip event of type `update_message`: https://zulip.com/api/get-events#update_message
@JsonSerializable(fieldRename: FieldRename.snake)
class UpdateMessageEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'update_message';

  final int? userId;
  final bool renderingOnly;
  final int messageId;
  final List<int> messageIds;

  final List<MessageFlag> flags;
  final int editTimestamp;

  // final String? streamName; // ignore

  @JsonKey(readValue: _readMoveData, fromJson: UpdateMessageMoveData.tryParseFromJson, includeToJson: false)
  final UpdateMessageMoveData? moveData;

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
    required this.moveData,
    required this.origContent,
    required this.origRenderedContent,
    required this.content,
    required this.renderedContent,
    required this.isMeMessage,
  });

  static Map<String, dynamic> _readMoveData(Map<dynamic, dynamic> json, String key) {
    // Parsing [UpdateMessageMoveData] requires `json`, not the default `json[key]`.
    assert(json is Map<String, dynamic>); // value came through `fromJson` with this type
    return json as Map<String, dynamic>;
  }

  factory UpdateMessageEvent.fromJson(Map<String, dynamic> json) =>
    _$UpdateMessageEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UpdateMessageEventToJson(this);
}

/// Data structure representing a message move.
class UpdateMessageMoveData {
  final int origStreamId;
  final int newStreamId;
  final TopicName origTopic;
  final TopicName newTopic;
  final PropagateMode propagateMode;

  UpdateMessageMoveData({
    required this.origStreamId,
    required this.newStreamId,
    required this.origTopic,
    required this.newTopic,
    required this.propagateMode,
  }) : assert(newStreamId != origStreamId || newTopic != origTopic);

  /// Try to extract [UpdateMessageMoveData] from the JSON object for an
  /// [UpdateMessageEvent].
  ///
  /// Returns `null` if there was no message move.
  ///
  /// Throws an error if the data is malformed.
  // When parsing this, 'stream_id', which is also present when there was only
  // a content edit, cannot be recovered if this ends up returning `null`.
  // This may matter if we ever need 'stream_id' when no message move occurred.
  static UpdateMessageMoveData? tryParseFromJson(Map<String, Object?> json) {
    final origStreamId = (json['stream_id'] as num?)?.toInt();
    final newStreamIdRaw = (json['new_stream_id'] as num?)?.toInt();
    final newStreamId = newStreamIdRaw ?? origStreamId;

    final origTopic = json['orig_subject'] == null ? null
      : TopicName.fromJson(json['orig_subject'] as String);
    final newTopicRaw = json['subject'] == null ? null
      : TopicName.fromJson(json['subject'] as String);
    final newTopic = newTopicRaw ?? origTopic;

    final propagateModeString = json['propagate_mode'] as String?;
    final propagateMode = propagateModeString == null ? null
      : PropagateMode.fromRawString(propagateModeString);

    if (newStreamId == origStreamId && newTopic == origTopic) {
      if (propagateMode != null) {
        throw FormatException(
          'Malformed UpdateMessageEvent: incoherent message-move fields; '
          'propagate_mode present but no new channel or topic');
      }
      return null;
    }

    return UpdateMessageMoveData(
      // The `stream_id` field (aka origStreamId) is documented to be present on moves;
      // newStreamId should not be null either because it falls back to origStreamId.
      origStreamId: origStreamId!,
      newStreamId: newStreamId!,

      // The `orig_subject` field (aka origTopic) is documented to be present on moves;
      // newTopic should not be null either because it falls back to origTopic.
      origTopic: origTopic!,
      newTopic: newTopic!,

      // The `propagate_mode` field (aka propagateMode) is documented to be present on moves.
      propagateMode: propagateMode!,
    );
  }
}

/// A Zulip event of type `delete_message`: https://zulip.com/api/get-events#delete_message
@JsonSerializable(fieldRename: FieldRename.snake)
class DeleteMessageEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'delete_message';

  final List<int> messageIds;
  // final int messageId; // Not present; we support the bulk_message_deletion capability
  // The server never actually sends "direct" here yet (it's "private" instead),
  // but we accept both forms for forward-compatibility.
  @MessageTypeConverter()
  final MessageType messageType;
  final int? streamId;
  final TopicName? topic;

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

/// As in [DeleteMessageEvent.messageType],
/// [UpdateMessageFlagsMessageDetail.type],
/// or [TypingEvent.messageType].
@JsonEnum(alwaysCreate: true)
enum MessageType {
  stream,
  direct;
}

class MessageTypeConverter extends JsonConverter<MessageType, String> {
  const MessageTypeConverter();

  @override
  MessageType fromJson(String json) {
    if (json == 'private') json = 'direct'; // TODO(server-future)
    return $enumDecode(_$MessageTypeEnumMap, json);
  }

  @override
  String toJson(MessageType object) {
    return _$MessageTypeEnumMap[object]!;
  }
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
  @JsonKey(includeToJson: true)
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
  @JsonKey(includeToJson: true)
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
    if (result.flag == MessageFlag.read) {
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
  // The server never actually sends "direct" here yet (it's "private" instead),
  // but we accept both forms for forward-compatibility.
  @MessageTypeConverter()
  final MessageType type;
  final bool? mentioned;
  final List<int>? userIds;
  final int? streamId;
  final TopicName? topic;

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
      case MessageType.direct:
        result.userIds as List<int>;
    }
    return result;
  }

  Map<String, dynamic> toJson() => _$UpdateMessageFlagsMessageDetailToJson(this);
}

/// A Zulip event of type `submessage`: https://zulip.com/api/get-events#submessage
@JsonSerializable(fieldRename: FieldRename.snake)
class SubmessageEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'submessage';

  @JsonKey(unknownEnumValue: SubmessageType.unknown)
  final SubmessageType msgType;
  /// [SubmessageData] encoded in JSON.
  // We cannot parse the String into one of the [SubmessageData] classes because
  // information from other submessages are required. Specifically, we need
  // the parsed [WidgetData] from the first [Message.submessages] of the
  // corresponding message.
  final String content;
  final int messageId;
  final int senderId;
  final int submessageId;

  SubmessageEvent({
    required super.id,
    required this.msgType,
    required this.content,
    required this.messageId,
    required this.senderId,
    required this.submessageId,
  });

  factory SubmessageEvent.fromJson(Map<String, dynamic> json) =>
    _$SubmessageEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SubmessageEventToJson(this);
}

/// A Zulip event of type `typing`:
///   https://zulip.com/api/get-events#typing-start
///   https://zulip.com/api/get-events#typing-stop
@JsonSerializable(fieldRename: FieldRename.snake)
class TypingEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'typing';

  final TypingOp op;
  @MessageTypeConverter()
  final MessageType messageType;
  @JsonKey(readValue: _readSenderId)
  final int senderId;
  @JsonKey(name: 'recipients', fromJson: _recipientIdsFromJson)
  final List<int>? recipientIds;
  final int? streamId;
  final TopicName? topic;

  TypingEvent({
    required super.id,
    required this.op,
    required this.messageType,
    required this.senderId,
    required this.recipientIds,
    required this.streamId,
    required this.topic,
  }) : assert(recipientIds == null || isSortedWithoutDuplicates(recipientIds));

  static Object? _readSenderId(Map<Object?, Object?> json, String key) {
    return (json['sender'] as Map<String, dynamic>)['user_id'];
  }

  static List<int>? _recipientIdsFromJson(Object? json) {
    if (json == null) return null;
    return (json as List<Object?>).map(
      (item) => (item as Map<String, Object?>)['user_id'] as int).toList()..sort();
  }

  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    final result = _$TypingEventFromJson(json);
    // Crunchy-shell validation
    switch (result.messageType) {
      case MessageType.stream:
        result.streamId as int;
        result.topic as String;
      case MessageType.direct:
        result.recipientIds as List<int>;
    }
    return result;
  }

  @override
  Map<String, dynamic> toJson() => _$TypingEventToJson(this);
}

/// As in [TypingEvent.op].
@JsonEnum(fieldRename: FieldRename.snake)
enum TypingOp {
  start,
  stop;

  String toJson() => _$TypingOpEnumMap[this]!;
}

/// A Zulip event of type `presence`.
///
/// See:
///   https://zulip.com/api/get-events#presence
@JsonSerializable(fieldRename: FieldRename.snake)
class PresenceEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'presence';

  final int userId;
  // final String email; // deprecated; ignore
  final int serverTimestamp;
  final Map<String, PerClientPresence> presence;

  PresenceEvent({
    required super.id,
    required this.userId,
    required this.serverTimestamp,
    required this.presence,
  });

  factory PresenceEvent.fromJson(Map<String, dynamic> json) =>
    _$PresenceEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PresenceEventToJson(this);
}

/// A value in [PresenceEvent.presence].
///
/// The "per client" name follows the event's structure,
/// but that structure is already an API wart; see the doc's "Changes" note
/// on [client] and on the `client_name` key of the map that holds these values:
///
/// https://zulip.com/api/get-events#presence
/// > Starting with Zulip 7.0 (feature level 178), this will always be "website"
/// > as the server no longer stores which client submitted presence updates.
///
/// This will probably be deprecated in favor of a form like [PerUserPresence].
/// See #1611 and discussion:
///   https://chat.zulip.org/#narrow/channel/378-api-design/topic/presence.20rewrite/near/2200812
// TODO(#1611) update comment about #1611
@JsonSerializable(fieldRename: FieldRename.snake)
class PerClientPresence {
  final String client; // always "website" (on 7.0+, so on all supported servers)
  final PresenceStatus status;
  final int timestamp;
  final bool pushable; // always false (on 7.0+, so on all supported servers)

  PerClientPresence({
    required this.client,
    required this.status,
    required this.timestamp,
    required this.pushable,
  });

  factory PerClientPresence.fromJson(Map<String, dynamic> json) =>
    _$PerClientPresenceFromJson(json);

  Map<String, dynamic> toJson() => _$PerClientPresenceToJson(this);
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
