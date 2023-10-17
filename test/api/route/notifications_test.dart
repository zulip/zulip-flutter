import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/route/notifications.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';

void main() {
  group('registerFcmToken', () {
    Future<void> checkRegisterFcmToken(FakeApiConnection connection, {
      required String token,
    }) async {
      connection.prepare(json: {});
      await registerFcmToken(connection, token: token);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/users/me/android_gcm_reg_id')
        ..bodyFields.deepEquals({
          'token': token,
        });
    }

    test('smoke', () {
      return FakeApiConnection.with_((connection) async {
        await checkRegisterFcmToken(connection, token: 'asdf');
      });
    });
  });

  group('registerApnsToken', () {
    Future<void> checkRegisterApnsToken(FakeApiConnection connection, {
      required String token,
      required String? appid,
    }) async {
      connection.prepare(json: {});
      await registerApnsToken(connection, token: token, appid: appid);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/users/me/apns_device_token')
        ..bodyFields.deepEquals({
          'token': token,
          if (appid != null) 'appid': appid,
        });
    }

    test('no appid', () {
      return FakeApiConnection.with_((connection) async {
        await checkRegisterApnsToken(connection, token: 'asdf', appid: null);
      });
    });

    test('with appid', () {
      return FakeApiConnection.with_((connection) async {
        await checkRegisterApnsToken(connection, token: 'asdf', appid: 'qwer');
      });
    });
  });
}
