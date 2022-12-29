import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';

@immutable
class ContentNode {
  const ContentNode({this.debugHtmlNode});

  final dom.Node? debugHtmlNode;

  String get debugHtmlText {
    final node = debugHtmlNode;
    if (node == null) return "(elided)";
    if (node is dom.Element) return node.outerHtml;
    if (node is dom.Text) return "(text «${node.text}»)";
    return "(node of type ${node.nodeType})";
  }
}

mixin UnimplementedNode on ContentNode {
  dom.Node get htmlNode;

  @override
  dom.Node get debugHtmlNode => htmlNode;
}

class ZulipContent extends ContentNode {
  const ZulipContent({super.debugHtmlNode, required this.nodes});

  final List<BlockContentNode> nodes;
}

abstract class BlockContentNode extends ContentNode {
  const BlockContentNode({super.debugHtmlNode});
}

class UnimplementedBlockContentNode extends BlockContentNode
    with UnimplementedNode {
  const UnimplementedBlockContentNode({required this.htmlNode});

  @override
  final dom.Node htmlNode;
}

// A `br` element.
class LineBreakNode extends BlockContentNode {
  const LineBreakNode({super.debugHtmlNode});
}

// A `p` element, or a place where the DOM tree logically wanted one.
//
// We synthesize these in the absence of an actual `p` element in cases where
// there's inline content (like [dom.Text] nodes, links, or spans) in a context
// where block content can also appear (like inside a `li`.)  These are marked
// with [wasImplicit].
//
// See also [parseImplicitParagraphBlockContentList].
class ParagraphNode extends BlockContentNode {
  const ParagraphNode(
      {super.debugHtmlNode, this.wasImplicit = false, required this.nodes});

  /// True when there was no corresponding `p` element in the original HTML.
  final bool wasImplicit;

  final List<InlineContentNode> nodes;
}

enum ListStyle { ordered, unordered }

class ListNode extends BlockContentNode {
  const ListNode(this.style, this.items, {super.debugHtmlNode});

  final ListStyle style;
  final List<List<BlockContentNode>> items;
}

enum HeadingLevel { h1, h2, h3, h4, h5, h6 }

class HeadingNode extends BlockContentNode {
  const HeadingNode(this.level, this.nodes, {super.debugHtmlNode});

  final HeadingLevel level;
  final List<InlineContentNode> nodes;
}

class QuotationNode extends BlockContentNode {
  const QuotationNode(this.nodes, {super.debugHtmlNode});

  final List<BlockContentNode> nodes;
}

class CodeBlockNode extends BlockContentNode {
  // TODO represent the code-highlighting style spans in CodeBlockNode
  const CodeBlockNode({super.debugHtmlNode, required this.text});

  final String text;
}

class ImageNode extends BlockContentNode {
  const ImageNode({super.debugHtmlNode, required this.srcUrl});

  /// The unmodified `src` attribute for the image.
  ///
  /// This may be a relative URL string.  It also may not work without adding
  /// authentication credentials to the request.
  final String srcUrl;
}

abstract class InlineContentNode extends ContentNode {
  const InlineContentNode({super.debugHtmlNode});
}

class UnimplementedInlineContentNode extends InlineContentNode
    with UnimplementedNode {
  const UnimplementedInlineContentNode({required this.htmlNode});

  @override
  final dom.Node htmlNode;
}

class TextNode extends InlineContentNode {
  const TextNode(this.text, {super.debugHtmlNode});

  final String text;
}

class LineBreakInlineNode extends InlineContentNode {
  const LineBreakInlineNode({super.debugHtmlNode});
}

abstract class InlineContainerNode extends InlineContentNode {
  const InlineContainerNode({super.debugHtmlNode, required this.nodes});

  final List<InlineContentNode> nodes;
}

class StrongNode extends InlineContainerNode {
  const StrongNode({super.debugHtmlNode, required super.nodes});
}

