import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../api/route/channels.dart' as channels_api;
import '../generated/l10n/zulip_localizations.dart';
import '../model/autocomplete.dart';
import '../model/store.dart';
import 'app_bar.dart';
import 'page.dart';
import 'profile.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'user.dart';

class ChannelMembersPage extends StatefulWidget {
  const ChannelMembersPage({super.key, required this.streamId});

  final int streamId;

  static Route<void> buildRoute({
    int? accountId,
    BuildContext? context,
    required int streamId,
  }) {
    return MaterialAccountWidgetRoute(
      accountId: accountId,context: context,
      page: ChannelMembersPage(streamId: streamId),
    );
  }

  @override
  State<ChannelMembersPage> createState() => _ChannelMembersPageState();
}

class _ChannelMembersPageState extends State<ChannelMembersPage>
    with PerAccountStoreAwareStateMixin<ChannelMembersPage> {
  late TextEditingController searchController;
  late ScrollController membersScrollController;

  List<int>? subscriberIds;
  List<int> filteredMembers = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController()..addListener(_handleSearchUpdate);
    membersScrollController = ScrollController();
  }

  @override
  void dispose() {
    searchController.dispose();
    membersScrollController.dispose();
    super.dispose();
  }

  @override
  void onNewStore() {
    _fetchSubscribers();
  }

  Future<void> _fetchSubscribers() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final store = PerAccountStoreWidget.of(context);
      final result = await channels_api.getSubscribers(store.connection, streamId: widget.streamId);
      if (!mounted) return;

      final sorted = _getSortedMembers(store, result.subscribers);
      setState(() {
        subscriberIds = sorted;
        _updateFilteredMembers(store);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        loading = false;
      });
    }
  }

  void _handleSearchUpdate() {
    final store = PerAccountStoreWidget.of(context);
    _updateFilteredMembers(store);
  }

  void _updateFilteredMembers(PerAccountStore store) {
    if (subscriberIds == null) return;

    final normalizedQuery = AutocompleteQuery.lowercaseAndStripDiacritics(
      searchController.text,
    );

    final result = <int>[];
    for (final userId in subscriberIds!) {
      final user = store.getUser(userId);
      if (user == null) continue;

      final normalizedName = AutocompleteQuery.lowercaseAndStripDiacritics(user.fullName);
      final normalizedEmail = AutocompleteQuery.lowercaseAndStripDiacritics(user.email);

      if (normalizedName.contains(normalizedQuery) ||
          normalizedEmail.contains(normalizedQuery)) {
        result.add(userId);
      }
    }

    setState(() {
      filteredMembers = result;
    });

    if (membersScrollController.hasClients) {
      // Jump to the first results for the new query.
      membersScrollController.jumpTo(0);
    }
  }

  List<int> _getSortedMembers(PerAccountStore store, List<int> memberIds) {
    final sorted = List<int>.from(memberIds)
      ..sort((a, b) {
        if (a == store.selfUserId) return -1;
        if (b == store.selfUserId) return 1;
        final userA = store.getUser(a);
        final userB = store.getUser(b);
        if (userA == null || userB == null) return 0;
        return userA.fullName.compareTo(userB.fullName);
      });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final memberCount = subscriberIds?.length ?? 0;

    if (loading) {
      return Scaffold(
        appBar: ZulipAppBar(title: Text("$memberCount members"),centerTitle: true),
        body: const Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: ZulipAppBar(title: Text("$memberCount members"),centerTitle: true),
        body: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage ?? 'Error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchSubscribers,
                child: const Text('Retry')),
            ],
          )));
    }

    return Scaffold(
      appBar: ZulipAppBar(title: Text("$memberCount members"),centerTitle: true),
      body: SafeArea(
        child: Column(children: [
          _MemberSearchBar(controller: searchController),
          Expanded(child: _MemberList(
              filteredMembers: filteredMembers,
              scrollController: membersScrollController)),
        ])));
  }
}

class _MemberSearchBar extends StatelessWidget {
  const _MemberSearchBar({required this.controller});

  final TextEditingController controller;

