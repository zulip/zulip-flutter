import 'dart:math';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:legacy_checks/legacy_checks.dart';
import 'package:zulip/widgets/button.dart';

import '../flutter_checks.dart';
import '../model/binding.dart';
import 'test_app.dart';
import 'text_test.dart';


void main() {
  TestZulipBinding.ensureInitialized();

  group('ZulipWebUiKitButton', () {
    final textScaleFactorVariants = ValueVariant(Set.of(kTextScaleFactors));
    testWidgets('button and touch-target heights', (tester) async {
      addTearDown(testBinding.reset);
      tester.platformDispatcher.textScaleFactorTestValue = textScaleFactorVariants.currentValue!;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final buttonFinder = find.byType(ZulipWebUiKitButton);

      int numTapsHandled = 0;
      await tester.pumpWidget(TestZulipApp(
        child: UnconstrainedBox(
          child: ZulipWebUiKitButton(
            label: 'Cancel',
            onPressed: () => numTapsHandled++))));
      await tester.pump();

      final element = tester.element(buttonFinder);
      final renderObject = element.renderObject as RenderBox;
      final width = renderObject.size.width;
      final buttonTopLeft = tester.getTopLeft(buttonFinder);
      final buttonCenter = tester.getCenter(buttonFinder);
      check(element).size.isNotNull().height.equals(44); // includes outer padding

      // Outer padding responds to taps, not just the painted part.
      int numTaps = 0;
      for (double y = 0; y < 44; y++) {
        await tester.tapAt(Offset(buttonCenter.dx, y + buttonTopLeft.dy));
        numTaps++;
      }
      check(numTapsHandled).equals(numTaps);

      final textScaler = TextScaler.linear(textScaleFactorVariants.currentValue!)
        .clamp(maxScaleFactor: 1.5);
      final expectedButtonHeight = max(28.0, // configured min height
        (textScaler.scale(17) * 1.20).roundToDouble() // text height
        + 4 + 4); // vertical padding

      // Rounded rectangle paints with the intended height…
      final expectedRRect = RRect.fromLTRBR(
        0, 0, // zero relative to the position at this paint step
        width, expectedButtonHeight, Radius.circular(4));
      check(renderObject).legacyMatcher(
        // `paints` isn't a [Matcher] so we wrap it with `equals`;
        // awkward but it works
        equals(paints..drrect(outer: expectedRRect)));

      // …and that height leaves at least 4px for outer vertical padding.
      check(expectedButtonHeight).isLessOrEqual(44 - 2 - 2);
    }, variant: textScaleFactorVariants);
  });
}
