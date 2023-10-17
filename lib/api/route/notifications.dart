
import '../core.dart';

// This endpoint is undocumented.  Compare zulip-mobile:
//   https://github.com/zulip/zulip-mobile/blob/86d94fa89/src/api/notifications/savePushToken.js
// and see the server implementation:
//   https://github.com/zulip/zulip/blob/34ceafadd/zproject/urls.py#L383
//   https://github.com/zulip/zulip/blob/34ceafadd/zerver/views/push_notifications.py#L47
Future<void> registerFcmToken(ApiConnection connection, {
  required String token,
}) {
  return connection.post('registerFcmToken', (_) {}, 'users/me/android_gcm_reg_id', {
    'token': RawParameter(token),
  });
}

// This endpoint is undocumented.  Compare zulip-mobile:
//   https://github.com/zulip/zulip-mobile/blob/86d94fa89/src/api/notifications/savePushToken.js
// and see the server implementation:
//   https://github.com/zulip/zulip/blob/34ceafadd/zproject/urls.py#L378-L381
//   https://github.com/zulip/zulip/blob/34ceafadd/zerver/views/push_notifications.py#L34
Future<void> registerApnsToken(ApiConnection connection, {
  required String token,
  String? appid,
}) {
  return connection.post('registerApnsToken', (_) {}, 'users/me/apns_device_token', {
    'token': RawParameter(token),
    if (appid != null) 'appid': RawParameter(appid),
  });
}
