import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_color_models/flutter_color_models.dart';

import '../api/model/model.dart';
import 'color.dart';

/// A lazily-computed map from a stream's base color to a
/// corresponding [StreamColorSwatch].
abstract class StreamColorSwatches {
  /// The [StreamColorSwatches] for the light theme.
  static final StreamColorSwatches light = _StreamColorSwatchesLight();

  /// The [StreamColorSwatches] for the dark theme.
  static final StreamColorSwatches dark = _StreamColorSwatchesDark();

  final Map<int, StreamColorSwatch> _cache = {};

  /// Gives the [StreamColorSwatch] for a [subscription.color].
  StreamColorSwatch forBaseColor(int base) =>
    _cache[base] ??= _computeForBaseColor(base);

  StreamColorSwatch _computeForBaseColor(int base);

  /// Gives a [StreamColorSwatches], lerped between [a] and [b] at [t].
  ///
  /// If [a] and [b] are [identical], returns [this].
  ///
  /// Else returns an instance whose [forBaseColor] will call
  /// [a.forBaseColor] and [b.forBaseColor]
  /// and return [StreamColorSwatch.lerp]'s result on those.
  /// This computation is cached on the instance
  /// in order to save work building [t]'s animation frame when there are
  /// multiple UI elements using the same [subscription.color].
  static StreamColorSwatches lerp(StreamColorSwatches a, StreamColorSwatches b, double t) {
    // This short-circuit helps when [a] and [b]
    // are both [StreamColorSwatches.light]
    // or both [StreamColorSwatches.dark].
    // Empirically, [lerp] is called even when the theme hasn't changed,
    // so this is an important optimization.
    if (identical(a, b)) return a;

    return _StreamColorSwatchesLerped(a, b, t);
  }
}

class _StreamColorSwatchesLight extends StreamColorSwatches {
  _StreamColorSwatchesLight();

  @override
  StreamColorSwatch _computeForBaseColor(int base) => StreamColorSwatch.light(base);
}

class _StreamColorSwatchesDark extends StreamColorSwatches {
  _StreamColorSwatchesDark();

  @override
  StreamColorSwatch _computeForBaseColor(int base) => StreamColorSwatch.dark(base);
}

class _StreamColorSwatchesLerped extends StreamColorSwatches {
  _StreamColorSwatchesLerped(this.a, this.b, this.t);

  final StreamColorSwatches a;
  final StreamColorSwatches b;
  final double t;

  @override
  StreamColorSwatch _computeForBaseColor(int base) =>
    StreamColorSwatch.lerp(a.forBaseColor(base), b.forBaseColor(base), t)!;
}


/// A [ColorSwatch] with colors related to a base stream color.
///
/// Use this in UI code for colors related to [Subscription.color],
/// such as the background of an unread count badge.
class StreamColorSwatch extends ColorSwatch<StreamColorVariant> {
  StreamColorSwatch.light(int base) : this._(base, _computeLight(base));
  StreamColorSwatch.dark(int base) : this._(base, _computeDark(base));

  const StreamColorSwatch._(int base, this._swatch) : super(base, _swatch);

  final Map<StreamColorVariant, Color> _swatch;

  /// The [Subscription.color] int that the swatch is based on.
  Color get base => this[StreamColorVariant.base]!;

  Color get unreadCountBadgeBackground => this[StreamColorVariant.unreadCountBadgeBackground]!;

  /// The stream icon on a plain-colored surface, such as white.
  ///
  /// For the icon on a [barBackground]-colored surface,
  /// use [iconOnBarBackground] instead.
  Color get iconOnPlainBackground => this[StreamColorVariant.iconOnPlainBackground]!;

  /// The stream icon on a [barBackground]-colored surface.
  ///
  /// For the icon on a plain surface, use [iconOnPlainBackground] instead.
  /// This color is chosen to enhance contrast with [barBackground]:
  ///   <https://github.com/zulip/zulip/pull/27485>
  Color get iconOnBarBackground => this[StreamColorVariant.iconOnBarBackground]!;

