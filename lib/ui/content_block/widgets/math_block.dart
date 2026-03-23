import 'package:flutter/material.dart';

import '../../../model/content.dart';
import '../../widgets/katex.dart';
import '../../widgets/scrolling.dart';
import '../content.dart';
import 'code_block.dart';

class MathBlock extends StatelessWidget {
  const MathBlock({super.key, required this.node});

  final MathBlockNode node;

  @override
  Widget build(BuildContext context) {
    final contentTheme = ContentTheme.of(context);

    final nodes = node.nodes;
    if (nodes == null) {
      return CodeBlockContainer(
        borderColor: contentTheme.colorMathBlockBorder,
        child: Text.rich(
          TextSpan(
            style: contentTheme.codeBlockTextStyles.plain,
            children: [TextSpan(text: node.texSource)],
          ),
        ),
      );
    }

    return Center(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollViewWithScrollbar(
          scrollDirection: Axis.horizontal,
          child: KatexWidget(
            textStyle: ContentTheme.of(context).textStylePlainParagraph,
            nodes: nodes,
          ),
        ),
      ),
    );
  }
}
