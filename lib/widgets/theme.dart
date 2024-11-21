import 'package:flutter/material.dart';

import '../api/model/model.dart';
import 'content.dart';
import 'emoji_reaction.dart';
import 'message_list.dart';
import 'channel_colors.dart';
import 'text.dart';

ThemeData zulipThemeData(BuildContext context) {
  final DesignVariables designVariables;
  final List<ThemeExtension> themeExtensions;
  Brightness brightness = MediaQuery.platformBrightnessOf(context);
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
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(
      foregroundColor: designVariables.icon,
    )),
    appBarTheme: AppBarTheme(
      // Set these two fields to prevent a color change in [AppBar]s when
      // there is something scrolled under it. If an app bar hasn't been
      // given a backgroundColor directly or by theme, it uses
      // ColorScheme.surfaceContainer for the scrolled-under state and
      // ColorScheme.surface otherwise, and those are different colors.
      scrolledUnderElevation: 0,
      backgroundColor: designVariables.bgTopBar,

      // TODO match actions layout to Figma

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
    bottomSheetTheme: BottomSheetThemeData(
      clipBehavior: Clip.antiAlias,
      backgroundColor: designVariables.bgContextMenu,
      modalBarrierColor: designVariables.modalBarrierColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
    ),
  );
}

/// The Zulip "brand color", a purplish blue.
///
/// This is chosen as the sRGB midpoint of the Zulip logo's gradient.
// As computed by Anders: https://github.com/zulip/zulip-mobile/pull/4467
const kZulipBrandColor = Color.fromRGBO(0x64, 0x92, 0xfe, 1);

/// Design variables, mainly from the Figma design.
///
/// For how to export these from the Figma, see:
///   https://github.com/zulip/zulip-flutter/pull/762#discussion_r1664748114
/// or
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=2945-49492&t=MEb4vtp7S26nntxm-0
class DesignVariables extends ThemeExtension<DesignVariables> {
  DesignVariables.light() :
    this._(
      background: const Color(0xffffffff),
      bgContextMenu: const Color(0xfff2f2f2),
      bgCounterUnread: const Color(0xff666699).withValues(alpha: 0.15),
      bgTopBar: const Color(0xfff5f5f5),
      borderBar: Colors.black.withValues(alpha: 0.2),
      composeBoxBg: const Color(0xffffffff),
      contextMenuCancelText: const Color(0xff222222),
      contextMenuItemBg: const Color(0xff6159e1),
      contextMenuItemText: const Color(0xff381da7),
      editorButtonPressedBg: Colors.black.withValues(alpha: 0.06),
      foreground: const Color(0xff000000),
      icon: const Color(0xff6159e1),
      labelCounterUnread: const Color(0xff222222),
      labelEdited: const HSLColor.fromAHSL(0.35, 0, 0, 0).toColor(),
      labelMenuButton: const Color(0xff222222),
      mainBackground: const Color(0xfff0f0f0),
      textInput: const Color(0xff000000),
      title: const Color(0xff1a1a1a),
      channelColorSwatches: ChannelColorSwatches.light,
      atMentionMarker: const HSLColor.fromAHSL(0.5, 0, 0, 0.2).toColor(),
      contextMenuCancelBg: const Color(0xff797986),
      dmHeaderBg: const HSLColor.fromAHSL(1, 46, 0.35, 0.93).toColor(),
      errorBannerBackground: const HSLColor.fromAHSL(1, 4, 0.33, 0.90).toColor(),
      errorBannerBorder: const HSLColor.fromAHSL(0.4, 3, 0.57, 0.33).toColor(),
      errorBannerLabel: const HSLColor.fromAHSL(1, 4, 0.58, 0.33).toColor(),
      groupDmConversationIcon: Colors.black.withValues(alpha: 0.5),
      groupDmConversationIconBg: const Color(0x33808080),
      loginOrDivider: const Color(0xffdedede),
      loginOrDividerText: const Color(0xff575757),
      modalBarrierColor: const Color(0xff000000).withValues(alpha: 0.3),
      mutedUnreadBadge: const HSLColor.fromAHSL(0.5, 0, 0, 0.8).toColor(),
      sectionCollapseIcon: const Color(0x7f1e2e48),
      star: const HSLColor.fromAHSL(0.5, 47, 1, 0.41).toColor(),
      subscriptionListHeaderLine: const HSLColor.fromAHSL(0.2, 240, 0.1, 0.5).toColor(),
      subscriptionListHeaderText: const HSLColor.fromAHSL(1.0, 240, 0.1, 0.5).toColor(),
      unreadCountBadgeTextForChannel: Colors.black.withValues(alpha: 0.9),
    );

