
import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/text.dart';

import '../flutter_checks.dart';

void main() {
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
}
