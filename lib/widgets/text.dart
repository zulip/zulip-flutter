import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// An app-wide [Typography] for Zulip, customized from the Material default.
///
/// Include this in the app-wide [MaterialApp.theme].
///
/// We expect these text styles to be the basis of all the styles chosen by the
/// Material library's widgets, such as the default styling of
/// an [AppBar]'s title, of an [ElevatedButton]'s label, and so on.
///
/// As of writing, it turns out that these styles also flow naturally into
/// many of our own widgets' text styles.
/// We often see this in the child of a [Material], for example,
/// since by default [Material] applies an [AnimatedDefaultTextStyle]
/// with the [TextTheme.bodyMedium] that gets its value from here.
/// There are exceptions, having `inherit: false`, that are self-contained
/// and not meant to inherit from this.
/// For example, the base style for message content;
/// see [ContentTheme.textStylePlainParagraph].
///
/// Applies [kDefaultFontFamily] and [kDefaultFontFamilyFallback],
/// being faithful to the Material-default font weights
/// by running them through [weightVariableTextStyle].
/// (That is needed because [kDefaultFontFamily] is a variable-weight font).
///
/// When building on top of these [TextStyles], callers that wish to specify
/// a different font weight are still responsible for reprocessing the style
/// with [weightVariableTextStyle] before passing it to a [Text].
/// (Widgets in the Material library won't do this; they aren't yet equipped
/// to set font weights on variable-weight fonts. If this causes visible bugs,
/// we should investigate and fix, but such bugs should become less likely as
/// we transition from Material's widgets to our own bespoke ones.)
// TODO decide if we like this data flow for our own widgets' text styles.
//   Does our design fit well with the fields of a [TextTheme]?
//   (That's [TextTheme.titleLarge], [TextTheme.bodyMedium], etc.)
Typography zulipTypography(BuildContext context) {
  final typography = Theme.of(context).typography;

  convertGeometry(TextTheme inputTextTheme) {
    TextTheme result = _weightVariableTextTheme(context, inputTextTheme);

    result = _convertTextTheme(result, (maybeInputStyle, _) =>
      maybeInputStyle?.merge(const TextStyle(letterSpacing: 0)));

    result = result.copyWith(
      labelLarge: result.labelLarge!.copyWith(
        fontSize: 14.0, // (should be unchanged; restated here for explicitness)
        letterSpacing: proportionalLetterSpacing(context,
          kButtonTextLetterSpacingProportion, baseFontSize: 14.0),
      ),
    );

    return result;
  }

  Typography result = typography.copyWith(
    black: typography.black.apply(
      fontFamily: kDefaultFontFamily,
      fontFamilyFallback: defaultFontFamilyFallback),
    white: typography.white.apply(
      fontFamily: kDefaultFontFamily,
      fontFamilyFallback: defaultFontFamilyFallback),

    dense:       convertGeometry(typography.dense),
    englishLike: convertGeometry(typography.englishLike),
    tall:        convertGeometry(typography.tall),
  );

  assert(() {
    // Set [TextStyle.debugLabel] for all styles, like:
    //   "zulipTypography black titleMedium"

    mkAddLabel(String debugTextThemeLabel)
      => (TextStyle? maybeInputStyle, String debugStyleLabel)
      => maybeInputStyle?.copyWith(debugLabel: '$debugTextThemeLabel $debugStyleLabel');

    result = result.copyWith(
      black:       _convertTextTheme(result.black,       mkAddLabel('zulipTypography black')),
      white:       _convertTextTheme(result.white,       mkAddLabel('zulipTypography white')),
      englishLike: _convertTextTheme(result.englishLike, mkAddLabel('zulipTypography englishLike')),
      dense:       _convertTextTheme(result.dense,       mkAddLabel('zulipTypography dense')),
      tall:        _convertTextTheme(result.tall,        mkAddLabel('zulipTypography tall')),
    );
    return true;
  }());

  return result;
}

/// Convert a geometry [TextTheme] to one that works with "wght"-variable fonts.
///
/// A "geometry [TextTheme]" is a [TextTheme] that's meant to specify
/// font weight and other parameters about shape, size, distance, etc.
/// See [Typography].
///
/// This looks at each of the [TextStyle]s found on the input [TextTheme]
/// (such as [TextTheme.bodyMedium]),
/// and uses [weightVariableTextStyle] to adjust the [TextStyle].
/// Fields that are null in the input [TextTheme] remain null in the output.
///
/// For each input [TextStyle], the `wght` value passed
/// to [weightVariableTextStyle] is based on the input's [TextStyle.fontWeight].
/// A null [TextStyle.fontWeight] is interpreted as the normal font weight.
TextTheme _weightVariableTextTheme(BuildContext context, TextTheme input) {
  TextStyle? convert(TextStyle? maybeInputStyle, _) {
    if (maybeInputStyle == null) {
      return null;
    }
    final inputFontWeight = maybeInputStyle.fontWeight;
    return maybeInputStyle.merge(weightVariableTextStyle(context,
      wght: inputFontWeight != null
        ? wghtFromFontWeight(inputFontWeight)
        : null));
  }

  return _convertTextTheme(input, convert);
}

