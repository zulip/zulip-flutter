import 'package:flutter/material.dart';

import '../model/narrow.dart';
import '../model/recent_dm_conversations.dart';
import 'content.dart';
import 'icons.dart';
import 'message_list.dart';
import 'page.dart';
import 'store.dart';
import 'text.dart';

class RecentDmConversationsPage extends StatefulWidget {
  const RecentDmConversationsPage({super.key});

  static Route<void> buildRoute({required BuildContext context}) {
    return MaterialAccountWidgetRoute(context: context,
      page: const RecentDmConversationsPage());
  }

  @override
  State<RecentDmConversationsPage> createState() => _RecentDmConversationsPageState();
}

class _RecentDmConversationsPageState extends State<RecentDmConversationsPage> with PerAccountStoreAwareStateMixin<RecentDmConversationsPage> {
  RecentDmConversationsView? model;

  @override
  void onNewStore() {
    model?.removeListener(_modelChanged);
    model = PerAccountStoreWidget.of(context).recentDmConversationsView
      ..addListener(_modelChanged);
  }

  void _modelChanged() {
    setState(() {
      // The actual state lives in [model].
      // This method was called because that just changed.
    });
  }

  @override
  Widget build(BuildContext context) {
    final sorted = model!.sorted;
    return Scaffold(
      appBar: AppBar(title: const Text('Direct messages')),
      body: ListView.builder(
        itemCount: sorted.length,
        itemBuilder: (context, index) => RecentDmConversationsItem(narrow: sorted[index])));
  }
}

class RecentDmConversationsItem extends StatelessWidget {
  const RecentDmConversationsItem({super.key, required this.narrow});

  final DmNarrow narrow;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final selfUser = store.users[store.account.userId]!;

    final String title;
    final Widget avatar;
    switch (narrow.otherRecipientIds) {
      case []:
        title = selfUser.fullName;
        avatar = AvatarImage(userId: selfUser.userId);
      case [var otherUserId]:
        final otherUser = store.users[otherUserId];
        title = otherUser?.fullName ?? '(unknown user)';
        avatar = AvatarImage(userId: otherUserId);
      default:
        // TODO(i18n): List formatting, like you can do in JavaScript:
        //   new Intl.ListFormat('ja').format(['Chris', 'Greg', 'Alya'])
        //   // 'Chris、Greg、Alya'
        title = narrow.otherRecipientIds.map((id) => store.users[id]?.fullName ?? '(unknown user)').join(', ');
        avatar = ColoredBox(color: const Color(0x33808080),
          child: Center(
            child: Icon(ZulipIcons.group_dm, color: Colors.black.withOpacity(0.5))));
    }

    return InkWell(
      onTap: () {
        Navigator.push(context,
          MessageListPage.buildRoute(context: context, narrow: narrow));
      },
      child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 48),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Padding(padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 0, 8),
            child: AvatarShape(size: 32, borderRadius: 3, child: avatar)),
          const SizedBox(width: 8),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              style: const TextStyle(
                fontFamily: 'Source Sans 3',
                fontSize: 17,
                height: (20 / 17),
                color: Color(0xFF222222),
              ).merge(weightVariableTextStyle(context)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              title))),
          const SizedBox(width: 8),
          // TODO(#253): Unread count
        ])));
  }
}
