import 'package:flutter/material.dart';

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
      streamRecipientHeaderChevronRight:
          streamRecipientHeaderChevronRight ??
          this.streamRecipientHeaderChevronRight,
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
      dmRecipientHeaderBg: Color.lerp(
        dmRecipientHeaderBg,
        other.dmRecipientHeaderBg,
        t,
      )!,
      labelTime: Color.lerp(labelTime, other.labelTime, t)!,
      senderBotIcon: Color.lerp(senderBotIcon, other.senderBotIcon, t)!,
      streamRecipientHeaderChevronRight: Color.lerp(
        streamRecipientHeaderChevronRight,
        other.streamRecipientHeaderChevronRight,
        t,
      )!,
      unreadMarker: Color.lerp(unreadMarker, other.unreadMarker, t)!,
      unreadMarkerGap: Color.lerp(unreadMarkerGap, other.unreadMarkerGap, t)!,
    );
  }
}
