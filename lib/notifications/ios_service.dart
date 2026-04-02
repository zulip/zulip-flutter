import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../api/core.dart';
import '../api/notifications.dart';
import '../host/ios_notifications.g.dart';
import '../model/binding.dart';
import '../model/localizations.dart';
import '../model/push_key.dart';
import 'display.dart';

@pragma('vm:entry-point')
void iosNotificationServiceMain() {
  if (defaultTargetPlatform != TargetPlatform.iOS) throw Error();

  _debugLog('dart: iosNotificationServiceMain');
  WidgetsFlutterBinding.ensureInitialized();
  LiveZulipBinding.ensureInitialized();

  IosNotificationService.init();
}

class IosNotificationService {
  const IosNotificationService._();

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
    ZulipBinding.instance.setupIosNotifFlutterApi(_IosNotifFlutterApiImpl());
  }
}

class _IosNotifFlutterApiImpl extends IosNotifFlutterApi {
  @override
  Future<ImprovedNotificationContent> didReceivePushNotification(NotificationContent notifContent) async {
    try {
      return await _didReceivePushNotification(notifContent);
    } catch (e, st) {
      _debugLog("$e\n$st");
      rethrow;
    }
  }

  Future<ImprovedNotificationContent> _didReceivePushNotification(NotificationContent notifContent) async {
    final parsed = EncryptedApnsPayload.fromJson(notifContent.payload.cast());

    final globalStore = await ZulipBinding.instance.getGlobalStore();
    final pushKey = globalStore.pushKeys.getPushKeyById(parsed.pushKeyId);
    if (pushKey == null) {
      // Not a key we have; nothing we can do with this notification-message.
      // This can happen if it's addressed to an account that's been logged out.
      // (On logout we try to unregister the device, but that can fail if the
      // device isn't able to reach the server at that time.)
      throw Exception(); // TODO(log)
    }
    final account = globalStore.getAccount(pushKey.accountId)!;

    final plaintext = await PushKeyStore.decryptNotification(
      pushKey.pushKey, parsed.encryptedData);
    final rawData = jsonUtf8Decoder.convert(plaintext) as Map<String, dynamic>;
    final data = NotifMessage.fromJson(rawData);
    switch (data) {
      case NotifMessageWithIdentity(): break;
      case UnexpectedNotifMessage(): throw Exception(); // TODO(log)
    }

    if (!(account.realmUrl.origin == data.realmUrl.origin
          && account.userId == data.userId)) {
      throw Exception("bad notif payload: realm/userId fails to match push key");
    }

    return _onFcmMessage(data, notifContent);
  }

  Future<ImprovedNotificationContent> _onFcmMessage(
    NotifMessageWithIdentity data,
    NotificationContent notifContent,
  ) async {
    return switch (data) {
      MessageNotifMessage() => _onMessageFcmMessage(data, notifContent),
      RemoveNotifMessage() => throw Exception(), // TODO(log)
    };
  }

  Future<ImprovedNotificationContent> _onMessageFcmMessage(
    MessageNotifMessage data,
    NotificationContent notifContent,
  ) async {
    final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
    final title =
      NotificationDisplayManager.titleForNotifMessage(data, zulipLocalizations);
    final notificationUrl =
      NotificationDisplayManager.notificationUrlForNotifMessage(data);

    return ImprovedNotificationContent(
      title: title,
      body: data.content,
      userInfo: {
        ...notifContent.payload,
        'notification_url': notificationUrl.toString(),
      });
  }
}

// `assert()` statements are not working in the extension even when running in
// debug mode. But fortunately `kDebugMode` does correctly return true in debug
// mode and false in release mode. So, use this helper instead of `debugLog`
// from `log.dart`.
// TODO(upstream) debug asserts not working
void _debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}
