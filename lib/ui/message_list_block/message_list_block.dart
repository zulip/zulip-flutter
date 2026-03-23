import 'package:flutter/material.dart';

import '../../model/message_list.dart';
import '../../model/narrow.dart';
import '../compose_box_block/compose_box_block.dart';
import 'message_list.dart';
import '../utils/page.dart';
import '../utils/store.dart';
import 'widgets/message_list/message_list.dart';
import 'widgets/message_list_app_bar/message_list_app_bar.dart';

/// The interface for the state of a [MessageListPage].
///
/// To obtain one of these, see [MessageListPage.ancestorOf].
abstract class MessageListBlockPageState extends State<MessageListBlockPage> {
  /// The narrow for this page's message list.
  Narrow get narrow;

  /// Resets the [MessageListView] model, triggering an initial fetch.
  ///
  /// If [anchor] isn't passed, reuses the anchor from the last initial fetch.
  ///
  /// Useful when updates won't arrive through the event system,
  /// as when showing an unsubscribed channel.
  /// (New-message events aren't sent for unsubscribed channels.)
  ///
  /// Does nothing if [MessageList] has not mounted yet.
  void refresh([Anchor? anchor]);

  /// The [ComposeBoxState] for this [MessageListPage]'s compose box,
  /// if this [MessageListPage] offers a compose box and it has mounted,
  /// else null.
  ComposeBoxBlockState? get composeBoxState;

  /// The active [MessageListView].
  ///
  /// This is null if [MessageList] has not mounted yet.
  MessageListView? get model;

  /// This view's decision whether to mark read on scroll,
  /// overriding [GlobalSettings.markReadOnScroll].
  ///
  /// For example, this is set to false after pressing
  /// "Mark as unread from here" in the message action sheet.
  bool? get markReadOnScroll;
  set markReadOnScroll(bool? value);

  /// For a message from a muted sender, reveal the sender and content,
  /// replacing the "Muted user" placeholder.
  void revealMutedMessage(int messageId);

  /// For a message from a muted sender, hide the sender and content again
  /// with the "Muted user" placeholder.
  void unrevealMutedMessage(int messageId);
}

class MessageListBlockPage extends StatefulWidget {
  const MessageListBlockPage({
    super.key,
    required this.initNarrow,
    this.initAnchorMessageId,
  });

  static AccountRoute<void> buildRoute({
    int? accountId,
    BuildContext? context,
    GlobalKey<MessageListBlockPageState>? key,
    required Narrow narrow,
    int? initAnchorMessageId,
  }) {
    return MaterialAccountWidgetRoute(
      accountId: accountId,
      context: context,
      page: MessageListBlockPage(
        key: key,
        initNarrow: narrow,
        initAnchorMessageId: initAnchorMessageId,
      ),
    );
  }

  /// The [MessageListPageState] for the page at the given route.
  ///
  /// The route must be a [WidgetRoute] for [MessageListPage].
  ///
  /// Null if the route is not mounted in the widget tree.
  static MessageListBlockPageState? stateOfRoute(Route<void> route) {
    if (!(route is WidgetRoute && route.page is MessageListBlockPage)) {
      assert(
        false,
        'MessageListPage.stateOfRoute expects a MessageListPage route',
      );
      return null;
    }
    final element = route.pageElement;
    if (element == null) return null;
    assert(element.widget == route.page);

    return (element as StatefulElement).state as MessageListBlockPageState;
  }

  /// The current narrow, as updated, for the given [MessageListPage] route.
  ///
  /// The route must be a [WidgetRoute] for [MessageListPage].
  ///
  /// This uses [MessageListPageState.narrow] to take into account any updates
  /// that have happened since the route was navigated to.
  static Narrow currentNarrow(Route<void> route) {
    final state = stateOfRoute(route);
    if (state == null) {
      // The page is not yet mounted.  Either the route has not yet been
      // navigated to, or there hasn't yet been a new frame since it was.
      // Either way, there's been no change to its narrow.
      return ((route as WidgetRoute).page as MessageListBlockPage).initNarrow;
    }
    // The page is mounted, and may have changed its narrow.
    return state.narrow;
  }

  /// The "revealed" state of a message from a muted sender,
  /// if there is a [MessageListPage] ancestor, else null.
  ///
  /// This is updated via [MessageListPageState.revealMutedMessage]
  /// and [MessageListPageState.unrevealMutedMessage].
  ///
  /// Uses the efficient [BuildContext.dependOnInheritedWidgetOfExactType],
  /// so this is safe to call in a build method.
  static RevealedMutedMessagesState? maybeRevealedMutedMessagesOf(
    BuildContext context,
  ) {
    final state = context
        .dependOnInheritedWidgetOfExactType<RevealedMutedMessagesProvider>()
        ?.state;
    return state;
  }

  /// The [MessageListPageState] above this context in the tree.
  ///
  /// Uses the inefficient [BuildContext.findAncestorStateOfType];
  /// don't call this in a build method.
  ///
  /// See also:
  ///  * [maybeAncestorOf], which returns null instead of throwing
  ///    when an ancestor [MessageListPageState] is not found.
  static MessageListBlockPageState ancestorOf(BuildContext context) {
    final state = maybeAncestorOf(context);
    assert(state != null, 'No MessageListPage ancestor');
    return state!;
  }

