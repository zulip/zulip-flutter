import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';

import 'code_block.dart';

/// A node in a parse tree for Zulip message-style content.
///
/// See [ZulipContent].
///
/// When implementing subclasses:
///  * Override [==] and [hashCode] when they are cheap, i.e. when there is
///    an O(1) quantity of data under the node.  These are for testing
///    and debugging.
///  * Don't override [==] or [hashCode] when the data includes a list.
///    This avoids accidentally doing a lot of work in an operation that
///    looks like it should be cheap.
///  * Don't override [toString].
///  * Override [debugDescribeChildren] and/or [debugFillProperties]
///    to report all the data attached to the node, for debugging.
///    See docs: https://api.flutter.dev/flutter/foundation/Diagnosticable/debugFillProperties.html
///    We also rely on these for comparing actual to expected in tests.
///
/// When modifying subclasses, always check the following places
/// to see if they need a matching update:
///  * [==] and [hashCode], if overridden.
///  * [debugFillProperties] and/or [debugDescribeChildren].
///
/// In particular, a newly-added field typically must be added in
/// [debugFillProperties].  Otherwise tests will not examine the new field,
/// and will not spot discrepancies there.
@immutable
sealed class ContentNode extends DiagnosticableTree {
  const ContentNode({this.debugHtmlNode});

  final dom.Node? debugHtmlNode;

  String get debugHtmlText {
    final node = debugHtmlNode;
    if (node == null) return "(elided)";
    if (node is dom.Element) return node.outerHtml;
    if (node is dom.Text) return "(text «${node.text}»)";
    return "(node of type ${node.nodeType})";
  }

  @override
  String toStringShort() => objectRuntimeType(this, 'ContentNode');

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    String? result;
    assert(() {
      result = toStringDeep(minLevel: minLevel);
      return true;
    }());
    return result ?? toStringShort();
  }
}

/// A node corresponding to HTML that this client doesn't know how to parse.
mixin UnimplementedNode on ContentNode {
  dom.Node get htmlNode;

  @override
  dom.Node get debugHtmlNode => htmlNode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('html', debugHtmlText));
  }
}

/// A complete parse tree for a Zulip message's content,
/// or other complete piece of Zulip HTML content.
///
/// This is a parsed representation for an entire value of [Message.content],
/// [Stream.renderedDescription], or other text from a Zulip server that comes
/// in the same Zulip HTML format.
class ZulipContent extends ContentNode {
  const ZulipContent({super.debugHtmlNode, required this.nodes});

  final List<BlockContentNode> nodes;

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return nodes.map((node) => node.toDiagnosticsNode()).toList();
  }
}

/// A content node that expects a block layout context from its parent.
///
/// When rendered as Flutter widgets, these become children of a [Column]
/// created by the parent node's widget.
///
/// Generally these correspond to HTML elements which in the Zulip web client
/// are laid out as block-level boxes, in a block formatting context:
///   <https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_flow_layout/Block_and_inline_layout_in_normal_flow>
///
/// Almost all nodes are either a [BlockContentNode] or an [InlineContentNode].
abstract class BlockContentNode extends ContentNode {
  const BlockContentNode({super.debugHtmlNode});
}

/// A block node corresponding to HTML that this client doesn't know how to parse.
class UnimplementedBlockContentNode extends BlockContentNode
    with UnimplementedNode {
  const UnimplementedBlockContentNode({required this.htmlNode});

  @override
  final dom.Node htmlNode;

  // No ==/hashCode, because htmlNode is a whole subtree.
}

/// A block content node whose children are inline content nodes.
///
/// A node of this type expects a block layout context from its parent,
/// but provides an inline layout context for its children.
///
/// See also [InlineContainerNode].
class BlockInlineContainerNode extends BlockContentNode {
  const BlockInlineContainerNode({
    super.debugHtmlNode,
    required this.links,
    required this.nodes,
  });

  /// A list of all [LinkNode] descendants.
  ///
  /// An empty list is represented as null.
  ///
  /// Because this lists all descendants that are [LinkNode]s,
  /// it carries no information that couldn't be computed from [nodes].
  /// It exists as an optimization, to allow a widget interpreting this node
  /// to obtain that list during build without having to walk the [nodes] tree.
  //
  // We leave [links] out of [debugFillProperties], because it should carry
  // no information that's not already in [nodes].
  // Our tests validate that invariant systematically
  // (see `_checkLinks` in `test/model/content_checks.dart`),
  // and give a specialized error message if it fails.
  final List<LinkNode>? links; // TODO perhaps use `const []` instead of null

