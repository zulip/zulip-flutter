
import 'package:flutter/widgets.dart';

import '../api/model/model.dart';

// ignore_for_file: constant_identifier_names

/// Identifiers for Zulip's custom icons.
///
/// Use these with the [Icon] widget, in the same way as one uses
/// the members of the [Icons] class from Flutter's Material library.
abstract final class ZulipIcons {
  // Generated code; do not edit.
  //
  // To add a new icon, or otherwise edit the set of icons:
  //
  //  * Add an SVG file in `assets/icons/`,
  //    or otherwise edit the SVG files there.
  //    The files' names (before ".svg") should be valid Dart identifiers.
  //
  //  * Then run the command `tools/icons/build-icon-font`.
  //    That will update this file and the generated icon font,
  //    `assets/icons/ZulipIcons.ttf`.
  //
  // BEGIN GENERATED ICON DATA

  /// The Zulip custom icon "arrow_down".
  static const IconData arrow_down = IconData(0xf101, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "arrow_left_right".
  static const IconData arrow_left_right = IconData(0xf102, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "arrow_right".
  static const IconData arrow_right = IconData(0xf103, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "at_sign".
  static const IconData at_sign = IconData(0xf104, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "attach_file".
  static const IconData attach_file = IconData(0xf105, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "bot".
  static const IconData bot = IconData(0xf106, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "camera".
  static const IconData camera = IconData(0xf107, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "check".
  static const IconData check = IconData(0xf108, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "check_circle_checked".
  static const IconData check_circle_checked = IconData(0xf109, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "check_circle_unchecked".
  static const IconData check_circle_unchecked = IconData(0xf10a, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "check_remove".
  static const IconData check_remove = IconData(0xf10b, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "chevron_down".
  static const IconData chevron_down = IconData(0xf10c, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "chevron_right".
  static const IconData chevron_right = IconData(0xf10d, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "clock".
  static const IconData clock = IconData(0xf10e, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "contacts".
  static const IconData contacts = IconData(0xf10f, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "copy".
  static const IconData copy = IconData(0xf110, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "edit".
  static const IconData edit = IconData(0xf111, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "eye".
  static const IconData eye = IconData(0xf112, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "eye_off".
  static const IconData eye_off = IconData(0xf113, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "follow".
  static const IconData follow = IconData(0xf114, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "format_quote".
  static const IconData format_quote = IconData(0xf115, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "globe".
  static const IconData globe = IconData(0xf116, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "group_dm".
  static const IconData group_dm = IconData(0xf117, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "hash_italic".
  static const IconData hash_italic = IconData(0xf118, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "hash_sign".
  static const IconData hash_sign = IconData(0xf119, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "image".
  static const IconData image = IconData(0xf11a, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "inbox".
  static const IconData inbox = IconData(0xf11b, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "info".
  static const IconData info = IconData(0xf11c, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "inherit".
  static const IconData inherit = IconData(0xf11d, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "language".
  static const IconData language = IconData(0xf11e, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "lock".
  static const IconData lock = IconData(0xf11f, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "menu".
  static const IconData menu = IconData(0xf120, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "message_checked".
  static const IconData message_checked = IconData(0xf121, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "message_feed".
  static const IconData message_feed = IconData(0xf122, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "mute".
  static const IconData mute = IconData(0xf123, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "person".
  static const IconData person = IconData(0xf124, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "plus".
  static const IconData plus = IconData(0xf125, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "read_receipts".
  static const IconData read_receipts = IconData(0xf126, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "remove".
  static const IconData remove = IconData(0xf127, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "search".
  static const IconData search = IconData(0xf128, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "see_who_reacted".
  static const IconData see_who_reacted = IconData(0xf129, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "send".
  static const IconData send = IconData(0xf12a, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "settings".
  static const IconData settings = IconData(0xf12b, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "share".
  static const IconData share = IconData(0xf12c, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "share_ios".
  static const IconData share_ios = IconData(0xf12d, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "smile".
  static const IconData smile = IconData(0xf12e, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "star".
  static const IconData star = IconData(0xf12f, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "star_filled".
  static const IconData star_filled = IconData(0xf130, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "three_person".
  static const IconData three_person = IconData(0xf131, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "topic".
  static const IconData topic = IconData(0xf132, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "topics".
  static const IconData topics = IconData(0xf133, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "two_person".
  static const IconData two_person = IconData(0xf134, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "unmute".
  static const IconData unmute = IconData(0xf135, fontFamily: "Zulip Icons");

  // END GENERATED ICON DATA
}

IconData iconDataForStream(ZulipStream stream) {
  // TODO: these icons aren't quite right yet;
  //   see this message and the one after it:
  //   https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/design.3A.20.23F117.20.22Inbox.22.20screen/near/1680637
  return switch(stream) {
    ZulipStream(isWebPublic: true) => ZulipIcons.globe,
    ZulipStream(inviteOnly: true) => ZulipIcons.lock,
    ZulipStream() => ZulipIcons.hash_sign,
  };
}

IconData? iconDataForTopicVisibilityPolicy(UserTopicVisibilityPolicy policy) {
  switch (policy) {
    case UserTopicVisibilityPolicy.muted:
      return ZulipIcons.mute;
    case UserTopicVisibilityPolicy.unmuted:
      return ZulipIcons.unmute;
    case UserTopicVisibilityPolicy.followed:
      return ZulipIcons.follow;
    case UserTopicVisibilityPolicy.none:
      return null;
    case UserTopicVisibilityPolicy.unknown:
      // This case is unreachable (or should be) because we keep `unknown` out
      // of our data structures. We plan to remove the `unknown` case in #1074.
      assert(false);
      return null;
  }
}
