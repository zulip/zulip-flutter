import 'package:flutter/material.dart';
import 'content_theme.dart';
import 'custom_themes/appbar_theme.dart';
import 'custom_themes/elevated_button_theme.dart';
import 'design_variables.dart';
import 'emoji_reaction.dart';
import 'message_list.dart';
import '../widgets/text.dart';


class ZulipTheme {
  ZulipTheme._();

  static ThemeData lightTheme(BuildContext context) {
    final DesignVariables designVariables = DesignVariables.light();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: designVariables.mainBackground,
      typography: zulipTypography(context),
      extensions: [
        ContentTheme.light(context),
        designVariables,
        EmojiReactionTheme.light(), // Adding EmojiReactionTheme
        MessageListTheme.light(),   // Adding MessageListTheme
      ],
      appBarTheme: ZAppBarTheme.lightAppBarTheme(context, designVariables),
      tooltipTheme: const TooltipThemeData(preferBelow: false),
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    final DesignVariables designVariables = DesignVariables.dark();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: designVariables.mainBackground,
      typography: zulipTypography(context),
      extensions: [
        ContentTheme.dark(context),
        designVariables,
        EmojiReactionTheme.dark(), // Adding EmojiReactionTheme
        MessageListTheme.dark(),   // Adding MessageListTheme
      ],
      appBarTheme: ZAppBarTheme.darkAppBarTheme(context, designVariables),
      tooltipTheme: const TooltipThemeData(preferBelow: false),
      elevatedButtonTheme: ZButtonTheme.darkElevatedButtonTheme(designVariables),

    );
  }
}



