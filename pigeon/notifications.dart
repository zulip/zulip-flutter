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
  /// On iOS, this returns `launchOptions.remoteNotification`,
  /// which is the raw APNs data dictionary
  /// if the app launch was opened by a notification tap,
  /// else null. See Apple doc:
  ///   https://developer.apple.com/documentation/uikit/uiapplication/launchoptionskey/remotenotification
  ///
  /// On Android, this checks if the launch `intent` has the intent data uri
  /// starting with `zulip://notification` and has the extras bundle containing
  /// the notification open payload we set during creating the notification.
  /// Either returns the payload we set in the extras bundle, or null if the
  /// `intent` doesn't match the preconditions, meaning launch wasn't triggered
  /// by a notification.
  NotificationDataFromLaunch? getNotificationDataFromLaunch();
}

@EventChannelApi()
abstract class NotificationEventChannelApi {
  /// An event stream that emits a notification payload when the app
  /// encounters a notification tap, while the app is running.
  ///
  /// On iOS, this emits an event when
  /// `userNotificationCenter(_:didReceive:withCompletionHandler:)` gets
  /// called, indicating that the user has tapped on a notification. The
  /// emitted payload will be the raw APNs data dictionary from the
  /// `UNNotificationResponse` passed to that method.
  ///
  /// On Android, this emits an event when `onNewIntent` gets called, and
  /// the intent matches preconditions of having a data uri starting with
  /// `zulip://notification` and an extras bundle containing the notification
  /// open payload we set during creating the notification. The emitted payload
  /// will be the same payload we set in the extras bundle.
  NotificationTapEvent notificationTapEvents();
}
