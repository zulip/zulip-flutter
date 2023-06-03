import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../log.dart';
import 'exception.dart';

/// A value for an API request parameter, to use directly without JSON encoding.
class RawParameter {
  RawParameter(this.value);

  final String value;
}

/// All the information to talk to a Zulip server, real or fake.
///
/// See also:
///  * `FakeApiConnection` in the test suite, which implements this
///    for use in tests.
class ApiConnection {
  /// Construct an API connection with an arbitrary [http.Client], real or fake.
  ///
  /// For talking to a live server, use [ApiConnection.live].
  ApiConnection({
    required this.realmUrl,
    required this.zulipFeatureLevel, // required even though nullable; see field doc
    String? email,
    String? apiKey,
    required http.Client client,
  }) : assert((email != null) == (apiKey != null)),
       _authValue = (email != null && apiKey != null)
         ? _authHeaderValue(email: email, apiKey: apiKey)
         : null,
       _client = client;

  /// Construct an API connection that talks to a live Zulip server over the real network.
  ApiConnection.live({
    required Uri realmUrl,
    required int? zulipFeatureLevel, // required even though nullable; see field doc
    String? email,
    String? apiKey,
  }) : this(client: http.Client(),
            realmUrl: realmUrl, zulipFeatureLevel: zulipFeatureLevel,
            email: email, apiKey: apiKey);

  final Uri realmUrl;

  /// The server's last known Zulip feature level, if any.
  ///
  /// Individual route/endpoint bindings may use this to adapt
  /// for compatibility with older servers.
  ///
  /// If this is null, this [ApiConnection] may be used only for the
  /// [getServerSettings] route.  Calls to other routes may throw an exception.
  /// Constructors therefore require this as a parameter, so that a null value
  /// must be passed explicitly.
  ///
  /// See:
  ///  * API docs at <https://zulip.com/api/changelog>.
  int? zulipFeatureLevel;

  final String? _authValue;

  void addAuth(http.BaseRequest request) {
    if (_authValue != null) {
      request.headers['Authorization'] = _authValue!;
    }
  }

  final http.Client _client;

  bool _isOpen = true;

  Future<T> send<T>(String routeName, T Function(Map<String, dynamic>) fromJson,
      http.BaseRequest request) async {
    assert(_isOpen);

    assert(debugLog("${request.method} ${request.url}"));

    addAuth(request);

    final http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } catch (e) {
      final String message;
      if (e is http.ClientException) {
        message = e.message;
      } else if (e is TlsException) {
        message = e.message;
      } else {
        message = 'Network request failed';
      }
      throw NetworkException(routeName: routeName, cause: e, message: message);
    }

    final int httpStatus = response.statusCode;
    Map<String, dynamic>? json;
    try {
      final bytes = await response.stream.toBytes();
      json = jsonDecode(utf8.decode(bytes));
    } catch (e) {
      // We'll throw something below, seeing `json` is null.
    }

    if (httpStatus != 200 || json == null) {
      throw _makeApiException(routeName, httpStatus, json);
    }

    try {
      return fromJson(json);
    } catch (e) {
      throw MalformedServerResponseException(
        routeName: routeName, httpStatus: httpStatus, data: json);
    }
  }

  void close() {
    assert(_isOpen);
    _client.close();
    _isOpen = false;
  }

  Future<T> get<T>(String routeName, T Function(Map<String, dynamic>) fromJson,
      String path, Map<String, dynamic>? params) async {
    final url = realmUrl.replace(
      path: "/api/v1/$path", queryParameters: encodeParameters(params));
    final request = http.Request('GET', url);
    return send(routeName, fromJson, request);
  }

  Future<T> post<T>(String routeName, T Function(Map<String, dynamic>) fromJson,
      String path, Map<String, dynamic>? params) async {
    final url = realmUrl.replace(path: "/api/v1/$path");
    final request = http.Request('POST', url);
    if (params != null) {
      request.bodyFields = encodeParameters(params)!;
    }
    return send(routeName, fromJson, request);
  }

  Future<T> postFileFromStream<T>(String routeName, T Function(Map<String, dynamic>) fromJson,
      String path, Stream<List<int>> content, int length, {String? filename}) async {
    final url = realmUrl.replace(path: "/api/v1/$path");
    final request = http.MultipartRequest('POST', url)
      ..files.add(http.MultipartFile('file', content, length, filename: filename));
    return send(routeName, fromJson, request);
  }
}

ApiRequestException _makeApiException(String routeName, int httpStatus, Map<String, dynamic>? json) {
  assert(httpStatus != 200 || json == null);
  if (400 <= httpStatus && httpStatus <= 499) {
    if (json != null && json['result'] == 'error'
        && json['code'] is String? && json['msg'] is String) {
      json.remove('result');
      return ZulipApiException( // TODO(log): systematically log these
        routeName: routeName,
        httpStatus: httpStatus,
        // When `code` is missing, we fall back to `BAD_REQUEST`,
        // the same value the server uses when nobody's made it more specific.
        // TODO(server): `code` should always be present.  Get the "Invalid API key" case fixed.
        code: json.remove('code') ?? 'BAD_REQUEST',
        message: json.remove('msg'),
        data: json,
      );
    }
  } else if (500 <= httpStatus && httpStatus <= 599) {
    return Server5xxException(
      routeName: routeName, httpStatus: httpStatus, data: json);
  }
  return MalformedServerResponseException( // TODO(log): systematically log these
    routeName: routeName, httpStatus: httpStatus, data: json);
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

Map<String, String>? encodeParameters(Map<String, dynamic>? params) {
  return params?.map((k, v) =>
    MapEntry(k, v is RawParameter ? v.value : jsonEncode(v)));
}
