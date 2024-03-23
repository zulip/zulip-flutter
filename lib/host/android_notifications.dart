export './android_notifications.g.dart';

/// For use in [PendingIntent.flags].
///
/// See: https://developer.android.com/reference/android/app/PendingIntent#constants_1
abstract class PendingIntentFlag {
  /// Corresponds to `FLAG_ONE_SHOT`.
  static const oneShot = 1 << 30;

  /// Corresponds to `FLAG_NO_CREATE`.
  static const noCreate = 1 << 29;

  /// Corresponds to `FLAG_CANCEL_CURRENT`.
  static const cancelCurrent = 1 << 28;

  /// Corresponds to `FLAG_UPDATE_CURRENT`.
  static const updateCurrent = 1 << 27;

  /// Corresponds to `FLAG_IMMUTABLE`.
  static const immutable = 1 << 26;

  /// Corresponds to `FLAG_MUTABLE`.
  static const mutable = 1 << 25;

  /// Corresponds to `FLAG_ALLOW_UNSAFE_IMPLICIT_INTENT`.
  static const allowUnsafeImplicitIntent = 1 << 24;
}
