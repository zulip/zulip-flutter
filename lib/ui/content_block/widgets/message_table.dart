import 'package:flutter/material.dart';

import '../../../model/content.dart';
import '../../values/text.dart';
import '../../widgets/scrolling.dart';
import '../content.dart';
import 'helpers.dart';

class MessageTable extends StatelessWidget {
  const MessageTable({super.key, required this.node});

  final TableNode node;

  @override
  Widget build(BuildContext context) {
    final contentTheme = ContentTheme.of(context);
    return SingleChildScrollViewWithScrollbar(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Table(
          border: TableBorder.all(
            width: 1,
            style: BorderStyle.solid,
            color: contentTheme.colorTableCellBorder,
          ),
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: List.unmodifiable(
            node.rows.map(
              (row) => TableRow(
                decoration: row.isHeader
                    ? BoxDecoration(
                        color: contentTheme.colorTableHeaderBackground,
                      )
                    : null,
                children: List.unmodifiable(
                  row.cells.map(
                    (cell) =>
                        MessageTableCell(node: cell, isHeader: row.isHeader),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MessageTableCell extends StatelessWidget {
  const MessageTableCell({
    super.key,
    required this.node,
    required this.isHeader,
  });

  final TableCellNode node;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final textAlign = switch (node.textAlignment) {
      TableColumnTextAlignment.left => TextAlign.left,
      TableColumnTextAlignment.center => TextAlign.center,
      TableColumnTextAlignment.right => TextAlign.right,
      // The web client sets `text-align: left;` for the header cells,
      // overriding the default browser alignment (which is `center` for header
      // and `start` for body). By default, the [Table] widget uses `start` for
      // text alignment, a saner choice that supports RTL text. So, defer to that.
      // See discussion:
      //  https://github.com/zulip/zulip-flutter/pull/1031#discussion_r1831950371
      TableColumnTextAlignment.defaults => null,
    };
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        // Web has 4px padding and 1px border on all sides.
        // In web, the 1px border grows each cell by 0.5px in all directions.
        // Our border doesn't affect the layout, it's just painted on,
        // so we add 0.5px on all sides to match web.
        // Ref: https://github.com/flutter/flutter/issues/78691
        padding: const EdgeInsets.all(4 + 0.5),
        child: node.nodes.isEmpty
            ? const SizedBox.shrink()
            : contentBuildBlockInlineContainer(
                node: node,
                textAlign: textAlign,
                style: !isHeader
                    ? DefaultTextStyle.of(context).style
                    : DefaultTextStyle.of(context).style.merge(
                        weightVariableTextStyle(context, wght: 700),
                      ),
              ),
      ),
    );
  }
}
