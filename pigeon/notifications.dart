import 'package:pigeon/pigeon.dart';

// To rebuild this pigeon's output after editing this file,
// run `tools/check pigeon --fix`.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/notifications.g.dart',
  swiftOut: 'ios/Runner/Notifications.g.swift',
))

class NotificationDataFromLaunch {
  const NotificationDataFromLaunch({required this.payload});

  /// The raw payload that is attached to the notification,
  /// holding the information required to carry out the navigation.
  ///
  /// See [NotificationHostApi.getNotificationDataFromLaunch].
  final Map<Object?, Object?> payload;
}

class NotificationTapEvent {
  const NotificationTapEvent({required this.payload});

  /// The raw payload that is attached to the notification,
  /// holding the information required to carry out the navigation.
  ///
  /// See [notificationTapEvents].
  final Map<Object?, Object?> payload;
}

@HostApi()
abstract class NotificationHostApi {
  /// Retrieves notification data if the app was launched by tapping on a notification.
  ///
  /// Returns `launchOptions.remoteNotification`,
  /// which is the raw APNs data dictionary
  /// if the app launch was opened by a notification tap,
  /// else null. See Apple doc:
  ///   https://developer.apple.com/documentation/uikit/uiapplication/launchoptionskey/remotenotification
  NotificationDataFromLaunch? getNotificationDataFromLaunch();
}

@EventChannelApi()
abstract class NotificationEventChannelApi {
  /// An event stream that emits a notification payload when the app
  /// encounters a notification tap, while the app is running.
  ///
  /// Emits an event when
  /// `userNotificationCenter(_:didReceive:withCompletionHandler:)` gets
  /// called, indicating that the user has tapped on a notification. The
  /// emitted payload will be the raw APNs data dictionary from the
  /// `UNNotificationResponse` passed to that method.
  NotificationTapEvent notificationTapEvents();
}
