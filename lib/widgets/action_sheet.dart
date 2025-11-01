import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../api/exception.dart';
import '../api/model/model.dart';
import '../api/route/channels.dart';
import '../api/route/messages.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/binding.dart';
import '../model/content.dart';
import '../model/emoji.dart';
import '../model/internal_link.dart';
import '../model/narrow.dart';
import 'actions.dart';
import 'button.dart';
import 'color.dart';
import 'compose_box.dart';
import 'content.dart';
import 'dialog.dart';
import 'emoji.dart';
import 'emoji_reaction.dart';
import 'icons.dart';
import 'inset_shadow.dart';
import 'message_list.dart';
import 'page.dart';
import 'read_receipts.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'topic_list.dart';

/// Show an action sheet with scrollable menu buttons
/// and an optional scrollable header.
///
/// [header] should not use vertical padding to position itself on the sheet.
/// It will be wrapped in vertical padding
/// and, if [headerScrollable], a scroll view and an [InsetShadowBox].
void _showActionSheet(
  BuildContext pageContext, {
  Widget? header,
  bool headerScrollable = true,
  required List<List<Widget>> buttonSections,
}) {
  assert(header is! BottomSheetHeader || !header.outerVerticalPadding);

  // Could omit this if we need _showActionSheet outside a per-account context.
  final accountId = PerAccountStoreWidget.accountIdOf(pageContext);

  showModalBottomSheet<void>(
    context: pageContext,
    // Clip.hardEdge looks bad; Clip.antiAliasWithSaveLayer looks pixel-perfect
    // on my iPhone 13 Pro but is marked as "much slower":
    //   https://api.flutter.dev/flutter/dart-ui/Clip.html
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (BuildContext _) {
      final designVariables = DesignVariables.of(pageContext);

      Widget? effectiveHeader;
      if (header != null) {
        effectiveHeader = headerScrollable
          ? Flexible(
              // TODO(upstream) Enforce a flex ratio (e.g. 1:3)
              //   only when the header height plus the buttons' height
              //   exceeds available space. Otherwise let one or the other
              //   grow to fill available space even if it breaks the ratio.
              //   Needs support for separate properties like `flex-grow`
              //   and `flex-shrink`.
              flex: 1,
              child: InsetShadowBox(
                top: 8, bottom: 8,
                color: designVariables.bgContextMenu,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: header)))
          : Padding(
              padding: EdgeInsets.only(top: 16, bottom: 4),
              child: header);
      }

      final body = Flexible(
        flex: (effectiveHeader != null && headerScrollable)
          ? 3
          : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: InsetShadowBox(
                top: 8, bottom: 8,
                color: designVariables.bgContextMenu,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: buttonSections.map((buttons) =>
                      MenuButtonsShape(buttons: buttons)).toList())))),
              const BottomSheetDismissButton(style: BottomSheetDismissButtonStyle.cancel),
            ])));

      return PerAccountStoreWidget(
        accountId: accountId,
        child: Semantics(
          role: SemanticsRole.menu,
          child: SafeArea(
            minimum: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (effectiveHeader != null)
                  effectiveHeader
                else
                  SizedBox(height: 8),
                body,
              ]))));
    });
}

typedef WidgetBuilderFromTextStyle = Widget Function(TextStyle);

/// A header for a bottom sheet with an optional title and multiline message.
///
/// A title, message, or both must be provided.
///
/// Provide a title by passing [title] or [buildTitle] (not both).
/// Provide a message by passing [message] or [buildMessage] (not both).
/// The "build" params support richer content, such as [TextWithLink],
/// and the callback is passed a [TextStyle] which is the base style.
///
/// To add outer vertical padding to position the header on the sheet,
/// pass true for [outerVerticalPadding].
///
/// Figma; just message no title:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3481-26993&m=dev
///
/// Figma; title and message:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=6326-96125&m=dev
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=11367-20898&m=dev
/// The latter example (read receipts) has more horizontal and bottom padding;
/// that looks like an accident that we don't need to follow.
/// It also colors the message text more opaquely…that difference might be
/// intentional, but Vlad's time is limited and I prefer consistency.
class BottomSheetHeader extends StatelessWidget {
  const BottomSheetHeader({
    super.key,
    this.title,
    this.buildTitle,
    this.message,
    this.buildMessage,
    this.outerVerticalPadding = false,
  }) : assert(message == null || buildMessage == null),
       assert(title == null || buildTitle == null),
       assert((message != null || buildMessage != null)
              || (title != null || buildTitle != null));

  final String? title;
  final Widget Function(TextStyle)? buildTitle;
  final String? message;
  final Widget Function(TextStyle)? buildMessage;
  final bool outerVerticalPadding;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final baseTitleStyle = TextStyle(
      fontSize: 20,
      // More height than in Figma, but it was looking too tight:
      //   https://github.com/zulip/zulip-flutter/pull/1877#issuecomment-3379664807
      // (See use of TextHeightBehavior below.)
      height: 24 / 20,
      color: designVariables.title,
    ).merge(weightVariableTextStyle(context, wght: 600));

    Widget? effectiveTitle = switch ((buildTitle, title)) {
      (final build?, null) => build(baseTitleStyle),
      (null,  final data?) => Text(style: baseTitleStyle, data),
      _                    => null,
    };

    if (effectiveTitle != null) {
      effectiveTitle = DefaultTextHeightBehavior(
        textHeightBehavior: TextHeightBehavior(
          // We want some breathing room between lines,
          // without adding margin above or below the title.
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
        child: effectiveTitle);
    }

    final baseMessageStyle = TextStyle(
      color: designVariables.labelTime,
      fontSize: 17,
      height: 22 / 17);

    final effectiveMessage = switch ((buildMessage, message)) {
      (final build?, null) => build(baseMessageStyle),
      (null,  final data?) => Text(style: baseMessageStyle, data),
      _                    => null,
    };

    Widget result = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [?effectiveTitle, ?effectiveMessage]));

    if (outerVerticalPadding) {
      result = Padding(
        padding: EdgeInsets.only(top: 16, bottom: 4),
        child: result);
    }

    return result;
  }
}

/// A placeholder for when a bottom sheet has no content to show.
///
/// Pass [message] for a "no-content-here" message,
/// or pass true for [loading] if the content hasn't finished loading yet,
/// but don't pass both.
///
/// Show this below a [BottomSheetHeader] if present.
///
/// See also:
///  * [PageBodyEmptyContentPlaceholder], for a similar element to use in
///    pages on the home screen.
// TODO(design) we don't yet have a design for this;
//   it was ad-hoc and modeled on [PageBodyEmptyContentPlaceholder].
class BottomSheetEmptyContentPlaceholder extends StatelessWidget {
  const BottomSheetEmptyContentPlaceholder({
    super.key,
    this.message,
    this.loading = false,
  }) : assert((message != null) ^ loading);