  DesignVariables.dark() :
    this._(
      background: const Color(0xff000000),
      bgContextMenu: const Color(0xff262626),
      bgCounterUnread: const Color(0xff666699).withValues(alpha: 0.37),
      bgTopBar: const Color(0xff242424),
      borderBar: Colors.black.withValues(alpha: 0.5),
      composeBoxBg: const Color(0xff0f0f0f),
      contextMenuCancelText: const Color(0xffffffff).withValues(alpha: 0.75),
      contextMenuItemBg: const Color(0xff7977fe),
      contextMenuItemText: const Color(0xff9398fd),
      editorButtonPressedBg: Colors.white.withValues(alpha: 0.06),
      foreground: const Color(0xffffffff),
      icon: const Color(0xff7977fe),
      labelCounterUnread: const Color(0xffffffff).withValues(alpha: 0.7),
      labelEdited: const HSLColor.fromAHSL(0.35, 0, 0, 1).toColor(),
      labelMenuButton: const Color(0xffffffff).withValues(alpha: 0.85),
      mainBackground: const Color(0xff1d1d1d),
      textInput: const Color(0xffffffff).withValues(alpha: 0.9),
      title: const Color(0xffffffff),
      channelColorSwatches: ChannelColorSwatches.dark,
      contextMenuCancelBg: const Color(0xff797986), // the same as the light mode in Figma
      // TODO(design-dark) need proper dark-theme color (this is ad hoc)
      atMentionMarker: const HSLColor.fromAHSL(0.4, 0, 0, 1).toColor(),
      dmHeaderBg: const HSLColor.fromAHSL(1, 46, 0.15, 0.2).toColor(),
      errorBannerBackground: const HSLColor.fromAHSL(1, 0, 0.61, 0.19).toColor(),
      errorBannerBorder: const HSLColor.fromAHSL(0.4, 3, 0.73, 0.74).toColor(),
      errorBannerLabel: const HSLColor.fromAHSL(1, 2, 0.73, 0.80).toColor(),
      // TODO(design-dark) need proper dark-theme color (this is ad hoc)
      groupDmConversationIcon: Colors.white.withValues(alpha: 0.5),
      // TODO(design-dark) need proper dark-theme color (this is ad hoc)
      groupDmConversationIconBg: const Color(0x33cccccc),
      loginOrDivider: const Color(0xff424242),
      loginOrDividerText: const Color(0xffa8a8a8),
      modalBarrierColor: const Color(0xff000000).withValues(alpha: 0.5),
      // TODO(design-dark) need proper dark-theme color (this is ad hoc)
      mutedUnreadBadge: const HSLColor.fromAHSL(0.5, 0, 0, 0.6).toColor(),
      // TODO(design-dark) need proper dark-theme color (this is ad hoc)
      sectionCollapseIcon: const Color(0x7fb6c8e2),
      // TODO(design-dark) unchanged in dark theme?
      star: const HSLColor.fromAHSL(0.5, 47, 1, 0.41).toColor(),
      // TODO(design-dark) need proper dark-theme color (this is ad hoc)
      subscriptionListHeaderLine: const HSLColor.fromAHSL(0.4, 240, 0.1, 0.75).toColor(),
      // TODO(design-dark) need proper dark-theme color (this is ad hoc)
      subscriptionListHeaderText: const HSLColor.fromAHSL(1.0, 240, 0.1, 0.75).toColor(),
      unreadCountBadgeTextForChannel: Colors.white.withValues(alpha: 0.9),
    );

