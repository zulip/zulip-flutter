import 'package:json_annotation/json_annotation.dart';

import '../../basic.dart';
import '../core.dart';
import '../model/model.dart';

part 'users.g.dart';

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
    }
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
  final int? presenceLastUpdateId;
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
