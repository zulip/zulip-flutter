import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/text.dart';

import '../flutter_checks.dart';
import '../model/binding.dart';
import 'test_app.dart';

// From trying the options on an iPhone 13 Pro running iOS 16.6.1:
const kTextScaleFactors = <double>[
  0.8235, // smallest
  1,
  1.3529, // largest without using the "Larger Accessibility Sizes" setting
  3.1176, // largest
];

void main() {
  TestZulipBinding.ensureInitialized();

  group('zulipTypography', () {
    Future<Typography> getZulipTypography(WidgetTester tester, {
      required bool platformRequestsBold,
    }) async {
      late final Typography result;
      await tester.pumpWidget(
        MediaQuery(data: MediaQueryData(boldText: platformRequestsBold),
          child: Builder(builder: (context) {
            result = zulipTypography(context);
            return const SizedBox.shrink();
          })));
      return result;
    }

    void matchesFontFamilies(Subject<TextStyle> it) => it
      ..fontFamily.equals(kDefaultFontFamily)
      ..fontFamilyFallback.isNotNull().deepEquals(defaultFontFamilyFallback);

    Condition<TextStyle> matchesWeight(FontWeight weight) => (Subject<TextStyle> it) => it
      ..fontWeight.equals(weight)
      ..fontVariations.isNotNull().contains(
          FontVariation('wght', wghtFromFontWeight(weight)));

    for (final platformRequestsBold in [false, true]) {
      final description = platformRequestsBold
        ? 'platform requests bold'
        : 'platform does not request bold';
      testWidgets(description, (tester) async {
        check(await getZulipTypography(tester, platformRequestsBold: platformRequestsBold))
          ..black.bodyMedium.isNotNull().which(matchesFontFamilies)
          ..white.bodyMedium.isNotNull().which(matchesFontFamilies)
          ..englishLike.bodyMedium.isNotNull().which(
              matchesWeight(platformRequestsBold ? FontWeight.w700 : FontWeight.w400))
          ..dense.bodyMedium.isNotNull().which(
              matchesWeight(platformRequestsBold ? FontWeight.w700 : FontWeight.w400))
          ..tall.bodyMedium.isNotNull().which(
              matchesWeight(platformRequestsBold ? FontWeight.w700 : FontWeight.w400));
      });
    }

    testWidgets('letter spacing', (tester) async {
      check(await getZulipTypography(tester, platformRequestsBold: false))
        ..englishLike.bodyMedium.isNotNull().letterSpacing.equals(0)
        ..englishLike.labelLarge.isNotNull().letterSpacing.equals(0.14)
        ..dense.bodyMedium.isNotNull().letterSpacing.equals(0)
        ..dense.labelLarge.isNotNull().letterSpacing.equals(0.14)
        ..tall.bodyMedium.isNotNull().letterSpacing.equals(0)
        ..tall.labelLarge.isNotNull().letterSpacing.equals(0.14);
    });

    test('Typography has the assumed fields', () {
      check(Typography().toDiagnosticsNode().getProperties().map((n) => n.name).toList())
        .unorderedEquals(['black', 'white', 'englishLike', 'dense', 'tall']);
    });
  });

  test('_convertTextTheme: TextTheme has the assumed fields', () {
    check(const TextTheme().toDiagnosticsNode().getProperties().map((n) => n.name).toList())
      .unorderedEquals([
        'displayLarge',  'displayMedium',  'displaySmall',
        'headlineLarge', 'headlineMedium', 'headlineSmall',
        'titleLarge',    'titleMedium',    'titleSmall',
        'bodyLarge',     'bodyMedium',     'bodySmall',
        'labelLarge',    'labelMedium',    'labelSmall',
      ]);
  });

  group('weightVariableTextStyle', () {
    void testWeights(
      String description, {
      required TextStyle Function(BuildContext context) styleBuilder,
      bool platformRequestsBold = false,
      required List<FontVariation> expectedFontVariations,
      required FontWeight expectedFontWeight,
    }) {
      testWidgets(description, (tester) async {
        addTearDown(testBinding.reset);
        tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(boldText: platformRequestsBold);
        addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
        await tester.pumpWidget(TestZulipApp(
          child: Builder(builder: (context) =>
            Text('', style: styleBuilder(context)))));
        await tester.pump();

        final TextStyle? style = tester.widget<Text>(find.byType(Text)).style;
        check(style)
          .isNotNull()
          ..inherit.isTrue()
          ..fontVariations.isNotNull().deepEquals(expectedFontVariations)
          ..fontWeight.isNotNull().equals(expectedFontWeight);
      });
    }

    testWeights('default values; platform does not request bold',
      styleBuilder: (context) => weightVariableTextStyle(context),
      platformRequestsBold: false,
      expectedFontVariations: const [FontVariation('wght', 400)],
      expectedFontWeight: FontWeight.normal);
    testWeights('default values; platform requests bold',
      styleBuilder: (context) => weightVariableTextStyle(context),
      platformRequestsBold: true,
      expectedFontVariations: const [FontVariation('wght', 700)],
      expectedFontWeight: FontWeight.bold);

    testWeights('specific values; platform does not request bold',
      styleBuilder: (context) => weightVariableTextStyle(context, wght: 475, wghtIfPlatformRequestsBold: 675),
      platformRequestsBold: false,
      expectedFontVariations: const [FontVariation('wght', 475)],
      expectedFontWeight: FontWeight.w500);
    testWeights('specific values; platform requests bold',
      styleBuilder: (context) => weightVariableTextStyle(context, wght: 475, wghtIfPlatformRequestsBold: 675),
      platformRequestsBold: true,
      expectedFontVariations: const [FontVariation('wght', 675)],
      expectedFontWeight: FontWeight.w700);

    testWeights('specific `wght`, default `wghtIfPlatformRequestsBold`; platform does not request bold',
      styleBuilder: (context) => weightVariableTextStyle(context, wght: 475),
      platformRequestsBold: false,
      expectedFontVariations: const [FontVariation('wght', 475)],
      expectedFontWeight: FontWeight.w500);
    testWeights('specific `wght`, default `wghtIfPlatformRequestsBold`; platform requests bold',
      styleBuilder: (context) => weightVariableTextStyle(context, wght: 475),
      platformRequestsBold: true,
      expectedFontVariations: const [FontVariation('wght', 775)],
      expectedFontWeight: FontWeight.w800);

    testWeights('default `wght`, specific `wghtIfPlatformRequestsBold`; platform does not request bold',
      styleBuilder: (context) => weightVariableTextStyle(context, wghtIfPlatformRequestsBold: 775),
      platformRequestsBold: false,
      expectedFontVariations: const [FontVariation('wght', 400)],
      expectedFontWeight: FontWeight.normal);
    testWeights('default `wght`, specific `wghtIfPlatformRequestsBold`; platform requests bold',
      styleBuilder: (context) => weightVariableTextStyle(context, wghtIfPlatformRequestsBold: 775),
      platformRequestsBold: true,
      expectedFontVariations: const [FontVariation('wght', 775)],
      expectedFontWeight: FontWeight.w800);
  });

  test('bolderWght', () {
    check(() => bolderWght(kWghtMin - 1)).throws<void>();
    check(() => bolderWght(kWghtMax + 1)).throws<void>();

    check(bolderWght(1)).equals(301);
    check(bolderWght(400)).equals(700);
    check(bolderWght(600)).equals(900);
    check(bolderWght(900)).equals(1000);

    check(bolderWght(1,    by: -200)).equals(1);
    check(bolderWght(201,  by: -200)).equals(1);
    check(bolderWght(1000, by: -200)).equals(800);

    check(bolderWght(1,   by: 200)).equals(201);
    check(bolderWght(400, by: 200)).equals(600);
    check(bolderWght(600, by: 200)).equals(800);
    check(bolderWght(900, by: 200)).equals(1000);
  });

  group('bolderWghtTextStyle', () {
    void testBolderWghtTextStyle(
      String description, {
      required TextStyle Function(BuildContext context) makeStyle,
      bool platformRequestsBold = false,
      required double expectedWght,
      required FontWeight expectedFontWeight,
    }) {
      testWidgets(description, (tester) async {
        addTearDown(testBinding.reset);
        tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(boldText: platformRequestsBold);

        await tester.pumpWidget(TestZulipApp(
          child: Builder(builder: (context) =>
            Text('', style: makeStyle(context)))));
        await tester.pump();

        final TextStyle? style = tester.widget<Text>(find.byType(Text)).style;

        check(style).isNotNull().fontWeight.isNotNull().equals(expectedFontWeight);

        final fontVariations = style!.fontVariations;
        check(fontVariations).isNotNull();
        final wghtVariation = fontVariations!.singleWhereOrNull((v) => v.axis == 'wght');
        check(wghtVariation).isNotNull().value.equals(expectedWght);

        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });
    }

    testBolderWghtTextStyle('default + default',
      makeStyle: (context) => bolderWghtTextStyle(weightVariableTextStyle(context)),
      expectedWght: 700,
      expectedFontWeight: FontWeight.w700);

    testBolderWghtTextStyle('default + default (platform requests bold)',
      platformRequestsBold: true,
      makeStyle: (context) => bolderWghtTextStyle(weightVariableTextStyle(context)),
      expectedWght: 1000,
      expectedFontWeight: FontWeight.w900);

    testBolderWghtTextStyle('320 + 200',
      makeStyle: (context) => bolderWghtTextStyle(
        weightVariableTextStyle(context, wght: 320),
        by: 200,
      ),
      expectedWght: 520,
      expectedFontWeight: FontWeight.w500);

    testBolderWghtTextStyle('320 + 200 (platform requests bold)',
      platformRequestsBold: true,
      makeStyle: (context) => bolderWghtTextStyle(
        weightVariableTextStyle(context, wght: 320),
        by: 200,
      ),
      expectedWght: 820,
      expectedFontWeight: FontWeight.w800);

    testBolderWghtTextStyle('320 + 200 (platform requests bold; custom response to setting)',
      platformRequestsBold: true,
      makeStyle: (context) => bolderWghtTextStyle(
        weightVariableTextStyle(context, wght: 320, wghtIfPlatformRequestsBold: 410),
        by: 200,
      ),
      expectedWght: 610,
      expectedFontWeight: FontWeight.w600);

    testBolderWghtTextStyle('900 + 200',
      makeStyle: (context) => bolderWghtTextStyle(
        weightVariableTextStyle(context, wght: 900),
        by: 200,
      ),
      expectedWght: 1000,
      expectedFontWeight: FontWeight.w900);
  });

  test('clampVariableFontWeight: FontWeight has the assumed list of values', () {
    // Implementation assumes specific FontWeight values; we should
    // adapt if these change in a new Flutter version.
    check(FontWeight.values).deepEquals([
      FontWeight.w100, FontWeight.w200, FontWeight.w300,
      FontWeight.w400, FontWeight.w500, FontWeight.w600,
      FontWeight.w700, FontWeight.w800, FontWeight.w900,
    ]);
  });

  test('clampVariableFontWeight', () {
    check(clampVariableFontWeight(1))    .equals(FontWeight.w100);
    check(clampVariableFontWeight(99))   .equals(FontWeight.w100);
    check(clampVariableFontWeight(100))  .equals(FontWeight.w100);
    check(clampVariableFontWeight(101))  .equals(FontWeight.w100);

    check(clampVariableFontWeight(199))  .equals(FontWeight.w200);
    check(clampVariableFontWeight(200))  .equals(FontWeight.w200);
    check(clampVariableFontWeight(201))  .equals(FontWeight.w200);

    check(clampVariableFontWeight(250))  .equals(FontWeight.w300);
    check(clampVariableFontWeight(299))  .equals(FontWeight.w300);
    check(clampVariableFontWeight(300))  .equals(FontWeight.w300);
    check(clampVariableFontWeight(301))  .equals(FontWeight.w300);

    check(clampVariableFontWeight(399))  .equals(FontWeight.w400);
    check(clampVariableFontWeight(400))  .equals(FontWeight.w400);
    check(clampVariableFontWeight(401))  .equals(FontWeight.w400);

    check(clampVariableFontWeight(499))  .equals(FontWeight.w500);
    check(clampVariableFontWeight(500))  .equals(FontWeight.w500);
    check(clampVariableFontWeight(501))  .equals(FontWeight.w500);

    check(clampVariableFontWeight(599))  .equals(FontWeight.w600);
    check(clampVariableFontWeight(600))  .equals(FontWeight.w600);
    check(clampVariableFontWeight(601))  .equals(FontWeight.w600);

    check(clampVariableFontWeight(699))  .equals(FontWeight.w700);
    check(clampVariableFontWeight(700))  .equals(FontWeight.w700);
    check(clampVariableFontWeight(701))  .equals(FontWeight.w700);

    check(clampVariableFontWeight(799))  .equals(FontWeight.w800);
    check(clampVariableFontWeight(800))  .equals(FontWeight.w800);
    check(clampVariableFontWeight(801))  .equals(FontWeight.w800);

    check(clampVariableFontWeight(899))  .equals(FontWeight.w900);
    check(clampVariableFontWeight(900))  .equals(FontWeight.w900);
    check(clampVariableFontWeight(901))  .equals(FontWeight.w900);
    check(clampVariableFontWeight(999))  .equals(FontWeight.w900);
    check(clampVariableFontWeight(1000)) .equals(FontWeight.w900);
  });

  test('wghtFromTextStyle', () {
    void doCheck(TextStyle style, double? expected) {
      check(wghtFromTextStyle(style)).equals(expected);
    }

    doCheck(const TextStyle(), null);
    doCheck(const TextStyle(fontVariations: []), null);
    doCheck(const TextStyle(fontVariations: [FontVariation.slant(45)]), null);

    doCheck(const TextStyle(fontVariations: [FontVariation('wght', 100)]), 100);
    doCheck(const TextStyle(
      fontVariations: [FontVariation('wght', 160)],
      fontWeight: FontWeight.w200,
    ), 160);
    doCheck(const TextStyle(
      fontVariations: [FontVariation('wght', 100), FontVariation('wght', 200)]
    ), 100);
    doCheck(const TextStyle(
      fontVariations: [FontVariation('wght', 100), FontVariation('wght', 100)],
      fontWeight: FontWeight.w900,
    ), 100);

    doCheck(const TextStyle(
      fontVariations: [],
      fontWeight: FontWeight.w900,
    ), 900);
    doCheck(const TextStyle(
      fontVariations: [FontVariation.slant(45)],
      fontWeight: FontWeight.w900,
    ), 900);
  });

  group('proportionalLetterSpacing', () {
    void testLetterSpacing(
      String description, {
      required double Function(BuildContext context) getValue,
      double? ambientTextScaleFactor,
      required double expected,
    }) {
      testWidgets(description, (tester) async {
        addTearDown(testBinding.reset);
        if (ambientTextScaleFactor != null) {
          tester.platformDispatcher.textScaleFactorTestValue = ambientTextScaleFactor;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        }
        await tester.pumpWidget(TestZulipApp(
          child: Builder(builder: (context) => Text('',
            style: TextStyle(letterSpacing: getValue(context))))));
        await tester.pump();

        final TextStyle? style = tester.widget<Text>(find.byType(Text)).style;
        final actualLetterSpacing = style!.letterSpacing!;
        check((actualLetterSpacing - expected).abs()).isLessThan(0.0001);
      });
    }

    testLetterSpacing('smoke 1',
      getValue: (context) => proportionalLetterSpacing(context, 0.01, baseFontSize: 14),
      expected: 0.14);

    testLetterSpacing('smoke 2',
      getValue: (context) => proportionalLetterSpacing(context, 0.02, baseFontSize: 16),
      expected: 0.32);

    for (final textScaleFactor in kTextScaleFactors) {
      testLetterSpacing('ambient text scale factor $textScaleFactor, no override',
        ambientTextScaleFactor: textScaleFactor,
        getValue: (context) => proportionalLetterSpacing(context, 0.01, baseFontSize: 14),
        expected: 0.14 * textScaleFactor);

      testLetterSpacing('ambient text scale factor $textScaleFactor, override with no scaling',
        ambientTextScaleFactor: textScaleFactor,
        getValue: (context) => proportionalLetterSpacing(context,
          0.01, baseFontSize: 14, textScaler: TextScaler.noScaling),
        expected: 0.14);

      final clampingTextScaler = TextScaler.linear(textScaleFactor)
        .clamp(minScaleFactor: 0.9, maxScaleFactor: 1.1);
      testLetterSpacing('ambient text scale factor $textScaleFactor, override with clamping',
        ambientTextScaleFactor: textScaleFactor,
        getValue: (context) => proportionalLetterSpacing(context,
          0.01, baseFontSize: 14, textScaler: clampingTextScaler),
        expected: clampingTextScaler.scale(14) * 0.01);
    }
  });

  group('localizedTextBaseline', () {
    void testLocalizedTextBaseline(Locale locale, TextBaseline expected) {
      testWidgets('gives $expected for $locale', (tester) async {
        addTearDown(testBinding.reset);
        tester.platformDispatcher.localeTestValue = locale;
        tester.platformDispatcher.localesTestValue = [locale];
        addTearDown(tester.platformDispatcher.clearLocaleTestValue);
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        await tester.pumpWidget(TestZulipApp(
          child: Builder(builder: (context) =>
            Text('123', style: TextStyle(textBaseline: localizedTextBaseline(context))))));
        await tester.pump();

        final TextStyle? style = tester.widget<Text>(find.text('123')).style;
        final actualTextBaseline = style!.textBaseline!;
        check(actualTextBaseline).equals(expected);
      });
    }

    testLocalizedTextBaseline(const Locale('en'), TextBaseline.alphabetic);
    testLocalizedTextBaseline(const Locale('ja'), TextBaseline.ideographic);

    // "und" is a special language code meaning undefined; see [Locale]
    testLocalizedTextBaseline(const Locale('und'), TextBaseline.alphabetic);
  });

  group('TextWithLink', () {
    testWidgets('responds correctly to taps', (tester) async {
      int calls = 0;
      addTearDown(testBinding.reset);
      await tester.pumpWidget(TestZulipApp(
        child: Center(
          child: TextWithLink(onTap: () => calls++,
            markup: 'asd <z-link>fgh</z-link> jkl'))));
      await tester.pump();

      final findText = find.text('asd fgh jkl', findRichText: true);
      final center = tester.getCenter(findText);
      final width = tester.getSize(findText).width;

      // No response to tapping the words not in the link.
      await tester.tapAt(center + Offset(-0.3 * width, 0));
      check(calls).equals(0);
      await tester.tapAt(center + Offset(0.3 * width, 0));
      check(calls).equals(0);

      // Tapping the word in the link calls the callback.
      await tester.tapAt(center);
      check(calls).equals(1);
      await tester.tapAt(center);
      check(calls).equals(2);
    });

    testWidgets('rejects extra tags', (tester) async {
      final markup = '<z-link>spurious</z-link><z-link>markup</z-link>';
      final plainText = 'spuriousmarkup';

      int calls = 0;
      addTearDown(testBinding.reset);
      await tester.pumpWidget(TestZulipApp(
        child: Center(
          child: TextWithLink(onTap: () => calls++,
            markup: markup))));
      await tester.pump();

      // The widget appears with the markup string as plain text.
      check(find.text(plainText, findRichText: true)).findsNothing();
      check(find.text(markup)).findsOne();

      // Nothing happens on tapping it.
      await tester.tap(find.text(markup));
      check(calls).equals(0);
    });
  });
}
