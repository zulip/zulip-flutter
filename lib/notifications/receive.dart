import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../api/core.dart';
import '../api/notifications.dart';
import '../api/route/notifications.dart';
import '../firebase_options.dart';
import '../log.dart';
import '../model/binding.dart';
import 'display.dart';
import 'open.dart';

@pragma('vm:entry-point')
class NotificationService {
  static NotificationService get instance => (_instance ??= NotificationService._());
  static NotificationService? _instance;

  NotificationService._();

  /// Reset the state of the [NotificationService], for testing.
  ///
  /// TODO refactor this better, perhaps unify with ZulipBinding
  @visibleForTesting
  static void debugReset() {
    instance.token.dispose();
    _instance = null;
    assert(debugBackgroundIsolateIsLive = true);
    NotificationOpenService.debugReset();
  }

  /// Whether a background isolate should initialize [LiveZulipBinding].
  ///
  /// Ordinarily a [ZulipBinding.firebaseMessagingOnBackgroundMessage] callback
  /// will be invoked in a background isolate where it must set up its
  /// [ZulipBinding], just as the `main` function does for most of the app.
  /// Consequently, by default we have that callback initialize
  /// [LiveZulipBinding], just like `main` does.
  ///
  /// In a test that behavior is undesirable.  Tests that will cause
  /// [ZulipBinding.firebaseMessagingOnBackgroundMessage] callbacks
  /// to get invoked should therefore set this to false.
  static bool debugBackgroundIsolateIsLive = true;

  /// The FCM registration token for this install of the app.
  ///
  /// This is unique to the (app, device) pair, but not permanent.
  /// Most often it's the same from one run of the app to the next,
  /// but it can change either during a run or between them.
  ///
  /// See also:
  ///  * Upstream docs on FCM registration tokens in general:
  ///    https://firebase.google.com/docs/cloud-messaging/manage-tokens
  ValueNotifier<String?> token = ValueNotifier(null);

  Future<void> start() async {
    await NotificationOpenService.instance.start();

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await ZulipBinding.instance.firebaseInitializeApp(
          options: kFirebaseOptionsAndroid);

        await NotificationDisplayManager.init();
        ZulipBinding.instance.firebaseMessagingOnMessage
          .listen(_onForegroundMessage);
        ZulipBinding.instance.firebaseMessagingOnBackgroundMessage(
          _onBackgroundMessage);

        await _requestPermission(); // TODO(#324): defer if not logged into any accounts
        // On Android, the notification permission is only about showing
        // notifications in the UI, not about getting notification data in the
        // background.  Even if the app lacks permission to show notifications
        // in the UI, it's useful to get the token and enable the user's Zulip
        // servers to send notification data to the client, because it means if
        // the user later enables notifications, they'll promptly start working.

        // Get the FCM registration token, now and upon changes.  See FCM API docs:
        //   https://firebase.google.com/docs/cloud-messaging/android/client#sample-register
        ZulipBinding.instance.firebaseMessaging.onTokenRefresh
          .listen(_onTokenRefresh);
        await _getFcmToken();

      case TargetPlatform.iOS: // TODO(#324): defer requesting notif permission
        await ZulipBinding.instance.firebaseInitializeApp(
          options: kFirebaseOptionsIos);

        if (!await _requestPermission()) {
          // TODO(#324): request only "provisional" permission at this stage:
          //   https://github.com/zulip/zulip-flutter/issues/324#issuecomment-1771400325
          //   then proceed to get and use the token just like on Android
          return;
        }

        await _getApnsToken();
        // TODO does iOS need token refresh too?

      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        // Do nothing; we don't offer notifications on these platforms.
        break;
    }
  }

  Future<bool> _requestPermission() async {
    // Docs on this API: https://firebase.flutter.dev/docs/messaging/permissions/
    final settings = await ZulipBinding.instance.firebaseMessaging
      .requestPermission();
    assert(debugLog('notif authorization: ${settings.authorizationStatus}'));
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.denied:
        return false;
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
      case AuthorizationStatus.notDetermined:
        return true;
    }
  }

  Future<void> _getFcmToken() async {
    final value = await ZulipBinding.instance.firebaseMessaging.getToken();
    // TODO(#323) warn user if getToken returns null, or doesn't timely return
    assert(debugLog("notif FCM token: $value"));
    // The call to `getToken` won't cause `onTokenRefresh` to fire if we
    // already have a token from a previous run of the app.
    // So we need to use the `getToken` return value.
    token.value = value;
  }

  Future<void> _getApnsToken() async {
    final value = await ZulipBinding.instance.firebaseMessaging.getAPNSToken();
    // TODO(#323) warn user if getAPNSToken returns null, or doesn't timely return
    assert(debugLog("notif APNs token: $value"));
    token.value = value;
  }

  void _onTokenRefresh(String value) {
    assert(debugLog("new notif token: $value"));
    // On first launch after install, our [FirebaseMessaging.getToken] call
    // causes this to fire, followed by completing its own future so that
    // `_getToken` sees the value as well.  So in that case this is redundant.
    //
    // Subsequently, though, this can also potentially fire on its own, if for
    // some reason the FCM system decides to replace the token.  So both paths
    // need to save the value.
    token.value = value;
  }

  Future<void> registerToken(ApiConnection connection) async {
    final token = this.token.value;
    if (token == null) return;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await addFcmToken(connection, token: token);

      case TargetPlatform.iOS:
        final packageInfo = await ZulipBinding.instance.packageInfo;
        await addApnsToken(connection,
          token: token,
          appid: packageInfo!.packageName);

      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        assert(false);
    }
  }

  static Future<void> unregisterToken(ApiConnection connection, {required String token}) async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await removeFcmToken(connection, token: token);

      case TargetPlatform.iOS:
        await removeApnsToken(connection, token: token);

      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        assert(false);
    }
  }

  static void _onForegroundMessage(FirebaseRemoteMessage message) {
    assert(debugLog("notif message: ${message.data}"));
    _onRemoteMessage(message);
  }

  // This pragma `vm:entry-point` is needed in release mode, when this method
  // is needed at all (i.e. on Android):
  //   https://firebase.google.com/docs/cloud-messaging/flutter/receive#background_messages
  //   https://github.com/firebase/flutterfire/issues/9446#issuecomment-1240554285
  //   https://github.com/zulip/zulip-flutter/issues/528#issuecomment-1960646800
  @pragma('vm:entry-point')
  static Future<void> _onBackgroundMessage(FirebaseRemoteMessage message) async {
    // This callback will run in a separate isolate from the rest of the app.
    // See docs:
    //   https://firebase.flutter.dev/docs/messaging/usage/#background-messages
    _initBackgroundIsolate();

    assert(debugLog("notif message in background: ${message.data}"));
    _onRemoteMessage(message);
  }

  static void _initBackgroundIsolate() {
    bool isolateIsLive = true;
    assert(() {
      isolateIsLive = debugBackgroundIsolateIsLive;
      return true;
    }());
    if (!isolateIsLive) {
      return;
    }

    // Compare these setup steps to the ones in `main` in lib/main.dart .
    assert(() {
      debugLogEnabled = true;
      return true;
    }());
    LiveZulipBinding.ensureInitialized();
    NotificationDisplayManager.init(); // TODO call this just once per isolate
  }

  static void _onRemoteMessage(FirebaseRemoteMessage message) {
    final data = FcmMessage.fromJson(message.data);
    NotificationDisplayManager.onFcmMessage(data, message.data);
  }
}
