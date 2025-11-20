import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_color_models/flutter_color_models.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/binding.dart';
import '../model/database.dart';
import '../model/message.dart';
import '../model/message_list.dart';
import '../model/narrow.dart';
import '../model/store.dart';
import '../model/typing_status.dart';
import 'action_sheet.dart';
import 'actions.dart';
import 'app_bar.dart';
import 'button.dart';
import 'color.dart';
import 'compose_box.dart';
import 'content.dart';
import 'emoji_reaction.dart';
import 'icons.dart';
import 'page.dart';
import 'profile.dart';
import 'scrolling.dart';
import 'sticky_header.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'topic_list.dart';
import 'user.dart';

/// Message-list styles that differ between light and dark themes.
class MessageListTheme extends ThemeExtension<MessageListTheme> {
  static final light = MessageListTheme._(
    dmRecipientHeaderBg: const HSLColor.fromAHSL(1, 46, 0.35, 0.93).toColor(),
    labelTime: const HSLColor.fromAHSL(0.49, 0, 0, 0).toColor(),
    senderBotIcon: const HSLColor.fromAHSL(1, 180, 0.08, 0.65).toColor(),
    streamRecipientHeaderChevronRight: Colors.black.withValues(alpha: 0.3),

    // From the Figma mockup at:
    //   https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=132-9684
    // See discussion about design at:
    //   https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20unread.20marker/near/1658008
    // (Web uses a left-to-right gradient from hsl(217deg 64% 59%) to transparent,
    // in both light and dark theme.)
    unreadMarker: const HSLColor.fromAHSL(1, 227, 0.78, 0.59).toColor(),

    unreadMarkerGap: Colors.white.withValues(alpha: 0.6),
  );

  static final dark = MessageListTheme._(
    dmRecipientHeaderBg: const HSLColor.fromAHSL(1, 46, 0.15, 0.2).toColor(),
    labelTime: const HSLColor.fromAHSL(0.5, 0, 0, 1).toColor(),
    senderBotIcon: const HSLColor.fromAHSL(1, 180, 0.05, 0.5).toColor(),
    streamRecipientHeaderChevronRight: Colors.white.withValues(alpha: 0.3),

    // 0.75 opacity from here:
    //   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=807-33998&m=dev
    // Discussion, some weeks after the discussion linked on the light variant:
    //   https://github.com/zulip/zulip-flutter/pull/317#issuecomment-1784311663
    // where Vlad includes screenshots that look like they're from there.
    unreadMarker: const HSLColor.fromAHSL(0.75, 227, 0.78, 0.59).toColor(),

    unreadMarkerGap: Colors.transparent,
  );

  MessageListTheme._({
    required this.dmRecipientHeaderBg,
    required this.labelTime,
    required this.senderBotIcon,
    required this.streamRecipientHeaderChevronRight,
    required this.unreadMarker,
    required this.unreadMarkerGap,
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

  final Color dmRecipientHeaderBg;
  final Color labelTime;
  final Color senderBotIcon;
  final Color streamRecipientHeaderChevronRight;
  final Color unreadMarker;
  final Color unreadMarkerGap;

  @override
  MessageListTheme copyWith({
    Color? dmRecipientHeaderBg,
    Color? labelTime,
    Color? senderBotIcon,
    Color? streamRecipientHeaderChevronRight,
    Color? unreadMarker,
    Color? unreadMarkerGap,
  }) {
    return MessageListTheme._(
      dmRecipientHeaderBg: dmRecipientHeaderBg ?? this.dmRecipientHeaderBg,
      labelTime: labelTime ?? this.labelTime,
      senderBotIcon: senderBotIcon ?? this.senderBotIcon,
      streamRecipientHeaderChevronRight: streamRecipientHeaderChevronRight ?? this.streamRecipientHeaderChevronRight,
      unreadMarker: unreadMarker ?? this.unreadMarker,
      unreadMarkerGap: unreadMarkerGap ?? this.unreadMarkerGap,
    );
  }

  @override
  MessageListTheme lerp(MessageListTheme other, double t) {
    if (identical(this, other)) {
      return this;
    }
    return MessageListTheme._(
      dmRecipientHeaderBg: Color.lerp(dmRecipientHeaderBg, other.dmRecipientHeaderBg, t)!,
      labelTime: Color.lerp(labelTime, other.labelTime, t)!,
      senderBotIcon: Color.lerp(senderBotIcon, other.senderBotIcon, t)!,
      streamRecipientHeaderChevronRight: Color.lerp(streamRecipientHeaderChevronRight, other.streamRecipientHeaderChevronRight, t)!,
      unreadMarker: Color.lerp(unreadMarker, other.unreadMarker, t)!,
      unreadMarkerGap: Color.lerp(unreadMarkerGap, other.unreadMarkerGap, t)!,
    );
  }
}

/// The interface for the state of a [MessageListPage].
///
/// To obtain one of these, see [MessageListPage.ancestorOf].
abstract class MessageListPageState extends State<MessageListPage> {
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
  ComposeBoxState? get composeBoxState;

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

class MessageListPage extends StatefulWidget {
  const MessageListPage({
    super.key,
    required this.initNarrow,
    this.initAnchorMessageId,
  });

  static AccountRoute<void> buildRoute({
    int? accountId,
    BuildContext? context,
    GlobalKey<MessageListPageState>? key,
    required Narrow narrow,
    int? initAnchorMessageId,
  }) {
    return MaterialAccountWidgetRoute(
      accountId: accountId,
      context: context,
      page: MessageListPage(
        key: key,
        initNarrow: narrow,
        initAnchorMessageId: initAnchorMessageId));
  }

  /// The "revealed" state of a message from a muted sender,
  /// if there is a [MessageListPage] ancestor, else null.
  ///
  /// This is updated via [MessageListPageState.revealMutedMessage]
  /// and [MessageListPageState.unrevealMutedMessage].
  ///
  /// Uses the efficient [BuildContext.dependOnInheritedWidgetOfExactType],
  /// so this is safe to call in a build method.
  static RevealedMutedMessagesState? maybeRevealedMutedMessagesOf(BuildContext context) {
    final state =
      context.dependOnInheritedWidgetOfExactType<_RevealedMutedMessagesProvider>()
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
  static MessageListPageState ancestorOf(BuildContext context) {
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
  static MessageListPageState? maybeAncestorOf(BuildContext context) {
    return context.findAncestorStateOfType<_MessageListPageState>();
  }

  final Narrow initNarrow;
  final int? initAnchorMessageId; // TODO(#1564) highlight target upon load

  @override
  State<MessageListPage> createState() => _MessageListPageState();

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

class _MessageListPageState extends State<MessageListPage> implements MessageListPageState {
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
  ComposeBoxState? get composeBoxState => _composeBoxKey.currentState;
  final GlobalKey<ComposeBoxState> _composeBoxKey = GlobalKey();

  @override
  MessageListView? get model => _messageListKey.currentState?.model;
  final GlobalKey<_MessageListState> _messageListKey = GlobalKey();

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
    _revealedMutedMessages._add(messageId);
  }

  @override
  void unrevealMutedMessage(int messageId) {
    _revealedMutedMessages._remove(messageId);
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
      final useFirstUnread = globalSettings.shouldVisitFirstUnread(narrow: narrow);
      initAnchor = useFirstUnread ? AnchorCode.firstUnread : AnchorCode.newest;
    }

    Widget result = Scaffold(
      appBar: _MessageListAppBar.build(context, narrow: narrow),
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
              removeBottom: ComposeBox.hasComposeBox(narrow),

              child: Expanded(
                child: MessageList(
                  key: _messageListKey,
                  narrow: narrow,
                  initAnchor: initAnchor,
                  onNarrowChanged: _narrowChanged,
                  markReadOnScroll: markReadOnScroll,
                ))),
            if (ComposeBox.hasComposeBox(narrow))
              ComposeBox(key: _composeBoxKey, narrow: narrow)
          ]);
        }));

