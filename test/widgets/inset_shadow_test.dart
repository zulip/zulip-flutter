import 'dart:ui' as ui;
import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_checks/legacy_checks.dart';
import 'package:zulip/widgets/inset_shadow.dart';

import '../flutter_checks.dart';

void main() {
  testWidgets('constraints from the parent are not modified', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        // Position child at the top-left corner of the box at (0, 0)
        // to ease the check on [Rect] later.
        alignment: Alignment.topLeft,
        child: SizedBox(width: 20, height: 20,
          child: InsetShadowBox(top: 7, bottom: 3,
            color: Colors.red,
            child: SizedBox.shrink())))));

    // We expect that the child of [InsetShadowBox] gets the constraints
    // from [InsetShadowBox]'s parent unmodified, so that the only effect of
    // the widget is adding shadows.
    final parentRect = tester.getRect(find.byType(SizedBox).at(0));
    final childRect = tester.getRect(find.byType(SizedBox).at(1));
    check(parentRect).equals(const Rect.fromLTRB(0, 0, 20, 20));
    check(childRect).equals(parentRect);
  });

  PaintPatternPredicate paintGradient({required Rect rect}) {
    // This is inspired by
    //   https://github.com/flutter/flutter/blob/7b5462cc34af903e2f2de4be7540ff858685cdfc/packages/flutter/test/cupertino/route_test.dart#L1449-L1475
    return (Symbol methodName, List<dynamic> arguments) {
      check(methodName).equals(#drawRect);
      check(arguments[0]).isA<Rect>().equals(rect);
      // We can't further check [ui.Gradient] because it is opaque:
      //   https://github.com/flutter/engine/blob/07d01ad1199522fa5889a10c1688c4e1812b6625/lib/ui/painting.dart#L4487
      check(arguments[1]).isA<Paint>().shader.isA<ui.Gradient>();
      return true;
    };
  }

  testWidgets('render shadow correctly', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        // This would be forced to fill up the screen
        // if not wrapped in a widget like [Center].
        child: SizedBox(width: 100, height: 100,
          child: InsetShadowBox(top: 3, bottom: 7,
            color: Colors.red,
            child: SizedBox(width: 30, height: 30))))));

    final box = tester.renderObject(find.byType(InsetShadowBox));
    check(box).legacyMatcher((paints
      // The coordinate system of these [Rect]'s is relative to the parent
      // of the [Gradient] from [InsetShadowBox], not the entire [FlutterView].
      ..something(paintGradient(rect: const Rect.fromLTRB(0, 0, 100, 0+3)))
      ..something(paintGradient(rect: const Rect.fromLTRB(0, 100-7, 100, 100)))
    ) as Matcher);
  });
}
