import 'dart:math';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:legacy_checks/legacy_checks.dart';
import 'package:zulip/widgets/button.dart';
import 'package:zulip/widgets/icons.dart';

import '../flutter_checks.dart';
import '../model/binding.dart';
import 'test_app.dart';
import 'text_test.dart';


void main() {
  TestZulipBinding.ensureInitialized();

  group('ZulipWebUiKitButton', () {
    void testVerticalOuterPadding({required ZulipWebUiKitButtonSize sizeVariant}) {
      final textScaleFactorVariants = ValueVariant(Set.of(kTextScaleFactors));
      T forSizeVariant<T>(T small, T normal) =>
        switch (sizeVariant) {
          ZulipWebUiKitButtonSize.small => small,
          ZulipWebUiKitButtonSize.normal => normal,
        };

      testWidgets('vertical outer padding is preserved as text scales; $sizeVariant', (tester) async {
        addTearDown(testBinding.reset);
        tester.platformDispatcher.textScaleFactorTestValue = textScaleFactorVariants.currentValue!;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final buttonFinder = find.byType(ZulipWebUiKitButton);

        await tester.pumpWidget(TestZulipApp(
          child: UnconstrainedBox(
            child: ZulipWebUiKitButton(
              label: 'Cancel',
              onPressed: () {},
              size: sizeVariant))));
        await tester.pump();

        final element = tester.element(buttonFinder);
        final renderObject = element.renderObject as RenderBox;
        final size = renderObject.size;
        check(size).height.equals(44); // includes outer padding

        final textScaler = TextScaler.linear(textScaleFactorVariants.currentValue!)
          .clamp(maxScaleFactor: 1.5);
        final expectedButtonHeight = max(forSizeVariant(24.0, 28.0), // configured min height
          (textScaler.scale(forSizeVariant(16, 17) * forSizeVariant(1, 1.20)).roundToDouble() // text height
          + 4 + 4)); // vertical padding

        // Rounded rectangle paints with the intended height…
        final expectedRRect = RRect.fromLTRBR(
          0, 0, // zero relative to the position at this paint step
          size.width, expectedButtonHeight, Radius.circular(forSizeVariant(6, 4)));
        check(renderObject).legacyMatcher(
          // `paints` isn't a [Matcher] so we wrap it with `equals`;
          // awkward but it works
          equals(paints..drrect(outer: expectedRRect)));

        // …and that height leaves at least 4px for vertical outer padding.
        check(expectedButtonHeight).isLessOrEqual(44 - 2 - 2);
      }, variant: textScaleFactorVariants);

      testWidgets('vertical outer padding responds to taps, not just painted area', (tester) async {
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
        final size = renderObject.size;
        check(size).height.equals(44); // includes outer padding

        // Outer padding responds to taps, not just the painted part.
        final buttonCenter = tester.getCenter(buttonFinder);
        int numTaps = 0;
        for (double y = -22; y < 22; y++) {
          await tester.tapAt(buttonCenter + Offset(0, y));
          numTaps++;
        }
        check(numTapsHandled).equals(numTaps);
      }, variant: textScaleFactorVariants);
    }
    testVerticalOuterPadding(sizeVariant: ZulipWebUiKitButtonSize.small);
    testVerticalOuterPadding(sizeVariant: ZulipWebUiKitButtonSize.normal);
  });

  group('ZulipIconButton', () {
    testWidgets('occupies a 40px square', (tester) async {
      addTearDown(testBinding.reset);

      await tester.pumpWidget(TestZulipApp(
        child: UnconstrainedBox(
          child: ZulipIconButton(
            icon: ZulipIcons.follow,
            onPressed: () {}))));
      await tester.pump();

      final element = tester.element(find.byType(ZulipIconButton));
      final renderObject = element.renderObject as RenderBox;
      check(renderObject).size.equals(Size.square(40));
    });

    // TODO test that the touch feedback fills the whole square
  });
}