    // Insert a PageRoot here (under MessageListPage),
    // to provide a context that can be used for MessageListPage.ancestorOf.
    result = PageRoot(child: result);

    result = _RevealedMutedMessagesProvider(state: _revealedMutedMessages,
      child: result);

    return result;
  }
}

// Conceptually this should be a widget class.  But it needs to be a
// PreferredSizeWidget, with the `preferredSize` that the underlying AppBar
// will have... and there's currently no good way to get that value short of
// constructing the whole AppBar widget with all its properties.
// So this has to be built eagerly by its parent's build method,
// making it a build function rather than a widget.  Discussion:
//   https://github.com/zulip/zulip-flutter/pull/1662#discussion_r2183471883
// Still we can organize it on a class, with the name the widget would have.
// TODO(upstream): AppBar should expose a bit more API so that it's possible
//   to customize by composition in a reasonable way.
abstract class _MessageListAppBar {
  static AppBar build(BuildContext context, {required Narrow narrow}) {
    final store = PerAccountStoreWidget.of(context);
    final messageListTheme = MessageListTheme.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final Color? appBarBackgroundColor;
    bool removeAppBarBottomBorder = false;
    switch(narrow) {
      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
      case KeywordSearchNarrow():
        appBarBackgroundColor = null; // i.e., inherit

      case ChannelNarrow(:final streamId):
      case TopicNarrow(:final streamId):
        final subscription = store.subscriptions[streamId];
        appBarBackgroundColor =
          colorSwatchFor(context, subscription).barBackground;
        // All recipient headers will match this color; remove distracting line
        // (but are recipient headers even needed for topic narrows?)
        removeAppBarBottomBorder = true;

      case DmNarrow():
        appBarBackgroundColor = messageListTheme.dmRecipientHeaderBg;
        // All recipient headers will match this color; remove distracting line
        // (but are recipient headers even needed?)
        removeAppBarBottomBorder = true;
    }

    List<Widget> actions = [];
    switch (narrow) {
      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
      case KeywordSearchNarrow():
      case DmNarrow():
        break;
      case ChannelNarrow(:final streamId):
        actions.add(_TopicListButton(streamId: streamId));
      case TopicNarrow(:final streamId):
        actions.add(IconButton(
          icon: const Icon(ZulipIcons.message_feed),
          tooltip: zulipLocalizations.channelFeedButtonTooltip,
          onPressed: () => Navigator.push(context,
            MessageListPage.buildRoute(context: context,
              narrow: ChannelNarrow(streamId)))));
        actions.add(_TopicListButton(streamId: streamId));
    }

    return ZulipAppBar(
      centerTitle: switch (narrow) {
        CombinedFeedNarrow() || ChannelNarrow()
            || TopicNarrow() || DmNarrow()
            || MentionsNarrow() || StarredMessagesNarrow()
          => null,
        KeywordSearchNarrow()
          => false,
      },
      buildTitle: (willCenterTitle) =>
        MessageListAppBarTitle(narrow: narrow, willCenterTitle: willCenterTitle),
      actions: actions,
      backgroundColor: appBarBackgroundColor,
      shape: removeAppBarBottomBorder
        ? const Border()
        : null, // i.e., inherit
    );
  }
}

class RevealedMutedMessagesState extends ChangeNotifier {
  final Set<int> _revealedMessages = {};

  bool isMutedMessageRevealed(int messageId) =>
    _revealedMessages.contains(messageId);

  void _add(int messageId) {
    _revealedMessages.add(messageId);
    notifyListeners();
  }

  void _remove(int messageId) {
    _revealedMessages.remove(messageId);
    notifyListeners();
  }
}

class _RevealedMutedMessagesProvider extends InheritedNotifier<RevealedMutedMessagesState> {
  const _RevealedMutedMessagesProvider({
    required RevealedMutedMessagesState state,
    required super.child,
  }) : super(notifier: state);

  RevealedMutedMessagesState get state => notifier!;
}

class _TopicListButton extends StatelessWidget {
  const _TopicListButton({required this.streamId});

  final int streamId;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return IconButton(
      icon: const Icon(ZulipIcons.topics),
      tooltip: zulipLocalizations.topicsButtonTooltip,
      onPressed: () => Navigator.push(context,
        TopicListPage.buildRoute(context: context,
          streamId: streamId)));
  }
}

class MessageListAppBarTitle extends StatelessWidget {
  const MessageListAppBarTitle({
    super.key,
    required this.narrow,
    required this.willCenterTitle,
  });

  final Narrow narrow;
  final bool willCenterTitle;

