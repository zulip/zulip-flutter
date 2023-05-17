import 'dart:convert';

import 'package:http/http.dart' as http;

import '../log.dart';

class Auth {
  Auth({required this.realmUrl, required this.email, required this.apiKey})
   : assert(realmUrl.query.isEmpty && realmUrl.fragment.isEmpty);

  final Uri realmUrl;
  final String email;
  final String apiKey;
}

/// A value for an API request parameter, to use directly without JSON encoding.
class RawParameter {
  RawParameter(this.value);

  final String value;
}

/// All the information to talk to a Zulip server, real or fake.
///
/// See also:
///  * [LiveApiConnection], which implements this for talking to a
///    real Zulip server.
///  * `FakeApiConnection` in the test suite, which implements this
///    for use in tests.
abstract class ApiConnection {
  ApiConnection({required this.auth});

  // TODO move auth field to subclass, have just a realmUrl getter;
  //   that ensures nothing assumes base class has a real API key
  final Auth auth;

  void close();

  Future<String> get(String route, Map<String, dynamic>? params);

  Future<String> post(String route, Map<String, dynamic>? params);

  Future<String> postFileFromStream(String route, Stream<List<int>> content, int length, { String? filename });
}

// TODO memoize auth header on LiveApiConnection and PerAccountStore
Map<String, String> authHeader({required String email, required String apiKey}) {
  final authBytes = utf8.encode("$email:$apiKey");
  return {
    'Authorization': 'Basic ${base64.encode(authBytes)}',
  };
}

/// An [ApiConnection] that makes real network requests to a real server.
class LiveApiConnection extends ApiConnection {
  LiveApiConnection({required super.auth});

  final http.Client _client = http.Client();

  bool _isOpen = true;

  @override
  void close() {
    assert(_isOpen);
    _client.close();
    _isOpen = false;
  }

  Map<String, String> _headers() {
    return authHeader(email: auth.email, apiKey: auth.apiKey);
  }

  @override
  Future<String> get(String route, Map<String, dynamic>? params) async {
    assert(_isOpen);
    final url = auth.realmUrl.replace(
        path: "/api/v1/$route", queryParameters: encodeParameters(params));
    assert(debugLog("GET $url"));
    final response = await _client.get(url, headers: _headers());
    if (response.statusCode != 200) {
      throw Exception("error on GET $route: status ${response.statusCode}");
    }
    return utf8.decode(response.bodyBytes);
  }

  @override
  Future<String> post(String route, Map<String, dynamic>? params) async {
    assert(_isOpen);
    final response = await _client.post(
        auth.realmUrl.replace(path: "/api/v1/$route"),
        headers: _headers(),
        body: encodeParameters(params));
    if (response.statusCode != 200) {
      throw Exception("error on POST $route: status ${response.statusCode}");
    }
    return utf8.decode(response.bodyBytes);
  }

  @override
  Future<String> postFileFromStream(String route, Stream<List<int>> content, int length, { String? filename }) async {
    assert(_isOpen);
    http.MultipartRequest request = http.MultipartRequest('POST', Uri.parse("${auth.realmUrl}/api/v1/$route"))
      ..files.add(http.MultipartFile('file', content, length, filename: filename))
      ..headers.addAll(_headers());
    final response = await http.Response.fromStream(await _client.send(request));
    if (response.statusCode != 200) {
      throw Exception("error on file-upload POST $route: status ${response.statusCode}");
    }
    return utf8.decode(response.bodyBytes);
  }
}

Map<String, dynamic>? encodeParameters(Map<String, dynamic>? params) {
  return params?.map((k, v) =>
      MapEntry(k, v is RawParameter ? v.value : jsonEncode(v)));
}