  final String? message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final child = loading
      ? CircularProgressIndicator()
      : Text(
          textAlign: TextAlign.center,
          style: TextStyle(
            color: designVariables.labelSearchPrompt,
            fontSize: 17,
            height: 23 / 17,
          ).merge(weightVariableTextStyle(context, wght: 500)),
          message!);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 48, 24, 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: child));
  }
}

/// A bottom sheet that resizes, scrolls, and dismisses in response to dragging.
///
/// [header] is assumed to occupy the full width its parent allows.
/// (This is important for the clipping/shadow effect when [contentSliver]
/// scrolls under the header.)
///
/// The sheet's initial height and minimum height before dismissing
/// are set proportionally to the screen's height.
/// The screen's height is read from the parent's max-height constraint,
/// so the caller should not introduce widgets that interfere with that.
/// (Non-layout wrapper widgets such as [InheritedWidget]s are OK.)
///
/// The sheet's dismissal works like this:
/// - A "Close" button is offered.
/// - A drag-down or fling on the header or the [contentSliver]
///   causes those areas to shrink past a threshold at which the sheet
///   decides to dismiss.
/// - The [enableDrag] param of upstream's [showModalBottomSheet]
///   only seems to affect gesture handling on the Close button and its padding
///   (which are not part of the resizable/scrollable area):
///   - When true, the Close button responds to a downward fling by
///     sliding the sheet downward and dismissing it
///     (i.e. not by the usual behavior where the header- and-content height
///     shrinks past a threshold, causing dismissal).
///   - When false, the Close button doesn't respond to a downward fling.
class DraggableScrollableModalBottomSheet extends StatelessWidget {
  const DraggableScrollableModalBottomSheet({
    super.key,
    required this.header,
    required this.contentSliver,
  });

  final Widget header;
  final Widget contentSliver;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, controller) {
        final backgroundColor = Theme.of(context).bottomSheetTheme.backgroundColor!;

        // The "inset shadow" effect in Figma is a bit awkwardly
        // implemented here, and there might be a better factoring:
        // 1. This effect leans on the abstraction that [contentSliver]
        //    is simply a scrollable area in its own viewport.
        //    We'd normally just wrap that viewport in [InsetShadowBox].
        // 2. Really, though, the scrollable includes the header,
        //    pinned to the viewport top. We do this to support resizing
        //    (and dismiss-on-min-height) on gestures in the header, too,
        //    uniformly with the content.
        // 3. So for the top shadow, we tack a shadow gradient onto the header,
        //    exploiting the header's pinning behavior to keep it fixed.
        // 3. For the bottom, I haven't found a nice sliver-based implementation
        //    that supports pinning a shadow overlay at the viewport bottom.
        //    So for the bottom we use [InsetShadowBox] around the viewport,
        //    with just `bottom:` and no `top:`.

        final headerWithShadow = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColoredBox(
              color: backgroundColor,
              child: header),
            SizedBox(height: 8, width: double.infinity,
              child: DecoratedBox(decoration: fadeToTransparencyDecoration(
                FadeToTransparencyDirection.down, backgroundColor))),
          ]);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: InsetShadowBox(
                bottom: 8,
                color: backgroundColor,
                child: CustomScrollView(
                  // The iOS default "bouncing" effect would look uncoordinated
                  // in the common case where overscroll co-occurs with
                  // shrinking the sheet past the threshold where it dismisses.
                  physics: ClampingScrollPhysics(),
                  controller: controller,
                  slivers: [
                    PinnedHeaderSliver(child: headerWithShadow),
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: 8),
                      sliver: contentSliver),
                  ]))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const BottomSheetDismissButton(style: BottomSheetDismissButtonStyle.close))
          ]);
    });
  }
}

/// A button in an action sheet.
///
/// When built from server data, the action sheet ignores changes in that data;
/// we intentionally don't live-update the buttons on events.
/// If a button's label, action, or position changes suddenly,
/// it can be confusing and make the on-tap behavior unexpected.
/// Better to let the user decide to tap
/// based on information that's comfortably in their working memory,
/// even if we sometimes have to explain (where we handle the tap)
/// that that information has changed and they need to decide again.
///
/// (Even if we did live-update the buttons, it's possible anyway that a user's
/// action can race with a change that's already been applied on the server,
/// because it takes some time for the server to report changes to us.)
abstract class ActionSheetMenuItemButton extends StatelessWidget {
  const ActionSheetMenuItemButton({super.key, required this.pageContext});

  IconData get icon;
  String label(ZulipLocalizations zulipLocalizations);
  bool get destructive => false;

  /// Called when the button is pressed, after dismissing the action sheet.
  ///
  /// If the action may take a long time, this method is responsible for
  /// arranging any form of progress feedback that may be desired.
  ///
  /// For operations that need a [BuildContext], see [pageContext].
  void onPressed();

  /// A context within the [MessageListPage] this action sheet was
  /// triggered from.
  final BuildContext pageContext;

  /// The [MessageListPageState] this action sheet was triggered from.
  ///
  /// Uses the inefficient [BuildContext.findAncestorStateOfType];
  /// don't call this in a build method.
  MessageListPageState findMessageListPage() {
    assert(pageContext.mounted,
      'findMessageListPage should be called only when pageContext is known to still be mounted');
    return MessageListPage.ancestorOf(pageContext);
  }

  void _handlePressed(BuildContext context) {
    // Dismiss the enclosing action sheet immediately,
    // for swift UI feedback that the user's selection was received.
    Navigator.of(context).pop();

    assert(pageContext.mounted);
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return ZulipMenuItemButton(
      style: destructive
        ? ZulipMenuItemButtonStyle.menuDestructive
        : ZulipMenuItemButtonStyle.menu,
      icon: icon,
      label: label(zulipLocalizations),
      onPressed: () => _handlePressed(context),
    );
  }
}

/// A stretched gray "Cancel" / "Close" button for the bottom of a bottom sheet.
class BottomSheetDismissButton extends StatelessWidget {
  const BottomSheetDismissButton({super.key, required this.style});