  Widget _buildStreamRow(BuildContext context, {
    ZulipStream? stream,
  }) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    // A null [Icon.icon] makes a blank space.
    IconData? icon;
    Color? iconColor;
    if (stream != null) {
      icon = iconDataForStream(stream);
      iconColor = colorSwatchFor(context, store.subscriptions[stream.streamId])
        .iconOnBarBackground;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      // TODO(design): The vertical alignment of the stream privacy icon is a bit ad hoc.
      //   For screenshots of some experiments, see:
      //     https://github.com/zulip/zulip-flutter/pull/219#discussion_r1281024746
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(size: 16, color: iconColor, icon),
        const SizedBox(width: 4),
        Flexible(child: Text(
          stream?.name ?? zulipLocalizations.unknownChannelName)),
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
        Flexible(child: Text(topic.displayName ?? store.realmEmptyTopicDisplayName, style: TextStyle(
          fontSize: 13,
          fontStyle: topic.displayName == null ? FontStyle.italic : null,
        ).merge(weightVariableTextStyle(context)))),
        if (icon != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: Icon(icon,
              color: designVariables.title.withFadedAlpha(0.5), size: 14)),
      ]);
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
        final alignment = willCenterTitle
          ? Alignment.center
          : AlignmentDirectional.centerStart;
        return SizedBox(
          width: double.infinity,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: () {
              showChannelActionSheet(context, channelId: streamId);
            },
            child: Align(alignment: alignment,
              child: _buildStreamRow(context, stream: stream))));

      case TopicNarrow(:var streamId, :var topic):
        final store = PerAccountStoreWidget.of(context);
        final stream = store.streams[streamId];
        final alignment = willCenterTitle
          ? Alignment.center
          : AlignmentDirectional.centerStart;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPress: () {
                showChannelActionSheet(context, channelId: streamId);
              },
              child: Align(alignment: alignment,
                child: _buildStreamRow(context, stream: stream))),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPress: () {
                final someMessage = MessageListPage.ancestorOf(context)
                  .model?.messages.lastOrNull;
                // If someMessage is null, the topic action sheet won't have a
                // resolve/unresolve button. That seems OK; in that case we're
                // either still fetching messages (and the user can reopen the
                // sheet after that finishes) or there aren't any messages to
                // act on anyway.
                assert(someMessage == null || narrow.containsMessage(someMessage)!);
                showTopicActionSheet(context,
                  channelId: streamId,
                  topic: topic,
                  someMessageIdInTopic: someMessage?.id);
              },
              child: Align(alignment: alignment,
                child: _buildTopicRow(context, stream: stream, topic: topic))),
          ]);

      case DmNarrow(:var otherRecipientIds):
        final store = PerAccountStoreWidget.of(context);
        if (otherRecipientIds.isEmpty) {
          return Text(zulipLocalizations.dmsWithYourselfPageTitle);
        } else {
          final names = otherRecipientIds.map(store.userDisplayName);
          // TODO show avatars
          return Text(
            zulipLocalizations.dmsWithOthersPageTitle(names.join(', ')));
        }

      case KeywordSearchNarrow():
        assert(!willCenterTitle);
        return _SearchBar(onSubmitted: (narrow) {
          MessageListPage.ancestorOf(context).model!
            .renarrowAndFetch(narrow, AnchorCode.newest);
        });
    }
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.onSubmitted});

  final void Function(KeywordSearchNarrow) onSubmitted;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late TextEditingController _controller;

  static KeywordSearchNarrow _valueToNarrow(String value) =>
    KeywordSearchNarrow(value.trim());

  @override
  void initState() {
    _controller = TextEditingController();
    super.initState();
  }

  void _handleSubmitted(String value) {
    widget.onSubmitted(_valueToNarrow(value));
  }

  void _clearInput() {
    _controller.clear();
    _handleSubmitted('');
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return TextField(
      controller: _controller,
      autocorrect: false,

      // Servers as of 2025-07 seem to require straight quotes for the
      // "exact match"- style query. (N.B. the doc says this param is iOS-only.)
      smartQuotesType: SmartQuotesType.disabled,

      autofocus: true,
      onSubmitted: _handleSubmitted,
      cursorColor: designVariables.textInput,
      style: TextStyle(
        color: designVariables.textInput,
        fontSize: 19,
        height: 28 / 19,
      ),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: zulipLocalizations.searchMessagesHintText,
        hintStyle: TextStyle(color: designVariables.labelSearchPrompt),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 0, 8),
          child: Icon(size: 24, ZulipIcons.search)),
        prefixIconColor: designVariables.labelSearchPrompt,
        prefixIconConstraints: BoxConstraints(),
        suffixIcon: IconButton(
          tooltip: zulipLocalizations.searchMessagesClearButtonTooltip,
          onPressed: _clearInput,
          // This and `suffixIconConstraints` allow 42px square touch target.
          visualDensity: VisualDensity.compact,
          highlightColor: Colors.transparent,
          style: ButtonStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.zero),
            splashFactory: NoSplash.splashFactory,
          ),
          iconSize: 24,
          icon: Icon(ZulipIcons.remove)),
        suffixIconColor: designVariables.textMessageMuted,
        suffixIconConstraints: BoxConstraints(minWidth: 42, minHeight: 42),
        contentPadding: const EdgeInsetsDirectional.symmetric(vertical: 7),
        filled: true,
        fillColor: designVariables.bgSearchInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none),
      ));
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

class _MessageListState extends State<MessageList> with PerAccountStoreAwareStateMixin<MessageList> {
  final GlobalKey _scrollViewKey = GlobalKey();

  MessageListView get model => _model!;
  MessageListView? _model;

  final MessageListScrollController scrollController = MessageListScrollController();

