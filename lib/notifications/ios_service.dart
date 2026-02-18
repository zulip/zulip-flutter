import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
void iosNotificationServiceMain() {
  _debugLog('dart: iosNotificationServiceMain');
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
