import 'package:pigeon/pigeon.dart';

// To rebuild this pigeon's output after editing this file,
// run `tools/check pigeon --fix`.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/android_notifications.g.dart',
  kotlinOut: 'android/app/src/main/kotlin/com/zulip/flutter/AndroidNotifications.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.zulip.flutter'),
))

/// Corresponds to `androidx.core.app.NotificationChannelCompat`
///
/// See: https://developer.android.com/reference/androidx/core/app/NotificationChannelCompat
class NotificationChannel {
  /// Corresponds to `androidx.core.app.NotificationChannelCompat.Builder`
  ///
  /// See: https://developer.android.com/reference/androidx/core/app/NotificationChannelCompat.Builder
  NotificationChannel({
    required this.id,
    required this.importance,
    this.name,
    this.lightsEnabled,
    this.soundUrl,
    this.vibrationPattern,
  });

  final String id;

  /// Specifies the importance level of notifications
  /// to be posted on this channel.
  ///
  /// Must be a valid constant from [NotificationImportance].
  final int importance;

  final String? name;
  final bool? lightsEnabled;
  final String? soundUrl;
  final Int64List? vibrationPattern;
}

/// Corresponds to `android.content.Intent`
///
/// See:
///   https://developer.android.com/reference/android/content/Intent
///   https://developer.android.com/reference/android/content/Intent#Intent(java.lang.String,%20android.net.Uri,%20android.content.Context,%20java.lang.Class%3C?%3E)
class AndroidIntent {
  AndroidIntent({required this.action, required this.dataUrl, this.flags = 0});

  final String action;
  final String dataUrl;

  /// A combination of flags from [IntentFlag].
  final int flags;
}

/// Corresponds to `android.app.PendingIntent`.
///
/// See: https://developer.android.com/reference/android/app/PendingIntent
class PendingIntent {
  /// Corresponds to `PendingIntent.getActivity`.
  PendingIntent({required this.requestCode, required this.intent, required this.flags});

  final int requestCode;
  final AndroidIntent intent;

  /// A combination of flags from [PendingIntent.flags], and others associated
  /// with `Intent`; see Android docs for `PendingIntent.getActivity`.
  final int flags;
}

/// Corresponds to `androidx.core.app.NotificationCompat.InboxStyle`
///
/// See: https://developer.android.com/reference/androidx/core/app/NotificationCompat.InboxStyle
class InboxStyle {
  InboxStyle({required this.summaryText});

  final String summaryText;
}

/// Corresponds to `androidx.core.app.Person`
///
/// See: https://developer.android.com/reference/androidx/core/app/Person
class Person {
  Person({
    required this.iconBitmap,
    required this.key,
    required this.name,
  });

  /// An icon for this person.
  ///
  /// This should be compressed image data, in a format to be passed
  /// to `androidx.core.graphics.drawable.IconCompat.createWithData`.
  /// Supported formats include JPEG, PNG, and WEBP.
  ///
  /// See:
  ///  https://developer.android.com/reference/androidx/core/graphics/drawable/IconCompat#createWithData(byte[],int,int)
  final Uint8List? iconBitmap;

  final String key;
  final String name;
}

/// Corresponds to `androidx.core.app.NotificationCompat.MessagingStyle.Message`
///
/// See: https://developer.android.com/reference/androidx/core/app/NotificationCompat.MessagingStyle.Message
class MessagingStyleMessage {
  MessagingStyleMessage({
    required this.text,
    required this.timestampMs,
    required this.person,
  });

  final String text;
  final int timestampMs;
  final Person person;
}

/// Corresponds to `androidx.core.app.NotificationCompat.MessagingStyle`
///
/// See: https://developer.android.com/reference/androidx/core/app/NotificationCompat.MessagingStyle
class MessagingStyle {
  MessagingStyle({
    required this.user,
    required this.conversationTitle,
    required this.isGroupConversation,
    required this.messages,
  });

  final Person user;
  final String? conversationTitle;
  final List<MessagingStyleMessage> messages;
  final bool isGroupConversation;
}

/// Corresponds to `android.app.Notification`
///
/// See: https://developer.android.com/reference/kotlin/android/app/Notification
class Notification {
  Notification({required this.group, required this.extras});

  final String group;
  final Map<String, String> extras;
  // Various other properties too; add them if needed.
}

/// Corresponds to `android.service.notification.StatusBarNotification`
///
/// See: https://developer.android.com/reference/android/service/notification/StatusBarNotification
class StatusBarNotification {
  StatusBarNotification({required this.id, required this.tag, required this.notification});

  final int id;
  final String tag;
  final Notification notification;

  // Ignore `groupKey` and `key`.  While the `.groupKey` contains the
  // `.notification.group`, and the `.key` contains the `.id` and `.tag`,
  // they also have more stuff added on (and their structure doesn't seem to
  // be documented.)
  // final String? groupKey;
  // final String? key;

  // Various other properties too; add them if needed.
}

/// Represents details about a notification sound stored in the
/// shared media store.
///
/// Returned as a list entry by
/// [AndroidNotificationHostApi.listStoredSoundsInNotificationsDirectory].
class StoredNotificationSound {
  StoredNotificationSound({
    required this.fileName,
    required this.isOwned,
    required this.contentUrl,
  });

  /// The display name of the sound file.
  final String fileName;

  /// Specifies whether this file was created by the app.
  ///
  /// It is true if the `MediaStore.Audio.Media.OWNER_PACKAGE_NAME` key in the
  /// metadata matches the app's package name.
  final bool isOwned;

  /// A `content://…` URL pointing to the sound file.
  final String contentUrl;
}

