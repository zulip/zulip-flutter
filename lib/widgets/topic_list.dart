import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../api/route/channels.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/message_list.dart';
import '../model/narrow.dart';
import 'app_bar.dart';
import 'icons.dart';
import 'message_list.dart';
import 'page.dart';
import 'store.dart';
import 'theme.dart';
import 'unread_count_badge.dart';

class TopicListPage extends StatefulWidget {
  const TopicListPage({
    super.key,
    required this.streamId,
    required this.messageListView,
  });

  final int streamId;
  final MessageListView messageListView;
  static AccountRoute<void> buildRoute({
    int? accountId,
    BuildContext? context,
    required int streamId,
    required MessageListView messageListView,
  }) {
    return MaterialAccountWidgetRoute(
      accountId: accountId,
      context: context,
      page: TopicListPage(streamId: streamId, messageListView: messageListView),
    );
  }

  @override
  State<TopicListPage> createState() => _TopicListPageState();
}

class _TopicListPageState extends State<TopicListPage> with PerAccountStoreAwareStateMixin<TopicListPage> {
  bool _isLoading = true;
  List<GetStreamTopicsEntry> _topics = [];
  List<GetStreamTopicsEntry> _filteredTopics = [];
  MessageListView? _model;

  late TextEditingController _searchController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_filterTopics);
  }

  @override
  void onNewStore() {
    _model = widget.messageListView;
    _model!.addListener(_onMessageListChanged);
    _fetchTopics();
  }

  void _onMessageListChanged() {
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
      final store = PerAccountStoreWidget.of(context);
      final result = await getStreamTopics(
        store.connection,
        streamId: widget.streamId,
      );

      setState(() {
        _topics = result.topics;
        _filterTopics();
        _isLoading = false;
      });
  }

  void _filterTopics() {
    setState(() {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) {
        _filteredTopics = List.from(_topics);
      } else {
        _filteredTopics = _topics
            .where((topic) => topic.name.displayName.toLowerCase().contains(query))
            .toList();
      }

      _filteredTopics.sort((a, b) => b.maxId.compareTo(a.maxId));
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _model?.removeListener(_onMessageListChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final stream = store.streams[widget.streamId];
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return Scaffold(
      appBar: _isSearching
          ? AppBar(
              backgroundColor: designVariables.background,
              title: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: zulipLocalizations.searchTopicsPlaceholder,
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _toggleSearch,
              ),
              actions: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  ),
              ],
            )
          : ZulipAppBar(
              title: Text(stream?.name ?? 'Topics'),
              backgroundColor: designVariables.background,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _toggleSearch,
                  tooltip: zulipLocalizations.searchTopicsPlaceholder,
                ),
              ],
            ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_topics.isEmpty) {
      return const Center(
        child: Text('No topics in this channel'),
      );
    }

    if (_filteredTopics.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Text('No topics matching "${_searchController.text}"'),
      );
    }

    return ListView.builder(
      itemCount: _filteredTopics.length,
      itemBuilder: (context, index) {
        final topic = _filteredTopics[index];
        return _TopicItem(
          streamId: widget.streamId,
          topic: topic.name,
        );
      },
    );
  }
}

class _TopicItem extends StatelessWidget {
  const _TopicItem({
    required this.streamId,
    required this.topic,
  });

  final int streamId;
  final TopicName topic;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final unreads = store.unreads;
    final unreadCount = unreads.countInTopicNarrow(streamId, topic);
    final hasMentions = unreads.mentions.any((id) {
      final message = store.messages[id];
      return message is StreamMessage &&
             message.streamId == streamId &&
             message.topic == topic;
    });
    final isMuted = !store.isTopicVisibleInStream(streamId, topic);

    final designVariables = DesignVariables.of(context);
    final opacity = isMuted ? 0.55 : 1.0;

    return Material(
      color: designVariables.background,
      child: InkWell(
        onTap: () {
          Navigator.push(context,
            MessageListPage.buildRoute(context: context,
              narrow: TopicNarrow(streamId, topic)));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Opacity(
                opacity: opacity,
                child: Icon(
                  ZulipIcons.topic,
                  size: 18,
                  color: designVariables.icon,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Opacity(
                  opacity: opacity,
                  child: Text(
                    topic.displayName,
                    style: TextStyle(
                      fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (isMuted)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    ZulipIcons.mute,
                    size: 16,
                    color: designVariables.icon.withValues(alpha: 0.5),
                  ),
                ),
              if (unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: UnreadCountBadge(
                    count: unreadCount,
                    backgroundColor: null,
                    bold: hasMentions,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}