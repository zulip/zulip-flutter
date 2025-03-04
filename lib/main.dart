import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'licenses.dart';
import 'log.dart';
import 'model/binding.dart';
import 'notifications/open.dart';
import 'notifications/receive.dart';
import 'widgets/app.dart';

Future<void> main() async {
  assert(() {
    debugLogEnabled = true;
    return true;
  }());
  LicenseRegistry.addLicense(additionalLicenses);
  WidgetsFlutterBinding.ensureInitialized();
  LiveZulipBinding.ensureInitialized();
  await NotificationOpenManager.instance.init();
  unawaited(NotificationService.instance.start());
  runApp(const ZulipApp());
}
