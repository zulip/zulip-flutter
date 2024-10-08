// appbar_theme.dart
import 'package:flutter/material.dart';


import '../../widgets/text.dart';
import '../design_variables.dart'; // Assuming colors are in this file

class ZAppBarTheme {
  ZAppBarTheme._(); // Private constructor to prevent instantiation

  // Light theme for AppBar
  static AppBarTheme lightAppBarTheme(BuildContext context, DesignVariables designVariables) {
    return AppBarTheme(
      backgroundColor: designVariables.bgTopBar,
      actionsIconTheme: IconThemeData(color: designVariables.icon),
      titleTextStyle: TextStyle(
        color: designVariables.title,
        fontSize: 20,
        fontFamily: kDefaultFontFamily, // Assuming this is a constant for font family
      ).merge(weightVariableTextStyle(context, wght: 600)), // Assuming weight styling function
      shape: Border(
        bottom: BorderSide(color: designVariables.borderBar),
      ),
    );
  }

  // Dark theme for AppBar
  static AppBarTheme darkAppBarTheme(BuildContext context,DesignVariables designVariables) {
    return AppBarTheme(
      backgroundColor: designVariables.bgTopBar,
      actionsIconTheme: IconThemeData(color: designVariables.icon),
      titleTextStyle: TextStyle(
        color: designVariables.title,
        fontSize: 20,
        fontFamily: kDefaultFontFamily,
      ).merge(weightVariableTextStyle(context, wght: 600)),
      shape: Border(
        bottom: BorderSide(color: designVariables.borderBar),
      ),
    );
  }
}
