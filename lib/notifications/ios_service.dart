import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../api/notifications.dart';
import '../host/ios_notifications.g.dart';
import '../model/binding.dart';
import '../model/localizations.dart';
import 'display.dart';

import '../log.dart';
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
    final parsed = EncryptedApnsPayload.fromJson(notifContent.payload.cast());

    final result = await NotificationService.decryptNotification(
      parsed.pushKeyId, parsed.encryptedData);
    if (result == null) throw Exception(); // TODO(log)

    final (data, _) = result;
    return _onNotifPayload(data, notifContent);
  }

  Future<ImprovedNotificationContent> _onNotifPayload(
    NotifPayloadWithIdentity data,
    NotificationContent notifContent,
  ) async {
    return switch (data) {
      NotifPayloadNewMessage() => _onNotifPayloadNewMessage(data, notifContent),
      NotifPayloadRemove() => throw Exception(), // TODO(log)
    };
  }

  Future<ImprovedNotificationContent> _onNotifPayloadNewMessage(
    NotifPayloadNewMessage data,
    NotificationContent notifContent,
  ) async {
    final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
    final title =
      NotificationDisplayManager.titleForNotifPayload(data, zulipLocalizations);
    final notificationUrl =
      NotificationDisplayManager.notificationUrlForNotifPayload(data);

    return ImprovedNotificationContent(
      title: title,
      body: data.content,
      userInfo: {
        'notification_url': notificationUrl.toString(),
      });
  }
}
