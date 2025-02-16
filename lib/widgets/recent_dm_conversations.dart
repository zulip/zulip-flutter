import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/narrow.dart';
import '../model/recent_dm_conversations.dart';
import '../model/unreads.dart';
import 'content.dart';
import 'icons.dart';
import 'message_list.dart';
import 'new_dm.dart';
import 'store.dart';
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

  final TextEditingController _searchController = TextEditingController();
  List<DmNarrow> _filteredConversations = [];

  @override
  void onNewStore() {
    model?.removeListener(_modelChanged);
    model = PerAccountStoreWidget.of(context).recentDmConversationsView
      ..addListener(_modelChanged);

    unreadsModel?.removeListener(_modelChanged);
    unreadsModel = PerAccountStoreWidget.of(context).unreads
      ..addListener(_modelChanged);

    _applySearchFilter();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearchFilter);
  }

  @override
  void dispose() {
    model?.removeListener(_modelChanged);
    unreadsModel?.removeListener(_modelChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _modelChanged() {
    setState(() {
      // The actual state lives in [model] and [unreadsModel].
      // This method was called because one of those just changed.
      _applySearchFilter();
    });
  }

  void _applySearchFilter() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredConversations = List.from(model!.sorted);
    } else {
      _filteredConversations = model!.sorted.where((narrow) {
        final store = PerAccountStoreWidget.of(context);
        final selfUser = store.users[store.selfUserId]!;
        final otherRecipientIds = narrow.otherRecipientIds;

        if (otherRecipientIds.isEmpty) {
          return selfUser.fullName.toLowerCase().contains(query);
        } else {
          return otherRecipientIds.any((id) {
            final user = store.users[id];
            return user?.fullName.toLowerCase().contains(query) ?? false;
          });
        }
      }).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    // Check if there are any DMs at all in the original model
    if (model!.sorted.isEmpty) {
      return const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 124,
                      height: 112,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Opacity(
                          opacity: 0.3,
                          child: Icon(
                            ZulipIcons.no_dm,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Opacity(
                      opacity: 0.5,
                      child: Text(
                        'There are no Direct Messages yet.\nStart a conversation with another person\nor a group of people.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 157,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Opacity(
                          opacity: 0.3,
                          child: Icon(
                            ZulipIcons.no_dm_down_arrow,
                          ),
                        ),
                      ),
                    )
                  ],
                )
                ,
                NewDmButton()
              ]
            ),
          ),
        ),
      );
    }
    else {
      return SafeArea(
      // Don't pad the bottom here; we want the list content to do that.
      bottom: false,
      child: Column(
        children: [
          SearchRow(controller: _searchController),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredConversations.length,
              itemBuilder: (context, index) {
                final narrow = _filteredConversations[index];
                return RecentDmConversationsItem(
                  narrow: narrow,
                  unreadCount: unreadsModel!.countInDmNarrow(narrow),
                );
              }),
          ),
          NewDmButton()
        ],
      ));
    }
  }
}

class NewDmButton extends StatelessWidget {
  const NewDmButton({super.key});

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size(137, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: designVariables.newDmButtonBg,
      ),
      onPressed: (){
        Navigator.of(context).push(
            NewDmScreen.buildRoute(context: context)
        );
      },
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'New DM',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}

class SearchRow extends StatefulWidget {
  const SearchRow({super.key, required this.controller,});

  final TextEditingController controller;

  @override
  State<SearchRow> createState() => _SearchRowState();
}

class _SearchRowState extends State<SearchRow> {
  bool _showCancelButton = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _showCancelButton = widget.controller.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add padding around the row
      child: Row(
        children: [
          const Icon(
            Icons.search,
            size: 24.0,
            color: Colors.grey,
          ),
          const SizedBox(width: 8.0), // Add space between the icon and the text field
          // Text Field
          Expanded(
            child: TextField(
              controller: widget.controller,
              decoration: const InputDecoration(
                hintText: 'Search...', // Placeholder text
                border: InputBorder.none, // Remove the border
              ),
              style: TextStyle(fontSize: 16.0), // Customize the text style
            ),
          ),
          if (_showCancelButton) ...[
            SizedBox(width: 8.0),
            GestureDetector(
              onTap: () {
                widget.controller.clear();
              },
              child: Icon(
                Icons.cancel,
                size: 20.0,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
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
    final selfUser = store.users[store.selfUserId]!;

    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);

    final String title;
    final Widget avatar;
    switch (narrow.otherRecipientIds) { // TODO dedupe with DM items in [InboxPage]
      case []:
        title = selfUser.fullName;
        avatar = AvatarImage(userId: selfUser.userId, size: _avatarSize);
      case [var otherUserId]:
        // TODO(#296) actually don't show this row if the user is muted?
        //   (should we offer a "spam folder" style summary screen of recent
        //   1:1 DM conversations from muted users?)
        final otherUser = store.users[otherUserId];
        title = otherUser?.fullName ?? zulipLocalizations.unknownUserName;
        avatar = AvatarImage(userId: otherUserId, size: _avatarSize);
      default:
        // TODO(i18n): List formatting, like you can do in JavaScript:
        //   new Intl.ListFormat('ja').format(['Chris', 'Greg', 'Alya'])
        //   // 'Chris、Greg、Alya'
        title = narrow.otherRecipientIds.map(
          (id) => store.users[id]?.fullName ?? zulipLocalizations.unknownUserName
        ).join(', ');
        avatar = ColoredBox(color: designVariables.groupDmConversationIconBg,
          child: Center(
            child: Icon(color: designVariables.groupDmConversationIcon,
              ZulipIcons.group_dm)));
    }

    return Material(
      color: designVariables.background, // TODO(design) check if this is the right variable
      child: InkWell(
        onTap: () {
          Navigator.push(context,
            MessageListPage.buildRoute(context: context, narrow: narrow));
        },
        child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 48),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Padding(padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 0, 8),
              child: AvatarShape(size: _avatarSize, borderRadius: 3, child: avatar)),
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
