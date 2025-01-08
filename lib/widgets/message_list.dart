import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color_models/flutter_color_models.dart';
import 'package:intl/intl.dart';

import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/message_list.dart';
import '../model/narrow.dart';
import '../model/store.dart';
import '../model/typing_status.dart';
import 'action_sheet.dart';
import 'actions.dart';
import 'app_bar.dart';
import 'compose_box.dart';
import 'content.dart';
import 'emoji_reaction.dart';
import 'icons.dart';
import 'page.dart';
import 'profile.dart';
import 'sticky_header.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';

/// Message-list styles that differ between light and dark themes.
class MessageListTheme extends ThemeExtension<MessageListTheme> {
  MessageListTheme.light() :
    this._(
      dateSeparator: Colors.black,
      dateSeparatorText: const HSLColor.fromAHSL(0.75, 0, 0, 0.15).toColor(),
      dmRecipientHeaderBg: const HSLColor.fromAHSL(1, 46, 0.35, 0.93).toColor(),
      messageTimestamp: const HSLColor.fromAHSL(0.8, 0, 0, 0.2).toColor(),
      recipientHeaderText: const HSLColor.fromAHSL(1, 0, 0, 0.15).toColor(),
      senderBotIcon: const HSLColor.fromAHSL(1, 180, 0.08, 0.65).toColor(),
      senderName: const HSLColor.fromAHSL(1, 0, 0, 0.2).toColor(),
      streamMessageBgDefault: Colors.white,
      streamRecipientHeaderChevronRight: Colors.black.withValues(alpha: 0.3),

      // From the Figma mockup at:
      //   https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=132-9684
      // See discussion about design at:
      //   https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20unread.20marker/near/1658008
      // (Web uses a left-to-right gradient from hsl(217deg 64% 59%) to transparent,
      // in both light and dark theme.)
      unreadMarker: const HSLColor.fromAHSL(1, 227, 0.78, 0.59).toColor(),

      unreadMarkerGap: Colors.white.withValues(alpha: 0.6),

      // TODO(design) this seems ad-hoc; is there a better color?
      unsubscribedStreamRecipientHeaderBg: const Color(0xfff5f5f5),
    );

  MessageListTheme.dark() :
    this._(
      dateSeparator: Colors.white,
      dateSeparatorText: const HSLColor.fromAHSL(0.75, 0, 0, 1).toColor(),
      dmRecipientHeaderBg: const HSLColor.fromAHSL(1, 46, 0.15, 0.2).toColor(),
      messageTimestamp: const HSLColor.fromAHSL(0.8, 0, 0, 0.85).toColor(),
      recipientHeaderText: const HSLColor.fromAHSL(0.8, 0, 0, 1).toColor(),
      senderBotIcon: const HSLColor.fromAHSL(1, 180, 0.05, 0.5).toColor(),
      senderName: const HSLColor.fromAHSL(0.85, 0, 0, 1).toColor(),
      streamMessageBgDefault: const HSLColor.fromAHSL(1, 0, 0, 0.15).toColor(),
      streamRecipientHeaderChevronRight: Colors.white.withValues(alpha: 0.3),

      // 0.75 opacity from here:
      //   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=807-33998&m=dev
      // Discussion, some weeks after the discussion linked on the light variant:
      //   https://github.com/zulip/zulip-flutter/pull/317#issuecomment-1784311663
      // where Vlad includes screenshots that look like they're from there.
      unreadMarker: const HSLColor.fromAHSL(0.75, 227, 0.78, 0.59).toColor(),

      unreadMarkerGap: Colors.transparent,

      // TODO(design) this is ad-hoc and untested; is there a better color?
      unsubscribedStreamRecipientHeaderBg: const Color(0xff0a0a0a),
    );

  MessageListTheme._({
    required this.dateSeparator,
    required this.dateSeparatorText,
    required this.dmRecipientHeaderBg,
    required this.messageTimestamp,
    required this.recipientHeaderText,
    required this.senderBotIcon,
    required this.senderName,
    required this.streamMessageBgDefault,
    required this.streamRecipientHeaderChevronRight,
    required this.unreadMarker,
    required this.unreadMarkerGap,
    required this.unsubscribedStreamRecipientHeaderBg,
  });

  /// The [MessageListTheme] from the context's active theme.
  ///
  /// The [ThemeData] must include [MessageListTheme] in [ThemeData.extensions].
  static MessageListTheme of(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<MessageListTheme>();
    assert(extension != null);
    return extension!;
  }

  final Color dateSeparator;
  final Color dateSeparatorText;
  final Color dmRecipientHeaderBg;
  final Color messageTimestamp;
  final Color recipientHeaderText;
  final Color senderBotIcon;
  final Color senderName;
  final Color streamMessageBgDefault;
  final Color streamRecipientHeaderChevronRight;
  final Color unreadMarker;
  final Color unreadMarkerGap;
  final Color unsubscribedStreamRecipientHeaderBg;

