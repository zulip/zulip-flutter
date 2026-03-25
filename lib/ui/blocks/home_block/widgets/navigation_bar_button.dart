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
        child: SizedBox(
          width: 48,
          height: 48,
          child: InkWell(
            borderRadius: BorderRadius.zero,
            splashFactory: NoSplash.splashFactory,
            highlightColor: designVariables.navigationButtonBg,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(3, 6, 3, 3),
              child: Column(
                spacing: 3,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 24, color: color),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                    textScaler: MediaQuery.textScalerOf(
                      context,
                    ).clamp(maxScaleFactor: 1.5),
                  ),
                ],
              ),
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
