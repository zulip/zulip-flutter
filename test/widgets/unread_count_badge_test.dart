import 'package:checks/checks.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/channel_colors.dart';
import 'package:zulip/widgets/unread_count_badge.dart';

import '../model/binding.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('UnreadCountBadge', () {
    Future<void> prepare(WidgetTester tester, {
      required Widget child,
    }) async {
      addTearDown(testBinding.reset);
      await tester.pumpWidget(TestZulipApp(
        child: child));
      await tester.pump();
    }

    testWidgets('smoke test; no crash', (tester) async {
      await prepare(tester,
        child: UnreadCountBadge(count: 1, backgroundColor: null));
      tester.widget(find.text("1"));
    });

    group('background', () {
      Color? findBackgroundColor(WidgetTester tester) {
        final widget = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
        final decoration = widget.decoration as BoxDecoration;
        return decoration.color;
      }

      testWidgets('default color', (tester) async {
        await prepare(tester,
          child: UnreadCountBadge(count: 1, backgroundColor: null));
        check(findBackgroundColor(tester)).isNotNull().isSameColorAs(const Color(0x26666699));
      });

      testWidgets('stream color', (tester) async {
        final swatch = ChannelColorSwatch.light(0xff76ce90);
        await prepare(tester,
          child: UnreadCountBadge(count: 1, backgroundColor: swatch));
        check(findBackgroundColor(tester)).isNotNull().isSameColorAs(swatch.unreadCountBadgeBackground);
      });
    });
  });
}
