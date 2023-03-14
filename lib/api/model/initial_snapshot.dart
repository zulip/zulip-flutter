// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

import 'model.dart';

part 'initial_snapshot.g.dart';

// https://zulip.com/api/register-queue#response
@JsonSerializable()
class InitialSnapshot {
  final String? queue_id;
  final int last_event_id;
  final int zulip_feature_level;
  final String zulip_version;
  final String? zulip_merge_base; // TODO(server-5)

  final List<String> alert_words;

  final List<CustomProfileField> custom_profile_fields;

  // TODO etc., etc.

  final List<Subscription> subscriptions;

  // TODO etc., etc.

  final int user_id;
  final String full_name;

  InitialSnapshot({
    this.queue_id,
    required this.last_event_id,
    required this.zulip_feature_level,
    required this.zulip_version,
    this.zulip_merge_base,
    required this.alert_words,
    required this.custom_profile_fields,
    required this.subscriptions,
    required this.user_id,
    required this.full_name,
  });

  factory InitialSnapshot.fromJson(Map<String, dynamic> json) =>
      _$InitialSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$InitialSnapshotToJson(this);
}
