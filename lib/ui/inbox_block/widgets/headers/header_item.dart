import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../values/icons.dart';
import '../../../values/text.dart';
import '../../../values/theme.dart';
import '../../../widgets/counter_badge.dart';
import '../../inbox.dart';
import '../inbox_item_marker.dart';

abstract class HeaderItem extends StatelessWidget {
  final bool collapsed;
  final InboxPageState pageState;
  final int count;
  final bool hasMention;

  /// A build context within the [_StreamSection] or [_AllDmsSection].
  ///
  /// Used to ensure the [_StreamSection] or [_AllDmsSection] that encloses the
  /// current [HeaderItem] is visible after being collapsed through this
  /// [HeaderItem].
  final BuildContext sectionContext;

  const HeaderItem({
    super.key,
    required this.collapsed,
    required this.pageState,
    required this.count,
    required this.hasMention,
    required this.sectionContext,
  });

  String title(ZulipLocalizations zulipLocalizations);
  IconData get icon;
  Color collapsedIconColor(BuildContext context);
  Color uncollapsedIconColor(BuildContext context);
  Color uncollapsedBackgroundColor(BuildContext context);

  /// A channel ID, if this represents a channel, else null.
  int? get channelId;

  Future<void> onCollapseButtonTap() async {
    if (!collapsed) {
      await Scrollable.ensureVisible(
        sectionContext,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  Future<void> onRowTap();

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);
    Widget result = Material(
      color: collapsed
          ? designVariables
                .background // TODO(design) check if this is the right variable
          : uncollapsedBackgroundColor(context),
      child: InkWell(
        // TODO use onRowTap to handle taps that are not on the collapse button.
        //   Probably we should give the collapse button a 44px or 48px square
        //   touch target:
        //     <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20Mark-as-read/near/1680973>
        //   But that's in tension with the Figma, which gives these header rows
        //   40px min height.
        onTap: onCollapseButtonTap,
        onLongPress: this is InboxLongPressable
            ? (this as InboxLongPressable).onLongPress
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                size: 20,
                color: designVariables.sectionCollapseIcon,
                collapsed ? ZulipIcons.arrow_right : ZulipIcons.arrow_down,
              ),
            ),
            Icon(
              size: 18,
              color: collapsed
                  ? collapsedIconColor(context)
                  : uncollapsedIconColor(context),
              icon,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  style: TextStyle(
                    fontSize: 17,
                    height: (20 / 17),
                    // TODO(design) check if this is the right variable
                    color: designVariables.labelMenuButton,
                  ).merge(weightVariableTextStyle(context, wght: 600)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  title(zulipLocalizations),
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
                channelIdForBackground: channelId,
                count: count,
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(container: true, child: result);
  }
}

mixin InboxLongPressable on HeaderItem {
  // TODO(#1272) move to _HeaderItem base class
  //   when DM headers become long-pressable; remove mixin
  Future<void> onLongPress();
}
