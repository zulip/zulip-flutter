import 'dart:convert';

import 'package:http/http.dart' as http;

import '../log.dart';

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
  ApiConnection({
    required this.realmUrl,
    String? email,
    String? apiKey,
    required http.Client client,
  }) : assert((email != null) == (apiKey != null)),
       _authValue = (email != null && apiKey != null)
         ? _authHeaderValue(email: email, apiKey: apiKey)
         : null,
       _client = client;

  final Uri realmUrl;

  final String? _authValue;

  void addAuth(http.BaseRequest request) {
    if (_authValue != null) {
      request.headers['Authorization'] = _authValue!;
    }
  }

  final http.Client _client;

  bool _isOpen = true;

  Future<http.Response> send(http.BaseRequest request) async {
    assert(_isOpen);
    return http.Response.fromStream(await _client.send(request));
  }

  void close() {
    assert(_isOpen);
    _client.close();
    _isOpen = false;
  }

  Future<String> get(String route, Map<String, dynamic>? params) async {
    final url = realmUrl.replace(
        path: "/api/v1/$route", queryParameters: encodeParameters(params));
    assert(debugLog("GET $url"));
    final request = http.Request('GET', url);
    addAuth(request);
    final response = await send(request);
    return _decodeResponse(response);
  }

  Future<String> post(String route, Map<String, dynamic>? params) async {
    final url = realmUrl.replace(path: "/api/v1/$route");
    final request = http.Request('POST', url);
    if (params != null) {
      request.bodyFields = encodeParameters(params)!;
    }
    addAuth(request);
    final response = await send(request);
    return _decodeResponse(response);
  }

  Future<String> postFileFromStream(String route, Stream<List<int>> content, int length, { String? filename }) async {
    http.MultipartRequest request = http.MultipartRequest('POST', Uri.parse("$realmUrl/api/v1/$route"))
      ..files.add(http.MultipartFile('file', content, length, filename: filename));
    addAuth(request);
    final response = await send(request);
    return _decodeResponse(response);
  }

  static String _decodeResponse(http.Response response) {
    if (response.statusCode != 200) {
      final request = response.request!;
      throw Exception("error on ${request.method} ${request.url.path}: status ${response.statusCode}");
    }
    return utf8.decode(response.bodyBytes);
  }
}

String _authHeaderValue({required String email, required String apiKey}) {
  final authBytes = utf8.encode("$email:$apiKey");
  return 'Basic ${base64.encode(authBytes)}';
}

// TODO memoize auth header map on PerAccountStore
Map<String, String> authHeader({required String email, required String apiKey}) {
  return {
    'Authorization': _authHeaderValue(email: email, apiKey: apiKey),
  };
}

/// An [ApiConnection] that makes real network requests to a real server.
class LiveApiConnection extends ApiConnection {
  LiveApiConnection({
    required super.realmUrl,
    required String email,
    required String apiKey,
  }) : super(email: email, apiKey: apiKey, client: http.Client());
}

Map<String, String>? encodeParameters(Map<String, dynamic>? params) {
  return params?.map((k, v) =>
      MapEntry(k, v is RawParameter ? v.value : jsonEncode(v)));
}
