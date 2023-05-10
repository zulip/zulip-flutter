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

  _PreparedResponse? _nextResponse;

  // Please add more features to this mocking API as needed.  For example:
  //  * preparing more than one request, and logging more than one request

  /// Prepare the response for the next request.
  ///
  /// If `exception` is null, the next request will produce an [http.Response]
  /// with the given `httpStatus` and `body`, defaulting to 200 and ''
  /// respectively.
  ///
  /// If `exception` is non-null, then `httpStatus` and `body` must be null,
  /// and the next request will throw the given exception.
  void prepare({int? httpStatus, String? body, Object? exception}) {
    assert(exception == null || (httpStatus == null && body == null));
    assert(_nextResponse == null,
      'FakeApiConnection.prepare was called while already expecting a request');
    _nextResponse = exception != null
      ? _PreparedException(exception: exception)
      : _PreparedSuccess(
          httpStatus: httpStatus ?? 200, bytes: utf8.encode(body ?? ''));
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final response = _nextResponse!;
    _nextResponse = null;
    lastRequest = request;
    switch (response) {
      case _PreparedException(:var exception):
        return Future.error(exception);
      case _PreparedSuccess(:var bytes, :var httpStatus):
        final byteStream = http.ByteStream.fromBytes(bytes);
        return Future.value(http.StreamedResponse(
          byteStream, httpStatus, request: request));
    }
  }
}

/// An [ApiConnection] that accepts and replays canned responses, for testing.
class FakeApiConnection extends ApiConnection {
  FakeApiConnection({Uri? realmUrl})
    : this._(realmUrl: realmUrl ?? eg.realmUrl, client: FakeHttpClient());

  FakeApiConnection.fromAccount(Account account)
    : this._(
        realmUrl: account.realmUrl,
        email: account.email,
        apiKey: account.apiKey,
        client: FakeHttpClient());

  FakeApiConnection._({
    required super.realmUrl,
    super.email,
    super.apiKey,
    required this.client,
  }) : super(client: client);

  final FakeHttpClient client;

  /// Run the given callback on a fresh [FakeApiConnection], then close it,
  /// using try/finally.
  static Future<T> with_<T>(
    Future<T> Function(FakeApiConnection connection) fn, {
    Uri? realmUrl,
    Account? account,
  }) async {
    assert((account == null) || (realmUrl == null));
    final connection = (account != null)
      ? FakeApiConnection.fromAccount(account)
      : FakeApiConnection(realmUrl: realmUrl);
    try {
      return fn(connection);
    } finally {
      connection.close();
    }
  }

  http.BaseRequest? get lastRequest => client.lastRequest;

  /// Prepare the response for the next request.
  ///
  /// If `exception` is null, the next request will produce an [http.Response]
  /// with the given `httpStatus` and `body`, defaulting to 200 and ''
  /// respectively.
  ///
  /// If `exception` is non-null, then `httpStatus` and `body` must be null,
  /// and the next request will throw the given exception.
  void prepare({int? httpStatus, String? body, Object? exception}) {
    client.prepare(httpStatus: httpStatus, body: body, exception: exception);
  }
}
