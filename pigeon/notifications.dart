import 'package:pigeon/pigeon.dart';

// To rebuild this pigeon's output after editing this file,
// run `tools/check pigeon --fix`.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/android_notifications.g.dart',
  kotlinOut: 'android/app/src/main/kotlin/com/zulip/flutter/Notifications.g.kt',
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
  final Int64List? vibrationPattern;
}

/// Corresponds to `android.content.Intent`
///
/// See:
///   https://developer.android.com/reference/android/content/Intent
///   https://developer.android.com/reference/android/content/Intent#Intent(java.lang.String,%20android.net.Uri,%20android.content.Context,%20java.lang.Class%3C?%3E)
class AndroidIntent {
  AndroidIntent({required this.action, required this.uri});

  final String action;
  final String uri;
}

/// Corresponds to `android.app.PendingIntent`.
///
/// See: https://developer.android.com/reference/android/app/PendingIntent
class PendingIntent {
  /// Corresponds to `PendingIntent.getActivity`.
  ///
  /// See: https://developer.android.com/reference/android/app/PendingIntent#getActivity(android.content.Context,%20int,%20android.content.Intent,%20int)
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
  // TODO(pigeon): Make list item non-nullable, once pigeon supports non-nullable type arguments.
  //   https://github.com/flutter/flutter/issues/97848
  final List<MessagingStyleMessage?> messages;
  final bool isGroupConversation;
}

@HostApi()
abstract class AndroidNotificationHostApi {
  /// Corresponds to `androidx.core.app.NotificationManagerCompat.createNotificationChannel`.
  ///
  /// See: https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat#createNotificationChannel(androidx.core.app.NotificationChannelCompat)
  void createNotificationChannel(NotificationChannel channel);

  /// Corresponds to `android.app.NotificationManager.notify`,
  /// combined with `androidx.core.app.NotificationCompat.Builder`.
  ///
  /// The arguments `tag` and `id` go to the `notify` call.
  /// The rest go to method calls on the builder.
  ///
  /// The `color` should be in the form 0xAARRGGBB.
  /// This is the form returned by [Color.value].
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
    Map<String?, String?>? extras,
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
}
