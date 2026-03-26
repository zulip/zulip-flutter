import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'get/services/account_service.dart';
import 'get/services/global_service.dart';
import 'get/services/store_service.dart';
import 'licenses.dart';
import 'log.dart';
import 'model/binding.dart';
import 'notifications/local_notifications.dart';
import 'ui/app.dart';
import 'ui/utils/share.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  mainInit();
  runApp(const ZulipApp());
}

/// Everything [main] does short of [runApp].
///
/// This is useful for setup in Patrol-based integration tests.
void mainInit() {
  assert(() {
    debugLogEnabled = true;
    return true;
  }());
  LocalNotificationsService().init();
  LicenseRegistry.addLicense(additionalLicenses);
  WidgetsFlutterBinding.ensureInitialized();
  LiveZulipBinding.ensureInitialized();
  ShareService.start();

  // Initialize GetX services
  Get.put(GlobalService());
  Get.put(StoreService());
  AccountService.initServices();
}
