import 'package:flutter/foundation.dart';

import '../log.dart';

@pragma('vm:entry-point')
void iosNotificationServiceMain() {
  if (defaultTargetPlatform != TargetPlatform.iOS) throw Error();

  assert(() {
    debugLogEnabled = true;
    return true;
  }());

  assert(debugLog('iosNotificationServiceMain'));
}
