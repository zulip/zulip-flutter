import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'licenses.dart';
import 'log.dart';
import 'model/binding.dart';
import 'widgets/app.dart';

void main() {
  assert(() {
    debugLogEnabled = true;
    return true;
  }());
  LicenseRegistry.addLicense(additionalLicenses);
  LiveZulipBinding.ensureInitialized();
  runApp(const ZulipApp());
}
