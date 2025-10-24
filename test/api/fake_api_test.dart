import 'dart:async';

import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/exception.dart';

import '../fake_async.dart';
import '../stdlib_checks.dart';
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

  test('prepare HTTP exception -> get NetworkException', () async {
    final connection = FakeApiConnection();
    final exception = Exception('oops');
    connection.prepare(httpException: exception);
    await check(connection.get('aRoute', (json) => json, '/', null))
      .throws((it) => it.isA<NetworkException>()
        ..cause.identicalTo(exception));
  });

  test('error message on prepare API exception as "HTTP exception"', () async {
    final connection = FakeApiConnection();
    final exception = ZulipApiException(routeName: 'someRoute',
      httpStatus: 456, code: 'SOME_ERROR',
      data: {'foo': ['bar']}, message: 'Something failed');
    check(() => connection.prepare(httpException: exception))
      .throws<Error>().asString.contains('apiException');
  });

  test('prepare API exception', () async {
    final connection = FakeApiConnection();
    final exception = ZulipApiException(routeName: 'someRoute',
      httpStatus: 456, code: 'SOME_ERROR',
      data: {'foo': ['bar']}, message: 'Something failed');
    connection.prepare(apiException: exception);
    await check(connection.get('aRoute', (json) => json, '/', null))
      .throws((it) => it.isA<ZulipApiException>()
        ..routeName.equals('aRoute') // actual route, not the prepared one
        ..routeName.not((it) => it.equals(exception.routeName))
        ..httpStatus.equals(exception.httpStatus)
        ..code.equals(exception.code)
        ..data.deepEquals(exception.data)
        ..message.equals(exception.message));
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
      httpException: Exception("oops"));

    Object? error;
    unawaited(connection.get('aRoute', (json) => null, '/', null)
      .catchError((Object e) { error = e; }));

    async.elapse(const Duration(seconds: 1));
    check(error).isNull();

    async.elapse(const Duration(seconds: 1));
    check(error).isA<NetworkException>().asString.contains("oops");
  }));
}
