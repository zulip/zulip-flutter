import 'dart:ui';

import 'package:flutter/material.dart';

import 'color.dart';
import 'text.dart';

/// A widget to display a given number of unreads in a conversation.
///
/// Implements the design for these in Figma:
///   <https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=341%3A12387&mode=dev>
class UnreadCountBadge extends StatelessWidget {
  const UnreadCountBadge({
    super.key,
    required this.count,
    required this.baseStreamColor,
    this.bold = false,
  });

  final int count;
  final bool bold;

  /// A base stream color, from a stream subscription in user data, or null.
  ///
  /// If not null, the background will be colored with an appropriate
  /// transformation of this.
  ///
  /// If null, the default neutral background will be used.
  final Color? baseStreamColor;

  @visibleForTesting
  Color getBackgroundColor() {
    if (baseStreamColor == null) {
      return const Color.fromRGBO(102, 102, 153, 0.15);
    }

    // Follows `.unread-count` in Vlad's replit:
    //   <https://replit.com/@VladKorobov/zulip-sidebar#script.js>
    //   <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/design.3A.20.23F117.20.22Inbox.22.20screen/near/1624484>
    //
    // TODO fix bug where our results differ from the replit's (see unit tests)
    // TODO profiling for expensive computation
    return clampLchLightness(baseStreamColor!, 30, 70).withOpacity(0.3);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: getBackgroundColor(),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 1),
        child: Text(
          style: const TextStyle(
            fontFamily: 'Source Sans 3',
            fontSize: 16,
            height: (18 / 16),
            fontFeatures: [FontFeature.enable('smcp')], // small caps
            color: Color(0xFF222222),
          ).merge(bold
            ? weightVariableTextStyle(context, wght: 600, wghtIfPlatformRequestsBold: 900)
            : weightVariableTextStyle(context)),
          count.toString())));
  }
}