  @override
  MessageListTheme copyWith({
    Color? dateSeparator,
    Color? dateSeparatorText,
    Color? dmRecipientHeaderBg,
    Color? messageTimestamp,
    Color? recipientHeaderText,
    Color? senderBotIcon,
    Color? senderName,
    Color? streamMessageBgDefault,
    Color? streamRecipientHeaderChevronRight,
    Color? unreadMarker,
    Color? unreadMarkerGap,
    Color? unsubscribedStreamRecipientHeaderBg,
  }) {
    return MessageListTheme._(
      dateSeparator: dateSeparator ?? this.dateSeparator,
      dateSeparatorText: dateSeparatorText ?? this.dateSeparatorText,
      dmRecipientHeaderBg: dmRecipientHeaderBg ?? this.dmRecipientHeaderBg,
      messageTimestamp: messageTimestamp ?? this.messageTimestamp,
      recipientHeaderText: recipientHeaderText ?? this.recipientHeaderText,
      senderBotIcon: senderBotIcon ?? this.senderBotIcon,
      senderName: senderName ?? this.senderName,
      streamMessageBgDefault: streamMessageBgDefault ?? this.streamMessageBgDefault,
      streamRecipientHeaderChevronRight: streamRecipientHeaderChevronRight ?? this.streamRecipientHeaderChevronRight,
      unreadMarker: unreadMarker ?? this.unreadMarker,
      unreadMarkerGap: unreadMarkerGap ?? this.unreadMarkerGap,
      unsubscribedStreamRecipientHeaderBg: unsubscribedStreamRecipientHeaderBg ?? this.unsubscribedStreamRecipientHeaderBg,
    );
  }

  @override
  MessageListTheme lerp(MessageListTheme other, double t) {
    if (identical(this, other)) {
      return this;
    }
    return MessageListTheme._(
      dateSeparator: Color.lerp(dateSeparator, other.dateSeparator, t)!,
      dateSeparatorText: Color.lerp(dateSeparatorText, other.dateSeparatorText, t)!,
      dmRecipientHeaderBg: Color.lerp(streamMessageBgDefault, other.dmRecipientHeaderBg, t)!,
      messageTimestamp: Color.lerp(messageTimestamp, other.messageTimestamp, t)!,
      recipientHeaderText: Color.lerp(recipientHeaderText, other.recipientHeaderText, t)!,
      senderBotIcon: Color.lerp(senderBotIcon, other.senderBotIcon, t)!,
      senderName: Color.lerp(senderName, other.senderName, t)!,
      streamMessageBgDefault: Color.lerp(streamMessageBgDefault, other.streamMessageBgDefault, t)!,
      streamRecipientHeaderChevronRight: Color.lerp(streamRecipientHeaderChevronRight, other.streamRecipientHeaderChevronRight, t)!,
      unreadMarker: Color.lerp(unreadMarker, other.unreadMarker, t)!,
      unreadMarkerGap: Color.lerp(unreadMarkerGap, other.unreadMarkerGap, t)!,
      unsubscribedStreamRecipientHeaderBg: Color.lerp(unsubscribedStreamRecipientHeaderBg, other.unsubscribedStreamRecipientHeaderBg, t)!,
    );
  }
}

/// The interface for the state of a [MessageListPage].
///
/// To obtain one of these, see [MessageListPage.ancestorOf].
abstract class MessageListPageState {
  /// The narrow for this page's message list.
  Narrow get narrow;

  /// The controller for this [MessageListPage]'s compose box,
  /// if this [MessageListPage] offers a compose box.
  ComposeBoxController? get composeBoxController;
}

class MessageListPage extends StatefulWidget {
  const MessageListPage({super.key, required this.initNarrow});

  static Route<void> buildRoute({int? accountId, BuildContext? context,
      required Narrow narrow}) {
    return MaterialAccountWidgetRoute(accountId: accountId, context: context,
      page: MessageListPage(initNarrow: narrow));
  }

  /// The [MessageListPageState] above this context in the tree.
  ///
  /// Uses the inefficient [BuildContext.findAncestorStateOfType];
  /// don't call this in a build method.
  // If we do find ourselves wanting this in a build method, it won't be hard
  // to enable that: we'd just need to add an [InheritedWidget] here.
  static MessageListPageState ancestorOf(BuildContext context) {
    final state = context.findAncestorStateOfType<_MessageListPageState>();
    assert(state != null, 'No MessageListPage ancestor');
    return state!;
  }

  final Narrow initNarrow;

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> implements MessageListPageState {
  @override
  late Narrow narrow;

  @override
  ComposeBoxController? get composeBoxController => _composeBoxKey.currentState?.controller;

  final GlobalKey<ComposeBoxState> _composeBoxKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    narrow = widget.initNarrow;
  }

