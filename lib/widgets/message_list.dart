import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:intl/intl.dart';

import '../api/model/model.dart';
import '../api/model/narrow.dart';
import '../api/route/messages.dart';
import '../model/message_list.dart';
import '../model/narrow.dart';
import '../model/store.dart';
import 'action_sheet.dart';
import 'compose_box.dart';
import 'content.dart';
import 'dialog.dart';
import 'emoji_reaction.dart';
import 'icons.dart';
import 'page.dart';
import 'profile.dart';
import 'sticky_header.dart';
import 'store.dart';
import 'text.dart';

class MessageListPage extends StatefulWidget {
  const MessageListPage({super.key, required this.narrow});

  static Route<void> buildRoute({int? accountId, BuildContext? context,
      required Narrow narrow}) {
    return MaterialAccountWidgetRoute(accountId: accountId, context: context,
      page: MessageListPage(narrow: narrow));
  }

  /// A [ComposeBoxController], if this [MessageListPage] offers a compose box.
  ///
  /// Uses the inefficient [BuildContext.findAncestorStateOfType];
  /// don't call this in a build method.
  static ComposeBoxController? composeBoxControllerOf(BuildContext context) {
    final messageListPageState = context.findAncestorStateOfType<_MessageListPageState>();
    assert(messageListPageState != null, 'No MessageListPage ancestor');
    return messageListPageState!._composeBoxKey.currentState;
  }

  final Narrow narrow;

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

// TODO(design) this seems ad-hoc; is there a better color?
const _kUnsubscribedStreamRecipientHeaderColor = Color(0xfff5f5f5);

class _MessageListPageState extends State<MessageListPage> {
  final GlobalKey<ComposeBoxController> _composeBoxKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);

    final Color? appBarBackgroundColor;
    bool removeAppBarBottomBorder = false;
    switch(widget.narrow) {
      case AllMessagesNarrow():
        appBarBackgroundColor = null; // i.e., inherit

      case StreamNarrow(:final streamId):
      case TopicNarrow(:final streamId):
        appBarBackgroundColor = store.subscriptions[streamId]?.colorSwatch().barBackground
          ?? _kUnsubscribedStreamRecipientHeaderColor;
        // All recipient headers will match this color; remove distracting line
        // (but are recipient headers even needed for topic narrows?)
        removeAppBarBottomBorder = true;

      case DmNarrow():
        appBarBackgroundColor = _kDmRecipientHeaderColor;
        // All recipient headers will match this color; remove distracting line
        // (but are recipient headers even needed?)
        removeAppBarBottomBorder = true;
    }

    return Scaffold(
      appBar: AppBar(title: MessageListAppBarTitle(narrow: widget.narrow),
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
              // TODO this copies the details of when the compose box is shown;
              //   if those details get complicated, refactor to avoid copying.
              // TODO(#311) If we have a bottom nav, it will pad the bottom
              //   inset, and this should always be true.
              removeBottom: widget.narrow is! AllMessagesNarrow,

              child: Expanded(
                child: MessageList(narrow: widget.narrow))),
            ComposeBox(controllerKey: _composeBoxKey, narrow: widget.narrow),
          ]))));
  }
}

class MessageListAppBarTitle extends StatelessWidget {
  const MessageListAppBarTitle({super.key, required this.narrow});

  final Narrow narrow;

