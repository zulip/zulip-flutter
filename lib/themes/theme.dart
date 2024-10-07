import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../widgets/content.dart';
import 'content_theme.dart';
import 'design_variables.dart';
import 'emoji_reaction.dart';
import 'message_list.dart';
import '../widgets/channel_colors.dart';
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
      appBarTheme: AppBarTheme(
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
      ),
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
      appBarTheme: AppBarTheme(
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
      ),
      tooltipTheme: const TooltipThemeData(preferBelow: false),
    );
  }
}