  void _narrowChanged(Narrow newNarrow) {
    setState(() {
      narrow = newNarrow;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final messageListTheme = MessageListTheme.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final Color? appBarBackgroundColor;
    bool removeAppBarBottomBorder = false;
    switch(narrow) {
      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
        appBarBackgroundColor = null; // i.e., inherit

      case ChannelNarrow(:final streamId):
      case TopicNarrow(:final streamId):
        final subscription = store.subscriptions[streamId];
        appBarBackgroundColor = subscription != null
          ? colorSwatchFor(context, subscription).barBackground
          : messageListTheme.unsubscribedStreamRecipientHeaderBg;
        // All recipient headers will match this color; remove distracting line
        // (but are recipient headers even needed for topic narrows?)
        removeAppBarBottomBorder = true;

      case DmNarrow():
        appBarBackgroundColor = messageListTheme.dmRecipientHeaderBg;
        // All recipient headers will match this color; remove distracting line
        // (but are recipient headers even needed?)
        removeAppBarBottomBorder = true;
    }

    List<Widget>? actions;
    if (narrow case TopicNarrow(:final streamId)) {
      // The helper [_getEffectiveCenterTitle] relies on the fact that we
      // have at most one action here.
      (actions ??= []).add(IconButton(
        icon: const Icon(ZulipIcons.message_feed),
        tooltip: zulipLocalizations.channelFeedButtonTooltip,
        onPressed: () => Navigator.push(context,
          MessageListPage.buildRoute(context: context,
            narrow: ChannelNarrow(streamId)))));
    }

    return Scaffold(
      appBar: ZulipAppBar(
        title: MessageListAppBarTitle(narrow: narrow),
        actions: actions,
        backgroundColor: appBarBackgroundColor,
        shape: removeAppBarBottomBorder
          ? const Border()
          : null, // i.e., inherit
      ),
      // TODO question for Vlad: for a stream view, should we set the Scaffold's
      //   [backgroundColor] based on stream color, as in this frame:
      //     https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=132%3A9684&mode=dev
      //   That's not obviously preferred over the default background that
      //   we matched to the Figma in 21dbae120. See another frame, which uses that:
      //     https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=147%3A9088&mode=dev
      body: Builder(
        builder: (BuildContext context) => Center(
          child: Column(children: [
            MediaQuery.removePadding(
              // Scaffold knows about the app bar, and so has run this
              // BuildContext, which is under `body`, through
              // MediaQuery.removePadding with `removeTop: true`.
              context: context,

              // The compose box, when present, pads the bottom inset.
              // TODO(#311) If we have a bottom nav, it will pad the bottom
              //   inset, and this should always be true.
              removeBottom: ComposeBox.hasComposeBox(narrow),

              child: Expanded(
                child: MessageList(narrow: narrow, onNarrowChanged: _narrowChanged))),
            if (ComposeBox.hasComposeBox(narrow))
              ComposeBox(key: _composeBoxKey, narrow: narrow)
          ]))));
  }
}

class MessageListAppBarTitle extends StatelessWidget {
  const MessageListAppBarTitle({super.key, required this.narrow});

  final Narrow narrow;

  Widget _buildStreamRow(BuildContext context, {
    ZulipStream? stream,
  }) {
    // A null [Icon.icon] makes a blank space.
    final icon = stream != null ? iconDataForStream(stream) : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      // TODO(design): The vertical alignment of the stream privacy icon is a bit ad hoc.
      //   For screenshots of some experiments, see:
      //     https://github.com/zulip/zulip-flutter/pull/219#discussion_r1281024746
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(size: 16, icon),
        const SizedBox(width: 4),
        Flexible(child: Text(stream?.name ?? '(unknown channel)')),
      ]);
  }

  Widget _buildTopicRow(BuildContext context, {
    required ZulipStream? stream,
    required TopicName topic,
  }) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);
    final icon = stream == null ? null
      : iconDataForTopicVisibilityPolicy(
          store.topicVisibilityPolicy(stream.streamId, topic));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(topic.displayName, style: const TextStyle(
          fontSize: 13,
        ).merge(weightVariableTextStyle(context)))),
        if (icon != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: Icon(icon,
              // TODO(design) copies the recipient header in web; is there a better color?
              color: designVariables.colorMessageHeaderIconInteractive, size: 14)),
      ]);
  }

  // TODO(upstream): provide an API for this
  // Adapted from [AppBar._getEffectiveCenterTitle].
  bool _getEffectiveCenterTitle(ThemeData theme) {
    bool platformCenter() {
      switch (theme.platform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          return false;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
        // We rely on the fact that there is at most one action
        // on the message list app bar, so that the expression returned
        // in the original helper, `actions == null || actions!.length < 2`,
        // always evaluates to `true`:
          return true;
      }
    }

    return theme.appBarTheme.centerTitle ?? platformCenter();
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);

    switch (narrow) {
      case CombinedFeedNarrow():
        return Text(zulipLocalizations.combinedFeedPageTitle);

      case MentionsNarrow():
        return Text(zulipLocalizations.mentionsPageTitle);

      case StarredMessagesNarrow():
        return Text(zulipLocalizations.starredMessagesPageTitle);

      case ChannelNarrow(:var streamId):
        final store = PerAccountStoreWidget.of(context);
        final stream = store.streams[streamId];
        return _buildStreamRow(context, stream: stream);

      case TopicNarrow(:var streamId, :var topic):
        final theme = Theme.of(context);
        final store = PerAccountStoreWidget.of(context);
        final stream = store.streams[streamId];
        final centerTitle = _getEffectiveCenterTitle(theme);
        return SizedBox(
          width: double.infinity,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: () => showTopicActionSheet(context,
              channelId: streamId, topic: topic),
            child: Column(
              crossAxisAlignment: centerTitle ? CrossAxisAlignment.center
                                              : CrossAxisAlignment.start,
              children: [
                _buildStreamRow(context, stream: stream),
                _buildTopicRow(context, stream: stream, topic: topic),
              ])));

      case DmNarrow(:var otherRecipientIds):
        final store = PerAccountStoreWidget.of(context);
        if (otherRecipientIds.isEmpty) {
          return const Text("DMs with yourself");
        } else {
          final names = otherRecipientIds.map((id) => store.users[id]?.fullName ?? '(unknown user)');
          return Text("DMs with ${names.join(", ")}"); // TODO show avatars
        }
    }
  }
}

