import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

abstract class Auth {
  String get realmUrl;

  String get email;

  String get apiKey;
}

class ApiConnection {
  ApiConnection({required this.auth});

  final Auth auth;

  Map<String, String> _headers() {
    // TODO memoize
    final authBytes = utf8.encode("${auth.email}:${auth.apiKey}");
    return {
      'Authorization': 'Basic ${base64.encode(authBytes)}',
    };
  }

  Future<String> get(String route, Map<String, dynamic>? params) async {
    final baseUrl = Uri.parse(auth.realmUrl);
    final url = Uri(
        scheme: baseUrl.scheme,
        userInfo: baseUrl.userInfo,
        host: baseUrl.host,
        port: baseUrl.port,
        path: "/api/v1/$route",
        queryParameters: params?.map((k, v) => MapEntry(k, jsonEncode(v))));
    if (kDebugMode) print("GET $url");
    final response = await http.get(url, headers: _headers());
    if (response.statusCode != 200) {
      throw Exception("error on GET $route: status ${response.statusCode}");
    }
    return utf8.decode(response.bodyBytes);
  }

  Future<String> post(String route, Map<String, dynamic>? params) async {
    final response = await http.post(
        Uri.parse("${auth.realmUrl}/api/v1/$route"),
        headers: _headers(),
        body: params?.map((k, v) => MapEntry(k, jsonEncode(v))));
    if (response.statusCode != 200) {
      throw Exception("error on POST $route: status ${response.statusCode}");
    }
    return utf8.decode(response.bodyBytes);
  }
}
