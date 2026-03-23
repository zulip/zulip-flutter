import 'package:flutter/material.dart';

import '../../../../model/content.dart';
import 'code_block.dart';
import 'heading.dart';
import 'helpers.dart';
import 'list_node_widget.dart';
import 'math_block.dart';
import 'message_embed_video.dart';
import 'message_image_preview.dart';
import 'message_image_preview_list.dart';
import 'message_inline_video.dart';
import 'message_table.dart';
import 'paragraph.dart';
import 'quotation.dart';
import 'spoiler.dart';
import 'thematic_break.dart';
import 'website_preview.dart';

/// A list of DOM nodes to display in block layout.
class BlockContentList extends StatelessWidget {
  const BlockContentList({super.key, required this.nodes});

  final List<BlockContentNode> nodes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...nodes.map((node) {
          return switch (node) {
            LineBreakNode() =>
              // This goes in a Column.  So to get the effect of a newline,
              // just use an empty Text.
              const Text(''),
            ThematicBreakNode() => const ThematicBreak(),
            ParagraphNode() => Paragraph(node: node),
            HeadingNode() => Heading(node: node),
            QuotationNode() => Quotation(node: node),
            ListNode() => ListNodeWidget(node: node),
            SpoilerNode() => Spoiler(node: node),
            CodeBlockNode() => CodeBlock(node: node),
            MathBlockNode() => MathBlock(node: node),
            ImagePreviewNodeList() => MessageImagePreviewList(node: node),
            ImagePreviewNode() => () {
              assert(
                false,
                "[ImagePreviewNode] not allowed in [BlockContentList]. "
                "It should be wrapped in [ImagePreviewNodeList].",
              );
              return MessageImagePreview(node: node);
            }(),
            InlineVideoNode() => MessageInlineVideo(node: node),
            EmbedVideoNode() => MessageEmbedVideo(node: node),
            TableNode() => MessageTable(node: node),
            TableRowNode() => () {
              assert(
                false,
                "[TableRowNode] not allowed in [BlockContentList]. "
                "It should be wrapped in [TableNode].",
              );
              return const SizedBox.shrink();
            }(),
            TableCellNode() => () {
              assert(
                false,
                "[TableCellNode] not allowed in [BlockContentList]. "
                "It should be wrapped in [TableRowNode].",
              );
              return const SizedBox.shrink();
            }(),
            WebsitePreviewNode() => WebsitePreview(node: node),
            UnimplementedBlockContentNode() => Text.rich(
              contentErrorUnimplemented(node, context: context),
            ),
          };
        }),
      ],
    );
  }
}
