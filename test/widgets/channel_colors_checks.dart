import 'dart:ui';

import 'package:checks/checks.dart';
import 'package:zulip/widgets/channel_colors.dart';

extension ChannelColorSwatchChecks on Subject<ChannelColorSwatch> {
  Subject<Color> get base => has((s) => s.base, 'base');
  Subject<Color> get unreadCountBadgeBackground => has((s) => s.unreadCountBadgeBackground, 'unreadCountBadgeBackground');
  Subject<Color> get iconOnPlainBackground => has((s) => s.iconOnPlainBackground, 'iconOnPlainBackground');
  Subject<Color> get iconOnBarBackground => has((s) => s.iconOnBarBackground, 'iconOnBarBackground');
  Subject<Color> get barBackground => has((s) => s.barBackground, 'barBackground');
}
