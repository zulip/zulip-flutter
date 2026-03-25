import 'package:flutter/material.dart';

import '../../../../api/model/model.dart';
import '../../../../model/narrow.dart';
import '../../../values/icons.dart';
import '../../../values/text.dart';
import '../../../values/theme.dart';
import '../../../widgets/action_sheet.dart';
import '../../../widgets/counter_badge.dart';
import '../subscription_list_block.dart';

@visibleForTesting
class SubscriptionItem extends StatelessWidget {
  const SubscriptionItem({
    super.key,
    required this.subscription,
    required this.unreadCount,
    required this.showMutedUnreadBadge,
    required this.showTopicListButtonInActionSheet,
    required this.onChannelSelect,
  });

  final Subscription subscription;
  final int unreadCount;
  final bool showMutedUnreadBadge;
  final bool showTopicListButtonInActionSheet;
  final OnChannelSelectCallback onChannelSelect;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final swatch = colorSwatchFor(context, subscription);
    final hasUnreads = (unreadCount > 0);
    final opacity = subscription.isMuted ? 0.55 : 1.0;
    return Material(
      // TODO(design) check if this is the right variable
      color: designVariables.background,
      child: InkWell(
        onTap: () => onChannelSelect(ChannelNarrow(subscription.streamId)),
        onLongPress: () => showChannelActionSheet(
          context,
          channelId: subscription.streamId,
          showTopicListButton: showTopicListButtonInActionSheet,
        ),
        onSecondaryTap: () => showChannelActionSheet(
          context,
          channelId: subscription.streamId,
          showTopicListButton: showTopicListButtonInActionSheet,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Opacity(
                opacity: opacity,
                child: Icon(
                  size: 18,
                  color: swatch.iconOnPlainBackground,
                  iconDataForStream(subscription),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                // TODO(design): unclear whether bold text is applied to all subscriptions
                //   or only those with unreads:
                //   https://github.com/zulip/zulip-flutter/pull/397#pullrequestreview-1742524205
                child: Opacity(
                  opacity: opacity,
                  child: Text(
                    style:
                        TextStyle(
                          fontSize: 18,
                          height: (20 / 18),
                          // TODO(design) check if this is the right variable
                          color: designVariables.labelMenuButton,
                        ).merge(
                          weightVariableTextStyle(
                            context,
                            wght: hasUnreads && !subscription.isMuted
                                ? 600
                                : null,
                          ),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    subscription.name,
                  ),
                ),
              ),
            ),
            if (hasUnreads) ...[
              const SizedBox(width: 12),
              // TODO(#747) show @-mention indicator when it applies
              Opacity(
                opacity: opacity,
                child: CounterBadge(
                  kind: CounterBadgeKind.unread,
                  count: unreadCount,
                  channelIdForBackground: subscription.streamId,
                ),
              ),
            ] else if (showMutedUnreadBadge) ...[
              const SizedBox(width: 12),
              // TODO(#747) show @-mention indicator when it applies
              const MutedUnreadBadge(),
            ],
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
