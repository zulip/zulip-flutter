import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/narrow.dart';
import '../model/recent_dm_conversations.dart';
import '../model/unreads.dart';
import 'content.dart';
import 'home.dart';
import 'icons.dart';
import 'message_list.dart';
import 'new_dm_sheet.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'unread_count_badge.dart';

class RecentDmConversationsPageBody extends StatefulWidget {
  const RecentDmConversationsPageBody({super.key});

  @override
  State<RecentDmConversationsPageBody> createState() => _RecentDmConversationsPageBodyState();
}

class _RecentDmConversationsPageBodyState extends State<RecentDmConversationsPageBody> with PerAccountStoreAwareStateMixin<RecentDmConversationsPageBody> {
  RecentDmConversationsView? model;
  Unreads? unreadsModel;

  @override
  void onNewStore() {
    model?.removeListener(_modelChanged);
    model = PerAccountStoreWidget.of(context).recentDmConversationsView
      ..addListener(_modelChanged);

    unreadsModel?.removeListener(_modelChanged);
    unreadsModel = PerAccountStoreWidget.of(context).unreads
      ..addListener(_modelChanged);
  }

  @override
  void dispose() {
    model?.removeListener(_modelChanged);
    unreadsModel?.removeListener(_modelChanged);
    super.dispose();
  }

  void _modelChanged() {
    setState(() {
      // The actual state lives in [model] and [unreadsModel].
      // This method was called because one of those just changed.
    });
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final sorted = model!.sorted;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        if (sorted.isEmpty)
          PageBodyEmptyContentPlaceholder(
            message: zulipLocalizations.recentDmConversationsEmptyPlaceholder)
        else
          SafeArea(
            // Don't pad the bottom here; we want the list content to do that.
            bottom: false,
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: 90),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final narrow = sorted[index];
                return RecentDmConversationsItem(
                  narrow: narrow,
                  unreadCount: unreadsModel!.countInDmNarrow(narrow));
              })),
        Positioned(
          bottom: 21,
          child: _NewDmButton()),
      ]);
  }
}

class RecentDmConversationsItem extends StatelessWidget {
  const RecentDmConversationsItem({
    super.key,
    required this.narrow,
    required this.unreadCount,
  });

  final DmNarrow narrow;
  final int unreadCount;

  static const double _avatarSize = 32;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);

    final String title;
    final Widget avatar;
    int? userIdForPresence;
    switch (narrow.otherRecipientIds) { // TODO dedupe with DM items in [InboxPage]
      case []:
        title = store.selfUser.fullName;
        avatar = AvatarImage(userId: store.selfUserId, size: _avatarSize);
      case [var otherUserId]:
        // TODO(#296) actually don't show this row if the user is muted?
        //   (should we offer a "spam folder" style summary screen of recent
        //   1:1 DM conversations from muted users?)
        title = store.userDisplayName(otherUserId);
        avatar = AvatarImage(userId: otherUserId, size: _avatarSize);
        userIdForPresence = otherUserId;
      default:
        // TODO(i18n): List formatting, like you can do in JavaScript:
        //   new Intl.ListFormat('ja').format(['Chris', 'Greg', 'Alya'])
        //   // 'Chris、Greg、Alya'
        title = narrow.otherRecipientIds.map(store.userDisplayName)
          .join(', ');
        avatar = ColoredBox(color: designVariables.groupDmConversationIconBg,
          child: Center(
            child: Icon(color: designVariables.groupDmConversationIcon,
              ZulipIcons.group_dm)));
    }

    // TODO(design) check if this is the right variable
    final backgroundColor = designVariables.background;
    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: () {
          Navigator.push(context,
            MessageListPage.buildRoute(context: context, narrow: narrow));
        },
        child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 48),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Padding(padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 0, 8),
              child: AvatarShape(
                size: _avatarSize,
                borderRadius: 3,
                backgroundColor: userIdForPresence != null ? backgroundColor : null,
                userIdForPresence: userIdForPresence,
                child: avatar)),
            const SizedBox(width: 8),
            Expanded(child: Padding(
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
                title))),
            const SizedBox(width: 12),
            unreadCount > 0
              ? Padding(padding: const EdgeInsetsDirectional.only(end: 16),
                child: UnreadCountBadge(backgroundColor: null,
                  count: unreadCount))
            : const SizedBox(),
          ]))));
  }
}

class _NewDmButton extends StatefulWidget {
  const _NewDmButton();

  @override
  State<_NewDmButton> createState() => _NewDmButtonState();
}

class _NewDmButtonState extends State<_NewDmButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final fabBgColor = _pressed
      ? designVariables.fabBgPressed
      : designVariables.fabBg;
    final fabLabelColor = _pressed
      ? designVariables.fabLabelPressed
      : designVariables.fabLabel;

    return GestureDetector(
      onTap: () => showNewDmSheet(context),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 20, 12),
        decoration: BoxDecoration(
          color: fabBgColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(
            color: designVariables.fabShadow,
            blurRadius: _pressed ? 12 : 16,
            offset: _pressed
              ? const Offset(0, 2)
              : const Offset(0, 4)),
          ]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ZulipIcons.plus, size: 24, color: fabLabelColor),
            const SizedBox(width: 8),
            Text(
              zulipLocalizations.newDmFabButtonLabel,
              style: TextStyle(
                fontSize: 20,
                height: 24 / 20,
                color: fabLabelColor,
              ).merge(weightVariableTextStyle(context, wght: 500))),
          ])));
  }
}
