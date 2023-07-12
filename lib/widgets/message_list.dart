import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/model/model.dart';
import '../model/content.dart';
import '../model/message_list.dart';
import '../model/narrow.dart';
import '../model/store.dart';
import 'action_sheet.dart';
import 'compose_box.dart';
import 'content.dart';
import 'icons.dart';
import 'page.dart';
import 'sticky_header.dart';
import 'store.dart';

class MessageListPage extends StatefulWidget {
  const MessageListPage({super.key, required this.narrow});

  static Route<void> buildRoute({required BuildContext context, required Narrow narrow}) {
    return MaterialAccountPageRoute(context: context,
      settings: RouteSettings(name: 'message_list', arguments: narrow), // for testing
      builder: (context) => MessageListPage(narrow: narrow));
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

class _MessageListPageState extends State<MessageListPage> {
  final GlobalKey<ComposeBoxController> _composeBoxKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: MessageListAppBarTitle(narrow: widget.narrow)),
      body: Builder(
        builder: (BuildContext context) => Center(
          child: Column(children: [
            MediaQuery.removePadding(
              // Scaffold knows about the app bar, and so has run this
              // BuildContext, which is under `body`, through
              // MediaQuery.removePadding with `removeTop: true`.
              context: context,

              // The compose box pads the bottom inset.
              removeBottom: true,

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
    final icon = switch (stream) {
      ZulipStream(isWebPublic: true) => ZulipIcons.globe,
      ZulipStream(inviteOnly: true) => ZulipIcons.lock,
      ZulipStream() => ZulipIcons.hash_sign,
      null => null, // A null [Icon.icon] makes a blank space.
    };
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
    switch (narrow) {
      case AllMessagesNarrow():
        return const Text("All messages");

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
  void onNewStore() {
    model?.dispose();
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

  void _adjustButtonVisibility(ScrollMetrics scrollMetrics) {
    if (scrollMetrics.extentBefore == 0) {
      _scrollToBottomVisibleValue.value = false;
    } else {
      _scrollToBottomVisibleValue.value = true;
    }

    final extentRemainingAboveViewport = scrollMetrics.maxScrollExtent - scrollMetrics.pixels;
    if (extentRemainingAboveViewport < kFetchMessagesBufferPixels) {
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
    _adjustButtonVisibility(scrollController.position);
  }

  bool _metricsChanged(ScrollMetricsNotification scrollMetricsNotification) {
    _adjustButtonVisibility(scrollMetricsNotification.metrics);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    assert(model != null);
    if (!model!.fetched) return const Center(child: CircularProgressIndicator());

    return DefaultTextStyle(
      // TODO figure out text color -- web is supposedly hsl(0deg 0% 20%),
      //   but seems much darker than that
      style: const TextStyle(color: Color.fromRGBO(0, 0, 0, 1)),
      child: ColoredBox(
        color: Colors.white,
        // Pad the left and right insets, for small devices in landscape.
        child: SafeArea(
          // Keep some padding when there are no horizontal insets,
          // which is usual in portrait mode.
          minimum: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: _metricsChanged,
                child: Stack(
                  children: <Widget>[
                    _buildListView(context),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: ScrollToBottomButton(
                        scrollController: scrollController,
                        visibleValue: _scrollToBottomVisibleValue)),
                  ])))))));
  }

  Widget _buildListView(context) {
    final length = model!.items.length;
    return StickyHeaderListView.builder(
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
      itemCount: length,
      // Setting reverse: true means the scroll starts at the bottom.
      // Flipping the indexes (in itemBuilder) means the start/bottom
      // has the latest messages.
      // This works great when we want to start from the latest.
      // TODO handle scroll starting at first unread, or link anchor
      // TODO on new message when scrolled up, anchor scroll to what's in view
      reverse: true,
      itemBuilder: (context, i) {
        final data = model!.items[length - 1 - i];
        return switch (data) {
          MessageListHistoryStartItem() =>
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text("No earlier messages."))), // TODO use an icon
          MessageListLoadingItem() =>
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: CircularProgressIndicator())), // TODO perhaps a different indicator
          MessageListMessageItem(:var message, :var content) =>
            MessageItem(
              trailing: i == 0 ? const SizedBox(height: 8) : const SizedBox(height: 11),
              message: message,
              content: content)
        };
      });
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

class MessageItem extends StatelessWidget {
  const MessageItem({
    super.key,
    required this.message,
    required this.content,
    this.trailing,
  });

  final Message message;
  final ZulipContent content;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // TODO recipient headings depend on narrow

    final store = PerAccountStoreWidget.of(context);

    Color highlightBorderColor;
    Color restBorderColor;
    Widget recipientHeader;
    if (message is StreamMessage) {
      final msg = (message as StreamMessage);
      final subscription = store.subscriptions[msg.streamId];
      highlightBorderColor = colorForStream(subscription);
      restBorderColor = _kStreamMessageBorderColor;
      recipientHeader = StreamTopicRecipientHeader(
        message: msg, streamColor: highlightBorderColor);
    } else if (message is DmMessage) {
      final msg = (message as DmMessage);
      highlightBorderColor = _kDmRecipientHeaderColor;
      restBorderColor = _kDmRecipientHeaderColor;
      recipientHeader = DmRecipientHeader(message: msg);
    } else {
      throw Exception("impossible message type: ${message.runtimeType}");
    }

    // This 3px border seems to accurately reproduce something much more
    // complicated on web, involving CSS box-shadow; see comment below.
    final recipientBorder = BorderSide(color: highlightBorderColor, width: 3);
    final restBorder = BorderSide(color: restBorderColor, width: 1);
    var borderDecoration = ShapeDecoration(
      // Web actually uses, for stream messages, a slightly lighter border at
      // right than at bottom and in the recipient header: black 10% alpha,
      // vs. 88% lightness.  Assume that's an accident.
      shape: Border(
        left: recipientBorder, bottom: restBorder, right: restBorder));

    return StickyHeader(
      header: recipientHeader,
      content: Column(children: [
        DecoratedBox(
          decoration: borderDecoration,
          child: MessageWithSender(message: message, content: content)),
        if (trailing != null) trailing!,
      ]));

    // Web handles the left-side recipient marker in a funky way:
    //   box-shadow: inset 3px 0px 0px -1px #c2726a, -1px 0px 0px 0px #c2726a;
    // (where the color is the stream color.)  That is, it's a pair of
    // box shadows.  One of them is inset.
    //
    // At attempt at a literal translation might look like this:
    //
    // DecoratedBox(
    //   decoration: ShapeDecoration(shadows: [
    //     BoxShadow(offset: Offset(3, 0), spreadRadius: -1, color: highlightBorderColor),
    //     BoxShadow(offset: Offset(-1, 0), color: highlightBorderColor),
    //   ], shape: Border.fromBorderSide(BorderSide.none)),
    //   child: MessageWithSender(message: message)),
    //
    // But CSS `box-shadow` seems to not apply under the item itself, while
    // Flutter's BoxShadow does.
  }
}

Color colorForStream(Subscription? subscription) {
  final color = subscription?.color;
  if (color == null) return const Color(0x00c2c2c2);
  assert(RegExp(r'^#[0-9a-f]{6}$').hasMatch(color));
  return Color(0xff000000 | int.parse(color.substring(1), radix: 16));
}

class StreamTopicRecipientHeader extends StatelessWidget {
  const StreamTopicRecipientHeader(
    {super.key, required this.message, required this.streamColor});

  final StreamMessage message;
  final Color streamColor;

  @override
  Widget build(BuildContext context) {
    final streamName = message.displayRecipient; // TODO get from stream data
    final topic = message.subject;
    final contrastingColor =
      ThemeData.estimateBrightnessForColor(streamColor) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return GestureDetector(
      onTap: () => Navigator.push(context,
        MessageListPage.buildRoute(context: context,
          narrow: TopicNarrow.ofMessage(message))),
      child: ColoredBox(
        color: _kStreamMessageBorderColor,
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          // TODO: Long stream name will break layout; find a fix.
          GestureDetector(
            onTap: () => Navigator.push(context,
              MessageListPage.buildRoute(context: context,
                narrow: StreamNarrow(message.streamId))),
            child: RecipientHeaderChevronContainer(
              color: streamColor,
              // TODO globe/lock icons for web-public and private streams
              child: Text(streamName, style: TextStyle(color: contrastingColor)))),
          Expanded(
            child: Padding(
              // Web has padding 9, 3, 3, 2 here; but 5px is the chevron.
              padding: const EdgeInsets.fromLTRB(4, 3, 3, 2),
              child: Text(topic,
                // TODO: Give a way to see the whole topic (maybe a
                //   long-press interaction?)
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)))),
          // TODO topic links?
          // Then web also has edit/resolve/mute buttons. Skip those for mobile.
        ])));
  }
}

