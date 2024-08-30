import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_color_models/flutter_color_models.dart';

import '../api/model/model.dart';
import 'color.dart';

/// A lazily-computed map from a channel's base color to a
/// corresponding [ChannelColorSwatch].
abstract class ChannelColorSwatches {
  /// The [ChannelColorSwatches] for the light theme.
  static final ChannelColorSwatches light = _ChannelColorSwatchesLight();

  /// The [ChannelColorSwatches] for the dark theme.
  static final ChannelColorSwatches dark = _ChannelColorSwatchesDark();

  final Map<int, ChannelColorSwatch> _cache = {};

  /// Gives the [ChannelColorSwatch] for a [subscription.color].
  ChannelColorSwatch forBaseColor(int base) =>
    _cache[base] ??= _computeForBaseColor(base);

  ChannelColorSwatch _computeForBaseColor(int base);

  /// Gives a [ChannelColorSwatches], lerped between [a] and [b] at [t].
  ///
  /// If [a] and [b] are [identical], returns [this].
  ///
  /// Else returns an instance whose [forBaseColor] will call
  /// [a.forBaseColor] and [b.forBaseColor]
  /// and return [ChannelColorSwatch.lerp]'s result on those.
  /// This computation is cached on the instance
  /// in order to save work building [t]'s animation frame when there are
  /// multiple UI elements using the same [subscription.color].
  static ChannelColorSwatches lerp(ChannelColorSwatches a, ChannelColorSwatches b, double t) {
    // This short-circuit helps when [a] and [b]
    // are both [ChannelColorSwatches.light]
    // or both [ChannelColorSwatches.dark].
    // Empirically, [lerp] is called even when the theme hasn't changed,
    // so this is an important optimization.
    if (identical(a, b)) return a;

    return _ChannelColorSwatchesLerped(a, b, t);
  }
}

class _ChannelColorSwatchesLight extends ChannelColorSwatches {
  _ChannelColorSwatchesLight();

  @override
  ChannelColorSwatch _computeForBaseColor(int base) => ChannelColorSwatch.light(base);
}

class _ChannelColorSwatchesDark extends ChannelColorSwatches {
  _ChannelColorSwatchesDark();

  @override
  ChannelColorSwatch _computeForBaseColor(int base) => ChannelColorSwatch.dark(base);
}

class _ChannelColorSwatchesLerped extends ChannelColorSwatches {
  _ChannelColorSwatchesLerped(this.a, this.b, this.t);

  final ChannelColorSwatches a;
  final ChannelColorSwatches b;
  final double t;

  @override
  ChannelColorSwatch _computeForBaseColor(int base) =>
    ChannelColorSwatch.lerp(a.forBaseColor(base), b.forBaseColor(base), t)!;
}


/// A [ColorSwatch] with colors related to a base channel color.
///
/// Use this in UI code for colors related to [Subscription.color],
/// such as the background of an unread count badge.
class ChannelColorSwatch extends ColorSwatch<ChannelColorVariant> {
  ChannelColorSwatch.light(int base) : this._(base, _computeLight(base));
  ChannelColorSwatch.dark(int base) : this._(base, _computeDark(base));

  const ChannelColorSwatch._(int base, this._swatch) : super(base, _swatch);

  final Map<ChannelColorVariant, Color> _swatch;

  /// The [Subscription.color] int that the swatch is based on.
  Color get base => this[ChannelColorVariant.base]!;

  Color get unreadCountBadgeBackground => this[ChannelColorVariant.unreadCountBadgeBackground]!;

  /// The channel icon on a plain-colored surface, such as white.
  ///
  /// For the icon on a [barBackground]-colored surface,
  /// use [iconOnBarBackground] instead.
  Color get iconOnPlainBackground => this[ChannelColorVariant.iconOnPlainBackground]!;

  /// The channel icon on a [barBackground]-colored surface.
  ///
  /// For the icon on a plain surface, use [iconOnPlainBackground] instead.
  /// This color is chosen to enhance contrast with [barBackground]:
  ///   <https://github.com/zulip/zulip/pull/27485>
  Color get iconOnBarBackground => this[ChannelColorVariant.iconOnBarBackground]!;

  /// The background color of a bar representing a channel, like a recipient bar.
  ///
  /// Use this in the message list, the "Inbox" view, and the "Channels" view.
  Color get barBackground => this[ChannelColorVariant.barBackground]!;