/// The approximate height of a short message in the message list.
const _kShortMessageHeight = 80;

/// The point at which we fetch more history, in pixels from the start or end.
///
/// When the user scrolls to within this distance of the start (or end) of the
/// history we currently have, we make a request to fetch the next batch of
/// older (or newer) messages.
//
// When the user reaches this point, they're at least halfway through the
// previous batch.
const kFetchMessagesBufferPixels = (kMessageListFetchBatchSize / 2) * _kShortMessageHeight;

class MessageList extends StatefulWidget {
  const MessageList({super.key, required this.narrow, required this.onNarrowChanged});

  final Narrow narrow;
  final void Function(Narrow newNarrow) onNarrowChanged;

  @override
  State<StatefulWidget> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> with PerAccountStoreAwareStateMixin<MessageList> {
  MessageListView? model;
  final ScrollController scrollController = ScrollController();
  final ValueNotifier<bool> _scrollToBottomVisibleValue = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollChanged);
  }

  @override
  void onNewStore() { // TODO(#464) try to keep using old model until new one gets messages
    _initModel(PerAccountStoreWidget.of(context));
  }

  @override
  void dispose() {
    model?.dispose();
    scrollController.dispose();
    _scrollToBottomVisibleValue.dispose();
    super.dispose();
  }

  void _initModel(PerAccountStore store) {
    model = MessageListView.init(store: store, narrow: widget.narrow);
    model!.addListener(_modelChanged);
    model!.fetchInitial();
  }

  void _modelChanged() {
    if (model!.narrow != widget.narrow) {
      // A message move event occurred, where propagate mode is
      // [PropagateMode.changeAll] or [PropagateMode.changeLater].
      widget.onNarrowChanged(model!.narrow);
    }
    setState(() {
      // The actual state lives in the [MessageListView] model.
      // This method was called because that just changed.
    });
  }

  void _handleScrollMetrics(ScrollMetrics scrollMetrics) {
    if (scrollMetrics.extentAfter == 0) {
      _scrollToBottomVisibleValue.value = false;
    } else {
      _scrollToBottomVisibleValue.value = true;
    }

    if (scrollMetrics.extentBefore < kFetchMessagesBufferPixels) {
      // TODO: This ends up firing a second time shortly after we fetch a batch.
      //   The result is that each time we decide to fetch a batch, we end up
      //   fetching two batches in quick succession.  This is basically harmless
      //   but makes things a bit more complicated to reason about.
      //   The cause seems to be that this gets called again with maxScrollExtent
      //   still not yet updated to account for the newly-added messages.
      model?.fetchOlder();
    }
  }

  void _scrollChanged() {
    _handleScrollMetrics(scrollController.position);
  }

  bool _handleScrollMetricsNotification(ScrollMetricsNotification notification) {
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
    assert(model != null);
    if (!model!.fetched) return const Center(child: CircularProgressIndicator());

    // Pad the left and right insets, for small devices in landscape.
    return SafeArea(
      // Don't let this be the place we pad the bottom inset. When there's
      // no compose box, we want to let the message-list content pad it.
      // TODO(#311) Remove as unnecessary if we do a bottom nav.
      //   The nav will pad the bottom inset, and an ancestor of this widget
      //   will have a `MediaQuery.removePadding` with `removeBottom: true`.
      bottom: false,

      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: _handleScrollMetricsNotification,
            child: Stack(
              children: <Widget>[
                _buildListView(context),
                Positioned(
                  bottom: 0,
                  right: 0,
                  // TODO(#311) SafeArea shouldn't be needed if we have a
                  //   bottom nav. That will pad the bottom inset.
                  child: SafeArea(
                    child: ScrollToBottomButton(
                      scrollController: scrollController,
                      visibleValue: _scrollToBottomVisibleValue))),
              ])))));
  }

  Widget _buildListView(BuildContext context) {
    final length = model!.items.length;
    const centerSliverKey = ValueKey('center sliver');

    Widget sliver = SliverStickyHeaderList(
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
          final valueKey = key as ValueKey<int>;
          final index = model!.findItemWithMessageId(valueKey.value);
          if (index == -1) return null;
          return length - 1 - (index - 3);
        },
        childCount: length + 3,
        (context, i) {
          // To reinforce that the end of the feed has been reached:
          //   https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20Mark-as-read/near/1680603
          if (i == 0) return const SizedBox(height: 36);

          if (i == 1) return MarkAsReadWidget(narrow: widget.narrow);

          if (i == 2) return TypingStatusWidget(narrow: widget.narrow);

          final data = model!.items[length - 1 - (i - 3)];
          return _buildItem(data, i);
        }));

    if (!ComposeBox.hasComposeBox(widget.narrow)) {
      // TODO(#311) If we have a bottom nav, it will pad the bottom
      //   inset, and this shouldn't be necessary
      sliver = SliverSafeArea(sliver: sliver);
    }

    return CustomScrollView(
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
      semanticChildCount: length + 2,
      anchor: 1.0,
      center: centerSliverKey,

      slivers: [
        sliver,

        // This is a trivial placeholder that occupies no space.  Its purpose is
        // to have the key that's passed to [ScrollView.center], and so to cause
        // the above [SliverStickyHeaderList] to run from bottom to top.
        const SliverToBoxAdapter(key: centerSliverKey),
      ]);
  }

  Widget _buildItem(MessageListItem data, int i) {
    switch (data) {
      case MessageListHistoryStartItem():
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text("No earlier messages."))); // TODO use an icon
      case MessageListLoadingItem():
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: CircularProgressIndicator())); // TODO perhaps a different indicator
      case MessageListRecipientHeaderItem():
        final header = RecipientHeader(message: data.message, narrow: widget.narrow);
        return StickyHeaderItem(allowOverflow: true,
          header: header, child: header);
      case MessageListDateSeparatorItem():
        final header = RecipientHeader(message: data.message, narrow: widget.narrow);
        return StickyHeaderItem(allowOverflow: true,
          header: header,
          child: DateSeparator(message: data.message));
      case MessageListMessageItem():
        final header = RecipientHeader(message: data.message, narrow: widget.narrow);
        return MessageItem(
          key: ValueKey(data.message.id),
          header: header,
          trailingWhitespace: i == 1 ? 8 : 11,
          item: data);
    }
  }
}

