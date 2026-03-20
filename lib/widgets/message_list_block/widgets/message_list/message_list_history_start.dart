import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';

class MessageListHistoryStart extends StatelessWidget {
  const MessageListHistoryStart({super.key});

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(zulipLocalizations.noEarlierMessages),
      ),
    ); // TODO use an icon
  }
}
