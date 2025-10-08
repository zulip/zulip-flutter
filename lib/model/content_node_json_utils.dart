import 'content.dart';
import 'katex.dart';

/// Converts any ContentNode to a JSON-serializable Map
Map<String, dynamic> nodeToJson(dynamic node) {
  if (node is TextNode) {
    return {
      'type': 'TextNode',
      'text': node.text,
    };
  } else if (node is LineBreakInlineNode) {
    return {'type': 'LineBreakInlineNode'};
  } else if (node is LineBreakNode) {
    return {'type': 'LineBreakNode'};
  } else if (node is StrongNode) {
    return {
      'type': 'StrongNode',
      'nodes': (node.nodes as List).map(nodeToJson).toList(),
    };
  } else if (node is EmphasisNode) {
    return {
      'type': 'EmphasisNode',
      'nodes': (node.nodes as List).map(nodeToJson).toList(),
    };
  } else if (node is DeletedNode) {
    return {
      'type': 'DeletedNode',
      'nodes': (node.nodes as List).map(nodeToJson).toList(),
    };
  } else if (node is InlineCodeNode) {
    return {
      'type': 'InlineCodeNode',
      'nodes': (node.nodes as List).map(nodeToJson).toList(),
    };
  } else if (node is LinkNode) {
    return {
      'type': 'LinkNode',
      'url': node.url,
      'nodes': (node.nodes as List).map(nodeToJson).toList(),
    };
  } else if (node is UserMentionNode) {
    return {
      'type': 'UserMentionNode',
      'nodes': (node.nodes as List).map(nodeToJson).toList(),
    };
  } else if (node is UnicodeEmojiNode) {
    return {
      'type': 'UnicodeEmojiNode',
      'emojiUnicode': node.emojiUnicode,
    };
  } else if (node is ImageEmojiNode) {
    return {
      'type': 'ImageEmojiNode',
      'src': node.src,
      'alt': node.alt,
    };
  } else if (node is GlobalTimeNode) {
    return {
      'type': 'GlobalTimeNode',
      'datetime': node.datetime.toIso8601String(),
    };
  } else if (node is ParagraphNode) {
    return {
      'type': 'ParagraphNode',
      'wasImplicit': node.wasImplicit,
      'links': node.links,
      'nodes': (node.nodes as List).map(nodeToJson).toList(),
    };
  } else if (node is HeadingNode) {
    return {
      'type': 'HeadingNode',
      'level': _enumToString(node.level),
      'links': node.links,
      'nodes': (node.nodes as List).map(nodeToJson).toList(),
    };
  } else if (node is OrderedListNode) {
    return {
      'type': 'OrderedListNode',
      'start': node.start,
      'items': node.items
          .map((item) => item.map(nodeToJson).toList())
          .toList(),
    };
  } else if (node is UnorderedListNode) {
    return {
      'type': 'UnorderedListNode',
      'items': node.items
          .map((item) => item.map(nodeToJson).toList())
          .toList(),
    };
  } else if (node is QuotationNode) {
    return {
      'type': 'QuotationNode',
      'nodes': (node.nodes as List).map(nodeToJson).toList(),
    };
  } else if (node is CodeBlockNode) {
    return {
      'type': 'CodeBlockNode',
      'spans': node.spans
          .map((span) => {
                'text': span.text,
                'type': _enumToString(span.type),
              })
          .toList(),
    };
  } else if (node is SpoilerNode) {
    return {
      'type': 'SpoilerNode',
      'header': (node.header as List).map(nodeToJson).toList(),
      'content': (node.content as List).map(nodeToJson).toList(),
    };
  } else if (node is ThematicBreakNode) {
    return {'type': 'ThematicBreakNode'};
  } else if (node is ImageNode) {
    return {
      'type': 'ImageNode',
      'srcUrl': node.srcUrl,
      'thumbnailUrl': node.thumbnailUrl,
      'loading': node.loading,
      'originalWidth': node.originalWidth,
      'originalHeight': node.originalHeight,
    };
  } else if (node is ImageNodeList) {
    return {
      'type': 'ImageNodeList',
      'images': node.images.map(nodeToJson).toList(),
    };
  } else if (node is MathInlineNode) {
    return {
      'type': 'MathInlineNode',
      'texSource': node.texSource,
      'nodes': node.nodes?.map(nodeToJson).toList(),
    };
  } else if (node is MathBlockNode) {
    return {
      'type': 'MathBlockNode',
      'texSource': node.texSource,
      'nodes': node.nodes?.map(nodeToJson).toList(),
    };
  } else if (node is KatexSpanNode) {
    return {
      'type': 'KatexSpanNode',
      'text': node.text,
      'styles': _katexStylesToJson(node.styles),
      'nodes': node.nodes?.map(nodeToJson).toList(),
    };
  } else if (node is KatexStrutNode) {
    return {
      'type': 'KatexStrutNode',
      'heightEm': node.heightEm,
      'verticalAlignEm': node.verticalAlignEm,
    };
  } else if (node is KatexVlistNode) {
    return {
      'type': 'KatexVlistNode',
      'rows': node.rows
          .map((row) => {
                'verticalOffsetEm': row.verticalOffsetEm,
                'node': nodeToJson(row.node),
              })
          .toList(),
    };
  } else if (node is KatexVlistRowNode) {
    return {
      'type': 'KatexVlistRowNode',
      'verticalOffsetEm': node.verticalOffsetEm,
      'node': nodeToJson(node.node),
    };
  } else if (node is KatexNegativeMarginNode) {
    return {
      'type': 'KatexNegativeMarginNode',
      'leftOffsetEm': node.leftOffsetEm,
      'nodes': node.nodes.map(nodeToJson).toList(),
    };
  } else if (node is EmbedVideoNode) {
    return {
      'type': 'EmbedVideoNode',
      'hrefUrl': node.hrefUrl,
      'previewImageSrcUrl': node.previewImageSrcUrl,
    };
  } else if (node is InlineVideoNode) {
    return {
      'type': 'InlineVideoNode',
      'srcUrl': node.srcUrl,
    };
  } else if (node is WebsitePreviewNode) {
    return {
      'type': 'WebsitePreviewNode',
      'hrefUrl': node.hrefUrl,
      'imageSrcUrl': node.imageSrcUrl,
      'title': node.title,
      'description': node.description,
    };
  } else if (node is TableNode) {
    return {
      'type': 'TableNode',
      'rows': node.rows
          .map((row) => {
                'isHeader': row.isHeader,
                'cells': row.cells
                    .map((cell) => {
                          'nodes': (cell.nodes as List).map(nodeToJson).toList(),
                          'links': cell.links,
                          'textAlignment': _enumToString(cell.textAlignment),
                        })
                    .toList(),
              })
          .toList(),
    };
  } else if (node is UnimplementedBlockContentNode) {
    return {
      'type': 'UnimplementedBlockContentNode',
      'htmlNode': node.htmlNode.toString(),
    };
  } else if (node is UnimplementedInlineContentNode) {
    return {
      'type': 'UnimplementedInlineContentNode',
      'htmlNode': node.htmlNode.toString(),
    };
  } else {
    return {
      'type': node.runtimeType.toString(),
      'error': 'Unknown node type',
    };
  }
}

/// Helper to convert enums to readable strings
String _enumToString(dynamic enumValue) {
  return enumValue.toString().split('.').last;
}

/// Helper to convert KatexSpanStyles to JSON
Map<String, dynamic>? _katexStylesToJson(KatexSpanStyles? styles) {
  if (styles == null) return null;
  return {
    'fontFamily': styles.fontFamily,
    'fontStyle': styles.fontStyle != null ? _enumToString(styles.fontStyle) : null,
    'fontSizeEm': styles.fontSizeEm,
    'marginRightEm': styles.marginRightEm,
    'marginLeftEm': styles.marginLeftEm,
    'topEm': styles.topEm,
    'widthEm': styles.widthEm,
    'textAlign': styles.textAlign != null ? _enumToString(styles.textAlign) : null,
    'color': styles.color != null
        ? {
            'r': styles.color!.r,
            'g': styles.color!.g,
            'b': styles.color!.b,
            'a': styles.color!.a,
          }
        : null,
    'position': styles.position != null ? _enumToString(styles.position) : null,
  };
}