import 'package:flutter/material.dart';
import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/autocomplete.dart';
import '../model/narrow.dart';
import '../model/store.dart';
import 'color.dart';
import 'icons.dart';
import 'message_list.dart';
import 'page.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'user.dart';

void showNewDmSheet(BuildContext context) {
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
        child: NewDmPicker())));
}

@visibleForTesting
class NewDmPicker extends StatefulWidget {
  const NewDmPicker({super.key});

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
    final searchTextLower = searchController.text.toLowerCase();

    final result = <User>[];
    for (final user in sortedUsers) {
      if (excludeSelfUser && user.userId == store.selfUserId) continue;
      if (user.fullName.toLowerCase().contains(searchTextLower)) {
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
      _NewDmHeader(selectedUserIds: selectedUserIds),
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
  const _NewDmHeader({required this.selectedUserIds});

  final Set<int> selectedUserIds;

  Widget _buildCancelButton(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return GestureDetector(
      onTap: Navigator.of(context).pop,
      child: Text(zulipLocalizations.dialogCancel, style: TextStyle(
        color: designVariables.icon,
        fontSize: 20,
        height: 30 / 20)));
  }

  Widget _buildComposeButton(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final color = selectedUserIds.isEmpty
      ? designVariables.icon.withFadedAlpha(0.5)
      : designVariables.icon;

    return GestureDetector(
      onTap: selectedUserIds.isEmpty ? null : () {
        final store = PerAccountStoreWidget.of(context);
        final narrow = DmNarrow.withUsers(
          selectedUserIds.toList(),
          selfUserId: store.selfUserId);
        Navigator.pushReplacement(context,
          MessageListPage.buildRoute(context: context, narrow: narrow));
      },
      child: Text(zulipLocalizations.newDmSheetComposeButtonLabel,
        style: TextStyle(
          color: color,
          fontSize: 20,
          height: 30 / 20,
        ).merge(weightVariableTextStyle(context, wght: 600))));
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 8, 6),
      child: Row(children: [
        _buildCancelButton(context),
        SizedBox(width: 8),
        Expanded(child: Text(zulipLocalizations.newDmSheetScreenTitle,
          style: TextStyle(
            color: designVariables.title,
            fontSize: 20,
            height: 30 / 20,
          ).merge(weightVariableTextStyle(context, wght: 600)),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.center)),
        SizedBox(width: 8),
        _buildComposeButton(context),
      ]));
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
    final designVariables = DesignVariables.of(context);

    return Container(
      constraints: const BoxConstraints(maxHeight: 124),
      decoration: BoxDecoration(color: designVariables.bgSearchInput),
      child: SingleChildScrollView(
        reverse: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final userId in selectedUserIds)
                _SelectedUserChip(userId: userId, unselectUser: unselectUser),
              // The IntrinsicWidth lets the text field participate in the Wrap
              // when its content fits on the same line with a user chip,
              // by preventing it from expanding to fill the available width.  See:
              //   https://github.com/zulip/zulip-flutter/pull/1322#discussion_r2094112488
              IntrinsicWidth(child: _buildSearchField(context)),
            ]))));
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: designVariables.bgMenuButtonSelected,
          borderRadius: BorderRadius.circular(3)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Avatar(userId: userId, size: clampedTextScaler.scale(22), borderRadius: 3),
          Flexible(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(5, 3, 4, 3),
              child: Text(store.userDisplayName(userId),
                textScaler: clampedTextScaler,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  height: 16 / 16,
                  color: designVariables.labelMenuButton)))),
          UserStatusEmoji(userId: userId, size: 16,
            padding: EdgeInsetsDirectional.only(end: 4)),
        ])));
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
              fontSize: 16))));
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
    return Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(10),
      color: isSelected
        ? designVariables.bgMenuButtonSelected
        : Colors.transparent,
      child: InkWell(
        highlightColor: designVariables.bgMenuButtonSelected,
        splashFactory: NoSplash.splashFactory,
        onTap: () => onTapped(userId),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 12, 6),
          child: Row(children: [
            SizedBox(width: 8),
            isSelected
              ? Icon(size: 24,
                  color: designVariables.radioFillSelected,
                  ZulipIcons.check_circle_checked)
              : Icon(size: 24,
                  color: designVariables.radioBorder,
                  ZulipIcons.check_circle_unchecked),
            SizedBox(width: 10),
            Avatar(userId: userId, size: 32, borderRadius: 3),
            SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(text: store.userDisplayName(userId), children: [
                  UserStatusEmoji.asWidgetSpan(userId: userId, fontSize: 17,
                    textScaler: MediaQuery.textScalerOf(context)),
                ]),
                style: TextStyle(
                  fontSize: 17,
                  height: 19 / 17,
                  color: designVariables.textMessage,
                ).merge(weightVariableTextStyle(context, wght: 500)))),
          ]))));
  }
}
