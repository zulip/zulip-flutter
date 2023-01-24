// ignore_for_file: non_constant_identifier_names

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
    final type = json['type'] as String;
    switch (type) {
      case 'alert_words': return AlertWordsEvent.fromJson(json);
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

  UnexpectedEvent({required super.id, required this.json});

  factory UnexpectedEvent.fromJson(Map<String, dynamic> json) =>
      UnexpectedEvent(id: json['id'] as int, json: json);

  @override
  Map<String, dynamic> toJson() => json;
}

/// A Zulip event of type `alert_words`.
@JsonSerializable()
class AlertWordsEvent extends Event {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'alert_words';

  final List<String> alert_words;

  AlertWordsEvent({required super.id, required this.alert_words});

  factory AlertWordsEvent.fromJson(Map<String, dynamic> json) =>
      _$AlertWordsEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AlertWordsEventToJson(this);
}

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
  // events and in the get-messages results is that `match_content` and
  // `match_subject` are absent here.  Already [Message.match_content] and
  // [Message.match_subject] are optional, so no action is needed on that.
  final Message message;

  MessageEvent({required super.id, required this.message});

  factory MessageEvent.fromJson(Map<String, dynamic> json) => MessageEvent(
      id: json['id'] as int,
      message: Message.fromJson({
        ...json['message'] as Map<String, dynamic>,
        'flags':
            (json['flags'] as List<dynamic>).map((e) => e as String).toList(),
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

@JsonSerializable()
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