class ScrollToBottomButton extends StatelessWidget {
  const ScrollToBottomButton({super.key, required this.scrollController, required this.visibleValue});

  final ValueNotifier<bool> visibleValue;
  final ScrollController scrollController;

  Future<void> _navigateToBottom() {
    final distance = scrollController.position.pixels;
    final durationMsAtSpeedLimit = (1000 * distance / 8000).ceil();
    final durationMs = max(300, durationMsAtSpeedLimit);
    return scrollController.animateTo(
      0,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: visibleValue,
      builder: (BuildContext context, bool value, Widget? child) {
        return (value && child != null) ? child : const SizedBox.shrink();
      },
      // TODO: fix hardcoded values for size and style here
      child: IconButton(
        tooltip: "Scroll to bottom",
        icon: const Icon(Icons.expand_circle_down_rounded),
        iconSize: 40,
        // Web has the same color in light and dark mode.
        color: const HSLColor.fromAHSL(0.5, 240, 0.96, 0.68).toColor(),
        onPressed: _navigateToBottom));
  }
}

class TypingStatusWidget extends StatefulWidget {
  const TypingStatusWidget({super.key, required this.narrow});

  final Narrow narrow;

  @override
  State<StatefulWidget> createState() => _TypingStatusWidgetState();
}

class _TypingStatusWidgetState extends State<TypingStatusWidget> with PerAccountStoreAwareStateMixin<TypingStatusWidget> {
  TypingStatus? model;

  @override
  void onNewStore() {
    model?.removeListener(_modelChanged);
    model = PerAccountStoreWidget.of(context).typingStatus
      ..addListener(_modelChanged);
  }

  @override
  void dispose() {
    model?.removeListener(_modelChanged);
    super.dispose();
  }

  void _modelChanged() {
    setState(() {
      // The actual state lives in [model].
      // This method was called because that just changed.
    });
  }

  @override
  Widget build(BuildContext context) {
    final narrow = widget.narrow;
    if (narrow is! SendableNarrow) return const SizedBox();

    final store = PerAccountStoreWidget.of(context);
    final localizations = ZulipLocalizations.of(context);
    final typistIds = model!.typistIdsInNarrow(narrow);
    if (typistIds.isEmpty) return const SizedBox();
    final text = switch (typistIds.length) {
      1 => localizations.onePersonTyping(
        store.users[typistIds.first]?.fullName ?? localizations.unknownUserName),
      2 => localizations.twoPeopleTyping(
        store.users[typistIds.first]?.fullName ?? localizations.unknownUserName,
        store.users[typistIds.last]?.fullName  ?? localizations.unknownUserName),
      _ => localizations.manyPeopleTyping,
    };

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, top: 2),
      child: Text(text,
        style: const TextStyle(
          // Web has the same color in light and dark mode.
          color: HslColor(0, 0, 53),
          fontStyle: FontStyle.italic)));
  }
}

class MarkAsReadWidget extends StatefulWidget {
  const MarkAsReadWidget({super.key, required this.narrow});

  final Narrow narrow;

  @override
  State<MarkAsReadWidget> createState() => _MarkAsReadWidgetState();
}

class _MarkAsReadWidgetState extends State<MarkAsReadWidget> {
  bool _loading = false;

  void _handlePress(BuildContext context) async {
    if (!context.mounted) return;
    setState(() => _loading = true);
    await markNarrowAsRead(context, widget.narrow);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);
    final unreadCount = store.unreads.countInNarrow(widget.narrow);
    final areMessagesRead = unreadCount == 0;

    final messageListTheme = MessageListTheme.of(context);

