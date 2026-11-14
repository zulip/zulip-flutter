import 'package:json_annotation/json_annotation.dart';

import '../core.dart';

part 'account.g.dart';

/// https://zulip.com/api/fetch-api-key
Future<FetchApiKeyResult> fetchApiKey(ApiConnection connection, {
  required String username,
  required String password,
}) {
  return connection.post('fetchApiKey', FetchApiKeyResult.fromJson, 'fetch_api_key', {
    'username': RawParameter(username),
    'password': RawParameter(password),
  });
}

@JsonSerializable(fieldRename: FieldRename.snake)
class FetchApiKeyResult {
  final String apiKey;
  final String email;
  final int userId;

  FetchApiKeyResult({
    required this.apiKey,
    required this.email,
    required this.userId,
  });

  factory FetchApiKeyResult.fromJson(Map<String, dynamic> json) =>
    _$FetchApiKeyResultFromJson(json);

  Map<String, dynamic> toJson() => _$FetchApiKeyResultToJson(this);
}

/// https://zulip.com/api/dev-fetch-api-key
Future<FetchApiKeyResult> devFetchApiKey(ApiConnection connection, {
  required String username,
}) {
  return connection.post('devFetchApiKey', FetchApiKeyResult.fromJson, 'dev_fetch_api_key', {
    'username': RawParameter(username),
  });
}

/// https://zulip.com/api/dev-list-users
Future<DevListUsersResult> devListUsers(ApiConnection connection) {
  return connection.get('devListUsers', DevListUsersResult.fromJson, 'dev_list_users', null);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DevListUsersResult {
  final List<DevListUsersEntry> directAdmins;
  final List<DevListUsersEntry> directUsers;

  DevListUsersResult({
    required this.directAdmins,
    required this.directUsers,
  });

  factory DevListUsersResult.fromJson(Map<String, dynamic> json) =>
    _$DevListUsersResultFromJson(json);

  Map<String, dynamic> toJson() => _$DevListUsersResultToJson(this);
}

/// An item in [DevListUsersResult.directAdmins] or [DevListUsersResult.directUsers].
@JsonSerializable(fieldRename: FieldRename.snake)
class DevListUsersEntry {
  final String email;
  final Uri realmUrl;

  DevListUsersEntry({
    required this.email,
    required this.realmUrl,
  });

  factory DevListUsersEntry.fromJson(Map<String, dynamic> json) =>
    _$DevListUsersEntryFromJson(json);

  Map<String, dynamic> toJson() => _$DevListUsersEntryToJson(this);
}

/// https://zulip.com/api/register-client-device
Future<RegisterClientDeviceResult> registerClientDevice(ApiConnection connection) {
  return connection.post('registerClientDevice', RegisterClientDeviceResult.fromJson, 'register_client_device', {});
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RegisterClientDeviceResult {
  final int deviceId;

  RegisterClientDeviceResult({
    required this.deviceId,
  });

  factory RegisterClientDeviceResult.fromJson(Map<String, dynamic> json) =>
    _$RegisterClientDeviceResultFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterClientDeviceResultToJson(this);
}

/// https://zulip.com/api/remove-client-device
Future<void> removeClientDevice(ApiConnection connection, {
  required int deviceId,
}) {
  assert(connection.zulipFeatureLevel! >= 470); // TODO(server-12)
  return connection.post('removeClientDevice', (_) {}, 'remove_client_device', {
    'device_id': deviceId,
  });
}
