import 'package:pigeon/pigeon.dart';

// To rebuild this pigeon's output after editing this file,
// run `tools/check pigeon --fix`.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/notifications.g.dart',
  swiftOut: 'ios/Runner/Notifications.g.swift',
  kotlinOut: 'android/app/src/main/kotlin/com/zulip/flutter/Notifications.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.zulip.flutter',
    // One error class is already generated in AndroidNotifications.g.kt ,
    // so avoid generating another one, preventing duplicate class build errors.
    includeErrorClass: false),
))

/// The payload that is attached to each notification and holds
/// the information required to carry out the navigation.
///
/// On iOS, the notification payload will be the APNs data from
/// the server.
///
/// On Android, the payload will be the Intent extras bundle provided
/// during the creation of the notification.
class NotificationPayloadForOpen {
  const NotificationPayloadForOpen({required this.payload});
  final Map<Object?, Object?> payload;
}

@HostApi()
abstract class NotificationHostApi {
  /// Retrieves notification data if the app was launched by tapping on a notification.
  NotificationPayloadForOpen? getNotificationDataFromLaunch();
}

@EventChannelApi()
abstract class NotificationHostEvents {
  /// An event stream that emits a notification payload when
  /// app encounters a notification tap, while the app is runnning.
  NotificationPayloadForOpen notificationTapEvents();
}