  final ValueNotifier<bool> _scrollToBottomVisible = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollChanged);
  }

  @override
  void onNewStore() { // TODO(#464) try to keep using old model until new one gets messages
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
      narrow = TopicNarrow(narrow.streamId,
        store.processTopicLikeServer(narrow.topic),
        with_: narrow.with_);
      if (narrow != widget.narrow) {
        SchedulerBinding.instance.scheduleFrameCallback((_) {
          widget.onNarrowChanged(narrow);
        });
      }
    }
    _model = MessageListView.init(store: store,
      narrow: narrow, anchor: anchor);
    model.addListener(_modelChanged);
    model.fetchInitial();
  }

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

    if (model.messages.isEmpty && model.haveOldest && model.haveNewest) {
      // If the fetch came up empty, there's nothing to read,
      // so opening the keyboard won't be bothersome and could be helpful.
      // It's definitely helpful if we got here from the new-DM page.
      MessageListPage.ancestorOf(context)
        .composeBoxState?.controller.requestFocusIfUnfocused();
    }
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
            element, scrollViewRenderObject: scrollViewRenderObject);
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
    assert(element.widget is MessageItem
      && (element.widget as MessageItem).item is MessageListMessageItem);
    final viewportHeight = scrollViewRenderObject.size.height;

    final messageRenderObject = element.renderObject as RenderBox;

    final messageBottom = messageRenderObject.localToGlobal(
      Offset(0, messageRenderObject.size.height),
      ancestor: scrollViewRenderObject).dy;

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
      (           _, int current) => current,
    };

    final lastOfHull = switch ((prevLast, currentLast)) {
      (int previous, int current) => previous > current ? previous : current,
      (           _, int current) => current,
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
    if (!MessageListPage.debugEnableMarkReadOnScroll) return false;
    return widget.markReadOnScroll
      ?? GlobalStoreWidget.settingsOf(context).markReadOnScrollForNarrow(widget.narrow);
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
    final zulipLocalizations = ZulipLocalizations.of(context);

    if (!model.initialFetched) return const Center(child: CircularProgressIndicator());

    if (model.items.isEmpty && model.haveNewest && model.haveOldest) {
      final String header;
      if (widget.narrow is KeywordSearchNarrow) {
        header = zulipLocalizations.emptyMessageListSearch;
      } else {
        header = zulipLocalizations.emptyMessageList;
      }

      return PageBodyEmptyContentPlaceholder(header: header);
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
                Positioned(
                  bottom: 0,
                  right: 0,
                  // TODO(#311) SafeArea shouldn't be needed if we have a
                  //   bottom nav; that will pad the bottom inset. Remove it,
                  //   and the mention of bottom-inset handling in
                  //   MessageList's dartdoc.
                  child: SafeArea(
                    child: ScrollToBottomButton(
                      model: model,
                      scrollController: scrollController,
                      visible: _scrollToBottomVisible))),
              ])))));
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
          final item = _buildItem(data, isLastInFeed: itemIndex == totalItems - 1);
          return item;
        }));

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
        }));

    if (!ComposeBox.hasComposeBox(widget.narrow)) {
      // TODO(#311) If we have a bottom nav, it will pad the bottom inset,
      //   and this can be removed; also remove mention in MessageList dartdoc
      bottomSliver = SliverSafeArea(key: bottomSliver.key, sliver: bottomSliver);
      topSliver = MediaQuery.removePadding(context: context,
        // In the top sliver, forget the bottom inset;
        // we're having the bottom sliver take care of it.
        removeBottom: true,
        // (Also forget the left and right insets; the outer SafeArea, above,
        // does that, but the `context` we're passing to this `removePadding`
        // is from outside that SafeArea, so we need to repeat it.)
        removeLeft: true, removeRight: true,
        child: topSliver);
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
      semanticChildCount: totalItems, // TODO(#537): what's the right value for this?
      center: centerSliverKey,
      paintOrder: SliverPaintOrder.firstIsTop,

      slivers: [
        topSliver,
        bottomSliver,
      ]);
  }

  Widget _buildStartCap() {
    // If we're done fetching older messages, show that.
    // Else if we're busy with fetching, then show a loading indicator.
    //
    // This applies even if the fetch is over, but failed, and we're still
    // in backoff from it.
    return model.haveOldest ? const _MessageListHistoryStart()
      : model.busyFetchingOlder ? const _MessageListLoadingMore()
      : const SizedBox.shrink();
  }

  Widget _buildEndCap() {
    if (model.haveNewest) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TypingStatusWidget(narrow: widget.narrow),
        // TODO perhaps offer mark-as-read even when not done fetching?
        if (model.messages.isNotEmpty)
          MarkAsReadWidget(narrow: widget.narrow),
        // To reinforce that the end of the feed has been reached:
        //   https://chat.zulip.org/#narrow/channel/48-mobile/topic/space.20at.20end.20of.20thread/near/2203391
        const SizedBox(height: 12),
      ]);
    } else if (model.busyFetchingNewer) {
      // See [_buildStartCap] for why this condition shows a loading indicator.
      return const _MessageListLoadingMore();
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildItem(MessageListItem data, {required bool isLastInFeed}) {
    switch (data) {
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
          narrow: widget.narrow,
          header: header,
          isLastInFeed: isLastInFeed,
          item: data);
      case MessageListOutboxMessageItem():
        final header = RecipientHeader(message: data.message, narrow: widget.narrow);
        return MessageItem(
          narrow: widget.narrow,
          header: header,
          isLastInFeed: isLastInFeed,
          item: data);
    }
  }
}

class _MessageListHistoryStart extends StatelessWidget {
  const _MessageListHistoryStart();

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(zulipLocalizations.noEarlierMessages))); // TODO use an icon
  }
}

class _MessageListLoadingMore extends StatelessWidget {
  const _MessageListLoadingMore();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: CircularProgressIndicator())); // TODO perhaps a different indicator
  }
}

class ScrollToBottomButton extends StatelessWidget {
  const ScrollToBottomButton({
    super.key,
    required this.model,
    required this.scrollController,
    required this.visible,
  });

  final MessageListView model;
  final MessageListScrollController scrollController;
  final ValueNotifier<bool> visible;

