import 'package:flutter/material.dart';

import 'color.dart';
import 'icons.dart';
import 'text.dart';
import 'theme.dart';

/// The "Button" component from Zulip Web UI kit,
/// plus outer vertical padding to make the touch target 44px tall.
///
/// The Figma uses this for the "Cancel" and "Save" buttons in the compose box
/// for editing an already-sent message.
///
/// See Figma:
///   * Component: https://www.figma.com/design/msWyAJ8cnMHgOMPxi7BUvA/Zulip-Web-UI-kit?node-id=1-2780&t=Wia0D0i1I0GXdD9z-0
///   * Edit-message compose box: https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3988-38201&m=dev
class ZulipWebUiKitButton extends StatelessWidget {
  const ZulipWebUiKitButton({
    super.key,
    this.attention = ZulipWebUiKitButtonAttention.medium,
    this.intent = ZulipWebUiKitButtonIntent.info,
    this.size = ZulipWebUiKitButtonSize.normal,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  final ZulipWebUiKitButtonAttention attention;
  final ZulipWebUiKitButtonIntent intent;
  final ZulipWebUiKitButtonSize size;
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  WidgetStateColor _backgroundColor(DesignVariables designVariables) {
    switch ((attention, intent)) {
      case (ZulipWebUiKitButtonAttention.minimal, ZulipWebUiKitButtonIntent.neutral):
        return WidgetStateColor.fromMap({
          WidgetState.pressed: designVariables.neutralButtonBg.withFadedAlpha(0.3),
          ~WidgetState.pressed: designVariables.neutralButtonBg.withAlpha(0),
        });
      case (ZulipWebUiKitButtonAttention.medium, ZulipWebUiKitButtonIntent.neutral):
      case (ZulipWebUiKitButtonAttention.high, ZulipWebUiKitButtonIntent.neutral):
      case (ZulipWebUiKitButtonAttention.minimal, ZulipWebUiKitButtonIntent.info):
        throw UnimplementedError();
      case (ZulipWebUiKitButtonAttention.medium, ZulipWebUiKitButtonIntent.info):
        return WidgetStateColor.fromMap({
          WidgetState.pressed: designVariables.btnBgAttMediumIntInfoActive,
          ~WidgetState.pressed: designVariables.btnBgAttMediumIntInfoNormal,
        });
      case (ZulipWebUiKitButtonAttention.high, ZulipWebUiKitButtonIntent.info):
        return WidgetStateColor.fromMap({
          WidgetState.pressed: designVariables.btnBgAttHighIntInfoActive,
          ~WidgetState.pressed: designVariables.btnBgAttHighIntInfoNormal,
        });
    }
  }

  Color _labelColor(DesignVariables designVariables) {
    switch ((attention, intent)) {
      case (ZulipWebUiKitButtonAttention.minimal, ZulipWebUiKitButtonIntent.neutral):
        // TODO nit: don't fade in pressed state
        return designVariables.neutralButtonLabel.withFadedAlpha(0.85);
      case (ZulipWebUiKitButtonAttention.medium, ZulipWebUiKitButtonIntent.neutral):
      case (ZulipWebUiKitButtonAttention.high, ZulipWebUiKitButtonIntent.neutral):
      case (ZulipWebUiKitButtonAttention.minimal, ZulipWebUiKitButtonIntent.info):
        throw UnimplementedError();
      case (ZulipWebUiKitButtonAttention.medium, ZulipWebUiKitButtonIntent.info):
        return designVariables.btnLabelAttMediumIntInfo;
      case (ZulipWebUiKitButtonAttention.high, ZulipWebUiKitButtonIntent.info):
        return designVariables.btnLabelAttHigh;
    }
  }

  TextStyle _labelStyle(BuildContext context, {required TextScaler textScaler}) {
    final designVariables = DesignVariables.of(context);
    // Normal-size values chosen from the Figma frame for zulip-flutter's
    // compose box:
    //   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3988-38201&m=dev
    // Commented values come from the Figma page "Zulip Web UI kit":
    //   https://www.figma.com/design/msWyAJ8cnMHgOMPxi7BUvA/Zulip-Web-UI-kit?node-id=1-8&p=f&m=dev
    // Discussion:
    //   https://github.com/zulip/zulip-flutter/pull/1432#discussion_r2023880851
    return TextStyle(
      color: _labelColor(designVariables),
      fontSize: _forSize(16, 17 /* 16 */),
      height: _forSize(1, 1.20 /* 1.25 */),
      letterSpacing: _forSize(
        0,
        proportionalLetterSpacing(context, textScaler: textScaler,
          0.006,
          baseFontSize: 17 /* 16 */),
      ),
    ).merge(weightVariableTextStyle(context,
        wght: 600)); // 500
  }

  BorderSide _borderSide(DesignVariables designVariables) {
    switch (attention) {
      case ZulipWebUiKitButtonAttention.minimal:
        return BorderSide.none;
      case ZulipWebUiKitButtonAttention.medium:
        // TODO inner shadow effect like `box-shadow: inset`, following Figma;
        //   needs Flutter support for something like that:
        //     https://github.com/flutter/flutter/issues/18636
        //     https://github.com/flutter/flutter/issues/52999
        //   For now, we just use a solid-stroke border with half the opacity
        //   and half the width.
        return BorderSide(
          color: designVariables.btnShadowAttMed.withFadedAlpha(0.5),
          width: 0.5);
      case ZulipWebUiKitButtonAttention.high:
        return BorderSide.none;
    }
  }

  T _forSize<T>(T small, T normal) =>
    switch (size) {
      ZulipWebUiKitButtonSize.small => small,
      ZulipWebUiKitButtonSize.normal => normal,
    };

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    // With [MaterialTapTargetSize.padded],
    // make [TextButton] set 44 instead of 48 for the touch-target height.
    final visualDensity = VisualDensity(vertical: -1);
    // A value that [TextButton] adds to some of its layout parameters;
    // we can cancel out those adjustments by subtracting it.
    final densityVerticalAdjustment = visualDensity.baseSizeAdjustment.dy;

    // An upper limit when the text-size setting is large
    // - helps prioritize more important content (like message content); #1023
    // - prevents the vertical padding added by [MaterialTapTargetSize.padded]
    //   from shrinking to zero as the button grows to accommodate a larger label
    final textScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5);

    final buttonHeight = _forSize(24, 28);

    final labelColor = _labelColor(designVariables);

    return AnimatedScaleOnTap(
      scaleEnd: 0.96,
      duration: Duration(milliseconds: 100),
      child: TextButton.icon(
        // TODO the gap between the icon and label should be 6px, not 8px
        icon: icon != null ? Icon(icon) : null,
        style: TextButton.styleFrom(
          iconSize: 16,
          iconColor: labelColor,
          padding: EdgeInsets.symmetric(
            horizontal: _forSize(6, 10),
            vertical: 4 - densityVerticalAdjustment,
          ),
          foregroundColor: labelColor,
          shape: RoundedRectangleBorder(
            side: _borderSide(designVariables),
            borderRadius: BorderRadius.circular(_forSize(6, 4))),
          splashFactory: NoSplash.splashFactory,

          // These three arguments make the button `buttonHeight` tall,
          // but with vertical padding to make the touch target 44px tall:
          //   https://github.com/zulip/zulip-flutter/pull/1432#discussion_r2023907300
          visualDensity: visualDensity,
          tapTargetSize: MaterialTapTargetSize.padded,
          minimumSize: Size(
            kMinInteractiveDimension,
            buttonHeight - densityVerticalAdjustment,
          ),
        ).copyWith(backgroundColor: _backgroundColor(designVariables)),
        onPressed: onPressed,
        label: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 240),
          child: Text(label,
            textScaler: textScaler,
            maxLines: 1,
            style: _labelStyle(context, textScaler: textScaler),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis))));
  }
}

