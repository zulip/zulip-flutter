import 'dart:ui';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/settings.dart';
import 'package:zulip/widgets/channel_colors.dart';
import 'package:zulip/widgets/text.dart';
import 'package:zulip/widgets/theme.dart';

import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/store_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('button text size and letter spacing', () {
    const buttonText = 'Zulip';

    Future<void> doCheck(
      String description, {
      required Widget button,
      double? ambientTextScaleFactor,
    }) async {
      testWidgets(description, (tester) async {
        addTearDown(testBinding.reset);
        if (ambientTextScaleFactor != null) {
          tester.platformDispatcher.textScaleFactorTestValue = ambientTextScaleFactor;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        }
        await tester.pumpWidget(TestZulipApp(
          child: button));
        await tester.pump();
        final context = tester.element(find.text(buttonText));
        final expectedFontSize = Theme.of(context).textTheme.labelLarge!.fontSize!;
        final expectedLetterSpacing = proportionalLetterSpacing(context,
          0.01, baseFontSize: expectedFontSize);
        check((context.renderObject as RenderParagraph).text.style!)
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
      button: Semantics(
        role: SemanticsRole.menu,
        child: MenuItemButton(onPressed: () {}, child: const Text(buttonText))));

    doCheck('SubmenuButton',
      button: Semantics(
        role: SemanticsRole.menu,
        child: const SubmenuButton(menuChildren: [], child: Text(buttonText))));

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
        final a = DesignVariables.light;
        final b = DesignVariables.light;
        check(() => a.lerp(b, 0.5)).returnsNormally();
      });

      testWidgets('light -> dark', (tester) async {
        final a = DesignVariables.light;
        final b = DesignVariables.dark;
        check(() => a.lerp(b, 0.5)).returnsNormally();
      });

      testWidgets('dark -> light', (tester) async {
        final a = DesignVariables.dark;
        final b = DesignVariables.light;
        check(() => a.lerp(b, 0.5)).returnsNormally();
      });

      testWidgets('dark -> dark', (tester) async {
        final a = DesignVariables.dark;
        final b = DesignVariables.dark;
        check(() => a.lerp(b, 0.5)).returnsNormally();
      });
    });
  });

  testWidgets('when globalSettings.themeSetting is null, follow system setting', (tester) async {
    addTearDown(testBinding.reset);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const TestZulipApp(child: Placeholder()));
    await tester.pump();
    check(testBinding.globalStore).settings.themeSetting.isNull();

    final element = tester.element(find.byType(Placeholder));
    check(zulipThemeData(element)).brightness.equals(Brightness.light);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();
    check(zulipThemeData(element)).brightness.equals(Brightness.dark);
  });

  testWidgets('when globalSettings.themeSetting is non-null, override system setting', (tester) async {
    addTearDown(testBinding.reset);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const TestZulipApp(child: Placeholder()));
    await tester.pump();
    check(testBinding.globalStore).settings.themeSetting.isNull();

    final element = tester.element(find.byType(Placeholder));
    check(zulipThemeData(element)).brightness.equals(Brightness.light);

    await testBinding.globalStore.settings.setThemeSetting(ThemeSetting.dark);
    check(zulipThemeData(element)).brightness.equals(Brightness.dark);

    await testBinding.globalStore.settings.setThemeSetting(null);
    check(zulipThemeData(element)).brightness.equals(Brightness.light);
  });

  group('colorSwatchFor', () {
    const baseColor = 0xff76ce90;

    testWidgets('light–dark animation', (tester) async {
      addTearDown(testBinding.reset);

      final subscription = eg.subscription(eg.stream(), color: baseColor);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(const TestZulipApp());
      await tester.pump();

      final element = tester.element(find.byType(Placeholder));
      // Compares all the swatch's members; see [ColorSwatch]'s `operator ==`.
      check(colorSwatchFor(element, subscription))
        .isSameColorSwatchAs(ChannelColorSwatch.light(baseColor));

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pump();

      await tester.pump(kThemeAnimationDuration * 0.4);
      check(colorSwatchFor(element, subscription))
        .isSameColorSwatchAs(ChannelColorSwatch.lerp(
          ChannelColorSwatch.light(baseColor),
          ChannelColorSwatch.dark(baseColor),
          0.4)!);

      await tester.pump(kThemeAnimationDuration * 0.6);
      check(colorSwatchFor(element, subscription))
        .isSameColorSwatchAs(ChannelColorSwatch.dark(baseColor));
    });

    testWidgets('fallback to default base color when no subscription', (tester) async {
      await tester.pumpWidget(const TestZulipApp());
      await tester.pump();
      final element = tester.element(find.byType(Placeholder));
      check(colorSwatchFor(element, null)).isSameColorSwatchAs(
        ChannelColorSwatch.light(kDefaultChannelColorSwatchBaseColor));
    });
  });
}
