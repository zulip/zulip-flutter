import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../api/notifications.dart';
import '../host/ios_notifications.g.dart';
import '../model/binding.dart';
import '../model/localizations.dart';
import 'display.dart';

import '../log.dart';
import 'open.dart';
import 'receive.dart';

@pragma('vm:entry-point')
void iosNotificationServiceMain() {
  if (defaultTargetPlatform != TargetPlatform.iOS) throw Error();

  assert(() {
    debugLogEnabled = true;
    return true;
  }());

  assert(debugLog('iosNotificationServiceMain'));
  WidgetsFlutterBinding.ensureInitialized();
  LiveZulipBinding.ensureInitialized();

  IosNotificationService.init();
}

abstract class IosNotificationService {
  /// Whether the currently executing context is
  /// iOS notification service app extension.
  static bool isExecutingInExtension = false;

  /// Reset the state of the [IosNotificationService], for testing.
  @visibleForTesting
  static void debugReset() {
    isExecutingInExtension = false;
  }

  @visibleForTesting
  static void init() {
    isExecutingInExtension = true;
    assert(debugLog('IosNotificationService.init'));
    ZulipBinding.instance.setupIosNotifFlutterApi(_IosNotifFlutterApiImpl());
  }
}

class _IosNotifFlutterApiImpl extends IosNotifFlutterApi {
  @override
  Future<ImprovedNotificationContent> didReceivePushNotification(NotificationContent notifContent) async {
    try {
      return await _didReceivePushNotification(notifContent);
    } catch (e, st) {
      assert(debugLog("$e\n$st"));
      rethrow;
    }
  }

  Future<ImprovedNotificationContent> _didReceivePushNotification(NotificationContent notifContent) async {
    // We always expect an E2EE notification here because for legacy plaintext
    // notifications the iOS NotificationService extension will never execute.
    // For iOS NotificationService extension to trigger the APNs payload needs
    // to include `"mutable-content": 1` entry, which the Zulip Server sets
    // only for the newer E2EE notifications.
    //
    // In case we encounter a malformed payload here (or legacy plaintext
    // payload for some reason), this method will throw here which in turn
    // will result the NotificationService extension implementation in Swift
    // to fallback and display the notification as per the incoming push
    // notification content (displaying the fields in APNs payload's
    // `"alert"` object).
    // For E2EE notifications, the server sets that to say "New notification".
    final parsed = EncryptedApnsPayload.fromJson(notifContent.payload.cast());

    final result = await NotificationService.decryptNotification(
      parsed.pushKeyId, parsed.encryptedData);
    if (result == null) throw Exception(); // TODO(log)

    final (data, _) = result;
    return _onNotifPayload(data);
  }

  Future<ImprovedNotificationContent> _onNotifPayload(NotifPayloadWithIdentity data) async {
    return switch (data) {
      NotifPayloadNewMessage() => _onNotifPayloadNewMessage(data),
      NotifPayloadRemove() => throw Exception(), // TODO(log)
    };
  }

  Future<ImprovedNotificationContent> _onNotifPayloadNewMessage(NotifPayloadNewMessage data) async {
    final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
    final title =
      NotificationDisplayManager.titleForNotifPayload(data, zulipLocalizations);
    final subtitle =
      NotificationDisplayManager.subtitleForNotifPayloadOnIos(data);
    final notificationUrl =
      NotificationDisplayManager.notificationUrlForNotifPayload(data);

    return ImprovedNotificationContent(
      title: title,
      subtitle: subtitle,
      body: data.content,
      userInfo: {
        // Pass the notification URL to this custom data map, so when a
        // notification is opened we can read this custom map to decide
        // which conversation to open.
        // See NotificationOpenService (in lib/notifications/ios_service.dart).
        NotificationOpenPayload.kIosNotificationUrlKey: notificationUrl.toString(),
      });
  }
}