class EmphasisNode extends InlineContainerNode {
  const EmphasisNode({super.debugHtmlNode, required super.nodes});
}

class InlineCodeNode extends InlineContainerNode {
  const InlineCodeNode({super.debugHtmlNode, required super.nodes});
}

class LinkNode extends InlineContainerNode {
  const LinkNode({super.debugHtmlNode, required super.nodes});
  // TODO: final String hrefUrl;
}

enum UserMentionType { user, userGroup }

class UserMentionNode extends InlineContainerNode {
  const UserMentionNode({
    super.debugHtmlNode,
    required super.nodes,
    // required this.mentionType,
    // required this.isSilent,
  });

  // We don't actually seem to need this information.
  //  final UserMentionType mentionType;
  //  final bool isSilent;
}

abstract class EmojiNode extends InlineContentNode {
  const EmojiNode({super.debugHtmlNode});
}

class UnicodeEmojiNode extends EmojiNode {
  const UnicodeEmojiNode({super.debugHtmlNode, required this.text});

  final String text;
}

class ImageEmojiNode extends EmojiNode {
  const ImageEmojiNode({super.debugHtmlNode, required this.alt});

  final String alt; // TODO parse actual emoji image URL
}

////////////////////////////////////////////////////////////////

final _emojiClassRegexp = RegExp(r"^emoji(-[0-9a-f]+)?$");

InlineContentNode parseInlineContent(dom.Node node) {
  final debugHtmlNode = kDebugMode ? node : null;
  InlineContentNode unimplemented() =>
      UnimplementedInlineContentNode(htmlNode: node);

  if (node is dom.Text) {
    return TextNode(node.text, debugHtmlNode: debugHtmlNode);
  }
  if (node is! dom.Element) {
    return unimplemented();
  }

  final element = node;
  final localName = element.localName;
  final classes = element.classes;
  List<InlineContentNode> nodes() =>
      element.nodes.map(parseInlineContent).toList(growable: false);

  if (localName == 'br' && classes.isEmpty) {
    return LineBreakInlineNode(debugHtmlNode: debugHtmlNode);
  }
  if (localName == 'strong' && classes.isEmpty) {
    return StrongNode(nodes: nodes(), debugHtmlNode: debugHtmlNode);
  }
  if (localName == 'em' && classes.isEmpty) {
    return EmphasisNode(nodes: nodes(), debugHtmlNode: debugHtmlNode);
  }
  if (localName == 'code' && classes.isEmpty) {
    return InlineCodeNode(nodes: nodes(), debugHtmlNode: debugHtmlNode);
  }

  if (localName == 'a'
      && (classes.isEmpty
          || (classes.length == 1
              && (classes.contains('stream-topic')
                  || classes.contains('stream'))))) {
    // TODO parse link's href
    return LinkNode(nodes: nodes(), debugHtmlNode: debugHtmlNode);
  }

  if (localName == 'span'
      && (classes.contains('user-mention')
          || classes.contains('user-group-mention'))
      && (classes.length == 1
          || (classes.length == 2 && classes.contains('silent')))) {
    return UserMentionNode(nodes: nodes(), debugHtmlNode: debugHtmlNode);
  }

  if (localName == 'span'
      && classes.length == 2
      && classes.contains('emoji')
      && classes.every(_emojiClassRegexp.hasMatch)) {
    return UnicodeEmojiNode(text: element.text, debugHtmlNode: debugHtmlNode);
  }

  if (localName == 'img'
      && classes.contains('emoji')
      && classes.length == 1) {
    final alt = element.attributes['alt'];
    if (alt == null) return unimplemented();
    return ImageEmojiNode(alt: alt, debugHtmlNode: debugHtmlNode);
  }

  // TODO more types of node
  return unimplemented();
}