enum ZulipWebUiKitButtonAttention {
  high,
  medium,
  // low,

  /// An ad hoc value for the "Reveal message" button
  /// on a message from a muted sender:
  ///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=6092-50786&m=dev
  minimal,
}

enum ZulipWebUiKitButtonIntent {
  neutral,
  // warning,
  // danger,
  info,
  // success,
  // brand,
}

enum ZulipWebUiKitButtonSize {
  /// A smaller size than the one in the Zulip Web UI Kit.
  ///
  /// This was ad hoc for mobile, for the "Reveal message" button
  /// on a message from a muted sender:
  ///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=6092-50786&m=dev
  small,

  normal,
}

/// Apply [Transform.scale] to the child widget when tapped, and reset its scale
/// when released, while animating the transitions.
class AnimatedScaleOnTap extends StatefulWidget {
  const AnimatedScaleOnTap({
    super.key,
    required this.scaleEnd,
    required this.duration,
    required this.child,
  });

  /// The terminal scale to animate to.
  final double scaleEnd;

  /// The duration over which to animate the scale change.
  final Duration duration;

  final Widget child;

  @override
  State<AnimatedScaleOnTap> createState() => _AnimatedScaleOnTapState();
}

class _AnimatedScaleOnTapState extends State<AnimatedScaleOnTap> {
  double _scale = 1;

