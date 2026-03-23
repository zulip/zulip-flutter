import 'package:flutter/material.dart';

import '../../../api/model/model.dart';
import '../../../model/unreads.dart';
import '../subscription_list_block.dart';
import 'subscription_item.dart';

class SubscriptionList extends StatelessWidget {
  const SubscriptionList({
    super.key,
    required this.unreadsModel,
    required this.subscriptions,
    required this.showTopicListButtonInActionSheet,
    required this.onChannelSelect,
  });

  final Unreads? unreadsModel;
  final List<Subscription> subscriptions;
  final bool showTopicListButtonInActionSheet;
  final OnChannelSelectCallback onChannelSelect;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: subscriptions.length,
      itemBuilder: (BuildContext context, int index) {
        final subscription = subscriptions[index];
        final unreadCount = unreadsModel!.countInChannel(subscription.streamId);
        final showMutedUnreadBadge =
            unreadCount == 0 &&
            unreadsModel!.countInChannelNarrow(subscription.streamId) > 0;
        return SubscriptionItem(
          subscription: subscription,
          unreadCount: unreadCount,
          showMutedUnreadBadge: showMutedUnreadBadge,
          showTopicListButtonInActionSheet: showTopicListButtonInActionSheet,
          onChannelSelect: onChannelSelect,
        );
      },
    );
  }
}