  final BottomSheetDismissButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final label = switch (style) {
      BottomSheetDismissButtonStyle.cancel => zulipLocalizations.dialogCancel,
      BottomSheetDismissButtonStyle.close => zulipLocalizations.dialogClose,
    };

    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.all(10),
        foregroundColor: designVariables.contextMenuCancelText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        splashFactory: NoSplash.splashFactory,
      ).copyWith(backgroundColor: WidgetStateColor.fromMap({
        WidgetState.pressed: designVariables.contextMenuCancelPressedBg,
        ~WidgetState.pressed: designVariables.contextMenuCancelBg,
      })),
      onPressed: () {
        Navigator.pop(context);
      },
      child: Text(label,
        style: const TextStyle(fontSize: 20, height: 24 / 20)
          .merge(weightVariableTextStyle(context, wght: 600))));
  }
}

enum BottomSheetDismissButtonStyle {
  /// The "Cancel" label, for action sheets.
  cancel,

  /// The "Close" label, for bottom sheets that are read-only or for navigation.
  close,
}

/// Show a sheet of actions you can take on a channel.
///
/// Needs a [PageRoot] ancestor.
/// May or may not have a [MessageListPage] ancestor;
/// some callers are on that page and some aren't.
void showChannelActionSheet(BuildContext context, {
  required int channelId,
  bool showTopicListButton = true,
}) {
  final pageContext = PageRoot.contextOf(context);
  final store = PerAccountStoreWidget.of(pageContext);
  final messageListPageState = MessageListPage.maybeAncestorOf(pageContext);

  final messageListPageNarrow = messageListPageState?.narrow;
  final isOnChannelFeed = messageListPageNarrow is ChannelNarrow
    && messageListPageNarrow.streamId == channelId;

  final unreadCount = store.unreads.countInChannelNarrow(channelId);
  final channel = store.streams[channelId];
  final isSubscribed = channel is Subscription;
  final buttonSections = [
    if (!isSubscribed
        && channel != null && store.selfHasContentAccess(channel))
      [SubscribeButton(pageContext: pageContext, channelId: channelId)],
    [
      if (unreadCount > 0)
        MarkChannelAsReadButton(pageContext: pageContext, channelId: channelId),
      if (showTopicListButton)
        TopicListButton(pageContext: pageContext, channelId: channelId),
      if (!isOnChannelFeed)
        ChannelFeedButton(pageContext: pageContext, channelId: channelId),
      CopyChannelLinkButton(channelId: channelId, pageContext: pageContext)
    ],
    if (isSubscribed)
      [UnsubscribeButton(pageContext: pageContext, channelId: channelId)],
  ];

  final header = BottomSheetHeader(
    buildTitle: (baseStyle) => Text.rich(
      style: baseStyle,
      channelTopicLabelSpan(
        context: context,
        channelId: channelId,
        fontSize: baseStyle.fontSize!,
        color: baseStyle.color!)),
    // TODO(#1896) show channel description
  );

  _showActionSheet(pageContext,
    header: header,
    headerScrollable: false,
    buttonSections: buttonSections);
}

class SubscribeButton extends ActionSheetMenuItemButton {
  const SubscribeButton({
    super.key,
    required this.channelId,
    required super.pageContext,
  });

  final int channelId;

  @override
  IconData get icon => ZulipIcons.plus;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionSubscribe;
  }

  @override
  void onPressed() async {
    await ZulipAction.subscribeToChannel(pageContext, channelId: channelId);
  }
}

class MarkChannelAsReadButton extends ActionSheetMenuItemButton {
  const MarkChannelAsReadButton({
    super.key,
    required this.channelId,
    required super.pageContext,
  });

  final int channelId;

  @override
  IconData get icon => ZulipIcons.message_checked;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionMarkChannelAsRead;
  }

  @override
  void onPressed() async {
    final narrow = ChannelNarrow(channelId);
    await ZulipAction.markNarrowAsRead(pageContext, narrow);
  }
}

class TopicListButton extends ActionSheetMenuItemButton {
  const TopicListButton({
    super.key,
    required this.channelId,
    required super.pageContext,
  });

  final int channelId;

  @override
  IconData get icon => ZulipIcons.topics;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionListOfTopics;
  }

  @override
  void onPressed() {
    Navigator.push(pageContext,
      TopicListPage.buildRoute(context: pageContext, streamId: channelId));
  }
}

class ChannelFeedButton extends ActionSheetMenuItemButton {
  const ChannelFeedButton({
    super.key,
    required this.channelId,
    required super.pageContext,
  });

  final int channelId;

  @override
  IconData get icon => ZulipIcons.message_feed;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionChannelFeed;
  }

  @override
  void onPressed() {
    Navigator.push(pageContext,
      MessageListPage.buildRoute(context: pageContext, narrow: ChannelNarrow(channelId)));
  }
}

class CopyChannelLinkButton extends ActionSheetMenuItemButton {
  const CopyChannelLinkButton({
    super.key,
    required this.channelId,
    required super.pageContext,
  });

  final int channelId;

  @override
  IconData get icon => ZulipIcons.link;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionCopyChannelLink;
  }

  @override
  void onPressed() async {
    final zulipLocalizations = ZulipLocalizations.of(pageContext);
    final store = PerAccountStoreWidget.of(pageContext);

    PlatformActions.copyWithPopup(context: pageContext,
      successContent: Text(zulipLocalizations.successChannelLinkCopied),
      data: ClipboardData(text: narrowLink(store, ChannelNarrow(channelId)).toString()));
  }
}

class UnsubscribeButton extends ActionSheetMenuItemButton {
  const UnsubscribeButton({
    super.key,
    required this.channelId,
    required super.pageContext,
  });

  final int channelId;

  @override
  IconData get icon => ZulipIcons.circle_x;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionUnsubscribe;
  }

  @override
  void onPressed() async {
    await ZulipAction.unsubscribeFromChannel(pageContext, channelId: channelId);
  }
}

