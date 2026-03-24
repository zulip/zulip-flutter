import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../values/theme.dart';
import '../../../widgets/button.dart';
import '../home.dart';

class NavigationBarButton extends StatelessWidget {
  const NavigationBarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final color = selected
        ? designVariables.iconSelected
        : designVariables.icon;

    Widget result = AnimatedScaleOnPress(
      scaleEnd: 0.875,
      duration: const Duration(milliseconds: 100),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          // TODO(#417): Disable splash effects for all buttons globally.
          splashFactory: NoSplash.splashFactory,
          highlightColor: designVariables.navigationButtonBg,
          onTap: onPressed,
          child: Padding(
            // (Added 3px horizontal padding not present in Figma, to make the
            // text wrap before getting too close to the button's edge, which is
            // visible on tap-down.)
            padding: const EdgeInsets.fromLTRB(3, 6, 3, 3),
            child: Column(
              spacing: 3,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: color),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      height: 12 / 12,
                    ),
                    textAlign: TextAlign.center,
                    textScaler: MediaQuery.textScalerOf(
                      context,
                    ).clamp(maxScaleFactor: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    result = MergeSemantics(
      child: Semantics(
        role: SemanticsRole.tab,
        controlsNodes: {
          HomePage.contentSemanticsIdentifier,
          HomePage.titleSemanticsIdentifier,
        },
        selected: selected,
        onTap: onPressed,
        child: result,
      ),
    );

    return result;
  }
}
