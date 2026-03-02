import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:zulip/api/route/account.dart';
import 'package:zulip/widgets/app.dart';

import '../test/example_data.dart' as eg;
import '../test/model/binding.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  patrolTest('email/password', ($) async {
    // This isn't especially useful as a test: it duplicates flows we have in
    // our widget tests, and doesn't do anything where the real device platform
    // would be expected to differ from the Flutter test environment.
    //
    // So the value of this is just as an initial demo of using Patrol.

    addTearDown(testBinding.reset);
    await $.pumpWidgetAndSettle(ZulipApp());

    // Hang out for a bit, to let the developer see this step.
    await Future<void>.delayed(Duration(seconds: 1));

    check($('Choose account')).findsOne();
    await $.tap($('Add an account'));

    // Similar to test/widgets/login_test.dart AddAccountPage happy path.
    final serverSettings = eg.serverSettings();
    testBinding.globalStore.useCachedApiConnections = true;
    final connection1 = testBinding.globalStore.apiConnection(
      realmUrl: serverSettings.realmUrl,
      zulipFeatureLevel: null);
    connection1.prepare(json: serverSettings.toJson());
    await $(TextField).enterText(serverSettings.realmUrl.toString());
    await $.tap($('Continue'));

    // Similar to test/widgets/login_test.dart username/password login.
    final findUsernameInput = find.byWidgetPredicate((widget) =>
      widget is TextField
      && (widget.autofillHints ?? []).contains(AutofillHints.email));
    final findPasswordInput = find.byWidgetPredicate((widget) =>
      widget is TextField
      && (widget.autofillHints ?? []).contains(AutofillHints.password));
    final account = eg.selfAccount;
    assert(account.realmUrl == serverSettings.realmUrl);
    await $.enterText(findUsernameInput, account.email);
    await $.enterText(findPasswordInput, 'p455w0rd');

    final connection2 = testBinding.globalStore.apiConnection(
      realmUrl: serverSettings.realmUrl,
      zulipFeatureLevel: serverSettings.zulipFeatureLevel);
    connection2.prepare(json: FetchApiKeyResult(
      apiKey: account.apiKey,
      email: account.email,
      userId: account.userId,
    ).toJson());
    // The next two lines together are a lot like `$.tap($('Log in'))`,
    // except the latter would do a pump instead of a mere idle.
    // We avoid pumping until we supply the data for the next page, below.
    await $.tester.tap($('Log in').first);
    await $.tester.idle();
    check(testBinding.globalStore.accounts).single
      .equals(eg.selfAccount.copyWith(
        id: testBinding.globalStore.accounts.single.id));

    testBinding.globalStore.addInitialSnapshot(
      testBinding.globalStore.accountIds.single,
      eg.initialSnapshot());
    await $.waitUntilVisible($('Inbox'));
  });
}
