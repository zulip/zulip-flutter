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
}
