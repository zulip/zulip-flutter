import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class MockSharePlus {
  MockSharePlus();

  /// The mock [ShareResult.raw] that `shareWithResult` should give.
  String resultString = 'some-success-response';

  /// The last string that `shareWithResult` was called with.
  String? sharedString;

  Future<Object?> handleMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'share':
        // The method channel doesn't preserve Map<String, dynamic> as
        // `arguments`'s type; logging runtimeType gives _Map<Object?, Object?>.
        final arguments = methodCall.arguments as Map;
        sharedString = arguments['text'] as String;
        return resultString;
      default:
        throw UnimplementedError();
    }
  }
}
