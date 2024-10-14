import '../widgets/theme.dart';
import 'package:flutter/material.dart';

class ZButtonTheme {
  ZButtonTheme._();

  // Dark theme for ElevatedButton
  static ElevatedButtonThemeData darkElevatedButtonTheme(DesignVariables designVariables) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: designVariables.title,
        backgroundColor: designVariables.bgTopBar,
        elevation: 4.0,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
    );
  }
}
