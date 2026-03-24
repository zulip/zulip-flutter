import 'package:flutter/material.dart';

import '../../../../../api/model/model.dart';
import '../../../../../generated/l10n/zulip_localizations.dart';
import '../../../../values/icons.dart';
import '../../../../values/theme.dart';
import '../../../../widgets/action_sheet.dart';
import 'header_item.dart';

@visibleForTesting
class InboxChannelHeaderItem extends HeaderItem with InboxLongPressable {
  final Subscription subscription;

  const InboxChannelHeaderItem({
    super.key,
    required this.subscription,
    required super.collapsed,
    required super.pageState,
    required super.count,
    required super.hasMention,
    required super.sectionContext,
  });

  @override
  String title(ZulipLocalizations zulipLocalizations) => subscription.name;
  @override
  IconData get icon => iconDataForStream(subscription);
  @override
  Color collapsedIconColor(context) =>
      colorSwatchFor(context, subscription).iconOnPlainBackground;
  @override
  Color uncollapsedIconColor(context) =>
      colorSwatchFor(context, subscription).iconOnBarBackground;
  @override
  Color uncollapsedBackgroundColor(context) =>
      colorSwatchFor(context, subscription).barBackground;
  @override
  int? get channelId => subscription.streamId;

  @override
  Future<void> onCollapseButtonTap() async {
    await super.onCollapseButtonTap();
    if (collapsed) {
      pageState.uncollapseStream(subscription.streamId);
    } else {
      pageState.collapseStream(subscription.streamId);
    }
  }

  @override
  Future<void> onRowTap() => onCollapseButtonTap(); // TODO open channel narrow

  @override
  Future<void> onLongPress() async {
    showChannelActionSheet(sectionContext, channelId: subscription.streamId);
  }
}