    return IgnorePointer(
      ignoring: areMessagesRead,
      child: MarkAsReadAnimation(
        loading: _loading,
        hidden: areMessagesRead,
        child: SizedBox(width: double.infinity,
          // Design referenced from:
          //   https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?type=design&node-id=132-9684&mode=design&t=jJwHzloKJ0TMOG4M-0
          child: Padding(
            // vertical padding adjusted for tap target height (48px) of button
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10 - ((48 - 38) / 2)),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                splashFactory: NoSplash.splashFactory,
                minimumSize: const Size.fromHeight(38),
                textStyle:
                  // Restate [FilledButton]'s default, which inherits from
                  // [zulipTypography]…
                  Theme.of(context).textTheme.labelLarge!
                    // …then clobber some attributes to follow Figma:
                    .merge(TextStyle(
                      fontSize: 18,
                      letterSpacing: proportionalLetterSpacing(context,
                        kButtonTextLetterSpacingProportion, baseFontSize: 18),
                      height: (23 / 18))
                    .merge(weightVariableTextStyle(context, wght: 400))),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              ).copyWith(
                // Give the buttons a constant color regardless of whether their
                // state is disabled, pressed, etc.  We handle those states
                // separately, via MarkAsReadAnimation.
                foregroundColor: const WidgetStatePropertyAll(Colors.white),
                iconColor: const WidgetStatePropertyAll(Colors.white),
                backgroundColor: WidgetStatePropertyAll(messageListTheme.unreadMarker),
              ),
              onPressed: _loading ? null : () => _handlePress(context),
              icon: const Icon(Icons.playlist_add_check),
              label: Text(zulipLocalizations.markAllAsReadLabel))))));
  }
}

class MarkAsReadAnimation extends StatefulWidget {
  final bool loading;
  final bool hidden;
  final Widget child;

  const MarkAsReadAnimation({
    super.key,
    required this.loading,
    required this.hidden,
    required this.child
  });

  @override
  State<MarkAsReadAnimation> createState() => _MarkAsReadAnimationState();
}

class _MarkAsReadAnimationState extends State<MarkAsReadAnimation> {
  bool _isPressed = false;

  void _setIsPressed(bool isPressed) {
    setState(() {
      _isPressed = isPressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setIsPressed(true),
      onTapUp: (_) => _setIsPressed(false),
      onTapCancel: () => _setIsPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: widget.hidden ? 0 : widget.loading ? 0.5 : 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: widget.child)));
  }
}

class RecipientHeader extends StatelessWidget {
  const RecipientHeader({super.key, required this.message, required this.narrow});

  final Message message;
  final Narrow narrow;

  static bool _containsDifferentChannels(Narrow narrow) {
    switch (narrow) {
      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
        return true;

      case ChannelNarrow():
      case TopicNarrow():
      case DmNarrow():
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return switch (message) {
      StreamMessage() => StreamMessageRecipientHeader(message: message,
        showStream: _containsDifferentChannels(narrow)),
      DmMessage() => DmRecipientHeader(message: message),
    };
  }
}

class DateSeparator extends StatelessWidget {
  const DateSeparator({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    // This makes the small-caps text vertically centered,
    // to align with the vertically centered divider lines.
    const textBottomPadding = 2.0;

    final messageListTheme = MessageListTheme.of(context);

    final line = BorderSide(width: 0, color: messageListTheme.dateSeparator);

    // TODO(#681) use different color for DM messages
    return ColoredBox(color: messageListTheme.streamMessageBgDefault,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(children: [
          Expanded(
            child: SizedBox(height: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: line))))),
          Padding(padding: const EdgeInsets.fromLTRB(2, 0, 2, textBottomPadding),
            child: DateText(
              fontSize: 16,
              height: (16 / 16),
              timestamp: message.timestamp)),
          SizedBox(height: 0, width: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: line)))),
        ])),
    );
  }
}

class MessageItem extends StatelessWidget {
  const MessageItem({
    super.key,
    required this.item,
    required this.header,
    this.trailingWhitespace,
  });

  final MessageListMessageItem item;
  final Widget header;
  final double? trailingWhitespace;

  @override
  Widget build(BuildContext context) {
    final message = item.message;
    final messageListTheme = MessageListTheme.of(context);
    return StickyHeaderItem(
      allowOverflow: !item.isLastInBlock,
      header: header,
      child: _UnreadMarker(
        isRead: message.flags.contains(MessageFlag.read),
        child: ColoredBox(
          color: messageListTheme.streamMessageBgDefault,
          child: Column(children: [
            MessageWithPossibleSender(item: item),
            if (trailingWhitespace != null && item.isLastInBlock) SizedBox(height: trailingWhitespace!),
          ]))));
  }
}

/// Widget responsible for showing the read status of a message.
class _UnreadMarker extends StatelessWidget {
  const _UnreadMarker({required this.isRead, required this.child});

  final bool isRead;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final messageListTheme = MessageListTheme.of(context);
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          bottom: 0,
          width: 4,
          child: AnimatedOpacity(
            opacity: isRead ? 0 : 1,
            // Web uses 2s and 0.3s durations, and a CSS ease-out curve.
            // See zulip:web/styles/message_row.css .
            duration: Duration(milliseconds: isRead ? 2000 : 300),
            curve: Curves.easeOut,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: messageListTheme.unreadMarker,
                border: Border(left: BorderSide(
                  width: 1,
                  color: messageListTheme.unreadMarkerGap)))))),
      ]);
  }
}

class StreamMessageRecipientHeader extends StatelessWidget {
  const StreamMessageRecipientHeader({
    super.key,
    required this.message,
    required this.showStream,
  });

  final StreamMessage message;
  final bool showStream;