  final List<InlineContentNode> nodes;

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return nodes.map((node) => node.toDiagnosticsNode()).toList();
  }
}

// A `br` element.
class LineBreakNode extends BlockContentNode {
  const LineBreakNode({super.debugHtmlNode});

  @override
  bool operator ==(Object other) {
    return other is LineBreakNode;
  }

  @override
  int get hashCode => 'LineBreakNode'.hashCode;
}

/// A `p` element, or a place where the DOM tree logically wanted one.
///
/// We synthesize these in the absence of an actual `p` element in cases where
/// there's inline content (like [dom.Text] nodes, links, or spans) in a context
/// where block content can also appear (like inside a `li`.)  These are marked
/// with [wasImplicit].
///
/// See also [parseImplicitParagraphBlockContentList].
class ParagraphNode extends BlockInlineContainerNode {
  const ParagraphNode({
    super.debugHtmlNode,
    this.wasImplicit = false,
    required super.links,
    required super.nodes,
  });

  /// True when there was no corresponding `p` element in the original HTML.
  final bool wasImplicit;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('wasImplicit', value: wasImplicit, ifTrue: 'was implicit'));
  }
}

enum HeadingLevel { h1, h2, h3, h4, h5, h6 }

class HeadingNode extends BlockInlineContainerNode {
  const HeadingNode({
    super.debugHtmlNode,
    required super.links,
    required super.nodes,
    required this.level,
  });

  final HeadingLevel level;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty('level', level));
  }
}

enum ListStyle { ordered, unordered }

class ListNode extends BlockContentNode {
  const ListNode(this.style, this.items, {super.debugHtmlNode});

  final ListStyle style;
  final List<List<BlockContentNode>> items;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('ordered', value: style == ListStyle.ordered,
      ifTrue: 'ordered', ifFalse: 'unordered'));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return items
      .map((nodes) => _ListItemDiagnosticableNode(nodes).toDiagnosticsNode())
      .toList();
  }
}

class _ListItemDiagnosticableNode extends DiagnosticableTree {
  _ListItemDiagnosticableNode(this.nodes);

  final List<BlockContentNode> nodes;

  @override
  String toStringShort() => 'list item';

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return nodes.map((node) => node.toDiagnosticsNode()).toList();
  }
}

class QuotationNode extends BlockContentNode {
  const QuotationNode(this.nodes, {super.debugHtmlNode});

  final List<BlockContentNode> nodes;

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return nodes.map((node) => node.toDiagnosticsNode()).toList();
  }
}

class CodeBlockNode extends BlockContentNode {
  const CodeBlockNode(this.spans, {super.debugHtmlNode});

  final List<CodeBlockSpanNode> spans;

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return spans.map((node) => node.toDiagnosticsNode()).toList();
  }
}

class CodeBlockSpanNode extends InlineContentNode {
  const CodeBlockSpanNode({super.debugHtmlNode, required this.text, required this.type});

  final String text;
  final CodeBlockSpanType type;

  @override
  bool operator ==(Object other) {
    return other is CodeBlockSpanNode && other.text == text && other.type == type;
  }

  @override
  int get hashCode => Object.hash('CodeBlockSpanNode', text, type);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text));
    properties.add(EnumProperty('type', type));
  }
}

class MathBlockNode extends BlockContentNode {
  const MathBlockNode({super.debugHtmlNode, required this.texSource});

  final String texSource;

  @override
  bool operator ==(Object other) {
    return other is MathBlockNode && other.texSource == texSource;
  }

  @override
  int get hashCode => Object.hash('MathBlockNode', texSource);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('texSource', texSource));
  }
}

class ImageNode extends BlockContentNode {
  const ImageNode({super.debugHtmlNode, required this.srcUrl});

  /// The unmodified `src` attribute for the image.
  ///
  /// This may be a relative URL string.  It also may not work without adding
  /// authentication credentials to the request.
  final String srcUrl;

  @override
  bool operator ==(Object other) {
    return other is ImageNode && other.srcUrl == srcUrl;
  }

  @override
  int get hashCode => Object.hash('ImageNode', srcUrl);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('srcUrl', srcUrl));
  }
}

