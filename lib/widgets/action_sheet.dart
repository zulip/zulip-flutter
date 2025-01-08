import 'dart:async';

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
import '../model/emoji.dart';
import '../model/internal_link.dart';
import '../model/narrow.dart';
import 'actions.dart';
import 'clipboard.dart';
import 'color.dart';
import 'compose_box.dart';
import 'dialog.dart';
import 'emoji.dart';
import 'emoji_reaction.dart';
import 'icons.dart';
import 'inset_shadow.dart';
import 'message_list.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';

void _showActionSheet(
  BuildContext context, {
  required List<Widget> optionButtons,
}) {
  showModalBottomSheet<void>(
    context: context,
    // Clip.hardEdge looks bad; Clip.antiAliasWithSaveLayer looks pixel-perfect
    // on my iPhone 13 Pro but is marked as "much slower":
    //   https://api.flutter.dev/flutter/dart-ui/Clip.html
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (BuildContext _) {
      return SafeArea(
        minimum: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // TODO(#217): show message text
              Flexible(child: InsetShadowBox(
                top: 8, bottom: 8,
                color: DesignVariables.of(context).bgContextMenu,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Column(spacing: 1,
                      children: optionButtons))))),
              const ActionSheetCancelButton(),
            ])));
    });
}

abstract class ActionSheetMenuItemButton extends StatelessWidget {
  const ActionSheetMenuItemButton({super.key, required this.pageContext});

  IconData get icon;
  String label(ZulipLocalizations zulipLocalizations);

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
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    return MenuItemButton(
      trailingIcon: Icon(icon, color: designVariables.contextMenuItemText),
      style: MenuItemButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        foregroundColor: designVariables.contextMenuItemText,
        splashFactory: NoSplash.splashFactory,
      ).copyWith(backgroundColor: WidgetStateColor.resolveWith((states) =>
          designVariables.contextMenuItemBg.withFadedAlpha(
            states.contains(WidgetState.pressed) ? 0.20 : 0.12))),
      onPressed: () => _handlePressed(context),
      child: Text(label(zulipLocalizations),
        style: const TextStyle(fontSize: 20, height: 24 / 20)
          .merge(weightVariableTextStyle(context, wght: 600)),
      ));
  }
}

class ActionSheetCancelButton extends StatelessWidget {
  const ActionSheetCancelButton({super.key});

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
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
      child: Text(ZulipLocalizations.of(context).dialogCancel,
        style: const TextStyle(fontSize: 20, height: 24 / 20)
          .merge(weightVariableTextStyle(context, wght: 600))));
  }
}

/// Show a sheet of actions you can take on a topic.
void showTopicActionSheet(BuildContext context, {
  required int channelId,
  required TopicName topic,
}) {
  final store = PerAccountStoreWidget.of(context);
  final subscription = store.subscriptions[channelId];

  final optionButtons = <ActionSheetMenuItemButton>[];

  // TODO(server-7): simplify this condition away
  final supportsUnmutingTopics = store.connection.zulipFeatureLevel! >= 170;
  // TODO(server-8): simplify this condition away
  final supportsFollowingTopics = store.connection.zulipFeatureLevel! >= 219;

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
      pageContext: context);
  }));

  if (optionButtons.isEmpty) {
    // TODO(a11y): This case makes a no-op gesture handler; as a consequence,
    //   we're presenting some UI (to people who use screen-reader software) as
    //   though it offers a gesture interaction that it doesn't meaningfully
    //   offer, which is confusing. The solution here is probably to remove this
    //   is-empty case by having at least one button that's always present,
    //   such as "copy link to topic".
    return;
  }

  _showActionSheet(context, optionButtons: optionButtons);
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

/// Show a sheet of actions you can take on a message in the message list.
///
/// Must have a [MessageListPage] ancestor.
void showMessageActionSheet({required BuildContext context, required Message message}) {
  final store = PerAccountStoreWidget.of(context);

  // The UI that's conditioned on this won't live-update during this appearance
  // of the action sheet (we avoid calling composeBoxControllerOf in a build
  // method; see its doc).
  // So we rely on the fact that isComposeBoxOffered for any given message list
  // will be constant through the page's life.
  final messageListPage = MessageListPage.ancestorOf(context);
  final isComposeBoxOffered = messageListPage.composeBoxController != null;

  final isMessageRead = message.flags.contains(MessageFlag.read);
  final markAsUnreadSupported = store.connection.zulipFeatureLevel! >= 155; // TODO(server-6)
  final showMarkAsUnreadButton = markAsUnreadSupported && isMessageRead;

  final optionButtons = [
    ReactionButtons(message: message, pageContext: context),
    StarButton(message: message, pageContext: context),
    if (isComposeBoxOffered)
      QuoteAndReplyButton(message: message, pageContext: context),
    if (showMarkAsUnreadButton)
      MarkAsUnreadButton(message: message, pageContext: context),
    CopyMessageTextButton(message: message, pageContext: context),
    CopyMessageLinkButton(message: message, pageContext: context),
    ShareButton(message: message, pageContext: context),
  ];

  _showActionSheet(context, optionButtons: optionButtons);
}

