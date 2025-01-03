import 'android_media_scanner.g.dart';

// Wrapper class for MediaScanner functionality
class AndroidMediaScanner {
  final MediaScannerHostApi _api = MediaScannerHostApi();

  // Scans a file to make it visible in the device's media library
  Future<void> scanFile(String filePath) async {
      await _api.scanFile(filePath);
  }
}