/// A content node that expects an inline layout context from its parent.
///
/// When rendered into a Flutter widget tree, an inline content node
/// becomes an [InlineSpan], not a widget.  It therefore participates
/// in paragraph layout, as a portion of the paragraph's text.
///
/// Generally these correspond to HTML elements which in the Zulip web client
/// are laid out as inline boxes, in an inline formatting context:
///   https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_flow_layout/Block_and_inline_layout_in_normal_flow#elements_participating_in_an_inline_formatting_context
///
/// Almost all nodes are either an [InlineContentNode] or a [BlockContentNode].
abstract class InlineContentNode extends ContentNode {
  const InlineContentNode({super.debugHtmlNode});
}

/// An inline node corresponding to HTML that this client doesn't know how to parse.
class UnimplementedInlineContentNode extends InlineContentNode
    with UnimplementedNode {
  const UnimplementedInlineContentNode({required this.htmlNode});

  @override
  final dom.Node htmlNode;
}

/// A node consisting of pure text, with no markup of its own.
///
/// This node type is how plain text is represented.  This is also the type
/// of the leaf nodes that ultimately provide the actual text in the
/// parse tree for any piece of content that contains text in a link, italics,
/// bold, a list, a blockquote, or many other constructs.
class TextNode extends InlineContentNode {
  const TextNode(this.text, {super.debugHtmlNode});

  final String text;

  @override
  bool operator ==(Object other) {
    return other is TextNode
        && other.text == text;
  }

  @override
  int get hashCode => Object.hash('TextNode', text);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text, showName: false));
  }
}

class LineBreakInlineNode extends InlineContentNode {
  const LineBreakInlineNode({super.debugHtmlNode});

  @override
  bool operator ==(Object other) => other is LineBreakInlineNode;

  @override
  int get hashCode => 'LineBreakInlineNode'.hashCode;
}

/// An inline content node which contains other inline content nodes.
///
/// A node of this type expects an inline layout context from its parent,
/// and provides an inline layout context for its children.
///
/// Typically this is realized by building a [TextSpan] whose children are
/// the [InlineSpan]s built from this node's children.  In that case,
/// the children participate in the same paragraph layout as this node
/// itself does.
///
/// See also [BlockInlineContainerNode].
abstract class InlineContainerNode extends InlineContentNode {
  const InlineContainerNode({super.debugHtmlNode, required this.nodes});

  final List<InlineContentNode> nodes;

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return nodes.map((node) => node.toDiagnosticsNode()).toList();
  }

  // No ==/hashCode, because contains nodes.
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
  const LinkNode({super.debugHtmlNode, required super.nodes, required this.url});

  final String url; // Left as a string, to defer parsing until link actually followed.

  // Unlike other [ContentNode]s, the identity is useful to show in debugging
  // because the identical [LinkNode]s are expected in the enclosing
  // [BlockInlineContainerNode.links].
  @override
  String toStringShort() => "${objectRuntimeType(this, 'LinkNode')}#${shortHash(this)}";

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('url', url));
  }
}

enum UserMentionType { user, userGroup }

class UserMentionNode extends InlineContainerNode {
  const UserMentionNode({
    super.debugHtmlNode,
    required super.nodes,
    // required this.mentionType,
    // required this.isSilent,
  });

  // We don't currently seem to need this information in code.  Instead,
  // the inner text already shows how to communicate it to the user
  // (e.g., silent mentions' text lacks a leading "@"),
  // and we show that text in the same style for all types of @-mention.
  // If we need this information in the future, go ahead and add it here.
  //   final UserMentionType mentionType;
  //   final bool isSilent;
}

abstract class EmojiNode extends InlineContentNode {
  const EmojiNode({super.debugHtmlNode});
}

class UnicodeEmojiNode extends EmojiNode {
  const UnicodeEmojiNode({super.debugHtmlNode, required this.emojiUnicode});

  final String emojiUnicode;

  @override
  bool operator ==(Object other) {
    return other is UnicodeEmojiNode && other.emojiUnicode == emojiUnicode;
  }

  @override
  int get hashCode => Object.hash('UnicodeEmojiNode', emojiUnicode);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('emojiUnicode', emojiUnicode));
  }
}

class ImageEmojiNode extends EmojiNode {
  const ImageEmojiNode({super.debugHtmlNode, required this.src, required this.alt });

  final String src;
  final String alt;

  @override
  bool operator ==(Object other) {
    return other is ImageEmojiNode && other.src == src && other.alt == alt;
  }

  @override
  int get hashCode => Object.hash('ImageEmojiNode', src, alt);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('alt', alt));
    properties.add(StringProperty('src', src));
  }
}

