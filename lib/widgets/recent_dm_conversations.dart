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

class _RecentDmConversationsPageBodyState extends State<RecentDmConversationsPageBody> with PerAccountStoreAwareStateMixin<RecentDmConversationsPageBody>{
  RecentDmConversationsView? model;
  Unreads? unreadsModel;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<DmNarrow> _filteredConversations = [];
  bool _isSearching = false;

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
    _searchFocusNode.addListener(_updateSearchState);
  }

  @override
  void dispose() {
    model?.removeListener(_modelChanged);
    unreadsModel?.removeListener(_modelChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _updateSearchState() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty || _searchFocusNode.hasFocus;
    });
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
    _updateSearchState();
  }

  @override
  Widget build(BuildContext context) {
    // Check if there are any DMs at all in the original model
    if (model!.sorted.isEmpty) {
      return const EmptyDmState();
    }

    print("printing the bottom view insets: ${MediaQuery.of(context).viewInsets.bottom}");

    return GestureDetector(
      behavior: HitTestBehavior.translucent, // Ensures taps outside are detected
      onTap: () {
        _searchFocusNode.unfocus(); // Remove focus when tapping outside
      },
      child: Scaffold(
        backgroundColor: DesignVariables.of(context).mainBackground,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              SearchRow(controller: _searchController, focusNode: _searchFocusNode),
              Expanded(
                  child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        if (scrollNotification is ScrollStartNotification) {
                          _searchFocusNode.unfocus(); // Unfocus when scrolling starts
                        }
                        return false;
                      },
                      child: ListView.builder(
                    itemCount: _filteredConversations.length + (_isSearching ? 1 : 0),
                    itemBuilder: (context, index) {
                      if(index < _filteredConversations.length) {
                        final narrow = _filteredConversations[index];
                        return RecentDmConversationsItem(
                          narrow: narrow,
                          unreadCount: unreadsModel!.countInDmNarrow(narrow),
                          searchQuery: _searchController.text,
                          focusNode: _searchFocusNode
                        );
                      }
                      else{
                        return NewDirectMessageButton(focusNode: _searchFocusNode);
                      }
                    })),
              )
            ],
          ),
        ),
        floatingActionButton: Visibility(
          visible: !_isSearching,
          child: const NewDmButton(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}

class EmptyDmState extends StatelessWidget {
  const EmptyDmState({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 48, 0, 16),
                child: SizedBox(
                  width: 124,
                  height: 112,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Opacity(
                      opacity: 0.3,
                      child: Icon(ZulipIcons.no_dm),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: const Opacity(
                  opacity: 0.5,
                  child: Text(
                    'There are no Direct Messages yet.\nStart a conversation with another person\nor a group of people.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                height: 157,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Opacity(
                    opacity: 0.3,
                    child: Icon(ZulipIcons.no_dm_down_arrow),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: NewDmButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class NewDirectMessageButton extends StatelessWidget {
  const NewDirectMessageButton({super.key, this.focusNode});
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8.0, 24, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), // Match the button's shape
        color: designVariables.contextMenuItemBg.withAlpha(30) //12% opacity
      ),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size(137, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.transparent,
        ),
        onPressed: (){
          focusNode?.unfocus();
          Navigator.of(context).push(
              NewDmScreen.buildRoute(context: context)
          );
        },
        icon: Icon(Icons.add, color: designVariables.contextMenuItemIcon, size: 24),
        label: Text(
          'New Direct Message',
          style: TextStyle(color: designVariables.contextMenuItemText, fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class NewDmButton extends StatelessWidget {
  const NewDmButton({super.key});
  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8.0, 16.0, 16),
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Color(0x662B0E8A), // 40% opacity for #2B0E8A
            offset: Offset(0, 4), // X: 0, Y: 4
            blurRadius: 16, // Blur: 16
            spreadRadius: 0, // Spread: 0
          ),
        ],
        borderRadius: BorderRadius.circular(28), // Match the button's shape
      ),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size(137, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: designVariables.fabBg,
        ),
        onPressed: (){
          Navigator.of(context).push(
              NewDmScreen.buildRoute(context: context)
          );
        },
        icon: const Icon(Icons.add, color: Colors.white, size: 24),
        label: Text(
          'New DM',
          style: TextStyle(color: designVariables.fabLabel, fontSize: 20, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class SearchRow extends StatefulWidget {
  SearchRow({super.key, required this.controller, required this.focusNode}); // Accept focusNode

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  State<SearchRow> createState() => _SearchRowState();
}

class _SearchRowState extends State<SearchRow> {
  bool _showCancelButton = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    widget.focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _updateSearchState();
  }
  void _onFocusChanged() {
    _updateSearchState();
  }

  void _updateSearchState() {
    setState(() {
      _showCancelButton = widget.controller.text.isNotEmpty;
      // Notify parent widget about the search state change
      (context as Element).markNeedsBuild();
    });
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      color: DesignVariables.of(context).bgSearchInput,
      child: Row(
        children: [
          const Icon(
            Icons.search,
            size: 24.0,
            color: Colors.grey,
          ),
          const SizedBox(width: 14.0), // Add space between the icon and the text field
          // Text Field
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              decoration: InputDecoration(
                hintText: 'Filter conversations',
                hintStyle: TextStyle(color: designVariables.labelSearchPrompt),
                border: InputBorder.none, // Remove the border
              ),
              style: const TextStyle(fontSize: 17.0, fontWeight: FontWeight.w400),
            ),
          ),
          if (_showCancelButton) ...[
            const SizedBox(width: 8.0),
            GestureDetector(
              onTap: () {
                widget.controller.clear();
                widget.focusNode.unfocus();
              },
              child: const Icon(
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
    required this.searchQuery,
    required this.focusNode,
  });

  final DmNarrow narrow;
  final int unreadCount;
  final String searchQuery;
  final FocusNode focusNode;

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
      color: designVariables.mainBackground, // TODO(design) check if this is the right variable
      child: InkWell(
        onTap: () {
          focusNode.unfocus();
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
              child: _buildHighlightedText(title, searchQuery, designVariables))),
            const SizedBox(width: 12),
            unreadCount > 0
              ? Padding(padding: const EdgeInsetsDirectional.only(end: 16),
                child: UnreadCountBadge(backgroundColor: null,
                  count: unreadCount))
            : const SizedBox(),
          ]))));
  }

  Widget _buildHighlightedText(String text, String query, DesignVariables designVariables) {
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      // If there's no query or it doesn't match, show normal text
      return Text(
        text,
        style: TextStyle(
          fontSize: 17,
          height: (20 / 17),
          color: designVariables.labelMenuButton,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final startIndex = text.toLowerCase().indexOf(query.toLowerCase());
    final endIndex = startIndex + query.length;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, startIndex),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: designVariables.textMessage,
            ),
          ),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700, // Bold for the matching text
              color: designVariables.textMessage,
            ),
          ),
          TextSpan(
            text: text.substring(endIndex),
            style: TextStyle(
              fontSize: 17,
              color: designVariables.labelMenuButton,
            ),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

}
