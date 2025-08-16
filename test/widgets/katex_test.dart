import 'package:checks/checks.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/katex.dart';

import '../model/binding.dart';
import '../model/katex_test.dart';
import 'content_test.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('snapshot per-character rects', () {
    final testCases = <(KatexExample, List<(String, Offset, Size)>, {bool? skip})>[
      (KatexExample.sizing, skip: false, [
        ('1', Offset(0.00, 2.24), Size(25.59, 61.00)),
        ('2', Offset(25.59, 10.04), Size(21.33, 51.00)),
        ('3', Offset(46.91, 16.55), Size(17.77, 43.00)),
        ('4', Offset(64.68, 21.98), Size(14.80, 36.00)),
        ('5', Offset(79.48, 26.50), Size(12.34, 30.00)),
        ('6', Offset(91.82, 30.26), Size(10.28, 25.00)),
        ('7', Offset(102.10, 32.15), Size(9.25, 22.00)),
        ('8', Offset(111.35, 34.03), Size(8.23, 20.00)),
        ('9', Offset(119.58, 35.91), Size(7.20, 17.00)),
        ('0', Offset(126.77, 39.68), Size(5.14, 12.00)),
      ]),
      (KatexExample.nestedSizing, skip: false, [
        ('1', Offset(0.00, 40.24), Size(5.14, 12.00)),
        ('2', Offset(5.14, 2.80), Size(25.59, 61.00)),
      ]),
      (KatexExample.delimsizing, skip: false, [
        ('(', Offset(8.00, 20.14), Size(9.42, 25.00)),
        ('[', Offset(17.42, 20.14), Size(9.71, 25.00)),
        ('⌈', Offset(27.12, 20.14), Size(11.99, 25.00)),
        ('⌊', Offset(39.11, 20.14), Size(13.14, 25.00)),
      ]),
      (KatexExample.spacing, skip: false, [
        ('1', Offset(0.00, 2.24), Size(10.28, 25.00)),
        (':', Offset(16.00, 2.24), Size(5.72, 25.00)),
        ('2', Offset(27.43, 2.24), Size(10.28, 25.00)),
      ]),
      (KatexExample.vlistSuperscript, skip: false, [
        ('a', Offset(0.00, 5.28), Size(10.88, 25.00)),
        ('′', Offset(10.88, 1.13), Size(3.96, 17.00)),
      ]),
      (KatexExample.vlistSubscript, skip: false, [
        ('x', Offset(0.00, 5.28), Size(11.76, 25.00)),
        ('n', Offset(11.76, 13.65), Size(8.63, 17.00)),
      ]),
      (KatexExample.vlistSubAndSuperscript, skip: false, [
        ('u', Offset(0.00, 15.65), Size(8.23, 17.00)),
        ('o', Offset(0.00, 2.07), Size(6.98, 17.00)),
      ]),
      (KatexExample.vlistRaisebox, skip: false, [
        ('a', Offset(0.00, 4.16), Size(10.88, 25.00)),
        ('b', Offset(10.88, -0.66), Size(8.82, 25.00)),
        ('c', Offset(19.70, 4.16), Size(8.90, 25.00)),
      ]),
      (KatexExample.negativeMargin, skip: false, [
        ('1', Offset(0.00, 3.12), Size(10.28, 25.00)),
        ('2', Offset(6.85, 3.36), Size(10.28, 25.00)),
      ]),
      (KatexExample.katexLogo, skip: false, [
        ('K', Offset(0.0, 8.64), Size(16.0, 25.0)),
        ('A', Offset(12.50, 10.85), Size(10.79, 17.0)),
        ('T', Offset(20.21, 9.36), Size(14.85, 25.0)),
        ('E', Offset(31.63, 14.52), Size(14.0, 25.0)),
        ('X', Offset(43.06, 9.85), Size(15.42, 25.0)),
      ]),
      (KatexExample.vlistNegativeMargin, skip: false, [
        ('X', Offset(0.00, 7.04), Size(17.03, 25.00)),
        ('n', Offset(17.03, 15.90), Size(8.63, 17.00)),
      ]),
      (KatexExample.nulldelimiter, skip: false, [
        ('a', Offset(2.47, 3.36), Size(10.88, 25.00)),
        ('b', Offset(15.81, 3.36), Size(8.82, 25.00)),
      ]),
    ];

    for (final testCase in testCases) {
      testWidgets(testCase.$1.description, (tester) async {
        await _loadKatexFonts();

        await prepareContent(tester, plainContent(testCase.$1.html));

        final baseRect = tester.getRect(find.byType(KatexWidget));

        for (final characterData in testCase.$2) {
          final character = characterData.$1;
          final expectedTopLeftOffset = characterData.$2;
          final expectedSize = characterData.$3;

          final rect = tester.getRect(find.text(character));
          final topLeftOffset = rect.topLeft - baseRect.topLeft;
          final size = rect.size;

          check(topLeftOffset)
            .within(distance: 0.05, from: expectedTopLeftOffset);
          check(size)
            .within(distance: 0.05, from: expectedSize);
        }
      }, skip: testCase.skip);
    }
  });

  group('characters are rendered in specific color', () {
    final testCases = <(KatexExample, List<(String, Color)>)>[
      (KatexExample.color, [
        ('0', Color.fromARGB(255, 255, 0, 0))
      ]),
      (KatexExample.textColor, [
        ('1', Color.fromARGB(255, 255, 0, 0))
      ]),
      (KatexExample.customColorMacro, [
        ('2', Color.fromARGB(255, 223, 0, 48))
      ]),
      (KatexExample.phantom, [
        ('∗', Color.fromARGB(0, 0, 0, 0))
      ])
    ];

    for (final testCase in testCases) {
      testWidgets(testCase.$1.description, (tester) async {
        await prepareContent(tester, plainContent(testCase.$1.html));

        for (final characterData in testCase.$2) {
          final character = characterData.$1;
          final expectedColor = characterData.$2;

          final renderParagraph =
            tester.renderObject<RenderParagraph>(find.text(character));
          final color = renderParagraph.text.style?.color;
          check(color).equals(expectedColor);
        }
      });
    }
  });
}