TextTheme _convertTextTheme(
  TextTheme input,
  TextStyle? Function(TextStyle?, String debugStyleLabel) converter,
) => TextTheme(
  displayLarge:   converter(input.displayLarge,   'displayLarge'),
  displayMedium:  converter(input.displayMedium,  'displayMedium'),
  displaySmall:   converter(input.displaySmall,   'displaySmall'),
  headlineLarge:  converter(input.headlineLarge,  'headlineLarge'),
  headlineMedium: converter(input.headlineMedium, 'headlineMedium'),
  headlineSmall:  converter(input.headlineSmall,  'headlineSmall'),
  titleLarge:     converter(input.titleLarge,     'titleLarge'),
  titleMedium:    converter(input.titleMedium,    'titleMedium'),
  titleSmall:     converter(input.titleSmall,     'titleSmall'),
  bodyLarge:      converter(input.bodyLarge,      'bodyLarge'),
  bodyMedium:     converter(input.bodyMedium,     'bodyMedium'),
  bodySmall:      converter(input.bodySmall,      'bodySmall'),
  labelLarge:     converter(input.labelLarge,     'labelLarge'),
  labelMedium:    converter(input.labelMedium,    'labelMedium'),
  labelSmall:     converter(input.labelSmall,     'labelSmall'),
);

/// The [TextStyle.fontFamily] to use in most of the app.
///
/// The same [TextStyle] should also specify [defaultFontFamilyFallback]
/// for [TextStyle.fontFamilyFallback].
///
/// This is a variable-weight font, so any [TextStyle] that uses this should be
/// merged with the result of calling [weightVariableTextStyle].
const kDefaultFontFamily = 'Source Sans 3';

/// The [TextStyle.fontFamilyFallback] for use with [kDefaultFontFamily].
List<String> get defaultFontFamilyFallback => [
  // iOS doesn't support any of the formats this font is available in.
  // If we use it on iOS, we'll get blank spaces where we could have had Apple-
  // style emojis.
  if (defaultTargetPlatform == TargetPlatform.android) 'Noto Color Emoji',
];

/// A mergeable [TextStyle] with 'Source Code Pro' and platform-aware fallbacks.
///
/// Callers should also call [weightVariableTextStyle] and merge that in too,
/// because for this font, we use "variable font" assets with a "wght" axis.
/// That is, unless we've already applied [weightVariableTextStyle]
/// for a different variable-weight font that we're overriding with this one.
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
  // TODO use Theme.of, not Platform, so that this is testable (needs a BuildContext)
  fontFamilyFallback: Platform.isIOS ? ['Menlo', 'Courier'] : ['monospace'],

  inherit: true,
);

const kButtonTextLetterSpacingProportion = 0.01;

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
TextStyle weightVariableTextStyle(BuildContext context, {
  double? wght,
  double? wghtIfPlatformRequestsBold,
}) {
  double value = wght ?? wghtFromFontWeight(FontWeight.normal);
  if (MediaQuery.boldTextOf(context)) {
    // The framework has a condition on [MediaQueryData.boldText]
    // in the [Text] widget, but that only affects `fontWeight`.
    // [Text] doesn't know where to land on the chosen font's "wght" axis if any,
    // and indeed it doesn't seem updated to be aware of variable fonts at all.
    value = wghtIfPlatformRequestsBold ?? bolderWght(value);
  }
  assert(value >= kWghtMin && value <= kWghtMax);

  TextStyle result = TextStyle(
    fontVariations: [FontVariation('wght', value)],

    // This use of `fontWeight` shouldn't affect glyphs in the preferred,
    // "wght"-axis font. But it can; see upstream bug:
    //   https://github.com/flutter/flutter/issues/136779
    // TODO(#500) await/send upstream bugfix?
    fontWeight: clampVariableFontWeight(value),

    inherit: true);

  assert(() {
    final attributes = [
      if (wght != null) 'wght: $wght',
      if (wghtIfPlatformRequestsBold != null) 'wghtIfPlatformRequestsBold: $wghtIfPlatformRequestsBold',
    ];
    result = result.copyWith(
      debugLabel: 'weightVariableTextStyle(${attributes.join(', ')})');
    return true;
  }());

  return result;
}

/// The minimum that a [FontVariation] "wght" value can be.
///
/// See <https://fonts.google.com/variablefonts#axis-definitions>.
const kWghtMin = 1.0;

