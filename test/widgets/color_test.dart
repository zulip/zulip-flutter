import 'dart:ui';

import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/widgets/color.dart';

void main() {
  group('ColorExtension', () {
    test('argbInt smoke', () {
      const testCases = [
        0xffffffff, 0x00000000, 0x12345678, 0x87654321, 0xfedcba98, 0x89abcdef];

      for (final testCase in testCases) {
        check(Color(testCase).argbInt).equals(testCase);
      }
    });
  });
}
