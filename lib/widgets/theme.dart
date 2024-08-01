import 'package:flutter/material.dart';

import '../api/model/model.dart';
import 'content.dart';
import 'emoji_reaction.dart';
import 'message_list.dart';
import 'channel_colors.dart';
import 'text.dart';

/// In debug mode, controls whether the UI responds to
/// [MediaQueryData.platformBrightness].
///
/// Outside of debug mode, this is always false and the setter has no effect.
// TODO(#95) when dark theme is fully implemented, simplify away;
//   the UI should always respond.
bool get debugFollowPlatformBrightness {
  bool result = false;
  assert(() {
    result = _debugFollowPlatformBrightness;
    return true;
  }());
  return result;
}
bool _debugFollowPlatformBrightness = false;
set debugFollowPlatformBrightness(bool value) {
  assert(() {
    _debugFollowPlatformBrightness = value;
    return true;
  }());
}


ThemeData zulipThemeData(BuildContext context) {
  final DesignVariables designVariables;
  final List<ThemeExtension> themeExtensions;
  Brightness brightness = debugFollowPlatformBrightness
    ? MediaQuery.of(context).platformBrightness
    : Brightness.light;
  switch (brightness) {
    case Brightness.light: {
      designVariables = DesignVariables.light();
      themeExtensions = [
        ContentTheme.light(context),
        designVariables,
        EmojiReactionTheme.light(),
        MessageListTheme.light(),
      ];
    }
    case Brightness.dark: {
      designVariables = DesignVariables.dark();
      themeExtensions = [
        ContentTheme.dark(context),
        designVariables,
        EmojiReactionTheme.dark(),
        MessageListTheme.dark(),
      ];
    }
  }

  return ThemeData(
    brightness: brightness,
    typography: zulipTypography(context),
    extensions: themeExtensions,
    appBarTheme: AppBarTheme(
      // Set these two fields to prevent a color change in [AppBar]s when
      // there is something scrolled under it. If an app bar hasn't been
      // given a backgroundColor directly or by theme, it uses
      // ColorScheme.surfaceContainer for the scrolled-under state and
      // ColorScheme.surface otherwise, and those are different colors.
      scrolledUnderElevation: 0,
      backgroundColor: designVariables.bgTopBar,

      // TODO match layout to Figma
      actionsIconTheme: IconThemeData(
        color: designVariables.icon,
      ),

      titleTextStyle: TextStyle(
        inherit: false,
        color: designVariables.title,
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

      // TODO Figma has height 42; we should try `toolbarHeight: 42` and test
      //   that it looks reasonable with different system text-size settings.
      //   Also the back button will look too big and need adjusting.

      shape: Border(bottom: BorderSide(
        color: designVariables.borderBar,
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
      brightness: brightness,
      seedColor: kZulipBrandColor,
    ),
    scaffoldBackgroundColor: designVariables.mainBackground,
    tooltipTheme: const TooltipThemeData(preferBelow: false),
  );
}

/// The Zulip "brand color", a purplish blue.
///
/// This is chosen as the sRGB midpoint of the Zulip logo's gradient.
// As computed by Anders: https://github.com/zulip/zulip-mobile/pull/4467
const kZulipBrandColor = Color.fromRGBO(0x64, 0x92, 0xfe, 1);

/// Variables from the Figma design.
///
/// For how to export these from the Figma, see:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=2945-49492&t=MEb4vtp7S26nntxm-0
class DesignVariables extends ThemeExtension<DesignVariables> {
  DesignVariables.light() :
    this._(
      bgTopBar: const Color(0xfff5f5f5),
      borderBar: const Color(0x33000000),
      icon: const Color(0xff666699),
      mainBackground: const Color(0xfff0f0f0),
      title: const Color(0xff1a1a1a),
      channelColorSwatches: ChannelColorSwatches.light,
      loginOrDivider: const Color(0xffdedede),
      loginOrDividerText: const Color(0xff575757),
      star: const HSLColor.fromAHSL(0.5, 47, 1, 0.41).toColor(),
    );

  DesignVariables.dark() :
    this._(
      bgTopBar: const Color(0xff242424),
      borderBar: Colors.black.withOpacity(0.41),
      icon: const Color(0xff7070c2),
      mainBackground: const Color(0xff1d1d1d),
      title: const Color(0xffffffff),
      channelColorSwatches: ChannelColorSwatches.dark,
      loginOrDivider: const Color(0xff424242),
      loginOrDividerText: const Color(0xffa8a8a8),
      // TODO(#95) unchanged in dark theme?
      star: const HSLColor.fromAHSL(0.5, 47, 1, 0.41).toColor(),
    );

  DesignVariables._({
    required this.bgTopBar,
    required this.borderBar,
    required this.icon,
    required this.mainBackground,
    required this.title,
    required this.channelColorSwatches,
    required this.loginOrDivider,
    required this.loginOrDividerText,
    required this.star,
  });

  /// The [DesignVariables] from the context's active theme.
  ///
  /// The [ThemeData] must include [DesignVariables] in [ThemeData.extensions].
  static DesignVariables of(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<DesignVariables>();
    assert(extension != null);
    return extension!;
  }

  final Color bgTopBar;
  final Color borderBar;
  final Color icon;
  final Color mainBackground;
  final Color title;

  // Not exactly from the Figma design, but from Vlad anyway.
  final ChannelColorSwatches channelColorSwatches;

  // Not named variables in Figma; taken from older Figma drafts, or elsewhere.
  final Color loginOrDivider; // TODO(#95) need proper dark-theme color (this is ad hoc)
  final Color loginOrDividerText; // TODO(#95) need proper dark-theme color (this is ad hoc)
  final Color star;

  @override
  DesignVariables copyWith({
    Color? bgTopBar,
    Color? borderBar,
    Color? icon,
    Color? mainBackground,
    Color? title,
    ChannelColorSwatches? channelColorSwatches,
    Color? loginOrDivider,
    Color? loginOrDividerText,
    Color? star,
  }) {
    return DesignVariables._(
      bgTopBar: bgTopBar ?? this.bgTopBar,
      borderBar: borderBar ?? this.borderBar,
      icon: icon ?? this.icon,
      mainBackground: mainBackground ?? this.mainBackground,
      title: title ?? this.title,
      channelColorSwatches: channelColorSwatches ?? this.channelColorSwatches,
      loginOrDivider: loginOrDivider ?? this.loginOrDivider,
      loginOrDividerText: loginOrDividerText ?? this.loginOrDividerText,
      star: star ?? this.star,
    );
  }

  @override
  DesignVariables lerp(DesignVariables other, double t) {
    if (identical(this, other)) {
      return this;
    }
    return DesignVariables._(
      bgTopBar: Color.lerp(bgTopBar, other.bgTopBar, t)!,
      borderBar: Color.lerp(borderBar, other.borderBar, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      mainBackground: Color.lerp(mainBackground, other.mainBackground, t)!,
      title: Color.lerp(title, other.title, t)!,
      channelColorSwatches: ChannelColorSwatches.lerp(channelColorSwatches, other.channelColorSwatches, t),
      loginOrDivider: Color.lerp(loginOrDivider, other.loginOrDivider, t)!,
      loginOrDividerText: Color.lerp(loginOrDividerText, other.loginOrDividerText, t)!,
      star: Color.lerp(star, other.star, t)!,
    );
  }
}

/// The theme-appropriate [ChannelColorSwatch] based on [subscription.color].
///
/// For how this value is cached, see [ChannelColorSwatches.forBaseColor].
ChannelColorSwatch colorSwatchFor(BuildContext context, Subscription subscription) {
  return DesignVariables.of(context)
    .channelColorSwatches.forBaseColor(subscription.color);
}
