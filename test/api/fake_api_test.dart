import 'dart:async';

import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/exception.dart';

import '../fake_async.dart';
import 'exception_checks.dart';
import 'fake_api.dart';

void main() {
  test('baseline happy case', () async {
    final connection = FakeApiConnection();
    connection.prepare(json: {'a': 3});
    await check(connection.get('aRoute', (json) => json, '/', null))
      .completes((it) => it.deepEquals({'a': 3}));
  });

  test('error message on send without prepare', () async {
    final connection = FakeApiConnection();
    // no connection.prepare
    await check(connection.get('aRoute', (json) => json, '/', null))
      .throws((it) => it.isA<NetworkException>()
        ..asString.contains('no response was prepared')
        ..asString.contains('FakeApiConnection.prepare'));
  });

  test('delay success', () => awaitFakeAsync((async) async {
    final connection = FakeApiConnection();
    connection.prepare(delay: const Duration(seconds: 2),
      json: {'a': 3});

    Map<String, dynamic>? result;
    unawaited(connection.get('aRoute', (json) => json, '/', null)
      .then((r) { result = r; }));

    async.elapse(const Duration(seconds: 1));
    check(result).isNull();

    async.elapse(const Duration(seconds: 1));
    check(result).isNotNull().deepEquals({'a': 3});
  }));

  test('delay exception', () => awaitFakeAsync((async) async {
    final connection = FakeApiConnection();
    connection.prepare(delay: const Duration(seconds: 2),
      exception: Exception("oops"));

    Object? error;
    unawaited(connection.get('aRoute', (json) => null, '/', null)
      .catchError((Object e) { error = e; }));

    async.elapse(const Duration(seconds: 1));
    check(error).isNull();

    async.elapse(const Duration(seconds: 1));
    check(error).isA<NetworkException>().asString.contains("oops");
  }));
}