Future<void> _loadKatexFonts() async {
  const fonts = {
    'KaTeX_AMS': ['KaTeX_AMS-Regular.ttf'],
    'KaTeX_Caligraphic': [
      'KaTeX_Caligraphic-Regular.ttf',
      'KaTeX_Caligraphic-Bold.ttf',
    ],
    'KaTeX_Fraktur': [
      'KaTeX_Fraktur-Regular.ttf',
      'KaTeX_Fraktur-Bold.ttf',
    ],
    'KaTeX_Main': [
      'KaTeX_Main-Regular.ttf',
      'KaTeX_Main-Bold.ttf',
      'KaTeX_Main-Italic.ttf',
      'KaTeX_Main-BoldItalic.ttf',
    ],
    'KaTeX_Math': [
      'KaTeX_Math-Italic.ttf',
      'KaTeX_Math-BoldItalic.ttf',
    ],
    'KaTeX_SansSerif': [
      'KaTeX_SansSerif-Regular.ttf',
      'KaTeX_SansSerif-Bold.ttf',
      'KaTeX_SansSerif-Italic.ttf',
    ],
    'KaTeX_Script': ['KaTeX_Script-Regular.ttf'],
    'KaTeX_Size1': ['KaTeX_Size1-Regular.ttf'],
    'KaTeX_Size2': ['KaTeX_Size2-Regular.ttf'],
    'KaTeX_Size3': ['KaTeX_Size3-Regular.ttf'],
    'KaTeX_Size4': ['KaTeX_Size4-Regular.ttf'],
    'KaTeX_Typewriter': ['KaTeX_Typewriter-Regular.ttf'],
  };
  for (final MapEntry(key: fontFamily, value: fontFiles) in fonts.entries) {
    final fontLoader = FontLoader(fontFamily);
    for (final fontFile in fontFiles) {
      fontLoader.addFont(rootBundle.load('assets/KaTeX/$fontFile'));
    }
    await fontLoader.load();
  }
}
