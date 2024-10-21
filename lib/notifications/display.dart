import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide Notification;

import '../api/notifications.dart';
import '../host/android_notifications.dart';
import '../log.dart';
import '../model/binding.dart';
import '../model/localizations.dart';
import '../model/narrow.dart';
import '../widgets/app.dart';
import '../widgets/color.dart';
import '../widgets/dialog.dart';
import '../widgets/message_list.dart';
import '../widgets/page.dart';
import '../widgets/store.dart';
import '../widgets/theme.dart';

AndroidNotificationHostApi get _androidHost => ZulipBinding.instance.androidNotificationHost;

/// Service for configuring our Android "notification channel".
class NotificationChannelManager {
  /// The channel ID we use for our one notification channel, which we use for
  /// all notifications.
  // TODO(launch) check this doesn't match zulip-mobile's current or previous
  //   channel IDs
  @visibleForTesting
  static const kChannelId = 'messages-1';

  /// The vibration pattern we set for notifications.
  // We try to set a vibration pattern that, with the phone in one's pocket,
  // is both distinctly present and distinctly different from the default.
  // Discussion: https://chat.zulip.org/#narrow/stream/48-mobile/topic/notification.20vibration.20pattern/near/1284530
  @visibleForTesting
  static final kVibrationPattern = Int64List.fromList([0, 125, 100, 450]);

  /// Create our notification channel, if it doesn't already exist.
  ///
  /// Deletes obsolete channels, if present, from old versions of the app.
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
  @visibleForTesting
  static Future<void> ensureChannel() async {
    // See if our current-version channel already exists; delete any obsolete
    // previous channels.
    var found = false;
    final channels = await _androidHost.getNotificationChannels();
    for (final channel in channels) {
      assert(channel != null); // TODO(#942)
      if (channel!.id == kChannelId) {
        found = true;
      } else {
        await _androidHost.deleteNotificationChannel(channel.id);
      }
    }

    if (found) {
      // The channel already exists; nothing to do.
      return;
    }

    // The channel doesn't exist. Create it.

    await _androidHost.createNotificationChannel(NotificationChannel(
      id: kChannelId,
      name: 'Messages', // TODO(i18n)
      importance: NotificationImportance.high,
      lightsEnabled: true,
      vibrationPattern: kVibrationPattern,
      // TODO(#340) sound
    ));
  }
}

/// Service for managing the notifications shown to the user.
class NotificationDisplayManager {
  static Future<void> init() async {
    await NotificationChannelManager.ensureChannel();
  }

  static void onFcmMessage(FcmMessage data, Map<String, dynamic> dataJson) {
    switch (data) {
      case MessageFcmMessage(): _onMessageFcmMessage(data, dataJson);
      case RemoveFcmMessage(): _onRemoveFcmMessage(data);
      case UnexpectedFcmMessage(): break; // TODO(log)
    }
  }

  static Future<void> _onMessageFcmMessage(MessageFcmMessage data, Map<String, dynamic> dataJson) async {
    assert(debugLog('notif message content: ${data.content}'));
    final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
    final groupKey = _groupKey(data);
    final conversationKey = _conversationKey(data, groupKey);

    final oldMessagingStyle = await _androidHost
      .getActiveNotificationMessagingStyleByTag(conversationKey);

    final MessagingStyle messagingStyle;
    if (oldMessagingStyle != null) {
      messagingStyle = oldMessagingStyle;
      messagingStyle.messages =
        oldMessagingStyle.messages.toList(); // Clone fixed-length list to growable.
    } else {
      messagingStyle = MessagingStyle(
        user: Person(
          key: _personKey(data.realmUrl, data.userId),
          name: zulipLocalizations.notifSelfUser),
        messages: [],
        isGroupConversation: switch (data.recipient) {
          FcmMessageChannelRecipient() => true,
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
      FcmMessageChannelRecipient(:var streamName?, :var topic) =>
        '#$streamName > $topic',
      FcmMessageChannelRecipient(:var topic) =>
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
        key: _personKey(data.realmUrl, data.senderId),
        name: data.senderFullName,
        iconBitmap: await _fetchBitmap(data.senderAvatarUrl))));

    final intentDataUrl = NotificationOpenPayload(
      realmUrl: data.realmUrl,
      userId: data.userId,
      narrow: switch (data.recipient) {
        FcmMessageChannelRecipient(:var streamId, :var topic) =>
          TopicNarrow(streamId, topic),
        FcmMessageDmRecipient(:var allRecipientIds) =>
          DmNarrow(allRecipientIds: allRecipientIds, selfUserId: data.userId),
      }).buildUrl();

    await _androidHost.notify(
      // TODO the notification ID can be constant, instead of matching requestCode
      //   (This is a legacy of `flutter_local_notifications`.)
      id: notificationIdAsHashOf(conversationKey),
      tag: conversationKey,
      channelId: NotificationChannelManager.kChannelId,
      groupKey: groupKey,

      color: kZulipBrandColor.argbInt,
      // TODO vary notification icon for debug
      smallIconResourceName: 'zulip_notification', // This name must appear in keep.xml too: https://github.com/zulip/zulip-flutter/issues/528

      messagingStyle: messagingStyle,
      number: messagingStyle.messages.length,
      extras: {
        // Used to decide when a `RemoveFcmMessage` event should clear this notification.
        kExtraLastZulipMessageId: data.zulipMessageId.toString(),
      },

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
        intent: AndroidIntent(
          action: IntentAction.view,
          dataUrl: intentDataUrl.toString(),
          extras: {}),
        // TODO this doesn't set the Intent flags we set in zulip-mobile; is that OK?
        //   (This is a legacy of `flutter_local_notifications`.)
        ),
      autoCancel: true,
    );

