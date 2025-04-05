import 'package:flutter/material.dart';
import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/narrow.dart';
import '../model/store.dart';
import 'color.dart';
import 'content.dart';
import 'icons.dart';
import 'message_list.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';

void showNewDmSheet(BuildContext context) {
  final store = PerAccountStoreWidget.of(context);
  showModalBottomSheet<void>(
    context: context,
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (BuildContext context) => Padding(
      // By default, when software keyboard is opened, the ListView
      // expands behind the software keyboard — resulting in some
      // list entries being covered by the keyboard. Add explicit
      // bottom padding the size of the keyboard, which fixes this.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: PerAccountStoreWidget(
          accountId: store.accountId,
          child: NewDmPicker(pageContext: context, store: store)))));
}

@visibleForTesting
class NewDmPicker extends StatefulWidget {
  const NewDmPicker({
    super.key,
    required this.pageContext,
    required this.store,
  });

  final BuildContext pageContext;
  final PerAccountStore store;

  @override
  State<NewDmPicker> createState() => _NewDmPickerState();
}

class _NewDmPickerState extends State<NewDmPicker> {
  late TextEditingController searchController;
  final Set<int> selectedUserIds = {};
  List<User> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController()..addListener(_handleSearchUpdate);
    _updateFilteredUsers(widget.store);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _handleSearchUpdate() {
    final store = PerAccountStoreWidget.of(context);
    _updateFilteredUsers(store);
  }

  // Function to sort users based on recency of DM's
  // TODO: switch to using an `AutocompleteView` for users
  void _updateFilteredUsers(PerAccountStore store) {
    setState(() {
      filteredUsers = store.allUsers
        .where((user) =>
          user.userId != store.selfUserId &&
          user.fullName.toLowerCase().contains(searchController.text.toLowerCase()))
        .toList()
        ..sort((a, b) {
          final recentDms = store.recentDmConversationsView;
          final aLatestMessageId = recentDms.latestMessagesByRecipient[a.userId];
          final bLatestMessageId = recentDms.latestMessagesByRecipient[b.userId];

          if (aLatestMessageId != null && bLatestMessageId != null) {
            return bLatestMessageId.compareTo(aLatestMessageId);
          }
          if (aLatestMessageId != null) return -1;
          if (bLatestMessageId != null) return 1;
          return 0;
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NewDmHeader(
          selectedUserIds: selectedUserIds,
          onClose: () => Navigator.pop(context)),
        _NewDmSearchBar(
          searchController: searchController,
          selectedUserIds: selectedUserIds),
        Expanded(child: _NewDmUserList(
          filteredUsers: filteredUsers,
          selectedUserIds: selectedUserIds,
          onUserTapped: (userId) {
            setState(() {
              if (selectedUserIds.contains(userId)) {
                selectedUserIds.remove(userId);
              } else {
                selectedUserIds.add(userId);
              }
            });
          })),
      ]);
  }
}

class _NewDmHeader extends StatelessWidget {
  const _NewDmHeader({
    required this.selectedUserIds,
    required this.onClose,
  });

  final Set<int> selectedUserIds;
  final VoidCallback onClose;

  Widget _buildBackButton(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return GestureDetector(
      onTap: onClose,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ZulipIcons.chevron_left, size: 24, color: designVariables.icon),
          Text(zulipLocalizations.newDmSheetBackButtonLabel,
            style: TextStyle(color: designVariables.icon,
              fontSize: 20, height: 30 / 20)),
        ]));
  }

  Widget _buildNextButton(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final nextButtonColor = selectedUserIds.isEmpty
      ? designVariables.icon.withFadedAlpha(0.5)
      : designVariables.icon;

    return GestureDetector(
      onTap: selectedUserIds.isEmpty ? null : () {
        final narrow = DmNarrow.withOtherUsers(
          selectedUserIds,
          selfUserId: store.selfUserId);
        Navigator.pop(context);
        Navigator.push(context,
          MessageListPage.buildRoute(context: context, narrow: narrow));
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(zulipLocalizations.newDmSheetNextButtonLabel,
            style: TextStyle(color: nextButtonColor,
              fontSize: 20, height: 30 / 20)
              .merge(weightVariableTextStyle(context, wght: 600))),
          Icon(ZulipIcons.chevron_right,
            size: 24,
            color: nextButtonColor),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 10, 8, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBackButton(context),
          Expanded(
            child: Center(
              child: Text(zulipLocalizations.newDmSheetScreenTitle,
                style: TextStyle(color: designVariables.title,
                  fontSize: 20, height: 30 / 20)
                  .merge(weightVariableTextStyle(context, wght: 600)),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center))),
          _buildNextButton(context),
        ])
    );
  }
}

