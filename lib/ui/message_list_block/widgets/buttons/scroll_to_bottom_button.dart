import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../model/message_list.dart';
import '../../../scrolling.dart';

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
        onPressed: _scrollToBottom,
      ),
    );
  }
}
