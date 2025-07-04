import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/katex.dart';

void main() {
  group('parseCssHexColor', () {
    const testCases = [
      ('#c0c0c0ff', KatexSpanColor(192, 192, 192, 255)),
      ('#f00ba4',   KatexSpanColor(240, 11, 164, 255)),
      ('#cafe',     KatexSpanColor(204, 170, 255, 238)),

      ('#ffffffff', KatexSpanColor(255, 255, 255, 255)),
      ('#ffffff',   KatexSpanColor(255, 255, 255, 255)),
      ('#ffff',     KatexSpanColor(255, 255, 255, 255)),
      ('#fff',      KatexSpanColor(255, 255, 255, 255)),
      ('#00ffffff', KatexSpanColor(0, 255, 255, 255)),
      ('#00ffff',   KatexSpanColor(0, 255, 255, 255)),
      ('#0fff',     KatexSpanColor(0, 255, 255, 255)),
      ('#0ff',      KatexSpanColor(0, 255, 255, 255)),
      ('#ff00ffff', KatexSpanColor(255, 0, 255, 255)),
      ('#ff00ff',   KatexSpanColor(255, 0, 255, 255)),
      ('#f0ff',     KatexSpanColor(255, 0, 255, 255)),
      ('#f0f',      KatexSpanColor(255, 0, 255, 255)),
      ('#ffff00ff', KatexSpanColor(255, 255, 0, 255)),
      ('#ffff00',   KatexSpanColor(255, 255, 0, 255)),
      ('#ff0f',     KatexSpanColor(255, 255, 0, 255)),
      ('#ff0',      KatexSpanColor(255, 255, 0, 255)),
      ('#ffffff00', KatexSpanColor(255, 255, 255, 0)),
      ('#fff0',     KatexSpanColor(255, 255, 255, 0)),

      ('#FF00FFFF', KatexSpanColor(255, 0, 255, 255)),
      ('#FF00FF',   KatexSpanColor(255, 0, 255, 255)),

      ('#ff00FFff', KatexSpanColor(255, 0, 255, 255)),
      ('#ff00FF',   KatexSpanColor(255, 0, 255, 255)),

      ('#F',        null),
      ('#FF',       null),
      ('#FFFFF',    null),
      ('#FFFFFFF',  null),
      ('FFF',       null),
    ];

    for (final testCase in testCases) {
      test(testCase.$1, () {
        check(parseCssHexColor(testCase.$1)).equals(testCase.$2);
      });
    }
  });
}
