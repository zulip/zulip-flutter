import 'package:json_annotation/json_annotation.dart';

import 'model.dart';

part 'initial_snapshot.g.dart';

// https://zulip.com/api/register-queue#response
@JsonSerializable(fieldRename: FieldRename.snake)
class InitialSnapshot {
  final String? queueId;
  final int lastEventId;
  final int zulipFeatureLevel;
  final String zulipVersion;
  final String? zulipMergeBase; // TODO(server-5)

  final List<String> alertWords;

  final List<CustomProfileField> customProfileFields;

  // TODO etc., etc.

  final List<Subscription> subscriptions;

  final int maxFileUploadSizeMib;

  // TODO etc., etc.

  InitialSnapshot({
    this.queueId,
    required this.lastEventId,
    required this.zulipFeatureLevel,
    required this.zulipVersion,
    this.zulipMergeBase,
    required this.alertWords,
    required this.customProfileFields,
    required this.subscriptions,
    required this.maxFileUploadSizeMib,
  });

  factory InitialSnapshot.fromJson(Map<String, dynamic> json) =>
      _$InitialSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$InitialSnapshotToJson(this);
}
