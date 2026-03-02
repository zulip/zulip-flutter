// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:math';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/main.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/store.dart';

import '../test/example_data.dart' as eg;

void main() {
  mainInit();

  // Successive tests in this file interact with the same real server
  // and the same real device platform, by the nature of live tests.
  // So we might as well let them use the same real database and global store.
  ZulipBinding.instance.debugRelaxGetGlobalStoreUniquely = true;

  ApiConnection makeOtherConnection() {
    return ApiConnection.live(
      realmUrl: Uri.parse(const String.fromEnvironment('REALM_URL')),
      email: const String.fromEnvironment('OTHER_EMAIL'),
      apiKey: const String.fromEnvironment('OTHER_API_KEY'),
      zulipFeatureLevel: eg.recentZulipFeatureLevel, // TODO get real value from server
    );
  }

  patrolTest('login', ($) async {
    addTearDown(ZulipApp.debugReset);
    await $.pumpWidget(ZulipApp());

    await $.waitUntilVisible($('Choose account'));
    check($('Choose account')).findsOne();

    if (await $.platform.mobile.isPermissionDialogVisible()) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }

    await $.tap($('Add an account'));

    await $(TextField).enterText(const String.fromEnvironment('REALM_URL'));
    await $.tap($('Continue'));

    final findUsernameInput = find.byWidgetPredicate((widget) =>
      widget is TextField
      && (widget.autofillHints ?? []).contains(AutofillHints.email));
    final findPasswordInput = find.byWidgetPredicate((widget) =>
      widget is TextField
      && (widget.autofillHints ?? []).contains(AutofillHints.password));
    await $(findUsernameInput).enterText(const String.fromEnvironment('EMAIL'));
    await $(findPasswordInput).enterText(const String.fromEnvironment('PASSWORD'));
    await $.tap($(find.widgetWithText(ElevatedButton, 'Log in')));
  });

  patrolTest('notification', ($) async {
    // Already logged in by the test above; no need to set up the account again.
    //
    // ... At least that's how the Patrol docs say it should behave,
    // and how it does often behave.  But sometimes `patrol test` instead
    // uninstalls and reinstalls the app between test cases:
    //   https://github.com/zulip/zulip-flutter/pull/2171#discussion_r2853854928
    // We could work around that by repeating the login steps here.
    // We'll introduce an easier way to do setup in an upcoming PR,
    // which will also solve this problem.

    addTearDown(ZulipApp.debugReset);
    await $.pumpWidgetAndSettle(ZulipApp());

    final navigator = await ZulipApp.navigator;
    final context = navigator.context;
    if (!context.mounted) throw Error();
    final globalStore = GlobalStoreWidget.of(context);
    final account = globalStore.accounts.single;
    final store = globalStore.getAccount(account.id)!;

    await Future<void>.delayed(Duration(milliseconds: 500));

    final token = Random().nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final content = 'hello $token';
    final otherConnection = makeOtherConnection();
    await sendMessage(otherConnection,
      destination: DmDestination(userIds: [store.userId]),
      content: content);

    await $.platform.mobile.openNotifications();
    // TODO poll? in a loop, with a timeout
    final notifs = await $.platform.mobile.getNotifications();
    check(notifs).isNotEmpty();

    await $.platform.mobile.tapOnNotificationByIndex(0);
    await $.waitUntilVisible($(RegExp(r'^DMs with')));
    check($(content)).findsOne();
  });
}
