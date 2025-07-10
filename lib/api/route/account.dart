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
  final int? userId; // TODO(server-7)

  FetchApiKeyResult({
    required this.apiKey,
    required this.email,
    required this.userId,
  });

  factory FetchApiKeyResult.fromJson(Map<String, dynamic> json) =>
    _$FetchApiKeyResultFromJson(json);

  Map<String, dynamic> toJson() => _$FetchApiKeyResultToJson(this);
}