/// Show a sheet of actions you can take on a topic.
///
/// Needs a [PageRoot] ancestor.
///
/// The API request for resolving/unresolving a topic needs a message ID.
/// If [someMessageIdInTopic] is null, the button for that will be absent.
void showTopicActionSheet(BuildContext context, {
  required int channelId,
  required TopicName topic,
  required int? someMessageIdInTopic,
}) {
  final pageContext = PageRoot.contextOf(context);

  final store = PerAccountStoreWidget.of(pageContext);
  final subscription = store.subscriptions[channelId];

  final optionButtons = <ActionSheetMenuItemButton>[];

  // TODO(server-7): simplify this condition away
  final supportsUnmutingTopics = store.zulipFeatureLevel >= 170;
  // TODO(server-8): simplify this condition away
  final supportsFollowingTopics = store.zulipFeatureLevel >= 219;

  final visibilityOptions = <UserTopicVisibilityPolicy>[];
  final visibilityPolicy = store.topicVisibilityPolicy(channelId, topic);
  if (subscription == null) {
    // Not subscribed to the channel; there is no user topic change to be made.
  } else if (!subscription.isMuted) {
    // Channel is subscribed and not muted.
    switch (visibilityPolicy) {
      case UserTopicVisibilityPolicy.muted:
        visibilityOptions.add(UserTopicVisibilityPolicy.none);
        if (supportsFollowingTopics) {
          visibilityOptions.add(UserTopicVisibilityPolicy.followed);
        }
      case UserTopicVisibilityPolicy.none:
      case UserTopicVisibilityPolicy.unmuted:
        visibilityOptions.add(UserTopicVisibilityPolicy.muted);
        if (supportsFollowingTopics) {
          visibilityOptions.add(UserTopicVisibilityPolicy.followed);
        }
      case UserTopicVisibilityPolicy.followed:
        visibilityOptions.add(UserTopicVisibilityPolicy.muted);
        if (supportsFollowingTopics) {
          visibilityOptions.add(UserTopicVisibilityPolicy.none);
        }
      case UserTopicVisibilityPolicy.unknown:
        // TODO(#1074): This should be unreachable as we keep `unknown` out of
        //   our data structures.
        assert(false);
    }
  } else {
    // Channel is muted.
    if (supportsUnmutingTopics) {
      switch (visibilityPolicy) {
        case UserTopicVisibilityPolicy.none:
        case UserTopicVisibilityPolicy.muted:
          visibilityOptions.add(UserTopicVisibilityPolicy.unmuted);
          if (supportsFollowingTopics) {
            visibilityOptions.add(UserTopicVisibilityPolicy.followed);
          }
        case UserTopicVisibilityPolicy.unmuted:
          visibilityOptions.add(UserTopicVisibilityPolicy.muted);
          if (supportsFollowingTopics) {
            visibilityOptions.add(UserTopicVisibilityPolicy.followed);
          }
        case UserTopicVisibilityPolicy.followed:
          visibilityOptions.add(UserTopicVisibilityPolicy.muted);
          if (supportsFollowingTopics) {
            visibilityOptions.add(UserTopicVisibilityPolicy.none);
          }
        case UserTopicVisibilityPolicy.unknown:
          // TODO(#1074): This should be unreachable as we keep `unknown` out of
          //   our data structures.
          assert(false);
      }
    }
  }
  optionButtons.addAll(visibilityOptions.map((to) {
    return UserTopicUpdateButton(
      currentVisibilityPolicy: visibilityPolicy,
      newVisibilityPolicy: to,
      narrow: TopicNarrow(channelId, topic),
      pageContext: pageContext);
  }));

  // TODO: check for other cases that may disallow this action (e.g.: time
  //   limit for editing topics).
  if (someMessageIdInTopic != null && topic.displayName != null) {
    optionButtons.add(ResolveUnresolveButton(pageContext: pageContext,
      topic: topic,
      someMessageIdInTopic: someMessageIdInTopic));
  }

  final unreadCount = store.unreads.countInTopicNarrow(channelId, topic);
  if (unreadCount > 0) {
    optionButtons.add(MarkTopicAsReadButton(
      channelId: channelId,
      topic: topic,
      pageContext: context));
  }

  optionButtons.add(CopyTopicLinkButton(
    narrow: TopicNarrow(channelId, topic, with_: someMessageIdInTopic),
    pageContext: context));

  final header = BottomSheetHeader(
    buildTitle: (baseStyle) => Text.rich(
      style: baseStyle,
      channelTopicLabelSpan(
        context: context,
        channelId: channelId,
        topic: topic,
        fontSize: baseStyle.fontSize!,
        color: baseStyle.color!)));

  _showActionSheet(pageContext,
    header: header,
    headerScrollable: false,
    buttonSections: [optionButtons]);
}

class UserTopicUpdateButton extends ActionSheetMenuItemButton {
  const UserTopicUpdateButton({
    super.key,
    required this.currentVisibilityPolicy,
    required this.newVisibilityPolicy,
    required this.narrow,
    required super.pageContext,
  });

  final UserTopicVisibilityPolicy currentVisibilityPolicy;
  final UserTopicVisibilityPolicy newVisibilityPolicy;
  final TopicNarrow narrow;

  @override IconData get icon {
    switch (newVisibilityPolicy) {
      case UserTopicVisibilityPolicy.none:
        return ZulipIcons.inherit;
      case UserTopicVisibilityPolicy.muted:
        return ZulipIcons.mute;
      case UserTopicVisibilityPolicy.unmuted:
        return ZulipIcons.unmute;
      case UserTopicVisibilityPolicy.followed:
        return ZulipIcons.follow;
      case UserTopicVisibilityPolicy.unknown:
        // TODO(#1074): This should be unreachable as we keep `unknown` out of
        //   our data structures.
        assert(false);
        return ZulipIcons.inherit;
    }
  }

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    switch ((currentVisibilityPolicy, newVisibilityPolicy)) {
      case (UserTopicVisibilityPolicy.muted, UserTopicVisibilityPolicy.none):
        return zulipLocalizations.actionSheetOptionUnmuteTopic;
      case (UserTopicVisibilityPolicy.followed, UserTopicVisibilityPolicy.none):
        return zulipLocalizations.actionSheetOptionUnfollowTopic;

      case (_, UserTopicVisibilityPolicy.muted):
        return zulipLocalizations.actionSheetOptionMuteTopic;
      case (_, UserTopicVisibilityPolicy.unmuted):
        return zulipLocalizations.actionSheetOptionUnmuteTopic;
      case (_, UserTopicVisibilityPolicy.followed):
        return zulipLocalizations.actionSheetOptionFollowTopic;

      case (_, UserTopicVisibilityPolicy.none):
        // This is unexpected because `UserTopicVisibilityPolicy.muted` and
        // `UserTopicVisibilityPolicy.followed` (handled in separate `case`'s)
        // are the only expected `currentVisibilityPolicy`
        // when `newVisibilityPolicy` is `UserTopicVisibilityPolicy.none`.
        assert(false);
        return '';

      case (_, UserTopicVisibilityPolicy.unknown):
        // This case is unreachable (or should be) because we keep `unknown` out
        // of our data structures. We plan to remove the `unknown` case in #1074.
        assert(false);
        return '';
    }
  }

  String _errorTitle(ZulipLocalizations zulipLocalizations) {
    switch ((currentVisibilityPolicy, newVisibilityPolicy)) {
      case (UserTopicVisibilityPolicy.muted, UserTopicVisibilityPolicy.none):
        return zulipLocalizations.errorUnmuteTopicFailed;
      case (UserTopicVisibilityPolicy.followed, UserTopicVisibilityPolicy.none):
        return zulipLocalizations.errorUnfollowTopicFailed;

      case (_, UserTopicVisibilityPolicy.muted):
        return zulipLocalizations.errorMuteTopicFailed;
      case (_, UserTopicVisibilityPolicy.unmuted):
        return zulipLocalizations.errorUnmuteTopicFailed;
      case (_, UserTopicVisibilityPolicy.followed):
        return zulipLocalizations.errorFollowTopicFailed;

      case (_, UserTopicVisibilityPolicy.none):
        // This is unexpected because `UserTopicVisibilityPolicy.muted` and
        // `UserTopicVisibilityPolicy.followed` (handled in separate `case`'s)
        // are the only expected `currentVisibilityPolicy`
        // when `newVisibilityPolicy` is `UserTopicVisibilityPolicy.none`.
        assert(false);
        return '';

      case (_, UserTopicVisibilityPolicy.unknown):
        // This case is unreachable (or should be) because we keep `unknown` out
        // of our data structures. We plan to remove the `unknown` case in #1074.
        assert(false);
        return '';
    }
  }

  @override void onPressed() async {
    try {
      await updateUserTopicCompat(
        PerAccountStoreWidget.of(pageContext).connection,
        streamId: narrow.streamId,
        topic: narrow.topic,
        visibilityPolicy: newVisibilityPolicy);
    } catch (e) {
      if (!pageContext.mounted) return;

      String? errorMessage;

      switch (e) {
        case ZulipApiException():
          errorMessage = e.message;
          // TODO(#741) specific messages for common errors, like network errors
          //   (support with reusable code)
        default:
      }

      final zulipLocalizations = ZulipLocalizations.of(pageContext);
      showErrorDialog(context: pageContext,
        title: _errorTitle(zulipLocalizations), message: errorMessage);
    }
  }
}

