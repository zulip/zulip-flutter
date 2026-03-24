import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../../model/message_list.dart';
import '../../../../../model/narrow.dart';
import '../../../../../model/store.dart';
import '../../../compose_box_block/compose_box_block.dart';
import '../../message_list.dart';
import '../../../../widgets/scrolling.dart';
import '../../../../widgets/sticky_header.dart';
import '../../../../utils/store.dart';
import '../../message_list_block.dart';
import '../buttons/scroll_to_bottom_button.dart';
import '../date_separator.dart';
import '../mark_as_read_widget.dart';
import '../../headers/recipient_header.dart';
import '../typing_status_widget.dart';
import 'empty_message_list_placeholder.dart';
import 'message/message_item.dart';
import 'message_list_history_start.dart';
import 'message_list_loading_more.dart';

/// The message list.
///
/// Takes the full screen width, keeping its contents
/// out of the horizontal insets with transparent [SafeArea] padding.
/// When there is no [ComposeBox], also takes responsibility
/// for dealing with the bottom inset.
class MessageList extends StatefulWidget {
  const MessageList({
    super.key,
    required this.narrow,
    required this.initAnchor,
    required this.onNarrowChanged,
    required this.markReadOnScroll,
  });

  final Narrow narrow;
  final Anchor initAnchor;
  final void Function(Narrow newNarrow) onNarrowChanged;
  final bool? markReadOnScroll;

