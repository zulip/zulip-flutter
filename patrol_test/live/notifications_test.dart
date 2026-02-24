import 'dart:math';

import 'package:checks/checks.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/main.dart';
import 'package:zulip/widgets/app.dart';

import 'binding.dart';

void main() {
  PatrolLiveZulipBinding.ensureInitialized();
  mainInit();

  patrolTest('notification', ($) async {
    await patrolLiveBinding.reset();
    final account = await patrolLiveBinding.addAccount(LiveCredentials.account());

    await $.pumpWidget(ZulipApp());
    await $.waitUntilVisible($('Inbox'));

    if (await $.platform.mobile.isPermissionDialogVisible()) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }

    await Future<void>.delayed(Duration(milliseconds: 500));

    // Put the app in the background.
    // (On iOS we don't show notifications when in the foreground: #408.)
    await $.platform.mobile.pressHome();

    final token = Random().nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final content = 'hello $token';
    final otherConnection = LiveCredentials.makeOtherConnection();
    await sendMessage(otherConnection,
      destination: DmDestination(userIds: [account.userId]),
      content: content);

    await $.platform.mobile.openNotifications();

    await Future<void>.delayed(Duration(seconds: 10)); // TODO poll? in a loop, with a timeout
    final notifs = await $.platform.mobile.getNotifications();
    check(notifs).isNotEmpty();

    await $.platform.mobile.tapOnNotificationBySelector(Selector(text: content));
    await $.waitUntilVisible($(RegExp(r'^DMs with')));

    // Scroll to the message.  (It might have been offscreen due to older unreads.)
    await $.scrollUntilVisible(finder: $(content));
    check($(content)).findsOne();
  });
}
