import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/android_media_scanner.g.dart',
  kotlinOut: 'android/app/src/main/kotlin/com/zulip/flutter/MediaScanner.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.zulip.flutter',
    errorClassName: 'NotificationsError',
  ),
))

@HostApi()
abstract class MediaScannerHostApi {
  /// Scans the file at the given path to make it visible in the device's media library.
  /// Returns a success message if the scan was initiated successfully.
  @async
  String scanFile(String filePath);
}