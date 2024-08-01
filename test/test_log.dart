import 'dart:async';

import 'package:checks/checks.dart';
import 'package:zulip/log.dart';

Future<Subject<List<String>>> checkLogs(FutureOr<void> Function() callback) async {
  assert(logHistory == null);
  logHistory = [];
  try {
    await callback();
    return check(logHistory).isA<List<String>>();
  } finally {
    logHistory = null;
  }
}