  void _changeScale(double scale) {
    setState(() {
      _scale = scale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) =>  _changeScale(widget.scaleEnd),
      onTapUp: (_) =>    _changeScale(1),
      onTapCancel: () => _changeScale(1),
      child: AnimatedScale(
        scale: _scale,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child));
  }
}

/// The rounded-rectangle shape and 1-pixel spacing for a run of [ZulipMenuItemButton]s.
class MenuButtonsShape extends StatelessWidget {
  const MenuButtonsShape({
    super.key,
    required this.buttons,
  });

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Column(spacing: 1,
        children: buttons));
  }
}

/// The "menu button" or "list button" component in Figma.
///
/// Use [ZulipMenuItemButtonStyle] to choose between components.
///
/// Must have a [MenuButtonsShape] ancestor.
///
/// See Figma:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=6070-60681&m=dev
class ZulipMenuItemButton extends StatelessWidget {
  const ZulipMenuItemButton({
    super.key,
    this.style = ZulipMenuItemButtonStyle.menu,
    required this.label,
    this.subLabel,
    required this.onPressed,
    this.icon,
    this.toggle,
  });

  final ZulipMenuItemButtonStyle style;
  final String label;
  final TextSpan? subLabel;
  final VoidCallback onPressed;
  final IconData? icon;

  /// A [Toggle] to go before [icon], or in its place if it's null.
  ///
  /// See Figma:
  ///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=6070-60682&m=dev
  // TODO(design) Is the toggle option meant only for
  //   [ZulipMenuItemButtonStyle.menu]?
  final Widget? toggle;

  double get itemSpacingAndEndPadding => switch (style) {
    ZulipMenuItemButtonStyle.menu => 16,
    ZulipMenuItemButtonStyle.list => 12,
  };

  static bool _debugCheckShapeAncestor(BuildContext context) {
    final ancestor = context.findAncestorWidgetOfExactType<MenuButtonsShape>();
    assert(() {
      if (ancestor != null) return true;
      throw FlutterError.fromParts([
        ErrorSummary('No MenuButtonsShape ancestor found.'),
        ErrorDescription('ZulipMenuItemButton widgets require a MenuButtonsShape ancestor.'),
      ]);
    }());
    return true;
  }

  WidgetStateColor _backgroundColor(DesignVariables designVariables) {
    switch (style) {
      case ZulipMenuItemButtonStyle.menu:
        return WidgetStateColor.fromMap({
          WidgetState.pressed: designVariables.contextMenuItemBg.withFadedAlpha(0.20),
          ~WidgetState.pressed: designVariables.contextMenuItemBg.withFadedAlpha(0.12),
        });
      case ZulipMenuItemButtonStyle.list:
        return WidgetStateColor.fromMap({
          WidgetState.pressed: designVariables.listMenuItemBg.withFadedAlpha(0.7),
          ~WidgetState.pressed: designVariables.listMenuItemBg.withFadedAlpha(0.35),
        });
    }
  }

  Color _labelColor(DesignVariables designVariables) {
    return switch (style) {
      ZulipMenuItemButtonStyle.menu => designVariables.contextMenuItemText,
      ZulipMenuItemButtonStyle.list => designVariables.listMenuItemText,
    };
  }

  double _labelWght() {
    return switch (style) {
      ZulipMenuItemButtonStyle.menu => 600,
      ZulipMenuItemButtonStyle.list => 500,
    };
  }

  Color _iconColor(DesignVariables designVariables) {
    return switch (style) {
      ZulipMenuItemButtonStyle.menu => designVariables.contextMenuItemIcon,
      ZulipMenuItemButtonStyle.list => designVariables.listMenuItemIcon,
    };
  }

