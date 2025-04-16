import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide Notification;
import 'package:http/http.dart' as http;

import '../api/model/model.dart';
import '../api/notifications.dart';
import '../generated/l10n/zulip_localizations.dart';
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

enum NotificationSound {
  // TODO(i18n): translate these file display names
  chime2(resourceName: 'chime2', fileDisplayName: 'Zulip - Low Chime.m4a'),
  chime3(resourceName: 'chime3', fileDisplayName: 'Zulip - Chime.m4a'),
  chime4(resourceName: 'chime4', fileDisplayName: 'Zulip - High Chime.m4a');
  // Any new entry here must appear in `keep.xml` too, see #528.

  const NotificationSound({
    required this.resourceName,
    required this.fileDisplayName,
  });
  final String resourceName;
  final String fileDisplayName;
}

/// Service for configuring our Android "notification channel".
class NotificationChannelManager {
  /// The channel ID we use for our one notification channel, which we use for
  /// all notifications.
  // TODO(launch) check this doesn't match zulip-mobile's current or previous
  //   channel IDs
  // Previous values: 'messages-1'
  @visibleForTesting
  static const kChannelId = 'messages-2';

  @visibleForTesting
  static const kDefaultNotificationSound = NotificationSound.chime3;

  /// The vibration pattern we set for notifications.
  // We try to set a vibration pattern that, with the phone in one's pocket,
  // is both distinctly present and distinctly different from the default.
  // Discussion: https://chat.zulip.org/#narrow/stream/48-mobile/topic/notification.20vibration.20pattern/near/1284530
  @visibleForTesting
  static final kVibrationPattern = Int64List.fromList([0, 125, 100, 450]);

  /// Generates an Android resource URL for the given resource name and type.
  ///
  /// For example, for a resource `@raw/chime3`, where `raw` would be the
  /// resource type and `chime3` would be the resource name it generates the
  /// following URL:
  ///   `android.resource://com.zulip.flutter/raw/chime3`
  ///
  /// Based on: https://stackoverflow.com/a/38340580
  static Uri _resourceUrlFromName({
    required String resourceTypeName,
    required String resourceEntryName,
  }) {
    const packageName = 'com.zulip.flutter'; // TODO(#407)

    // URL scheme for Android resource url.
    // See: https://developer.android.com/reference/android/content/ContentResolver#SCHEME_ANDROID_RESOURCE
    const schemeAndroidResource = 'android.resource';

    return Uri(
      scheme: schemeAndroidResource,
      host: packageName,
      pathSegments: <String>[resourceTypeName, resourceEntryName],
    );
  }

  /// Prepare our notification sounds; return a URL for our default sound.
  ///
  /// Where possible, this copies each of our notification sounds into shared storage
  /// so that the user can choose between them in the system notification settings.
  ///
  /// Returns a URL for our default notification sound: either in shared storage
  /// if we successfully copied it there, or else as our internal resource file.
  static Future<String> _ensureInitNotificationSounds() async {
    String defaultSoundUrl = _resourceUrlFromName(
      resourceTypeName: 'raw',
      resourceEntryName: kDefaultNotificationSound.resourceName).toString();

    final shouldUseResourceFile = switch (await ZulipBinding.instance.deviceInfo) {
      // Before Android 10 Q, we don't attempt to put the sounds in shared media storage.
      // Just use the resource file directly.
      // TODO(android-sdk-29): Simplify this away.
      AndroidDeviceInfo(:var sdkInt) => sdkInt < 29,
      _                              => true,
    };
    if (shouldUseResourceFile) return defaultSoundUrl;

    // First, look to see what notification sounds we've already stored,
    // and check against our list of sounds we have.
    final soundsToAdd = NotificationSound.values.toList();

    final List<StoredNotificationSound> storedSounds;
    try {
      storedSounds = await _androidHost.listStoredSoundsInNotificationsDirectory();
    } catch (e, st) {
      assert(debugLog('$e\n$st')); // TODO(log)
      return defaultSoundUrl;
    }
    for (final storedSound in storedSounds) {
      // If the file is one we put there, and has the name we give to our
      // default sound, then use it as the default sound.
      if (storedSound.fileName == kDefaultNotificationSound.fileDisplayName
          && storedSound.isOwned) {
        defaultSoundUrl = storedSound.contentUrl;
      }

      // If it has the name of any of our sounds, then don't try to add
      // that sound.  This applies even if we didn't put it there: the
      // name is taken, so if we tried adding it anyway it'd get some
      // other name (like "Zulip - Chime (1).m4a", with " (1)" added).
      // Which means the *next* launch would try to add it again ad infinitum.
      // We could avoid this given some other way to uniquely identify the
      // file, but haven't found an obvious one.
      //
      // This does mean it's possible the file isn't the one we would have
      // put there... but it probably is, just from a debug vs. release build
      // of the app (because those may have different package names).  And anyway,
      // this is a file we're supplying for the user in case they want it, not
      // something where the app depends on it having specific content.
      soundsToAdd.removeWhere((v) => v.fileDisplayName == storedSound.fileName);
    }

    // If that leaves any sounds we haven't yet put into shared storage
    // (e.g., because this is the first run after install, or after an
    // upgrade that added a sound), then store those.

    for (final sound in soundsToAdd) {
      try {
        final url = await _androidHost.copySoundResourceToMediaStore(
          targetFileDisplayName: sound.fileDisplayName,
          sourceResourceName: sound.resourceName);

        if (sound == kDefaultNotificationSound) {
          defaultSoundUrl = url;
        }
      } catch (e, st) {
        assert(debugLog("$e\n$st")); // TODO(log)
      }
    }

    return defaultSoundUrl;
  }

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
      if (channel.id == kChannelId) {
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

    final defaultSoundUrl = await _ensureInitNotificationSounds();

    await _androidHost.createNotificationChannel(NotificationChannel(
      id: kChannelId,
      name: 'Messages', // TODO(#1284)
      importance: NotificationImportance.high,
      lightsEnabled: true,
      soundUrl: defaultSoundUrl,
      vibrationPattern: kVibrationPattern,
    ));
  }
}

