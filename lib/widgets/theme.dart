import 'package:flutter/material.dart';

import 'content.dart';
import 'text.dart';

ThemeData zulipThemeData(BuildContext context) {
  return ThemeData(
    typography: zulipTypography(context),
    extensions: [ContentTheme(context)],
    appBarTheme: AppBarTheme(
      // Set these two fields to prevent a color change in [AppBar]s when
      // there is something scrolled under it. If an app bar hasn't been
      // given a backgroundColor directly or by theme, it uses
      // ColorScheme.surfaceContainer for the scrolled-under state and
      // ColorScheme.surface otherwise, and those are different colors.
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0xfff5f5f5), // `bg-top-bar` in Figma

      actionsIconTheme: const IconThemeData(
        color: Color(0xff666699), // `icon` in Figma
      ),

      titleTextStyle: TextStyle(
        inherit: false,
        color: const Color(0xff1a1a1a), // `title` in Figma
        fontSize: 20,
        letterSpacing: 0.0,
        height: (30 / 20),
        textBaseline: localizedTextBaseline(context),
        leadingDistribution: TextLeadingDistribution.even,
        decoration: TextDecoration.none,
        fontFamily: kDefaultFontFamily,
        fontFamilyFallback: defaultFontFamilyFallback,
      )
        .merge(weightVariableTextStyle(context, wght: 600)),
      titleSpacing: 4,

      shape: const Border(bottom: BorderSide(
        color: Color(0x33000000), // `border-bar` in Figma
        strokeAlign: BorderSide.strokeAlignInside, // (default restated for explicitness)
      )),
    ),
    // This applies Material 3's color system to produce a palette of
    // appropriately matching and contrasting colors for use in a UI.
    // The Zulip brand color is a starting point, but doesn't end up as
    // one that's directly used.  (After all, we didn't design it for that
    // purpose; we designed a logo.)  See docs:
    //   https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html
    // Or try this tool to see the whole palette:
    //   https://m3.material.io/theme-builder#/custom
    colorScheme: ColorScheme.fromSeed(
      seedColor: kZulipBrandColor,
    ),
    scaffoldBackgroundColor: const Color(0xfff0f0f0), // `bg-main` in Figma
    tooltipTheme: const TooltipThemeData(preferBelow: false),
  );
}

/// The Zulip "brand color", a purplish blue.
///
/// This is chosen as the sRGB midpoint of the Zulip logo's gradient.
// As computed by Anders: https://github.com/zulip/zulip-mobile/pull/4467
const kZulipBrandColor = Color.fromRGBO(0x64, 0x92, 0xfe, 1);
