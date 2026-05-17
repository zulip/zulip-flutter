import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MathWidget extends StatelessWidget {
  const MathWidget({
    super.key,
    required this.texSource,
    required this.displayMode,
    this.ambientTextStyle,
  });

  final String texSource;
  final bool displayMode;
  final TextStyle? ambientTextStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle = ambientTextStyle ??
        DefaultTextStyle.of(context).style;

    return Math.tex(
      texSource,
      mathStyle: MathStyle.display,
      textStyle: effectiveTextStyle.copyWith(
        fontSize: effectiveTextStyle.fontSize! * 1.21,
      ),
      onErrorFallback: (error) => Text(
        texSource,
        style: effectiveTextStyle.copyWith(
          color: Colors.grey,
        ),
        maxLines: displayMode ? null : 1,
        overflow: displayMode ? null : TextOverflow.ellipsis,
      ),
    );
  }
}
