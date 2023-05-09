import 'package:flutter/material.dart';

import 'log.dart';
import 'widgets/app.dart';

void main() {
  assert(() {
    debugLogEnabled = true;
    return true;
  }());
  runApp(const ZulipApp());
}
