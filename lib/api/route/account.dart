// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../core.dart';
import 'package:http/http.dart' as http;

part 'account.g.dart';

/// https://zulip.com/api/fetch-api-key
Future<FetchApiKeyResult> fetchApiKey({
  required String realmUrl,
  required String username,
  required String password,
}) async {
  // TODO dedupe this part with LiveApiConnection; make this function testable
  final response = await http.post(
    Uri.parse("$realmUrl/api/v1/fetch_api_key"),
    body: encodeParameters({
      'username': RawParameter(username),
      'password': RawParameter(password),
    }));
  if (response.statusCode != 200) {
    throw Exception('error on POST fetch_api_key: status ${response.statusCode}');
  }
  final data = utf8.decode(response.bodyBytes);

  final json = jsonDecode(data);
  return FetchApiKeyResult.fromJson(json);
}

@JsonSerializable()
class FetchApiKeyResult {
  final String api_key;
  final String email;

  FetchApiKeyResult({required this.api_key, required this.email});

  factory FetchApiKeyResult.fromJson(Map<String, dynamic> json) =>
    _$FetchApiKeyResultFromJson(json);

  Map<String, dynamic> toJson() => _$FetchApiKeyResultToJson(this);
}
