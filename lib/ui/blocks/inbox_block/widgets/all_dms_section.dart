import 'package:flutter/material.dart';

import '../../../widgets/sticky_header.dart';
import '../inbox_controller.dart';
import '../inbox_section_data_model.dart';
import 'headers/inbox_all_dms_header_item.dart';
import 'inbox_dm_item.dart';

class AllDmsSection extends StatelessWidget {
  const AllDmsSection({
    super.key,
    required this.data,
    required this.collapsed,
    required this.pageState,
  });

  final AllDmsSectionData data;
  final bool collapsed;
  final InboxPageStateTemplate pageState;

  @override
  Widget build(BuildContext context) {
    final header = InboxAllDmsHeaderItem(
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
              final (narrow, count, hasMention) = item;
              return InboxDmItem(
                narrow: narrow,
                count: count,
                hasMention: hasMention,
              );
            }),
        ],
      ),
    );
  }
}
