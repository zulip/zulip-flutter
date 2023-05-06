import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zulip/api/core.dart';
import 'package:zulip/model/store.dart';

/// An [ApiConnection] that accepts and replays canned responses, for testing.
class FakeApiConnection extends ApiConnection {
  FakeApiConnection({required Uri realmUrl, required String email})
      : super(auth: Auth(
                realmUrl: realmUrl, email: email, apiKey: _fakeApiKey));

  FakeApiConnection.fromAccount(Account account)
      : this(realmUrl: account.realmUrl, email: account.email);

  List<int>? _nextResponseBytes;

  // TODO: This mocking API will need to get richer to support all the tests we need.

  void prepare(String response) {
    assert(_nextResponseBytes == null,
        'FakeApiConnection.prepare was called while already expecting a request');
    _nextResponseBytes = utf8.encode(response);
  }

  @override
  void close() {
    // TODO: record connection closed; assert open in methods
  }

  @override
  Future<http.Response> send(http.BaseRequest request) async {
    final responseBytes = _nextResponseBytes!;
    _nextResponseBytes = null;
    return http.Response.bytes(responseBytes, 200, request: request);
  }
}

const String _fakeApiKey = 'fake-api-key';