class ResolveUnresolveButton extends ActionSheetMenuItemButton {
  ResolveUnresolveButton({
    super.key,
    required this.topic,
    required this.someMessageIdInTopic,
    required super.pageContext,
  }) : _actionIsResolve = !topic.isResolved;

  /// The topic that the action sheet was opened for.
  ///
  /// There might not currently be any messages with this topic;
  /// see dartdoc of [ActionSheetMenuItemButton].
  final TopicName topic;

  /// The message ID that was passed when opening the action sheet.
  ///
  /// The message with this ID might currently not exist,
  /// or might exist with a different topic;
  /// see dartdoc of [ActionSheetMenuItemButton].
  final int someMessageIdInTopic;

  final bool _actionIsResolve;

  @override
  IconData get icon => _actionIsResolve ? ZulipIcons.check : ZulipIcons.check_remove;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return _actionIsResolve
      ? zulipLocalizations.actionSheetOptionResolveTopic
      : zulipLocalizations.actionSheetOptionUnresolveTopic;
  }

  @override void onPressed() async {
    final zulipLocalizations = ZulipLocalizations.of(pageContext);
    final store = PerAccountStoreWidget.of(pageContext);

    // We *could* check here if the topic has changed since the action sheet was
    // opened (see dartdoc of [ActionSheetMenuItemButton]) and abort if so.
    // We simplify by not doing so.
    // There's already an inherent race that that check wouldn't help with:
    // when you tap the button, an intervening topic change may already have
    // happened, just not reached us in an event yet.
    // Discussion, including about what web does:
    //   https://github.com/zulip/zulip-flutter/pull/1301#discussion_r1936181560

    try {
      await updateMessage(store.connection,
        messageId: someMessageIdInTopic,
        topic: _actionIsResolve ? topic.resolve() : topic.unresolve(),
        propagateMode: PropagateMode.changeAll,
        sendNotificationToOldThread: false,
        sendNotificationToNewThread: true,
      );
    } catch (e) {
      if (!pageContext.mounted) return;

      String? errorMessage;
      switch (e) {
        case ZulipApiException():
          errorMessage = e.message;
          // TODO(#741) specific messages for common errors, like network errors
          //   (support with reusable code)
        default:
      }

      final title = _actionIsResolve
        ? zulipLocalizations.errorResolveTopicFailedTitle
        : zulipLocalizations.errorUnresolveTopicFailedTitle;
      showErrorDialog(context: pageContext, title: title, message: errorMessage);
    }
  }
}

class MarkTopicAsReadButton extends ActionSheetMenuItemButton {
  const MarkTopicAsReadButton({
    super.key,
    required this.channelId,
    required this.topic,
    required super.pageContext,
  });

  final int channelId;
  final TopicName topic;

  @override IconData get icon => ZulipIcons.message_checked;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionMarkTopicAsRead;
  }

  @override void onPressed() async {
    await ZulipAction.markNarrowAsRead(pageContext, TopicNarrow(channelId, topic));
  }
}

class CopyTopicLinkButton extends ActionSheetMenuItemButton {
  const CopyTopicLinkButton({
    super.key,
    required this.narrow,
    required super.pageContext,
  });

  final TopicNarrow narrow;

  @override IconData get icon => ZulipIcons.link;

  @override
  String label(ZulipLocalizations localizations) {
    return localizations.actionSheetOptionCopyTopicLink;
  }

  @override void onPressed() async {
    final zulipLocalizations = ZulipLocalizations.of(pageContext);
    final store = PerAccountStoreWidget.of(pageContext);

    PlatformActions.copyWithPopup(context: pageContext,
      successContent: Text(zulipLocalizations.successTopicLinkCopied),
      data: ClipboardData(text: narrowLink(store, narrow).toString()));
  }
}