  /// The background color of a bar representing a stream, like a recipient bar.
  ///
  /// Use this in the message list, the "Inbox" view, and the "Streams" view.
  Color get barBackground => this[StreamColorVariant.barBackground]!;

  static Map<StreamColorVariant, Color> _computeLight(int base) {
    final baseAsColor = Color(base);

    final clamped20to75 = clampLchLightness(baseAsColor, 20, 75);
    final clamped20to75AsHsl = HSLColor.fromColor(clamped20to75);

    return {
      StreamColorVariant.base: baseAsColor,

      // Follows `.unread-count` in Vlad's replit:
      //   <https://replit.com/@VladKorobov/zulip-sidebar#script.js>
      //   <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/design.3A.20.23F117.20.22Inbox.22.20screen/near/1624484>
      //
      // TODO fix bug where our results differ from the replit's (see unit tests)
      StreamColorVariant.unreadCountBadgeBackground:
        clampLchLightness(baseAsColor, 30, 70)
          .withOpacity(0.3),

      // Follows `.sidebar-row__icon` in Vlad's replit:
      //   <https://replit.com/@VladKorobov/zulip-sidebar#script.js>
      //
      // TODO fix bug where our results differ from the replit's (see unit tests)
      StreamColorVariant.iconOnPlainBackground: clamped20to75,

      // Follows `.recepeient__icon` in Vlad's replit:
      //   <https://replit.com/@VladKorobov/zulip-topic-feed-colors#script.js>
      //   <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/design.3A.20.23F117.20.22Inbox.22.20screen/near/1624484>
      //
      // TODO fix bug where our results differ from the replit's (see unit tests)
      StreamColorVariant.iconOnBarBackground:
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
      StreamColorVariant.barBackground:
        LabColor.fromColor(const Color(0xfff9f9f9))
          .interpolate(LabColor.fromColor(clamped20to75), 0.22)
          .toColor(),
    };
  }

  static Map<StreamColorVariant, Color> _computeDark(int base) {
    final baseAsColor = Color(base);

    final clamped20to75 = clampLchLightness(baseAsColor, 20, 75);

    return {
      // See comments in [_computeLight] about what these computations are based
      // on, and how the resulting values are a little off sometimes. The
      // comments mostly apply here too.

      StreamColorVariant.base: baseAsColor,
      StreamColorVariant.unreadCountBadgeBackground:
        clampLchLightness(baseAsColor, 30, 70)
          .withOpacity(0.3),
      StreamColorVariant.iconOnPlainBackground: clamped20to75,

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
      StreamColorVariant.iconOnBarBackground: clamped20to75,

      StreamColorVariant.barBackground:
        LabColor.fromColor(const Color(0xff000000))
          .interpolate(LabColor.fromColor(clamped20to75), 0.38)
          .toColor(),
    };
  }

  /// Copied from [ColorSwatch.lerp].
  static StreamColorSwatch? lerp(StreamColorSwatch? a, StreamColorSwatch? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    final Map<StreamColorVariant, Color> swatch;
    if (b == null) {
      swatch = a!._swatch.map((key, color) => MapEntry(key, Color.lerp(color, null, t)!));
    } else {
      if (a == null) {
        swatch = b._swatch.map((key, color) => MapEntry(key, Color.lerp(null, color, t)!));
      } else {
        swatch = a._swatch.map((key, color) => MapEntry(key, Color.lerp(color, b[key], t)!));
      }
    }
    return StreamColorSwatch._(Color.lerp(a, b, t)!.value, swatch);
  }
}

@visibleForTesting
enum StreamColorVariant {
  base,
  unreadCountBadgeBackground,
  iconOnPlainBackground,
  iconOnBarBackground,
  barBackground,
}
