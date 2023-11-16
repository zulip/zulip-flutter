import 'dart:ui';

import 'package:checks/checks.dart';
import 'package:zulip/widgets/unread_count_badge.dart';

extension UnreadCountBadgeChecks on Subject<UnreadCountBadge> {
  Subject<int> get count => has((b) => b.count, 'count');
  Subject<bool> get bold => has((b) => b.bold, 'bold');
  Subject<Color?> get backgroundColor => has((b) => b.backgroundColor, 'backgroundColor');
}