class MathInlineNode extends InlineContentNode {
  const MathInlineNode({super.debugHtmlNode, required this.texSource});

  final String texSource;

  @override
  bool operator ==(Object other) {
    return other is MathInlineNode && other.texSource == texSource;
  }

  @override
  int get hashCode => Object.hash('MathInlineNode', texSource);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('texSource', texSource));
  }
}

////////////////////////////////////////////////////////////////

// Ported from https://github.com/zulip/zulip-mobile/blob/c979530d6804db33310ed7d14a4ac62017432944/src/emoji/data.js#L108-L112
//
// Which was in turn ported from https://github.com/zulip/zulip/blob/63c9296d5339517450f79f176dc02d77b08020c8/zerver/models.py#L3235-L3242
// and that describes the encoding as follows:
//
// > * For Unicode emoji, [emoji_code is] a dash-separated hex encoding of
// >   the sequence of Unicode codepoints that define this emoji in the
// >   Unicode specification.  For examples, see "non_qualified" or
// >   "unified" in the following data, with "non_qualified" taking
// >   precedence when both present:
// >   https://raw.githubusercontent.com/iamcal/emoji-data/master/emoji_pretty.json
String? tryParseEmojiCodeToUnicode(String code) {
  try {
    return String.fromCharCodes(code.split('-').map((hex) => int.parse(hex, radix: 16)));
  } on FormatException { // thrown by `int.parse`
    return null;
  } on ArgumentError { // thrown by `String.fromCharCodes`
    return null;
  }
}

/// What sort of nodes a [_ZulipContentParser] is currently expecting to find.
enum _ParserContext {
  /// The parser is currently looking for block nodes.
  block,

  /// The parser is currently looking for inline nodes.
  inline,
}

class _ZulipContentParser {
  /// The current state of what sort of nodes the parser is looking for.
  ///
  /// This exists for the sake of debug-mode checks,
  /// and should be read or updated only inside an assertion.
  _ParserContext _debugParserContext = _ParserContext.block;

  String? parseMath(dom.Element element, {required bool block}) {
    assert(block == (_debugParserContext == _ParserContext.block));

    final dom.Element katexElement;
    if (!block) {
      assert(element.localName == 'span'
          && element.classes.length == 1
          && element.classes.contains('katex'));

      katexElement = element;
    } else {
      assert(element.localName == 'span'
          && element.classes.length == 1
          && element.classes.contains('katex-display'));

      if (element.nodes.length != 1) return null;
      final child = element.nodes.single;
      if (child is! dom.Element) return null;
      if (child.localName != 'span') return null;
      if (child.classes.length != 1) return null;
      if (!child.classes.contains('katex')) return null;
      katexElement = child;
    }

    // Expect two children span.katex-mathml, span.katex-html .
    // For now we only care about the .katex-mathml .
    if (katexElement.nodes.isEmpty) return null;
    final child = katexElement.nodes.first;
    if (child is! dom.Element) return null;
    if (child.localName != 'span') return null;
    if (child.classes.length != 1) return null;
    if (!child.classes.contains('katex-mathml')) return null;

    if (child.nodes.length != 1) return null;
    final grandchild = child.nodes.single;
    if (grandchild is! dom.Element) return null;
    if (grandchild.localName != 'math') return null;
    if (grandchild.attributes['display'] != (block ? 'block' : null)) return null;
    if (grandchild.namespaceUri != 'http://www.w3.org/1998/Math/MathML') return null;

    if (grandchild.nodes.length != 1) return null;
    final greatgrand = grandchild.nodes.single;
    if (greatgrand is! dom.Element) return null;
    if (greatgrand.localName != 'semantics') return null;

    if (greatgrand.nodes.isEmpty) return null;
    final descendant4 = greatgrand.nodes.last;
    if (descendant4 is! dom.Element) return null;
    if (descendant4.localName != 'annotation') return null;
    if (descendant4.attributes['encoding'] != 'application/x-tex') return null;

    return descendant4.text.trim();
  }

  /// The links found so far in the current block inline container.
  ///
  /// Empty is represented as null.
  /// This is also null when not within a block inline container.
  List<LinkNode>? _linkNodes;

  List<LinkNode>? _takeLinkNodes() {
    final result = _linkNodes;
    _linkNodes = null;
    return result;
  }

  static final _emojiClassRegexp = RegExp(r"^emoji(-[0-9a-f]+)*$");

