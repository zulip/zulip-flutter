import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Enable these checks.  See this property's doc, which is basically
  // an apology for the fact that (for historical reasons) it isn't
  // the default.
  WidgetController.hitTestWarningShouldBeFatal = true;

  await testMain();
}
