import 'package:pigeon/pigeon.dart';

// To rebuild this pigeon's output after editing this file,
// run `tools/check pigeon --fix`.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/notifications.g.dart',
  swiftOut: 'ios/Runner/Notifications.g.swift',
))

/// The payload that is attached to each notification and holds
/// the information required to carry out the navigation.
class NotificationPayloadForOpen {
  const NotificationPayloadForOpen({required this.payload});
  final Map<Object?, Object?> payload;
}

@HostApi()
abstract class NotificationHostApi {
  /// Retrieves notification data if the app was launched by tapping on a notification.
  ///
  /// On iOS, this checks and returns value for the `remoteNotification` key
  /// in the `launchOptions` map. The value could be either the raw APNs data
  /// dictionary, if the launch of the app was triggered by a notification tap,
  /// otherwise it will be null.
  ///
  /// See: https://developer.apple.com/documentation/uikit/uiapplication/launchoptionskey/remotenotification
  NotificationPayloadForOpen? getNotificationDataFromLaunch();
}
