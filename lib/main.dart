import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:toastification/toastification.dart';

import 'licenses.dart';
import 'log.dart';
import 'model/binding.dart';
import 'notifications/receive.dart';
import 'widgets/app.dart';
import 'widgets/share.dart';

void main() {
  assert(() {
    debugLogEnabled = true;
    return true;
  }());
  LicenseRegistry.addLicense(additionalLicenses);
  WidgetsFlutterBinding.ensureInitialized();
  LiveZulipBinding.ensureInitialized();
  NotificationService.instance.start();
  ShareService.start();
  runApp(ToastificationWrapper(child: const ZulipApp()));
}