  Widget _buildStreamRow(ZulipStream? stream, String text) {
    // A null [Icon.icon] makes a blank space.
    final icon = (stream != null) ? iconDataForStream(stream) : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      // TODO(design): The vertical alignment of the stream privacy icon is a bit ad hoc.
      //   For screenshots of some experiments, see:
      //     https://github.com/zulip/zulip-flutter/pull/219#discussion_r1281024746
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Icon(size: 16, icon),
        const SizedBox(width: 8),
        Flexible(child: Text(text)),
      ]);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);

    switch (narrow) {
      case AllMessagesNarrow():
        return Text(zulipLocalizations.combinedFeedPageTitle);

      case StreamNarrow(:var streamId):
        final store = PerAccountStoreWidget.of(context);
        final stream = store.streams[streamId];
        final streamName = stream?.name ?? '(unknown stream)';
        return _buildStreamRow(stream, streamName);

      case TopicNarrow(:var streamId, :var topic):
        final store = PerAccountStoreWidget.of(context);
        final stream = store.streams[streamId];
        final streamName = stream?.name ?? '(unknown stream)';
        return _buildStreamRow(stream, "$streamName > $topic");

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
  const MessageList({super.key, required this.narrow});

  final Narrow narrow;

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

    return DefaultTextStyle.merge(
      style: TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.15).toColor()),
      // Pad the left and right insets, for small devices in landscape.
      child: SafeArea(
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
                ]))))));
  }

  Widget _buildListView(context) {
    final length = model!.items.length;
    const centerSliverKey = ValueKey('center sliver');
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
        SliverStickyHeaderList(
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
              final valueKey = key as ValueKey;
              final index = model!.findItemWithMessageId(valueKey.value);
              if (index == -1) return null;
              return length - 1 - (index - 2);
            },
            childCount: length + 2,
            (context, i) {
              // To reinforce that the end of the feed has been reached:
              //   https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20Mark-as-read/near/1680603
              if (i == 0) return const SizedBox(height: 36);

              if (i == 1) return MarkAsReadWidget(narrow: widget.narrow);

              final data = model!.items[length - 1 - (i - 2)];
              return _buildItem(data, i);
            })),

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

  Future<void> _navigateToBottom() async {
    final distance = scrollController.position.pixels;
    final durationMsAtSpeedLimit = (1000 * distance / 8000).ceil();
    final durationMs = max(300, durationMsAtSpeedLimit);
    scrollController.animateTo(
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
        color: const HSLColor.fromAHSL(0.5,240,0.96,0.68).toColor(),
        onPressed: _navigateToBottom));
  }
}

class MarkAsReadWidget extends StatelessWidget {
  const MarkAsReadWidget({super.key, required this.narrow});

  final Narrow narrow;

  void _handlePress(BuildContext context) async {
    if (!context.mounted) return;

    final store = PerAccountStoreWidget.of(context);
    final connection = store.connection;
    final useLegacy = connection.zulipFeatureLevel! < 155;

    try {
      await markNarrowAsRead(context, narrow, useLegacy);
    } catch (e) {
      if (!context.mounted) return;
      final zulipLocalizations = ZulipLocalizations.of(context);
      await showErrorDialog(context: context,
        title: zulipLocalizations.errorMarkAsReadFailedTitle,
        message: e.toString());
      return;
    }
    if (!context.mounted) return;
    if (narrow is AllMessagesNarrow && !useLegacy) {
      PerAccountStoreWidget.of(context).unreads.handleAllMessagesReadSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);
    final unreadCount = store.unreads.countInNarrow(narrow);
    final areMessagesRead = unreadCount == 0;

    return IgnorePointer(
      ignoring: areMessagesRead,
      child: AnimatedOpacity(
        opacity: areMessagesRead ? 0 : 1,
        duration: Duration(milliseconds: areMessagesRead ? 2000 : 300),
        curve: Curves.easeOut,
        child: SizedBox(width: double.infinity,
          // Design referenced from:
          //   https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?type=design&node-id=132-9684&mode=design&t=jJwHzloKJ0TMOG4M-0
          child: Padding(
            // vertical padding adjusted for tap target height (48px) of button
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10 - ((48 - 38) / 2)),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                // TODO(#95) need dark-theme colors (foreground and background)
                backgroundColor: _UnreadMarker.color,
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
              ),
              onPressed: () => _handlePress(context),
              icon: const Icon(Icons.playlist_add_check),
              label: Text(zulipLocalizations.markAllAsReadLabel))))),
    );
  }
}

class RecipientHeader extends StatelessWidget {
  const RecipientHeader({super.key, required this.message, required this.narrow});

  final Message message;
  final Narrow narrow;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return switch (message) {
      StreamMessage() => StreamMessageRecipientHeader(message: message,
        showStream: narrow is AllMessagesNarrow),
      DmMessage() => DmRecipientHeader(message: message),
    };
  }
}

