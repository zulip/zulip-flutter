import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/core.dart';

import '../stdlib_checks.dart';
import 'fake_api.dart';
import '../example_data.dart' as eg;

void main() {
  test('ApiConnection.get', () async {
    Future<void> checkRequest(Map<String, dynamic>? params, String expectedRelativeUrl) {
      return FakeApiConnection.with_(account: eg.selfAccount, (connection) async {
        connection.prepare(body: jsonEncode({}));
        await connection.get(kExampleRouteName, 'example/route', params);
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
        connection.prepare(body: jsonEncode({}));
        await connection.post(kExampleRouteName, 'example/route', params);
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
        connection.prepare(body: jsonEncode({}));
        await connection.postFileFromStream(
          kExampleRouteName, 'example/route',
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

  test('API success result', () async {
    await FakeApiConnection.with_(account: eg.selfAccount, (connection) async {
      connection.prepare(body: jsonEncode({'result': 'success', 'x': 3}));
      final result = await connection.get(
        kExampleRouteName, 'example/route', {'y': 'z'});
      check(result).deepEquals({'result': 'success', 'x': 3});
    });
  });
}

const kExampleRouteName = 'exampleRoute';
