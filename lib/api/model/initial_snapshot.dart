import 'package:json_annotation/json_annotation.dart';

import 'model.dart';

part 'initial_snapshot.g.dart';

// https://zulip.com/api/register-queue#response
@JsonSerializable(fieldRename: FieldRename.snake)
class InitialSnapshot {
  // Keep these fields in the order they appear in the API docs.
  // (For many API types we choose a more logical order than the docs.
  // But this one is so long that that'd make it become impossible to
  // compare the lists by hand.)

  final String? queueId;
  final int lastEventId;
  final int zulipFeatureLevel;
  final String zulipVersion;
  final String? zulipMergeBase; // TODO(server-5)

  final List<String> alertWords;

  final List<CustomProfileField> customProfileFields;

  // TODO etc., etc.

  final List<Subscription> subscriptions;

  final List<ZulipStream> streams;

  final int maxFileUploadSizeMib;

  @JsonKey(readValue: _readUsersIsActiveFallbackTrue)
  final List<User> realmUsers;
  @JsonKey(readValue: _readUsersIsActiveFallbackFalse)
  final List<User> realmNonActiveUsers;
  @JsonKey(readValue: _readUsersIsActiveFallbackTrue)
  final List<User> crossRealmBots;

  // TODO etc., etc.
  // If adding fields, keep them all in the order they appear in the API docs.

  // `is_active` is sometimes absent:
  //   https://chat.zulip.org/#narrow/stream/412-api-documentation/topic/.60is_active.60.20in.20.60.2Fregister.60.20response/near/1371603
  // But for our model it's convenient to always have it; so, fill it in.
  static Object? _readUsersIsActiveFallbackTrue(Map json, String key) {
    final list = (json[key] as List<dynamic>);
    for (final Map<String, dynamic> user in list) {
      user.putIfAbsent('is_active', () => true);
    }
    return list;
  }
  static Object? _readUsersIsActiveFallbackFalse(Map json, String key) {
    final list = (json[key] as List<dynamic>);
    for (final Map<String, dynamic> user in list) {
      user.putIfAbsent('is_active', () => false);
    }
    return list;
  }

  InitialSnapshot({
    this.queueId,
    required this.lastEventId,
    required this.zulipFeatureLevel,
    required this.zulipVersion,
    this.zulipMergeBase,
    required this.alertWords,
    required this.customProfileFields,
    required this.subscriptions,
    required this.streams,
    required this.maxFileUploadSizeMib,
    required this.realmUsers,
    required this.realmNonActiveUsers,
    required this.crossRealmBots,
  });

  factory InitialSnapshot.fromJson(Map<String, dynamic> json) =>
    _$InitialSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$InitialSnapshotToJson(this);
}
