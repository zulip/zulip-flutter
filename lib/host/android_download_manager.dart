import 'android_download_manager.g.dart';

// Wrapper class for Download functionality
class AndroidDownloader {
  final DownloadManagerHostApi _api = DownloadManagerHostApi();

  /// Downloads a file from the given URL and saves it with the specified file name.
  Future<void> downloadFile(String url, String fileName) async {
    await _api.downloadFile(url, fileName, );
  }
}
