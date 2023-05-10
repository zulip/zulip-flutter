import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zulip/api/core.dart';
import 'package:zulip/model/store.dart';

import '../example_data.dart' as eg;

/// An [http.Client] that accepts and replays canned responses, for testing.
class FakeHttpClient extends http.BaseClient {

  http.BaseRequest? lastRequest;

  List<int>? _nextResponseBytes;

  // Please add more features to this mocking API as needed.  For example:
  //  * preparing an HTTP status other than 200
  //  * preparing an exception instead of an [http.StreamedResponse]
  //  * preparing more than one request, and logging more than one request

  void prepare({String? body}) {
    assert(_nextResponseBytes == null,
      'FakeApiConnection.prepare was called while already expecting a request');
    _nextResponseBytes = utf8.encode(body ?? '');
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final responseBytes = _nextResponseBytes!;
    _nextResponseBytes = null;
    lastRequest = request;
    final byteStream = http.ByteStream.fromBytes(responseBytes);
    return Future.value(http.StreamedResponse(byteStream, 200, request: request));
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

  void prepare({String? body}) {
    client.prepare(body: body);
  }
}