  /// The [MessageListPageState] above this context in the tree, if any.
  ///
  /// Uses the inefficient [BuildContext.findAncestorStateOfType];
  /// don't call this in a build method.
  ///
  /// See also:
  ///  * [ancestorOf], which throws instead of returning null
  ///    when an ancestor [MessageListPageState] is not found.
  // If we do find ourselves wanting this in a build method, it won't be hard
  // to enable that: we'd just need to add an [InheritedWidget] here.
  static MessageListBlockPageState? maybeAncestorOf(BuildContext context) {
    return context.findAncestorStateOfType<_MessageListBlockPageState>();
  }

  final Narrow initNarrow;
  final int? initAnchorMessageId; // TODO(#1564) highlight target upon load

  @override
  State<MessageListBlockPage> createState() => _MessageListBlockPageState();

  /// In debug mode, controls whether mark-read-on-scroll is enabled,
  /// overriding [GlobalSettings.markReadOnScroll]
  /// and [MessageListPageState.markReadOnScroll].
  ///
  /// Outside of debug mode, this is always true and the setter has no effect.
  static bool get debugEnableMarkReadOnScroll {
    bool result = true;
    assert(() {
      result = _debugEnableMarkReadOnScroll;
      return true;
    }());
    return result;
  }

  static bool _debugEnableMarkReadOnScroll = true;
  static set debugEnableMarkReadOnScroll(bool value) {
    assert(() {
      _debugEnableMarkReadOnScroll = value;
      return true;
    }());
  }

  @visibleForTesting
  static void debugReset() {
    _debugEnableMarkReadOnScroll = true;
  }
}

class _MessageListBlockPageState extends State<MessageListBlockPage>
    implements MessageListBlockPageState {
  @override
  late Narrow narrow;

  @override
  void refresh([Anchor? anchor]) {
    // TODO If anchor isn't passed, check if there's some onscreen message
    //   we can anchor to, before defaulting to model.anchor.
    //   Update the dartdoc on this method with the new behavior.
    model?.renarrowAndFetch(narrow, anchor ?? model!.anchor);
  }

  @override
  ComposeBoxBlockState? get composeBoxState => _composeBoxKey.currentState;
  final GlobalKey<ComposeBoxBlockState> _composeBoxKey = GlobalKey();

  @override
  MessageListView? get model => _messageListKey.currentState?.model;
  final GlobalKey<_MessageListBlockPageState> _messageListKey = GlobalKey();

  @override
  bool? get markReadOnScroll => _markReadOnScroll;
  bool? _markReadOnScroll;
  @override
  set markReadOnScroll(bool? value) {
    setState(() {
      _markReadOnScroll = value;
    });
  }

  final _revealedMutedMessages = RevealedMutedMessagesState();

  @override
  void revealMutedMessage(int messageId) {
    _revealedMutedMessages.add(messageId);
  }

  @override
  void unrevealMutedMessage(int messageId) {
    _revealedMutedMessages.remove(messageId);
  }

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
    final Anchor initAnchor;
    if (narrow is KeywordSearchNarrow) {
      initAnchor = AnchorCode.newest;
    } else if (widget.initAnchorMessageId != null) {
      initAnchor = NumericAnchor(widget.initAnchorMessageId!);
    } else {
      final globalSettings = GlobalStoreWidget.settingsOf(context);
      final useFirstUnread = globalSettings.shouldVisitFirstUnread(
        narrow: narrow,
      );
      initAnchor = useFirstUnread ? AnchorCode.firstUnread : AnchorCode.newest;
    }

    Widget result = Scaffold(
      appBar: MessageListAppBar.build(context, narrow: narrow),
      // TODO question for Vlad: for a stream view, should we set the Scaffold's
      //   [backgroundColor] based on stream color, as in this frame:
      //     https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=132%3A9684&mode=dev
      //   That's not obviously preferred over the default background that
      //   we matched to the Figma in 21dbae120. See another frame, which uses that:
      //     https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=147%3A9088&mode=dev
      body: Builder(
        builder: (BuildContext context) {
          return Column(
            // Children are expected to take the full horizontal space
            // and handle the horizontal device insets.
            // The bottom inset should be handled by the last child only.
            children: [
              MediaQuery.removePadding(
                // Scaffold knows about the app bar, and so has run this
                // BuildContext, which is under `body`, through
                // MediaQuery.removePadding with `removeTop: true`.
                context: context,

                // The compose box, when present, pads the bottom inset.
                // TODO(#311) If we have a bottom nav, it will pad the bottom
                //   inset, and this should always be true.
                removeBottom: ComposeBoxBlock.hasComposeBox(narrow),

                child: Expanded(
                  child: MessageList(
                    key: _messageListKey,
                    narrow: narrow,
                    initAnchor: initAnchor,
                    onNarrowChanged: _narrowChanged,
                    markReadOnScroll: markReadOnScroll,
                  ),
                ),
              ),
              if (ComposeBoxBlock.hasComposeBox(narrow))
                ComposeBoxBlock(key: _composeBoxKey, narrow: narrow),
            ],
          );
        },
      ),
    );

    // Insert a PageRoot here (under MessageListPage),
    // to provide a context that can be used for MessageListPage.ancestorOf.
    result = PageRoot(child: result);

    result = RevealedMutedMessagesProvider(
      state: _revealedMutedMessages,
      child: result,
    );

    return result;
  }
}
