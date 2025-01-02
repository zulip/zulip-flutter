import 'package:flutter/material.dart';

import '../model/narrow.dart';
import '../model/recent_dm_conversations.dart';
import '../model/unreads.dart';
import 'content.dart';
import 'icons.dart';
import 'message_list.dart';
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
    final sorted = model!.sorted;

    final designVariables = DesignVariables.of(context);

    if (sorted.isEmpty) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 124, // Set the desired width
                      height: 112, // Set the desired height
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
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(137, 48), // Adjust button size
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    backgroundColor: designVariables.newDmButtonBg,
                  ),
                  onPressed: () {
                    // Add functionality here
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'New DM',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
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
      child: ListView.builder(
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final narrow = sorted[index];
          return RecentDmConversationsItem(
            narrow: narrow,
            unreadCount: unreadsModel!.countInDmNarrow(narrow),
          );
        }));
    }
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
        title = otherUser?.fullName ?? '(unknown user)';
        avatar = AvatarImage(userId: otherUserId, size: _avatarSize);
      default:
        // TODO(i18n): List formatting, like you can do in JavaScript:
        //   new Intl.ListFormat('ja').format(['Chris', 'Greg', 'Alya'])
        //   // 'Chris、Greg、Alya'
        title = narrow.otherRecipientIds.map((id) => store.users[id]?.fullName ?? '(unknown user)').join(', ');
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
