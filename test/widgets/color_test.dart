import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
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

    const color = Color.fromRGBO(100, 200, 100, 0.5);

    test('withFadedAlpha smoke', () {
      check(color.withFadedAlpha(0.5))
        .isSameColorAs(color.withValues(alpha: 0.25));
    });

    test('withFadedAlpha opaque color', () {
      const color = Colors.black;

      check(color.withFadedAlpha(0.5))
        .isSameColorAs(color.withValues(alpha: 0.5));
    });

    test('withFadedAlpha factor > 1 fails', () {
      check(() => color.withFadedAlpha(1.1)).throws<AssertionError>();
    });

    test('withFadedAlpha factor < 0 fails', () {
      check(() => color.withFadedAlpha(-0.1)).throws<AssertionError>();
    });
  });
}
