import 'package:flutter/material.dart';
import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/autocomplete.dart';
import '../model/narrow.dart';
import '../model/store.dart';
import 'color.dart';
import 'page.dart';
import 'recent_dm_conversations.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'user.dart';

void showNewDmSheet(BuildContext context, OnDmSelectCallback onDmSelect) {
  final pageContext = PageRoot.contextOf(context);
  final store = PerAccountStoreWidget.of(context);
  showModalBottomSheet<void>(
    context: pageContext,
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (BuildContext context) => Padding(
      // By default, when software keyboard is opened, the ListView
      // expands behind the software keyboard — resulting in some
      // list entries being covered by the keyboard. Add explicit
      // bottom padding the size of the keyboard, which fixes this.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: PerAccountStoreWidget(
        accountId: store.accountId,
        child: NewDmPicker(onDmSelect: onDmSelect))));
}

@visibleForTesting
class NewDmPicker extends StatefulWidget {
  const NewDmPicker({super.key, required this.onDmSelect});

  final OnDmSelectCallback onDmSelect;

  @override
  State<NewDmPicker> createState() => _NewDmPickerState();
}

class _NewDmPickerState extends State<NewDmPicker> with PerAccountStoreAwareStateMixin<NewDmPicker> {
  late TextEditingController searchController;
  late ScrollController resultsScrollController;
  Set<int> selectedUserIds = {};
  List<User> filteredUsers = [];
  List <User> sortedUsers = [];

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController()..addListener(_handleSearchUpdate);
    resultsScrollController = ScrollController();
  }

  @override
  void onNewStore() {
    final store = PerAccountStoreWidget.of(context);
    _initSortedUsers(store);
  }

  @override
  void dispose() {
    searchController.dispose();
    resultsScrollController.dispose();
    super.dispose();
  }

  void _initSortedUsers(PerAccountStore store) {
    final users = store.allUsers
      .where((user) => user.isActive && !store.isUserMuted(user.userId));
    sortedUsers = List<User>.from(users)
      ..sort((a, b) => MentionAutocompleteView.compareByDms(a, b, store: store));
    _updateFilteredUsers(store);
  }

  void _handleSearchUpdate() {
    final store = PerAccountStoreWidget.of(context);
    _updateFilteredUsers(store);
  }

  // Function to sort users based on recency of DM's
  // TODO: switch to using an `AutocompleteView` for users
  void _updateFilteredUsers(PerAccountStore store) {
    final excludeSelfUser = selectedUserIds.isNotEmpty
      && !selectedUserIds.contains(store.selfUserId);
    final normalizedQuery =
      AutocompleteQuery.lowercaseAndStripDiacritics(searchController.text);

    final result = <User>[];
    for (final user in sortedUsers) {
      if (excludeSelfUser && user.userId == store.selfUserId) continue;
      final normalizedName = AutocompleteQuery.lowercaseAndStripDiacritics(user.fullName);
      if (normalizedName.contains(normalizedQuery)) {
        result.add(user);
      }
    }

    setState(() {
      filteredUsers = result;
    });

    if (resultsScrollController.hasClients) {
      // Jump to the first results for the new query.
      resultsScrollController.jumpTo(0);
    }
  }

  void _selectUser(int userId) {
    assert(!selectedUserIds.contains(userId));
    final store = PerAccountStoreWidget.of(context);
    selectedUserIds.add(userId);
    if (userId != store.selfUserId) {
      selectedUserIds.remove(store.selfUserId);
    }
    _updateFilteredUsers(store);
  }

  void _unselectUser(int userId) {
    assert(selectedUserIds.contains(userId));
    final store = PerAccountStoreWidget.of(context);
    selectedUserIds.remove(userId);
    _updateFilteredUsers(store);
  }

  void _handleUserTap(int userId) {
    selectedUserIds.contains(userId)
      ? _unselectUser(userId)
      : _selectUser(userId);
    searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _NewDmHeader(selectedUserIds: selectedUserIds, onDmSelect: widget.onDmSelect),
      _NewDmSearchBar(
        controller: searchController,
        selectedUserIds: selectedUserIds,
        unselectUser: _unselectUser),
      Expanded(
        child: _NewDmUserList(
          filteredUsers: filteredUsers,
          selectedUserIds: selectedUserIds,
          scrollController: resultsScrollController,
          onUserTapped: (userId) => _handleUserTap(userId))),
    ]);
  }
}

class _NewDmHeader extends StatelessWidget {
  const _NewDmHeader({required this.selectedUserIds, required this.onDmSelect});

