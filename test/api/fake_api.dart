import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zulip/api/core.dart';
import 'package:zulip/model/store.dart';

/// An [http.Client] that accepts and replays canned responses, for testing.
class FakeHttpClient extends http.BaseClient {

  List<int>? _nextResponseBytes;

  // TODO: This mocking API will need to get richer to support all the tests we need.

  void prepare(String response) {
    assert(_nextResponseBytes == null,
        'FakeApiConnection.prepare was called while already expecting a request');
    _nextResponseBytes = utf8.encode(response);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final responseBytes = _nextResponseBytes!;
    _nextResponseBytes = null;
    final byteStream = http.ByteStream.fromBytes(responseBytes);
    return Future.value(http.StreamedResponse(byteStream, 200, request: request));
  }
}

/// An [ApiConnection] that accepts and replays canned responses, for testing.
class FakeApiConnection extends ApiConnection {
  FakeApiConnection({required Uri realmUrl, required String email})
    : this._(realmUrl: realmUrl, email: email, client: FakeHttpClient());

  FakeApiConnection.fromAccount(Account account)
    : this(realmUrl: account.realmUrl, email: account.email);

  FakeApiConnection._({required Uri realmUrl, required String email, required this.client})
    : super(client: client, auth: Auth(
        realmUrl: realmUrl, email: email, apiKey: _fakeApiKey));

  final FakeHttpClient client;

  void prepare(String response) {
    client.prepare(response);
  }

  @override
  void addAuth(http.BaseRequest request) {
    // do nothing
  }
}

const String _fakeApiKey = 'fake-api-key';