  @override
  Widget build(BuildContext context) {
    // For design specs, see:
    //   https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=538%3A20849&mode=dev
    //   https://github.com/zulip/zulip-mobile/issues/5511
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);

    final topic = message.topic;

    final messageListTheme = MessageListTheme.of(context);

    final subscription = store.subscriptions[message.streamId];
    final Color backgroundColor;
    final Color iconColor;
    if (subscription != null) {
      final swatch = colorSwatchFor(context, subscription);
      backgroundColor = swatch.barBackground;
      iconColor = swatch.iconOnBarBackground;
    } else {
      backgroundColor = messageListTheme.unsubscribedStreamRecipientHeaderBg;
      iconColor = messageListTheme.recipientHeaderText;
    }

    final Widget streamWidget;
    if (!showStream) {
      streamWidget = const SizedBox(width: 16);
    } else {
      final stream = store.streams[message.streamId];
      final streamName = stream?.name
        ?? message.displayRecipient
        ?? '(unknown channel)'; // TODO(log)

      streamWidget = GestureDetector(
        onTap: () => Navigator.push(context,
          MessageListPage.buildRoute(context: context,
            narrow: ChannelNarrow(message.streamId))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              // Figma specifies 5px horizontal spacing around an icon that's
              // 18x18 and includes 1px padding.  The icon SVG is flush with
              // the edges, so make it 16x16 with 6px horizontal padding.
              // Bottom padding added here to shift icon up to
              // match alignment with text visually.
              padding: const EdgeInsets.only(left: 6, right: 6, bottom: 3),
              child: Icon(size: 16, color: iconColor,
                // A null [Icon.icon] makes a blank space.
                stream != null ? iconDataForStream(stream) : null)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Text(streamName,
                style: recipientHeaderTextStyle(context),
                overflow: TextOverflow.ellipsis),
            ),
            Padding(
              // Figma has 5px horizontal padding around an 8px wide icon.
              // Icon is 16px wide here so horizontal padding is 1px.
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Icon(size: 16,
                color: messageListTheme.streamRecipientHeaderChevronRight,
                ZulipIcons.chevron_right)),
          ]));
    }

    final topicWidget = Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Flexible(
            child: Text(topic.displayName,
              // TODO: Give a way to see the whole topic (maybe a
              //   long-press interaction?)
              overflow: TextOverflow.ellipsis,
              style: recipientHeaderTextStyle(context))),
          const SizedBox(width: 4),
          // TODO(design) copies the recipient header in web; is there a better color?
          Icon(size: 14, color: designVariables.colorMessageHeaderIconInteractive,
            // A null [Icon.icon] makes a blank space.
            iconDataForTopicVisibilityPolicy(
              store.topicVisibilityPolicy(message.streamId, topic))),
        ]));

    return GestureDetector(
      onTap: () => Navigator.push(context,
        MessageListPage.buildRoute(context: context,
          narrow: TopicNarrow.ofMessage(message))),
      onLongPress: () => showTopicActionSheet(context,
        channelId: message.streamId, topic: topic),
      child: ColoredBox(
        color: backgroundColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // TODO(#282): Long stream name will break layout; find a fix.
            streamWidget,
            Expanded(child: topicWidget),
            // TODO topic links?
            // Then web also has edit/resolve/mute buttons. Skip those for mobile.
            RecipientHeaderDate(message: message),
          ])));
  }
}

class DmRecipientHeader extends StatelessWidget {
  const DmRecipientHeader({super.key, required this.message});

  final DmMessage message;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);
    final String title;
    if (message.allRecipientIds.length > 1) {
      title = zulipLocalizations.messageListGroupYouAndOthers(message.allRecipientIds
        .where((id) => id != store.selfUserId)
        .map((id) => store.users[id]?.fullName ?? zulipLocalizations.unknownUserName)
        .sorted()
        .join(", "));
    } else {
      // TODO pick string; web has glitchy "You and $yourname"
      title = zulipLocalizations.messageListGroupYouWithYourself;
    }

    final messageListTheme = MessageListTheme.of(context);

    return GestureDetector(
      onTap: () => Navigator.push(context,
        MessageListPage.buildRoute(context: context,
          narrow: DmNarrow.ofMessage(message, selfUserId: store.selfUserId))),
      child: ColoredBox(
        color: messageListTheme.dmRecipientHeaderBg,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  color: messageListTheme.recipientHeaderText,
                  size: 16,
                  ZulipIcons.user)),
              Expanded(
                child: Text(title,
                  style: recipientHeaderTextStyle(context),
                  overflow: TextOverflow.ellipsis)),
              RecipientHeaderDate(message: message),
            ]))));
  }
}

TextStyle recipientHeaderTextStyle(BuildContext context) {
  return TextStyle(
    color: MessageListTheme.of(context).recipientHeaderText,
    fontSize: 16,
    letterSpacing: proportionalLetterSpacing(context, 0.02, baseFontSize: 16),
    height: (18 / 16),
  ).merge(weightVariableTextStyle(context, wght: 600));
}

class RecipientHeaderDate extends StatelessWidget {
  const RecipientHeaderDate({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 16, 0),
      child: DateText(
        fontSize: 16,
        // In Figma this has a line-height of 19, but using 18
        // here to match the stream/topic text widgets helps
        // to align all the text to the same baseline.
        height: (18 / 16),
        timestamp: message.timestamp));
  }
}