  void _scrollToBottom() {
    if (model.haveNewest) {
      // Scrolling smoothly from here to the bottom won't require any requests
      // to the server.
      // It also probably isn't *that* far away: the user must have scrolled
      // here from there (or from near enough that a fetch reached there),
      // so scrolling back there -- at top speed -- shouldn't take too long.
      // Go for it.
      scrollController.position.scrollToEnd();
    } else {
      // This message list doesn't have the messages for the bottom of history.
      // There could be quite a lot of history between here and there --
      // for example, at first unread in the combined feed or a busy channel,
      // for a user who has some old unreads going back months and years.
      // In that case trying to scroll smoothly to the bottom is hopeless.
      //
      // Given that there were at least 100 messages between this message list's
      // initial anchor and the end of history (or else `fetchInitial` would
      // have reached the end at the outset), that situation is very likely.
      // Even if the end is close by, it's at least one fetch away.
      // Instead of scrolling, jump to the end, which is always just one fetch.
      model.jumpToEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: visible,
      builder: (BuildContext context, bool value, Widget? child) {
        return (value && child != null) ? child : const SizedBox.shrink();
      },
      // TODO: fix hardcoded values for size and style here
      child: IconButton(
        tooltip: zulipLocalizations.scrollToBottomTooltip,
        icon: const Icon(Icons.expand_circle_down_rounded),
        iconSize: 40,
        // Web has the same color in light and dark mode.
        color: const HSLColor.fromAHSL(0.5, 240, 0.96, 0.68).toColor(),
        onPressed: _scrollToBottom));
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
    final zulipLocalizations = ZulipLocalizations.of(context);
    final typistIds = model!.typistIdsInNarrow(narrow);
    final filteredTypistIds = typistIds.whereNot(store.isUserMuted);
    if (filteredTypistIds.isEmpty) return const SizedBox();
    final text = switch (filteredTypistIds.length) {
      1 => zulipLocalizations.onePersonTyping(
             store.userDisplayName(filteredTypistIds.first)),
      2 => zulipLocalizations.twoPeopleTyping(
             store.userDisplayName(filteredTypistIds.first),
             store.userDisplayName(filteredTypistIds.last)),
      _ => zulipLocalizations.manyPeopleTyping,
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
    await ZulipAction.markNarrowAsRead(context, widget.narrow);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);
    final unreadCount = store.unreads.countInNarrow(widget.narrow);
    final shouldHide = unreadCount == 0;

    final messageListTheme = MessageListTheme.of(context);

    return IgnorePointer(
      ignoring: shouldHide,
      child: MarkAsReadAnimation(
        loading: _loading,
        hidden: shouldHide,
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
              icon: const Icon(ZulipIcons.message_checked),
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

  final MessageBase message;
  final Narrow narrow;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return switch (message) {
      MessageBase<StreamConversation>() =>
        StreamMessageRecipientHeader(message: message, narrow: narrow),
      MessageBase<DmConversation>() =>
        DmRecipientHeader(message: message, narrow: narrow),
      MessageBase<Conversation>() =>
        throw StateError('Bad concrete subclass of MessageBase'),
    };
  }
}

class DateSeparator extends StatelessWidget {
  const DateSeparator({super.key, required this.message});

  final MessageBase message;

  @override
  Widget build(BuildContext context) {
    // This makes the small-caps text vertically centered,
    // to align with the vertically centered divider lines.
    const textBottomPadding = 2.0;

    final designVariables = DesignVariables.of(context);

    final line = BorderSide(width: 0, color: designVariables.foreground);

    // TODO(#681) use different color for DM messages
    return ColoredBox(color: designVariables.bgMessageRegular,
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
    required this.narrow,
    required this.item,
    required this.header,
    required this.isLastInFeed,
  });

  final Narrow narrow;
  final MessageListMessageBaseItem item;
  final Widget header;
  final bool isLastInFeed;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final item = this.item;
    Widget child = ColoredBox(
      color: designVariables.bgMessageRegular,
      child: Column(children: [
        switch (item) {
          MessageListMessageItem() => MessageWithPossibleSender(
            narrow: narrow,
            item: item),
          MessageListOutboxMessageItem() => OutboxMessageWithPossibleSender(item: item),
        },
        // TODO write tests for this padding logic
        if (isLastInFeed)
          const SizedBox(height: 5)
        else if (item.isLastInBlock)
          const SizedBox(height: 11),
      ]));
    if (item case MessageListMessageItem(:final message)) {
      child = _UnreadMarker(
        isRead: message.flags.contains(MessageFlag.read),
        child: child);
    }
    return StickyHeaderItem(
      allowOverflow: !item.isLastInBlock,
      header: header,
      child: child);
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
    required this.narrow,
  });

  final MessageBase<StreamConversation> message;
  final Narrow narrow;

  static bool _containsDifferentChannels(Narrow narrow) {
    switch (narrow) {
      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
      case KeywordSearchNarrow():
        return true;

      case ChannelNarrow():
      case TopicNarrow():
      case DmNarrow():
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // For design specs, see:
    //   https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=538%3A20849&mode=dev
    //   https://github.com/zulip/zulip-mobile/issues/5511
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);
    final messageListTheme = MessageListTheme.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final streamId = message.conversation.streamId;
    final topic = message.conversation.topic;

    final swatch = colorSwatchFor(context, store.subscriptions[streamId]);
    final backgroundColor = swatch.barBackground;
    final iconColor = swatch.iconOnBarBackground;

    final Widget streamWidget;
    if (!_containsDifferentChannels(narrow)) {
      streamWidget = const SizedBox(width: 16);
    } else {
      final stream = store.streams[streamId];
      final streamName = stream?.name
        ?? message.conversation.displayRecipient
        ?? zulipLocalizations.unknownChannelName; // TODO(log)

      streamWidget = GestureDetector(
        onTap: () => Navigator.push(context,
          MessageListPage.buildRoute(context: context,
            narrow: ChannelNarrow(streamId))),
        onLongPress: () => showChannelActionSheet(context, channelId: streamId),
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
            child: Text(topic.displayName ?? store.realmEmptyTopicDisplayName,
              // TODO: Give a way to see the whole topic (maybe a
              //   long-press interaction?)
              overflow: TextOverflow.ellipsis,
              style: recipientHeaderTextStyle(context,
                fontStyle: topic.displayName == null ? FontStyle.italic : null,
              ))),
          const SizedBox(width: 4),
          Icon(size: 14, color: designVariables.title.withFadedAlpha(0.5),
            // A null [Icon.icon] makes a blank space.
            iconDataForTopicVisibilityPolicy(
              store.topicVisibilityPolicy(streamId, topic))),
        ]));

    return GestureDetector(
      // When already in a topic narrow, disable tap interaction that would just
      // push a MessageListPage for the same topic narrow.
      // TODO(#1039) simplify by removing topic-narrow condition if we remove
      //   recipient headers in topic narrows
      onTap: narrow is TopicNarrow ? null
        : () => Navigator.push(context,
            MessageListPage.buildRoute(context: context,
              narrow: TopicNarrow.ofMessage(message))),
      onLongPress: () => showTopicActionSheet(context,
        channelId: streamId,
        topic: topic,
        someMessageIdInTopic: message.id),
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
  const DmRecipientHeader({
    super.key,
    required this.message,
    required this.narrow,
  });

  final MessageBase<DmConversation> message;
  final Narrow narrow;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);
    final String title;
    if (message.conversation.allRecipientIds.length > 1) {
      title = zulipLocalizations.messageListGroupYouAndOthers(
        message.conversation.allRecipientIds
          .where((id) => id != store.selfUserId)
          .map(store.userDisplayName)
          .sorted()
          .join(", "));
    } else {
      title = zulipLocalizations.messageListGroupYouWithYourself;
    }

    final messageListTheme = MessageListTheme.of(context);
    final designVariables = DesignVariables.of(context);

    return GestureDetector(
      // When already in a DM narrow, disable tap interaction that would just
      // push a MessageListPage for the same DM narrow.
      // TODO(#1244) simplify by removing DM-narrow condition if we remove
      //   recipient headers in DM narrows
      onTap: narrow is DmNarrow ? null
        : () => Navigator.push(context,
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
                  color: designVariables.title,
                  size: 16,
                  ZulipIcons.two_person)),
              Expanded(
                child: Text(title,
                  style: recipientHeaderTextStyle(context),
                  overflow: TextOverflow.ellipsis)),
              RecipientHeaderDate(message: message),
            ]))));
  }
}