    await _androidHost.notify(
      id: notificationIdAsHashOf(groupKey),
      tag: groupKey,
      channelId: NotificationChannelManager.kChannelId,
      groupKey: groupKey,
      isGroupSummary: true,

      color: kZulipBrandColor.argbInt,
      // TODO vary notification icon for debug
      smallIconResourceName: 'zulip_notification', // This name must appear in keep.xml too: https://github.com/zulip/zulip-flutter/issues/528
      inboxStyle: InboxStyle(
        // TODO(#570) Show organization name, not URL
        summaryText: data.realmUrl.toString()),

      // On Android 11 and lower, if autoCancel is not specified,
      // the summary notification may linger even after all child
      // notifications have been opened and cleared.
      // TODO(android-12): cut this autoCancel workaround
      autoCancel: true,
    );
  }

  static void _onRemoveFcmMessage(RemoveFcmMessage data) async {
    // We have an FCM message telling us that some Zulip messages were read
    // and should no longer appear as notifications.  We'll remove their
    // conversations' notifications, if appropriate, and then the whole
    // notification group if it's now empty.
    assert(debugLog('notif remove zulipMessageIds: ${data.zulipMessageIds}'));

    // There may be a lot of messages mentioned here, across a lot of
    // conversations.  But they'll all be for one account, so they'll
    // fall under one notification group.
    final groupKey = _groupKey(data);

    // Find any conversations we can cancel the notification for.
    // The API doesn't lend itself to removing individual messages as
    // they're read, so we wait until we're ready to remove the whole
    // conversation's notification.  For background discussion, see:
    //   https://github.com/zulip/zulip-mobile/pull/4842#pullrequestreview-725817909
    var haveRemaining = false;
    final activeNotifications = await _androidHost.getActiveNotifications(
      desiredExtras: [kExtraLastZulipMessageId]);
    for (final statusBarNotification in activeNotifications) {
      if (statusBarNotification == null) continue; // TODO(pigeon) eliminate this case

      // The StatusBarNotification object describes an active notification in the UI.
      // Its `.tag`, `.id`, and `.notification` are the same values as we passed to
      // [AndroidNotificationHostApi.notify] (and so to `NotificationManager#notify`
      // in the underlying Android APIs).  So these are good to match on and inspect.
      final notification = statusBarNotification.notification;

      // Sadly we don't get toString on Pigeon data classes: flutter#59027
      assert(debugLog('  existing notif'
        ' id: ${statusBarNotification.id}, tag: ${statusBarNotification.tag},'
        ' notification: (group: ${notification.group}, extras: ${notification.extras}))'));

      // Don't act on notifications that are for other Zulip accounts/identities.
      if (notification.group != groupKey) continue;

      // Don't act on the summary notification for the group.
      if (statusBarNotification.tag == groupKey) continue;

      final lastMessageIdStr = notification.extras[kExtraLastZulipMessageId];
      assert(lastMessageIdStr != null);
      if (lastMessageIdStr == null) continue; // TODO(log)
      final lastMessageId = int.parse(lastMessageIdStr, radix: 10);
      if (data.zulipMessageIds.contains(lastMessageId)) {
        // The latest Zulip message in this conversation was read.
        // That's our cue to cancel the notification for the conversation.
        await _androidHost.cancel(
          tag: statusBarNotification.tag, id: statusBarNotification.id);
        assert(debugLog('  … notif cancelled.'));
      } else {
        // This notification is for another conversation that's still unread.
        // We won't cancel the summary notification.
        haveRemaining = true;
      }
    }

    if (!haveRemaining) {
      // The notification group is now empty; it had no notifications we didn't
      // just cancel, except the summary notification.  Cancel that one too.
      //
      // Even though we enable the `autoCancel` flag for summary notification
      // during creation, the summary notification doesn't get auto canceled if
      // child notifications are canceled programatically as done above.
      await _androidHost.cancel(
        tag: groupKey, id: notificationIdAsHashOf(groupKey));
    }
  }

  /// A key we use in [Notification.extras] for the [Message.id] of the
  /// latest Zulip message in the notification's conversation.
  ///
  /// We use this to determine if a [RemoveFcmMessage] event should
  /// clear that specific notification.
  @visibleForTesting
  static const kExtraLastZulipMessageId = 'lastZulipMessageId';

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
      FcmMessageChannelRecipient(:var streamId, :var topic) => 'stream:$streamId:$topic',
      FcmMessageDmRecipient(:var allRecipientIds) => 'dm:${allRecipientIds.join(',')}',
    };
    return '$groupKey|$conversation';
  }

  static String _groupKey(FcmMessageWithIdentity data) {
    // The realm URL can't contain a `|`, because `|` is not a URL code point:
    //   https://url.spec.whatwg.org/#url-code-points
    return "${data.realmUrl}|${data.userId}";
  }

  static String _personKey(Uri realmUrl, int userId) => "$realmUrl|$userId";

  /// Navigates to the [MessageListPage] of the specific conversation
  /// given the `zulip://notification/…` Android intent data URL,
  /// generated with [NotificationOpenPayload.buildUrl] while creating
  /// the notification.
  static Future<void> navigateForNotification(Uri url) async {
    assert(debugLog('opened notif: url: $url'));

    assert(url.scheme == 'zulip' && url.host == 'notification');
    final payload = NotificationOpenPayload.parseUrl(url);

    NavigatorState navigator = await ZulipApp.navigator;
    final context = navigator.context;
    assert(context.mounted);
    if (!context.mounted) return; // TODO(linter): this is impossible as there's no actual async gap, but the use_build_context_synchronously lint doesn't see that

    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalStore = GlobalStoreWidget.of(context);
    final account = globalStore.accounts.firstWhereOrNull((account) =>
      account.realmUrl == payload.realmUrl && account.userId == payload.userId);
    if (account == null) { // TODO(log)
      showErrorDialog(context: context,
        title: zulipLocalizations.errorNotificationOpenTitle,
        message: zulipLocalizations.errorNotificationOpenAccountMissing);
      return;
    }

    // TODO(nav): Better interact with existing nav stack on notif open
    unawaited(navigator.push(MaterialAccountWidgetRoute<void>(accountId: account.id,
      // TODO(#82): Open at specific message, not just conversation
      page: MessageListPage(initNarrow: payload.narrow))));
  }

  static Future<Uint8List?> _fetchBitmap(Uri url) async {
    try {
      // TODO timeout to prevent waiting indefinitely
      final resp = await http.get(url);
      if (resp.statusCode == HttpStatus.ok) {
        return resp.bodyBytes;
      }
    } catch (e) {
      // TODO(log)
    }
    return null;
  }
}