class DateText extends StatelessWidget {
  const DateText({
    super.key,
    required this.fontSize,
    required this.height,
    required this.timestamp,
  });

  final double fontSize;
  final double height;
  final int timestamp;

  @override
  Widget build(BuildContext context) {
    final messageListTheme = MessageListTheme.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Text(
      style: TextStyle(
        color: messageListTheme.dateSeparatorText,
        fontSize: fontSize,
        height: height,
        // This is equivalent to css `all-small-caps`, see:
        //   https://developer.mozilla.org/en-US/docs/Web/CSS/font-variant-caps#all-small-caps
        fontFeatures: const [FontFeature.enable('c2sc'), FontFeature.enable('smcp')],
      ),
      formatHeaderDate(
        zulipLocalizations,
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
        now: DateTime.now()));
  }
}

@visibleForTesting
String formatHeaderDate(
  ZulipLocalizations zulipLocalizations,
  DateTime dateTime, {
  required DateTime now,
}) {
  assert(!dateTime.isUtc && !now.isUtc,
    '`dateTime` and `now` need to be in local time.');

  if (dateTime.year == now.year &&
      dateTime.month == now.month &&
      dateTime.day == now.day) {
    return zulipLocalizations.today;
  }

  final yesterday = now
    .copyWith(hour: 12, minute: 0, second: 0, millisecond: 0, microsecond: 0)
    .add(const Duration(days: -1));
  if (dateTime.year == yesterday.year &&
      dateTime.month == yesterday.month &&
      dateTime.day == yesterday.day) {
    return zulipLocalizations.yesterday;
  }

  // If it is Dec 1 and you see a label that says `Dec 2`
  // it could be misinterpreted as Dec 2 of the previous
  // year. For times in the future, those still on the
  // current day will show as today (handled above) and
  // any dates beyond that show up with the year.
  if (dateTime.year == now.year && dateTime.isBefore(now)) {
    return DateFormat.MMMd().format(dateTime);
  } else {
    return DateFormat.yMMMd().format(dateTime);
  }
}

/// A Zulip message, showing the sender's name and avatar if specified.
// Design referenced from:
//   - https://github.com/zulip/zulip-mobile/issues/5511
//   - https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=538%3A20849&mode=dev
class MessageWithPossibleSender extends StatelessWidget {
  const MessageWithPossibleSender({super.key, required this.item});

  final MessageListMessageItem item;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final messageListTheme = MessageListTheme.of(context);
    final designVariables = DesignVariables.of(context);

    final message = item.message;
    final sender = store.users[message.senderId];

    Widget? senderRow;
    if (item.showSender) {
      final time = _kMessageTimestampFormat
        .format(DateTime.fromMillisecondsSinceEpoch(1000 * message.timestamp));
      senderRow = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: localizedTextBaseline(context),
        children: [
          Flexible(
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                ProfilePage.buildRoute(context: context,
                  userId: message.senderId)),
              child: Row(
                children: [
                  Avatar(size: 32, borderRadius: 3,
                    userId: message.senderId),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(message.senderFullName, // TODO get from user data
                      style: TextStyle(
                        fontSize: 18,
                        height: (22 / 18),
                        color: messageListTheme.senderName,
                      ).merge(weightVariableTextStyle(context, wght: 600)),
                      overflow: TextOverflow.ellipsis)),
                  if (sender?.isBot ?? false) ...[
                    const SizedBox(width: 5),
                    Icon(
                      ZulipIcons.bot,
                      size: 15,
                      color: messageListTheme.senderBotIcon,
                    ),
                  ],
                ]))),
          const SizedBox(width: 4),
          Text(time,
            style: TextStyle(
              color: messageListTheme.messageTimestamp,
              fontSize: 16,
              height: (18 / 16),
              fontFeatures: const [FontFeature.enable('c2sc'), FontFeature.enable('smcp')],
            ).merge(weightVariableTextStyle(context))),
        ]);
    }

    final localizations = ZulipLocalizations.of(context);
    String? editStateText;
    switch (message.editState) {
      case MessageEditState.edited:
        editStateText = localizations.messageIsEditedLabel;
      case MessageEditState.moved:
        editStateText = localizations.messageIsMovedLabel;
      case MessageEditState.none:
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () => showMessageActionSheet(context: context, message: message),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          if (senderRow != null)
            Padding(padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: senderRow),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: localizedTextBaseline(context),
            children: [
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MessageContent(message: message, content: item.content),
                  if ((message.reactions?.total ?? 0) > 0)
                    ReactionChipsList(messageId: message.id, reactions: message.reactions!),
                  if (editStateText != null)
                    Text(editStateText,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: designVariables.labelEdited,
                        fontSize: 12,
                        height: (12 / 12),
                        letterSpacing: proportionalLetterSpacing(
                          context, 0.05, baseFontSize: 12))),
                ])),
              SizedBox(width: 16,
                child: message.flags.contains(MessageFlag.starred)
                  ? Icon(ZulipIcons.star_filled, size: 16, color: designVariables.star)
                  : null),
            ]),
        ])));
  }
}

// TODO web seems to ignore locale in formatting time, but we could do better
final _kMessageTimestampFormat = DateFormat('h:mm aa', 'en_US');