  DesignVariables._({
    required this.background,
    required this.bgContextMenu,
    required this.bgCounterUnread,
    required this.bgTopBar,
    required this.borderBar,
    required this.composeBoxBg,
    required this.contextMenuCancelText,
    required this.contextMenuItemBg,
    required this.contextMenuItemText,
    required this.editorButtonPressedBg,
    required this.foreground,
    required this.icon,
    required this.labelCounterUnread,
    required this.labelEdited,
    required this.labelMenuButton,
    required this.mainBackground,
    required this.textInput,
    required this.title,
    required this.channelColorSwatches,
    required this.atMentionMarker,
    required this.contextMenuCancelBg,
    required this.dmHeaderBg,
    required this.errorBannerBackground,
    required this.errorBannerBorder,
    required this.errorBannerLabel,
    required this.groupDmConversationIcon,
    required this.groupDmConversationIconBg,
    required this.loginOrDivider,
    required this.loginOrDividerText,
    required this.modalBarrierColor,
    required this.mutedUnreadBadge,
    required this.sectionCollapseIcon,
    required this.star,
    required this.subscriptionListHeaderLine,
    required this.subscriptionListHeaderText,
    required this.unreadCountBadgeTextForChannel,
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

  final Color background;
  final Color bgContextMenu;
  final Color bgCounterUnread;
  final Color bgTopBar;
  final Color borderBar;
  final Color composeBoxBg;
  final Color contextMenuCancelText;
  final Color contextMenuItemBg;
  final Color contextMenuItemText;
  final Color editorButtonPressedBg;
  final Color foreground;
  final Color icon;
  final Color labelCounterUnread;
  final Color labelEdited;
  final Color labelMenuButton;
  final Color mainBackground;
  final Color textInput;
  final Color title;

  // Not exactly from the Figma design, but from Vlad anyway.
  final ChannelColorSwatches channelColorSwatches;

  // Not named variables in Figma; taken from older Figma drafts, or elsewhere.
  final Color atMentionMarker;
  final Color contextMenuCancelBg; // In Figma, but unnamed.
  final Color dmHeaderBg;
  final Color errorBannerBackground;
  final Color errorBannerBorder;
  final Color errorBannerLabel;
  final Color groupDmConversationIcon;
  final Color groupDmConversationIconBg;
  final Color loginOrDivider; // TODO(design-dark) need proper dark-theme color (this is ad hoc)
  final Color loginOrDividerText; // TODO(design-dark) need proper dark-theme color (this is ad hoc)
  final Color modalBarrierColor;
  final Color mutedUnreadBadge;
  final Color sectionCollapseIcon;
  final Color star;
  final Color subscriptionListHeaderLine;
  final Color subscriptionListHeaderText;
  final Color unreadCountBadgeTextForChannel;

  @override
  DesignVariables copyWith({
    Color? background,
    Color? bgContextMenu,
    Color? bgCounterUnread,
    Color? bgTopBar,
    Color? borderBar,
    Color? composeBoxBg,
    Color? contextMenuCancelText,
    Color? contextMenuItemBg,
    Color? contextMenuItemText,
    Color? editorButtonPressedBg,
    Color? foreground,
    Color? icon,
    Color? labelCounterUnread,
    Color? labelEdited,
    Color? labelMenuButton,
    Color? mainBackground,
    Color? textInput,
    Color? title,
    ChannelColorSwatches? channelColorSwatches,
    Color? atMentionMarker,
    Color? contextMenuCancelBg,
    Color? dmHeaderBg,
    Color? errorBannerBackground,
    Color? errorBannerBorder,
    Color? errorBannerLabel,
    Color? groupDmConversationIcon,
    Color? groupDmConversationIconBg,
    Color? loginOrDivider,
    Color? loginOrDividerText,
    Color? modalBarrierColor,
    Color? mutedUnreadBadge,
    Color? sectionCollapseIcon,
    Color? star,
    Color? subscriptionListHeaderLine,
    Color? subscriptionListHeaderText,
    Color? unreadCountBadgeTextForChannel,
  }) {
    return DesignVariables._(
      background: background ?? this.background,
      bgContextMenu: bgContextMenu ?? this.bgContextMenu,
      bgCounterUnread: bgCounterUnread ?? this.bgCounterUnread,
      bgTopBar: bgTopBar ?? this.bgTopBar,
      borderBar: borderBar ?? this.borderBar,
      composeBoxBg: composeBoxBg ?? this.composeBoxBg,
      contextMenuCancelText: contextMenuCancelText ?? this.contextMenuCancelText,
      contextMenuItemBg: contextMenuItemBg ?? this.contextMenuItemBg,
      contextMenuItemText: contextMenuItemText ?? this.contextMenuItemBg,
      editorButtonPressedBg: editorButtonPressedBg ?? this.editorButtonPressedBg,
      foreground: foreground ?? this.foreground,
      icon: icon ?? this.icon,
      labelCounterUnread: labelCounterUnread ?? this.labelCounterUnread,
      labelEdited: labelEdited ?? this.labelEdited,
      labelMenuButton: labelMenuButton ?? this.labelMenuButton,
      mainBackground: mainBackground ?? this.mainBackground,
      textInput: textInput ?? this.textInput,
      title: title ?? this.title,
      channelColorSwatches: channelColorSwatches ?? this.channelColorSwatches,
      atMentionMarker: atMentionMarker ?? this.atMentionMarker,
      contextMenuCancelBg: contextMenuCancelBg ?? this.contextMenuCancelBg,
      dmHeaderBg: dmHeaderBg ?? this.dmHeaderBg,
      errorBannerBackground: errorBannerBackground ?? this.errorBannerBackground,
      errorBannerBorder: errorBannerBorder ?? this.errorBannerBorder,
      errorBannerLabel: errorBannerLabel ?? this.errorBannerLabel,
      groupDmConversationIcon: groupDmConversationIcon ?? this.groupDmConversationIcon,
      groupDmConversationIconBg: groupDmConversationIconBg ?? this.groupDmConversationIconBg,
      loginOrDivider: loginOrDivider ?? this.loginOrDivider,
      loginOrDividerText: loginOrDividerText ?? this.loginOrDividerText,
      modalBarrierColor: modalBarrierColor ?? this.modalBarrierColor,
      mutedUnreadBadge: mutedUnreadBadge ?? this.mutedUnreadBadge,
      sectionCollapseIcon: sectionCollapseIcon ?? this.sectionCollapseIcon,
      star: star ?? this.star,
      subscriptionListHeaderLine: subscriptionListHeaderLine ?? this.subscriptionListHeaderLine,
      subscriptionListHeaderText: subscriptionListHeaderText ?? this.subscriptionListHeaderText,
      unreadCountBadgeTextForChannel: unreadCountBadgeTextForChannel ?? this.unreadCountBadgeTextForChannel,
    );
  }

  @override
  DesignVariables lerp(DesignVariables other, double t) {
    if (identical(this, other)) {
      return this;
    }
    return DesignVariables._(
      background: Color.lerp(background, other.background, t)!,
      bgContextMenu: Color.lerp(bgContextMenu, other.bgContextMenu, t)!,
      bgCounterUnread: Color.lerp(bgCounterUnread, other.bgCounterUnread, t)!,
      bgTopBar: Color.lerp(bgTopBar, other.bgTopBar, t)!,
      borderBar: Color.lerp(borderBar, other.borderBar, t)!,
      composeBoxBg: Color.lerp(composeBoxBg, other.composeBoxBg, t)!,
      contextMenuCancelText: Color.lerp(contextMenuCancelText, other.contextMenuCancelText, t)!,
      contextMenuItemBg: Color.lerp(contextMenuItemBg, other.contextMenuItemBg, t)!,
      contextMenuItemText: Color.lerp(contextMenuItemText, other.contextMenuItemBg, t)!,
      editorButtonPressedBg: Color.lerp(editorButtonPressedBg, other.editorButtonPressedBg, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      labelCounterUnread: Color.lerp(labelCounterUnread, other.labelCounterUnread, t)!,
      labelEdited: Color.lerp(labelEdited, other.labelEdited, t)!,
      labelMenuButton: Color.lerp(labelMenuButton, other.labelMenuButton, t)!,
      mainBackground: Color.lerp(mainBackground, other.mainBackground, t)!,
      textInput: Color.lerp(textInput, other.textInput, t)!,
      title: Color.lerp(title, other.title, t)!,
      channelColorSwatches: ChannelColorSwatches.lerp(channelColorSwatches, other.channelColorSwatches, t),
      atMentionMarker: Color.lerp(atMentionMarker, other.atMentionMarker, t)!,
      contextMenuCancelBg: Color.lerp(contextMenuCancelBg, other.contextMenuCancelBg, t)!,
      dmHeaderBg: Color.lerp(dmHeaderBg, other.dmHeaderBg, t)!,
      errorBannerBackground: Color.lerp(errorBannerBackground, other.errorBannerBackground, t)!,
      errorBannerBorder: Color.lerp(errorBannerBorder, other.errorBannerBorder, t)!,
      errorBannerLabel: Color.lerp(errorBannerLabel, other.errorBannerLabel, t)!,
      groupDmConversationIcon: Color.lerp(groupDmConversationIcon, other.groupDmConversationIcon, t)!,
      groupDmConversationIconBg: Color.lerp(groupDmConversationIconBg, other.groupDmConversationIconBg, t)!,
      loginOrDivider: Color.lerp(loginOrDivider, other.loginOrDivider, t)!,
      loginOrDividerText: Color.lerp(loginOrDividerText, other.loginOrDividerText, t)!,
      modalBarrierColor: Color.lerp(modalBarrierColor, other.modalBarrierColor, t)!,
      mutedUnreadBadge: Color.lerp(mutedUnreadBadge, other.mutedUnreadBadge, t)!,
      sectionCollapseIcon: Color.lerp(sectionCollapseIcon, other.sectionCollapseIcon, t)!,
      star: Color.lerp(star, other.star, t)!,
      subscriptionListHeaderLine: Color.lerp(subscriptionListHeaderLine, other.subscriptionListHeaderLine, t)!,
      subscriptionListHeaderText: Color.lerp(subscriptionListHeaderText, other.subscriptionListHeaderText, t)!,
      unreadCountBadgeTextForChannel: Color.lerp(unreadCountBadgeTextForChannel, other.unreadCountBadgeTextForChannel, t)!,
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
