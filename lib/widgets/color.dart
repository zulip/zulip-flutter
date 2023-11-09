import 'dart:ui';

import 'package:flutter_color_models/flutter_color_models.dart';

// This function promises to deal with "LCH" lightness, not "LAB" lightness,
// but it's not yet true. We haven't found a Dart libary that can work with LCH:
//   <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/design.3A.20.23F117.20.22Inbox.22.20screen/near/1677537>
// We use LAB because some quick reading suggests that the "L" axis
// is the same in both representations:
//   <https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/lch>
//
// TODO try LCH; see linked discussion
Color clampLchLightness(Color color, num lowerLimit, num upperLimit) {
  final asLab = LabColor.fromColor(color);
  return asLab
    .copyWith(lightness: asLab.lightness.clamp(lowerLimit, upperLimit))
    .toColor();
}
