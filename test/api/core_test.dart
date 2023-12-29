import 'dart:convert';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:checks/context.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/api/exception.dart';

import '../stdlib_checks.dart';
import 'exception_checks.dart';
import 'fake_api.dart';
import '../example_data.dart' as eg;

void main() {
  test('ApiConnection.get', () async {
    Future<void> checkRequest(Map<String, dynamic>? params, String expectedRelativeUrl) {
      return FakeApiConnection.with_(account: eg.selfAccount, (connection) async {
        connection.prepare(json: {});
        await connection.get(kExampleRouteName, (json) => json, 'example/route', params);
        check(connection.lastRequest!).isA<http.Request>()
          ..method.equals('GET')
          ..url.asString.equals('${eg.realmUrl.origin}$expectedRelativeUrl')
          ..headers.deepEquals(authHeader(email: eg.selfAccount.email, apiKey: eg.selfAccount.apiKey))
          ..body.equals('');
      });
    }

    checkRequest(null,             '/api/v1/example/route');
    checkRequest({},               '/api/v1/example/route?');
    checkRequest({'x': 3},         '/api/v1/example/route?x=3');
    checkRequest({'x': 3, 'y': 4}, '/api/v1/example/route?x=3&y=4');
    checkRequest({'x': null},      '/api/v1/example/route?x=null');
    checkRequest({'x': true},      '/api/v1/example/route?x=true');
    checkRequest({'x': 'foo'},     '/api/v1/example/route?x=%22foo%22');
    checkRequest({'x': [1, 2]},    '/api/v1/example/route?x=%5B1%2C2%5D');
    checkRequest({'x': {'y': 1}},  '/api/v1/example/route?x=%7B%22y%22%3A1%7D');
    checkRequest({'x': RawParameter('foo')},
                                   '/api/v1/example/route?x=foo');
    checkRequest({'x': RawParameter('foo'), 'y': 'bar'},
                                   '/api/v1/example/route?x=foo&y=%22bar%22');
  });

  test('ApiConnection.post', () async {
    Future<void> checkRequest(Map<String, dynamic>? params, String expectedBody, {bool expectContentType = true}) {
      return FakeApiConnection.with_(account: eg.selfAccount, (connection) async {
        connection.prepare(json: {});
        await connection.post(kExampleRouteName, (json) => json, 'example/route', params);
        check(connection.lastRequest!).isA<http.Request>()
          ..method.equals('POST')
          ..url.asString.equals('${eg.realmUrl.origin}/api/v1/example/route')
          ..headers.deepEquals({
            ...authHeader(email: eg.selfAccount.email, apiKey: eg.selfAccount.apiKey),
            if (expectContentType)
              'content-type': 'application/x-www-form-urlencoded; charset=utf-8',
          })
          ..body.equals(expectedBody);
      });
    }

    checkRequest(null,                                   '', expectContentType: false);
    checkRequest({},                                     '');
    checkRequest({'x': 3},                               'x=3');
    checkRequest({'x': 3, 'y': 4},                       'x=3&y=4');
    checkRequest({'x': null},                            'x=null');
    checkRequest({'x': true},                            'x=true');
    checkRequest({'x': 'foo'},                           'x=%22foo%22');
    checkRequest({'x': [1, 2]},                          'x=%5B1%2C2%5D');
    checkRequest({'x': {'y': 1}},                        'x=%7B%22y%22%3A1%7D');
    checkRequest({'x': RawParameter('foo')},             'x=foo');
    checkRequest({'x': RawParameter('foo'), 'y': 'bar'}, 'x=foo&y=%22bar%22');
  });

  test('ApiConnection.postFileFromStream', () async {
    Future<void> checkRequest(List<List<int>> content, int length, String? filename) {
      return FakeApiConnection.with_(account: eg.selfAccount, (connection) async {
        connection.prepare(json: {});
        await connection.postFileFromStream(
          kExampleRouteName, (json) => json, 'example/route',
          Stream.fromIterable(content), length, filename: filename);
        check(connection.lastRequest!).isA<http.MultipartRequest>()
          ..method.equals('POST')
          ..url.asString.equals('${eg.realmUrl.origin}/api/v1/example/route')
          ..headers.deepEquals(authHeader(email: eg.selfAccount.email, apiKey: eg.selfAccount.apiKey))
          ..fields.deepEquals({})
          ..files.single.which(it()
            ..field.equals('file')
            ..length.equals(length)
            ..filename.equals(filename)
            ..has<Future<List<int>>>((f) => f.finalize().toBytes(), 'contents')
              .completes(it()..deepEquals(content.expand((l) => l)))
          );
      });
    }

    checkRequest([], 0, null);
    checkRequest(['asdf'.codeUnits], 4, null);
    checkRequest(['asd'.codeUnits, 'f'.codeUnits], 4, null);

    checkRequest(['asdf'.codeUnits], 4, 'info.txt');

    checkRequest(['asdf'.codeUnits], 1, null); // nothing on client side catches a wrong length
    checkRequest(['asdf'.codeUnits], 100, null);
  });

  test('ApiConnection.delete', () async {
    Future<void> checkRequest(Map<String, dynamic>? params, String expectedBody, {bool expectContentType = true}) {
      return FakeApiConnection.with_(account: eg.selfAccount, (connection) async {
        connection.prepare(json: {});
        await connection.delete(kExampleRouteName, (json) => json, 'example/route', params);
        check(connection.lastRequest!).isA<http.Request>()
          ..method.equals('DELETE')
          ..url.asString.equals('${eg.realmUrl.origin}/api/v1/example/route')
          ..headers.deepEquals({
            ...authHeader(email: eg.selfAccount.email, apiKey: eg.selfAccount.apiKey),
            if (expectContentType)
              'content-type': 'application/x-www-form-urlencoded; charset=utf-8',
          })
          ..body.equals(expectedBody);
      });
    }

    checkRequest(null,                                   '', expectContentType: false);
    checkRequest({},                                     '');
    checkRequest({'x': 3},                               'x=3');
    checkRequest({'x': 3, 'y': 4},                       'x=3&y=4');
    checkRequest({'x': null},                            'x=null');
    checkRequest({'x': true},                            'x=true');
    checkRequest({'x': 'foo'},                           'x=%22foo%22');
    checkRequest({'x': [1, 2]},                          'x=%5B1%2C2%5D');
    checkRequest({'x': {'y': 1}},                        'x=%7B%22y%22%3A1%7D');
    checkRequest({'x': RawParameter('foo')},             'x=foo');
    checkRequest({'x': RawParameter('foo'), 'y': 'bar'}, 'x=foo&y=%22bar%22');
  });

  test('API success result', () async {
    await FakeApiConnection.with_(account: eg.selfAccount, (connection) async {
      connection.prepare(json: {'result': 'success', 'x': 3});
      final result = await connection.get(
        kExampleRouteName, (json) => json['x'], 'example/route', {'y': 'z'});
      check(result).equals(3);
    });
  });

  test('API network errors', () async {
    Future<void> checkRequest<T extends Object>(
        T exception, Condition<NetworkException> condition) {
      return check(tryRequest(exception: exception))
        .throws<NetworkException>(it()
          ..routeName.equals(kExampleRouteName)
          ..cause.equals(exception)
          ..which(condition));
    }

    final zulipLocalizations = lookupZulipLocalizations(ZulipLocalizations.supportedLocales.first);
    checkRequest(http.ClientException('Oops'), it()..message.equals('Oops'));
    checkRequest(const TlsException('Oops'), it()..message.equals('Oops'));
    checkRequest((foo: 'bar'), it()
      ..message.equals(zulipLocalizations.errorNetworkRequestFailed));
  });

  test('API 4xx errors, well formed', () async {
    Future<void> checkRequest({
      int httpStatus = 400,
      String? code = 'SOME_ERROR',
      String? expectedCode,
      String message = 'A thing failed',
      Map<String, dynamic> data = const {},
    }) async {
      final json = {
        'result': 'error',
        if (code != null) 'code': code,
        'msg': message,
        ...data,
      };
      await check(tryRequest(httpStatus: httpStatus, json: json))
        .throws<ZulipApiException>(it()
          ..routeName.equals(kExampleRouteName)
          ..httpStatus.equals(httpStatus)
          ..code.equals(expectedCode ?? code!)
          ..data.deepEquals(data)
          ..message.equals(message));
    }

    await checkRequest();
    await checkRequest(code: null, expectedCode: 'BAD_REQUEST');
    await checkRequest(code: 'BAD_EVENT_QUEUE_ID');
    await checkRequest(httpStatus: 456);
    await checkRequest(httpStatus: 499);
    await checkRequest(data: {'foo': 'a', 'bar': 1, 'baz': {'x': null, 'y': [2, 3]}});
  });

  test('API 4xx errors, malformed', () async {
    Future<void> checkMalformed({
        int httpStatus = 400, Map<String, dynamic>? json, String? body}) async {
      assert((json == null) != (body == null));
      await check(tryRequest(httpStatus: httpStatus, json: json, body: body))
        .throws<MalformedServerResponseException>(it()
          ..routeName.equals(kExampleRouteName)
          ..httpStatus.equals(httpStatus)
          ..data.deepEquals(json));
    }

    await check(
      tryRequest(json: {  'result': 'error',    'code': 'ERR', 'msg': 'Oops'}, httpStatus: 400),
    ).throws<ZulipApiException>();

    checkMalformed(json: {'result': 'success',  'code': 'ERR', 'msg': 'Oops'});
    checkMalformed(json: {'result': 'nonsense', 'code': 'ERR', 'msg': 'Oops'});
    checkMalformed(json: {/* result */          'code': 'ERR', 'msg': 'Oops'});
    checkMalformed(json: {'result': 'error',    'code': 1,     'msg': 'Oops'});
    checkMalformed(json: {'result': 'error',    'code': 'ERR'  /* msg */    });
    checkMalformed(json: {'result': 'error',    'code': 'ERR', 'msg': 1     });
    checkMalformed(json: {});
    checkMalformed(body: '');
    checkMalformed(body: '<html><body><p>An error occurred</p></body></html>');
    checkMalformed(json: {'result': 'nonsense'}, httpStatus: 401);
    checkMalformed(json: {'result': 'nonsense'}, httpStatus: 499);
  });

  test('API 5xx errors', () async {
    Future<void> check5xx({
        required int httpStatus, Map<String, dynamic>? json, String? body}) {
      return check(tryRequest(httpStatus: httpStatus, json: json, body: body))
        .throws<Server5xxException>(it()
          ..routeName.equals(kExampleRouteName)
          ..httpStatus.equals(httpStatus)
          ..data.deepEquals(json));
    }

    await check5xx(httpStatus: 500, json: {'result': 'error'});
    await check5xx(httpStatus: 503, body: '');
    await check5xx(httpStatus: 503,
      json: {'result': 'error', 'code': 'EXTERNAL_SERVICE_UNAVAILABLE', 'msg': 'Dang'});
    await check5xx(httpStatus: 599, body: '');
  });

  test('API errors of unexpected HTTP status codes', () async {
    Future<void> checkMalformed({
        required int httpStatus, Map<String, dynamic>? json, String? body}) {
      return check(tryRequest(httpStatus: httpStatus, json: json, body: body))
        .throws<MalformedServerResponseException>(it()
          ..routeName.equals(kExampleRouteName)
          ..httpStatus.equals(httpStatus)
          ..data.deepEquals(json));
    }

    await check(tryRequest(httpStatus: 200, json: {'result': 'success'})).completes();
    await checkMalformed(httpStatus: 201, json: {'result': 'success'});
    await checkMalformed(httpStatus: 301, json: {'result': 'success'});
    await checkMalformed(httpStatus: 100, json: {'result': 'success'});
  });

  test('malformed API success responses', () async {
    Future<void> checkMalformed({
      Map<String, dynamic>? json,
      String? body,
      Object? Function(Map<String, dynamic>)? fromJson,
    }) {
      return check(tryRequest(json: json, body: body, fromJson: fromJson))
        .throws<MalformedServerResponseException>(it()
          ..routeName.equals(kExampleRouteName)
          ..httpStatus.equals(200)
          ..data.deepEquals(json));
    }

    await check(tryRequest<Map>(json: {})).completes(it()..deepEquals({}));

    await checkMalformed(body: jsonEncode([]));
    await checkMalformed(body: jsonEncode(null));
    await checkMalformed(body: jsonEncode(3));
    await checkMalformed(body: jsonEncode(true));
    await checkMalformed(body: 'not JSON');

    await check(tryRequest(json: {'x': 'y'}, fromJson: (json) => json['x'] as String))
      .completes(it()..equals('y'));
    await checkMalformed(  json: {},         fromJson: (json) => json['x'] as String);
    await checkMalformed(  json: {'x': 3},   fromJson: (json) => json['x'] as String);
  });

  test('malformed API success responses: exception preserves details', () async {
    int distinctivelyNamedFromJson(Map<String, dynamic> json) {
      throw DistinctiveError("something is wrong");
    }

    try {
      await tryRequest(json: {}, fromJson: distinctivelyNamedFromJson);
      assert(false);
    } catch (e, st) {
      check(e).isA<MalformedServerResponseException>()
        ..causeException.isA<DistinctiveError>()
        ..message.contains("something is wrong");
      check(st.toString()).contains("distinctivelyNamedFromJson");
    }
  });
}

class DistinctiveError extends Error {
  final String message;

  DistinctiveError(this.message);

  @override
  String toString() => message;
}

Future<T> tryRequest<T>({
  Object? exception,
  int? httpStatus,
  Map<String, dynamic>? json,
  String? body,
  T Function(Map<String, dynamic>)? fromJson,
}) {
  assert((exception != null && json == null && body == null)
      || (exception == null && json != null && body == null)
      || (exception == null && json == null && body != null));
  fromJson ??= (((Map<String, dynamic> x) => x) as T Function(Map<String, dynamic>));
  return FakeApiConnection.with_((connection) {
    connection.prepare(
      exception: exception, httpStatus: httpStatus, json: json, body: body);
    return connection.get(kExampleRouteName, fromJson!, 'example/route', {});
  });
}

const kExampleRouteName = 'exampleRoute';
