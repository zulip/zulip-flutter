import 'package:pigeon/pigeon.dart';

// To rebuild this pigeon's output after editing this file,
// run `tools/check pigeon --fix`.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/notifications.g.dart',
  swiftOut: 'ios/Runner/Notifications.g.swift',
))

/// The payload that is attached to each notification and holds
/// the information required to carry out the navigation.
///
/// On iOS, the notification payload will be the APNs data from
/// the server.
class NotificationPayloadForOpen {
  const NotificationPayloadForOpen({required this.payload});
  final Map<Object?, Object?> payload;
}

@HostApi()
abstract class NotificationHostApi {
  /// Retrieves notification data if the app was launched by tapping on a notification.
  NotificationPayloadForOpen? getNotificationDataFromLaunch();
}
