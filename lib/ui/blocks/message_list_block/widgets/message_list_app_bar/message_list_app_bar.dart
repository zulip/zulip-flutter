import 'package:flutter/material.dart';

import '../../../../../generated/l10n/zulip_localizations.dart';
import '../../../../../model/narrow.dart';
import '../../../../themes/message_list_theme.dart';
import '../../../../widgets/app_bar.dart';
import '../../../../values/icons.dart';
import '../../../../utils/store.dart';
import '../../../../values/theme.dart';
import '../../message_list_block.dart';
import 'message_list_app_bar_title.dart';
import '../buttons/topic_list_button.dart';

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
abstract class MessageListAppBar {
  static AppBar build(BuildContext context, {required Narrow narrow}) {
    final store = PerAccountStoreWidget.of(context);
    final messageListTheme = MessageListTheme.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final Color? appBarBackgroundColor;
    bool removeAppBarBottomBorder = false;
    switch (narrow) {
      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
      case KeywordSearchNarrow():
        appBarBackgroundColor = null; // i.e., inherit

      case ChannelNarrow(:final streamId):
      case TopicNarrow(:final streamId):
        final subscription = store.subscriptions[streamId];
        appBarBackgroundColor = colorSwatchFor(
          context,
          subscription,
        ).barBackground;
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
        actions.add(
          IconButton(
            icon: const Icon(ZulipIcons.search),
            tooltip: zulipLocalizations.searchMessagesPageTitle,
            onPressed: () => Navigator.push(
              context,
              MessageListBlockPage.buildRoute(
                context: context,
                narrow: KeywordSearchNarrow(''),
              ),
            ),
          ),
        );
      case MentionsNarrow():
      case StarredMessagesNarrow():
      case KeywordSearchNarrow():
      case DmNarrow():
        break;
      case ChannelNarrow(:final streamId):
        actions.add(TopicListButton(streamId: streamId));
      case TopicNarrow(:final streamId):
        actions.add(
          IconButton(
            icon: const Icon(ZulipIcons.message_feed),
            tooltip: zulipLocalizations.channelFeedButtonTooltip,
            onPressed: () => Navigator.push(
              context,
              MessageListBlockPage.buildRoute(
                context: context,
                narrow: ChannelNarrow(streamId),
              ),
            ),
          ),
        );
        actions.add(TopicListButton(streamId: streamId));
    }

    return ZulipAppBar(
      centerTitle: switch (narrow) {
        CombinedFeedNarrow() ||
        ChannelNarrow() ||
        TopicNarrow() ||
        DmNarrow() ||
        MentionsNarrow() ||
        StarredMessagesNarrow() => null,
        KeywordSearchNarrow() => false,
      },
      buildTitle: (willCenterTitle) => MessageListAppBarTitle(
        narrow: narrow,
        willCenterTitle: willCenterTitle,
      ),
      actions: actions,
      backgroundColor: appBarBackgroundColor,
      shape: removeAppBarBottomBorder ? const Border() : null, // i.e., inherit
    );
  }
}
