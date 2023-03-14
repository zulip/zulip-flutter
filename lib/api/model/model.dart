// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

/// As in `custom_profile_fields` in the initial snapshot.
///
/// https://zulip.com/api/register-queue#response
@JsonSerializable()
class CustomProfileField {
  final int id;
  final int type; // TODO enum; also TODO(server-6) a value added
  final int order;
  final String name;
  final String hint;
  final String field_data;
  final bool? display_in_profile_summary; // TODO(server-6)

  CustomProfileField({
    required this.id,
    required this.type,
    required this.order,
    required this.name,
    required this.hint,
    required this.field_data,
    required this.display_in_profile_summary,
  });

  factory CustomProfileField.fromJson(Map<String, dynamic> json) =>
      _$CustomProfileFieldFromJson(json);

  Map<String, dynamic> toJson() => _$CustomProfileFieldToJson(this);
}

/// As in `subscriptions` in the initial snapshot.
@JsonSerializable()
class Subscription {
  final int stream_id;
  final String name;
  final String description;
  final String rendered_description;
  final int date_created;
  final bool invite_only;

  // final List<int> subscribers; // we register with include_subscribers false

  final bool? desktop_notifications;
  final bool? email_notifications;
  final bool? wildcard_mentions_notify;
  final bool? push_notifications;
  final bool? audible_notifications;

  final bool pin_to_top;

  final String email_address;

  final bool is_muted;

  // final bool? in_home_view; // deprecated; ignore

  // final bool? is_announcement_only; // deprecated; ignore
  final bool? is_web_public; // TODO(server-??): doc doesn't say when added

  final String color;

  final int stream_post_policy; // TODO enum
  final int? message_retention_days;
  final bool history_public_to_subscribers;

  final int? first_message_id;
  final int? stream_weekly_traffic;

  final int? can_remove_subscribers_group_id; // TODO(server-6)

  Subscription({
    required this.stream_id,
    required this.name,
    required this.description,
    required this.rendered_description,
    required this.date_created,
    required this.invite_only,
    this.desktop_notifications,
    this.email_notifications,
    this.wildcard_mentions_notify,
    this.push_notifications,
    this.audible_notifications,
    required this.pin_to_top,
    required this.email_address,
    required this.is_muted,
    this.is_web_public,
    required this.color,
    required this.stream_post_policy,
    this.message_retention_days,
    required this.history_public_to_subscribers,
    this.first_message_id,
    this.stream_weekly_traffic,
    this.can_remove_subscribers_group_id,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);
}

/// As in the get-messages response.
///
/// https://zulip.com/api/get-messages#response
abstract class Message {
  final String? avatar_url;
  final String client;
  final String content;
  final String content_type;

  // final List<MessageEditHistory> edit_history; // TODO handle
  final int id;
  final bool is_me_message;
  final int? last_edit_timestamp;

  // final List<Reaction> reactions; // TODO handle
  final int recipient_id;
  final String sender_email;
  final String sender_full_name;
  final int sender_id;
  final String sender_realm_str;
  final String subject; // TODO call it "topic" internally; also similar others
  // final List<string> submessages; // TODO handle
  final int timestamp;
  String get type;

  // final List<TopicLink> topic_links; // TODO handle
  // final string type; // handled by runtime type of object
  final List<String> flags; // TODO enum
  final String? match_content;
  final String? match_subject;

  Message({
    this.avatar_url,
    required this.client,
    required this.content,
    required this.content_type,
    required this.id,
    required this.is_me_message,
    this.last_edit_timestamp,
    required this.recipient_id,
    required this.sender_email,
    required this.sender_full_name,
    required this.sender_id,
    required this.sender_realm_str,
    required this.subject,
    required this.timestamp,
    required this.flags,
    this.match_content,
    this.match_subject,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    if (type == 'stream') return StreamMessage.fromJson(json);
    if (type == 'private') return PmMessage.fromJson(json);
    throw Exception("Message.fromJson: unexpected message type $type");
  }

  Map<String, dynamic> toJson();
}

@JsonSerializable()
class StreamMessage extends Message {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'stream';

  final String display_recipient;
  final int stream_id;

  StreamMessage({
    super.avatar_url,
    required super.client,
    required super.content,
    required super.content_type,
    required super.id,
    required super.is_me_message,
    super.last_edit_timestamp,
    required super.recipient_id,
    required super.sender_email,
    required super.sender_full_name,
    required super.sender_id,
    required super.sender_realm_str,
    required super.subject,
    required super.timestamp,
    required super.flags,
    super.match_content,
    super.match_subject,
    required this.display_recipient,
    required this.stream_id,
  });

  factory StreamMessage.fromJson(Map<String, dynamic> json) =>
      _$StreamMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StreamMessageToJson(this);
}

@JsonSerializable()
class PmRecipient {
  final int id;
  final String email;
  final String full_name;

  // final String? short_name; // obsolete, ignore
  // final bool? is_mirror_dummy; // obsolete, ignore

  PmRecipient({required this.id, required this.email, required this.full_name});

  factory PmRecipient.fromJson(Map<String, dynamic> json) =>
      _$PmRecipientFromJson(json);

  Map<String, dynamic> toJson() => _$PmRecipientToJson(this);
}

@JsonSerializable()
class PmMessage extends Message {
  @override
  @JsonKey(includeToJson: true)
  String get type => 'private';

  final List<PmRecipient> display_recipient;

  PmMessage({
    super.avatar_url,
    required super.client,
    required super.content,
    required super.content_type,
    required super.id,
    required super.is_me_message,
    super.last_edit_timestamp,
    required super.recipient_id,
    required super.sender_email,
    required super.sender_full_name,
    required super.sender_id,
    required super.sender_realm_str,
    required super.subject,
    required super.timestamp,
    required super.flags,
    super.match_content,
    super.match_subject,
    required this.display_recipient,
  });

  factory PmMessage.fromJson(Map<String, dynamic> json) =>
      _$PmMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PmMessageToJson(this);
}
