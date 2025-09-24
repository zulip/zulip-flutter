import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../log.dart';
import '../model/binding.dart';
import '../model/localizations.dart';
import 'exception.dart';

/// The Zulip Server version below which we should refuse to connect.
///
/// When updating this, also update [kMinSupportedZulipFeatureLevel]
/// and the README.
// TODO(#1838) address all TODO(server-7)
const kMinSupportedZulipVersion = '7.0';

/// The Zulip feature level reserved for the [kMinSupportedZulipVersion] release.
///
/// For this value, see the API changelog:
///   https://zulip.com/api/changelog
const kMinSupportedZulipFeatureLevel = 185;

/// The doc stating our oldest supported server version.
// TODO: Instead, link to new Help Center doc once we have it:
//   https://github.com/zulip/zulip/issues/23842
final kServerSupportDocUrl = Uri.parse(
  'https://zulip.readthedocs.io/en/latest/overview/release-lifecycle.html#client-apps');

/// A fused JSON + UTF-8 decoder.
///
/// This object is an instance of [`_JsonUtf8Decoder`][1] which is
/// a fast-path present in VM and WASM standard library implementations.
///
/// [1]: https://github.com/dart-lang/sdk/blob/6c7452ac1530fe6161023c9b3007764ab26cc96d/sdk/lib/_internal/vm/lib/convert_patch.dart#L55
final jsonUtf8Decoder = const Utf8Decoder().fuse(const JsonDecoder());

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
    required this.useBinding,
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
            email: email, apiKey: apiKey, useBinding: true);

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

  /// Toggles the use of a user-agent generated via [ZulipBinding].
  ///
  /// When set to true, the user-agent will be generated using
  /// [ZulipBinding.deviceInfo] and [ZulipBinding.packageInfo].
  /// Otherwise, a fallback user-agent [kFallbackUserAgentHeader] will be used.
  final bool useBinding;

  Map<String, String>? _cachedUserAgentHeader;

  void addUserAgent(http.BaseRequest request) {
    if (!useBinding) {
      request.headers.addAll(kFallbackUserAgentHeader);
      return;
    }

    if (_cachedUserAgentHeader != null) {
      request.headers.addAll(_cachedUserAgentHeader!);
      return;
    }

    final deviceInfo = ZulipBinding.instance.syncDeviceInfo;
    final packageInfo = ZulipBinding.instance.syncPackageInfo;
    if (deviceInfo == null || packageInfo == null) {
      request.headers.addAll(kFallbackUserAgentHeader);
      return;
    }
    _cachedUserAgentHeader = _buildUserAgentHeader(deviceInfo, packageInfo);
    request.headers.addAll(_cachedUserAgentHeader!);
  }

  final String? _authValue;

  void addAuth(http.BaseRequest request) {
    if (_authValue != null) {
      request.headers['Authorization'] = _authValue;
    }
  }

  final http.Client _client;

  bool _isOpen = true;

  Future<T> send<T>(String routeName, T Function(Map<String, dynamic>) fromJson,
    http.BaseRequest request, {
    bool useAuth = true,
    String? overrideUserAgent,
  }) async {
    assert(_isOpen);

    assert(debugLog("${request.method} ${request.url}"));

    if (useAuth) {
      if (request.url.origin != realmUrl.origin) {
        // No caller should get here with a URL whose origin isn't the realm's.
        // If this does happen, it's important not to proceed, because we'd be
        // sending the user's auth credentials.
        throw StateError("ApiConnection.send called with useAuth on off-realm URL");
      }
      addAuth(request);
    }

    if (overrideUserAgent != null) {
      request.headers['User-Agent'] = overrideUserAgent;
    } else {
      addUserAgent(request);
    }

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
        final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
        message = zulipLocalizations.errorNetworkRequestFailed;
      }
      throw NetworkException(routeName: routeName, cause: e, message: message);
    }

    final int httpStatus = response.statusCode;
    Map<String, dynamic>? json;
    try {
      // The stream-oriented `bind` method allows decoding to happen in chunks
      // while the response is still being downloaded, improving latency.
      final jsonStream = jsonUtf8Decoder.bind(response.stream);
      json = await jsonStream.single as Map<String, dynamic>?;
    } catch (e) {
      // We'll throw something below, seeing `json` is null.
    }

    if (httpStatus != 200 || json == null) {
      throw _makeApiException(routeName, httpStatus, json);
    }

    try {
      return fromJson(json);
    } catch (exception, stackTrace) { // TODO(log)
      Error.throwWithStackTrace(
        MalformedServerResponseException(
          routeName: routeName, httpStatus: httpStatus, data: json,
          causeException: exception),
        stackTrace);
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
      String path, Map<String, dynamic>? params, {String? overrideUserAgent}) async {
    final url = realmUrl.replace(path: "/api/v1/$path");
    final request = http.Request('POST', url);
    if (params != null) {
      request.bodyFields = encodeParameters(params)!;
    }
    return send(routeName, fromJson, request, overrideUserAgent: overrideUserAgent);
  }

  Future<T> postFileFromStream<T>(String routeName, T Function(Map<String, dynamic>) fromJson,
      String path, Stream<List<int>> content, int length,
      {String? filename, String? contentType}) async {
    final url = realmUrl.replace(path: "/api/v1/$path");
    MediaType? parsedContentType;
    if (contentType != null) {
      try {
        parsedContentType = MediaType.parse(contentType);
      } on FormatException {
        // TODO log
      }
    }
    final request = http.MultipartRequest('POST', url)
      ..files.add(http.MultipartFile('file', content, length,
        filename: filename, contentType: parsedContentType));
    return send(routeName, fromJson, request);
  }

  Future<T> patch<T>(String routeName, T Function(Map<String, dynamic>) fromJson,
      String path, Map<String, dynamic>? params) async {
    final url = realmUrl.replace(path: "/api/v1/$path");
    final request = http.Request('PATCH', url);
    if (params != null) {
      request.bodyFields = encodeParameters(params)!;
    }
    return send(routeName, fromJson, request);
  }

  Future<T> delete<T>(String routeName, T Function(Map<String, dynamic>) fromJson,
      String path, Map<String, dynamic>? params) async {
    final url = realmUrl.replace(path: "/api/v1/$path");
    final request = http.Request('DELETE', url);
    if (params != null) {
      request.bodyFields = encodeParameters(params)!;
    }
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
        code: (json.remove('code') as String?) ?? 'BAD_REQUEST',
        message: json.remove('msg') as String,
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

/// Fallback user-agent header.
///
/// See documentation on [ApiConnection.useBinding].
@visibleForTesting
const kFallbackUserAgentHeader = {'User-Agent': 'ZulipFlutter'};

Map<String, String> userAgentHeader() {
  final deviceInfo = ZulipBinding.instance.syncDeviceInfo;
  final packageInfo = ZulipBinding.instance.syncPackageInfo;
  if (deviceInfo == null || packageInfo == null) {
    return kFallbackUserAgentHeader;
  }
  return _buildUserAgentHeader(deviceInfo, packageInfo);
}

Map<String, String> _buildUserAgentHeader(BaseDeviceInfo deviceInfo, PackageInfo packageInfo) {
  final osInfo = switch (deviceInfo) {
    AndroidDeviceInfo(
      :var release)       => 'Android $release', // "Android 14"
    IosDeviceInfo(
      :var systemVersion) => 'iOS $systemVersion', // "iOS 17.4"
    MacOsDeviceInfo(
      :var majorVersion,
      :var minorVersion,
      :var patchVersion)  => 'macOS $majorVersion.$minorVersion.$patchVersion', // "macOS 14.5.0"
    WindowsDeviceInfo()   => 'Windows', // "Windows"
    LinuxDeviceInfo(
      :var name,
      :var versionId)     => 'Linux; $name${versionId != null ? ' $versionId' : ''}', // "Linux; Fedora Linux 40" or "Linux; Fedora Linux"
    _                     => throw UnimplementedError(),
  };
  final PackageInfo(:version, :buildNumber) = packageInfo;

  // Possible examples:
  //  'ZulipFlutter/0.0.15+15 (Android 14)'
  //  'ZulipFlutter/0.0.15+15 (iOS 17.4)'
  //  'ZulipFlutter/0.0.15+15 (macOS 14.5.0)'
  //  'ZulipFlutter/0.0.15+15 (Windows)'
  //  'ZulipFlutter/0.0.15+15 (Linux; Fedora Linux 40)'
  return {
    'User-Agent': 'ZulipFlutter/$version+$buildNumber ($osInfo)',
  };
}

Map<String, String>? encodeParameters(Map<String, dynamic>? params) {
  return params?.map((k, v) =>
    MapEntry(k, v is RawParameter ? v.value : jsonEncode(v)));
}
