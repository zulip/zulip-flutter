import 'package:flutter/material.dart';

import '../../../../model/content.dart';
import '../../../values/text.dart';
import 'block_content_list.dart';

class ListNodeWidget extends StatelessWidget {
  const ListNodeWidget({super.key, required this.node});

  final ListNode node;

  @override
  Widget build(BuildContext context) {
    // TODO(#162): p+ul and p+ol interactions
    final items = List.generate(node.items.length, (index) {
      final item = node.items[index];
      String marker;
      switch (node) {
        // TODO(#161): different unordered marker styles at different levels of nesting
        //   see:
        //     https://html.spec.whatwg.org/multipage/rendering.html#lists
        //     https://www.w3.org/TR/css-counter-styles-3/#simple-symbolic
        // TODO proper alignment of unordered marker; should be "• ", one space,
        //   but that comes out too close to item; not sure what's fixing that
        //   in a browser
        case UnorderedListNode():
          marker = "•   ";
          break;
        case OrderedListNode(:final start):
          marker = "${start + index}. ";
          break;
      }
      return TableRow(
        children: [
          Align(alignment: AlignmentDirectional.topEnd, child: Text(marker)),
          BlockContentList(nodes: item),
        ],
      );
    });

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 5),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
        textBaseline: localizedTextBaseline(context),
        columnWidths: const <int, TableColumnWidth>{
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
        },
        children: items,
      ),
    );
  }
}
