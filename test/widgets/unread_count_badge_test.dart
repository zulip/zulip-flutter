import 'package:checks/checks.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/widgets/unread_count_badge.dart';

void main() {
  group('UnreadCountBadge', () {
    testWidgets('smoke test; no crash', (tester) async {
      await tester.pumpWidget(
        const Directionality(textDirection: TextDirection.ltr,
          child: UnreadCountBadge(count: 1, backgroundColor: null)));
      tester.widget(find.text("1"));
    });

    group('background', () {
      Future<void> prepare(WidgetTester tester, Color? backgroundColor) async {
        await tester.pumpWidget(
          Directionality(textDirection: TextDirection.ltr,
            child: UnreadCountBadge(count: 1, backgroundColor: backgroundColor)));
      }

      Color? findBackgroundColor(WidgetTester tester) {
        final widget = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
        final decoration = widget.decoration as BoxDecoration;
        return decoration.color;
      }

      testWidgets('default color', (WidgetTester tester) async {
        await prepare(tester, null);
        check(findBackgroundColor(tester)).equals(const Color(0x26666699));
      });

      testWidgets('specified color', (WidgetTester tester) async {
        await prepare(tester, Colors.pink);
        check(findBackgroundColor(tester)).equals(Colors.pink);
      });

      testWidgets('stream color', (WidgetTester tester) async {
        final swatch = StreamColorSwatch.light(0xff76ce90);
        await prepare(tester, swatch);
        check(findBackgroundColor(tester)).equals(swatch.unreadCountBadgeBackground);
      });
    });
  });
}
