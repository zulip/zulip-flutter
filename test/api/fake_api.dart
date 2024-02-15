import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zulip/api/core.dart';
import 'package:zulip/model/store.dart';

import '../example_data.dart' as eg;

sealed class _PreparedResponse {
}

class _PreparedException extends _PreparedResponse {
  final Object exception;

  _PreparedException({required this.exception});
}

class _PreparedSuccess extends _PreparedResponse {
  final int httpStatus;
  final List<int> bytes;

  _PreparedSuccess({required this.httpStatus, required this.bytes});
}

/// An [http.Client] that accepts and replays canned responses, for testing.
class FakeHttpClient extends http.BaseClient {

  http.BaseRequest? lastRequest;

  http.BaseRequest? takeLastRequest() {
    final result = lastRequest;
    lastRequest = null;
    return result;
  }

  _PreparedResponse? _nextResponse;

  // Please add more features to this mocking API as needed.  For example:
  //  * preparing more than one request, and logging more than one request

  /// Prepare the response for the next request.
  ///
  /// If `exception` is null, the next request will produce an [http.Response]
  /// with the given `httpStatus`, defaulting to 200.  The body of the response
  /// will be `body` if non-null, or `jsonEncode(json)` if `json` is non-null,
  /// or else ''.  The `body` and `json` parameters must not both be non-null.
  ///
  /// If `exception` is non-null, then `httpStatus`, `body`, and `json` must
  /// all be null, and the next request will throw the given exception.
  void prepare({
    Object? exception,
    int? httpStatus,
    Map<String, dynamic>? json,
    String? body,
  }) {
    assert(_nextResponse == null,
      'FakeApiConnection.prepare was called while already expecting a request');
    if (exception != null) {
      assert(httpStatus == null && json == null && body == null);
      _nextResponse = _PreparedException(exception: exception);
    } else {
      assert((json == null) || (body == null));
      final String resolvedBody = switch ((body, json)) {
        (var body?, _) => body,
        (_, var json?) => jsonEncode(json),
        _              => '',
      };
      _nextResponse = _PreparedSuccess(
        httpStatus: httpStatus ?? 200,
        bytes: utf8.encode(resolvedBody),
      );
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    lastRequest = request;
    final response = _nextResponse!;
    _nextResponse = null;
    switch (response) {
      case _PreparedException(:var exception):
        return Future(() => throw exception);
      case _PreparedSuccess(:var bytes, :var httpStatus):
        final byteStream = http.ByteStream.fromBytes(bytes);
        return Future(() => http.StreamedResponse(
          byteStream, httpStatus, request: request));
    }
  }
}

/// An [ApiConnection] that accepts and replays canned responses, for testing.
class FakeApiConnection extends ApiConnection {
  /// Construct an [ApiConnection] that accepts and replays canned responses, for testing.
  ///
  /// If `zulipFeatureLevel` is omitted, it defaults to [eg.futureZulipFeatureLevel],
  /// which causes route bindings to behave as they would for the
  /// latest Zulip server versions.
  /// To set `zulipFeatureLevel` to null, pass null explicitly.
  FakeApiConnection({
    Uri? realmUrl,
    int? zulipFeatureLevel = eg.futureZulipFeatureLevel,
    String? email,
    String? apiKey,
  }) : this._(
         realmUrl: realmUrl ?? eg.realmUrl,
         zulipFeatureLevel: zulipFeatureLevel,
         email: email,
         apiKey: apiKey,
         client: FakeHttpClient(),
       );

  FakeApiConnection.fromAccount(Account account)
    : this(
        realmUrl: account.realmUrl,
        zulipFeatureLevel: account.zulipFeatureLevel,
        email: account.email,
        apiKey: account.apiKey);

  FakeApiConnection._({
    required super.realmUrl,
    required super.zulipFeatureLevel,
    super.email,
    super.apiKey,
    required this.client,
  }) : super(client: client);

  final FakeHttpClient client;

  /// Run the given callback on a fresh [FakeApiConnection], then close it,
  /// using try/finally.
  ///
  /// If `zulipFeatureLevel` is omitted, it defaults to [eg.futureZulipFeatureLevel],
  /// which causes route bindings to behave as they would for the
  /// latest Zulip server versions.
  /// To set `zulipFeatureLevel` to null, pass null explicitly.
  static Future<T> with_<T>(
    Future<T> Function(FakeApiConnection connection) fn, {
    Uri? realmUrl,
    int? zulipFeatureLevel = eg.futureZulipFeatureLevel,
    Account? account,
  }) async {
    assert((account == null)
      || (realmUrl == null && zulipFeatureLevel == eg.futureZulipFeatureLevel));
    final connection = (account != null)
      ? FakeApiConnection.fromAccount(account)
      : FakeApiConnection(realmUrl: realmUrl, zulipFeatureLevel: zulipFeatureLevel);
    try {
      return await fn(connection);
    } finally {
      connection.close();
    }
  }

  /// True just if [close] has never been called on this connection.
  // In principle this could live on [ApiConnection]... but [http.Client]
  // offers no way to tell if [http.Client.close] has been called,
  // so we follow that library's lead on this point of API design.
  bool get isOpen => _isOpen;
  bool _isOpen = true;

  @override
  void close() {
    _isOpen = false;
    super.close();
  }

  http.BaseRequest? get lastRequest => client.lastRequest;

  http.BaseRequest? takeLastRequest() => client.takeLastRequest();

  /// Prepare the response for the next request.
  ///
  /// If `exception` is null, the next request will produce an [http.Response]
  /// with the given `httpStatus`, defaulting to 200.  The body of the response
  /// will be `body` if non-null, or `jsonEncode(json)` if `json` is non-null,
  /// or else ''.  The `body` and `json` parameters must not both be non-null.
  ///
  /// If `exception` is non-null, then `httpStatus`, `body`, and `json` must
  /// all be null, and the next request will throw the given exception.
  void prepare({
    Object? exception,
    int? httpStatus,
    Map<String, dynamic>? json,
    String? body,
  }) {
    client.prepare(
      exception: exception, httpStatus: httpStatus, json: json, body: body);
  }
}
