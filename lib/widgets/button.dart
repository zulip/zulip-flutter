import 'package:flutter/material.dart';

import 'color.dart';
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
    required this.label,
    required this.onPressed,
  });

  final ZulipWebUiKitButtonAttention attention;
  final ZulipWebUiKitButtonIntent intent;
  final String label;
  final VoidCallback onPressed;

  WidgetStateColor _backgroundColor(DesignVariables designVariables) {
    switch ((attention, intent)) {
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
      case (ZulipWebUiKitButtonAttention.medium, ZulipWebUiKitButtonIntent.info):
        return designVariables.btnLabelAttMediumIntInfo;
      case (ZulipWebUiKitButtonAttention.high, ZulipWebUiKitButtonIntent.info):
        return designVariables.btnLabelAttHigh;
    }
  }

  TextStyle _labelStyle(BuildContext context, {required TextScaler textScaler}) {
    final designVariables = DesignVariables.of(context);
    // Values chosen from the Figma frame for zulip-flutter's compose box:
    //   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3988-38201&m=dev
    // Commented values come from the Figma page "Zulip Web UI kit":
    //   https://www.figma.com/design/msWyAJ8cnMHgOMPxi7BUvA/Zulip-Web-UI-kit?node-id=1-8&p=f&m=dev
    // Discussion:
    //   https://github.com/zulip/zulip-flutter/pull/1432#discussion_r2023880851
    return TextStyle(
      color: _labelColor(designVariables),
      fontSize: 17, // 16
      height: 1.20, // 1.25
      letterSpacing: proportionalLetterSpacing(context, textScaler: textScaler,
        0.006,
        baseFontSize: 17), // 16
    ).merge(weightVariableTextStyle(context,
        wght: 600)); // 500
  }

  BorderSide _borderSide(DesignVariables designVariables) {
    switch (attention) {
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

    return AnimatedScaleOnTap(
      scaleEnd: 0.96,
      duration: Duration(milliseconds: 100),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4 - densityVerticalAdjustment),
          foregroundColor: _labelColor(designVariables),
          shape: RoundedRectangleBorder(
            side: _borderSide(designVariables),
            borderRadius: BorderRadius.circular(4)),
          splashFactory: NoSplash.splashFactory,

          // These three arguments make the button 28px tall vertically,
          // but with vertical padding to make the touch target 44px tall:
          //   https://github.com/zulip/zulip-flutter/pull/1432#discussion_r2023907300
          visualDensity: visualDensity,
          tapTargetSize: MaterialTapTargetSize.padded,
          minimumSize: Size(kMinInteractiveDimension, 28 - densityVerticalAdjustment),
        ).copyWith(backgroundColor: _backgroundColor(designVariables)),
        onPressed: onPressed,
        child: ConstrainedBox(
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
}

enum ZulipWebUiKitButtonIntent {
  // neutral,
  // warning,
  // danger,
  info,
  // success,
  // brand,
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

/// The rounded-rectangle shape and 1-pixel spacing for a run of [MenuButton]s.
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

/// The "menu button" component in Figma.
///
/// Must have a [MenuButtonsShape] ancestor.
///
/// See Figma:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=6070-60681&m=dev
class MenuButton extends StatelessWidget {
  const MenuButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.beforeIcon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  /// An element to go before [icon], or in its place if it's null.
  ///
  /// E.g. a switch:
  ///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=6070-60682&m=dev
  final Widget? beforeIcon;

  static double itemSpacing = 16;

  static bool _debugCheckShapeAncestor(BuildContext context) {
    final ancestor = context.findAncestorWidgetOfExactType<MenuButtonsShape>();
    assert(() {
      if (ancestor != null) return true;
      throw FlutterError.fromParts([
        ErrorSummary('No MenuButtonsShape ancestor found.'),
        ErrorDescription('MenuButton widgets require a MenuButtonsShape ancestor.'),
      ]);
    }());
    return true;
  }

  @override
  Widget build(BuildContext context) {
    _debugCheckShapeAncestor(context);

    final designVariables = DesignVariables.of(context);

    // (see `trailingIcon`)
    assert(Theme.of(context).visualDensity == VisualDensity.standard);

    return MenuItemButton(
      trailingIcon: (icon != null || beforeIcon != null)
        ? Padding(
            // This Material widget gives us 12px padding before the icon --
            // or more or less, depending on Theme.of(context).visualDensity,
            // hence the `assert` above.
            padding: EdgeInsetsDirectional.only(start: itemSpacing - 12),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: itemSpacing,
              children: [
                if (beforeIcon != null) beforeIcon!,
                if (icon != null) Icon(icon, color: designVariables.contextMenuItemText),
              ]))
        : null,
      style: MenuItemButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        foregroundColor: designVariables.contextMenuItemText,
        splashFactory: NoSplash.splashFactory,
      ).copyWith(backgroundColor: WidgetStateColor.resolveWith((states) =>
          designVariables.contextMenuItemBg.withFadedAlpha(
            states.contains(WidgetState.pressed) ? 0.20 : 0.12))),
      onPressed: onPressed,
      child: Text(label,
        style: const TextStyle(fontSize: 20, height: 24 / 20)
          .merge(weightVariableTextStyle(context, wght: 600))));
  }
}