/// The maximum that a [FontVariation] "wght" value can be.
///
/// See <https://fonts.google.com/variablefonts#axis-definitions>.
const kWghtMax = 1000.0;

/// A [FontVariation] "wght" value that's 300 above a given, clamped to [kWghtMax].
///
/// The input value must be between [kWghtMin] and [kWghtMax].
///
/// Pass [by] to use a value other than 300.
double bolderWght(double baseWght, {double by = 300}) {
  assert(kWghtMin <= baseWght && baseWght <= kWghtMax);
  return clampDouble(baseWght + by, kWghtMin, kWghtMax);
}

/// A [TextStyle] whose [FontVariation] "wght" and [TextStyle.fontWeight]
/// have been raised using [bolderWght].
///
/// [style] must have already been processed with [weightVariableTextStyle],
/// and [by] must be positive.
///
/// The increase done here will commute with any increase that was done by
/// [weightVariableTextStyle] to respond to the device bold-text setting,
/// because both adjustments are done with [bolderWght] with positive `by`.
///
/// [by] defaults to 300.
TextStyle bolderWghtTextStyle(TextStyle style, {double by = 300}) {
  assert(
    style.debugLabel!.contains('weightVariableTextStyle')
    // ([ContentTheme.textStylePlainParagraph] applies [weightVariableTextStyle])
    || style.debugLabel!.contains('ContentTheme.textStylePlainParagraph')
    || style.debugLabel!.contains('bolderWghtTextStyle')
  );
  assert(by > 0);
  assert(style.fontVariations!.where((v) => v.axis == 'wght').length == 1);

  final newWght = bolderWght(wghtFromTextStyle(style)!, by: by);

  TextStyle result = style.copyWith(
    fontVariations: style.fontVariations!.map((v) => v.axis == 'wght'
      ? FontVariation('wght', newWght)
      : v).toList(),
    fontWeight: clampVariableFontWeight(newWght),
  );

  assert(() {
    result = result.copyWith(debugLabel: 'bolderWghtTextStyle(by: $by)');
    return true;
  }());

  return result;
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

/// A "wght" value extracted from a [TextStyle].
///
/// Returns the value in [TextStyle.fontVariations] if present.
/// If that's absent but a [TextStyle.fontWeight] is present,
/// returns [wghtFromFontWeight] for that value.
///
/// The returned value already reflects any response to the system bold-text
/// setting, so if the [TextStyle] was built using [weightVariableTextStyle],
/// this value might be larger than the `wght` that was passed to that function.
double? wghtFromTextStyle(TextStyle style) {
  double? result = style.fontVariations?.firstWhereOrNull((v) => v.axis == 'wght')?.value;
  if (result == null && style.fontWeight != null) {
    result = wghtFromFontWeight(style.fontWeight!);
  }
  return result;
}

/// A good guess at a font's "wght" value to match a given [FontWeight].
///
/// Returns [FontWeight.value] as a double.
///
/// This might not be exactly where the font designer would land on their
/// font's own custom-defined "wght" axis. But it's a great guess,
/// at least without knowledge of the particular font.
double wghtFromFontWeight(FontWeight fontWeight) => fontWeight.value.toDouble();

/// A [TextStyle.letterSpacing] value from a given proportion of the font size.
///
/// Returns [baseFontSize] scaled by the ambient [MediaQueryData.textScaler],
/// multiplied by [proportion] (e.g., 0.01).
///
/// Using [MediaQueryData.textScaler] ensures that [proportion] is still
/// respected when the device font size setting is adjusted.
/// To opt out of this behavior, pass [TextScaler.noScaling] or some other value
/// for [textScaler].
double proportionalLetterSpacing(
  BuildContext context,
  double proportion, {
  required double baseFontSize,
  TextScaler? textScaler,
}) {
  final effectiveTextScaler = textScaler ?? MediaQuery.textScalerOf(context);
  return effectiveTextScaler.scale(baseFontSize) * proportion;
}

/// The most suitable [TextBaseline] for the current language.
///
/// The result is chosen based on information from [MaterialLocalizations]
/// about the language's script.
/// If [MaterialLocalizations] doesn't have that information,
/// gives [TextBaseline.alphabetic].
// Adapted from [Theme.of], which localizes text styles according to the
// locale's [ScriptCategory]. With M3 defaults, this just means varying
// [TextStyle.textBaseline] the way we do here.
TextBaseline localizedTextBaseline(BuildContext context) {
  final materialLocalizations =
    Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
  final scriptCategory = materialLocalizations?.scriptCategory
    ?? ScriptCategory.englishLike;
  return switch (scriptCategory) {
    ScriptCategory.dense => TextBaseline.ideographic,
    ScriptCategory.englishLike => TextBaseline.alphabetic,
    ScriptCategory.tall => TextBaseline.alphabetic,
  };
}
