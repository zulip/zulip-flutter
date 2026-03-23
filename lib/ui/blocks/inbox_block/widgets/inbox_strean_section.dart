import 'package:flutter/material.dart';

import '../../../utils/store.dart';
import '../../../widgets/sticky_header.dart';
import '../inbox.dart';
import '../inbox_section_data_model.dart';
import 'headers/inbox_channel_header_item.dart';
import 'inbox_topic_item.dart';

class InboxStreamSection extends StatelessWidget {
  const InboxStreamSection({
    super.key,
    required this.data,
    required this.collapsed,
    required this.pageState,
  });

  final StreamSectionData data;
  final bool collapsed;
  final InboxPageState pageState;

  @override
  Widget build(BuildContext context) {
    final subscription = PerAccountStoreWidget.of(
      context,
    ).subscriptions[data.streamId]!;
    final header = InboxChannelHeaderItem(
      subscription: subscription,
      count: data.count,
      hasMention: data.hasMention,
      collapsed: collapsed,
      pageState: pageState,
      sectionContext: context,
    );
    return StickyHeaderItem(
      header: header,
      child: Column(
        children: [
          header,
          if (!collapsed)
            ...data.items.map((item) {
              return InboxTopicItem(streamId: data.streamId, data: item);
            }),
        ],
      ),
    );
  }
}
