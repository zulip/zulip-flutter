// This is adapted from [MessageListAppBarTitle].
import 'package:flutter/material.dart';

import '../../../generated/l10n/zulip_localizations.dart';
import '../../utils/store.dart';
import '../../values/icons.dart';
import '../../values/text.dart';
import '../../values/theme.dart';
import '../../widgets/action_sheet.dart';

class TopicListAppBarTitle extends StatelessWidget {
  const TopicListAppBarTitle({
    super.key,
    required this.streamId,
    required this.willCenterTitle,
  });

  final int streamId;
  final bool willCenterTitle;

  Widget _buildStreamRow(BuildContext context) {
    // TODO(#1039) implement a consistent app bar design here
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);
    final store = PerAccountStoreWidget.of(context);
    final stream = store.streams[streamId];
    final channelIconColor = colorSwatchFor(
      context,
      store.subscriptions[streamId],
    ).iconOnBarBackground;

    // A null [Icon.icon] makes a blank space.
    final icon = stream != null ? iconDataForStream(stream) : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      // TODO(design): The vertical alignment of the stream privacy icon is a bit ad hoc.
      //   For screenshots of some experiments, see:
      //     https://github.com/zulip/zulip-flutter/pull/219#discussion_r1281024746
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
          child: Icon(size: 18, icon, color: channelIconColor),
        ),
        Flexible(
          child: Text(
            stream?.name ?? zulipLocalizations.unknownChannelName,
            style: TextStyle(
              fontSize: 20,
              height: 30 / 20,
              color: designVariables.title,
            ).merge(weightVariableTextStyle(context, wght: 600)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final alignment = willCenterTitle
        ? Alignment.center
        : AlignmentDirectional.centerStart;
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () {
          showChannelActionSheet(
            context,
            channelId: streamId,
            // We're already on the topic list.
            showTopicListButton: false,
          );
        },
        child: Align(alignment: alignment, child: _buildStreamRow(context)),
      ),
    );
  }
}