/// Show a sheet of actions you can take on a message in the message list.
///
/// Must have a [MessageListPage] ancestor.
void showMessageActionSheet({required BuildContext context, required Message message}) {
  final now = ZulipBinding.instance.utcNow();

  final pageContext = PageRoot.contextOf(context);
  final store = PerAccountStoreWidget.of(pageContext);

  final popularEmojiLoaded = store.popularEmojiCandidates().isNotEmpty;

  final reactions = message.reactions;
  final hasReactions = reactions != null && reactions.total > 0;

  final readReceiptsEnabled = store.realmEnableReadReceipts;

  // The UI that's conditioned on this won't live-update during this appearance
  // of the action sheet (we avoid calling composeBoxControllerOf in a build
  // method; see its doc).
  // So we rely on the fact that isComposeBoxOffered for any given message list
  // will be constant through the page's life.
  final messageListPage = MessageListPage.ancestorOf(pageContext);
  final isComposeBoxOffered = messageListPage.composeBoxState != null;

  final isMessageRead = message.flags.contains(MessageFlag.read);

  final isSenderMuted = store.isUserMuted(message.senderId);

  final buttonSections = [
    [
      if (popularEmojiLoaded)
        ReactionButtons(message: message, pageContext: pageContext),
      if (hasReactions)
        ViewReactionsButton(message: message, pageContext: pageContext),
      if (readReceiptsEnabled)
        ViewReadReceiptsButton(message: message, pageContext: pageContext),
      StarButton(message: message, pageContext: pageContext),
      if (isComposeBoxOffered)
        QuoteAndReplyButton(message: message, pageContext: pageContext),
      if (isMessageRead)
        MarkAsUnreadButton(message: message, pageContext: pageContext),
      if (isSenderMuted)
        // The message must have been revealed in order to open this action sheet.
        UnrevealMutedMessageButton(message: message, pageContext: pageContext),
      CopyMessageTextButton(message: message, pageContext: pageContext),
      CopyMessageLinkButton(message: message, pageContext: pageContext),
      ShareButton(message: message, pageContext: pageContext),
      if (_getShouldShowEditButton(pageContext, message))
        EditButton(message: message, pageContext: pageContext),
    ],
    if (store.selfCanDeleteMessage(message.id, atDate: now))
      [DeleteMessageButton(message: message, pageContext: pageContext)],
  ];

  _showActionSheet(pageContext,
    buttonSections: buttonSections,
    header: _MessageActionSheetHeader(message: message));
}

class _MessageActionSheetHeader extends StatelessWidget {
  const _MessageActionSheetHeader({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    // TODO this seems to lose the hero animation when opening an image;
    //   investigate.
    // TODO should we close the sheet before opening a narrow link?
    //   On popping the pushed narrow route, the sheet is still open.

    return Container(
      // TODO(#647) use different color for highlighted messages
      // TODO(#681) use different color for DM messages
      color: designVariables.bgMessageRegular,
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        spacing: 4,
        children: [
          SenderRow(message: message,
            timestampStyle: MessageTimestampStyle.full),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            // TODO(#10) offer text selection; the Figma asks for it here:
            //   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3483-30210&m=dev
            child: MessageContent(message: message, content: parseMessageContent(message))),
        ]));
  }
}

abstract class MessageActionSheetMenuItemButton extends ActionSheetMenuItemButton {
  MessageActionSheetMenuItemButton({
    super.key,
    required this.message,
    required super.pageContext,
  }) : assert(pageContext.findAncestorWidgetOfExactType<MessageListPage>() != null);

  final Message message;
}

bool _getShouldShowEditButton(BuildContext pageContext, Message message) {
  final store = PerAccountStoreWidget.of(pageContext);

  final messageListPage = MessageListPage.ancestorOf(pageContext);
  final composeBoxState = messageListPage.composeBoxState;
  final isComposeBoxOffered = composeBoxState != null;
  final composeBoxController = composeBoxState?.controller;

  final editMessageErrorStatus = store.getEditMessageErrorStatus(message.id);
  final editMessageInProgress =
    // The compose box is in edit-message mode, with Cancel/Save instead of Send.
    composeBoxController is EditMessageComposeBoxController
    // An edit request is in progress or the error state.
    || editMessageErrorStatus != null;

  final now = ZulipBinding.instance.utcNow().millisecondsSinceEpoch ~/ 1000;
  final editLimit = store.realmMessageContentEditLimitSeconds;
  final outsideEditLimit = editLimit != null && now - message.timestamp > editLimit;

  return message.senderId == store.selfUserId
    && isComposeBoxOffered
    && store.realmAllowMessageEditing
    && !outsideEditLimit
    && !editMessageInProgress
    && message.poll == null; // messages with polls cannot be edited
}

class ReactionButtons extends StatelessWidget {
  const ReactionButtons({
    super.key,
    required this.message,
    required this.pageContext,
  });

  final Message message;

  /// A context within the [MessageListPage] this action sheet was
  /// triggered from.
  final BuildContext pageContext;

  void _handleTapReaction({
    required EmojiCandidate emoji,
    required bool isSelfVoted,
  }) {
    // Dismiss the enclosing action sheet immediately,
    // for swift UI feedback that the user's selection was received.
    Navigator.pop(pageContext);

    final zulipLocalizations = ZulipLocalizations.of(pageContext);
    doAddOrRemoveReaction(
      context: pageContext,
      doRemoveReaction: isSelfVoted,
      messageId: message.id,
      emoji: emoji,
      errorDialogTitle: isSelfVoted
        ? zulipLocalizations.errorReactionRemovingFailedTitle
        : zulipLocalizations.errorReactionAddingFailedTitle);
  }

  void _handleTapMore() async {
    // TODO(design): have emoji picker slide in from right and push
    //   action sheet off to the left

    // Dismiss current action sheet before opening emoji picker sheet.
    Navigator.of(pageContext).pop();

    final emoji = await showEmojiPickerSheet(pageContext: pageContext);
    if (emoji == null || !pageContext.mounted) return;
    unawaited(doAddOrRemoveReaction(
      context: pageContext,
      doRemoveReaction: false,
      messageId: message.id,
      emoji: emoji,
      errorDialogTitle:
        ZulipLocalizations.of(pageContext).errorReactionAddingFailedTitle));
  }

