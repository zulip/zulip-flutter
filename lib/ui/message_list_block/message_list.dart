// ПРОВЕЛ ДЕКОМПОЗИЦИЮ ВСЕГО ГОВНА!
// ТУТ ОСТАЛОСЬ ВСЕ ТО, ЧТО Я ПОКА НЕ ПОНЯЛ, КУДА ЗАСУНУТЬ

import 'package:flutter/material.dart' hide SearchBar;
import 'package:intl/intl.dart' hide TextDirection;

import '../../api/model/model.dart';
import '../../generated/l10n/zulip_localizations.dart';
import '../../model/message_list.dart';
import '../values/text.dart';
import '../values/theme.dart';

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

class RevealedMutedMessagesState extends ChangeNotifier {
  final Set<int> _revealedMessages = {};

  bool isMutedMessageRevealed(int messageId) =>
      _revealedMessages.contains(messageId);

  void add(int messageId) {
    _revealedMessages.add(messageId);
    notifyListeners();
  }

  void remove(int messageId) {
    _revealedMessages.remove(messageId);
    notifyListeners();
  }
}

class RevealedMutedMessagesProvider
    extends InheritedNotifier<RevealedMutedMessagesState> {
  const RevealedMutedMessagesProvider({
    super.key,
    required RevealedMutedMessagesState state,
    required super.child,
  }) : super(notifier: state);

  RevealedMutedMessagesState get state => notifier!;
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
const kFetchMessagesBufferPixels =
    (kMessageListFetchBatchSize / 2) * _kShortMessageHeight;

TextStyle recipientHeaderTextStyle(
  BuildContext context, {
  FontStyle? fontStyle,
}) {
  return TextStyle(
    color: DesignVariables.of(context).title,
    fontSize: 16,
    letterSpacing: proportionalLetterSpacing(context, 0.02, baseFontSize: 16),
    height: (18 / 16),
    fontStyle: fontStyle,
  ).merge(weightVariableTextStyle(context, wght: 600));
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
  full;

  static String _formatDateOnlyRelative(
    DateTime dateTime, {
    required DateTime now,
    required ZulipLocalizations zulipLocalizations,
  }) {
    assert(
      !dateTime.isUtc && !now.isUtc,
      '`dateTime` and `now` need to be in local time.',
    );

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return zulipLocalizations.today;
    }

    final yesterday = now
        .copyWith(
          hour: 12,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        )
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

  // Since https://github.com/flutter/flutter/commit/3ea161909,
  // DateFormat with 'j'-prefix pattern (used by locale default patterns below)
  // emits U+202F (NARROW NO-BREAK SPACE) character as a separator between time
  // and its period (AM/PM), instead of the space character.
  // So, do the same for other 12-hour formats here.
  static final _timeFormat12 = DateFormat('h:mm\u{202F}aa');
  static final _timeFormat24 = DateFormat('Hm');
  static final _timeFormatLocaleDefault = DateFormat('jm');
  static final _timeFormat12WithSeconds = DateFormat('h:mm:ss\u{202F}aa');
  static final _timeFormat24WithSeconds = DateFormat('Hms');
  static final _timeFormatLocaleDefaultWithSeconds = DateFormat('jms');

  static DateFormat _resolveTimeFormat(TwentyFourHourTimeMode mode) =>
      switch (mode) {
        TwentyFourHourTimeMode.twelveHour => _timeFormat12,
        TwentyFourHourTimeMode.twentyFourHour => _timeFormat24,
        TwentyFourHourTimeMode.localeDefault => _timeFormatLocaleDefault,
      };

  static DateFormat _resolveTimeFormatWithSeconds(
    TwentyFourHourTimeMode mode,
  ) => switch (mode) {
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
    final asDateTime = dateTimeFromTimestamp(messageTimestamp);

    switch (this) {
      case none:
        return null;
      case dateOnlyRelative:
        return _formatDateOnlyRelative(
          asDateTime,
          now: now,
          zulipLocalizations: zulipLocalizations,
        );
      case timeOnly:
        return _resolveTimeFormat(twentyFourHourTimeMode).format(asDateTime);
      case lightbox:
        return DateFormat.yMMMd()
            .addPattern(
              _resolveTimeFormatWithSeconds(twentyFourHourTimeMode).pattern,
            )
            .format(asDateTime);
      case full:
        return DateFormat.yMMMd()
            .addPattern(_resolveTimeFormat(twentyFourHourTimeMode).pattern)
            .format(asDateTime);
    }
  }
}
