// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:zulip/main.dart';
import 'package:zulip/widgets/app.dart';

import 'binding.dart';

void main() {
  PatrolLiveZulipBinding.ensureInitialized();
  mainInit();

  patrolTest('email/password', ($) async {
    // This isn't especially useful as a test: it duplicates flows we have in
    // our widget tests, and doesn't do anything where the real device platform
    // would be expected to differ from the Flutter test environment.
    //
    // Given the importance of the login flow, though, and the fact that it's
    // something we don't naturally manually test in the course of using the
    // app ourselves day to day, this test has some marginal value in
    // double-checking that we haven't missed something.

    await patrolLiveBinding.reset();
    await $.pumpWidget(ZulipApp());

    await $.waitUntilVisible($('Choose account'));
    check($('Choose account')).findsOne();

    if (await $.platform.mobile.isPermissionDialogVisible()) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }

    await $.tap($('Add an account'));

    await $(TextField).enterText(LiveCredentials.realmUrlStr);
    await $.tap($('Continue'));

    final findUsernameInput = find.byWidgetPredicate((widget) =>
      widget is TextField
      && (widget.autofillHints ?? []).contains(AutofillHints.email));
    final findPasswordInput = find.byWidgetPredicate((widget) =>
      widget is TextField
      && (widget.autofillHints ?? []).contains(AutofillHints.password));
    await $(findUsernameInput).enterText(LiveCredentials.email);
    await $(findPasswordInput).enterText(LiveCredentials.password);
    await $.tap($(find.widgetWithText(ElevatedButton, 'Log in')));

    await $.waitUntilVisible($('Inbox'));
  });

  // TODO test web auth
}
