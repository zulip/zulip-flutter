import 'package:pigeon/pigeon.dart';

// To rebuild this pigeon's output after editing this file,
// run `tools/check pigeon --fix`.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/ios_notifications.g.dart',
  swiftOut: 'ios/NotificationService/IosNotifications.g.swift',
))

/// The notification content of the incoming push notification.
class NotificationContent {
  const NotificationContent({
    required this.payload,
  });

  /// The raw APNs payload of the push notification.
  final Map<Object?, Object?> payload;
}

/// The improved notification content that will be displayed to the user.
class ImprovedNotificationContent {
  const ImprovedNotificationContent({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.userInfo,
  });

  /// The new title to use for the notification.
  final String title;

  /// The new subtitle to use for the notification.
  final String subtitle;

  /// The new body to use for the notification.
  final String body;

  /// The internal data to attach with the new notification.
  ///
  /// This replaces the raw APNs payload that was initially set from
  /// the remote push notification.
  final Map<String, Object?> userInfo;
}

/// Exposes an API from Dart code which can be called from Swift code.
///
/// An implementation of this interface should be passed to
/// [ZulipBinding.instance.setupIosNotifFlutterApi] (which wraps
/// [IosNotifFlutterApi.setUp]) to initialize this Pigeon API.
@FlutterApi()
abstract class IosNotifFlutterApi {
  /// Corresponds to `NotificationService.didReceive` in NotificationService.swift.
  ///
  /// Invoked when NotificationService is triggered by a remote push
  /// notification, with the notification content which will contain the APNs
  /// payload.
  ///
  /// The returned result should be the improved notification content that
  /// will be displayed to the user.
  ///
  /// See docs: https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension/didreceive(_:withcontenthandler:)
  @async
  ImprovedNotificationContent didReceivePushNotification(NotificationContent content);
}