  InlineContentNode parseInlineContent(dom.Node node) {
    assert(_debugParserContext == _ParserContext.inline);
    final debugHtmlNode = kDebugMode ? node : null;
    InlineContentNode unimplemented() => UnimplementedInlineContentNode(htmlNode: node);

    if (node is dom.Text) {
      return TextNode(node.text, debugHtmlNode: debugHtmlNode);
    }
    if (node is! dom.Element) {
      return unimplemented();
    }

    final element = node;
    final localName = element.localName;
    final classes = element.classes;
    List<InlineContentNode> nodes() => parseInlineContentList(element.nodes);

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
      final href = element.attributes['href'];
      if (href == null) return unimplemented();
      final link = LinkNode(nodes: nodes(), url: href, debugHtmlNode: debugHtmlNode);
      (_linkNodes ??= []).add(link);
      return link;
    }

    if (localName == 'span'
        && (classes.contains('user-mention')
            || classes.contains('user-group-mention'))
        && (classes.length == 1
            || (classes.length == 2 && classes.contains('silent')))) {
      // TODO assert UserMentionNode can't contain LinkNode;
      //   either a debug-mode check, or perhaps we can make expectations much
      //   tighter on a UserMentionNode's contents overall.
      return UserMentionNode(nodes: nodes(), debugHtmlNode: debugHtmlNode);
    }

    if (localName == 'span'
        && classes.length == 2
        && classes.contains('emoji')
        && classes.every(_emojiClassRegexp.hasMatch)) {
      final emojiCode = classes
        .firstWhere((className) => className.startsWith('emoji-'))
        .replaceFirst('emoji-', '');
      assert(emojiCode.isNotEmpty);

      final unicode = tryParseEmojiCodeToUnicode(emojiCode);
      if (unicode == null) return unimplemented();
      return UnicodeEmojiNode(emojiUnicode: unicode, debugHtmlNode: debugHtmlNode);
    }

    if (localName == 'img'
        && classes.contains('emoji')
        && classes.length == 1) {
      final alt = element.attributes['alt'];
      if (alt == null) return unimplemented();
      final src = element.attributes['src'];
      if (src == null) return unimplemented();
      return ImageEmojiNode(src: src, alt: alt, debugHtmlNode: debugHtmlNode);
    }

    if (localName == 'span'
        && classes.length == 1
        && classes.contains('katex')) {
      final texSource = parseMath(element, block: false);
      if (texSource == null) return unimplemented();
      return MathInlineNode(texSource: texSource, debugHtmlNode: debugHtmlNode);
    }

