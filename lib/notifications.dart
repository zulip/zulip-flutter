import 'package:flutter/foundation.dart';

import 'log.dart';
import 'model/binding.dart';

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
    instance.token = ValueNotifier(null);
  }

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
    if (defaultTargetPlatform != TargetPlatform.android) return; // TODO(#321)

    await ZulipBinding.instance.firebaseInitializeApp();

    // TODO(#324) defer notif setup if user not logged into any accounts
    //   (in order to avoid calling for permissions)

    ZulipBinding.instance.firebaseMessagingOnMessage.listen(_onRemoteMessage);

    // Get the FCM registration token, now and upon changes.  See FCM API docs:
    //   https://firebase.google.com/docs/cloud-messaging/android/client#sample-register
    ZulipBinding.instance.firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
    await _getToken();
  }

  Future<void> _getToken() async {
    final value = await ZulipBinding.instance.firebaseMessaging.getToken();
    // TODO(#323) warn user if getToken returns null, or doesn't timely return
    assert(debugLog("notif token: $value"));
    // The call to `getToken` won't cause `onTokenRefresh` to fire if we
    // already have a token from a previous run of the app.
    // So we need to use the `getToken` return value.
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

  static void _onRemoteMessage(FirebaseRemoteMessage message) {
    assert(debugLog("notif message: ${message.data}"));
    // TODO(#122): parse data; show notification UI
  }
}