TextStyle recipientHeaderTextStyle(BuildContext context, {FontStyle? fontStyle}) {
  return TextStyle(
    color: DesignVariables.of(context).title,
    fontSize: 16,
    letterSpacing: proportionalLetterSpacing(context, 0.02, baseFontSize: 16),
    height: (18 / 16),
    fontStyle: fontStyle,
  ).merge(weightVariableTextStyle(context, wght: 600));
}

class RecipientHeaderDate extends StatelessWidget {
  const RecipientHeaderDate({super.key, required this.message});

  final MessageBase message;

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
    final store = PerAccountStoreWidget.of(context);
    final messageListTheme = MessageListTheme.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final formattedTimestamp = MessageTimestampStyle.dateOnlyRelative.format(
      timestamp,
      now: ZulipBinding.instance.utcNow().toLocal(),
      twentyFourHourTimeMode: store.userSettings.twentyFourHourTime,
      zulipLocalizations: zulipLocalizations)!;
    return Text(
      style: TextStyle(
        color: messageListTheme.labelTime,
        fontSize: fontSize,
        height: height,
        // This is equivalent to css `all-small-caps`, see:
        //   https://developer.mozilla.org/en-US/docs/Web/CSS/font-variant-caps#all-small-caps
        fontFeatures: const [FontFeature.enable('c2sc'), FontFeature.enable('smcp')],
      ),
      formattedTimestamp);
  }
}

class SenderRow extends StatelessWidget {
  const SenderRow({super.key, required this.message, required this.timestampStyle});

  final MessageBase message;
  final MessageTimestampStyle timestampStyle;

  bool _showAsMuted(BuildContext context, PerAccountStore store) {
    final message = this.message;
    if (!store.isUserMuted(message.senderId)) return false;
    if (message is! Message) return false; // i.e., if an outbox message
    final revealedMutedMessagesState =
      MessageListPage.maybeRevealedMutedMessagesOf(context);
    // The "unrevealed" state only exists in the message list,
    // and we show a sender row in at least one place outside the message list
    // (the message action sheet).
    if (revealedMutedMessagesState == null) return false;
    return !revealedMutedMessagesState.isMutedMessageRevealed(message.id);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);
    final messageListTheme = MessageListTheme.of(context);
    final designVariables = DesignVariables.of(context);

    final sender = store.getUser(message.senderId);
    final timestamp = timestampStyle
      .format(message.timestamp,
        now: DateTime.now(),
        twentyFourHourTimeMode: store.userSettings.twentyFourHourTime,
        zulipLocalizations: zulipLocalizations);

    final showAsMuted = _showAsMuted(context, store);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: localizedTextBaseline(context),
        children: [
          Flexible(
            child: GestureDetector(
              onTap: () => showAsMuted ? null : Navigator.push(context,
                ProfilePage.buildRoute(context: context,
                  userId: message.senderId)),
              child: Row(
                children: [
                  Avatar(
                    size: 32,
                    borderRadius: 3,
                    showPresence: false,
                    replaceIfMuted: showAsMuted,
                    userId: message.senderId),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(message is Message
                        ? store.senderDisplayName(message as Message,
                            replaceIfMuted: showAsMuted)
                        : store.userDisplayName(message.senderId),
                      style: TextStyle(
                        fontSize: 18,
                        height: (22 / 18),
                        color: showAsMuted
                          ? designVariables.title.withFadedAlpha(0.5)
                          : designVariables.title,
                      ).merge(weightVariableTextStyle(context, wght: 600)),
                      overflow: TextOverflow.ellipsis)),
                  UserStatusEmoji(userId: message.senderId, size: 18,
                    padding: const EdgeInsetsDirectional.only(start: 5.0)),
                  if (sender?.isBot ?? false) ...[
                    const SizedBox(width: 5),
                    Icon(
                      ZulipIcons.bot,
                      size: 15,
                      color: messageListTheme.senderBotIcon,
                    ),
                  ],
                ]))),
          if (timestamp != null) ...[
            const SizedBox(width: 4),
            Text(timestamp,
              style: TextStyle(
                color: messageListTheme.labelTime,
                fontSize: 16,
                height: (18 / 16),
                fontFeatures: const [FontFeature.enable('c2sc'), FontFeature.enable('smcp')],
              ).merge(weightVariableTextStyle(context))),
          ],
        ]));
  }
}

enum MessageTimestampStyle {
  none,
  dateOnlyRelative,
  timeOnly,

  // TODO(#45): E.g. "Yesterday at 4:47 PM"; see details in #45
  lightbox,

