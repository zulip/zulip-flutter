import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/stream_colors.dart';
import 'package:zulip/widgets/text.dart';
import 'package:zulip/widgets/theme.dart';

import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('button text size and letter spacing', () {
    const buttonText = 'Zulip';

    Future<void> doCheck(
      String description, {
      required Widget button,
      double? ambientTextScaleFactor,
    }) async {
      testWidgets(description, (WidgetTester tester) async {
        if (ambientTextScaleFactor != null) {
          tester.platformDispatcher.textScaleFactorTestValue = ambientTextScaleFactor;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        }
        late final double expectedFontSize;
        late final double expectedLetterSpacing;
        await tester.pumpWidget(
          Builder(builder: (context) => MaterialApp(
            theme: zulipThemeData(context),
            home: Builder(builder: (context) {
              expectedFontSize = Theme.of(context).textTheme.labelLarge!.fontSize!;
              expectedLetterSpacing = proportionalLetterSpacing(context,
                0.01, baseFontSize: expectedFontSize);
              return button;
            }))));

        final text = tester.renderObject<RenderParagraph>(find.text(buttonText)).text;
        check(text.style!)
          ..fontSize.equals(expectedFontSize)
          ..letterSpacing.equals(expectedLetterSpacing);
      });
    }

    doCheck('with device text size adjusted',
      ambientTextScaleFactor: 2.0,
      button: ElevatedButton(onPressed: () {}, child: const Text(buttonText)));

    doCheck('ElevatedButton',
      button: ElevatedButton(onPressed: () {}, child: const Text(buttonText)));

    doCheck('FilledButton',
      button: FilledButton(onPressed: () {}, child: const Text(buttonText)));

    // IconButton can't have text; skip

    doCheck('MenuItemButton',
      button: MenuItemButton(onPressed: () {}, child: const Text(buttonText)));

    doCheck('SubmenuButton',
      button: const SubmenuButton(menuChildren: [], child: Text(buttonText)));

    doCheck('OutlinedButton',
      button: OutlinedButton(onPressed: () {}, child: const Text(buttonText)));

    doCheck('SegmentedButton',
      button: SegmentedButton(selected: const {1},
        segments: const [ButtonSegment(value: 1, label: Text(buttonText))]));

    doCheck('TextButton',
      button: TextButton(onPressed: () {}, child: const Text(buttonText)));
  });

  group('DesignVariables', () {
    group('lerp', () {
      testWidgets('light -> light', (tester) async {
        final a = DesignVariables.light();
        final b = DesignVariables.light();
        check(() => a.lerp(b, 0.5)).returnsNormally();
      });

      testWidgets('light -> dark', (tester) async {
        final a = DesignVariables.light();
        final b = DesignVariables.dark();
        check(() => a.lerp(b, 0.5)).returnsNormally();
      });

      testWidgets('dark -> light', (tester) async {
        final a = DesignVariables.dark();
        final b = DesignVariables.light();
        check(() => a.lerp(b, 0.5)).returnsNormally();
      });

      testWidgets('dark -> dark', (tester) async {
        final a = DesignVariables.dark();
        final b = DesignVariables.dark();
        check(() => a.lerp(b, 0.5)).returnsNormally();
      });
    });
  });

  group('colorSwatchFor', () {
    const baseColor = 0xff76ce90;

    testWidgets('light–dark animation', (WidgetTester tester) async {
      addTearDown(testBinding.reset);

      final subscription = eg.subscription(eg.stream(), color: baseColor);

      assert(!debugFollowPlatformBrightness); // to be removed with #95
      debugFollowPlatformBrightness = true;
      addTearDown(() { debugFollowPlatformBrightness = false; });
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(const ZulipApp());
      await tester.pump();

      final navigator = await ZulipApp.navigator;
      navigator.push(MaterialWidgetRoute(page: Builder(builder: (context) =>
        const Placeholder())));
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(Placeholder));
      // Compares all the swatch's members; see [ColorSwatch]'s `operator ==`.
      check(colorSwatchFor(element, subscription))
        .equals(StreamColorSwatch.light(baseColor));

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pump();

      await tester.pump(kThemeAnimationDuration * 0.4);
      check(colorSwatchFor(element, subscription))
        .equals(StreamColorSwatch.lerp(
          StreamColorSwatch.light(baseColor),
          StreamColorSwatch.dark(baseColor),
          0.4)!);

      await tester.pump(kThemeAnimationDuration * 0.6);
      check(colorSwatchFor(element, subscription))
        .equals(StreamColorSwatch.dark(baseColor));
    });
  });
}