  @override
  State<StatefulWidget> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList>
    with PerAccountStoreAwareStateMixin<MessageList> {
  final GlobalKey _scrollViewKey = GlobalKey();

  MessageListView get model => _model!;
  MessageListView? _model;

  final MessageListScrollController scrollController =
      MessageListScrollController();

  final ValueNotifier<bool> _scrollToBottomVisible = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollChanged);
  }

  @override
  void onNewStore() {
    // TODO(#464) try to keep using old model until new one gets messages
    final anchor = _model == null ? widget.initAnchor : _model!.anchor;
    _model?.dispose();
    _initModel(PerAccountStoreWidget.of(context), anchor);
  }

  @override
  void dispose() {
    _model?.dispose();
    scrollController.dispose();
    _scrollToBottomVisible.dispose();
    super.dispose();
  }

  void _initModel(PerAccountStore store, Anchor anchor) {
    var narrow = widget.narrow;
    if (narrow is TopicNarrow) {
      // Normalize topic name.  See #1717.
      narrow = TopicNarrow(
        narrow.streamId,
        store.processTopicLikeServer(narrow.topic),
        with_: narrow.with_,
      );
      if (narrow != widget.narrow) {
        SchedulerBinding.instance.scheduleFrameCallback((_) {
          widget.onNarrowChanged(narrow);
        });
      }
    }
    _model = MessageListView.init(store: store, narrow: narrow, anchor: anchor);
    model.addListener(_modelChanged);
    model.fetchInitial();
  }

  bool _prevFetched = false;

  void _modelChanged() {
    // When you're scrolling quickly, our mark-as-read requests include the
    // messages *between* _messagesRecentlyInViewport and the messages currently
    // in view, so that messages don't get left out because you were scrolling
    // so fast that they never rendered onscreen.
    //
    // Here, the onscreen messages might be totally different,
    // and not because of scrolling; e.g. because the narrow changed.
    // Avoid "filling in" a mark-as-read request with totally wrong messages,
    // by forgetting the old range.
    _messagesRecentlyInViewport = null;

    if (model.narrow != widget.narrow) {
      // Either:
      // - A message move event occurred, where propagate mode is
      //   [PropagateMode.changeAll] or [PropagateMode.changeLater]. Or:
      // - We fetched a "with" / topic-permalink narrow, and the response
      //   redirected us to the new location of the operand message ID.
      widget.onNarrowChanged(model.narrow);
    }
    // TODO when model reset, reset scroll
    setState(() {
      // The actual state lives in the [MessageListView] model.
      // This method was called because that just changed.
    });

    if (!_prevFetched && model.fetched && model.messages.isEmpty) {
      // If the fetch came up empty, there's nothing to read,
      // so opening the keyboard won't be bothersome and could be helpful.
      // It's definitely helpful if we got here from the new-DM page.
      MessageListBlockPage.ancestorOf(
        context,
      ).composeBoxState?.controller.requestFocusIfUnfocused();
    }
    _prevFetched = model.fetched;
  }

  /// Find the range of message IDs on screen, as a (first, last) tuple,
  /// or null if no messages are onscreen.
  ///
  /// A message is considered onscreen if its bottom edge is in the viewport.
  ///
  /// Ignores outbox messages.
  (int, int)? _findMessagesInViewport() {
    final scrollViewElement = _scrollViewKey.currentContext as Element;
    final scrollViewRenderObject = scrollViewElement.renderObject as RenderBox;

    int? first;
    int? last;
    void visit(Element element) {
      final widget = element.widget;
      switch (widget) {
        case RecipientHeader():
        case DateSeparator():
        case MarkAsReadWidget():
          // MessageItems won't be descendants of these
          return;

        case MessageItem(item: MessageListOutboxMessageItem()):
          return; // ignore outbox

        case MessageItem(item: MessageListMessageItem(:final message)):
          final isInViewport = _isMessageItemInViewport(
            element,
            scrollViewRenderObject: scrollViewRenderObject,
          );
          if (isInViewport) {
            if (first == null) {
              assert(last == null);
              first = message.id;
              last = message.id;
              return;
            }
            if (message.id < first!) {
              first = message.id;
            }
            if (last! < message.id) {
              last = message.id;
            }
          }
          return; // no need to look for more MessageItems inside this one

        default:
          element.visitChildElements(visit);
      }
    }

    scrollViewElement.visitChildElements(visit);

    if (first == null) {
      assert(last == null);
      return null;
    }
    return (first!, last!);
  }

  bool _isMessageItemInViewport(
    Element element, {
    required RenderBox scrollViewRenderObject,
  }) {
    assert(
      element.widget is MessageItem &&
          (element.widget as MessageItem).item is MessageListMessageItem,
    );
    final viewportHeight = scrollViewRenderObject.size.height;

    final messageRenderObject = element.renderObject as RenderBox;

    final messageBottom = messageRenderObject
        .localToGlobal(
          Offset(0, messageRenderObject.size.height),
          ancestor: scrollViewRenderObject,
        )
        .dy;

    return 0 < messageBottom && messageBottom <= viewportHeight;
  }

  (int, int)? _messagesRecentlyInViewport;

  void _markReadFromScroll() {
    final currentRange = _findMessagesInViewport();
    if (currentRange == null) return;

    final (currentFirst, currentLast) = currentRange;
    final (prevFirst, prevLast) = _messagesRecentlyInViewport ?? (null, null);

    // ("Hull" as in the "convex hull" around the old and new ranges.)
    final firstOfHull = switch ((prevFirst, currentFirst)) {
      (int previous, int current) => previous < current ? previous : current,
      (_, int current) => current,
    };

    final lastOfHull = switch ((prevLast, currentLast)) {
      (int previous, int current) => previous > current ? previous : current,
      (_, int current) => current,
    };

    final sublist = model.getMessagesRange(firstOfHull, lastOfHull);
    if (sublist == null) {
      _messagesRecentlyInViewport = null;
      return;
    }
    model.store.markReadFromScroll(sublist.map((message) => message.id));

    _messagesRecentlyInViewport = currentRange;
  }

  bool _effectiveMarkReadOnScroll() {
    if (!MessageListBlockPage.debugEnableMarkReadOnScroll) return false;
    return widget.markReadOnScroll ??
        GlobalStoreWidget.settingsOf(
          context,
        ).markReadOnScrollForNarrow(widget.narrow);
  }

  void _handleScrollMetrics(ScrollMetrics scrollMetrics) {
    if (_effectiveMarkReadOnScroll()) {
      _markReadFromScroll();
    }

    if (scrollMetrics.extentAfter == 0) {
      _scrollToBottomVisible.value = false;
    } else {
      _scrollToBottomVisible.value = true;
    }

    if (scrollMetrics.extentBefore < kFetchMessagesBufferPixels) {
      // TODO: This ends up firing a second time shortly after we fetch a batch.
      //   The result is that each time we decide to fetch a batch, we end up
      //   fetching two batches in quick succession.  This is basically harmless
      //   but makes things a bit more complicated to reason about.
      //   The cause seems to be that this gets called again with maxScrollExtent
      //   still not yet updated to account for the newly-added messages.
      model.fetchOlder();
    }
    if (scrollMetrics.extentAfter < kFetchMessagesBufferPixels) {
      model.fetchNewer();
    }
  }

  void _scrollChanged() {
    _handleScrollMetrics(scrollController.position);
  }

  bool _handleScrollMetricsNotification(
    ScrollMetricsNotification notification,
  ) {
    if (notification.depth > 0) {
      // This notification came from some Viewport nested more deeply than the
      // one for the message list itself (e.g., from a CodeBlock).  Ignore it.
      return true;
    }

    _handleScrollMetrics(notification.metrics);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!model.fetched) return const Center(child: CircularProgressIndicator());

    if (model.items.isEmpty && model.haveNewest && model.haveOldest) {
      return EmptyMessageListPlaceholder(narrow: widget.narrow);
    }

    // Pad the left and right insets, for small devices in landscape.
    return SafeArea(
      // Don't let this be the place we pad the bottom inset. When there's
      // no compose box, we want to let the message-list content
      // and the scroll-to-bottom button avoid it.
      // TODO(#311) Remove as unnecessary if we do a bottom nav.
      //   The nav will pad the bottom inset, and an ancestor of this widget
      //   will have a `MediaQuery.removePadding` with `removeBottom: true`.
      bottom: false,

      // Horizontally, on wide screens, this Center grows the SafeArea
      // to position its padding over the device insets and centers content.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: _handleScrollMetricsNotification,
            child: Stack(
              children: <Widget>[
                _buildListView(context),
                PositionedDirectional(
                  bottom: 0,
                  end: 0,
                  // TODO(#311) SafeArea shouldn't be needed if we have a
                  //   bottom nav; that will pad the bottom inset. Remove it,
                  //   and the mention of bottom-inset handling in
                  //   MessageList's dartdoc.
                  child: SafeArea(
                    child: ScrollToBottomButton(
                      model: model,
                      scrollController: scrollController,
                      visible: _scrollToBottomVisible,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    const centerSliverKey = ValueKey('center sliver');

    // The list has two slivers: a top sliver growing upward,
    // and a bottom sliver growing downward.
    // Each sliver has some of the items from `model.items`.
    final totalItems = model.items.length;
    final topItems = model.middleItem;
    final bottomItems = totalItems - topItems;

    // The top sliver has its child 0 as the item just before the
    // sliver boundary, child 1 as the item before that, and so on.
    Widget topSliver = SliverStickyHeaderList(
      headerPlacement: HeaderPlacement.scrollingStart,
      delegate: SliverChildBuilderDelegate(
        // To preserve state across rebuilds for individual [MessageItem]
        // widgets as the size of [MessageListView.items] changes we need
        // to match old widgets by their key to their new position in
        // the list.
        //
        // The keys are of type [ValueKey] with a value of [Message.id]
        // and here we use a O(log n) binary search method. This could
        // be improved but for now it only triggers for materialized
        // widgets. As a simple test, flinging through Combined feed in
        // CZO on a Pixel 5, this only runs about 10 times per rebuild
        // and the timing for each call is <100 microseconds.
        //
        // Non-message items (e.g., start and end markers) that do not
        // have state that needs to be preserved have not been given keys
        // and will not trigger this callback.
        findChildIndexCallback: (Key key) {
          final messageId = (key as ValueKey<int>).value;
          final itemIndex = model.findItemWithMessageId(messageId);
          if (itemIndex == -1) return null;
          final childIndex = totalItems - 1 - (itemIndex + bottomItems);
          if (childIndex < 0) return null;
          return childIndex;
        },
        childCount: topItems + 1,
        (context, childIndex) {
          if (childIndex == topItems) return _buildStartCap();

          final itemIndex = totalItems - 1 - (childIndex + bottomItems);
          final data = model.items[itemIndex];
          final item = _buildItem(
            data,
            isLastInFeed: itemIndex == totalItems - 1,
          );
          return item;
        },
      ),
    );

    // The bottom sliver has its child 0 as the item just after the
    // sliver boundary (just after child 0 of the top sliver),
    // its child 1 as the next item after that, and so on.
    Widget bottomSliver = SliverStickyHeaderList(
      key: centerSliverKey,
      headerPlacement: HeaderPlacement.scrollingStart,
      delegate: SliverChildBuilderDelegate(
        // To preserve state across rebuilds for individual [MessageItem]
        // widgets as the size of [MessageListView.items] changes we need
        // to match old widgets by their key to their new position in
        // the list.
        //
        // The keys are of type [ValueKey] with a value of [Message.id]
        // and here we use a O(log n) binary search method. This could
        // be improved but for now it only triggers for materialized
        // widgets. As a simple test, flinging through All Messages in
        // CZO on a Pixel 5, this only runs about 10 times per rebuild
        // and the timing for each call is <100 microseconds.
        //
        // Non-message items (e.g., start and end markers) that do not
        // have state that needs to be preserved have not been given keys
        // and will not trigger this callback.
        findChildIndexCallback: (Key key) {
          final messageId = (key as ValueKey<int>).value;
          final itemIndex = model.findItemWithMessageId(messageId);
          if (itemIndex == -1) return null;
          final childIndex = itemIndex - topItems;
          if (childIndex < 0) return null;
          return childIndex;
        },
        childCount: bottomItems + 1,
        (context, childIndex) {
          if (childIndex == bottomItems) return _buildEndCap();

          final itemIndex = topItems + childIndex;
          final data = model.items[itemIndex];
          return _buildItem(data, isLastInFeed: itemIndex == totalItems - 1);
        },
      ),
    );

    if (!ComposeBoxBlock.hasComposeBox(widget.narrow)) {
      // TODO(#311) If we have a bottom nav, it will pad the bottom inset,
      //   and this can be removed; also remove mention in MessageList dartdoc
      bottomSliver = SliverSafeArea(
        key: bottomSliver.key,
        sliver: bottomSliver,
      );
      topSliver = MediaQuery.removePadding(
        context: context,
        // In the top sliver, forget the bottom inset;
        // we're having the bottom sliver take care of it.
        removeBottom: true,
        // (Also forget the left and right insets; the outer SafeArea, above,
        // does that, but the `context` we're passing to this `removePadding`
        // is from outside that SafeArea, so we need to repeat it.)
        removeLeft: true,
        removeRight: true,
        child: topSliver,
      );
    }

    return MessageListScrollView(
      key: _scrollViewKey,

      // TODO: Offer `ScrollViewKeyboardDismissBehavior.interactive` (or
      //   similar) if that is ever offered:
      //     https://github.com/flutter/flutter/issues/57609#issuecomment-1355340849
      keyboardDismissBehavior: switch (Theme.of(context).platform) {
        // This seems to offer the only built-in way to close the keyboard
        // on iOS. It's not ideal; see TODO above.
        TargetPlatform.iOS => ScrollViewKeyboardDismissBehavior.onDrag,
        // The Android keyboard seems to have a built-in close button.
        _ => ScrollViewKeyboardDismissBehavior.manual,
      },

      controller: scrollController,
      semanticChildCount:
          totalItems, // TODO(#537): what's the right value for this?
      center: centerSliverKey,
      paintOrder: SliverPaintOrder.firstIsTop,

      slivers: [topSliver, bottomSliver],
    );
  }

  Widget _buildStartCap() {
    // If we're done fetching older messages, show that.
    // Else if we're busy with fetching, then show a loading indicator.
    //
    // This applies even if the fetch is over, but failed, and we're still
    // in backoff from it; and even if the fetch is/was for the other direction.
    // The loading indicator really means "busy, working on it"; and that's the
    // right summary even if the fetch is internally queued behind other work.
    return model.haveOldest
        ? const MessageListHistoryStart()
        : model.busyFetchingMore
        ? const MessageListLoadingMore()
        : const SizedBox.shrink();
  }

  Widget _buildEndCap() {
    if (model.haveNewest) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TypingStatusWidget(narrow: widget.narrow),
          // TODO perhaps offer mark-as-read even when not done fetching?
          MarkAsReadWidget(narrow: widget.narrow),
          // To reinforce that the end of the feed has been reached:
          //   https://chat.zulip.org/#narrow/channel/48-mobile/topic/space.20at.20end.20of.20thread/near/2203391
          const SizedBox(height: 12),
        ],
      );
    } else if (model.busyFetchingMore) {
      // See [_buildStartCap] for why this condition shows a loading indicator.
      return const MessageListLoadingMore();
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildItem(MessageListItem data, {required bool isLastInFeed}) {
    switch (data) {
      case MessageListRecipientHeaderItem():
        final header = RecipientHeader(
          message: data.message,
          narrow: widget.narrow,
        );
        return StickyHeaderItem(
          allowOverflow: true,
          header: header,
          child: header,
        );
      case MessageListDateSeparatorItem():
        final header = RecipientHeader(
          message: data.message,
          narrow: widget.narrow,
        );
        return StickyHeaderItem(
          allowOverflow: true,
          header: header,
          child: DateSeparator(message: data.message),
        );
      case MessageListMessageItem():
        final header = RecipientHeader(
          message: data.message,
          narrow: widget.narrow,
        );
        return MessageItem(
          key: ValueKey(data.message.id),
          narrow: widget.narrow,
          header: header,
          isLastInFeed: isLastInFeed,
          item: data,
        );
      case MessageListOutboxMessageItem():
        final header = RecipientHeader(
          message: data.message,
          narrow: widget.narrow,
        );
        return MessageItem(
          narrow: widget.narrow,
          header: header,
          isLastInFeed: isLastInFeed,
          item: data,
        );
    }
  }
}
