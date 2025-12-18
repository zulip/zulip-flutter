import 'package:pigeon/pigeon.dart';

// To rebuild this pigeon's output after editing this file,
// run `tools/check pigeon --fix`.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/notifications.g.dart',
  swiftOut: 'ios/Runner/Notifications.g.swift',
  kotlinOut: 'android/app/src/main/kotlin/com/zulip/flutter/notifications/Notifications.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.zulip.flutter.notifications'),
))

class NotificationDataFromLaunch {
  const NotificationDataFromLaunch({required this.payload});

  /// The raw payload that is attached to the notification,
  /// holding the information required to carry out the navigation.
  ///
  /// See [NotificationHostApi.getNotificationDataFromLaunch].
  final Map<Object?, Object?> payload;
}

sealed class NotificationTapEvent {
  const NotificationTapEvent();
}

/// On iOS, an event emitted when a notification is tapped.
///
/// See [notificationTapEvents].
class IosNotificationTapEvent extends NotificationTapEvent {
  const IosNotificationTapEvent({required this.payload});

  /// The iOS APNs payload of the notification.
  ///
  /// See [notificationTapEvents].
  final Map<Object?, Object?> payload;
}

/// On Android, an event emitted when a notification is tapped.
///
/// See [notificationTapEvents].
class AndroidNotificationTapEvent extends NotificationTapEvent {
  const AndroidNotificationTapEvent({required this.dataUrl});

  /// The intent data URL of the notification.
  ///
  /// This is an internal URL that is generated using
  /// `NotificationOpenPayload.buildAndroidNotificationUrl` while creating the
  /// notification during `NotificationDisplayManager._onMessageFcmMessage`.
  ///
  /// See [notificationTapEvents].
  final String dataUrl;
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

/// An event stream that emits a notification payload
/// when a notification is tapped.
///
/// On iOS, emits [IosNotificationTapEvent] when
/// `userNotificationCenter(_:didReceive:withCompletionHandler:)` gets
/// called, indicating that the user has tapped on a notification. The
/// emitted event carries a payload which will be the raw APNs data
/// dictionary from the `UNNotificationResponse` passed to that method.
///
/// On Android, emits [AndroidNotificationTapEvent] when the initial launch
/// intent (`MainActivity.intent`) or the intent received via
/// `MainActivity.onNewIntent` is an ACTION_VIEW intent and the associated
/// data URL has the "zulip" scheme, and "notification" authority. The
/// emitted event will carry the intent data URL.
@EventChannelApi()
abstract class NotificationEventChannelApi {
  NotificationTapEvent notificationTapEvents();
}
