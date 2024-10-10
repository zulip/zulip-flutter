
import '../core.dart';

// https://zulip.com/api/add-fcm-token
Future<void> registerFcmToken(ApiConnection connection, {
  required String token,
}) {
  return connection.post('registerFcmToken', (_) {}, 'users/me/android_gcm_reg_id', {
    'token': RawParameter(token),
  });
}

// https://zulip.com/api/remove-fcm-token
Future<void> unregisterFcmToken(ApiConnection connection, {
  required String token,
}) {
  return connection.delete('unregisterFcmToken', (_) {}, 'users/me/android_gcm_reg_id', {
    'token': RawParameter(token),
  });
}

// https://zulip.com/api/add-apns-token
Future<void> registerApnsToken(ApiConnection connection, {
  required String token,
  String? appid,
}) {
  return connection.post('registerApnsToken', (_) {}, 'users/me/apns_device_token', {
    'token': RawParameter(token),
    if (appid != null) 'appid': RawParameter(appid),
  });
}

// https://zulip.com/api/remove-apns-token
Future<void> unregisterApnsToken(ApiConnection connection, {
  required String token,
}) {
  return connection.delete('unregisterApnsToken', (_) {}, 'users/me/apns_device_token', {
    'token': RawParameter(token),
  });
}
