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

/// An event that is only emitted on iOS platform when a notification is
/// tapped on.
///
/// See [notificationTapEvents].
class IosNotificationTapEvent extends NotificationTapEvent {
  const IosNotificationTapEvent({required this.payload});

  /// The raw payload that is attached to the notification,
  /// holding the information required to carry out the navigation.
  ///
  /// See [notificationTapEvents].
  final Map<Object?, Object?> payload;
}

/// An event that is only emitted on Android platform when a notification is
/// tapped on.
///
/// See [notificationTapEvents].
class AndroidNotificationTapEvent extends NotificationTapEvent {
  const AndroidNotificationTapEvent({required this.dataUrl});

  /// The intent data URL that was provided when the notification was created
  /// during `NotificationDisplayManager._onMessageFcmMessage`.
  ///
  /// Also see [notificationTapEvents].
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

@EventChannelApi()
abstract class NotificationEventChannelApi {
  /// An event stream that emits a notification payload when the app
  /// encounters a notification tap, on iOS and Android while the app is
  /// running, or only on Android when apps was launched by tapping a
  /// notification.
  ///
  /// On iOS, emits an event when
  /// `userNotificationCenter(_:didReceive:withCompletionHandler:)` gets
  /// called, indicating that the user has tapped on a notification. The
  /// emitted payload will be the raw APNs data dictionary from the
  /// `UNNotificationResponse` passed to that method.
  ///
  /// On Android, emits an event when the initial launch intent
  /// (`MainActivity.intent`) or the intent received via
  /// `MainActivity.onNewIntent` is an ACTION_VIEW intent and the associated
  /// data URL has the "zulip" scheme, and "notification" authority. The
  /// emitted event will carry the intent data URL.
  NotificationTapEvent notificationTapEvents();
}
