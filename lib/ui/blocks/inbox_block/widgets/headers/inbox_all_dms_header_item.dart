import 'package:flutter/material.dart';

import '../../../../../generated/l10n/zulip_localizations.dart';
import '../../../../values/icons.dart';
import '../../../../values/theme.dart';
import 'header_item.dart';

@visibleForTesting
class InboxAllDmsHeaderItem extends HeaderItem {
  const InboxAllDmsHeaderItem({
    super.key,
    required super.collapsed,
    required super.pageState,
    required super.count,
    required super.hasMention,
    required super.sectionContext,
  });

  @override
  String title(ZulipLocalizations zulipLocalizations) =>
      zulipLocalizations.recentDmConversationsSectionHeader;
  @override
  IconData get icon => ZulipIcons.two_person;

  // TODO(design) check if this is the right variable for these
  @override
  Color collapsedIconColor(context) =>
      DesignVariables.of(context).labelMenuButton;
  @override
  Color uncollapsedIconColor(context) =>
      DesignVariables.of(context).labelMenuButton;

  @override
  Color uncollapsedBackgroundColor(context) =>
      DesignVariables.of(context).dmHeaderBg;
  @override
  int? get channelId => null;

  @override
  Future<void> onCollapseButtonTap() async {
    await super.onCollapseButtonTap();
    pageState.allDmsCollapsed = !collapsed;
  }

  @override
  Future<void> onRowTap() => onCollapseButtonTap(); // TODO open all-DMs narrow?
}
