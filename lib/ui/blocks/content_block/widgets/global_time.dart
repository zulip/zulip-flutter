import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../api/model/model.dart';
import '../../../../model/content.dart';
import '../../../themes/content_theme.dart';
import '../../../utils/store.dart';
import '../../../values/constants.dart';
import '../../../values/icons.dart';

class GlobalTime extends StatelessWidget {
  const GlobalTime({
    super.key,
    required this.node,
    required this.ambientTextStyle,
  });

  final GlobalTimeNode node;
  final TextStyle ambientTextStyle;

  // Since https://github.com/flutter/flutter/commit/3ea161909,
  // DateFormat with 'j'-prefix pattern (used by locale default pattern below)
  // emits U+202F (NARROW NO-BREAK SPACE) character as a separator between time
  // and its period (AM/PM), instead of the space character.
  // So, do the same for 12-hour format here.
  static final _format12 = intl.DateFormat(
    'EEE, MMM d, y',
  ).addPattern('h:mm\u{202F}aa', ', ');
  static final _format24 = intl.DateFormat(
    'EEE, MMM d, y',
  ).addPattern('Hm', ', ');
  static final _formatLocaleDefault = intl.DateFormat(
    'EEE, MMM d, y',
  ).addPattern('jm', ', ');

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final twentyFourHourTimeMode = store.userSettings.twentyFourHourTime;
    // Design taken from css for `.rendered_markdown & time` in web,
    //   see zulip:web/styles/rendered_markdown.css .
    // TODO(i18n): localize; see plan with ffi in #45
    final format = switch (twentyFourHourTimeMode) {
      TwentyFourHourTimeMode.twelveHour => _format12,
      TwentyFourHourTimeMode.twentyFourHour => _format24,
      TwentyFourHourTimeMode.localeDefault => _formatLocaleDefault,
    };
    final text = format.format(node.datetime.toLocal());
    final contentTheme = ContentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: contentTheme.colorGlobalTimeBackground,
          border: Border.all(
            width: 1,
            color: contentTheme.colorGlobalTimeBorder,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.2 * kBaseFontSize),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                size: ambientTextStyle.fontSize!,
                // (When GlobalTime appears in a link, it should be blue
                // like the text.)
                color: DefaultTextStyle.of(context).style.color!,
                ZulipIcons.clock,
              ),
              // Ad-hoc spacing adjustment per feedback:
              //   https://chat.zulip.org/#narrow/stream/101-design/topic/clock.20icons/near/1729345
              const SizedBox(width: 1),
              Text(text, style: ambientTextStyle),
            ],
          ),
        ),
      ),
    );
  }
}
