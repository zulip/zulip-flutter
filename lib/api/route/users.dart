import 'package:json_annotation/json_annotation.dart';

import '../core.dart';

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
