import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/exception.dart';

void main() {
  test('ZulipApiException.toString', () {
    void checkValue(String expected,
        {required int httpStatus, required String code,
         required Map<String, dynamic> data}) {
      check(ZulipApiException(
        code: code, httpStatus: httpStatus, data: data,
        routeName: 'aRoute', message: 'oops',
      ).toString()).equals('ZulipApiException:$expected aRoute: oops');
    }

    checkValue(httpStatus: 400, code: 'BAD_REQUEST', data: {}, '');
    checkValue(httpStatus: 401, code: 'BAD_REQUEST', data: {}, ' 401');
    checkValue(httpStatus: 400, code: 'PROBLEM',     data: {}, ' PROBLEM');
    checkValue(httpStatus: 400, code: 'BAD_REQUEST', data: {'x': 'y'}, ' {"x":"y"}');

    check(ZulipApiException(
      httpStatus: 401, code: 'PROBLEM', data: {'x': 'y'},
      routeName: 'aRoute', message: 'oops').toString()
    ).equals('ZulipApiException: 401 PROBLEM {"x":"y"} aRoute: oops');
  });

  // NetworkException.toString: see "API network errors" test in core_test.dart

  test('MalformedServerResponseException shows JSON parsing location', () {
    const jsonResponse = '''
      {
        "result": "success",
        "queue_id": "1234567890",
        "last_event_id": -1,
        "properties": {
          "realm_uri": "https://example.zulipchat.com"
        }
      }
    ''';

    try {
      Map<String, String> wrongType =
        (jsonDecode(jsonResponse) as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value.toString()));

      wrongType['properties']! as Map<String, dynamic>;
      fail('Should have thrown');
    } catch (e, stackTrace) {
      final exception = MalformedServerResponseException(
        routeName: 'registerQueue',
        httpStatus: 200,
        data: jsonDecode(jsonResponse) as Map<String, dynamic>,
        causeException: e,
        causeStackTrace: stackTrace,
      );

      final string = exception.toString();
      check(string)
        ..contains('type \'String\'')
        ..contains('Map<String, dynamic>')
        ..contains(stackTrace.toString());
    }
  });
}