class DateSeparator extends StatelessWidget {
  const DateSeparator({super.key, required this.message});

  final Message message;

  // TODO(#95) in dark theme, use white, following web
  static const _line = BorderSide(width: 0, color: Colors.black);

  @override
  Widget build(BuildContext context) {
    // This makes the small-caps text vertically centered,
    // to align with the vertically centered divider lines.
    const textBottomPadding = 2.0;

    return ColoredBox(color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(children: [
          const Expanded(
            child: SizedBox(height: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: _line))))),
          Padding(padding: const EdgeInsets.fromLTRB(2, 0, 2, textBottomPadding),
            child: DateText(
              fontSize: 16,
              height: (16 / 16),
              timestamp: message.timestamp)),
          const SizedBox(height: 0, width: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: _line)))),
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
    return StickyHeaderItem(
      allowOverflow: !item.isLastInBlock,
      header: header,
      child: _UnreadMarker(
        isRead: message.flags.contains(MessageFlag.read),
        child: ColoredBox(
          color: Colors.white,
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

  // The color hsl(227deg 78% 59%) comes from the Figma mockup at:
  //   https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=132-9684
  // See discussion about design at:
  //   https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20unread.20marker/near/1658008
  // TODO(#95) use opacity 0.75 in dark theme? Discussion, a few weeks after the
  //   above-linked discussion:
  //     https://github.com/zulip/zulip-flutter/pull/317#issuecomment-1784311663
  //   where Vlad includes screenshots that look like they're from the Figma here:
  //     https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=807-33998&t=81Z9nyeJmsdmLgq4-0
  // (Web uses a left-to-right gradient from hsl(217deg 64% 59%) to transparent,
  // in both light and dark theme.)
  static final color = const HSLColor.fromAHSL(1, 227, 0.78, 0.59).toColor();

  @override
  Widget build(BuildContext context) {
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
                color: color,
                // TODO(#95): Don't show this extra border in dark mode, see:
                //   https://github.com/zulip/zulip-flutter/pull/317#issuecomment-1784311663
                border: Border(left: BorderSide(
                  width: 1,
                  color: Colors.white.withOpacity(0.6))))))),
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

    final topic = message.subject;

    final subscription = store.subscriptions[message.streamId];
    final Color backgroundColor;
    final Color iconColor;
    if (subscription != null) {
      final swatch = subscription.colorSwatch();
      backgroundColor = swatch.barBackground;
      iconColor = swatch.iconOnBarBackground;
    } else {
      backgroundColor = _kUnsubscribedStreamRecipientHeaderColor;
      iconColor = _kRecipientHeaderTextColor;
    }

    final Widget streamWidget;
    if (!showStream) {
      streamWidget = const SizedBox(width: 16);
    } else {
      final stream = store.streams[message.streamId];
      final streamName = stream?.name ?? message.displayRecipient; // TODO(log) if missing

      streamWidget = GestureDetector(
        onTap: () => Navigator.push(context,
          MessageListPage.buildRoute(context: context,
            narrow: StreamNarrow(message.streamId))),
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
                (stream != null) ? iconDataForStream(stream) : null)),
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
                color: Colors.black.withOpacity(0.3),
                ZulipIcons.chevron_right)),
          ]));
    }

    return GestureDetector(
      onTap: () => Navigator.push(context,
        MessageListPage.buildRoute(context: context,
          narrow: TopicNarrow.ofMessage(message))),
      child: ColoredBox(
        color: backgroundColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // TODO(#282): Long stream name will break layout; find a fix.
            streamWidget,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Text(topic,
                  // TODO: Give a way to see the whole topic (maybe a
                  //   long-press interaction?)
                  overflow: TextOverflow.ellipsis,
                  style: recipientHeaderTextStyle(context)))),
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

    return GestureDetector(
      onTap: () => Navigator.push(context,
        MessageListPage.buildRoute(context: context,
          narrow: DmNarrow.ofMessage(message, selfUserId: store.selfUserId))),
      child: ColoredBox(
        color: _kDmRecipientHeaderColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  color: _kRecipientHeaderTextColor,
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

// TODO(#95): web uses different color in dark mode
// --color-background-private-message-header in web/styles/app_variables.css
final _kDmRecipientHeaderColor = const HSLColor.fromAHSL(1, 46, 0.35, 0.93).toColor();

TextStyle recipientHeaderTextStyle(BuildContext context) {
  return TextStyle(
    color: _kRecipientHeaderTextColor,
    fontSize: 16,
    letterSpacing: proportionalLetterSpacing(context, 0.02, baseFontSize: 16),
    height: (18 / 16),
  ).merge(weightVariableTextStyle(context, wght: 600));
}
final _kRecipientHeaderTextColor = const HSLColor.fromAHSL(1, 0, 0, 0.15).toColor();

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
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Text(
      style: TextStyle(
        color: const HSLColor.fromAHSL(0.75, 0, 0, 0.15).toColor(),
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

  // TODO(#95) unchanged in dark theme?
  static final _starColor = const HSLColor.fromAHSL(0.5, 47, 1, 0.41).toColor();

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);

    final message = item.message;
    final sender = store.users[message.senderId];

    Widget? senderRow;
    if (item.showSender) {
      final time = _kMessageTimestampFormat
        .format(DateTime.fromMillisecondsSinceEpoch(1000 * message.timestamp));
      senderRow = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
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
                        fontFamily: 'Source Sans 3',
                        fontSize: 18,
                        height: (22 / 18),
                        color: const HSLColor.fromAHSL(1, 0, 0, 0.2).toColor(),
                      ).merge(weightVariableTextStyle(context, wght: 600)),
                      overflow: TextOverflow.ellipsis)),
                  if (sender?.isBot ?? false) ...[
                    const SizedBox(width: 5),
                    const Icon(
                      ZulipIcons.bot,
                      size: 15,
                      color: Color.fromARGB(255, 159, 173, 173),
                    ),
                  ],
                ]))),
          const SizedBox(width: 4),
          Text(time,
            style: TextStyle(
              color: _kMessageTimestampColor,
              fontFamily: 'Source Sans 3',
              fontSize: 16,
              height: (18 / 16),
              fontFeatures: const [FontFeature.enable('c2sc'), FontFeature.enable('smcp')],
            ).merge(weightVariableTextStyle(context))),
        ]);
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
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MessageContent(message: message, content: item.content),
                  if ((message.reactions?.total ?? 0) > 0)
                    ReactionChipsList(messageId: message.id, reactions: message.reactions!)
                ])),
            SizedBox(width: 16,
              child: message.flags.contains(MessageFlag.starred)
                // TODO(#157): fix how star marker aligns with message content
                // Design from Figma at:
                //   https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=813%3A28817&mode=dev .
                ? Padding(padding: const EdgeInsets.only(top: 4),
                    child: Icon(ZulipIcons.star_filled, size: 16, color: _starColor))
                : null),
          ]),
        ])));
  }
}

