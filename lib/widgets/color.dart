import 'dart:ui';

import 'package:flutter_color_models/flutter_color_models.dart' as flutter_color_models;

// This function promises to deal with "LCH" lightness, not "LAB" lightness,
// but it's not yet true. We haven't found a Dart libary that can work with LCH:
//   <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/design.3A.20.23F117.20.22Inbox.22.20screen/near/1677537>
// We use LAB because some quick reading suggests that the "L" axis
// is the same in both representations:
//   <https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/lch>
//
// TODO try LCH; see linked discussion
Color clampLchLightness(Color color, num lowerLimit, num upperLimit) {
  final asLab = flutter_color_models.LabColor.fromColor(color);
  return asLab
    .copyWith(lightness: asLab.lightness.clamp(lowerLimit, upperLimit))
    .toColor();
}

extension ColorExtension on Color {
  /// A 32 bit integer representing this sRGB color.
  ///
  /// If [colorSpace] is not [ColorSpace.sRGB], do not use this.
  ///
  /// The bits are assigned as follows:
  ///
  /// * Bits 24-31 are the alpha value.
  /// * Bits 16-23 are the red value.
  /// * Bits 8-15 are the green value.
  /// * Bits 0-7 are the blue value.
  ///
  /// This is the same form that [Color.new] takes.
  int get argbInt {
    assert(colorSpace == ColorSpace.sRGB);

    return ((a * 255.0).round() & 0xff) << 24 |
           ((r * 255.0).round() & 0xff) << 16 |
           ((g * 255.0).round() & 0xff) << 8 |
           ((b * 255.0).round() & 0xff) << 0;
  }

  /// Makes a copy of this color with [a] multiplied by `factor`.
  ///
  /// `factor` must be between 0 and 1, inclusive.
  ///
  /// To fade a color variable from [DesignVariables], [ContentTheme], etc.,
  /// use this instead of calling [withValues] with `factor` passed as `alpha`,
  /// which simply replaces the color's [a] instead of multiplying by it.
  /// Using [withValues] gives the same result for an opaque color,
  /// but a wrong result for a semi-transparent color,
  /// and we want our color variables to be free to change
  /// without breaking things.
  Color withFadedAlpha(double factor) {
    assert(factor >= 0);
    assert(factor <= 1);
    return withValues(alpha: a * factor);
  }
}
