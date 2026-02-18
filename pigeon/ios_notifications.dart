import 'package:pigeon/pigeon.dart';

// To rebuild this pigeon's output after editing this file,
// run `tools/check pigeon --fix`.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/ios_notifications.g.dart',
  swiftOut: 'ios/NotificationService/IosNotifications.g.swift',
))

class NotificationContent {
  const NotificationContent({
    required this.payload,
  });

  final Map<Object?, Object?> payload;
}

class MutatedNotificationContent {
  const MutatedNotificationContent({
    required this.title,
    required this.body,
  });

  final String title;
  final String? body;
}

@FlutterApi()
abstract class IosNotifFlutterApi {
  @async
  MutatedNotificationContent didReceivePushNotification(NotificationContent content);
}
