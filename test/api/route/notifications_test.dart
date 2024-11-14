import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/route/notifications.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';

void main() {
  group('addFcmToken', () {
    Future<void> checkAddFcmToken(FakeApiConnection connection, {
      required String token,
    }) async {
      connection.prepare(json: {});
      await addFcmToken(connection, token: token);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/users/me/android_gcm_reg_id')
        ..bodyFields.deepEquals({
          'token': token,
        });
    }

    test('smoke', () {
      return FakeApiConnection.with_((connection) async {
        await checkAddFcmToken(connection, token: 'asdf');
      });
    });
  });

  group('removeFcmToken', () {
    Future<void> checkRemoveFcmToken(FakeApiConnection connection, {
      required String token,
    }) async {
      connection.prepare(json: {});
      await removeFcmToken(connection, token: token);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('DELETE')
        ..url.path.equals('/api/v1/users/me/android_gcm_reg_id')
        ..bodyFields.deepEquals({
          'token': token,
        });
    }

    test('smoke', () {
      return FakeApiConnection.with_((connection) async {
        await checkRemoveFcmToken(connection, token: 'asdf');
      });
    });
  });

  group('addApnsToken', () {
    Future<void> checkAddApnsToken(FakeApiConnection connection, {
      required String token,
      required String appid,
    }) async {
      connection.prepare(json: {});
      await addApnsToken(connection, token: token, appid: appid);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/users/me/apns_device_token')
        ..bodyFields.deepEquals({
          'token': token,
          'appid': appid,
        });
    }

    test('smoke', () {
      return FakeApiConnection.with_((connection) async {
        await checkAddApnsToken(connection, token: 'asdf', appid: 'qwer');
      });
    });
  });

  group('removeApnsToken', () {
    Future<void> checkRemoveApnsToken(FakeApiConnection connection, {
      required String token,
    }) async {
      connection.prepare(json: {});
      await removeApnsToken(connection, token: token);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('DELETE')
        ..url.path.equals('/api/v1/users/me/apns_device_token')
        ..bodyFields.deepEquals({
          'token': token,
        });
    }

    test('smoke', () {
      return FakeApiConnection.with_((connection) async {
        await checkRemoveApnsToken(connection, token: 'asdf');
      });
    });
  });
}
