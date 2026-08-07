import 'dart:async';
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
/// When updating this, also update [kMinAllowedZulipFeatureLevel]
/// and the README.
// TODO(#1838) address all TODO(server-7)
// TODO(#2362) address all TODO(server-8)
// TODO(#2363) address all TODO(server-9)
const kMinAllowedZulipVersion = '9.0';

/// The Zulip feature level reserved for the [kMinAllowedZulipVersion] release.
///
/// For this value, see the API changelog:
///   https://zulip.com/api/changelog
const kMinAllowedZulipFeatureLevel = 277;

/// The oldest Zulip Server version we currently support.
///
/// Should match the policy stated at [kServerSupportDocUrl]:
/// all versions below this should be older than 18 months.
///
/// See also [kMinAllowedZulipVersion], for the version below
/// which we just refuse to connect.
const kMinSupportedZulipVersion = '10.0';

/// The Zulip feature level reserved for the [kMinSupportedZulipVersion] release.
///
/// For this value, see the API changelog:
///   https://zulip.com/api/changelog
const kMinSupportedZulipFeatureLevel = 371;

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
    required this._client,
    required this.useBinding,
  }) : assert((email != null) == (apiKey != null)),
       _authValue = (email != null && apiKey != null)
         ? _authHeaderValue(email: email, apiKey: apiKey)
         : null;

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
      _throwNetworkException(routeName, e);
    }

    final int httpStatus = response.statusCode;
    Map<String, dynamic>? json;
    try {
      // The stream-oriented `bind` method allows decoding to happen in chunks
      // while the response is still being downloaded, improving latency.
      final jsonStream = jsonUtf8Decoder.bind(response.stream);
      json = await jsonStream.single as Map<String, dynamic>?;
    } on http.RequestAbortedException catch (e) {
      // The timeout in [_withTimeout] fired while we were reading the response.
      _throwNetworkException(routeName, e);
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

  /// Make a GET request to the given path with the given params.
  ///
  /// If [timeout] is non-null and the request hasn't completed within it,
  /// including reading the response body,
  /// then the request is aborted, tearing down the connection,
  /// and this throws a [NetworkException]
  /// with kind [NetworkExceptionKind.connectionFailed].
  Future<T> get<T>(String routeName, T Function(Map<String, dynamic>) fromJson,
      String path, Map<String, dynamic>? params, {Duration? timeout}) async {
    final url = realmUrl.replace(
      path: "/api/v1/$path", queryParameters: encodeParameters(params));
    if (timeout == null) {
      return send(routeName, fromJson, http.Request('GET', url));
    }
    return _withTimeout(timeout, (abortTrigger) => send(routeName, fromJson,
      http.AbortableRequest('GET', url, abortTrigger: abortTrigger)));
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

  /// Run [body] with a trigger that fires after [timeout],
  /// for constructing an [http.Abortable] request.
  ///
  /// The timer is canceled when the returned future completes,
  /// so a request that finishes in time leaves no timer behind.
  Future<T> _withTimeout<T>(Duration timeout,
      Future<T> Function(Future<void> abortTrigger) body) async {
    final abortCompleter = Completer<void>();
    final abortTimer = Timer(timeout, abortCompleter.complete);
    try {
      return await body(abortCompleter.future);
    } finally {
      abortTimer.cancel();
    }
  }
}

/// OS-level socket error texts that can arrive as the whole message of a
/// bare [http.ClientException], the exception type erased on the way
/// (see #2417).
///
/// (The pipeline, as of Dart 3.14 / package:http 1.6.0, August 2026:
/// dart:io wraps the OS error text in a [SocketException];
/// `_HttpClientConnection`'s socket-error handler flattens that to
/// `HttpException(message)`; and `IOClient` rethrows it as a
/// `ClientException`.)
///
/// These are strerror(3) texts, so the set is inherently best-effort:
/// this covers the common POSIX texts (shared by Android, iOS, and Linux,
/// except as noted); texts from other platforms can be added as observed.
// TODO(#461): moot once we use the platform-native HTTP clients,
//   which classify these errors natively.
const _erasedSocketErrorMessages = {
  'Software caused connection abort', // ECONNABORTED
  'Connection reset by peer', // ECONNRESET
  'Connection timed out', // ETIMEDOUT
  'Operation timed out', // ETIMEDOUT (Darwin)
  'No route to host', // EHOSTUNREACH
  'Network is unreachable', // ENETUNREACH
  'Network is down', // ENETDOWN
  'Broken pipe', // EPIPE
};

/// Throw a [NetworkException] wrapping the given exception
/// from the underlying HTTP client.
Never _throwNetworkException(String routeName, Object cause) {
  final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
  final (NetworkExceptionKind kind, String message) = switch (cause) {
    // Our own timeout, from [ApiConnection._withTimeout].  Skip the
    // exception's message: it names a package-internal mechanism
    // ("Request aborted by `abortTrigger`"), which wouldn't mean much to a user.
    http.RequestAbortedException() =>
      (.connectionFailed, zulipLocalizations.errorNetworkRequestFailed),
    // A wrapped SocketException, like package:http's IOClient throws
    // for a connection failure.
    SocketException() && http.ClientException(:final message) =>
      (.connectionFailed, message),
    SocketException() => (.connectionFailed, zulipLocalizations.errorNetworkRequestFailed),
    // A connection that died mid-request, its type erased to a bare
    // ClientException on the way to us, so that only the message
    // identifies it.  See #2417 for how these arise and why we match
    // on the message; take care not to match persistent failures,
    // like redirect loops, which would falsely classify as routine.
    // TODO(upstream): have IOClient preserve the type instead, as it
    //   already does for SocketException.
    http.ClientException(:final message)
        // dart:io's orderly-close messages, from _HttpParser
        // and _HttpClientConnection…
        when message.startsWith('Connection closed')
          // …and their one stray, from _HttpClientConnection.send:
          || message == 'Socket closed before request was sent'
          || _erasedSocketErrorMessages.contains(message) =>
      (.connectionFailed, zulipLocalizations.errorNetworkRequestFailed),
    http.ClientException(:final message) => (.other, message),
    TlsException(:final message) => (.other, message),
    _ => (.other, zulipLocalizations.errorNetworkRequestFailed),
  };
  throw NetworkException(routeName: routeName,
    kind: kind, cause: cause, message: message);
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