  Widget _buildButton({
    required BuildContext context,
    required EmojiCandidate emoji,
    required bool isSelfVoted,
    required bool isFirst,
  }) {
    final designVariables = DesignVariables.of(context);
    return Flexible(child: InkWell(
      onTap: () => _handleTapReaction(emoji: emoji, isSelfVoted: isSelfVoted),
      splashFactory: NoSplash.splashFactory,
      borderRadius: isFirst
        ? const BorderRadius.only(topLeft: Radius.circular(7))
        : null,
      overlayColor: WidgetStateColor.resolveWith((states) =>
        states.any((e) => e == WidgetState.pressed)
          ? designVariables.contextMenuItemBg.withFadedAlpha(0.20)
          : Colors.transparent),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
        alignment: Alignment.center,
        color: isSelfVoted
          ? designVariables.contextMenuItemBg.withFadedAlpha(0.20)
          : null,
        child: UnicodeEmojiWidget(
          emojiDisplay: emoji.emojiDisplay as UnicodeEmojiDisplay,
          size: 24))));
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(pageContext);
    final popularEmojiCandidates = store.popularEmojiCandidates();
    assert(popularEmojiCandidates.every(
      (emoji) => emoji.emojiType == ReactionType.unicodeEmoji));
    // (if this is empty, the widget isn't built in the first place)
    assert(popularEmojiCandidates.isNotEmpty);
    // UI not designed to handle more than 6 popular emoji.
    // (We might have fewer if ServerEmojiData is lacking expected data,
    // but that looks fine in manual testing, even when there's just one.)
    assert(popularEmojiCandidates.length <= 6);

    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);

    bool hasSelfVote(EmojiCandidate emoji) {
      return message.reactions?.aggregated.any((reactionWithVotes) {
        return reactionWithVotes.reactionType == ReactionType.unicodeEmoji
          && reactionWithVotes.emojiCode == emoji.emojiCode
          && reactionWithVotes.userIds.contains(store.selfUserId);
      }) ?? false;
    }

    return Container(
      decoration: BoxDecoration(
        color: designVariables.contextMenuItemBg.withFadedAlpha(0.12)),
      child: Row(children: [
        Flexible(child: Row(spacing: 1, children: List.unmodifiable(
          popularEmojiCandidates.mapIndexed((index, emoji) =>
            _buildButton(
              context: context,
              emoji: emoji,
              isSelfVoted: hasSelfVote(emoji),
              isFirst: index == 0))))),
        InkWell(
          onTap: _handleTapMore,
          splashFactory: NoSplash.splashFactory,
          borderRadius: const BorderRadius.only(topRight: Radius.circular(7)),
          overlayColor: WidgetStateColor.resolveWith((states) =>
            states.any((e) => e == WidgetState.pressed)
              ? designVariables.contextMenuItemBg.withFadedAlpha(0.20)
              : Colors.transparent),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 4, 12),
            child: Row(children: [
              Text(zulipLocalizations.emojiReactionsMore,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: designVariables.contextMenuItemText,
                  fontSize: 14,
                ).merge(weightVariableTextStyle(context, wght: 600))),
              Icon(ZulipIcons.chevron_right,
                color: designVariables.contextMenuItemText,
                size: 24),
            ]),
          )),
      ]),
    );
  }
}

class ViewReactionsButton extends MessageActionSheetMenuItemButton {
  ViewReactionsButton({super.key, required super.message, required super.pageContext});

  @override IconData get icon => ZulipIcons.see_who_reacted;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionSeeWhoReacted;
  }

  @override void onPressed() {
    showViewReactionsSheet(pageContext, messageId: message.id);
  }
}

class ViewReadReceiptsButton extends MessageActionSheetMenuItemButton {
  ViewReadReceiptsButton({super.key, required super.message, required super.pageContext});

  @override IconData get icon => ZulipIcons.check_check;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionViewReadReceipts;
  }

  @override void onPressed() {
    showReadReceiptsSheet(pageContext, messageId: message.id);
  }
}

class StarButton extends MessageActionSheetMenuItemButton {
  StarButton({super.key, required super.message, required super.pageContext});

  @override IconData get icon => _isStarred ? ZulipIcons.star_filled : ZulipIcons.star;

  bool get _isStarred => message.flags.contains(MessageFlag.starred);

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return _isStarred
      ? zulipLocalizations.actionSheetOptionUnstarMessage
      : zulipLocalizations.actionSheetOptionStarMessage;
  }

  @override void onPressed() async {
    final zulipLocalizations = ZulipLocalizations.of(pageContext);
    final op = message.flags.contains(MessageFlag.starred)
      ? UpdateMessageFlagsOp.remove
      : UpdateMessageFlagsOp.add;

    try {
      final connection = PerAccountStoreWidget.of(pageContext).connection;
      await updateMessageFlags(connection, messages: [message.id],
        op: op, flag: MessageFlag.starred);
    } catch (e) {
      if (!pageContext.mounted) return;

      String? errorMessage;
      switch (e) {
        case ZulipApiException():
          errorMessage = e.message;
          // TODO specific messages for common errors, like network errors
          //   (support with reusable code)
        default:
      }

      showErrorDialog(context: pageContext,
        title: switch(op) {
          UpdateMessageFlagsOp.remove => zulipLocalizations.errorUnstarMessageFailedTitle,
          UpdateMessageFlagsOp.add    => zulipLocalizations.errorStarMessageFailedTitle,
        }, message: errorMessage);
    }
  }
}

class QuoteAndReplyButton extends MessageActionSheetMenuItemButton {
  QuoteAndReplyButton({super.key, required super.message, required super.pageContext});

  @override IconData get icon => ZulipIcons.format_quote;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionQuoteMessage;
  }

  @override void onPressed() async {
    final zulipLocalizations = ZulipLocalizations.of(pageContext);
    final message = this.message;

    var composeBoxController = findMessageListPage().composeBoxState?.controller;
    // The compose box doesn't null out its controller; it's either always null
    // (e.g. in Combined Feed) or always non-null; it can't have been nulled out
    // after the action sheet opened.
    composeBoxController!;
    if (
      composeBoxController is StreamComposeBoxController
      && composeBoxController.topic.isTopicVacuous
      && message is StreamMessage
    ) {
      composeBoxController.topic.setTopic(message.topic);
    }

    // This inserts a "[Quoting…]" placeholder into the content input,
    // giving the user a form of progress feedback.
    final tag = composeBoxController.content
      .registerQuoteAndReplyStart(
        zulipLocalizations,
        PerAccountStoreWidget.of(pageContext),
        message: message,
      );

    final rawContent = await ZulipAction.fetchRawContentWithFeedback(
      context: pageContext,
      messageId: message.id,
      errorDialogTitle: zulipLocalizations.errorQuotationFailed,
    );

    if (!pageContext.mounted) return;

    composeBoxController = findMessageListPage().composeBoxState?.controller;
    // The compose box doesn't null out its controller; it's either always null
    // (e.g. in Combined Feed) or always non-null; it can't have been nulled out
    // during the raw-content request.
    composeBoxController!.content
      .registerQuoteAndReplyEnd(PerAccountStoreWidget.of(pageContext), tag,
        message: message,
        rawContent: rawContent,
      );
    if (!composeBoxController.contentFocusNode.hasFocus) {
      composeBoxController.contentFocusNode.requestFocus();
    }
  }
}

class MarkAsUnreadButton extends MessageActionSheetMenuItemButton {
  MarkAsUnreadButton({super.key, required super.message, required super.pageContext});

  @override IconData get icon => Icons.mark_chat_unread_outlined;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionMarkAsUnread;
  }

  @override void onPressed() async {
    final messageListPage = findMessageListPage();
    unawaited(ZulipAction.markNarrowAsUnreadFromMessage(pageContext,
      message, messageListPage.narrow));
    // TODO should we alert the user about this change somehow? A snackbar?
    messageListPage.markReadOnScroll = false;
  }
}

