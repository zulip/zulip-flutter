import 'package:checks/checks.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/exception.dart';

import 'core_test.dart';

void main() {
  // NetworkException.toString: see "API network errors" test in core_test.dart
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

  // MalformedServerResponseException: see "malformed API success responses" test in core_test.dart
  test('error details help debug schema mismatches', () async {
    final response = await tryRequest<Map<String, dynamic>>(
      json: {'properties': 'not an object'});

    try {
      final properties = response['properties'] as Map<String, dynamic>;
      properties['realm_uri'].toString();
      fail('Should have thrown');
    } catch (e, st) {
      final exception = MalformedServerResponseException(
        routeName: 'getServerSettings',
        httpStatus: 200,
        data: response,
        causeException: e,
        causeStackTrace: st,
      );

      final message = exception.toString();
      check(message)
        ..contains('getServerSettings')
        ..contains('type \'String\'')
        ..contains('Map<String, dynamic>');
      check(st.toString()).contains('exception_test.dart');
    }
  });
}
