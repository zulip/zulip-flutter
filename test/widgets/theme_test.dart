import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/text.dart';
import 'package:zulip/widgets/theme.dart';

import '../flutter_checks.dart';

void main() {
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
}
