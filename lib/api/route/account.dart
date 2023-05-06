import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../core.dart';
import 'package:http/http.dart' as http;

part 'account.g.dart';

/// https://zulip.com/api/fetch-api-key
Future<FetchApiKeyResult> fetchApiKey({
  required Uri realmUrl,
  required String username,
  required String password,
}) async {
  final request = http.Request('POST', realmUrl.replace(path: "/api/v1/fetch_api_key"))
    ..bodyFields = encodeParameters({
      'username': RawParameter(username),
      'password': RawParameter(password),
    })!;

  // TODO dedupe with LiveApiConnection; make this function testable
  final client = http.Client();
  final http.Response response;
  try {
    response = await http.Response.fromStream(await client.send(request));
  } finally {
    client.close();
  }

  if (response.statusCode != 200) {
    throw Exception('error on POST fetch_api_key: status ${response.statusCode}');
  }
  final data = utf8.decode(response.bodyBytes);

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
