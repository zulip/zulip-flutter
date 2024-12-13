import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/android_download_manager.g.dart',
  kotlinOut: 'android/app/src/main/kotlin/com/zulip/flutter/DownloadManager.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.zulip.flutter',
    errorClassName: 'DownloadManagerError',
  ),
))

@HostApi()
abstract class DownloadManagerHostApi {
  /// Downloads a file using the given URL and saves it with the specified file name in the Downloads directory.
  /// Returns a success message or an error message.
  @async
  String downloadFile(String fileUrl, String fileName);
}
