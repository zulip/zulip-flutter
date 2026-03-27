import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'get/services/account_service.dart';
import 'get/services/global_service.dart';
import 'get/services/store_service.dart';
import 'licenses.dart';
import 'log.dart';
import 'model/binding.dart';
import 'notifications/local_notifications.dart';
import 'notifications/open.dart';
import 'notifications/background_service.dart';
import 'ui/app.dart';
import 'ui/utils/share.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  mainInit();
  runApp(const ZulipApp());
}

void mainInit() {
  assert(() {
    debugLogEnabled = true;
    return true;
  }());

  // Initialize local notifications (wrapped to handle plugin not ready)
  _initLocalNotificationsSafe();

  // Initialize GetX services first
  Get.put(GlobalService());
  Get.put(StoreService());
  AccountService.initServices();

  // Initialize background service after a delay to let plugins initialize
  _initBackgroundServiceDelayed();

  LicenseRegistry.addLicense(additionalLicenses);
  WidgetsFlutterBinding.ensureInitialized();
  LiveZulipBinding.ensureInitialized();
  ShareService.start();

  // Initialize notification tap listener after delay
  _initNotificationOpenServiceDelayed();
}

void _initLocalNotificationsSafe() {
  try {
    final notificationsService = LocalNotificationsService();
    notificationsService.init(onSelectedNotification: _handleNotificationTap);
    notificationsService.requestPermissions();
  } catch (e) {
    debugPrint(
      'LocalNotifications init failed (expected on some platforms): $e',
    );
  }
}

void _initBackgroundServiceDelayed() {
  try {
    Get.put<BackgroundService>(BackgroundService());
    // Defer background service start to after Flutter is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        BackgroundService.instance.start();
      } catch (e) {
        debugPrint(
          'BackgroundService start failed (expected on some platforms): $e',
        );
      }
    });
  } catch (e) {
    debugPrint(
      'BackgroundService init failed (expected on some platforms): $e',
    );
  }
}

void _initNotificationOpenServiceDelayed() {
  // Defer notification open service to after Flutter is ready
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      NotificationOpenService.instance.start();
    } catch (e) {
      debugPrint(
        'NotificationOpenService start failed (expected on some platforms): $e',
      );
    }
  });
}

void _handleNotificationTap(NotificationResponse response) {
  debugPrint('Notification tapped: ${response.payload}');
}