class UnrevealMutedMessageButton extends MessageActionSheetMenuItemButton {
  UnrevealMutedMessageButton({
    super.key,
    required super.message,
    required super.pageContext,
  });

  @override
  IconData get icon => ZulipIcons.eye_off;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionHideMutedMessage;
  }

  @override
  void onPressed() {
    // The message should have been revealed in order to reach this action sheet.
    assert(MessageListPage.maybeRevealedMutedMessagesOf(pageContext)!
      .isMutedMessageRevealed(message.id));
    findMessageListPage().unrevealMutedMessage(message.id);
  }
}

class CopyMessageTextButton extends MessageActionSheetMenuItemButton {
  CopyMessageTextButton({super.key, required super.message, required super.pageContext});

  @override IconData get icon => ZulipIcons.copy;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionCopyMessageText;
  }

  @override void onPressed() async {
    // This action doesn't show request progress.
    // But hopefully it won't take long at all,
    // and [ZulipAction.fetchRawContentWithFeedback] has a TODO
    // for giving feedback if it does.

    final zulipLocalizations = ZulipLocalizations.of(pageContext);

    final rawContent = await ZulipAction.fetchRawContentWithFeedback(
      context: pageContext,
      messageId: message.id,
      errorDialogTitle: zulipLocalizations.errorCopyingFailed,
    );

    if (rawContent == null) return;

    if (!pageContext.mounted) return;

    PlatformActions.copyWithPopup(context: pageContext,
      successContent: Text(zulipLocalizations.successMessageTextCopied),
      data: ClipboardData(text: rawContent));
  }
}

class CopyMessageLinkButton extends MessageActionSheetMenuItemButton {
  CopyMessageLinkButton({super.key, required super.message, required super.pageContext});

  @override IconData get icon => ZulipIcons.link;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionCopyMessageLink;
  }

  @override void onPressed() {
    final zulipLocalizations = ZulipLocalizations.of(pageContext);

    final store = PerAccountStoreWidget.of(pageContext);
    final messageLink = narrowLink(
      store,
      SendableNarrow.ofMessage(message, selfUserId: store.selfUserId),
      nearMessageId: message.id,
    );

    PlatformActions.copyWithPopup(context: pageContext,
      successContent: Text(zulipLocalizations.successMessageLinkCopied),
      data: ClipboardData(text: messageLink.toString()));
  }
}

class ShareButton extends MessageActionSheetMenuItemButton {
  ShareButton({super.key, required super.message, required super.pageContext});

  @override
  IconData get icon => defaultTargetPlatform == TargetPlatform.iOS
    ? ZulipIcons.share_ios
    : ZulipIcons.share;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionShare;
  }

  @override void onPressed() async {
    // TODO(#591): Fix iOS bug where if the keyboard was open before the call
    //   to `showMessageActionSheet`, it reappears briefly between
    //   the `pop` of the action sheet and the appearance of the share sheet.
    //
    //   (Alternatively we could delay the [NavigatorState.pop] that
    //   dismisses the action sheet until after the sharing Future settles
    //   with [ShareResultStatus.success].  But on iOS one gets impatient with
    //   how slowly our action sheet dismisses in that case.)

    final zulipLocalizations = ZulipLocalizations.of(pageContext);

    final rawContent = await ZulipAction.fetchRawContentWithFeedback(
      context: pageContext,
      messageId: message.id,
      errorDialogTitle: zulipLocalizations.errorSharingFailed,
    );

    if (rawContent == null) return;

    if (!pageContext.mounted) return;

    // TODO: to support iPads, we're asked to give a
    //   `sharePositionOrigin` param, or risk crashing / hanging:
    //     https://pub.dev/packages/share_plus#ipad
    //   Perhaps a wart in the API; discussion:
    //     https://github.com/zulip/zulip-flutter/pull/12#discussion_r1130146231
    final result =
      await SharePlus.instance.share(ShareParams(text: rawContent));

    switch (result.status) {
      // The plugin isn't very helpful: "The status can not be determined".
      // Until we learn otherwise, assume something wrong happened.
      case ShareResultStatus.unavailable:
        if (!pageContext.mounted) return;
        showErrorDialog(context: pageContext,
          title: zulipLocalizations.errorSharingFailed);
      case ShareResultStatus.success:
      case ShareResultStatus.dismissed:
        // nothing to do
    }
  }
}

class EditButton extends MessageActionSheetMenuItemButton {
  EditButton({super.key, required super.message, required super.pageContext});

  @override
  IconData get icon => ZulipIcons.edit;

  @override
  String label(ZulipLocalizations zulipLocalizations) =>
    zulipLocalizations.actionSheetOptionEditMessage;

  @override void onPressed() async {
    final composeBoxState = findMessageListPage().composeBoxState;
    if (composeBoxState == null) {
      throw StateError('Compose box unexpectedly absent when edit-message button pressed');
    }
    composeBoxState.startEditInteraction(message.id);
  }
}

class DeleteMessageButton extends MessageActionSheetMenuItemButton {
  DeleteMessageButton({super.key, required super.message, required super.pageContext});

  @override
  IconData get icon => ZulipIcons.trash;

  @override
  bool get destructive => true;

  @override
  String label(ZulipLocalizations zulipLocalizations) =>
    zulipLocalizations.actionSheetOptionDeleteMessage;

  @override void onPressed() async {
    final zulipLocalizations = ZulipLocalizations.of(pageContext);

    final dialog = showSuggestedActionDialog(context: pageContext,
      title: zulipLocalizations.deleteMessageConfirmationDialogTitle,
      message: zulipLocalizations.deleteMessageConfirmationDialogMessage,
      destructiveActionButton: true,
      actionButtonText: zulipLocalizations.deleteMessageConfirmationDialogConfirmButton,
    );
    if (await dialog.result != true) return;
    if (!pageContext.mounted) return;

    final connection = PerAccountStoreWidget.of(pageContext).connection;
    try {
      await deleteMessage(connection, messageId: message.id);
    } catch (e) {
      if (!pageContext.mounted) return;

      String? errorMessage;
      switch (e) {
        case ZulipApiException():
          errorMessage = e.message;
          // TODO(#741) specific messages for common errors, like network errors
          //   (support with reusable code)
        default:
      }

      final title = ZulipLocalizations.of(pageContext).errorDeleteMessageFailedTitle;
      showErrorDialog(context: pageContext, title: title, message: errorMessage);
    }
  }
}