// TODO web seems to ignore locale in formatting time, but we could do better
final _kMessageTimestampFormat = DateFormat('h:mm aa', 'en_US');

// TODO(#95) need dark-theme color (this one comes from the Figma)
final _kMessageTimestampColor = const HSLColor.fromAHSL(1, 0, 0, 0.5).toColor();

Future<void> markNarrowAsRead(
  BuildContext context,
  Narrow narrow,
  bool useLegacy, // TODO(server-6)
) async {
  final store = PerAccountStoreWidget.of(context);
  final connection = store.connection;
  if (useLegacy) {
    return await _legacyMarkNarrowAsRead(context, narrow);
  }

  // Compare web's `mark_all_as_read` in web/src/unread_ops.js
  // and zulip-mobile's `markAsUnreadFromMessage` in src/action-sheets/index.js .
  final zulipLocalizations = ZulipLocalizations.of(context);
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  // Use [AnchorCode.oldest], because [AnchorCode.firstUnread]
  // will be the oldest non-muted unread message, which would
  // result in muted unreads older than the first unread not
  // being processed.
  Anchor anchor = AnchorCode.oldest;
  int responseCount = 0;
  int updatedCount = 0;

  // Include `is:unread` in the narrow.  That has a database index, so
  // this can be an important optimization in narrows with a lot of history.
  // The server applies the same optimization within the (deprecated)
  // specialized endpoints for marking messages as read; see
  // `do_mark_stream_messages_as_read` in `zulip:zerver/actions/message_flags.py`.
  final apiNarrow = narrow.apiEncode()..add(ApiNarrowIsUnread());

  while (true) {
    final result = await updateMessageFlagsForNarrow(connection,
      anchor: anchor,
      // [AnchorCode.oldest] is an anchor ID lower than any valid
      // message ID; and follow-up requests will have already
      // processed the anchor ID, so we just want this to be
      // unconditionally false.
      includeAnchor: false,
      // There is an upper limit of 5000 messages per batch
      // (numBefore + numAfter <= 5000) enforced on the server.
      // See `update_message_flags_in_narrow` in zerver/views/message_flags.py .
      // zulip-mobile uses `numAfter` of 5000, but web uses 1000
      // for more responsive feedback. See zulip@f0d87fcf6.
      numBefore: 0,
      numAfter: 1000,
      narrow: apiNarrow,
      op: UpdateMessageFlagsOp.add,
      flag: MessageFlag.read);
    if (!context.mounted) {
      scaffoldMessenger.clearSnackBars();
      return;
    }
    responseCount++;
    updatedCount += result.updatedCount;

    if (result.foundNewest) {
      if (responseCount > 1) {
        // We previously showed an in-progress [SnackBar], so say we're done.
        // There may be a backlog of [SnackBar]s accumulated in the queue
        // so be sure to clear them out here.
        scaffoldMessenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(behavior: SnackBarBehavior.floating,
              content: Text(zulipLocalizations.markAsReadComplete(updatedCount))));
      }
      return;
    }

    if (result.lastProcessedId == null) {
      // No messages were in the range of the request.
      // This should be impossible given that `foundNewest` was false
      // (and that our `numAfter` was positive.)
      await showErrorDialog(context: context,
        title: zulipLocalizations.errorMarkAsReadFailedTitle,
        message: zulipLocalizations.errorInvalidResponse);
      return;
    }
    anchor = NumericAnchor(result.lastProcessedId!);

    // The task is taking a while, so tell the user we're working on it.
    // No need to say how many messages, as the [MarkAsUnread] widget
    // should follow along.
    // TODO: Ideally we'd have a progress widget here that showed up based
    //   on actual time elapsed -- so it could appear before the first
    //   batch returns, if that takes a while -- and that then stuck
    //   around continuously until the task ends. For now we use a
    //   series of [SnackBar]s, which may feel a bit janky.
    //   There is complexity in tracking the status of each [SnackBar],
    //   due to having no way to determine which is currently active,
    //   or if there is an active one at all.  Resetting the [SnackBar] here
    //   results in the same message popping in and out and the user experience
    //   is better for now if we allow them to run their timer through
    //   and clear the backlog later.
    scaffoldMessenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating,
      content: Text(zulipLocalizations.markAsReadInProgress)));
  }
}

Future<void> _legacyMarkNarrowAsRead(BuildContext context, Narrow narrow) async {
  final store = PerAccountStoreWidget.of(context);
  final connection = store.connection;
  switch (narrow) {
    case AllMessagesNarrow():
      await markAllAsRead(connection);
    case StreamNarrow(:final streamId):
      await markStreamAsRead(connection, streamId: streamId);
    case TopicNarrow(:final streamId, :final topic):
      await markTopicAsRead(connection, streamId: streamId, topicName: topic);
    case DmNarrow():
      final unreadDms = store.unreads.dms[narrow];
      // Silently ignore this race-condition as the outcome
      // (no unreads in this narrow) was the desired end-state
      // of pushing the button.
      if (unreadDms == null) return;
      await updateMessageFlags(connection,
        messages: unreadDms,
        op: UpdateMessageFlagsOp.add,
        flag: MessageFlag.read);
  }
}
