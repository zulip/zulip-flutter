import 'package:flutter/material.dart';

import '../../../../model/content.dart';
import 'block_content_list.dart';

class Quotation extends StatelessWidget {
  const Quotation({super.key, required this.node});

  final QuotationNode node;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 10),
      child: Container(
        padding: const EdgeInsetsDirectional.only(start: 5),
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(
              width: 5,
              // Web has the same color in light and dark mode.
              color: const HSLColor.fromAHSL(1, 0, 0, 0.87).toColor(),
            ),
          ),
        ),
        child: BlockContentList(nodes: node.nodes),
      ),
    );
  }
}
