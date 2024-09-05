import '../core.dart';

/// https://zulip.com/api/add-fcm-token
Future<void> addFcmToken(ApiConnection connection, {
  required String token,
}) {
  return connection.post('addFcmToken', (_) {}, 'users/me/android_gcm_reg_id', {
    'token': RawParameter(token),
  });
}

/// https://zulip.com/api/remove-fcm-token
Future<void> removeFcmToken(ApiConnection connection, {
  required String token,
}) {
  return connection.delete('removeFcmToken', (_) {}, 'users/me/android_gcm_reg_id', {
    'token': RawParameter(token),
  });
}

/// https://zulip.com/api/add-apns-token
Future<void> addApnsToken(ApiConnection connection, {
  required String token,
  required String appid,
}) {
  return connection.post('addApnsToken', (_) {}, 'users/me/apns_device_token', {
    'token': RawParameter(token),
    'appid': RawParameter(appid),
  });
}

/// https://zulip.com/api/remove-apns-token
Future<void> removeApnsToken(ApiConnection connection, {
  required String token,
}) {
  return connection.delete('removeApnsToken', (_) {}, 'users/me/apns_device_token', {
    'token': RawParameter(token),
  });
}