  /// The longest format, with full date and time as numbers, not "Today"/etc.
  ///
  /// For UI contexts focused just on the one message,
  /// or as a tooltip on a shorter-formatted timestamp.
  ///
  /// The detail won't always be needed, but this format makes mental timezone
  /// conversions easier, which is helpful when the user is thinking about
  /// business hours on a different continent,
  /// or traveling and they know their device timezone setting is wrong, etc.
  // TODO(design) show "Today"/etc. after all? Discussion:
  //   https://github.com/zulip/zulip-flutter/pull/1624#issuecomment-3050296488
  full,
  ;

  static String _formatDateOnlyRelative(
    DateTime dateTime, {
    required DateTime now,
    required ZulipLocalizations zulipLocalizations,
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

  static final _timeFormat12 =                       DateFormat('h:mm aa');
  static final _timeFormat24 =                       DateFormat('Hm');
  static final _timeFormatLocaleDefault =            DateFormat('jm');
  static final _timeFormat12WithSeconds =            DateFormat('h:mm:ss aa');
  static final _timeFormat24WithSeconds =            DateFormat('Hms');
  static final _timeFormatLocaleDefaultWithSeconds = DateFormat('jms');

  static DateFormat _resolveTimeFormat(TwentyFourHourTimeMode mode) => switch (mode) {
    TwentyFourHourTimeMode.twelveHour => _timeFormat12,
    TwentyFourHourTimeMode.twentyFourHour => _timeFormat24,
    TwentyFourHourTimeMode.localeDefault => _timeFormatLocaleDefault,
  };

  static DateFormat _resolveTimeFormatWithSeconds(TwentyFourHourTimeMode mode) => switch (mode) {
    TwentyFourHourTimeMode.twelveHour => _timeFormat12WithSeconds,
    TwentyFourHourTimeMode.twentyFourHour => _timeFormat24WithSeconds,
    TwentyFourHourTimeMode.localeDefault => _timeFormatLocaleDefaultWithSeconds,
  };

  /// Format a [Message.timestamp] for this mode.
  // TODO(i18n): locale-specific formatting (see #45 for a plan with ffi)
  String? format(
    int messageTimestamp, {
    required DateTime now,
    required ZulipLocalizations zulipLocalizations,
    required TwentyFourHourTimeMode twentyFourHourTimeMode,
  }) {
    final asDateTime =
      DateTime.fromMillisecondsSinceEpoch(1000 * messageTimestamp);

    switch (this) {
      case none:     return null;
      case dateOnlyRelative:
        return _formatDateOnlyRelative(asDateTime,
          now: now, zulipLocalizations: zulipLocalizations);
      case timeOnly:
        return _resolveTimeFormat(twentyFourHourTimeMode).format(asDateTime);
      case lightbox:
        return DateFormat
          .yMMMd()
          .addPattern(_resolveTimeFormatWithSeconds(twentyFourHourTimeMode).pattern)
          .format(asDateTime);
      case full:
        return DateFormat
          .yMMMd()
          .addPattern(_resolveTimeFormat(twentyFourHourTimeMode).pattern)
          .format(asDateTime);
    }
  }
}

/// A Zulip message, showing the sender's name and avatar if specified.
// Design referenced from:
//   - https://github.com/zulip/zulip-mobile/issues/5511
//   - https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=538%3A20849&mode=dev
class MessageWithPossibleSender extends StatelessWidget {
  const MessageWithPossibleSender({
    super.key,
    required this.narrow,
    required this.item,
  });

  final Narrow narrow;
  final MessageListMessageItem item;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);
    final message = item.message;

    final zulipLocalizations = ZulipLocalizations.of(context);
    String? editStateText;
    switch (message.editState) {
      case MessageEditState.edited:
        editStateText = zulipLocalizations.messageIsEditedLabel;
      case MessageEditState.moved:
        editStateText = zulipLocalizations.messageIsMovedLabel;
      case MessageEditState.none:
    }

    Widget? star;
    if (message.flags.contains(MessageFlag.starred)) {
      final starOffset = switch (Directionality.of(context)) {
        TextDirection.ltr => -2.0,
        TextDirection.rtl => 2.0,
      };
      star = Transform.translate(
        offset: Offset(starOffset, 0),
        child: Icon(ZulipIcons.star_filled, size: 16, color: designVariables.star));
    }

    Widget content = MessageContent(message: message, content: item.content);

    final editMessageErrorStatus = store.getEditMessageErrorStatus(message.id);
    if (editMessageErrorStatus != null) {
      // The Figma also fades the sender row:
      //   https://github.com/zulip/zulip-flutter/pull/1498#discussion_r2076574000
      // We've decided to just fade the message content because that's the only
      // thing that's changing.
      content = Opacity(opacity: 0.6, child: content);
      if (!editMessageErrorStatus) {
        // IgnorePointer neutralizes interactable message content like links;
        // this seemed appropriate along with the faded appearance.
        content = IgnorePointer(child: content);
      } else {
        content = _RestoreEditMessageGestureDetector(messageId: message.id,
          child: content);
      }
    }

    final tapOpensConversation = switch (narrow) {
      CombinedFeedNarrow()
        || ChannelNarrow()
        || TopicNarrow()
        || DmNarrow() => false,
      MentionsNarrow()
        || StarredMessagesNarrow()
        || KeywordSearchNarrow() => true,
    };

    final showAsMuted = store.isUserMuted(message.senderId)
      && !MessageListPage.maybeRevealedMutedMessagesOf(context)!
                         .isMutedMessageRevealed(message.id);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: tapOpensConversation
        ? () => unawaited(Navigator.push(context,
            MessageListPage.buildRoute(context: context,
              narrow: SendableNarrow.ofMessage(message, selfUserId: store.selfUserId),
              // TODO(#1655) "this view does not mark messages as read on scroll"
              initAnchorMessageId: message.id)))
        : null,
      onLongPress: showAsMuted
        ? null // TODO write a test for this
        : () => showMessageActionSheet(context: context, message: message),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(children: [
          if (item.showSender)
            SenderRow(message: message,
              timestampStyle: MessageTimestampStyle.timeOnly),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: localizedTextBaseline(context),
            children: [
              const SizedBox(width: 16),
              Expanded(child: showAsMuted
                ? Align(
                    alignment: AlignmentDirectional.topStart,
                    child: ZulipWebUiKitButton(
                      label: zulipLocalizations.revealButtonLabel,
                      icon: ZulipIcons.eye,
                      size: ZulipWebUiKitButtonSize.small,
                      intent: ZulipWebUiKitButtonIntent.neutral,
                      attention: ZulipWebUiKitButtonAttention.minimal,
                      onPressed: () {
                        MessageListPage.ancestorOf(context).revealMutedMessage(message.id);
                      }))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      content,
                      if ((message.reactions?.total ?? 0) > 0)
                        ReactionChipsList(messageId: message.id, reactions: message.reactions!),
                      if (editMessageErrorStatus != null)
                        _EditMessageStatusRow(messageId: message.id, status: editMessageErrorStatus)
                      else if (editStateText != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(editStateText,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: designVariables.labelEdited,
                              fontSize: 12,
                              height: (12 / 12),
                              letterSpacing: proportionalLetterSpacing(context,
                                0.05, baseFontSize: 12))))
                      else
                        Padding(padding: const EdgeInsets.only(bottom: 4))
                    ])),
              SizedBox(width: 16,
                child: star),
            ]),
        ])));
  }
}

