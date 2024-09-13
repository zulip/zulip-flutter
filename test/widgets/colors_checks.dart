import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_matcher;
import 'package:flutter/painting.dart';
import 'package:legacy_checks/legacy_checks.dart';

extension ColorSwatchChecks<T> on Subject<ColorSwatch<T>> {
  /// package:checks-style wrapper for [flutter_matcher.isSameColorSwatchAs].
  void isSameColorSwatchAs(ColorSwatch<T> colorSwatch) {
    legacyMatcher(flutter_matcher.isSameColorSwatchAs(colorSwatch));
  }
}
