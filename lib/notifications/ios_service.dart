import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../host/ios_notifications.g.dart';
import '../model/binding.dart';

import '../log.dart';

@pragma('vm:entry-point')
void iosNotificationServiceMain() {
  if (defaultTargetPlatform != TargetPlatform.iOS) throw Error();

  assert(() {
    debugLogEnabled = true;
    return true;
  }());

  assert(debugLog('iosNotificationServiceMain'));
  WidgetsFlutterBinding.ensureInitialized();
  LiveZulipBinding.ensureInitialized();

  IosNotificationService.init();
}

@visibleForTesting
abstract class IosNotificationService {
  @visibleForTesting
  static void init() {
    assert(debugLog('IosNotificationService.init'));
    ZulipBinding.instance.setupIosNotifFlutterApi(_IosNotifFlutterApiImpl());
  }
}

class _IosNotifFlutterApiImpl extends IosNotifFlutterApi {
  @override
  Future<ImprovedNotificationContent> didReceivePushNotification(NotificationContent content) async {
    assert(debugLog("_IosNotifFlutterApiImpl.didReceivePushNotification"));
    assert(debugLog("content.payload=${jsonEncode(content.payload)}"));

    final apsData = content.payload['aps'] as Map<Object?, Object?>;
    final alertData = apsData['alert'] as Map<Object?, Object?>;
    final title = alertData['title'] as String;
    final body = alertData['body'] as String;

    // This doesn't ultimately have any effect: it returns the same
    // title and body that the notification already had, so nothing changes.
    // Moreover this code doesn't run in the first place when talking to a
    // normal Zulip server, because the non-E2EE APNs payloads
    // don't contain the flag `'mutable-content': 1` and so
    // don't trigger the NotificationService app extension.
    //
    // The purpose of this code is to be a checkpoint on the way to supporting
    // E2EE notifications (#1764) and more generally client-side control over
    // notification behavior (#1265).  It can be manually tested with
    // a server-side edit to set the `mutable-content` flag, plus other steps:
    //   https://github.com/zulip/zulip-flutter/pull/2156#pullrequestreview-4085925962
    return ImprovedNotificationContent(title: title, body: body);
  }
}