/// Service for managing the notifications shown to the user.
class NotificationDisplayManager {
  static Future<void> init() async {
    assert(defaultTargetPlatform == TargetPlatform.android);
    await NotificationChannelManager.ensureChannel();
  }

  static void onFcmMessage(FcmMessage data, Map<String, dynamic> dataJson) {
    assert(defaultTargetPlatform == TargetPlatform.android);
    switch (data) {
      case MessageFcmMessage(): _onMessageFcmMessage(data, dataJson);
      case RemoveFcmMessage(): _onRemoveFcmMessage(data);
      case UnexpectedFcmMessage(): break; // TODO(log)
    }
  }

  static Future<void> _onMessageFcmMessage(MessageFcmMessage data, Map<String, dynamic> dataJson) async {
    assert(debugLog('notif message content: ${data.content}'));
    final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
    final groupKey = _groupKey(data.realmUrl, data.userId);
    final conversationKey = _conversationKey(data, groupKey);

    final globalStore = await ZulipBinding.instance.getGlobalStore();
    final account = globalStore.accounts.firstWhereOrNull((account) =>
      account.realmUrl.origin == data.realmUrl.origin && account.userId == data.userId);

    // Skip showing notifications for a logged-out account. This can occur if
    // the unregisterToken request failed previously. It would be annoying
    // to the user if notifications keep showing up after they've logged out.
    // (Also alarming: it suggests the logout didn't fully work.)
    if (account == null) {
      return;
    }

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
        '#$streamName > ${topic.displayName}',
      FcmMessageChannelRecipient(:var topic) =>
        '#${zulipLocalizations.unknownChannelName} > ${topic.displayName}', // TODO get stream name from data
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
      id: kNotificationId,
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
        // The intent data URL is distinct for each conversation, so this value
        // doesn't matter.
        requestCode: 0,
        flags: PendingIntentFlag.immutable,
        intent: AndroidIntent(
          action: IntentAction.view,
          dataUrl: intentDataUrl.toString(),
          // See these sections in the Android docs:
          //   https://developer.android.com/guide/components/activities/tasks-and-back-stack#TaskLaunchModes
          //   https://developer.android.com/reference/android/content/Intent#FLAG_ACTIVITY_CLEAR_TOP
          //
          // * From the doc on `PendingIntent.getActivity` at
          //     https://developer.android.com/reference/android/app/PendingIntent#getActivity(android.content.Context,%20int,%20android.content.Intent,%20int)
          //   > Note that the activity will be started outside of the context of an
          //   > existing activity, so you must use the Intent.FLAG_ACTIVITY_NEW_TASK
          //   > launch flag in the Intent.
          //
          // * The flag FLAG_ACTIVITY_CLEAR_TOP is mentioned as being what the
          //   notification manager does; so use that.  It has no effect as long
          //   as we only have one activity; but if we add more, it will destroy
          //   all the activities on top of the target one.
          flags: IntentFlag.activityClearTop | IntentFlag.activityNewTask)),
      autoCancel: true,
    );

    await _androidHost.notify(
      id: kNotificationId,
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
    final groupKey = _groupKey(data.realmUrl, data.userId);

    // Find any conversations we can cancel the notification for.
    // The API doesn't lend itself to removing individual messages as
    // they're read, so we wait until we're ready to remove the whole
    // conversation's notification.  For background discussion, see:
    //   https://github.com/zulip/zulip-mobile/pull/4842#pullrequestreview-725817909
    var haveRemaining = false;
    final activeNotifications = await _androidHost.getActiveNotifications(
      desiredExtras: [kExtraLastZulipMessageId]);
    for (final statusBarNotification in activeNotifications) {
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
      await _androidHost.cancel(tag: groupKey, id: kNotificationId);
    }
  }

  static Future<void> removeNotificationsForAccount(Uri realmUrl, int userId) async {
    assert(defaultTargetPlatform == TargetPlatform.android);

    final groupKey = _groupKey(realmUrl, userId);
    final activeNotifications = await _androidHost.getActiveNotifications(
      desiredExtras: []);
    for (final statusBarNotification in activeNotifications) {
      if (statusBarNotification.notification.group == groupKey) {
        await _androidHost.cancel(
          tag: statusBarNotification.tag, id: statusBarNotification.id);
      }
    }
  }

  /// The constant numeric "ID" we use for all non-test notifications,
  /// along with unique tags.
  ///
  /// Because we construct a unique string "tag" for each distinct
  /// notification, and Android notifications are identified by the
  /// pair (tag, ID), it's simplest to leave these numeric IDs all the same.
  static const kNotificationId = 0x00C0FFEE;

  /// A key we use in [Notification.extras] for the [Message.id] of the
  /// latest Zulip message in the notification's conversation.
  ///
  /// We use this to determine if a [RemoveFcmMessage] event should
  /// clear that specific notification.
  @visibleForTesting
  static const kExtraLastZulipMessageId = 'lastZulipMessageId';

  static String _conversationKey(MessageFcmMessage data, String groupKey) {
    final conversation = switch (data.recipient) {
      FcmMessageChannelRecipient(:var streamId, :var topic) => 'stream:$streamId:${topic.canonicalize()}',
      FcmMessageDmRecipient(:var allRecipientIds) => 'dm:${allRecipientIds.join(',')}',
    };
    return '$groupKey|$conversation';
  }

  static String _groupKey(Uri realmUrl, int userId) {
    // The realm URL can't contain a `|`, because `|` is not a URL code point:
    //   https://url.spec.whatwg.org/#url-code-points
    return "$realmUrl|$userId";
  }

  static String _personKey(Uri realmUrl, int userId) => "$realmUrl|$userId";

  /// Provides the route and the account ID by parsing the notification URL.
  ///
  /// The URL must have been generated using [NotificationOpenPayload.buildUrl]
  /// while creating the notification.
  ///
  /// Returns null and shows an error dialog if the associated account is not
  /// found in the global store.
  static AccountRoute<void>? routeForNotification({
    required BuildContext context,
    required Uri url,
  }) {
    assert(defaultTargetPlatform == TargetPlatform.android);

    final globalStore = GlobalStoreWidget.of(context);

    assert(debugLog('got notif: url: $url'));
    assert(url.scheme == 'zulip' && url.host == 'notification');
    final payload = NotificationOpenPayload.parseUrl(url);

    final account = globalStore.accounts.firstWhereOrNull(
      (account) => account.realmUrl.origin == payload.realmUrl.origin
                && account.userId == payload.userId);
    if (account == null) { // TODO(log)
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(context: context,
        title: zulipLocalizations.errorNotificationOpenTitle,
        message: zulipLocalizations.errorNotificationOpenAccountNotFound);
      return null;
    }

    return MessageListPage.buildRoute(
      accountId: account.id,
      // TODO(#82): Open at specific message, not just conversation
      narrow: payload.narrow);
  }

  /// Navigates to the [MessageListPage] of the specific conversation
  /// given the `zulip://notification/…` Android intent data URL,
  /// generated with [NotificationOpenPayload.buildUrl] while creating
  /// the notification.
  static Future<void> navigateForNotification(Uri url) async {
    assert(defaultTargetPlatform == TargetPlatform.android);
    assert(debugLog('opened notif: url: $url'));

    NavigatorState navigator = await ZulipApp.navigator;
    final context = navigator.context;
    assert(context.mounted);
    if (!context.mounted) return; // TODO(linter): this is impossible as there's no actual async gap, but the use_build_context_synchronously lint doesn't see that

    final route = routeForNotification(context: context, url: url);
    if (route == null) return; // TODO(log)

    // TODO(nav): Better interact with existing nav stack on notif open
    unawaited(navigator.push(route));
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
          final topicStr = url.queryParameters['topic']!;
          narrow = TopicNarrow(channelId, TopicName(topicStr));
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
            'topic': topic.apiName,
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
