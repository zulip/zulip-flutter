import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../model/settings.dart';
import 'compose_box.dart';
import 'content.dart';
import 'emoji_reaction.dart';
import 'message_list.dart';
import 'channel_colors.dart';
import 'store.dart';
import 'text.dart';

ThemeData zulipThemeData(BuildContext context) {
  final DesignVariables designVariables;
  final List<ThemeExtension> themeExtensions;
  final globalSettings = GlobalStoreWidget.settingsOf(context);
  Brightness brightness = switch (globalSettings.themeSetting) {
    null => MediaQuery.platformBrightnessOf(context),
    ThemeSetting.light => Brightness.light,
    ThemeSetting.dark => Brightness.dark,
  };

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
        EmojiReactionTheme.light,
        MessageListTheme.light,
        ComposeBoxTheme.light,
      ];
    }
    case Brightness.dark: {
      designVariables = DesignVariables.dark;
      themeExtensions = [
        ContentTheme.dark(context),
        designVariables,
        EmojiReactionTheme.dark,
        MessageListTheme.dark,
        ComposeBoxTheme.dark,
      ];
    }
  }

  return ThemeData(
    brightness: brightness,
    typography: zulipTypography(context),
    extensions: themeExtensions,

    // Use "standard" visual density (the default for mobile platforms)
    // on all platforms.  That helps the desktop builds of the app be faithful
    // previews of how the app behaves on mobile -- which is the only purpose
    // we use the desktop builds for.
    visualDensity: VisualDensity.standard,

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
    bannerBgIntInfo: const Color(0xffddecf6),
    bannerBgIntWarning: const Color(0xfffaf5dc),
    bannerTextIntInfo: const Color(0xff06037c),
    bgBotBar: const Color(0xfff6f6f6),
    bgContextMenu: const Color(0xfff2f2f2),
    bgCounterUnread: const Color(0xff666699).withValues(alpha: 0.15),
    bgMenuButtonActive: Colors.black.withValues(alpha: 0.05),
    bgMenuButtonSelected: Colors.white,
    bgMessageRegular: const HSLColor.fromAHSL(1, 0, 0, 1).toColor(),
    bgTopBar: const Color(0xfff5f5f5),
    borderBar: Colors.black.withValues(alpha: 0.2),
    borderMenuButtonSelected: Colors.black.withValues(alpha: 0.2),
    btnBgAttHighIntInfoActive: const Color(0xff1e41d3),
    btnBgAttHighIntInfoNormal: const Color(0xff3c6bff),
    btnBgAttHighIntWarningActive: const Color(0xffeba002),
    btnBgAttHighIntWarningNormal: const Color(0xfffebe3d),
    btnBgAttMediumIntInfoActive: const Color(0xff3c6bff).withValues(alpha: 0.22),
    btnBgAttMediumIntInfoNormal: const Color(0xff3c6bff).withValues(alpha: 0.12),
    btnBgAttMediumIntWarningActive: const Color(0xffeba001).withValues(alpha: 0.28),
    btnBgAttMediumIntWarningNormal: const Color(0xffeba002).withValues(alpha: 0.18),
    btnLabelAttHigh: const Color(0xffffffff),
    btnLabelAttHighIntWarning: const Color(0xff000000).withValues(alpha: 0.88),
    btnLabelAttLowIntDanger: const Color(0xffc0070a),
    btnLabelAttLowIntInfo: const Color(0xff2347c6),
    btnLabelAttMediumIntDanger: const Color(0xffac0508),
    btnLabelAttMediumIntInfo: const Color(0xff1027a6),
    btnLabelAttMediumIntWarning: const Color(0xff764607),
    btnShadowAttMed: const Color(0xff000000).withValues(alpha: 0.20),
    composeBoxBg: const Color(0xffffffff),
    contextMenuCancelText: const Color(0xff222222),
    contextMenuItemBg: const Color(0xff6159e1),
    contextMenuItemBgDanger: const Color(0xffc0070a), // TODO(#831) red/550
    contextMenuItemIcon: const Color(0xff4f42c9),
    contextMenuItemIconDanger: const Color(0xffac0508), // TODO(#831) red/600
    contextMenuItemLabel: const Color(0xff242631),
    contextMenuItemMeta: const Color(0xff626573),
    contextMenuItemText: const Color(0xff381da7),
    contextMenuItemTextDanger: const Color(0xffac0508), // TODO(#831) red/600
    editorButtonPressedBg: Colors.black.withValues(alpha: 0.06),
    fabBg: const Color(0xff6e69f3),
    fabBgPressed: const Color(0xff6159e1),
    fabLabel: const Color(0xfff1f3fe),
    fabLabelPressed: const Color(0xffeceefc),
    fabShadow: const Color(0xff2b0e8a).withValues(alpha: 0.4),
    foreground: const Color(0xff000000),
    icon: const Color(0xff6159e1),
    iconSelected: const Color(0xff222222),
    labelCounterUnread: const Color(0xff1a1a1a),
    labelEdited: const HSLColor.fromAHSL(0.35, 0, 0, 0).toColor(),
    labelMenuButton: const Color(0xff222222),
    labelSearchPrompt: const Color(0xff000000).withValues(alpha: 0.5),
    labelTime: const Color(0x00000000).withValues(alpha: 0.49),
    link: const Color(0xff066bd0), // from "Zulip Web UI kit"
    listMenuItemBg: const Color(0xffcbcdd6),
    listMenuItemIcon: const Color(0xff9194a3),
    listMenuItemText: const Color(0xff2d303c),

    // Keep the color here and the corresponding non-dark mode entry in
    // ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json
    // in sync.
    mainBackground: const Color(0xfff0f0f0),

    neutralButtonBg: const Color(0xff8c84ae),
    neutralButtonLabel: const Color(0xff433d5c),
    radioBorder: Color(0xffbbbdc8),
    radioFillSelected: Color(0xff4370f0),
    statusAway: Color(0xff73788c).withValues(alpha: 0.25),

    // Following Web because it uses a gradient, to distinguish it by shape from
    // the "active" dot, and the Figma doesn't; Figma just has solid #d5bb6c.
    statusIdle: Color(0xfff5b266),

    statusOnline: Color(0xff46aa62),
    textInput: const Color(0xff000000),
    title: const Color(0xff1a1a1a),
    bgSearchInput: const Color(0xffe3e3e3),
    textMessage: const Color(0xff262626),
    textMessageMuted: const Color(0xff262626).withValues(alpha: 0.6),
    channelColorSwatches: ChannelColorSwatches.light,
    avatarPlaceholderBg: const Color(0x33808080),
    avatarPlaceholderIcon: Colors.black.withValues(alpha: 0.5),
    contextMenuCancelBg: const Color(0xff797986).withValues(alpha: 0.15),
    contextMenuCancelPressedBg: const Color(0xff797986).withValues(alpha: 0.20),
    dmHeaderBg: const HSLColor.fromAHSL(1, 46, 0.35, 0.93).toColor(),
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
    userStatusText: const Color(0xff808080),
  );

  static final dark = DesignVariables._(
    background: const Color(0xff000000),
    bannerBgIntDanger: const Color(0xff461616),
    bannerBgIntInfo: const Color(0xff00253d),
    bannerBgIntWarning: const Color(0xff332b00),
    bannerTextIntInfo: const Color(0xffcbdbfd),
    bgBotBar: const Color(0xff222222),
    bgContextMenu: const Color(0xff262626),
    bgCounterUnread: const Color(0xff666699).withValues(alpha: 0.37),
    bgMenuButtonActive: Colors.black.withValues(alpha: 0.2),
    bgMenuButtonSelected: Colors.black.withValues(alpha: 0.25),
    bgMessageRegular: const HSLColor.fromAHSL(1, 0, 0, 0.11).toColor(),
    bgTopBar: const Color(0xff242424),
    borderBar: const Color(0xffffffff).withValues(alpha: 0.1),
    borderMenuButtonSelected: Colors.white.withValues(alpha: 0.1),
    btnBgAttHighIntInfoActive: const Color(0xff1e41d3),
    btnBgAttHighIntInfoNormal: const Color(0xff1e41d3),
    btnBgAttHighIntWarningActive: const Color(0xffdb920d),
    btnBgAttHighIntWarningNormal: const Color(0xffdb920d),
    btnBgAttMediumIntInfoActive: const Color(0xff97b6fe).withValues(alpha: 0.12),
    btnBgAttMediumIntInfoNormal: const Color(0xff97b6fe).withValues(alpha: 0.12),
    btnBgAttMediumIntWarningActive: const Color(0xffdb920d).withValues(alpha: 0.12),
    btnBgAttMediumIntWarningNormal: const Color(0xffdb920d).withValues(alpha: 0.12),
    btnLabelAttHigh: const Color(0xffffffff).withValues(alpha: 0.85),
    btnLabelAttHighIntWarning: const Color(0xff000000).withValues(alpha: 0.90),
    btnLabelAttLowIntDanger: const Color(0xffff8b7c),
    btnLabelAttLowIntInfo: const Color(0xff84a8fd),
    btnLabelAttMediumIntDanger: const Color(0xffff8b7c),
    btnLabelAttMediumIntInfo: const Color(0xff97b6fe),
    btnLabelAttMediumIntWarning: const Color(0xfff8b325),
    btnShadowAttMed: const Color(0xffffffff).withValues(alpha: 0.21),
    composeBoxBg: const Color(0xff0f0f0f),
    contextMenuCancelText: const Color(0xffffffff).withValues(alpha: 0.75),
    contextMenuItemBg: const Color(0xff7977fe),
    contextMenuItemBgDanger: const Color(0xffe1392e), // TODO(#831) red/450
    contextMenuItemIcon: const Color(0xff9398fd),
    contextMenuItemIconDanger: const Color(0xfffd7465), // TODO(#831) red/300
    contextMenuItemLabel: const Color(0xffdfe1e8),
    contextMenuItemMeta: const Color(0xff9194a3),
    contextMenuItemText: const Color(0xff9398fd),
    contextMenuItemTextDanger: const Color(0xfffd7465), // TODO(#831) red/300
    editorButtonPressedBg: Colors.white.withValues(alpha: 0.06),
    fabBg: const Color(0xff4f42c9),
    fabBgPressed: const Color(0xff4331b8),
    fabLabel: const Color(0xffeceefc),
    fabLabelPressed: const Color(0xffeceefc),
    fabShadow: const Color(0xff18171c),
    foreground: const Color(0xffffffff),
    icon: const Color(0xff7977fe),
    iconSelected: Colors.white.withValues(alpha: 0.8),
    labelCounterUnread: const Color(0xffffffff).withValues(alpha: 0.95),
    labelEdited: const HSLColor.fromAHSL(0.35, 0, 0, 1).toColor(),
    labelMenuButton: const Color(0xffffffff).withValues(alpha: 0.85),
    labelSearchPrompt: const Color(0xffffffff).withValues(alpha: 0.5),
    labelTime: const Color(0xffffffff).withValues(alpha: 0.50),
    link: const Color(0xff00aaff), // from "Zulip Web UI kit"
    listMenuItemBg: const Color(0xff2d303c),
    listMenuItemIcon: const Color(0xff767988),
    listMenuItemText: const Color(0xffcbcdd6),

    // Keep the color here and the corresponding dark mode entry in
    // ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json
    // in sync.
    mainBackground: const Color(0xff1d1d1d),

    neutralButtonBg: const Color(0xffd4d1e0),
    neutralButtonLabel: const Color(0xffa9a3c2),
    radioBorder: Color(0xff626573),
    radioFillSelected: Color(0xff4e7cfa),
    statusAway: Color(0xffabaeba).withValues(alpha: 0.30),

    // Following Web because it uses a gradient, to distinguish it by shape from
    // the "active" dot, and the Figma doesn't; Figma just has solid #8c853b.
    statusIdle: Color(0xffae640a),

    statusOnline: Color(0xff44bb66),
    textInput: const Color(0xffffffff).withValues(alpha: 0.9),
    title: const Color(0xffffffff).withValues(alpha: 0.9),
    bgSearchInput: const Color(0xff313131),
    textMessage: const Color(0xffffffff).withValues(alpha: 0.8),
    textMessageMuted: const Color(0xffffffff).withValues(alpha: 0.5),
    channelColorSwatches: ChannelColorSwatches.dark,
    // TODO(design-dark) need proper dark-theme color (this is ad hoc)
    avatarPlaceholderBg: const Color(0x33cccccc),
    // TODO(design-dark) need proper dark-theme color (this is ad hoc)
    avatarPlaceholderIcon: Colors.white.withValues(alpha: 0.5),
    contextMenuCancelBg: const Color(0xff797986).withValues(alpha: 0.15), // the same as the light mode in Figma
    contextMenuCancelPressedBg: const Color(0xff797986).withValues(alpha: 0.20), // the same as the light mode in Figma
    // TODO(design-dark) need proper dark-theme color (this is ad hoc)
    dmHeaderBg: const HSLColor.fromAHSL(1, 46, 0.15, 0.2).toColor(),
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
    // TODO(design-dark) unchanged in dark theme?
    userStatusText: const Color(0xff808080),
  );

  DesignVariables._({
    required this.background,
    required this.bannerBgIntDanger,
    required this.bannerBgIntInfo,
    required this.bannerBgIntWarning,
    required this.bannerTextIntInfo,
    required this.bgBotBar,
    required this.bgContextMenu,
    required this.bgCounterUnread,
    required this.bgMenuButtonActive,
    required this.bgMenuButtonSelected,
    required this.bgMessageRegular,
    required this.bgTopBar,
    required this.borderBar,
    required this.borderMenuButtonSelected,
    required this.btnBgAttHighIntInfoActive,
    required this.btnBgAttHighIntInfoNormal,
    required this.btnBgAttHighIntWarningActive,
    required this.btnBgAttHighIntWarningNormal,
    required this.btnBgAttMediumIntInfoActive,
    required this.btnBgAttMediumIntInfoNormal,
    required this.btnBgAttMediumIntWarningActive,
    required this.btnBgAttMediumIntWarningNormal,
    required this.btnLabelAttHigh,
    required this.btnLabelAttHighIntWarning,
    required this.btnLabelAttLowIntDanger,
    required this.btnLabelAttLowIntInfo,
    required this.btnLabelAttMediumIntDanger,
    required this.btnLabelAttMediumIntInfo,
    required this.btnLabelAttMediumIntWarning,
    required this.btnShadowAttMed,
    required this.composeBoxBg,
    required this.contextMenuCancelText,
    required this.contextMenuItemBg,
    required this.contextMenuItemBgDanger,
    required this.contextMenuItemIcon,
    required this.contextMenuItemIconDanger,
    required this.contextMenuItemLabel,
    required this.contextMenuItemMeta,
    required this.contextMenuItemText,
    required this.contextMenuItemTextDanger,
    required this.editorButtonPressedBg,
    required this.foreground,
    required this.fabBg,
    required this.fabBgPressed,
    required this.fabLabel,
    required this.fabLabelPressed,
    required this.fabShadow,
    required this.icon,
    required this.iconSelected,
    required this.labelCounterUnread,
    required this.labelEdited,
    required this.labelMenuButton,
    required this.labelSearchPrompt,
    required this.labelTime,
    required this.link,
    required this.listMenuItemBg,
    required this.listMenuItemIcon,
    required this.listMenuItemText,
    required this.mainBackground,
    required this.neutralButtonBg,
    required this.neutralButtonLabel,
    required this.radioBorder,
    required this.radioFillSelected,
    required this.statusAway,
    required this.statusIdle,
    required this.statusOnline,
    required this.textInput,
    required this.title,
    required this.bgSearchInput,
    required this.textMessage,
    required this.textMessageMuted,
    required this.channelColorSwatches,
    required this.avatarPlaceholderBg,
    required this.avatarPlaceholderIcon,
    required this.contextMenuCancelBg,
    required this.contextMenuCancelPressedBg,
    required this.dmHeaderBg,
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
    required this.userStatusText,
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
  final Color bannerBgIntInfo;
  final Color bannerBgIntWarning;
  final Color bannerTextIntInfo;
  final Color bgBotBar;
  final Color bgContextMenu;
  final Color bgCounterUnread;
  final Color bgMenuButtonActive;
  final Color bgMenuButtonSelected;
  final Color bgMessageRegular;
  final Color bgTopBar;
  final Color borderBar;
  final Color borderMenuButtonSelected;
  final Color btnBgAttHighIntInfoActive;
  final Color btnBgAttHighIntInfoNormal;
  final Color btnBgAttHighIntWarningActive;
  final Color btnBgAttHighIntWarningNormal;
  final Color btnBgAttMediumIntInfoActive;
  final Color btnBgAttMediumIntInfoNormal;
  final Color btnBgAttMediumIntWarningActive;
  final Color btnBgAttMediumIntWarningNormal;
  final Color btnLabelAttHigh;
  final Color btnLabelAttHighIntWarning;
  final Color btnLabelAttLowIntDanger;
  final Color btnLabelAttLowIntInfo;
  final Color btnLabelAttMediumIntDanger;
  final Color btnLabelAttMediumIntInfo;
  final Color btnLabelAttMediumIntWarning;
  final Color btnShadowAttMed;
  final Color composeBoxBg;
  final Color contextMenuCancelText;
  final Color contextMenuItemBg;
  final Color contextMenuItemBgDanger;
  final Color contextMenuItemIcon;
  final Color contextMenuItemIconDanger;
  final Color contextMenuItemLabel;
  final Color contextMenuItemMeta;
  final Color contextMenuItemText;
  final Color contextMenuItemTextDanger;
  final Color editorButtonPressedBg;
  final Color fabBg;
  final Color fabBgPressed;
  final Color fabLabel;
  final Color fabLabelPressed;
  final Color fabShadow;
  final Color foreground;
  final Color icon;
  final Color iconSelected;
  final Color labelCounterUnread;
  final Color labelEdited;
  final Color labelMenuButton;
  final Color labelSearchPrompt;
  final Color labelTime;
  final Color link;
  final Color listMenuItemBg;
  final Color listMenuItemIcon;
  final Color listMenuItemText;
  final Color mainBackground;
  final Color neutralButtonBg;
  final Color neutralButtonLabel;
  final Color radioBorder;
  final Color radioFillSelected;
  final Color statusAway;
  final Color statusIdle;
  final Color statusOnline;
  final Color textInput;
  final Color title;
  final Color bgSearchInput;
  final Color textMessage;
  final Color textMessageMuted;

  // Not exactly from the Figma design, but from Vlad anyway.
  final ChannelColorSwatches channelColorSwatches;

  // Not named variables in Figma; taken from older Figma drafts, or elsewhere.
  final Color avatarPlaceholderBg;
  final Color avatarPlaceholderIcon;
  final Color contextMenuCancelBg; // In Figma, but unnamed.
  final Color contextMenuCancelPressedBg; // In Figma, but unnamed.
  final Color dmHeaderBg;
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
  final Color userStatusText; // In Figma, but unnamed.

  @override
  DesignVariables copyWith({
    Color? background,
    Color? bannerBgIntDanger,
    Color? bannerBgIntInfo,
    Color? bannerBgIntWarning,
    Color? bannerTextIntInfo,
    Color? bgBotBar,
    Color? bgContextMenu,
    Color? bgCounterUnread,
    Color? bgMenuButtonActive,
    Color? bgMenuButtonSelected,
    Color? bgMessageRegular,
    Color? bgTopBar,
    Color? borderBar,
    Color? borderMenuButtonSelected,
    Color? btnBgAttHighIntInfoActive,
    Color? btnBgAttHighIntInfoNormal,
    Color? btnBgAttHighIntWarningActive,
    Color? btnBgAttHighIntWarningNormal,
    Color? btnBgAttMediumIntInfoActive,
    Color? btnBgAttMediumIntInfoNormal,
    Color? btnBgAttMediumIntWarningActive,
    Color? btnBgAttMediumIntWarningNormal,
    Color? btnLabelAttHigh,
    Color? btnLabelAttHighIntWarning,
    Color? btnLabelAttLowIntDanger,
    Color? btnLabelAttLowIntInfo,
    Color? btnLabelAttMediumIntDanger,
    Color? btnLabelAttMediumIntInfo,
    Color? btnLabelAttMediumIntWarning,
    Color? btnShadowAttMed,
    Color? composeBoxBg,
    Color? contextMenuCancelText,
    Color? contextMenuItemBg,
    Color? contextMenuItemBgDanger,
    Color? contextMenuItemIcon,
    Color? contextMenuItemIconDanger,
    Color? contextMenuItemLabel,
    Color? contextMenuItemMeta,
    Color? contextMenuItemText,
    Color? contextMenuItemTextDanger,
    Color? editorButtonPressedBg,
    Color? fabBg,
    Color? fabBgPressed,
    Color? fabLabel,
    Color? fabLabelPressed,
    Color? fabShadow,
    Color? foreground,
    Color? icon,
    Color? iconSelected,
    Color? labelCounterUnread,
    Color? labelEdited,
    Color? labelMenuButton,
    Color? labelSearchPrompt,
    Color? labelTime,
    Color? link,
    Color? listMenuItemBg,
    Color? listMenuItemIcon,
    Color? listMenuItemText,
    Color? mainBackground,
    Color? neutralButtonBg,
    Color? neutralButtonLabel,
    Color? radioBorder,
    Color? radioFillSelected,
    Color? statusAway,
    Color? statusIdle,
    Color? statusOnline,
    Color? textInput,
    Color? title,
    Color? bgSearchInput,
    Color? textMessage,
    Color? textMessageMuted,
    ChannelColorSwatches? channelColorSwatches,
    Color? avatarPlaceholderBg,
    Color? avatarPlaceholderIcon,
    Color? contextMenuCancelBg,
    Color? contextMenuCancelPressedBg,
    Color? dmHeaderBg,
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
    Color? userStatusText,
  }) {
    return DesignVariables._(
      background: background ?? this.background,
      bannerBgIntDanger: bannerBgIntDanger ?? this.bannerBgIntDanger,
      bannerBgIntInfo: bannerBgIntInfo ?? this.bannerBgIntInfo,
      bannerBgIntWarning: bannerBgIntWarning ?? this.bannerBgIntWarning,
      bannerTextIntInfo: bannerTextIntInfo ?? this.bannerTextIntInfo,
      bgBotBar: bgBotBar ?? this.bgBotBar,
      bgContextMenu: bgContextMenu ?? this.bgContextMenu,
      bgCounterUnread: bgCounterUnread ?? this.bgCounterUnread,
      bgMenuButtonActive: bgMenuButtonActive ?? this.bgMenuButtonActive,
      bgMenuButtonSelected: bgMenuButtonSelected ?? this.bgMenuButtonSelected,
      bgMessageRegular: bgMessageRegular ?? this.bgMessageRegular,
      bgTopBar: bgTopBar ?? this.bgTopBar,
      borderBar: borderBar ?? this.borderBar,
      borderMenuButtonSelected: borderMenuButtonSelected ?? this.borderMenuButtonSelected,
      btnBgAttHighIntInfoActive: btnBgAttHighIntInfoActive ?? this.btnBgAttHighIntInfoActive,
      btnBgAttHighIntInfoNormal: btnBgAttHighIntInfoNormal ?? this.btnBgAttHighIntInfoNormal,
      btnBgAttHighIntWarningActive: btnBgAttHighIntWarningActive ?? this.btnBgAttHighIntWarningActive,
      btnBgAttHighIntWarningNormal: btnBgAttHighIntWarningNormal ?? this.btnBgAttHighIntWarningNormal,
      btnBgAttMediumIntInfoActive: btnBgAttMediumIntInfoActive ?? this.btnBgAttMediumIntInfoActive,
      btnBgAttMediumIntInfoNormal: btnBgAttMediumIntInfoNormal ?? this.btnBgAttMediumIntInfoNormal,
      btnBgAttMediumIntWarningActive: btnBgAttMediumIntWarningActive ?? this.btnBgAttMediumIntWarningActive,
      btnBgAttMediumIntWarningNormal: btnBgAttMediumIntWarningNormal ?? this.btnBgAttMediumIntWarningNormal,
      btnLabelAttHigh: btnLabelAttHigh ?? this.btnLabelAttHigh,
      btnLabelAttHighIntWarning: btnLabelAttHighIntWarning ?? this.btnLabelAttHighIntWarning,
      btnLabelAttLowIntDanger: btnLabelAttLowIntDanger ?? this.btnLabelAttLowIntDanger,
      btnLabelAttLowIntInfo: btnLabelAttLowIntInfo ?? this.btnLabelAttLowIntInfo,
      btnLabelAttMediumIntDanger: btnLabelAttMediumIntDanger ?? this.btnLabelAttMediumIntDanger,
      btnLabelAttMediumIntInfo: btnLabelAttMediumIntInfo ?? this.btnLabelAttMediumIntInfo,
      btnLabelAttMediumIntWarning: btnLabelAttMediumIntWarning ?? this.btnLabelAttMediumIntWarning,
      btnShadowAttMed: btnShadowAttMed ?? this.btnShadowAttMed,
      composeBoxBg: composeBoxBg ?? this.composeBoxBg,
      contextMenuCancelText: contextMenuCancelText ?? this.contextMenuCancelText,
      contextMenuItemBg: contextMenuItemBg ?? this.contextMenuItemBg,
      contextMenuItemBgDanger: contextMenuItemBgDanger ?? this.contextMenuItemBgDanger,
      contextMenuItemIcon: contextMenuItemIcon ?? this.contextMenuItemIcon,
      contextMenuItemIconDanger: contextMenuItemIconDanger ?? this.contextMenuItemIconDanger,
      contextMenuItemLabel: contextMenuItemLabel ?? this.contextMenuItemLabel,
      contextMenuItemMeta: contextMenuItemMeta ?? this.contextMenuItemMeta,
      contextMenuItemText: contextMenuItemText ?? this.contextMenuItemText,
      contextMenuItemTextDanger: contextMenuItemTextDanger ?? this.contextMenuItemTextDanger,
      editorButtonPressedBg: editorButtonPressedBg ?? this.editorButtonPressedBg,
      foreground: foreground ?? this.foreground,
      fabBg: fabBg ?? this.fabBg,
      fabBgPressed: fabBgPressed ?? this.fabBgPressed,
      fabLabel: fabLabel ?? this.fabLabel,
      fabLabelPressed: fabLabelPressed ?? this.fabLabelPressed,
      fabShadow: fabShadow ?? this.fabShadow,
      icon: icon ?? this.icon,
      iconSelected: iconSelected ?? this.iconSelected,
      labelCounterUnread: labelCounterUnread ?? this.labelCounterUnread,
      labelEdited: labelEdited ?? this.labelEdited,
      labelMenuButton: labelMenuButton ?? this.labelMenuButton,
      labelSearchPrompt: labelSearchPrompt ?? this.labelSearchPrompt,
      labelTime: labelTime ?? this.labelTime,
      link: link ?? this.link,
      listMenuItemBg: listMenuItemBg ?? this.listMenuItemBg,
      listMenuItemIcon: listMenuItemIcon ?? this.listMenuItemIcon,
      listMenuItemText: listMenuItemText ?? this.listMenuItemText,
      mainBackground: mainBackground ?? this.mainBackground,
      neutralButtonBg: neutralButtonBg ?? this.neutralButtonBg,
      neutralButtonLabel: neutralButtonLabel ?? this.neutralButtonLabel,
      radioBorder: radioBorder ?? this.radioBorder,
      radioFillSelected: radioFillSelected ?? this.radioFillSelected,
      statusAway: statusAway ?? this.statusAway,
      statusIdle: statusIdle ?? this.statusIdle,
      statusOnline: statusOnline ?? this.statusOnline,
      textInput: textInput ?? this.textInput,
      title: title ?? this.title,
      bgSearchInput: bgSearchInput ?? this.bgSearchInput,
      textMessage: textMessage ?? this.textMessage,
      textMessageMuted: textMessageMuted ?? this.textMessageMuted,
      channelColorSwatches: channelColorSwatches ?? this.channelColorSwatches,
      avatarPlaceholderBg: avatarPlaceholderBg ?? this.avatarPlaceholderBg,
      avatarPlaceholderIcon: avatarPlaceholderIcon ?? this.avatarPlaceholderIcon,
      contextMenuCancelBg: contextMenuCancelBg ?? this.contextMenuCancelBg,
      contextMenuCancelPressedBg: contextMenuCancelPressedBg ?? this.contextMenuCancelPressedBg,
      dmHeaderBg: dmHeaderBg ?? this.dmHeaderBg,
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
      userStatusText: userStatusText ?? this.userStatusText,
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
      bannerBgIntInfo: Color.lerp(bannerBgIntInfo, other.bannerBgIntInfo, t)!,
      bannerBgIntWarning: Color.lerp(bannerBgIntWarning, other.bannerBgIntWarning, t)!,
      bannerTextIntInfo: Color.lerp(bannerTextIntInfo, other.bannerTextIntInfo, t)!,
      bgBotBar: Color.lerp(bgBotBar, other.bgBotBar, t)!,
      bgContextMenu: Color.lerp(bgContextMenu, other.bgContextMenu, t)!,
      bgCounterUnread: Color.lerp(bgCounterUnread, other.bgCounterUnread, t)!,
      bgMenuButtonActive: Color.lerp(bgMenuButtonActive, other.bgMenuButtonActive, t)!,
      bgMenuButtonSelected: Color.lerp(bgMenuButtonSelected, other.bgMenuButtonSelected, t)!,
      bgMessageRegular: Color.lerp(bgMessageRegular, other.bgMessageRegular, t)!,
      bgTopBar: Color.lerp(bgTopBar, other.bgTopBar, t)!,
      borderBar: Color.lerp(borderBar, other.borderBar, t)!,
      borderMenuButtonSelected: Color.lerp(borderMenuButtonSelected, other.borderMenuButtonSelected, t)!,
      btnBgAttHighIntInfoActive: Color.lerp(btnBgAttHighIntInfoActive, other.btnBgAttHighIntInfoActive, t)!,
      btnBgAttHighIntInfoNormal: Color.lerp(btnBgAttHighIntInfoNormal, other.btnBgAttHighIntInfoNormal, t)!,
      btnBgAttHighIntWarningActive: Color.lerp(btnBgAttHighIntWarningActive, other.btnBgAttHighIntWarningActive, t)!,
      btnBgAttHighIntWarningNormal: Color.lerp(btnBgAttHighIntWarningNormal, other.btnBgAttHighIntWarningNormal, t)!,
      btnBgAttMediumIntInfoActive: Color.lerp(btnBgAttMediumIntInfoActive, other.btnBgAttMediumIntInfoActive, t)!,
      btnBgAttMediumIntInfoNormal: Color.lerp(btnBgAttMediumIntInfoNormal, other.btnBgAttMediumIntInfoNormal, t)!,
      btnBgAttMediumIntWarningActive: Color.lerp(btnBgAttMediumIntWarningActive, other.btnBgAttMediumIntWarningActive, t)!,
      btnBgAttMediumIntWarningNormal: Color.lerp(btnBgAttMediumIntWarningNormal, other.btnBgAttMediumIntWarningNormal, t)!,
      btnLabelAttHigh: Color.lerp(btnLabelAttHigh, other.btnLabelAttHigh, t)!,
      btnLabelAttHighIntWarning: Color.lerp(btnLabelAttHighIntWarning, other.btnLabelAttHighIntWarning, t)!,
      btnLabelAttLowIntDanger: Color.lerp(btnLabelAttLowIntDanger, other.btnLabelAttLowIntDanger, t)!,
      btnLabelAttLowIntInfo: Color.lerp(btnLabelAttLowIntInfo, other.btnLabelAttLowIntInfo, t)!,
      btnLabelAttMediumIntDanger: Color.lerp(btnLabelAttMediumIntDanger, other.btnLabelAttMediumIntDanger, t)!,
      btnLabelAttMediumIntInfo: Color.lerp(btnLabelAttMediumIntInfo, other.btnLabelAttMediumIntInfo, t)!,
      btnLabelAttMediumIntWarning: Color.lerp(btnLabelAttMediumIntWarning, other.btnLabelAttMediumIntWarning, t)!,
      btnShadowAttMed: Color.lerp(btnShadowAttMed, other.btnShadowAttMed, t)!,
      composeBoxBg: Color.lerp(composeBoxBg, other.composeBoxBg, t)!,
      contextMenuCancelText: Color.lerp(contextMenuCancelText, other.contextMenuCancelText, t)!,
      contextMenuItemBg: Color.lerp(contextMenuItemBg, other.contextMenuItemBg, t)!,
      contextMenuItemBgDanger: Color.lerp(contextMenuItemBgDanger, other.contextMenuItemBgDanger, t)!,
      contextMenuItemIcon: Color.lerp(contextMenuItemIcon, other.contextMenuItemIcon, t)!,
      contextMenuItemIconDanger: Color.lerp(contextMenuItemIconDanger, other.contextMenuItemIconDanger, t)!,
      contextMenuItemLabel: Color.lerp(contextMenuItemLabel, other.contextMenuItemLabel, t)!,
      contextMenuItemMeta: Color.lerp(contextMenuItemMeta, other.contextMenuItemMeta, t)!,
      contextMenuItemText: Color.lerp(contextMenuItemText, other.contextMenuItemText, t)!,
      contextMenuItemTextDanger: Color.lerp(contextMenuItemTextDanger, other.contextMenuItemTextDanger, t)!,
      editorButtonPressedBg: Color.lerp(editorButtonPressedBg, other.editorButtonPressedBg, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      fabBg: Color.lerp(fabBg, other.fabBg, t)!,
      fabBgPressed: Color.lerp(fabBgPressed, other.fabBgPressed, t)!,
      fabLabel: Color.lerp(fabLabel, other.fabLabel, t)!,
      fabLabelPressed: Color.lerp(fabLabelPressed, other.fabLabelPressed, t)!,
      fabShadow: Color.lerp(fabShadow, other.fabShadow, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      iconSelected: Color.lerp(iconSelected, other.iconSelected, t)!,
      labelCounterUnread: Color.lerp(labelCounterUnread, other.labelCounterUnread, t)!,
      labelEdited: Color.lerp(labelEdited, other.labelEdited, t)!,
      labelMenuButton: Color.lerp(labelMenuButton, other.labelMenuButton, t)!,
      labelSearchPrompt: Color.lerp(labelSearchPrompt, other.labelSearchPrompt, t)!,
      labelTime: Color.lerp(labelTime, other.labelTime, t)!,
      link: Color.lerp(link, other.link, t)!,
      listMenuItemBg: Color.lerp(listMenuItemBg, other.listMenuItemBg, t)!,
      listMenuItemIcon: Color.lerp(listMenuItemIcon, other.listMenuItemIcon, t)!,
      listMenuItemText: Color.lerp(listMenuItemText, other.listMenuItemText, t)!,
      mainBackground: Color.lerp(mainBackground, other.mainBackground, t)!,
      neutralButtonBg: Color.lerp(neutralButtonBg, other.neutralButtonBg, t)!,
      neutralButtonLabel: Color.lerp(neutralButtonLabel, other.neutralButtonLabel, t)!,
      radioBorder: Color.lerp(radioBorder, other.radioBorder, t)!,
      radioFillSelected: Color.lerp(radioFillSelected, other.radioFillSelected, t)!,
      statusAway: Color.lerp(statusAway, other.statusAway, t)!,
      statusIdle: Color.lerp(statusIdle, other.statusIdle, t)!,
      statusOnline: Color.lerp(statusOnline, other.statusOnline, t)!,
      textInput: Color.lerp(textInput, other.textInput, t)!,
      title: Color.lerp(title, other.title, t)!,
      bgSearchInput: Color.lerp(bgSearchInput, other.bgSearchInput, t)!,
      textMessage: Color.lerp(textMessage, other.textMessage, t)!,
      textMessageMuted: Color.lerp(textMessageMuted, other.textMessageMuted, t)!,
      channelColorSwatches: ChannelColorSwatches.lerp(channelColorSwatches, other.channelColorSwatches, t),
      avatarPlaceholderBg: Color.lerp(avatarPlaceholderBg, other.avatarPlaceholderBg, t)!,
      avatarPlaceholderIcon: Color.lerp(avatarPlaceholderIcon, other.avatarPlaceholderIcon, t)!,
      contextMenuCancelBg: Color.lerp(contextMenuCancelBg, other.contextMenuCancelBg, t)!,
      contextMenuCancelPressedBg: Color.lerp(contextMenuCancelPressedBg, other.contextMenuCancelPressedBg, t)!,
      dmHeaderBg: Color.lerp(dmHeaderBg, other.dmHeaderBg, t)!,
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
      userStatusText: Color.lerp(userStatusText, other.userStatusText, t)!,
    );
  }
}

// This is taken from:
//   https://github.com/zulip/zulip/blob/b248e2d93/web/src/stream_data.ts#L40
const kDefaultChannelColorSwatchBaseColor = 0xffc2c2c2;

/// The theme-appropriate [ChannelColorSwatch] based on [subscription.color].
///
/// If [subscription] is null, [ChannelColorSwatch] will be based on
/// [kDefaultChannelColorSwatchBaseColor].
///
/// For how this value is cached, see [ChannelColorSwatches.forBaseColor].
// TODO(#188) pick different colors for unsubscribed channels
ChannelColorSwatch colorSwatchFor(BuildContext context, Subscription? subscription) {
  return DesignVariables.of(context)
    .channelColorSwatches.forBaseColor(
      subscription?.color ?? kDefaultChannelColorSwatchBaseColor);
}