final _kStreamMessageBorderColor = const HSLColor.fromAHSL(1, 0, 0, 0.88).toColor();

class DmRecipientHeader extends StatelessWidget {
  const DmRecipientHeader({super.key, required this.message});

  final DmMessage message;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final store = PerAccountStoreWidget.of(context);
        final narrow = DmNarrow.ofMessage(message, selfUserId: store.account.userId);
        Navigator.push(context,
          MessageListPage.buildRoute(context: context, narrow: narrow));
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: RecipientHeaderChevronContainer(
          color: _kDmRecipientHeaderColor,
          child: const Text("Direct message", // TODO DM recipient headers
            style: TextStyle(color: Colors.white)))));
  }
}

final _kDmRecipientHeaderColor =
    const HSLColor.fromAHSL(1, 0, 0, 0.27).toColor();

/// A widget with the distinctive chevron-tailed shape in Zulip recipient headers.
class RecipientHeaderChevronContainer extends StatelessWidget {
  const RecipientHeaderChevronContainer(
    {super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const chevronLength = 5.0;
    const recipientBorderShape = BeveledRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.elliptical(chevronLength, double.infinity),
        bottomRight: Radius.elliptical(chevronLength, double.infinity)));
    return Container(
      decoration: ShapeDecoration(color: color, shape: recipientBorderShape),
      padding: const EdgeInsets.only(right: chevronLength),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 3), child: child));
  }
}

