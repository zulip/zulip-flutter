import 'package:pigeon/pigeon.dart';

// To rebuild this pigeon's output after editing this file,
// run `tools/check pigeon --fix`.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/notifications.g.dart',
  swiftOut: 'ios/Runner/Notifications.g.swift',
  kotlinOut: 'android/app/src/main/kotlin/com/zulip/flutter/Notifications.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.zulip.flutter',
    includeErrorClass: false),
))

class NotificationPayloadForOpen {
  const NotificationPayloadForOpen({required this.payload});
  final Map<Object?, Object?> payload;
}

@HostApi()
abstract class NotificationHostApi {
  NotificationPayloadForOpen? getNotificationDataFromLaunch();
}

@EventChannelApi()
abstract class NotificationHostEvents {
  NotificationPayloadForOpen notificationTapEvents();
}
