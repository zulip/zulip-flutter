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

  // This applies Material 3's color system to produce a palette of
  // appropriately matching and contrasting colors for use in a UI.
  // The Zulip brand color is a starting point, but doesn't end up as
  // one that's directly used.  (After all, we didn't design it for that
  // purpose; we designed a logo.)  See docs:
  //   https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html
  // Or try this tool to see the whole palette:
  //   https://m3.material.io/theme-builder#/custom
  final colorScheme = ColorScheme.fromSeed(
    brightness: brightness,
    seedColor: kZulipBrandColor);

  switch (brightness) {
    case Brightness.light: {
      designVariables = DesignVariables.light;
      themeExtensions = [
        ContentTheme.light(context),
        designVariables,
        EmojiReactionTheme.light(),
        MessageListTheme.light(),
      ];
    }
    case Brightness.dark: {
      designVariables = DesignVariables.dark;
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
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
      backgroundColor: colorScheme.secondaryContainer,
      foregroundColor: colorScheme.onSecondaryContainer,
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
    colorScheme: colorScheme,
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
  static final light = DesignVariables._(
    background: const Color(0xffffffff),
    bannerBgIntDanger: const Color(0xfff2e4e4),
    bgBotBar: const Color(0xfff6f6f6),
    bgContextMenu: const Color(0xfff2f2f2),
    bgCounterUnread: const Color(0xff666699).withValues(alpha: 0.15),
    bgMenuButtonActive: Colors.black.withValues(alpha: 0.05),
    bgMenuButtonSelected: Colors.white,
    bgTopBar: const Color(0xfff5f5f5),
    borderBar: Colors.black.withValues(alpha: 0.2),
    borderMenuButtonSelected: Colors.black.withValues(alpha: 0.2),
    btnLabelAttLowIntDanger: const Color(0xffc0070a),
    btnLabelAttMediumIntDanger: const Color(0xffac0508),
    composeBoxBg: const Color(0xffffffff),
    contextMenuCancelText: const Color(0xff222222),
    contextMenuItemBg: const Color(0xff6159e1),
    contextMenuItemText: const Color(0xff381da7),
    editorButtonPressedBg: Colors.black.withValues(alpha: 0.06),
    foreground: const Color(0xff000000),
    icon: const Color(0xff6159e1),
    iconSelected: const Color(0xff222222),
    labelCounterUnread: const Color(0xff222222),
    labelEdited: const HSLColor.fromAHSL(0.35, 0, 0, 0).toColor(),
    labelMenuButton: const Color(0xff222222),
    mainBackground: const Color(0xfff0f0f0),
    textInput: const Color(0xff000000),
    title: const Color(0xff1a1a1a),
    bgSearchInput: const Color(0xffe3e3e3),
    textMessage: const Color(0xff262626),
    channelColorSwatches: ChannelColorSwatches.light,
    colorMessageHeaderIconInteractive: Colors.black.withValues(alpha: 0.2),
    contextMenuCancelBg: const Color(0xff797986).withValues(alpha: 0.15),
    contextMenuCancelPressedBg: const Color(0xff797986).withValues(alpha: 0.20),
    dmHeaderBg: const HSLColor.fromAHSL(1, 46, 0.35, 0.93).toColor(),
    groupDmConversationIcon: Colors.black.withValues(alpha: 0.5),
    groupDmConversationIconBg: const Color(0x33808080),
    inboxItemIconMarker: const HSLColor.fromAHSL(0.5, 0, 0, 0.2).toColor(),
    loginOrDivider: const Color(0xffdedede),
    loginOrDividerText: const Color(0xff575757),
    modalBarrierColor: const Color(0xff000000).withValues(alpha: 0.3),
    mutedUnreadBadge: const HSLColor.fromAHSL(0.5, 0, 0, 0.8).toColor(),
    navigationButtonBg: Colors.black.withValues(alpha: 0.05),
    sectionCollapseIcon: const Color(0x7f1e2e48),
    star: const HSLColor.fromAHSL(0.5, 47, 1, 0.41).toColor(),
    subscriptionListHeaderLine: const HSLColor.fromAHSL(0.2, 240, 0.1, 0.5).toColor(),
    subscriptionListHeaderText: const HSLColor.fromAHSL(1.0, 240, 0.1, 0.5).toColor(),
    unreadCountBadgeTextForChannel: Colors.black.withValues(alpha: 0.9),
  );

  static final dark = DesignVariables._(
    background: const Color(0xff000000),
    bannerBgIntDanger: const Color(0xff461616),
    bgBotBar: const Color(0xff222222),
    bgContextMenu: const Color(0xff262626),
    bgCounterUnread: const Color(0xff666699).withValues(alpha: 0.37),
    bgMenuButtonActive: Colors.black.withValues(alpha: 0.2),
    bgMenuButtonSelected: Colors.black.withValues(alpha: 0.25),
    bgTopBar: const Color(0xff242424),
    borderBar: Colors.black.withValues(alpha: 0.5),
    borderMenuButtonSelected: Colors.white.withValues(alpha: 0.1),
    btnLabelAttLowIntDanger: const Color(0xffff8b7c),
    btnLabelAttMediumIntDanger: const Color(0xffff8b7c),
    composeBoxBg: const Color(0xff0f0f0f),
    contextMenuCancelText: const Color(0xffffffff).withValues(alpha: 0.75),
    contextMenuItemBg: const Color(0xff7977fe),
    contextMenuItemText: const Color(0xff9398fd),
    editorButtonPressedBg: Colors.white.withValues(alpha: 0.06),
    foreground: const Color(0xffffffff),
    icon: const Color(0xff7977fe),
    iconSelected: Colors.white.withValues(alpha: 0.8),
    labelCounterUnread: const Color(0xffffffff).withValues(alpha: 0.7),
    labelEdited: const HSLColor.fromAHSL(0.35, 0, 0, 1).toColor(),
    labelMenuButton: const Color(0xffffffff).withValues(alpha: 0.85),
    mainBackground: const Color(0xff1d1d1d),
    textInput: const Color(0xffffffff).withValues(alpha: 0.9),
    title: const Color(0xffffffff),
    bgSearchInput: const Color(0xff313131),
    textMessage: const Color(0xffffffff).withValues(alpha: 0.8),
    channelColorSwatches: ChannelColorSwatches.dark,
    contextMenuCancelBg: const Color(0xff797986).withValues(alpha: 0.15), // the same as the light mode in Figma
    contextMenuCancelPressedBg: const Color(0xff797986).withValues(alpha: 0.20), // the same as the light mode in Figma
    // TODO(design-dark) need proper dark-theme color (this is ad hoc)
    colorMessageHeaderIconInteractive: Colors.white.withValues(alpha: 0.2),
    dmHeaderBg: const HSLColor.fromAHSL(1, 46, 0.15, 0.2).toColor(),
    // TODO(design-dark) need proper dark-theme color (this is ad hoc)
    groupDmConversationIcon: Colors.white.withValues(alpha: 0.5),
    // TODO(design-dark) need proper dark-theme color (this is ad hoc)
    groupDmConversationIconBg: const Color(0x33cccccc),
    inboxItemIconMarker: const HSLColor.fromAHSL(0.4, 0, 0, 1).toColor(),
    loginOrDivider: const Color(0xff424242),
    loginOrDividerText: const Color(0xffa8a8a8),
    modalBarrierColor: const Color(0xff000000).withValues(alpha: 0.5),
    // TODO(design-dark) need proper dark-theme color (this is ad hoc)
    mutedUnreadBadge: const HSLColor.fromAHSL(0.5, 0, 0, 0.6).toColor(),
    navigationButtonBg: Colors.white.withValues(alpha: 0.05),
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
    required this.bannerBgIntDanger,
    required this.bgBotBar,
    required this.bgContextMenu,
    required this.bgCounterUnread,
    required this.bgMenuButtonActive,
    required this.bgMenuButtonSelected,
    required this.bgTopBar,
    required this.borderBar,
    required this.borderMenuButtonSelected,
    required this.btnLabelAttLowIntDanger,
    required this.btnLabelAttMediumIntDanger,
    required this.composeBoxBg,
    required this.contextMenuCancelText,
    required this.contextMenuItemBg,
    required this.contextMenuItemText,
    required this.editorButtonPressedBg,
    required this.foreground,
    required this.icon,
    required this.iconSelected,
    required this.labelCounterUnread,
    required this.labelEdited,
    required this.labelMenuButton,
    required this.mainBackground,
    required this.textInput,
    required this.title,
    required this.bgSearchInput,
    required this.textMessage,
    required this.channelColorSwatches,
    required this.colorMessageHeaderIconInteractive,
    required this.contextMenuCancelBg,
    required this.contextMenuCancelPressedBg,
    required this.dmHeaderBg,
    required this.groupDmConversationIcon,
    required this.groupDmConversationIconBg,
    required this.inboxItemIconMarker,
    required this.loginOrDivider,
    required this.loginOrDividerText,
    required this.modalBarrierColor,
    required this.mutedUnreadBadge,
    required this.navigationButtonBg,
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
  final Color bannerBgIntDanger;
  final Color bgBotBar;
  final Color bgContextMenu;
  final Color bgCounterUnread;
  final Color bgMenuButtonActive;
  final Color bgMenuButtonSelected;
  final Color bgTopBar;
  final Color borderBar;
  final Color borderMenuButtonSelected;
  final Color btnLabelAttLowIntDanger;
  final Color btnLabelAttMediumIntDanger;
  final Color composeBoxBg;
  final Color contextMenuCancelText;
  final Color contextMenuItemBg;
  final Color contextMenuItemText;
  final Color editorButtonPressedBg;
  final Color foreground;
  final Color icon;
  final Color iconSelected;
  final Color labelCounterUnread;
  final Color labelEdited;
  final Color labelMenuButton;
  final Color mainBackground;
  final Color textInput;
  final Color title;
  final Color bgSearchInput;
  final Color textMessage;

  // Not exactly from the Figma design, but from Vlad anyway.
  final ChannelColorSwatches channelColorSwatches;

  // Not named variables in Figma; taken from older Figma drafts, or elsewhere.
  final Color colorMessageHeaderIconInteractive;
  final Color contextMenuCancelBg; // In Figma, but unnamed.
  final Color contextMenuCancelPressedBg; // In Figma, but unnamed.
  final Color dmHeaderBg;
  final Color groupDmConversationIcon;
  final Color groupDmConversationIconBg;
  final Color inboxItemIconMarker;
  final Color loginOrDivider; // TODO(design-dark) need proper dark-theme color (this is ad hoc)
  final Color loginOrDividerText; // TODO(design-dark) need proper dark-theme color (this is ad hoc)
  final Color modalBarrierColor;
  final Color mutedUnreadBadge;
  final Color navigationButtonBg;
  final Color sectionCollapseIcon;
  final Color star;
  final Color subscriptionListHeaderLine;
  final Color subscriptionListHeaderText;
  final Color unreadCountBadgeTextForChannel;

  @override
  DesignVariables copyWith({
    Color? background,
    Color? bannerBgIntDanger,
    Color? bgBotBar,
    Color? bgContextMenu,
    Color? bgCounterUnread,
    Color? bgMenuButtonActive,
    Color? bgMenuButtonSelected,
    Color? bgTopBar,
    Color? borderBar,
    Color? borderMenuButtonSelected,
    Color? btnLabelAttLowIntDanger,
    Color? btnLabelAttMediumIntDanger,
    Color? composeBoxBg,
    Color? contextMenuCancelText,
    Color? contextMenuItemBg,
    Color? contextMenuItemText,
    Color? editorButtonPressedBg,
    Color? foreground,
    Color? icon,
    Color? iconSelected,
    Color? labelCounterUnread,
    Color? labelEdited,
    Color? labelMenuButton,
    Color? mainBackground,
    Color? textInput,
    Color? title,
    Color? bgSearchInput,
    Color? textMessage,
    ChannelColorSwatches? channelColorSwatches,
    Color? colorMessageHeaderIconInteractive,
    Color? contextMenuCancelBg,
    Color? contextMenuCancelPressedBg,
    Color? dmHeaderBg,
    Color? groupDmConversationIcon,
    Color? groupDmConversationIconBg,
    Color? inboxItemIconMarker,
    Color? loginOrDivider,
    Color? loginOrDividerText,
    Color? modalBarrierColor,
    Color? mutedUnreadBadge,
    Color? navigationButtonBg,
    Color? sectionCollapseIcon,
    Color? star,
    Color? subscriptionListHeaderLine,
    Color? subscriptionListHeaderText,
    Color? unreadCountBadgeTextForChannel,
  }) {
    return DesignVariables._(
      background: background ?? this.background,
      bannerBgIntDanger: bannerBgIntDanger ?? this.bannerBgIntDanger,
      bgBotBar: bgBotBar ?? this.bgBotBar,
      bgContextMenu: bgContextMenu ?? this.bgContextMenu,
      bgCounterUnread: bgCounterUnread ?? this.bgCounterUnread,
      bgMenuButtonActive: bgMenuButtonActive ?? this.bgMenuButtonActive,
      bgMenuButtonSelected: bgMenuButtonSelected ?? this.bgMenuButtonSelected,
      bgTopBar: bgTopBar ?? this.bgTopBar,
      borderBar: borderBar ?? this.borderBar,
      borderMenuButtonSelected: borderMenuButtonSelected ?? this.borderMenuButtonSelected,
      btnLabelAttLowIntDanger: btnLabelAttLowIntDanger ?? this.btnLabelAttLowIntDanger,
      btnLabelAttMediumIntDanger: btnLabelAttMediumIntDanger ?? this.btnLabelAttMediumIntDanger,
      composeBoxBg: composeBoxBg ?? this.composeBoxBg,
      contextMenuCancelText: contextMenuCancelText ?? this.contextMenuCancelText,
      contextMenuItemBg: contextMenuItemBg ?? this.contextMenuItemBg,
      contextMenuItemText: contextMenuItemText ?? this.contextMenuItemBg,
      editorButtonPressedBg: editorButtonPressedBg ?? this.editorButtonPressedBg,
      foreground: foreground ?? this.foreground,
      icon: icon ?? this.icon,
      iconSelected: iconSelected ?? this.iconSelected,
      labelCounterUnread: labelCounterUnread ?? this.labelCounterUnread,
      labelEdited: labelEdited ?? this.labelEdited,
      labelMenuButton: labelMenuButton ?? this.labelMenuButton,
      mainBackground: mainBackground ?? this.mainBackground,
      textInput: textInput ?? this.textInput,
      title: title ?? this.title,
      bgSearchInput: bgSearchInput ?? this.bgSearchInput,
      textMessage: textMessage ?? this.textMessage,
      channelColorSwatches: channelColorSwatches ?? this.channelColorSwatches,
      colorMessageHeaderIconInteractive: colorMessageHeaderIconInteractive ?? this.colorMessageHeaderIconInteractive,
      contextMenuCancelBg: contextMenuCancelBg ?? this.contextMenuCancelBg,
      contextMenuCancelPressedBg: contextMenuCancelPressedBg ?? this.contextMenuCancelPressedBg,
      dmHeaderBg: dmHeaderBg ?? this.dmHeaderBg,
      groupDmConversationIcon: groupDmConversationIcon ?? this.groupDmConversationIcon,
      groupDmConversationIconBg: groupDmConversationIconBg ?? this.groupDmConversationIconBg,
      inboxItemIconMarker: inboxItemIconMarker ?? this.inboxItemIconMarker,
      loginOrDivider: loginOrDivider ?? this.loginOrDivider,
      loginOrDividerText: loginOrDividerText ?? this.loginOrDividerText,
      modalBarrierColor: modalBarrierColor ?? this.modalBarrierColor,
      mutedUnreadBadge: mutedUnreadBadge ?? this.mutedUnreadBadge,
      navigationButtonBg: navigationButtonBg ?? this.navigationButtonBg,
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
      bannerBgIntDanger: Color.lerp(bannerBgIntDanger, other.bannerBgIntDanger, t)!,
      bgBotBar: Color.lerp(bgBotBar, other.bgBotBar, t)!,
      bgContextMenu: Color.lerp(bgContextMenu, other.bgContextMenu, t)!,
      bgCounterUnread: Color.lerp(bgCounterUnread, other.bgCounterUnread, t)!,
      bgMenuButtonActive: Color.lerp(bgMenuButtonActive, other.bgMenuButtonActive, t)!,
      bgMenuButtonSelected: Color.lerp(bgMenuButtonSelected, other.bgMenuButtonSelected, t)!,
      bgTopBar: Color.lerp(bgTopBar, other.bgTopBar, t)!,
      borderBar: Color.lerp(borderBar, other.borderBar, t)!,
      borderMenuButtonSelected: Color.lerp(borderMenuButtonSelected, other.borderMenuButtonSelected, t)!,
      btnLabelAttLowIntDanger: Color.lerp(btnLabelAttLowIntDanger, other.btnLabelAttLowIntDanger, t)!,
      btnLabelAttMediumIntDanger: Color.lerp(btnLabelAttMediumIntDanger, other.btnLabelAttMediumIntDanger, t)!,
      composeBoxBg: Color.lerp(composeBoxBg, other.composeBoxBg, t)!,
      contextMenuCancelText: Color.lerp(contextMenuCancelText, other.contextMenuCancelText, t)!,
      contextMenuItemBg: Color.lerp(contextMenuItemBg, other.contextMenuItemBg, t)!,
      contextMenuItemText: Color.lerp(contextMenuItemText, other.contextMenuItemBg, t)!,
      editorButtonPressedBg: Color.lerp(editorButtonPressedBg, other.editorButtonPressedBg, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      iconSelected: Color.lerp(iconSelected, other.iconSelected, t)!,
      labelCounterUnread: Color.lerp(labelCounterUnread, other.labelCounterUnread, t)!,
      labelEdited: Color.lerp(labelEdited, other.labelEdited, t)!,
      labelMenuButton: Color.lerp(labelMenuButton, other.labelMenuButton, t)!,
      mainBackground: Color.lerp(mainBackground, other.mainBackground, t)!,
      textInput: Color.lerp(textInput, other.textInput, t)!,
      title: Color.lerp(title, other.title, t)!,
      bgSearchInput: Color.lerp(bgSearchInput, other.bgSearchInput, t)!,
      textMessage: Color.lerp(textMessage, other.textMessage, t)!,
      channelColorSwatches: ChannelColorSwatches.lerp(channelColorSwatches, other.channelColorSwatches, t),
      colorMessageHeaderIconInteractive: Color.lerp(colorMessageHeaderIconInteractive, other.colorMessageHeaderIconInteractive, t)!,
      contextMenuCancelBg: Color.lerp(contextMenuCancelBg, other.contextMenuCancelBg, t)!,
      contextMenuCancelPressedBg: Color.lerp(contextMenuCancelPressedBg, other.contextMenuCancelPressedBg, t)!,
      dmHeaderBg: Color.lerp(dmHeaderBg, other.dmHeaderBg, t)!,
      groupDmConversationIcon: Color.lerp(groupDmConversationIcon, other.groupDmConversationIcon, t)!,
      groupDmConversationIconBg: Color.lerp(groupDmConversationIconBg, other.groupDmConversationIconBg, t)!,
      inboxItemIconMarker: Color.lerp(inboxItemIconMarker, other.inboxItemIconMarker, t)!,
      loginOrDivider: Color.lerp(loginOrDivider, other.loginOrDivider, t)!,
      loginOrDividerText: Color.lerp(loginOrDividerText, other.loginOrDividerText, t)!,
      modalBarrierColor: Color.lerp(modalBarrierColor, other.modalBarrierColor, t)!,
      mutedUnreadBadge: Color.lerp(mutedUnreadBadge, other.mutedUnreadBadge, t)!,
      navigationButtonBg: Color.lerp(navigationButtonBg, other.navigationButtonBg, t)!,
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
