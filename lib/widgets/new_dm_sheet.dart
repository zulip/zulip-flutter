import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/narrow.dart';
import '../model/store.dart';
import 'color.dart';
import 'content.dart';
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
        child: NewDmPicker(pageContext: context),
      ),
    ),
  );
}

class NewDmPicker extends StatefulWidget {
  const NewDmPicker({
    super.key,
    required this.pageContext,
  });

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
    searchController = TextEditingController()
    ..addListener(_handleSearchUpdate);
    scrollController = ScrollController();
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
      filteredUsers = store.users.values.where((user) =>
        user.userId != store.selfUserId &&
        user.fullName.toLowerCase().contains(searchController.text.toLowerCase())
      ).toList()
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
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.95,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chevron_left,
                        size: 24,
                        color: designVariables.icon,
                      ),
                      Text(
                        zulipLocalizations.newDmSheetBackButtonLabel,
                        style: TextStyle(
                          fontSize: 20,
                          color: designVariables.icon,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(zulipLocalizations.newDmSheetScreenTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: selectedUserIds.isEmpty ? null : () {
                    final narrow = DmNarrow.withOtherUsers(
                      selectedUserIds,
                      selfUserId: store.selfUserId,
                    );
                    Navigator.pop(context);
                    Navigator.push(context,
                    MessageListPage.buildRoute(
                      context: context,
                      narrow: narrow
                    ));
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        zulipLocalizations.newDmSheetNextButtonLabel,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: selectedUserIds.isEmpty
                            ? designVariables.icon.withFadedAlpha(0.5)
                            : designVariables.icon,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: selectedUserIds.isEmpty
                          ? designVariables.icon.withFadedAlpha(0.5)
                          : designVariables.icon,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            constraints: const BoxConstraints(
              minHeight: 44,
              maxHeight: 124,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: designVariables.bgSearchInput,
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...selectedUserIds.map((userId) {
                          final user = store.users[userId]!;
                          return Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: designVariables.bgMenuButtonSelected,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Avatar(userId: userId, size: 22, borderRadius: 3),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    user.fullName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: designVariables.labelMenuButton
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        SizedBox(
                          width: double.infinity,
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: zulipLocalizations.newDmSheetSearchHint,
                              hintStyle: TextStyle(
                                fontSize: 17,
                                color: designVariables.textInput.withFadedAlpha(0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 11),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                final isSelected = selectedUserIds.contains(user.userId);

                return ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                        color: isSelected
                          ? designVariables.icon
                          : null,
                      ),
                      const SizedBox(width: 8),
                      Avatar(userId: user.userId, size: 32, borderRadius: 3,),
                    ],
                  ),
                  title: Text(user.fullName),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedUserIds.remove(user.userId);
                      } else {
                        selectedUserIds.add(user.userId);
                      }
                      scrollToSearchField();
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