/// A Zulip message, showing the sender's name and avatar.
class MessageWithSender extends StatelessWidget {
  const MessageWithSender(
    {super.key, required this.message, required this.content});

  final Message message;
  final ZulipContent content;

  @override
  Widget build(BuildContext context) {
    final time = _kMessageTimestampFormat
      .format(DateTime.fromMillisecondsSinceEpoch(1000 * message.timestamp));

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () => showMessageActionSheet(context: context, message: message),
      // TODO clean up this layout, by less precisely imitating web
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 3, left: 8, right: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(3, 6, 11, 0),
            child: Avatar(userId: message.senderId, size: 35, borderRadius: 4)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 3),
                Text(message.senderFullName, // TODO get from user data
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                MessageContent(message: message, content: content),
              ])),
          Container(
            width: 80,
            padding: const EdgeInsets.only(top: 4, right: 2),
            alignment: Alignment.topRight,
            child: Text(time, style: _kMessageTimestampStyle)),
        ])));
  }
}

// TODO web seems to ignore locale in formatting time, but we could do better
final _kMessageTimestampFormat = DateFormat('h:mm aa', 'en_US');

// TODO this seems to come out lighter than on web
final _kMessageTimestampStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: const HSLColor.fromAHSL(0.4, 0, 0, 0.2).toColor());