class _EditMessageStatusRow extends StatelessWidget {
  const _EditMessageStatusRow({
    required this.messageId,
    required this.status,
  });

  final int messageId;
  final bool status;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final baseTextStyle = TextStyle(
      fontSize: 12,
      height: 12 / 12,
      letterSpacing: proportionalLetterSpacing(context,
        0.05, baseFontSize: 12));

    return switch (status) {
      // TODO parse markdown and show new content as local echo?
      false => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 1.5,
          children: [
            Text(
              style: baseTextStyle
                .copyWith(color: designVariables.btnLabelAttLowIntInfo),
              textAlign: TextAlign.end,
              zulipLocalizations.savingMessageEditLabel),
            // TODO instead place within bottom outer padding:
            //   https://github.com/zulip/zulip-flutter/pull/1498#discussion_r2087576108
            LinearProgressIndicator(
              minHeight: 2,
              color: designVariables.foreground.withValues(alpha: 0.5),
              backgroundColor: designVariables.foreground.withValues(alpha: 0.2),
            ),
          ])),
      true => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: _RestoreEditMessageGestureDetector(
          messageId: messageId,
          child: Text(
            style: baseTextStyle
              .copyWith(color: designVariables.btnLabelAttLowIntDanger),
            textAlign: TextAlign.end,
            zulipLocalizations.savingMessageEditFailedLabel))),
    };
  }
}

class _RestoreEditMessageGestureDetector extends StatelessWidget {
  const _RestoreEditMessageGestureDetector({
    required this.messageId,
    required this.child,
  });

  final int messageId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final composeBoxState = MessageListPage.ancestorOf(context).composeBoxState;
        // TODO(#1518) allow restore-edit-message from any message-list page
        if (composeBoxState == null) return;
        composeBoxState.startEditInteraction(messageId);
      },
      child: child);
  }
}

/// A "local echo" placeholder for a Zulip message to be sent by the self-user.
///
/// See also [OutboxMessage].
class OutboxMessageWithPossibleSender extends StatelessWidget {
  const OutboxMessageWithPossibleSender({super.key, required this.item});

  final MessageListOutboxMessageItem item;

  @override
  Widget build(BuildContext context) {
    final message = item.message;
    final localMessageId = message.localMessageId;

    // This is adapted from [MessageContent].
    // TODO(#576): Offer InheritedMessage ancestor once we are ready
    //   to support local echoing images and lightbox.
    Widget content = DefaultTextStyle(
      style: ContentTheme.of(context).textStylePlainParagraph,
      child: BlockContentList(nodes: item.content.nodes));

    switch (message.state) {
      case OutboxMessageState.hidden:
        throw StateError('Hidden OutboxMessage messages should not appear in message lists');
      case OutboxMessageState.waiting:
        break;
      case OutboxMessageState.failed:
      case OutboxMessageState.waitPeriodExpired:
        // TODO(#576): When we support rendered-content local echo,
        //   use IgnorePointer along with this faded appearance,
        //   like we do for the failed-message-edit state
        content = _RestoreOutboxMessageGestureDetector(
          localMessageId: localMessageId,
          child: Opacity(opacity: 0.6, child: content));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(children: [
        if (item.showSender)
          SenderRow(message: message, timestampStyle: MessageTimestampStyle.none),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              content,
              _OutboxMessageStatusRow(
                localMessageId: localMessageId, outboxMessageState: message.state),
            ])),
      ]));
  }
}

class _OutboxMessageStatusRow extends StatelessWidget {
  const _OutboxMessageStatusRow({
    required this.localMessageId,
    required this.outboxMessageState,
  });

  final int localMessageId;
  final OutboxMessageState outboxMessageState;

  @override
  Widget build(BuildContext context) {
    switch (outboxMessageState) {
      case OutboxMessageState.hidden:
        assert(false,
          'Hidden OutboxMessage messages should not appear in message lists');
        return SizedBox.shrink();

      case OutboxMessageState.waiting:
        final designVariables = DesignVariables.of(context);
        return Padding(
          padding: const EdgeInsetsGeometry.only(bottom: 2),
          child: LinearProgressIndicator(
            minHeight: 2,
            color: designVariables.foreground.withFadedAlpha(0.5),
            backgroundColor: designVariables.foreground.withFadedAlpha(0.2)));

      case OutboxMessageState.failed:
      case OutboxMessageState.waitPeriodExpired:
        final designVariables = DesignVariables.of(context);
        final zulipLocalizations = ZulipLocalizations.of(context);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _RestoreOutboxMessageGestureDetector(
            localMessageId: localMessageId,
            child: Text(
              zulipLocalizations.messageNotSentLabel,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: designVariables.btnLabelAttLowIntDanger,
                fontSize: 12,
                height: 12 / 12,
                letterSpacing: proportionalLetterSpacing(
                  context, 0.05, baseFontSize: 12)))));
    }
  }
}

class _RestoreOutboxMessageGestureDetector extends StatelessWidget {
  const _RestoreOutboxMessageGestureDetector({
    required this.localMessageId,
    required this.child,
  });

  final int localMessageId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final composeBoxState = MessageListPage.ancestorOf(context).composeBoxState;
        // TODO(#1518) allow restore-outbox-message from any message-list page
        if (composeBoxState == null) return;
        composeBoxState.restoreMessageNotSent(localMessageId);
      },
      child: child);
  }
}