  final Set<int> selectedUserIds;
  final OnDmSelectCallback onDmSelect;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
        child: Row(children: [
          GestureDetector(
            onTap: Navigator.of(context).pop,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.close, size: 24, color: designVariables.icon),
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              zulipLocalizations.newDmSheetScreenTitle,
              style: TextStyle(
                color: designVariables.title,
                fontSize: 18,
                height: 26 / 18,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 4),
          GestureDetector(
            onTap: selectedUserIds.isEmpty ? null : () {
              final store = PerAccountStoreWidget.of(context);
              final narrow = DmNarrow.withUsers(
                selectedUserIds.toList(),
                selfUserId: store.selfUserId);
              onDmSelect(narrow);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selectedUserIds.isEmpty
                  ? Colors.grey.withValues(alpha: 0.1)
                  : designVariables.icon.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                zulipLocalizations.newDmSheetComposeButtonLabel,
                style: TextStyle(
                  color: selectedUserIds.isEmpty
                    ? designVariables.icon.withFadedAlpha(0.5)
                    : designVariables.icon,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _NewDmSearchBar extends StatelessWidget {
  const _NewDmSearchBar({
    required this.controller,
    required this.selectedUserIds,
    required this.unselectUser,
  });

  final TextEditingController controller;
  final Set<int> selectedUserIds;
  final void Function(int) unselectUser;

  // void _removeUser

  Widget _buildSearchField(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final hintText = selectedUserIds.isEmpty
      ? zulipLocalizations.newDmSheetSearchHintEmpty
      : zulipLocalizations.newDmSheetSearchHintSomeSelected;

    return TextField(
      controller: controller,
      autofocus: true,
      cursorColor: designVariables.foreground,
      style: TextStyle(
        color: designVariables.textMessage,
        fontSize: 17,
        height: 22 / 17),
      scrollPadding: EdgeInsets.zero,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        hintText: hintText,
        hintStyle: TextStyle(
          color: designVariables.labelSearchPrompt,
          fontSize: 17,
          height: 22 / 17)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 140),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
      ),
      child: SingleChildScrollView(
        reverse: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final userId in selectedUserIds)
                _SelectedUserChip(userId: userId, unselectUser: unselectUser),
              // The IntrinsicWidth lets the text field participate in the Wrap
              // when its content fits on the same line with a user chip,
              // by preventing it from expanding to fill the available width.  See:
              //   https://github.com/zulip/zulip-flutter/pull/1322#discussion_r2094112488
              IntrinsicWidth(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildSearchField(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedUserChip extends StatelessWidget {
  const _SelectedUserChip({
    required this.userId,
    required this.unselectUser,
  });

  final int userId;
  final void Function(int) unselectUser;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final store = PerAccountStoreWidget.of(context);
    final clampedTextScaler = MediaQuery.textScalerOf(context)
      .clamp(maxScaleFactor: 1.5);

    return GestureDetector(
      onTap: () => unselectUser(userId),
      child: Container(
        decoration: BoxDecoration(
          color: designVariables.icon.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: designVariables.icon.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 4, 4),
            child: Avatar(userId: userId, size: clampedTextScaler.scale(24), borderRadius: 4),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 6, 6),
              child: Text(
                store.userDisplayName(userId),
                textScaler: clampedTextScaler,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 16 / 14,
                  fontWeight: FontWeight.w500,
                  color: designVariables.textMessage,
                ),
              ),
            ),
          ),
          UserStatusEmoji(
            userId: userId,
            size: 14,
            padding: EdgeInsetsDirectional.only(end: 6),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: Icon(
              Icons.clear_rounded,
              size: 16,
              color: designVariables.icon.withFadedAlpha(0.6),
            ),
          ),
        ]),
      ),
    );
  }
}

class _NewDmUserList extends StatelessWidget {
  const _NewDmUserList({
    required this.filteredUsers,
    required this.selectedUserIds,
    required this.scrollController,
    required this.onUserTapped,
  });

  final List<User> filteredUsers;
  final Set<int> selectedUserIds;
  final ScrollController scrollController;
  final void Function(int userId) onUserTapped;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    if (filteredUsers.isEmpty) {
      // TODO(design): Missing in Figma.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            textAlign: TextAlign.center,
            zulipLocalizations.newDmSheetNoUsersFound,
            style: TextStyle(
              color: designVariables.labelMenuButton,
              fontSize: 15,
              height: 20 / 15,
              fontWeight: FontWeight.w500,
            ))));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: CustomScrollView(controller: scrollController, slivers: [
        SliverPadding(
          padding: EdgeInsets.only(top: 8),
          sliver: SliverSafeArea(
            minimum: EdgeInsets.only(bottom: 8),
            sliver: SliverList.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                final isSelected = selectedUserIds.contains(user.userId);

                return _NewDmUserListItem(
                  userId: user.userId,
                  isSelected: isSelected,
                  onTapped: onUserTapped,
                );
              }))),
        ]));
  }
}

class _NewDmUserListItem extends StatelessWidget {
  const _NewDmUserListItem({
    required this.userId,
    required this.isSelected,
    required this.onTapped,
  });

  final int userId;
  final bool isSelected;
  final void Function(int userId) onTapped;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isSelected
          ? designVariables.icon.withValues(alpha: 0.08)
          : Colors.transparent,
        border: isSelected
          ? Border.all(color: designVariables.icon.withValues(alpha: 0.15))
          : null,
      ),
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
        child: InkWell(
          highlightColor: designVariables.icon.withValues(alpha: 0.05),
          splashFactory: NoSplash.splashFactory,
          onTap: () => onTapped(userId),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
            child: Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                    ? designVariables.radioFillSelected
                    : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                      ? designVariables.radioFillSelected
                      : designVariables.radioBorder,
                    width: 2,
                  ),
                ),
                child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
              ),
              SizedBox(width: 12),
              Avatar(userId: userId, size: 40, borderRadius: 6),
              SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(text: store.userDisplayName(userId), children: [
                    UserStatusEmoji.asWidgetSpan(userId: userId, fontSize: 16,
                      textScaler: MediaQuery.textScalerOf(context)),
                  ]),
                  style: TextStyle(
                    fontSize: 16,
                    height: 20 / 16,
                    color: designVariables.textMessage,
                    fontWeight: FontWeight.w500,
                  ).merge(weightVariableTextStyle(context, wght: 500))),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