@HostApi()
abstract class AndroidNotificationHostApi {
  /// Corresponds to `androidx.core.app.NotificationManagerCompat.createNotificationChannel`.
  ///
  /// See: https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat#createNotificationChannel(androidx.core.app.NotificationChannelCompat)
  void createNotificationChannel(NotificationChannel channel);

  /// Corresponds to `androidx.core.app.NotificationManagerCompat.getNotificationChannelsCompat`.
  ///
  /// See: https://developer.android.com/reference/kotlin/androidx/core/app/NotificationManagerCompat#getNotificationChannelsCompat()
  List<NotificationChannel> getNotificationChannels();

  /// Corresponds to `androidx.core.app.NotificationManagerCompat.deleteNotificationChannel`
  ///
  /// See: https://developer.android.com/reference/kotlin/androidx/core/app/NotificationManagerCompat#deleteNotificationChannel(java.lang.String)
  void deleteNotificationChannel(String channelId);

  /// The list of notification sound files present under `Notifications/Zulip/`
  /// in the device's shared media storage,
  /// found with `android.content.ContentResolver.query`.
  ///
  /// This is a complex ad-hoc method.
  /// For detailed behavior, see its implementation.
  ///
  /// Requires minimum of Android 10 (API 29) or higher.
  ///
  /// See: https://developer.android.com/reference/android/content/ContentResolver#query(android.net.Uri,%20java.lang.String[],%20java.lang.String,%20java.lang.String[],%20java.lang.String)
  List<StoredNotificationSound> listStoredSoundsInNotificationsDirectory();

  /// Wraps `android.content.ContentResolver.insert` combined with
  /// `android.content.ContentResolver.openOutputStream` and
  /// `android.content.res.Resources.openRawResource`.
  ///
  /// Copies a raw resource audio file to `Notifications/Zulip/`
  /// directory in device's shared media storage. Returns the URL
  /// of the target file in media store.
  ///
  /// Requires minimum of Android 10 (API 29) or higher.
  ///
  /// See:
  ///   https://developer.android.com/reference/android/content/ContentResolver#insert(android.net.Uri,%20android.content.ContentValues)
  ///   https://developer.android.com/reference/android/content/ContentResolver#openOutputStream(android.net.Uri)
  ///   https://developer.android.com/reference/android/content/res/Resources#openRawResource(int)
  String copySoundResourceToMediaStore({required String targetFileDisplayName, required String sourceResourceName});

  /// Corresponds to `android.app.NotificationManager.notify`,
  /// combined with `androidx.core.app.NotificationCompat.Builder`.
  ///
  /// The arguments `tag` and `id` go to the `notify` call.
  /// The rest go to method calls on the builder.
  ///
  /// The `color` should be in the form 0xAARRGGBB.
  /// See [ColorExtension.argbInt].
  ///
  /// The `smallIconResourceName` is passed to `android.content.res.Resources.getIdentifier`
  /// to get a resource ID to pass to `Builder.setSmallIcon`.
  /// Whatever name is passed there must appear in keep.xml too:
  /// see https://github.com/zulip/zulip-flutter/issues/528 .
  ///
  /// See:
  ///   https://developer.android.com/reference/kotlin/android/app/NotificationManager.html#notify
  ///   https://developer.android.com/reference/androidx/core/app/NotificationCompat.Builder
  // TODO(pigeon): Try ProxyApi for Notification objects, once that exists for Kotlin.
  //   As of 2024-03, ProxyApi is actively being implemented; the Dart side just landed.
  //   https://github.com/flutter/flutter/issues/134777
  void notify({
    String? tag,
    required int id,

    // The remaining arguments go to method calls on NotificationCompat.Builder.
    bool? autoCancel,
    required String channelId,
    int? color,
    PendingIntent? contentIntent,
    String? contentText,
    String? contentTitle,
    Map<String, String>? extras,
    String? groupKey,
    InboxStyle? inboxStyle,
    bool? isGroupSummary,
    MessagingStyle? messagingStyle,
    int? number,
    String? smallIconResourceName,
    // NotificationCompat.Builder has lots more methods; add as needed.
    // Keep them alphabetized, for easy comparison with that class's docs.
  });

  /// Wraps `androidx.core.app.NotificationManagerCompat.getActiveNotifications`,
  /// combined with `androidx.core.app.NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification`.
  ///
  /// Returns the messaging style, if any, of an active notification
  /// that has tag `tag`.  If there are several such notifications,
  /// an arbitrary one of them is used.
  /// Returns null if there are no such notifications.
  ///
  /// See:
  ///   https://developer.android.com/reference/kotlin/androidx/core/app/NotificationManagerCompat#getActiveNotifications()
  ///   https://developer.android.com/reference/kotlin/androidx/core/app/NotificationCompat.MessagingStyle#extractMessagingStyleFromNotification(android.app.Notification)
  MessagingStyle? getActiveNotificationMessagingStyleByTag(String tag);

  /// Corresponds to `androidx.core.app.NotificationManagerCompat.getActiveNotifications`.
  ///
  /// The keys of entries to fetch from notification's extras bundle must be
  /// specified in the [desiredExtras] list. If this list is empty, then
  /// [Notifications.extras] will also be empty. If value of the matched entry
  /// is not of type string or is null, then that entry will be skipped.
  ///
  /// See: https://developer.android.com/reference/kotlin/androidx/core/app/NotificationManagerCompat?hl=en#getActiveNotifications()
  List<StatusBarNotification> getActiveNotifications({required List<String> desiredExtras});

  /// Corresponds to `androidx.core.app.NotificationManagerCompat.cancel`.
  ///
  /// See: https://developer.android.com/reference/kotlin/androidx/core/app/NotificationManagerCompat?hl=en#cancel(java.lang.String,int)
  void cancel({String? tag, required int id});
}
