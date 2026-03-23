import 'package:flutter/material.dart';

import '../../../model/content.dart';
import '../../widgets/scrolling.dart';
import '../content.dart';

class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.node});

  final CodeBlockNode node;

  @override
  Widget build(BuildContext context) {
    final styles = ContentTheme.of(context).codeBlockTextStyles;
    return CodeBlockContainer(
      borderColor: Colors.transparent,
      child: Text.rich(
        TextSpan(
          style: styles.plain,
          children: node.spans
              .map(
                (node) =>
                    TextSpan(style: styles.forSpan(node.type), text: node.text),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class CodeBlockContainer extends StatelessWidget {
  const CodeBlockContainer({
    super.key,
    required this.borderColor,
    required this.child,
  });

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ContentTheme.of(context).colorCodeBlockBackground,
        border: Border.all(width: 1, color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollViewWithScrollbar(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(7, 5, 7, 3),
          child: child,
        ),
      ),
    );
  }
}
