import 'package:checks/checks.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:zulip/widgets/app.dart';

import '../test/model/binding.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  patrolTest('smoke', ($) async {
    addTearDown(testBinding.reset);
    await $.pumpWidgetAndSettle(ZulipApp());

    // Hang out for a bit, to let the developer see this step.
    await Future<void>.delayed(Duration(seconds: 1));

    check($('Choose account')).findsOne();
    await $.tap($('Add an account'));
  });
}
