import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../core.dart';

part 'account.g.dart';

/// https://zulip.com/api/fetch-api-key
Future<FetchApiKeyResult> fetchApiKey({
  required Uri realmUrl,
  required String username,
  required String password,
}) async {
  final String data;
  // TODO make this function testable by taking ApiConnection from caller
  final connection = ApiConnection.live(realmUrl: realmUrl);
  try {
    data = await connection.post('fetch_api_key', {
      'username': RawParameter(username),
      'password': RawParameter(password),
    });
  } finally {
    connection.close();
  }

  final json = jsonDecode(data);
  return FetchApiKeyResult.fromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class FetchApiKeyResult {
  final String apiKey;
  final String email;
  final int? userId; // TODO(server-7)

  FetchApiKeyResult({
    required this.apiKey,
    required this.email,
    this.userId,
  });

  factory FetchApiKeyResult.fromJson(Map<String, dynamic> json) =>
    _$FetchApiKeyResultFromJson(json);

  Map<String, dynamic> toJson() => _$FetchApiKeyResultToJson(this);
}
