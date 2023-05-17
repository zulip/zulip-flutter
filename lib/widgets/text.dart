import 'dart:io';
import 'dart:ui';
import 'package:flutter/widgets.dart';

/// A mergeable [TextStyle] with 'Source Code Pro' and platform-aware fallbacks.
///
/// Callers should also call [weightVariableTextStyle] and merge that in too,
/// because for this font, we use "variable font" assets with a "wght" axis.
///
/// Example:
///
/// ```dart
/// kMonospaceTextStyle
///   .merge(const TextStyle(color: Colors.red))
///   .merge(weightVariableTextStyle(context))
/// ```
final TextStyle kMonospaceTextStyle = TextStyle(
  fontFamily: 'Source Code Pro',

  // Oddly, iOS doesn't handle 'monospace':
  //   https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20monospace.20font.20fallback/near/1570622
  fontFamilyFallback: Platform.isIOS ? ['Menlo', 'Courier'] : ['monospace'],

  inherit: true,
);

/// A mergeable [TextStyle] to use when the preferred font has a "wght" axis.
///
/// Some variable fonts can be controlled on a "wght" axis.
/// Use this to set a value on that axis. It uses [TextStyle.fontVariations],
/// along with a [TextStyle.fontWeight] that approximates the given "wght"
/// for the sake of glyphs that need to be rendered by a fallback font
/// (which might not offer a "wght" axis).
///
/// Use this even to specify normal-weight text, by omitting `wght`; then,
/// [FontWeight.normal.value] will be used. No other layer applies a default,
/// so if you don't use this, you may e.g. get the font's lightest weight.
///
/// Pass [context] to respect a platform request to draw bold text for
/// accessibility (see [MediaQueryData.boldText]). This handles that request by
/// using [wghtIfPlatformRequestsBold] or if that's null, [FontWeight.bold.value].
///
/// Example:
///
/// ```dart
/// someTextStyle.merge(weightVariableTextStyle(context, wght: 250)
/// ```
///
/// See also [FontVariation] for more background on variable fonts.
// TODO(a11y) make `context` required when callers can adapt?
TextStyle weightVariableTextStyle(BuildContext? context, {
  double? wght,
  double? wghtIfPlatformRequestsBold,
}) {
  assert((wght != null) == (wghtIfPlatformRequestsBold != null));
  double value = wght ?? FontWeight.normal.value.toDouble();
  if (context != null && MediaQuery.of(context).boldText) {
    // The framework has a condition on [MediaQueryData.boldText]
    // in the [Text] widget, but that only affects `fontWeight`.
    // [Text] doesn't know where to land on the chosen font's "wght" axis if any,
    // and indeed it doesn't seem updated to be aware of variable fonts at all.
    value = wghtIfPlatformRequestsBold ?? FontWeight.bold.value.toDouble();
  }
  assert(value >= 1 && value <= 1000); // https://fonts.google.com/variablefonts#axis-definitions

  return TextStyle(
    fontVariations: [FontVariation('wght', value)],

    // This use of `fontWeight` shouldn't affect glyphs in the preferred,
    // "wght"-axis font. If it does, see for debugging:
    //   https://github.com/zulip/zulip-flutter/issues/65#issuecomment-1550666764
    fontWeight: clampVariableFontWeight(value),

    inherit: true);
}

/// Find the nearest [FontWeight] constant for a variable-font "wght"-axis value.
///
/// Use this for a reasonable [TextStyle.fontWeight] for glyphs that need to be
/// rendered by a fallback font that doesn't have a "wght" axis.
///
/// See also [FontVariation] for background on variable fonts.
FontWeight clampVariableFontWeight(double wght) {
  if (wght < 450) {
    if (wght < 250) {
      if (wght < 150)      return FontWeight.w100; // ignore_for_file: curly_braces_in_flow_control_structures
      else                 return FontWeight.w200;
    } else {
      if (wght < 350)      return FontWeight.w300;
      else                 return FontWeight.w400;
    }
  } else {
    if (wght < 650) {
      if (wght < 550)      return FontWeight.w500;
      else                 return FontWeight.w600;
    } else {
      if (wght < 750)      return FontWeight.w700;
      else if (wght < 850) return FontWeight.w800;
      else                 return FontWeight.w900;
    }
  }
}
