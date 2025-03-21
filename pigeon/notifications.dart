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
  ///
  /// On Android, this checks if the launch `intent` has the intent data uri
  /// starting with `zulip://notification` and has the extras bundle containing
  /// the notification open payload we set during creating the notification.
  /// Either returns the payload we set in the extras bundle, or null if the
  /// `intent` doesn't match the preconditions, meaning launch wasn't triggered
  /// by a notification.
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
  ///
  /// On Android, this emits an event when `onNewIntent` gets called, and
  /// the intent matches preconditions of having a data uri starting with
  /// `zulip://notification` and an extras bundle containing the notification
  /// open payload we set during creating the notification. The emitted payload
  /// will be the same payload we set in the extras bundle.
  NotificationPayloadForOpen notificationTapEvents();
}
