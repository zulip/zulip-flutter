import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/exception.dart';
import 'fake_api.dart';
import 'package:zulip/api/core.dart';

void main() {
  test('Report message API success', () async {
    await FakeApiConnection.with_((api) async {
      api.prepare(json: {'result': 'success'});

      final response = await api.post<Map<String, dynamic>>(
        '/messages/report',
        (json) => json,
        'messages/report',
        {'message_id': 123},
      );

      expect(response['result'], 'success');
    });
  });

  test('Report message API failure', () async {
    await FakeApiConnection.with_((api) async {
      api.prepare(
        apiException: ZulipApiException(
          routeName: '/messages/report',
          httpStatus: 400,
          code: 'BAD_REQUEST',
          message: 'Invalid ID',
          data: {},
        ),
      );

      try {
        await api.post<Map<String, dynamic>>(
          '/messages/report',
          (json) => json,
          'messages/report',
          {'message_id': 999},
        );
      } catch (e) {
        expect(e, isA<ZulipApiException>());
      }
    });
  });
}
