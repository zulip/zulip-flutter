import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/unread_count_badge.dart';

import 'unread_count_badge_checks.dart';

void main() {
  group('UnreadCountBadge', () {
    testWidgets('smoke test; no crash', (tester) async {
      await tester.pumpWidget(
        const Directionality(textDirection: TextDirection.ltr,
          child: UnreadCountBadge(count: 1, baseStreamColor: null)));
      tester.widget(find.text("1"));
    });

    test('colors', () {
      void runCheck(Color? baseStreamColor, Color expectedBackgroundColor) {
        check(UnreadCountBadge(count: 1, baseStreamColor: baseStreamColor))
          .backgroundColor.equals(expectedBackgroundColor);
      }

      runCheck(null, const Color(0x26666699));

      // Check against everything in ZULIP_ASSIGNMENT_COLORS and EXTREME_COLORS
      // in <https://replit.com/@VladKorobov/zulip-sidebar#script.js>.
      // On how to extract expected results from the replit, see:
      //   https://github.com/zulip/zulip-flutter/pull/371#discussion_r1393643523

      // TODO Fix bug causing our implementation's results to differ from the
      //  replit's. Where they differ, see comment with what the replit gives.

      // ZULIP_ASSIGNMENT_COLORS
      runCheck(const Color(0xff76ce90), const Color(0x4d65bd80));
      runCheck(const Color(0xfffae589), const Color(0x4dbdab53)); // 0x4dbdaa52
      runCheck(const Color(0xffa6c7e5), const Color(0x4d8eafcc)); // 0x4d8fb0cd
      runCheck(const Color(0xffe79ab5), const Color(0x4de295b0)); // 0x4de194af
      runCheck(const Color(0xffbfd56f), const Color(0x4d9eb551)); // 0x4d9eb450
      runCheck(const Color(0xfff4ae55), const Color(0x4de19d45)); // 0x4de09c44
      runCheck(const Color(0xffb0a5fd), const Color(0x4daba0f8)); // 0x4daca2f9
      runCheck(const Color(0xffaddfe5), const Color(0x4d83b4b9)); // 0x4d83b4ba
      runCheck(const Color(0xfff5ce6e), const Color(0x4dcba749)); // 0x4dcaa648
      runCheck(const Color(0xffc2726a), const Color(0x4dc2726a));
      runCheck(const Color(0xff94c849), const Color(0x4d86ba3c)); // 0x4d86ba3b
      runCheck(const Color(0xffbd86e5), const Color(0x4dbd86e5));
      runCheck(const Color(0xffee7e4a), const Color(0x4dee7e4a));
      runCheck(const Color(0xffa6dcbf), const Color(0x4d82b69b)); // 0x4d82b79b
      runCheck(const Color(0xff95a5fd), const Color(0x4d95a5fd));
      runCheck(const Color(0xff53a063), const Color(0x4d53a063));
      runCheck(const Color(0xff9987e1), const Color(0x4d9987e1));
      runCheck(const Color(0xffe4523d), const Color(0x4de4523d));
      runCheck(const Color(0xffc2c2c2), const Color(0x4dababab));
      runCheck(const Color(0xff4f8de4), const Color(0x4d4f8de4));
      runCheck(const Color(0xffc6a8ad), const Color(0x4dc2a4a9)); // 0x4dc1a4a9
      runCheck(const Color(0xffe7cc4d), const Color(0x4dc3ab2a)); // 0x4dc2aa28
      runCheck(const Color(0xffc8bebf), const Color(0x4db3a9aa));
      runCheck(const Color(0xffa47462), const Color(0x4da47462));

      // EXTREME_COLORS
      runCheck(const Color(0xFFFFFFFF), const Color(0x4dababab));
      runCheck(const Color(0xFF000000), const Color(0x4d474747));
      runCheck(const Color(0xFFD3D3D3), const Color(0x4dababab));
      runCheck(const Color(0xFFA9A9A9), const Color(0x4da9a9a9));
      runCheck(const Color(0xFF808080), const Color(0x4d808080));
      runCheck(const Color(0xFFFFFF00), const Color(0x4dacb300)); // 0x4dacb200
      runCheck(const Color(0xFFFF0000), const Color(0x4dff0000));
      runCheck(const Color(0xFF008000), const Color(0x4d008000));
      runCheck(const Color(0xFF0000FF), const Color(0x4d0000ff)); // 0x4d0902ff
      runCheck(const Color(0xFFEE82EE), const Color(0x4dee82ee));
      runCheck(const Color(0xFFFFA500), const Color(0x4def9800)); // 0x4ded9600
      runCheck(const Color(0xFF800080), const Color(0x4d810181)); // 0x4d810281
      runCheck(const Color(0xFF00FFFF), const Color(0x4d00c2c3)); // 0x4d00c3c5
      runCheck(const Color(0xFFFF00FF), const Color(0x4dff00ff));
      runCheck(const Color(0xFF00FF00), const Color(0x4d00cb00));
      runCheck(const Color(0xFF800000), const Color(0x4d8d140c)); // 0x4d8b130b
      runCheck(const Color(0xFF008080), const Color(0x4d008080));
      runCheck(const Color(0xFF000080), const Color(0x4d492bae)); // 0x4d4b2eb3
      runCheck(const Color(0xFFFFFFE0), const Color(0x4dadad90)); // 0x4dacad90
      runCheck(const Color(0xFFFF69B4), const Color(0x4dff69b4));
    });
  });
}
