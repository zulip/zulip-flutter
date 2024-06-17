import 'package:pigeon/pigeon.dart';

// To rebuild this pigeon's output after editing this file,
// run `tools/check pigeon --fix`.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/android_notifications.g.dart',
  kotlinOut: 'android/app/src/main/kotlin/com/zulip/flutter/Notifications.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.zulip.flutter'),
))

/// Corresponds to `android.app.PendingIntent`.
///
/// See: https://developer.android.com/reference/android/app/PendingIntent
class PendingIntent {
  /// Corresponds to `PendingIntent.getActivity`.
  PendingIntent({required this.requestCode, required this.intentPayload, required this.flags});

  final int requestCode;

  /// A value set on an extra on the Intent, and passed to
  /// the on-notification-opened callback.
  // TODO replace intentPayload with a more direct wrapping of the underlying API
  final String intentPayload;

  /// A combination of flags from [PendingIntent.flags], and others associated
  /// with `Intent`; see Android docs for `PendingIntent.getActivity`.
  final int flags;
}

@HostApi()
abstract class AndroidNotificationHostApi {
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
    required String channelId,
    int? color,
    PendingIntent? contentIntent,
    String? contentText,
    String? contentTitle,
    Map<String?, String?>? extras,
    String? smallIconResourceName,
    // NotificationCompat.Builder has lots more methods; add as needed.
    // Keep them alphabetized, for easy comparison with that class's docs.
  });
}
