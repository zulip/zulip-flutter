import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
void iosNotificationServiceMain() {
  if (defaultTargetPlatform != TargetPlatform.iOS) throw Error();

  _debugLog('dart: iosNotificationServiceMain');
}

// `assert()` statements are not working in the extension even when running in
// debug mode. But fortunately `kDebugMode` does correctly return true in debug
// mode and false in release mode. So, use this helper instead of `debugLog`
// from `log.dart`.
// TODO(upstream) debug asserts not working
void _debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}