  static Map<ChannelColorVariant, Color> _computeLight(int base) {
    final baseAsColor = Color(base);

    final clamped20to75 = clampLchLightness(baseAsColor, 20, 75);
    final clamped20to75AsHsl = HSLColor.fromColor(clamped20to75);

    return {
      ChannelColorVariant.base: baseAsColor,

      // Follows `.unread-count` in Vlad's replit:
      //   <https://replit.com/@VladKorobov/zulip-sidebar#script.js>
      //   <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/design.3A.20.23F117.20.22Inbox.22.20screen/near/1624484>
      //
      // TODO fix bug where our results differ from the replit's (see unit tests)
      ChannelColorVariant.unreadCountBadgeBackground:
        clampLchLightness(baseAsColor, 30, 70)
          .withValues(alpha: 0.3),

      // Follows `.sidebar-row__icon` in Vlad's replit:
      //   <https://replit.com/@VladKorobov/zulip-sidebar#script.js>
      //
      // TODO fix bug where our results differ from the replit's (see unit tests)
      ChannelColorVariant.iconOnPlainBackground: clamped20to75,

      // Follows `.recepeient__icon` in Vlad's replit:
      //   <https://replit.com/@VladKorobov/zulip-topic-feed-colors#script.js>
      //   <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/design.3A.20.23F117.20.22Inbox.22.20screen/near/1624484>
      //
      // TODO fix bug where our results differ from the replit's (see unit tests)
      ChannelColorVariant.iconOnBarBackground:
        clamped20to75AsHsl
          .withLightness(clampDouble(clamped20to75AsHsl.lightness - 0.12, 0.0, 1.0))
          .toColor(),

      // Follows `.recepient` in Vlad's replit:
      //   <https://replit.com/@VladKorobov/zulip-topic-feed-colors#script.js>
      //
      // TODO I think [LabColor.interpolate] doesn't actually do LAB mixing;
      //   it just calls up to the superclass method [ColorModel.interpolate]:
      //     <https://pub.dev/documentation/flutter_color_models/latest/flutter_color_models/ColorModel/interpolate.html>
      //   which does ordinary RGB mixing. Investigate and send a PR?
      // TODO fix bug where our results differ from the replit's (see unit tests)
      ChannelColorVariant.barBackground:
        LabColor.fromColor(const Color(0xfff9f9f9))
          .interpolate(LabColor.fromColor(clamped20to75), 0.22)
          .toColor(),
    };
  }

  static Map<ChannelColorVariant, Color> _computeDark(int base) {
    final baseAsColor = Color(base);

    final clamped20to75 = clampLchLightness(baseAsColor, 20, 75);

    return {
      // See comments in [_computeLight] about what these computations are based
      // on, and how the resulting values are a little off sometimes. The
      // comments mostly apply here too.

      ChannelColorVariant.base: baseAsColor,
      ChannelColorVariant.unreadCountBadgeBackground:
        clampLchLightness(baseAsColor, 30, 70)
          .withValues(alpha: 0.3),
      ChannelColorVariant.iconOnPlainBackground: clamped20to75,

      // Follows the web app (as of zulip/zulip@db03369ac); see
      // get_stream_privacy_icon_color in web/src/stream_color.ts.
      //
      // `.recepeient__icon` in Vlad's replit gives something different so we
      // don't use that:
      //   <https://replit.com/@VladKorobov/zulip-topic-feed-colors#script.js>
      //   <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/design.3A.20.23F117.20.22Inbox.22.20screen/near/1624484>
      // But that's OK because Vlad said "I feel like current dark theme contrast
      // is fine", and when he said that, this had been the web app's icon color
      // for 6+ months (since zulip/zulip@023584e04):
      //   https://chat.zulip.org/#narrow/stream/101-design/topic/UI.20redesign.3A.20recipient.20bar.20colors/near/1675786
      //
      // TODO fix bug where our results are unexpected (see unit tests)
      ChannelColorVariant.iconOnBarBackground: clamped20to75,

      ChannelColorVariant.barBackground:
        LabColor.fromColor(const Color(0xff000000))
          .interpolate(LabColor.fromColor(clamped20to75), 0.38)
          .toColor(),
    };
  }

  /// Copied from [ColorSwatch.lerp].
  static ChannelColorSwatch? lerp(ChannelColorSwatch? a, ChannelColorSwatch? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    final Map<ChannelColorVariant, Color> swatch;
    if (b == null) {
      swatch = a!._swatch.map((key, color) => MapEntry(key, Color.lerp(color, null, t)!));
    } else {
      if (a == null) {
        swatch = b._swatch.map((key, color) => MapEntry(key, Color.lerp(null, color, t)!));
      } else {
        swatch = a._swatch.map((key, color) => MapEntry(key, Color.lerp(color, b[key], t)!));
      }
    }
    return ChannelColorSwatch._(Color.lerp(a, b, t)!.argbInt, swatch);
  }
}

@visibleForTesting
enum ChannelColorVariant {
  base,
  unreadCountBadgeBackground,
  iconOnPlainBackground,
  iconOnBarBackground,
  barBackground,
}
