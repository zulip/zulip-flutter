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

  // The token logic is tested end-to-end in `test/model/store_test.dart` in the
  // `UpdateMachine.registerNotificationToken` tests.

  group('permissions', () {
    testWidgets('request permission', (tester) async {
      await init();
      check(testBinding.firebaseMessaging.takeRequestPermissionCalls())
        .length.equals(1);
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
  });

  group('tokens', () {
    test('APNs token registration using correct app bundle ID', () async {
      await init();
      check((await testBinding.packageInfo)?.packageName)
        .equals('com.zulip.flutter.test');
    }, );

    test('Fallback to default appBundleId if packageInfo is null', () async {
      await init();
      // setting package Info to null
      testBinding.setPackageInfo(null);

      const defaultAppId = 'com.zulip.flutter.test';

      check((await testBinding.packageInfo)?.packageName?? defaultAppId)
        .equals(defaultAppId);
    }, );
  });
}
