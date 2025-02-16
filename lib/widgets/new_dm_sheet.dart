import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/narrow.dart';
import '../model/store.dart';
import 'color.dart';
import 'content.dart';
import 'icons.dart';
import 'message_list.dart';
import 'store.dart';
import 'theme.dart';

void showNewDmSheet(BuildContext context) {
  final store = PerAccountStoreWidget.of(context);
  showModalBottomSheet<dynamic>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) => SafeArea(
      child: PerAccountStoreWidget(
        accountId: store.accountId,
        child: NewDmPicker(pageContext: context)))); }

class NewDmPicker extends StatefulWidget {
  const NewDmPicker({
    super.key,
    required this.pageContext});

  final BuildContext pageContext;

  @override
  State<NewDmPicker> createState() => _NewDmPickerState();
}

class _NewDmPickerState extends State<NewDmPicker> with PerAccountStoreAwareStateMixin<NewDmPicker> {
  late TextEditingController searchController;
  late ScrollController scrollController;
  final Set<int> selectedUserIds = {};
  List<User> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController()..addListener(_handleSearchUpdate);
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  void onNewStore() {
    final store = PerAccountStoreWidget.of(context);
    _updateFilteredUsers(store);
  }

  void _handleSearchUpdate() {
    final store = PerAccountStoreWidget.of(context);
    _updateFilteredUsers(store);
  }

  // function to sort users based on recency of DM's
  void _updateFilteredUsers(PerAccountStore store) {
    setState(() {
      filteredUsers = store.users.values
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

  // Scroll to the search field when the user selects a user
  void scrollToSearchField() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.95,
      child: Column(children: [
        NewDmHeader(
          selectedUserIds: selectedUserIds,
          onClose: () => Navigator.pop(context)),
        NewDmSearchBar(
          searchController: searchController,
          scrollController: scrollController,
          selectedUserIds: selectedUserIds),
        Expanded(child: NewDmUserList(
          filteredUsers: filteredUsers,
          selectedUserIds: selectedUserIds,
          onUserSelected: (userId) {
            setState(() {
              if (selectedUserIds.contains(userId)) {
                selectedUserIds.remove(userId);
              } else {
                selectedUserIds.add(userId);
              }
              scrollToSearchField();
            });
          }))]));
  }
}

class NewDmHeader extends StatelessWidget {
  const NewDmHeader({
    super.key,
    required this.selectedUserIds,
    required this.onClose});

  final Set<int> selectedUserIds;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBackButton(context, designVariables, zulipLocalizations),
          Text(zulipLocalizations.newDmSheetScreenTitle,
            style: TextStyle(color: designVariables.title,fontSize: 20, fontWeight: FontWeight.w600)),
          _buildNextButton(context, store, designVariables, zulipLocalizations)]));
  }

  Widget _buildBackButton(BuildContext context, DesignVariables designVariables,
      ZulipLocalizations zulipLocalizations) => TextButton(
    onPressed: onClose,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ZulipIcons.chevron_left, size: 24, color: designVariables.icon),
        Text(zulipLocalizations.newDmSheetBackButtonLabel,
          style: TextStyle(fontSize: 20, color: designVariables.icon))]));

  Widget _buildNextButton(BuildContext context, PerAccountStore store,
      DesignVariables designVariables, ZulipLocalizations zulipLocalizations) => TextButton(
    onPressed: selectedUserIds.isEmpty ? null : () {
      final narrow = DmNarrow.withOtherUsers(
        selectedUserIds,
        selfUserId: store.selfUserId);
      Navigator.pop(context);
      Navigator.push(context, MessageListPage.buildRoute(
        context: context,
        narrow: narrow));
    },
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(zulipLocalizations.newDmSheetNextButtonLabel,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: selectedUserIds.isEmpty
              ? designVariables.icon.withFadedAlpha(0.5)
              : designVariables.icon)),
        Icon(ZulipIcons.chevron_right,
          size: 24,
          color: selectedUserIds.isEmpty
            ? designVariables.icon.withFadedAlpha(0.5)
            : designVariables.icon)]));
}

class NewDmSearchBar extends StatelessWidget {
  const NewDmSearchBar({
    super.key,
    required this.searchController,
    required this.scrollController,
    required this.selectedUserIds});

  final TextEditingController searchController;
  final ScrollController scrollController;
  final Set<int> selectedUserIds;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints(
        minHeight: 44,
        maxHeight: 124),
      padding: const EdgeInsets.symmetric(horizontal: 14,vertical:11),
      decoration: BoxDecoration(color: designVariables.bgSearchInput),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Row(children: [
          Expanded(child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...selectedUserIds.map((userId) => SelectedUserChip(userId: userId)),
              _buildSearchField(designVariables, zulipLocalizations)]))])));
  }

  Widget _buildSearchField(DesignVariables designVariables,
      ZulipLocalizations zulipLocalizations) => IntrinsicWidth(
        child: SizedBox(
          height: 22,
          child: TextField(
            controller: searchController,
            cursorColor: designVariables.foreground,
            style: const TextStyle(
              fontSize: 17,
              height: 1.0,
            ),
            scrollPadding: EdgeInsets.zero,
            decoration: InputDecoration(
              hintText: zulipLocalizations.newDmSheetSearchHint,
              hintStyle: TextStyle(
                fontSize: 17,
                height: 1.0,
                color: designVariables.textInput.withFadedAlpha(0.5)),
              border: InputBorder.none,
            ))));
}

class SelectedUserChip extends StatelessWidget {
  const SelectedUserChip({
    super.key,
    required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final store = PerAccountStoreWidget.of(context);
    final user = store.users[userId]!;

    return Container(
      height: 22,
      decoration: BoxDecoration(color: designVariables.bgMenuButtonSelected, borderRadius: BorderRadius.circular(3)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Avatar(userId: userId, size: 22, borderRadius: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: Text(user.fullName,
              style: TextStyle(
                fontSize: 16,
                height: 1.0,
                color: designVariables.labelMenuButton)))]));
  }
}

class NewDmUserList extends StatelessWidget {
  const NewDmUserList({
    super.key,
    required this.filteredUsers,
    required this.selectedUserIds,
    required this.onUserSelected});

  final List<User> filteredUsers;
  final Set<int> selectedUserIds;
  final void Function(int) onUserSelected;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final isSelected = selectedUserIds.contains(user.userId);

        return InkWell(
          onTap: () => onUserSelected(user.userId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: isSelected ? BoxDecoration(
                color: designVariables.bgMenuButtonSelected,
                borderRadius: BorderRadius.circular(10),
              ) : null,
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? designVariables.radioFillSelected : designVariables.radioBorder,
                    size: 24),
                  const SizedBox(width: 10),
                  Avatar(userId: user.userId, size: 32, borderRadius: 3),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(user.fullName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: designVariables.textMessage)))]))));});
  }
}