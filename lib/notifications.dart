import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api/notifications.dart';
import 'log.dart';
import 'model/binding.dart';
import 'widgets/app.dart';

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
    if (defaultTargetPlatform != TargetPlatform.android) return; // TODO(#321)

    await ZulipBinding.instance.firebaseInitializeApp();

    // TODO(#324) defer notif setup if user not logged into any accounts
    //   (in order to avoid calling for permissions)

    await NotificationDisplayManager._init();
    ZulipBinding.instance.firebaseMessagingOnMessage.listen(_onForegroundMessage);
    ZulipBinding.instance.firebaseMessagingOnBackgroundMessage(_onBackgroundMessage);

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

  static void _onForegroundMessage(FirebaseRemoteMessage message) {
    assert(debugLog("notif message: ${message.data}"));
    _onRemoteMessage(message);
  }

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
    NotificationDisplayManager._init(); // TODO call this just once per isolate
  }

  static void _onRemoteMessage(FirebaseRemoteMessage message) {
    final data = FcmMessage.fromJson(message.data);
    switch (data) {
      case MessageFcmMessage(): NotificationDisplayManager._onMessageFcmMessage(data, message.data);
      case RemoveFcmMessage(): break; // TODO(#341) handle
      case UnexpectedFcmMessage(): break; // TODO(log)
    }
  }
}

/// Service for configuring our Android "notification channel".
class NotificationChannelManager {
  @visibleForTesting
  static const kChannelId = 'messages-1';

  /// The vibration pattern we set for notifications.
  // We try to set a vibration pattern that, with the phone in one's pocket,
  // is both distinctly present and distinctly different from the default.
  // Discussion: https://chat.zulip.org/#narrow/stream/48-mobile/topic/notification.20vibration.20pattern/near/1284530
  @visibleForTesting
  static final kVibrationPattern = Int64List.fromList([0, 125, 100, 450]);

  /// Create our notification channel, if it doesn't already exist.
  //
  // NOTE when changing anything here: the changes will not take effect
  // for existing installs of the app!  That's because we'll have already
  // created the channel with the old settings, and they're in the user's
  // hands from there.  Our choices are:
  //
  //  * Leave the old settings in place for existing installs, so the
  //    changes only apply to new installs.
  //
  //  * Change `kChannelId`, so that we abandon the old channel and use
  //    a new one.  Existing installs will get the new settings.
  //
  //    This also means that if the user has changed any of the notification
  //    settings for the channel -- like "override Do Not Disturb", or "use
  //    a different sound", or "don't pop on screen" -- their changes get
  //    reset.  So this has to be done sparingly.
  //
  //    If we do this, we should also look for any channel with the old
  //    channel ID and delete it.  See zulip-mobile's `createNotificationChannel`
  //    in android/app/src/main/java/com/zulipmobile/notifications/NotificationChannelManager.kt .
  static Future<void> _ensureChannel() async {
    final plugin = ZulipBinding.instance.notifications;
    await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(AndroidNotificationChannel(
        kChannelId,
        'Messages', // TODO(i18n)
        importance: Importance.high,
        enableLights: true,
        vibrationPattern: kVibrationPattern,
        // TODO(#340) sound
      ));
  }
}

/// Service for managing the notifications shown to the user.
class NotificationDisplayManager {
  // We rely on the tag instead.
  @visibleForTesting
  static const kNotificationId = 0;

  static Future<void> _init() async {
    await ZulipBinding.instance.notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('zulip_notification'),
      ),
    );
    await NotificationChannelManager._ensureChannel();
  }

  static void _onMessageFcmMessage(MessageFcmMessage data, Map<String, dynamic> dataJson) {
    assert(debugLog('notif message content: ${data.content}'));
    final title = switch (data.recipient) {
      FcmMessageStreamRecipient(:var streamName?, :var topic) =>
        '$streamName > $topic',
      FcmMessageStreamRecipient(:var topic) =>
        '(unknown stream) > $topic', // TODO get stream name from data
      FcmMessageDmRecipient(:var allRecipientIds) when allRecipientIds.length > 2 =>
        '${data.senderFullName} to you and ${allRecipientIds.length - 2} others', // TODO(i18n), also plural; TODO use others' names, from data
      FcmMessageDmRecipient() =>
        data.senderFullName,
    };
    ZulipBinding.instance.notifications.show(
      kNotificationId,
      title,
      data.content,
      NotificationDetails(android: AndroidNotificationDetails(
        NotificationChannelManager.kChannelId,
        // This [FlutterLocalNotificationsPlugin.show] call can potentially create
        // a new channel, if our channel doesn't already exist.  That *shouldn't*
        // happen; if it does, it won't get the right settings.  Set the channel
        // name in that case to something that has a chance of warning the user,
        // and that can serve as a signature to diagnose the situation in support.
        // But really we should fix flutter_local_notifications to not do that
        // (see issue linked below), or replace that package entirely (#351).
        '(Zulip internal error)', // TODO never implicitly create channel: https://github.com/MaikuB/flutter_local_notifications/issues/2135
        tag: _conversationKey(data),
        color: kZulipBrandColor,
        icon: 'zulip_notification', // TODO vary for debug
        // TODO(#128) inbox-style
      )));
  }

  static String _conversationKey(MessageFcmMessage data) {
    final groupKey = _groupKey(data);
    final conversation = switch (data.recipient) {
      FcmMessageStreamRecipient(:var streamId, :var topic) => 'stream:$streamId:$topic',
      FcmMessageDmRecipient(:var allRecipientIds) => 'dm:${allRecipientIds.join(',')}',
    };
    return '$groupKey|$conversation';
  }

  static String _groupKey(FcmMessageWithIdentity data) {
    // The realm URL can't contain a `|`, because `|` is not a URL code point:
    //   https://url.spec.whatwg.org/#url-code-points
    return "${data.realmUri}|${data.userId}";
  }
}