BlockContentNode parseListNode(dom.Element element) {
  ListStyle? listStyle;
  switch (element.localName) {
    case 'ol': listStyle = ListStyle.ordered; break;
    case 'ul': listStyle = ListStyle.unordered; break;
  }
  assert(listStyle != null);
  assert(element.classes.isEmpty);

  final debugHtmlNode = kDebugMode ? element : null;
  final List<List<BlockContentNode>> items = [];
  for (final item in element.nodes) {
    if (item is dom.Text && item.text == '\n') continue;
    if (item is! dom.Element || item.localName != 'li' || item.classes.isNotEmpty) {
      items.add([UnimplementedBlockContentNode(htmlNode: item)]);
    }
    items.add(parseImplicitParagraphBlockContentList(item.nodes));
  }

  return ListNode(listStyle!, items, debugHtmlNode: debugHtmlNode);
}

BlockContentNode parseCodeBlock(dom.Element divElement) {
  final mainElement = () {
    assert(divElement.localName == 'div' &&
        divElement.classes.length == 1 &&
        divElement.classes.contains("codehilite"));

    if (divElement.nodes.length != 1) return null;
    final child = divElement.nodes[0];
    if (child is! dom.Element) return null;
    if (child.localName != 'pre') return null;

    if (child.nodes.length > 2) return null;
    if (child.nodes.length == 2) {
      final first = child.nodes[0];
      if (first is! dom.Element ||
          first.localName != 'span' ||
          first.nodes.isNotEmpty) return null;
    }
    final grandchild = child.nodes[child.nodes.length - 1];
    if (grandchild is! dom.Element) return null;
    if (grandchild.localName != 'code') return null;

    return grandchild;
  }();

  final debugHtmlNode = kDebugMode ? divElement : null;
  if (mainElement == null) {
    return UnimplementedBlockContentNode(htmlNode: divElement);
  }

  final buffer = StringBuffer();
  for (int i = 0; i < mainElement.nodes.length; i++) {
    final child = mainElement.nodes[i];
    if (child is dom.Text) {
      String text = child.text;
      if (i == mainElement.nodes.length - 1) {
        // The HTML tends to have a final newline here.  If included in the
        // [Text] widget, that would make a trailing blank line.  So cut it out.
        text = text.replaceFirst(RegExp(r'\n$'), '');
      }
      buffer.write(text);
    } else if (child is dom.Element && child.localName == 'span') {
      // TODO parse the code-highlighting spans, to style them
      buffer.write(child.text);
    } else {
      return UnimplementedBlockContentNode(htmlNode: divElement);
    }
  }
  final text = buffer.toString();

  return CodeBlockNode(text: text, debugHtmlNode: debugHtmlNode);
}

BlockContentNode parseImageNode(dom.Element divElement) {
  final imgElement = () {
    assert(divElement.localName == 'div'
      && divElement.classes.length == 1
      && divElement.classes.contains('message_inline_image'));

    if (divElement.nodes.length != 1) return null;
    final child = divElement.nodes[0];
    if (child is! dom.Element) return null;
    if (child.localName != 'a') return null;
    if (child.classes.isNotEmpty) return null;

    if (child.nodes.length != 1) return null;
    final grandchild = child.nodes[0];
    if (grandchild is! dom.Element) return null;
    if (grandchild.localName != 'img') return null;
    if (grandchild.classes.isNotEmpty) return null;
    return grandchild;
  }();

  final debugHtmlNode = kDebugMode ? divElement : null;
  if (imgElement == null) {
    return UnimplementedBlockContentNode(htmlNode: divElement);
  }

  final src = imgElement.attributes['src'];
  if (src == null) {
    return UnimplementedBlockContentNode(htmlNode: divElement);
  }

  return ImageNode(srcUrl: src, debugHtmlNode: debugHtmlNode);
}