    // TODO more types of node
    return unimplemented();
  }

  List<InlineContentNode> parseInlineContentList(List<dom.Node> nodes) {
    assert(_debugParserContext == _ParserContext.inline);
    return nodes.map(parseInlineContent).toList(growable: false);
  }

  ({List<InlineContentNode> nodes, List<LinkNode>? links}) parseBlockInline(List<dom.Node> nodes) {
    assert(_debugParserContext == _ParserContext.block);
    assert(() {
      _debugParserContext = _ParserContext.inline;
      return true;
    }());
    final resultNodes = parseInlineContentList(nodes);
    assert(() {
      _debugParserContext = _ParserContext.block;
      return true;
    }());
    return (nodes: resultNodes, links: _takeLinkNodes());
  }

  BlockContentNode parseListNode(dom.Element element) {
    assert(_debugParserContext == _ParserContext.block);
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
    assert(_debugParserContext == _ParserContext.block);
    final mainElement = () {
      assert(divElement.localName == 'div'
          && divElement.classes.length == 1
          && divElement.classes.contains("codehilite"));

      if (divElement.nodes.length != 1) return null;
      final child = divElement.nodes[0];
      if (child is! dom.Element) return null;
      if (child.localName != 'pre') return null;

      if (child.nodes.length > 2) return null;
      if (child.nodes.length == 2) {
        final first = child.nodes[0];
        if (first is! dom.Element
            || first.localName != 'span'
            || first.nodes.isNotEmpty) return null;
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

    final spans = <CodeBlockSpanNode>[];
    for (int i = 0; i < mainElement.nodes.length; i++) {
      final child = mainElement.nodes[i];

      final CodeBlockSpanNode span;
      switch (child) {
        case dom.Text(:var text):
          if (i == mainElement.nodes.length - 1) {
            // The HTML tends to have a final newline here.  If included in the
            // [Text] widget, that would make a trailing blank line.  So cut it out.
            text = text.replaceFirst(RegExp(r'\n$'), '');
          }
          if (text.isEmpty) {
            continue;
          }
          span = CodeBlockSpanNode(text: text, type: CodeBlockSpanType.text);

        case dom.Element(localName: 'span', :final text, :final classes)
            when classes.length == 1:
          final CodeBlockSpanType type = codeBlockSpanTypeFromClassName(classes.first);
          switch (type) {
            case CodeBlockSpanType.unknown:
              // TODO(#194): Show these as un-syntax-highlighted code, in production.
              return UnimplementedBlockContentNode(htmlNode: divElement);
            case CodeBlockSpanType.highlightedLines:
              // TODO: Implement nesting in CodeBlockSpanNode to support hierarchically
              //       inherited styles for `span.hll` nodes.
              return UnimplementedBlockContentNode(htmlNode: divElement);
            default:
              span = CodeBlockSpanNode(text: text, type: type);
          }

        default:
          return UnimplementedBlockContentNode(htmlNode: divElement);
      }

      spans.add(span);
    }

    return CodeBlockNode(spans, debugHtmlNode: debugHtmlNode);
  }

  BlockContentNode parseImageNode(dom.Element divElement) {
    assert(_debugParserContext == _ParserContext.block);
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
    assert(_debugParserContext == _ParserContext.block);
    final debugHtmlNode = kDebugMode ? node : null;
    if (node is! dom.Element) {
      return UnimplementedBlockContentNode(htmlNode: node);
    }
    final element = node;
    final localName = element.localName;
    final classes = element.classes;
    List<BlockContentNode> blockNodes() => parseBlockContentList(element.nodes);

    if (localName == 'br' && classes.isEmpty) {
      return LineBreakNode(debugHtmlNode: debugHtmlNode);
    }

    if (localName == 'p' && classes.isEmpty) {
      // Oddly, the way a math block gets encoded in Zulip HTML is inside a <p>.
      if (element.nodes case [dom.Element(localName: 'span') && var child, ...]) {
        if (child.classes.length == 1
            && child.classes.contains('katex-display')) {
          if (element.nodes case [_]
                              || [_, dom.Element(localName: 'br'),
                                     dom.Text(text: "\n")]) {
            // This might be too specific; we'll find out when we do #190.
            // The case with the `<br>\n` can happen when at the end of a quote;
            // it seems like a glitch in the server's Markdown processing,
            // so hopefully there just aren't any further such glitches.
            final texSource = parseMath(child, block: true);
            if (texSource == null) return UnimplementedBlockContentNode(htmlNode: node);
            return MathBlockNode(texSource: texSource, debugHtmlNode: debugHtmlNode);
          }
        }
      }

      final parsed = parseBlockInline(element.nodes);
      return ParagraphNode(debugHtmlNode: debugHtmlNode,
        links: parsed.links,
        nodes: parsed.nodes);
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
    if (headingLevel != null && classes.isEmpty) {
      final parsed = parseBlockInline(element.nodes);
      return HeadingNode(debugHtmlNode: debugHtmlNode,
        level: headingLevel,
        links: parsed.links,
        nodes: parsed.nodes);
    }

    if ((localName == 'ol' || localName == 'ul') && classes.isEmpty) {
      return parseListNode(element);
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
    assert(_debugParserContext == _ParserContext.block);
    final List<BlockContentNode> result = [];
    final List<dom.Node> currentParagraph = [];
    void consumeParagraph() {
      final parsed = parseBlockInline(currentParagraph);
      result.add(ParagraphNode(
        wasImplicit: true,
        links: parsed.links,
        nodes: parsed.nodes));
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
    assert(_debugParserContext == _ParserContext.block);
    final acceptedNodes = nodes.where((node) {
      // We get a bunch of newline Text nodes between paragraphs.
      // A browser seems to ignore these; let's do the same.
      if (node is dom.Text && (node.text == '\n')) return false;
      return true;
    });
    return acceptedNodes.map(parseBlockContent).toList(growable: false);
  }

  ZulipContent parse(String html) {
    final fragment = HtmlParser(html, parseMeta: false).parseFragment();
    final nodes = parseBlockContentList(fragment.nodes);
    return ZulipContent(nodes: nodes, debugHtmlNode: kDebugMode ? fragment : null);
  }
}

ZulipContent parseContent(String html) {
  return _ZulipContentParser().parse(html);
}
