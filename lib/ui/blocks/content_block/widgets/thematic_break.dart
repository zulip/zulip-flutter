import 'package:flutter/material.dart';

import '../content.dart';

class ThematicBreak extends StatelessWidget {
  const ThematicBreak({super.key});

  static const htmlHeight = 2.0;
  static const htmlMarginY = 20.0;

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: ContentTheme.of(context).colorThematicBreak,
      thickness: htmlHeight,
      height: 2 * htmlMarginY + htmlHeight,
    );
  }
}