abstract class MessageActionSheetMenuItemButton extends ActionSheetMenuItemButton {
  MessageActionSheetMenuItemButton({
    super.key,
    required this.message,
    required super.pageContext,
  }) : assert(pageContext.findAncestorWidgetOfExactType<MessageListPage>() != null);

  final Message message;
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

  void _handleTapMore() {
    // TODO(design): have emoji picker slide in from right and push
    //   action sheet off to the left

    // Dismiss current action sheet before opening emoji picker sheet.
    Navigator.of(pageContext).pop();

    showEmojiPickerSheet(pageContext: pageContext, message: message);
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
          notoColorEmojiTextSize: 20.1,
          size: 24))));
  }

  @override
  Widget build(BuildContext context) {
    assert(EmojiStore.popularEmojiCandidates.every(
      (emoji) => emoji.emojiType == ReactionType.unicodeEmoji));

    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(pageContext);
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
          EmojiStore.popularEmojiCandidates.mapIndexed((index, emoji) =>
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

/// Fetch and return the raw Markdown content for [messageId],
/// showing an error dialog on failure.
Future<String?> fetchRawContentWithFeedback({
  required BuildContext context,
  required int messageId,
  required String errorDialogTitle,
}) async {
    Message? fetchedMessage;
    String? errorMessage;
    // TODO, supported by reusable code:
    // - (?) Retry with backoff on plausibly transient errors.
    // - If request(s) take(s) a long time, show snackbar with cancel
    //   button, like "Still working on quote-and-reply…".
    //   On final failure or success, auto-dismiss the snackbar.
    final zulipLocalizations = ZulipLocalizations.of(context);
    try {
      fetchedMessage = await getMessageCompat(PerAccountStoreWidget.of(context).connection,
        messageId: messageId,
        applyMarkdown: false,
      );
      if (fetchedMessage == null) {
        errorMessage = zulipLocalizations.errorMessageDoesNotSeemToExist;
      }
    } catch (e) {
      switch (e) {
        case ZulipApiException():
          errorMessage = e.message;
        // TODO specific messages for common errors, like network errors
        //   (support with reusable code)
        default:
          errorMessage = zulipLocalizations.errorCouldNotFetchMessageSource;
      }
    }

    if (!context.mounted) return null;

    if (fetchedMessage == null) {
      assert(errorMessage != null);
      // TODO(?) give no feedback on error conditions we expect to
      //   flag centrally in event polling, like invalid auth,
      //   user/realm deactivated. (Support with reusable code.)
      showErrorDialog(context: context,
        title: errorDialogTitle, message: errorMessage);
    }

    return fetchedMessage?.content;
}

class QuoteAndReplyButton extends MessageActionSheetMenuItemButton {
  QuoteAndReplyButton({super.key, required super.message, required super.pageContext});

  @override IconData get icon => ZulipIcons.format_quote;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionQuoteAndReply;
  }

  @override void onPressed() async {
    final zulipLocalizations = ZulipLocalizations.of(pageContext);
    final message = this.message;

    var composeBoxController = findMessageListPage().composeBoxController;
    // The compose box doesn't null out its controller; it's either always null
    // (e.g. in Combined Feed) or always non-null; it can't have been nulled out
    // after the action sheet opened.
    composeBoxController!;
    if (
      composeBoxController is StreamComposeBoxController
      && composeBoxController.topic.textNormalized == kNoTopicTopic
      && message is StreamMessage
    ) {
      composeBoxController.topic.setTopic(message.topic);
    }

    // This inserts a "[Quoting…]" placeholder into the content input,
    // giving the user a form of progress feedback.
    final tag = composeBoxController.content
      .registerQuoteAndReplyStart(PerAccountStoreWidget.of(pageContext),
        message: message,
      );

    final rawContent = await fetchRawContentWithFeedback(
      context: pageContext,
      messageId: message.id,
      errorDialogTitle: zulipLocalizations.errorQuotationFailed,
    );

    if (!pageContext.mounted) return;

    composeBoxController = findMessageListPage().composeBoxController;
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
    final narrow = findMessageListPage().narrow;
    unawaited(markNarrowAsUnreadFromMessage(pageContext, message, narrow));
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
    // But hopefully it won't take long at all; and
    // fetchRawContentWithFeedback has a TODO for giving feedback if it does.

    final zulipLocalizations = ZulipLocalizations.of(pageContext);

    final rawContent = await fetchRawContentWithFeedback(
      context: pageContext,
      messageId: message.id,
      errorDialogTitle: zulipLocalizations.errorCopyingFailed,
    );

    if (rawContent == null) return;

    if (!pageContext.mounted) return;

    copyWithPopup(context: pageContext,
      successContent: Text(zulipLocalizations.successMessageTextCopied),
      data: ClipboardData(text: rawContent));
  }
}

class CopyMessageLinkButton extends MessageActionSheetMenuItemButton {
  CopyMessageLinkButton({super.key, required super.message, required super.pageContext});

  @override IconData get icon => Icons.link;

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

    copyWithPopup(context: pageContext,
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

    final rawContent = await fetchRawContentWithFeedback(
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
    final result = await Share.share(rawContent);

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
