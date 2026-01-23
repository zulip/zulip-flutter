import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/narrow.dart';
import '../model/recent_dm_conversations.dart';
import '../model/unreads.dart';
import 'icons.dart';
import 'message_list.dart';
import 'new_dm_sheet.dart';
import 'page.dart';
import 'search.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'counter_badge.dart';
import 'user.dart';

typedef OnDmSelectCallback = void Function(DmNarrow narrow);

class RecentDmConversationsPageBody extends StatefulWidget {
  const RecentDmConversationsPageBody({
    super.key,
    this.hideDmsIfUserCantPost = false,
    this.onDmSelect,
  });

  // TODO refactor this widget to avoid reuse of the whole page,
  //   avoiding the need for these flags, callback, and the below
  //   handling of safe-area at this level of abstraction.
  //   See discussion:
  //     https://github.com/zulip/zulip-flutter/pull/1774#discussion_r2249032503
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
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(_handleSearchUpdate);
  }

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
    _searchController.dispose();
    model?.removeListener(_modelChanged);
    unreadsModel?.removeListener(_modelChanged);
    super.dispose();
  }

  void _handleSearchUpdate() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _modelChanged() {
    setState(() {
      // The actual state lives in [model] and [unreadsModel].
      // This method was called because one of those just changed.
    });
  }

  bool _filterNarrow(DmNarrow narrow) {
    if (_searchQuery.isEmpty) return true;
    final store = PerAccountStoreWidget.of(context);
    final String title;
    switch (narrow.otherRecipientIds) {
      case []:
        title = store.selfUser.fullName;
      case [var otherUserId]:
        title = store.userDisplayName(otherUserId);
      default:
        title = narrow.otherRecipientIds.map(store.userDisplayName).join(', ');
    }
    return title.toLowerCase().contains(_searchQuery);
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

    // This value will be zero when this page is used in the context of
    // home-page, see comment on `bottom: false` arg in use of `SafeArea`
    // below.
    final bottomInsets = MediaQuery.paddingOf(context).bottom;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        if (sorted.isEmpty)
          PageBodyEmptyContentPlaceholder(
            header: zulipLocalizations.recentDmConversationsEmptyPlaceholderHeader,
            message: zulipLocalizations.recentDmConversationsEmptyPlaceholderMessage)
        else
          SafeArea(
            // Don't pad the bottom here; we want the list content to do that.
            //
            // When this page is used in the context of the home page, this
            // param and the below use of `MediaQuery.paddingOf(context).bottom`
            // via `bottomInsets` would be noop, because
            // `Scaffold.bottomNavigationBar` in the home page handles that for
            // us. But this page is also used for share-to-zulip page, so we
            // need this to be handled here.
            //
            // Other *PageBody widgets don't handle this because they aren't
            // (re-)used outside the context of the home page.
            bottom: false,
            child: CustomScrollView(
              // Avoid vertical scrollbar appearing on search box
              primary: false,
              slivers: [
                SliverToBoxAdapter(
                  child: SearchBox(
                    controller: _searchController,
                    hintText: zulipLocalizations.recentDmConversationsFilterPlaceholder)),
                SliverPadding(
                  padding: EdgeInsets.only(bottom: bottomInsets + 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final narrow = sorted[index];
                        if (!_filterNarrow(narrow)) {
                           return SizedBox.shrink();
                        }
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
                      },
                      childCount: sorted.length,
                    ),
                  ),
                ),
              ])),
        Positioned(
          bottom: bottomInsets + 21,
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
                child: CounterBadge(
                  kind: CounterBadgeKind.unread,
                  channelIdForBackground: null,
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


