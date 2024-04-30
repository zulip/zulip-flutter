import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/text.dart';

import '../flutter_checks.dart';

// From trying the options on an iPhone 13 Pro running iOS 16.6.1:
const kTextScaleFactors = <double>[
  0.8235, // smallest
  1,
  1.3529, // largest without using the "Larger Accessibility Sizes" setting
  3.1176, // largest
];

void main() {
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

    matchesFontFamilies(Subject<TextStyle> it) => it
      ..fontFamily.equals(kDefaultFontFamily)
      ..fontFamilyFallback.isNotNull().deepEquals(defaultFontFamilyFallback);

    matchesWeight(FontWeight weight) => (Subject<TextStyle> it) => it
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

    testWidgets('zero letter spacing', (tester) async {
      check(await getZulipTypography(tester, platformRequestsBold: false))
        ..englishLike.bodyMedium.isNotNull().letterSpacing.equals(0)
        ..dense.bodyMedium.isNotNull().letterSpacing.equals(0)
        ..tall.bodyMedium.isNotNull().letterSpacing.equals(0);
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
    Future<void> testWeights(
      String description, {
      required TextStyle Function(BuildContext context) styleBuilder,
      bool platformRequestsBold = false,
      required List<FontVariation> expectedFontVariations,
      required FontWeight expectedFontWeight,
    }) async {
      testWidgets(description, (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(boldText: platformRequestsBold),
              child: Builder(builder: (context) => Text('', style: styleBuilder(context))))));

        final TextStyle? style = tester.widget<Text>(find.byType(Text)).style;
        check(style)
          .isNotNull()
          ..inherit.isTrue()
          ..fontVariations.isNotNull().deepEquals(expectedFontVariations)
          ..fontWeight.isNotNull().equals(expectedFontWeight);
      });
    }

    testWeights('no context passed; default wght values',
      styleBuilder: (context) => weightVariableTextStyle(null),
      expectedFontVariations: const [FontVariation('wght', 400)],
      expectedFontWeight: FontWeight.normal);
    testWeights('no context passed; specific wght',
      styleBuilder: (context) => weightVariableTextStyle(null, wght: 225, wghtIfPlatformRequestsBold: 425),
      expectedFontVariations: const [FontVariation('wght', 225)],
      expectedFontWeight: FontWeight.w200);

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
    check(bolderWght(1)).equals(301);
    check(bolderWght(400)).equals(700);
    check(bolderWght(600)).equals(900);
    check(bolderWght(900)).equals(1000);
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

  group('proportionalLetterSpacing', () {
    Future<void> testLetterSpacing(
      String description, {
      required double Function(BuildContext context) getValue,
      double? ambientTextScaleFactor,
      required double expected,
    }) async {
      testWidgets(description, (WidgetTester tester) async {
        if (ambientTextScaleFactor != null) {
          tester.platformDispatcher.textScaleFactorTestValue = ambientTextScaleFactor;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        }
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(builder: (context) => Text('',
              style: TextStyle(letterSpacing: getValue(context))))));

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
}
