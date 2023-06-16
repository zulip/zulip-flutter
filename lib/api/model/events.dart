import 'package:json_annotation/json_annotation.dart';

import 'model.dart';

part 'events.g.dart';

/// A Zulip event.
///
/// See API documentation: https://zulip.com/api/get-events
abstract class Event {
  final int id;
  String get type;

  Event({required this.id});

  factory Event.fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'alert_words': return AlertWordsEvent.fromJson(json);
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
      case 'message': return MessageEvent.fromJson(json);
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

  UnexpectedEvent({required this.json}) : super(id: json['id'] as int);

  factory UnexpectedEvent.fromJson(Map<String, dynamic> json) =>
    UnexpectedEvent(json: json);

  @override
  Map<String, dynamic> toJson() => json;
}

/// A Zulip event of type `alert_words`.
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

/// A Zulip event of type `realm_user`.
abstract class RealmUserEvent extends Event {
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
  @JsonKey(readValue: _readFromPerson) final int? role; // TODO enum
  @JsonKey(readValue: _readFromPerson) final bool? isBillingAdmin;
  @JsonKey(readValue: _readFromPerson) final String? deliveryEmail; // TODO handle JSON `null`
  @JsonKey(readValue: _readFromPerson) final RealmUserUpdateCustomProfileField? customProfileField;
  @JsonKey(readValue: _readFromPerson) final String? newEmail;

  static Object? _readFromPerson(Map json, String key) {
    return (json['person'] as Map<String, dynamic>)[key];
  }

  RealmUserUpdateEvent({
    required super.id,
    required this.userId,
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
abstract class StreamEvent extends Event {
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

/// A Zulip event of type `message`.
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
