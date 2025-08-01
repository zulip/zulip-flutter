import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/narrow.dart';
import '../model/recent_dm_conversations.dart';
import '../model/unreads.dart';
import 'icons.dart';
import 'message_list.dart';
import 'new_dm_sheet.dart';
import 'page.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'unread_count_badge.dart';
import 'user.dart';

typedef OnDmSelectCallback = void Function(DmNarrow narrow);

class RecentDmConversationsPageBody extends StatefulWidget {
  const RecentDmConversationsPageBody({
    super.key,
    this.hideDmsIfUserCantPost = false,
    this.onDmSelect,
  });

  final bool hideDmsIfUserCantPost;

  /// Callback to invoke when the user selects a DM conversation from the list.
  ///
  /// If null, the default behavior is to navigate to the DM conversation.
  final OnDmSelectCallback? onDmSelect;

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

  void _handleDmSelect(DmNarrow narrow) {
    if (widget.onDmSelect case final onDmSelect?) {
      onDmSelect(narrow);
    } else {
      Navigator.push(context,
        MessageListPage.buildRoute(context: context,
          narrow: narrow));
    }
  }

  void _handleDmSelectForNewDms(DmNarrow narrow) {
    if (widget.onDmSelect case final onDmSelect?) {
      // Pop the new-DMs action sheet.
      Navigator.pop(context);
      onDmSelect(narrow);
    } else {
      Navigator.pushReplacement(context,
        MessageListPage.buildRoute(context: context,
          narrow: narrow));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
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
          SafeArea( // horizontal insets
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: 90),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final narrow = sorted[index];
                if (store.shouldMuteDmConversation(narrow)) {
                  // Filter out conversations where everyone is muted.
                  // TODO should we offer a "spam folder"-style summary screen
                  //   for these conversations we're filtering out?
                  return SizedBox.shrink();
                }
                if (widget.hideDmsIfUserCantPost) {
                  // TODO(#791) handle other cases where user can't post
                  final hasDeactivatedUser =
                    narrow.otherRecipientIds.any(
                      (id) => !(store.getUser(id)?.isActive ?? true));
                  if (hasDeactivatedUser) {
                    return SizedBox.shrink();
                  }
                }
                return RecentDmConversationsItem(
                  narrow: narrow,
                  unreadCount: unreadsModel!.countInDmNarrow(narrow),
                  onDmSelect: _handleDmSelect);
              })),
        Positioned(
          bottom: 21,
          child: _NewDmButton(onDmSelect: _handleDmSelectForNewDms)),
      ]);
  }
}

class RecentDmConversationsItem extends StatelessWidget {
  const RecentDmConversationsItem({
    super.key,
    required this.narrow,
    required this.unreadCount,
    required this.onDmSelect,
  });

  final DmNarrow narrow;
  final int unreadCount;
  final OnDmSelectCallback onDmSelect;

  static const double _avatarSize = 32;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);

    final InlineSpan title;
    final Widget avatar;
    int? userIdForPresence;
    switch (narrow.otherRecipientIds) { // TODO dedupe with DM items in [InboxPage]
      case []:
        title = TextSpan(text: store.selfUser.fullName, children: [
          UserStatusEmoji.asWidgetSpan(userId: store.selfUserId,
            fontSize: 17, textScaler: MediaQuery.textScalerOf(context)),
        ]);
        avatar = AvatarImage(userId: store.selfUserId, size: _avatarSize);
      case [var otherUserId]:
        title = TextSpan(text: store.userDisplayName(otherUserId), children: [
          UserStatusEmoji.asWidgetSpan(userId: otherUserId,
            fontSize: 17, textScaler: MediaQuery.textScalerOf(context)),
        ]);
        avatar = AvatarImage(userId: otherUserId, size: _avatarSize);
        userIdForPresence = otherUserId;
      default:
        title = TextSpan(
          // TODO(i18n): List formatting, like you can do in JavaScript:
          //   new Intl.ListFormat('ja').format(['Chris', 'Greg', 'Alya'])
          //   // 'Chris、Greg、Alya'
          text: narrow.otherRecipientIds.map(store.userDisplayName).join(', '));
        avatar = ColoredBox(color: designVariables.avatarPlaceholderBg,
          child: Center(
            child: Icon(color: designVariables.avatarPlaceholderIcon,
              ZulipIcons.group_dm)));
    }

    // TODO(design) check if this is the right variable
    final backgroundColor = designVariables.background;
    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: () => onDmSelect(narrow),
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
              child: Text.rich(
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
  const _NewDmButton({
    required this.onDmSelect,
  });

  final OnDmSelectCallback onDmSelect;

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
      onTap: () => showNewDmSheet(context, widget.onDmSelect),
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
