import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Person;

import '../api/notifications.dart';
import '../host/android_notifications.dart';
import '../log.dart';
import '../model/binding.dart';
import '../model/localizations.dart';
import '../model/narrow.dart';
import '../widgets/app.dart';
import '../widgets/message_list.dart';
import '../widgets/page.dart';
import '../widgets/store.dart';
import '../widgets/theme.dart';

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
  static Future<void> init() async {
    await ZulipBinding.instance.notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('zulip_notification'),
      ),
      onDidReceiveNotificationResponse: _onNotificationOpened,
    );
    final launchDetails = await ZulipBinding.instance.notifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handleNotificationAppLaunch(launchDetails!.notificationResponse);
    }
    await NotificationChannelManager._ensureChannel();
  }

  static void onFcmMessage(FcmMessage data, Map<String, dynamic> dataJson) {
    switch (data) {
      case MessageFcmMessage(): _onMessageFcmMessage(data, dataJson);
      case RemoveFcmMessage(): break; // TODO(#341) handle
      case UnexpectedFcmMessage(): break; // TODO(log)
    }
  }

  static Future<void> _onMessageFcmMessage(MessageFcmMessage data, Map<String, dynamic> dataJson) async {
    assert(debugLog('notif message content: ${data.content}'));
    final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
    final groupKey = _groupKey(data);
    final conversationKey = _conversationKey(data, groupKey);

    final oldMessagingStyle = await ZulipBinding.instance.androidNotificationHost
      .getActiveNotificationMessagingStyleByTag(conversationKey);

    final MessagingStyle messagingStyle;
    if (oldMessagingStyle != null) {
      messagingStyle = oldMessagingStyle;
      messagingStyle.messages =
        oldMessagingStyle.messages.toList(); // Clone fixed-length list to growable.
    } else {
      messagingStyle = MessagingStyle(
        user: Person(
          key: _personKey(data.realmUri, data.userId),
          name: zulipLocalizations.notifSelfUser),
        messages: [],
        isGroupConversation: switch (data.recipient) {
          FcmMessageStreamRecipient() => true,
          FcmMessageDmRecipient(:var allRecipientIds) when allRecipientIds.length > 2 => true,
          FcmMessageDmRecipient() => false,
        });
    }

    // The title typically won't change between messages in a conversation, but we
    // update it anyway. This means a DM sender's display name gets updated if it's
    // changed, which is a rare edge case but probably good. The main effect is that
    // group-DM threads (pending #794) get titled with the latest sender, rather than
    // the first.
    messagingStyle.conversationTitle = switch (data.recipient) {
      FcmMessageStreamRecipient(:var streamName?, :var topic) =>
        '#$streamName > $topic',
      FcmMessageStreamRecipient(:var topic) =>
        '#(unknown channel) > $topic', // TODO get stream name from data
      FcmMessageDmRecipient(:var allRecipientIds) when allRecipientIds.length > 2 =>
        zulipLocalizations.notifGroupDmConversationLabel(
          data.senderFullName, allRecipientIds.length - 2), // TODO use others' names, from data
      FcmMessageDmRecipient() =>
        data.senderFullName,
    };

    messagingStyle.messages.add(MessagingStyleMessage(
      text: data.content,
      timestampMs: data.time * 1000,
      person: Person(
        key: _personKey(data.realmUri, data.senderId),
        name: data.senderFullName,
        iconBitmap: await _fetchBitmap(data.senderAvatarUrl))));

    await ZulipBinding.instance.androidNotificationHost.notify(
      // TODO the notification ID can be constant, instead of matching requestCode
      //   (This is a legacy of `flutter_local_notifications`.)
      id: notificationIdAsHashOf(conversationKey),
      tag: conversationKey,
      channelId: NotificationChannelManager.kChannelId,
      groupKey: groupKey,

      color: kZulipBrandColor.value,
      // TODO vary notification icon for debug
      smallIconResourceName: 'zulip_notification', // This name must appear in keep.xml too: https://github.com/zulip/zulip-flutter/issues/528

      messagingStyle: messagingStyle,
      number: messagingStyle.messages.length,

      contentIntent: PendingIntent(
        // TODO make intent URLs distinct, instead of requestCode
        //   (This way is a legacy of flutter_local_notifications.)
        //   The Intent objects we make for different conversations look the same.
        //   They differ in their extras, but that doesn't count:
        //     https://developer.android.com/reference/android/app/PendingIntent
        //
        //   This leaves only PendingIntent.requestCode to distinguish one
        //   PendingIntent from another; the plugin sets that to the notification ID.
        //   We need a distinct PendingIntent for each conversation, so that the
        //   notifications can lead to the right conversations when opened.
        //   So, use a hash of the conversation key.
        requestCode: notificationIdAsHashOf(conversationKey),

        // TODO is setting PendingIntentFlag.updateCurrent OK?
        //   (That's a legacy of `flutter_local_notifications`.)
        flags: PendingIntentFlag.immutable | PendingIntentFlag.updateCurrent,
        intentPayload: jsonEncode(dataJson),
        // TODO this doesn't set the Intent flags we set in zulip-mobile; is that OK?
        //   (This is a legacy of `flutter_local_notifications`.)
        ),
      autoCancel: true,
    );

    await ZulipBinding.instance.androidNotificationHost.notify(
      id: notificationIdAsHashOf(groupKey),
      tag: groupKey,
      channelId: NotificationChannelManager.kChannelId,
      groupKey: groupKey,
      isGroupSummary: true,

      color: kZulipBrandColor.value,
      // TODO vary notification icon for debug
      smallIconResourceName: 'zulip_notification', // This name must appear in keep.xml too: https://github.com/zulip/zulip-flutter/issues/528
      inboxStyle: InboxStyle(
        // TODO(#570) Show organization name, not URL
        summaryText: data.realmUri.toString()),

      // On Android 11 and lower, if autoCancel is not specified,
      // the summary notification may linger even after all child
      // notifications have been opened and cleared.
      // TODO(android-12): cut this autoCancel workaround
      autoCancel: true,
    );
  }

  /// A notification ID, derived as a hash of the given string key.
  ///
  /// The result fits in 31 bits, the size of a nonnegative Java `int`,
  /// so that it can be used as an Android notification ID.  (It's possible
  /// negative values would work too, which would add one bit.)
  ///
  /// This is a cryptographic hash, meaning that collisions are about as
  /// unlikely as one could hope for given the size of the hash.
  @visibleForTesting
  static int notificationIdAsHashOf(String key) {
    final bytes = sha256.convert(utf8.encode(key)).bytes;
    return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16)
      | ((bytes[3] & 0x7f) << 24);
  }

  static String _conversationKey(MessageFcmMessage data, String groupKey) {
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

  static String _personKey(Uri realmUri, int userId) => "$realmUri|$userId";

  static void _onNotificationOpened(NotificationResponse response) async {
    final payload = jsonDecode(response.payload!) as Map<String, dynamic>;
    final data = MessageFcmMessage.fromJson(payload);
    assert(debugLog('opened notif: message ${data.zulipMessageId}, content ${data.content}'));
    _navigateForNotification(data);
  }

  static void _handleNotificationAppLaunch(NotificationResponse? response) async {
    assert(response != null);
    if (response == null) return; // TODO(log) seems like a bug in flutter_local_notifications if this can happen

    final payload = jsonDecode(response.payload!) as Map<String, dynamic>;
    final data = MessageFcmMessage.fromJson(payload);
    assert(debugLog('launched from notif: message ${data.zulipMessageId}, content ${data.content}'));
    _navigateForNotification(data);
  }

  static void _navigateForNotification(MessageFcmMessage data) async {
    NavigatorState navigator = await ZulipApp.navigator;
    final context = navigator.context;
    assert(context.mounted);
    if (!context.mounted) return; // TODO(linter): this is impossible as there's no actual async gap, but the use_build_context_synchronously lint doesn't see that

    final globalStore = GlobalStoreWidget.of(context);
    final account = globalStore.accounts.firstWhereOrNull((account) =>
      account.realmUrl == data.realmUri && account.userId == data.userId);
    if (account == null) return; // TODO(log)

    final narrow = switch (data.recipient) {
      FcmMessageStreamRecipient(:var streamId, :var topic) =>
        TopicNarrow(streamId, topic),
      FcmMessageDmRecipient(:var allRecipientIds) =>
        DmNarrow(allRecipientIds: allRecipientIds, selfUserId: account.userId),
    };

    assert(debugLog('  account: $account, narrow: $narrow'));
    // TODO(nav): Better interact with existing nav stack on notif open
    navigator.push(MaterialAccountWidgetRoute<void>(accountId: account.id,
      // TODO(#82): Open at specific message, not just conversation
      page: MessageListPage(initNarrow: narrow)));
    return;
  }

  static Future<Uint8List?> _fetchBitmap(Uri url) async {
    try {
      // TODO timeout to prevent waiting indefinitely
      final resp = await http.get(url);
      return resp.bodyBytes;
    } catch (e) {
      // TODO(log)
      return null;
    }
  }
}