  Widget _buildSearchField(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return TextField(
      controller: controller,
      autofocus: false,
      cursorColor: designVariables.foreground,
      style: TextStyle(
        color: designVariables.textMessage,
        fontSize: 17,
        height: 22 / 17),
      scrollPadding: EdgeInsets.zero,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: designVariables.bgSearchInput,
        hintText: zulipLocalizations.searchMessagesHintText,   //"search"
        hintStyle: TextStyle(
          color: designVariables.labelSearchPrompt,
          fontSize: 17,
          height: 22 / 17),
        prefixIcon: Icon(Icons.search,color: designVariables.icon),
        suffixIcon: controller.text.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.clear, color: designVariables.icon),
              onPressed: controller.clear,
            )
          : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: _buildSearchField(context),
    );
  }
}

class _MemberList extends StatelessWidget {
  const _MemberList({
    required this.filteredMembers,
    required this.scrollController,
  });

  final List<int> filteredMembers;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    if (filteredMembers.isEmpty) {
      return Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            textAlign: TextAlign.center,
            'No members found',
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
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                final userId = filteredMembers[index];
                return _MemberListItem(userId: userId);
              }))),
      ]));
  }
}

class _MemberListItem extends StatelessWidget {
  const _MemberListItem({required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);
    final user = store.getUser(userId);

    if (user == null) return const SizedBox.shrink();

    final isSelf = userId == store.selfUserId;
    final userStatus = store.getUserStatus(userId);
    final presence = store.presence.presenceStatusForUser(
      userId,
      utcNow: DateTime.now(),
    );

    Color presenceColor;
    switch (presence) {
      case PresenceStatus.active:
        presenceColor = designVariables.statusOnline;
        break;
      case PresenceStatus.idle:
        presenceColor = designVariables.statusIdle;
        break;
      default:
        presenceColor = designVariables.statusAway;
        break;
    }

    return Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(10),
      color: Colors.transparent,
      child: InkWell(
        highlightColor: designVariables.bgMenuButtonSelected,
        splashFactory: NoSplash.splashFactory,
        onTap: () {
          Navigator.push(
              context, ProfilePage.buildRoute(context: context, userId: userId));
        },
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 12, 6),
          child: Row(children: [
            SizedBox(width: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarShape(
                  size: 40,
                  borderRadius: 4,
                  userIdForPresence: userId,
                  backgroundColor: designVariables.background,
                  child: AvatarImage(userId: userId, size: 40),
                ),
                Positioned(
                  right: -2,bottom: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: presenceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: designVariables.background,width: 2),
                    ))),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                      Flexible(child: Text(
                          user.fullName,
                          style: TextStyle(
                            fontSize: 17,
                            height: 19 / 17,
                            color: designVariables.textMessage,
                          ).merge(weightVariableTextStyle(context, wght: 500)),
                          overflow: TextOverflow.ellipsis,
                        )),
                      if (isSelf)
                        Padding(padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '(you)',
                            style: TextStyle(fontSize: 14,color: designVariables.textMessageMuted),
                        )),
                    ],
                  ),
                  SizedBox(height: 2),
                  if (!user.isActive)
                    Text(
                      'Deactivated',
                      style: TextStyle(fontSize: 14,fontStyle: FontStyle.italic,color: designVariables.textMessageMuted))
                  else if (userStatus.text != null || userStatus.emoji != null)
                    Row(children: [
                        Expanded(child: Text.rich(
                            TextSpan(
                              children: [
                                if (userStatus.emoji != null)
                                  UserStatusEmoji.asWidgetSpan(
                                    userId: userId,
                                    fontSize: 14,
                                    textScaler: MediaQuery.textScalerOf(context),
                                    position: StatusEmojiPosition.before,
                                    neverAnimate: false),
                                TextSpan(
                                  text: userStatus.text ?? '',
                                  style: TextStyle(fontSize: 14,color: designVariables.textMessageMuted,
                                )),
                              ]),
                              overflow: TextOverflow.ellipsis,
                          ))],
                    )])),
          ]))));
  }
}