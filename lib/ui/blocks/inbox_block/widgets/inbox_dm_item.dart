import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../get/app_pages.dart';

import '../../../../model/narrow.dart';
import '../../../utils/store.dart';
import '../../../values/icons.dart';
import '../../../values/theme.dart';
import '../../../widgets/counter_badge.dart';
import 'inbox_item_marker.dart';

@visibleForTesting
class InboxDmItem extends StatelessWidget {
  const InboxDmItem({
    super.key,
    required this.narrow,
    required this.count,
    required this.hasMention,
  });

  final DmNarrow narrow;
  final int count;
  final bool hasMention;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);

    // TODO write a test where a/the recipient is muted
    final title = switch (narrow.otherRecipientIds) {
      // TODO dedupe with [RecentDmConversationsItem]
      [] => store.selfUser.fullName,
      [var otherUserId] => store.userDisplayName(otherUserId),

      // TODO(i18n): List formatting, like you can do in JavaScript:
      //   new Intl.ListFormat('ja').format(['Chris', 'Greg', 'Alya', 'Shu'])
      //   // 'Chris、Greg、Alya、Shu'
      _ => narrow.otherRecipientIds.map(store.userDisplayName).join(', '),
    };

    Widget result = Material(
      color: designVariables
          .background, // TODO(design) check if this is the right variable
      child: InkWell(
        onTap: () {
          Get.toNamed<dynamic>(
            AppRoutes.messageList,
            arguments: {'narrow': narrow},
          );
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 34),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 63),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    style: TextStyle(
                      fontSize: 17,
                      height: (20 / 17),
                      // TODO(design) check if this is the right variable
                      color: designVariables.labelMenuButton,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    title,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (hasMention) const InboxIconMarker(icon: ZulipIcons.at_sign),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 16),
                child: CounterBadge(
                  // TODO(design) use CounterKind.quantity, following Figma
                  kind: CounterBadgeKind.unread,
                  channelIdForBackground: null,
                  count: count,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(container: true, child: result);
  }
}