class _NewDmSearchBar extends StatelessWidget {
  const _NewDmSearchBar({
    required this.searchController,
    required this.selectedUserIds,
  });

  final TextEditingController searchController;
  final Set<int> selectedUserIds;

  Widget _buildSearchField(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final hintText = selectedUserIds.isEmpty
      ? zulipLocalizations.newDmSheetSearchHintEmpty
      : zulipLocalizations.newDmSheetSearchHintSomeSelected;

    return TextField(
      controller: searchController,
      cursorColor: designVariables.foreground,
      style: TextStyle(color: designVariables.textMessage,
        fontSize: 17, height: 22 / 17),
      scrollPadding: EdgeInsets.zero,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        hintText: hintText,
        hintStyle: TextStyle(color: designVariables.labelSearchPrompt,
          fontSize: 17, height: 22 / 17),
        border: InputBorder.none));
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    return Container(
      constraints: const BoxConstraints(
        minHeight: 44,
        maxHeight: 124),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(color: designVariables.bgSearchInput),
      child: SingleChildScrollView(
        reverse: true,
        child: Row(children: [
          Expanded(child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...selectedUserIds.map((userId) => _SelectedUserChip(userId: userId)),
              IntrinsicWidth(child: _buildSearchField(context)),
            ])),
        ])));
  }
}

class _SelectedUserChip extends StatelessWidget {
  const _SelectedUserChip({ required this.userId });

  final int userId;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final user = store.getUser(userId);

    return Container(
      decoration: BoxDecoration(
        color: designVariables.bgMenuButtonSelected,
        borderRadius: BorderRadius.circular(3)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Avatar(userId: userId, size: 22, borderRadius: 3),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(5, 3, 4, 3),
            child: Text(user?.fullName ?? zulipLocalizations.unknownUserName,
              style: TextStyle(
                fontSize: 16,
                height: 16 / 16,
                color: designVariables.labelMenuButton))),
        ]));
  }
}

class _NewDmUserList extends StatelessWidget {
  const _NewDmUserList({
    required this.filteredUsers,
    required this.selectedUserIds,
    required this.onUserTapped,
  });

  final List<User> filteredUsers;
  final Set<int> selectedUserIds;
  final void Function(int userId) onUserTapped;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final isSelected = selectedUserIds.contains(user.userId);

        return InkWell(
          splashFactory: NoSplash.splashFactory,
          onTap: () => onUserTapped(user.userId),
          child: Container(
            decoration: isSelected ? BoxDecoration(
              color: designVariables.bgMenuButtonSelected,
              borderRadius: BorderRadius.circular(10),
            ) : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 12, 6),
              child:Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected
                        ? designVariables.radioFillSelected
                        : designVariables.radioBorder,
                      size: 24)),
                  Avatar(userId: user.userId, size: 32, borderRadius: 3),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(8, 6.5, 0, 6.5),
                      child: Text(user.fullName,
                        style: TextStyle(
                          fontSize: 17,
                          height: 19 / 17,
                          color: designVariables.textMessage)
                        .merge(weightVariableTextStyle(context, wght: 500))))),
                ]))));
      });
  }
}