/// The information contained in 'zulip://notification/…' internal
/// Android intent data URL, used for notification-open flow.
class NotificationOpenPayload {
  final Uri realmUrl;
  final int userId;
  final Narrow narrow;

  NotificationOpenPayload({
    required this.realmUrl,
    required this.userId,
    required this.narrow,
  });

  factory NotificationOpenPayload.parseUrl(Uri url) {
    if (url case Uri(
      scheme: 'zulip',
      host: 'notification',
      queryParameters: {
        'realm_url': var realmUrlStr,
        'user_id': var userIdStr,
        'narrow_type': var narrowType,
        // In case of narrowType == 'topic':
        // 'channel_id' and 'topic' handled below.

        // In case of narrowType == 'dm':
        // 'all_recipient_ids' handled below.
      },
    )) {
      final realmUrl = Uri.parse(realmUrlStr);
      final userId = int.parse(userIdStr, radix: 10);

      final Narrow narrow;
      switch (narrowType) {
        case 'topic':
          final channelIdStr = url.queryParameters['channel_id']!;
          final channelId = int.parse(channelIdStr, radix: 10);
          final topic = url.queryParameters['topic']!;
          narrow = TopicNarrow(channelId, topic);
        case 'dm':
          final allRecipientIdsStr = url.queryParameters['all_recipient_ids']!;
          final allRecipientIds = allRecipientIdsStr.split(',')
            .map((idStr) => int.parse(idStr, radix: 10))
            .toList(growable: false);
          narrow = DmNarrow(allRecipientIds: allRecipientIds, selfUserId: userId);
        default:
          throw const FormatException();
      }

      return NotificationOpenPayload(
        realmUrl: realmUrl,
        userId: userId,
        narrow: narrow,
      );
    } else {
      // TODO(dart): simplify after https://github.com/dart-lang/language/issues/2537
      throw const FormatException();
    }
  }

  Uri buildUrl() {
    return Uri(
      scheme: 'zulip',
      host: 'notification',
      queryParameters: <String, String>{
        'realm_url': realmUrl.toString(),
        'user_id': userId.toString(),
        ...(switch (narrow) {
          TopicNarrow(streamId: var channelId, :var topic) => {
            'narrow_type': 'topic',
            'channel_id': channelId.toString(),
            'topic': topic,
          },
          DmNarrow(:var allRecipientIds) => {
            'narrow_type': 'dm',
            'all_recipient_ids': allRecipientIds.join(','),
          },
          _ => throw UnsupportedError('Found an unexpected Narrow of type ${narrow.runtimeType}.'),
        })
      },
    );
  }
}
