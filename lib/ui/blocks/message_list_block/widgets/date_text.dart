import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../get/services/store_service.dart';
import '../../../../model/binding.dart';
import '../../../themes/message_list_theme.dart';
import '../message_list.dart';

class DateText extends StatelessWidget {
  const DateText({
    super.key,
    required this.fontSize,
    required this.height,
    required this.timestamp,
  });

  final double fontSize;
  final double height;
  final int timestamp;

  @override
  Widget build(BuildContext context) {
    final store = requirePerAccountStore();
    final messageListTheme = MessageListTheme.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final formattedTimestamp = MessageTimestampStyle.dateOnlyRelative.format(
      timestamp,
      now: ZulipBinding.instance.utcNow().toLocal(),
      twentyFourHourTimeMode: store.userSettings.twentyFourHourTime,
      zulipLocalizations: zulipLocalizations,
    )!;
    return Text(
      style: TextStyle(
        color: messageListTheme.labelTime,
        fontSize: fontSize,
        height: height,
        // This is equivalent to css `all-small-caps`, see:
        //   https://developer.mozilla.org/en-US/docs/Web/CSS/font-variant-caps#all-small-caps
        fontFeatures: const [
          FontFeature.enable('c2sc'),
          FontFeature.enable('smcp'),
        ],
      ),
      formattedTimestamp,
    );
  }
}