  @override
  Widget build(BuildContext context) {
    _debugCheckShapeAncestor(context);

    final designVariables = DesignVariables.of(context);

    // (see `trailingIcon`)
    assert(Theme.of(context).visualDensity == VisualDensity.standard);

    return MenuItemButton(
      trailingIcon: (icon != null || toggle != null)
        ? Padding(
            // This Material widget gives us 12px padding before the icon --
            // or more or less, depending on Theme.of(context).visualDensity,
            // hence the `assert` above.
            padding: EdgeInsetsDirectional.only(start: itemSpacingAndEndPadding - 12),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: itemSpacingAndEndPadding,
              children: [
                if (toggle != null) toggle!,
                if (icon != null) Icon(icon!, color: _iconColor(designVariables)),
              ]))
        : null,
      style: MenuItemButton.styleFrom(
        minimumSize: Size.fromHeight(48),
        padding: EdgeInsetsDirectional.only(start: 16, end: itemSpacingAndEndPadding),
        foregroundColor: _labelColor(designVariables),
        splashFactory: NoSplash.splashFactory,
      ).copyWith(backgroundColor: _backgroundColor(designVariables)),
      overflowAxis: Axis.vertical,
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: localizedTextBaseline(context),
          children: [
            Flexible(child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, height: 24 / 20)
                .merge(weightVariableTextStyle(context, wght: _labelWght())))),
            if (subLabel != null)
              Flexible(child: Text.rich(subLabel!,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  height: 16 / 16,
                  color: _labelColor(designVariables).withFadedAlpha(0.70),
                ).merge(weightVariableTextStyle(context, wght: _labelWght())))),
          ],
        )));
  }
}

/// The style of a [ZulipMenuItemButton].
enum ZulipMenuItemButtonStyle {
  /// The purple "menu button" component in Figma, with 16px end padding.
  ///
  /// See Figma:
  ///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3302-20443&m=dev
  menu,

  /// The gray "list button" component in Figma, with 12px end padding.
  ///
  /// See Figma:
  ///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=5000-52868&m=dev
  list,
}

/// The "toggle" component in Figma.
///
/// See Figma:
///    https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=6070-60682&m=dev
class Toggle extends StatelessWidget {
  const Toggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // Figma has this (blue/500) in both light and dark mode.
    // TODO(#831)
    final activeColor = Color(0xff4370f0);

    // Figma has this (grey/400) in both light and dark mode.
    // TODO(#831)
    final inactiveColor = Color(0xff9194a3);

    // TODO(#1636):
    //   All of these just need _SwitchConfig to be exposed,
    //   and there's an upstream issue for that:
    //     https://github.com/flutter/flutter/issues/131478
    //
    //   - active thumb radius should be 10px, not 12px
    //     (_SwitchConfig.thumbRadiusWithIcon)
    //   - inactive thumb radius should be 7px, not 8px
    //     (_SwitchConfig.inactiveThumbRadius)
    //   - track dimensions before trackOutlineWidth should be 24px by 44px,
    //     not 32px by 52px (_SwitchConfig.trackHeight and trackWidth).

    return Switch(
      value: value,
      onChanged: onChanged,
      padding: EdgeInsets.zero,
      splashRadius: 0,
      thumbIcon: WidgetStateProperty<Icon?>.fromMap({
        WidgetState.selected: Icon(ZulipIcons.check, size: 16, color: activeColor),
        ~WidgetState.selected: null,
      }),

      // Figma has white for "on" and "off" in both light and dark mode.
      thumbColor: WidgetStatePropertyAll(Colors.white),

      activeTrackColor: activeColor,
      inactiveTrackColor: inactiveColor,
      trackOutlineColor: WidgetStateColor.fromMap({
        WidgetState.selected: activeColor,
        ~WidgetState.selected: inactiveColor,
      }),
      trackOutlineWidth: WidgetStateProperty<double>.fromMap({
        // The outline is effectively painted with strokeAlignCenter:
        //   https://api.flutter.dev/flutter/painting/BorderSide/strokeAlignCenter-constant.html
        WidgetState.selected: 2 * 2,
        ~WidgetState.selected: 1 * 2,
      }),
      overlayColor: WidgetStatePropertyAll(Colors.transparent),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
