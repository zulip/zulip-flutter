import 'dart:math';

import 'package:checks/checks.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/main.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/widgets/app.dart';

import 'binding.dart';
import '../../test/example_data.dart' as eg;

void main() {
  PatrolLiveZulipBinding.ensureInitialized();
  mainInit();

  ApiConnection makeOtherConnection() {
    return ApiConnection.live(
      realmUrl: Uri.parse(const String.fromEnvironment('REALM_URL')),
      email: const String.fromEnvironment('OTHER_EMAIL'),
      apiKey: const String.fromEnvironment('OTHER_API_KEY'),
      zulipFeatureLevel: eg.recentZulipFeatureLevel, // TODO get real value from server
    );
  }

  patrolTest('notification', ($) async {
    await patrolLiveBinding.reset();

    final globalStore = await ZulipBinding.instance.getGlobalStore();
    await globalStore.insertAccount(eg.account(
      realmUrl: Uri.parse(const String.fromEnvironment('REALM_URL')),
      user: eg.user(
        userId: int.parse(const String.fromEnvironment('USER_ID'), radix: 10),
        deliveryEmail: const String.fromEnvironment('EMAIL')),
      apiKey: const String.fromEnvironment('API_KEY'),
    ).toCompanion(false));
    final account = globalStore.accounts.single;
    await globalStore.setLastVisitedAccount(account.id);

    await $.pumpWidget(ZulipApp());
    await $.waitUntilVisible($('Inbox'));

    if (await $.platform.mobile.isPermissionDialogVisible()) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }

    final navigator = await ZulipApp.navigator;
    final context = navigator.context;
    if (!context.mounted) throw Error();
    final store = globalStore.getAccount(account.id)!;

    await Future<void>.delayed(Duration(milliseconds: 500));

    // Put the app in the background.
    // (On iOS we don't show notifications when in the foreground: #408.)
    await $.platform.mobile.pressHome();

    final token = Random().nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final content = 'hello $token';
    final otherConnection = makeOtherConnection();
    await sendMessage(otherConnection,
      destination: DmDestination(userIds: [store.userId]),
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
