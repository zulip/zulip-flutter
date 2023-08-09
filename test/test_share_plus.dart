import 'package:flutter/services.dart';

class MockSharePlus {
  MockSharePlus();

  /// The last string that `shareWithResult` was called with.
  String? sharedString;

  Future<Object?> handleMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'shareWithResult':
        // The method channel doesn't preserve Map<String, dynamic> as
        // `arguments`'s type; logging runtimeType gives _Map<Object?, Object?>.
        final arguments = methodCall.arguments as Map;
        sharedString = arguments['text'] as String;
        return 'some-success-response';
      default:
        throw UnimplementedError();
    }
  }
}