BlockContentNode parseBlockContent(dom.Node node) {
  final debugHtmlNode = kDebugMode ? node : null;
  if (node is! dom.Element) {
    return UnimplementedBlockContentNode(htmlNode: node);
  }
  final element = node;
  final localName = element.localName;
  final classes = element.classes;
  List<BlockContentNode> blockNodes() => parseBlockContentList(element.nodes);
  List<InlineContentNode> inlineNodes() =>
      element.nodes.map(parseInlineContent).toList(growable: false);

  if (localName == 'br' && classes.isEmpty) {
    return LineBreakNode(debugHtmlNode: debugHtmlNode);
  }

  if (localName == 'p' && classes.isEmpty) {
    return ParagraphNode(nodes: inlineNodes(), debugHtmlNode: debugHtmlNode);
  }

  if ((localName == 'ol' || localName == 'ul') && classes.isEmpty) {
    return parseListNode(element);
  }

  HeadingLevel? headingLevel;
  switch (localName) {
    case 'h1': headingLevel = HeadingLevel.h1; break;
    case 'h2': headingLevel = HeadingLevel.h2; break;
    case 'h3': headingLevel = HeadingLevel.h3; break;
    case 'h4': headingLevel = HeadingLevel.h4; break;
    case 'h5': headingLevel = HeadingLevel.h5; break;
    case 'h6': headingLevel = HeadingLevel.h6; break;
  }
  if (headingLevel == HeadingLevel.h6 && classes.isEmpty) {
    // TODO handle h1, h2, h3, h4, h5
    return HeadingNode(
        headingLevel!, inlineNodes(), debugHtmlNode: debugHtmlNode);
  }

  if (localName == 'blockquote' && classes.isEmpty) {
    return QuotationNode(blockNodes(), debugHtmlNode: debugHtmlNode);
  }

  if (localName == 'div'
      && classes.length == 1 && classes.contains('codehilite')) {
    return parseCodeBlock(element);
  }

  if (localName == 'div'
      && classes.length == 1 && classes.contains('message_inline_image')) {
    return parseImageNode(element);
  }

  // TODO more types of node
  return UnimplementedBlockContentNode(htmlNode: node);
}

bool _isPossibleInlineNode(dom.Node node) {
  // TODO: find a way to assert that this matches parsing, or refactor away
  if (node is dom.Text) return true;
  if (node is! dom.Element) return false;
  switch (node.localName) {
    case 'p':
    case 'ol':
    case 'ul':
    case 'h1':
    case 'h2':
    case 'h3':
    case 'h4':
    case 'h5':
    case 'h6':
    case 'blockquote':
    case 'div':
      return false;
    default:
      return true;
  }
}

/// Parse where block content is expected, but paragraphs may be implicit.
///
/// See [ParagraphNode].
List<BlockContentNode> parseImplicitParagraphBlockContentList(dom.NodeList nodes) {
  final List<BlockContentNode> result = [];
  final List<dom.Node> currentParagraph = [];
  void consumeParagraph() {
    result.add(ParagraphNode(
        wasImplicit: true,
        nodes:
            currentParagraph.map(parseInlineContent).toList(growable: false)));
    currentParagraph.clear();
  }

  for (final node in nodes) {
    if (node is dom.Text && (node.text == '\n')) continue;

    if (_isPossibleInlineNode(node)) {
      currentParagraph.add(node);
      continue;
    }
    if (currentParagraph.isNotEmpty) consumeParagraph();
    result.add(parseBlockContent(node));
  }
  if (currentParagraph.isNotEmpty) consumeParagraph();

  return result;
}

List<BlockContentNode> parseBlockContentList(dom.NodeList nodes) {
  final acceptedNodes = nodes.where((node) {
    // We get a bunch of newline Text nodes between paragraphs.
    // A browser seems to ignore these; let's do the same.
    if (node is dom.Text && (node.text == '\n')) return false;
    return true;
  });
  return acceptedNodes.map(parseBlockContent).toList(growable: false);
}

ZulipContent parseContent(String html) {
  final fragment = HtmlParser(html, parseMeta: false).parseFragment();
  final nodes = parseBlockContentList(fragment.nodes);
  return ZulipContent(nodes: nodes, debugHtmlNode: kDebugMode ? fragment : null);
}
