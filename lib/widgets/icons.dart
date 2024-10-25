
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

  /// The Zulip custom icon "arrow_right".
  static const IconData arrow_right = IconData(0xf102, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "at_sign".
  static const IconData at_sign = IconData(0xf103, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "bot".
  static const IconData bot = IconData(0xf104, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "chevron_right".
  static const IconData chevron_right = IconData(0xf105, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "clock".
  static const IconData clock = IconData(0xf106, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "copy".
  static const IconData copy = IconData(0xf107, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "format_quote".
  static const IconData format_quote = IconData(0xf108, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "globe".
  static const IconData globe = IconData(0xf109, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "group_dm".
  static const IconData group_dm = IconData(0xf10a, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "hash_sign".
  static const IconData hash_sign = IconData(0xf10b, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "language".
  static const IconData language = IconData(0xf10c, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "lock".
  static const IconData lock = IconData(0xf10d, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "mute".
  static const IconData mute = IconData(0xf10e, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "read_receipts".
  static const IconData read_receipts = IconData(0xf10f, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "share".
  static const IconData share = IconData(0xf110, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "share_ios".
  static const IconData share_ios = IconData(0xf111, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "smile".
  static const IconData smile = IconData(0xf112, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "star".
  static const IconData star = IconData(0xf113, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "star_filled".
  static const IconData star_filled = IconData(0xf114, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "topic".
  static const IconData topic = IconData(0xf115, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "unmute".
  static const IconData unmute = IconData(0xf116, fontFamily: "Zulip Icons");

  /// The Zulip custom icon "user".
  static const IconData user = IconData(0xf117, fontFamily: "Zulip Icons");

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
