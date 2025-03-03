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

@EventChannelApi()
abstract class NotificationHostEvents {
  /// An event stream that emits a notification payload when the app
  /// encounters a notification tap, while the app is running.
  ///
  /// On iOS, this emits an event when
  /// `userNotificationCenter(_:didReceive:withCompletionHandler:)` gets
  /// called, indicating that the user has tapped on a notification. The
  /// emitted payload will be the raw APNs data from the
  /// `UNNotificationResponse` passed to the method.
  NotificationPayloadForOpen notificationTapEvents();
}
