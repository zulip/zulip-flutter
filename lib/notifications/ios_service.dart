import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../host/ios_notifications.g.dart';
import '../model/binding.dart';

@pragma('vm:entry-point')
void iosNotificationServiceMain() {
  WidgetsFlutterBinding.ensureInitialized();
  LiveZulipBinding.ensureInitialized();

  IosNotificationService.init();
}

@visibleForTesting
class IosNotificationService {
  static void init() {
    _debugLog('dart: IosNotificationService.init');
    final iosNotifFlutterApiImpl = _IosNotifFlutterApiImpl();
    ZulipBinding.instance.setupIosNotifFlutterApi(iosNotifFlutterApiImpl);
  }
}

class _IosNotifFlutterApiImpl extends IosNotifFlutterApi {
  @override
  Future<MutatedNotificationContent> didReceivePushNotification(NotificationContent content) async {
    _debugLog("dart: _IosNotifFlutterApiImpl.didReceivePushNotification");
    _debugLog("dart: content.payload=${jsonEncode(content.payload)}");

    final parsed = _ApnsPayload.parseApnsPayload(content.payload);

    return MutatedNotificationContent(
      title: parsed.title, // '${parsed.title} (from dart)',
      body: parsed.body);
  }
}

class _ApnsPayload {
  const _ApnsPayload._({
    required this.title,
    required this.body,
  });

  final String title;
  final String? body;

  factory _ApnsPayload.parseApnsPayload(Map<Object?, Object?> payload) {
    if (payload case {
      "aps": {
        "alert": {
          "title": final String title,
        } && final alertData,
      },
    }) {
      final body = alertData['body'] as String?;
      return _ApnsPayload._(title: title, body: body);
    } else {
      // TODO(dart): simplify after https://github.com/dart-lang/language/issues/2537
      throw const FormatException();
    }
  }
}

// `assert()` statements are not working in the extension even when running in
// the debug mode. But fortunately `kDebugMode` does correctly return true in
// the debug mode and false in the release mode. So, use this helper instead of
// `debugLog` from `log.dart`.
void _debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}
