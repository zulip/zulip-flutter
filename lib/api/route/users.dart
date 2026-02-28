import 'package:json_annotation/json_annotation.dart';

import '../../basic.dart';
import '../core.dart';
import '../model/model.dart';

part 'users.g.dart';

/// https://zulip.com/api/get-own-user, abridged
///
/// This route's return type is simplified because we use it only
/// as a workaround on old servers.
Future<GetOwnUserResult> getOwnUser(ApiConnection connection) {
  return connection.get('getOwnUser', GetOwnUserResult.fromJson, 'users/me', {});
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetOwnUserResult {
  final int userId;

  // There are many more properties in this route's result.
  // But we use this route only as a workaround on old servers:
  //  https://github.com/zulip/zulip/issues/24980
  //  https://chat.zulip.org/#narrow/stream/378-api-design/topic/user.20ID.20in.20fetch-api-key/near/1540592
  // for which `userId` is the only property we need.
  // TODO(server-7): Drop getOwnUser entirely, relying on userId from fetchApiKey.

  GetOwnUserResult({
    required this.userId,
  });

  factory GetOwnUserResult.fromJson(Map<String, dynamic> json) =>
    _$GetOwnUserResultFromJson(json);

  Map<String, dynamic> toJson() => _$GetOwnUserResultToJson(this);
}

/// https://zulip.com/api/update-status
Future<void> updateStatus(ApiConnection connection, {
  required UserStatusChange change,
}) {
  return connection.post('updateStatus', (_) {}, 'users/me/status', {
    if (change.text case OptionSome(:var value))
      'status_text': RawParameter(value ?? ''),
    if (change.emoji case OptionSome(:var value)) ...{
      'emoji_name': RawParameter(value?.emojiName ?? ''),
      'emoji_code': RawParameter(value?.emojiCode ?? ''),
      'reaction_type': RawParameter(value?.reactionType.toJson() ?? ''),
    },
    if (change.scheduledEndTime case OptionSome(:var value))
      'scheduled_end_time': value,
  });
}


/// https://zulip.com/api/update-presence
///
/// Passes true for `slim_presence` to avoid getting an ancient data format
/// in the response.
// TODO(#1611) Passing `slim_presence` is the old, deprecated way to avoid
//   getting an ancient data format. Pass `last_update_id` to new servers to get
//   that effect (make lastUpdateId required?) and update the dartdoc.
//   (Passing `slim_presence`, for now, shouldn't break things, but we'd like to
//   stop; see discussion:
//     https://chat.zulip.org/#narrow/channel/378-api-design/topic/presence.20rewrite/near/2201035 )
Future<UpdatePresenceResult> updatePresence(ApiConnection connection, {
  int? lastUpdateId,
  int? historyLimitDays,
  bool? newUserInput,
  bool? pingOnly,
  required PresenceStatus status,
}) {
  return connection.post('updatePresence', UpdatePresenceResult.fromJson, 'users/me/presence', {
    'last_update_id': ?lastUpdateId,
    'history_limit_days': ?historyLimitDays,
    'new_user_input': ?newUserInput,
    'ping_only': ?pingOnly,
    'status': RawParameter(status.toJson()),
    'slim_presence': true,
  });
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UpdatePresenceResult {
  final int? presenceLastUpdateId; // TODO(server-9.0) new in FL 263
  final double? serverTimestamp; // 1656958539.6287155 in the example response
  final Map<int, PerUserPresence>? presences;
  // final bool zephyrMirrorActive; // deprecated, ignore

  UpdatePresenceResult({
    required this.presenceLastUpdateId,
    required this.serverTimestamp,
    required this.presences,
  });

  factory UpdatePresenceResult.fromJson(Map<String, dynamic> json) =>
    _$UpdatePresenceResultFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePresenceResultToJson(this);
}
