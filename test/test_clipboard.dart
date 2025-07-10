import 'package:flutter/services.dart';

// Inspired by MockClipboard in test code in the Flutter tree:
//   https://github.com/flutter/flutter/blob/de26ad0a8/packages/flutter/test/widgets/clipboard_utils.dart
class MockClipboard {
  MockClipboard();

  dynamic clipboardData;

  Future<Object?> handleMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Clipboard.getData':
        return clipboardData;
      case 'Clipboard.hasStrings':
        final clipboardDataMap = clipboardData as Map<String, dynamic>?;
        final text = clipboardDataMap?['text'] as String?;
        return {'value': text != null && text.isNotEmpty};
      case 'Clipboard.setData':
        clipboardData = methodCall.arguments;
      default:
        if (methodCall.method.startsWith('Clipboard.')) {
          throw UnimplementedError();
        }
    }
    return null;
  }
}
