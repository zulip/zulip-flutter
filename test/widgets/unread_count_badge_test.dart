import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/unread_count_badge.dart';

void main() {
  group('UnreadCountBadge', () {
    testWidgets('smoke test; no crash', (tester) async {
      await tester.pumpWidget(
        const Directionality(textDirection: TextDirection.ltr,
          child: UnreadCountBadge(count: 1)));
      tester.widget(find.text("1"));
    });
  });
}
