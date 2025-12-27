import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/notifications/receive.dart';

import '../model/binding.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  Future<void> init() async {
    addTearDown(testBinding.reset);
    testBinding.firebaseMessagingInitialToken = '012abc';
    addTearDown(NotificationService.debugReset);
    NotificationService.debugBackgroundIsolateIsLive = false;
    await NotificationService.instance.start();
  }

  // The calls to firebaseMessagingOnMessage and firebaseMessagingOnBackgroundMessage
  // are tested end-to-end in `display_test.dart`, by posting FCM messages
  // to the respective streams and checking that the right logic then runs.

  // The token logic is tested end-to-end in `test/model/push_device_test.dart`.

  group('permissions', () {
    testWidgets('request permission', (tester) async {
      await init();
      check(testBinding.firebaseMessaging.takeRequestPermissionCalls())
        .length.equals(1);
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
  });
}
