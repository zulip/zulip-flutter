import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../icons.dart';
import '../../../topic_list.dart';

class TopicListButton extends StatelessWidget {
  const TopicListButton({super.key, required this.streamId});

  final int streamId;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return IconButton(
      icon: const Icon(ZulipIcons.topics),
      tooltip: zulipLocalizations.topicsButtonTooltip,
      onPressed: () => Navigator.push(
        context,
        TopicListPage.buildRoute(context: context, streamId: streamId),
      ),
    );
  }
}
