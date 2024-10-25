import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';

import '../api/model/model.dart';
import '../api/model/submessage.dart';
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

/// A parsed, ready-to-render representation of Zulip message content.
sealed class ZulipMessageContent {}

/// A wrapper around a mutable representation of a Zulip poll message.
///
/// Consumers are expected to listen for [Poll]'s changes to receive
/// live-updates.
class PollContent implements ZulipMessageContent {
  const PollContent(this.poll);

  final Poll poll;
}

/// A complete parse tree for a Zulip message's content,
/// or other complete piece of Zulip HTML content.
///
/// This is a parsed representation for an entire value of [Message.content],
/// [Stream.renderedDescription], or other text from a Zulip server that comes
/// in the same Zulip HTML format.
class ZulipContent extends ContentNode implements ZulipMessageContent {
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
sealed class BlockContentNode extends ContentNode {
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

class _BlockContentListNode extends DiagnosticableTree {
  const _BlockContentListNode(this.nodes);

  final List<BlockContentNode> nodes;

  @override
  String toStringShort() => 'BlockContentNode list';

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return nodes.map((node) => node.toDiagnosticsNode()).toList();
  }
}

/// A block content node whose children are inline content nodes.
///
/// A node of this type expects a block layout context from its parent,
/// but provides an inline layout context for its children.
///
/// See also [InlineContainerNode].
sealed class BlockInlineContainerNode extends BlockContentNode {
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

/// A `hr` element
class ThematicBreakNode extends BlockContentNode {
  const ThematicBreakNode({super.debugHtmlNode});

  @override
  bool operator ==(Object other) {
    return other is ThematicBreakNode;
  }

  @override
  int get hashCode => 'ThematicBreakNode'.hashCode;
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
      .mapIndexed((i, nodes) =>
        _BlockContentListNode(nodes).toDiagnosticsNode(name: 'item $i'))
      .toList();
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

class SpoilerNode extends BlockContentNode {
  const SpoilerNode({super.debugHtmlNode, required this.header, required this.content});

  final List<BlockContentNode> header;
  final List<BlockContentNode> content;

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return [
      _BlockContentListNode(header).toDiagnosticsNode(name: 'header'),
      _BlockContentListNode(content).toDiagnosticsNode(name: 'content'),
    ];
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

class CodeBlockSpanNode extends ContentNode {
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

class ImageNodeList extends BlockContentNode {
  const ImageNodeList(this.images, {super.debugHtmlNode});

  final List<ImageNode> images;

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return images.map((node) => node.toDiagnosticsNode()).toList();
  }
}

class ImageNode extends BlockContentNode {
  const ImageNode({
    super.debugHtmlNode,
    required this.srcUrl,
    required this.thumbnailUrl,
    required this.loading,
    required this.originalWidth,
    required this.originalHeight,
  });

  /// The canonical source URL of the image.
  ///
  /// This may be a relative URL string. It also may not work without adding
  /// authentication credentials to the request.
  final String srcUrl;

  /// The thumbnail URL of the image.
  ///
  /// This may be a relative URL string. It also may not work without adding
  /// authentication credentials to the request.
  ///
  /// This will be null if the server hasn't yet generated a thumbnail,
  /// or is a version that doesn't offer thumbnails.
  /// It will also be null when [loading] is true.
  final String? thumbnailUrl;

  /// A flag to indicate whether to show the placeholder.
  ///
  /// Typically it will be `true` while Server is generating thumbnails.
  final bool loading;

  /// The width of the canonical image.
  final double? originalWidth;

  /// The height of the canonical image.
  final double? originalHeight;

  @override
  bool operator ==(Object other) {
    return other is ImageNode
      && other.srcUrl == srcUrl
      && other.thumbnailUrl == thumbnailUrl
      && other.loading == loading
      && other.originalWidth == originalWidth
      && other.originalHeight == originalHeight;
  }

  @override
  int get hashCode => Object.hash('ImageNode',
    srcUrl, thumbnailUrl, loading, originalWidth, originalHeight);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('srcUrl', srcUrl));
    properties.add(StringProperty('thumbnailUrl', thumbnailUrl));
    properties.add(FlagProperty('loading', value: loading, ifTrue: "is loading"));
    properties.add(DoubleProperty('originalWidth', originalWidth));
    properties.add(DoubleProperty('originalHeight', originalHeight));
  }
}

class InlineVideoNode extends BlockContentNode {
  const InlineVideoNode({
    super.debugHtmlNode,
    required this.srcUrl,
  });

  /// A URL string for the video resource, on the Zulip server.
  ///
  /// This may be a relative URL string.  It also may not work without adding
  /// authentication credentials to the request.
  ///
  /// Unlike [EmbedVideoNode.hrefUrl], this should always be a URL served by
  /// either the Zulip server itself or a service it trusts.  It's therefore
  /// fine from a privacy perspective to eagerly request data from this resource
  /// when the user passively scrolls the video into view.
  final String srcUrl;

  @override
  bool operator ==(Object other) {
    return other is InlineVideoNode
      && other.srcUrl == srcUrl;
  }

  @override
  int get hashCode => Object.hash('InlineVideoNode', srcUrl);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('srcUrl', srcUrl));
  }
}

class EmbedVideoNode extends BlockContentNode {
  const EmbedVideoNode({
    super.debugHtmlNode,
    required this.hrefUrl,
    required this.previewImageSrcUrl,
  });

  /// A URL string for the video, typically on an external service.
  ///
  /// For example, this URL may be on youtube.com or vimeo.com.
  ///
  /// Unlike with [previewImageSrcUrl] or [InlineVideoNode.srcUrl],
  /// no requests should be made to this URL unless the user explicitly chooses
  /// to interact with the video, in order to protect the user's privacy.
  final String hrefUrl;

  /// A URL string for a thumbnail image for the video, on the Zulip server.
  ///
  /// This may be a relative URL string.  It also may not work without adding
  /// authentication credentials to the request.
  ///
  /// Like [InlineVideoNode.srcUrl] and unlike [hrefUrl], this is suitable
  /// from a privacy perspective for eagerly fetching data when the user
  /// passively scrolls the video into view.
  final String previewImageSrcUrl;

  @override
  bool operator ==(Object other) {
    return other is EmbedVideoNode
      && other.hrefUrl == hrefUrl
      && other.previewImageSrcUrl == previewImageSrcUrl;
  }

  @override
  int get hashCode => Object.hash('EmbedVideoNode', hrefUrl, previewImageSrcUrl);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('hrefUrl', hrefUrl));
    properties.add(StringProperty('previewImageSrcUrl', previewImageSrcUrl));
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
sealed class InlineContentNode extends ContentNode {
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
sealed class InlineContainerNode extends InlineContentNode {
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

class DeletedNode extends InlineContainerNode {
  const DeletedNode({super.debugHtmlNode, required super.nodes});
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

sealed class EmojiNode extends InlineContentNode {
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

class GlobalTimeNode extends InlineContentNode {
  const GlobalTimeNode({super.debugHtmlNode, required this.datetime});

  /// Always in UTC, enforced in [_ZulipContentParser.parseInlineContent].
  final DateTime datetime;

  @override
  bool operator ==(Object other) {
    return other is GlobalTimeNode && other.datetime == datetime;
  }

  @override
  int get hashCode => Object.hash('GlobalTimeNode', datetime);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<DateTime>('datetime', datetime));
  }
}

////////////////////////////////////////////////////////////////

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
      assert(element.localName == 'span' && element.className == 'katex');

      katexElement = element;
    } else {
      assert(element.localName == 'span' && element.className == 'katex-display');

      if (element.nodes.length != 1) return null;
      final child = element.nodes.single;
      if (child is! dom.Element) return null;
      if (child.localName != 'span') return null;
      if (child.className != 'katex') return null;
      katexElement = child;
    }

    // Expect two children span.katex-mathml, span.katex-html .
    // For now we only care about the .katex-mathml .
    if (katexElement.nodes.isEmpty) return null;
    final child = katexElement.nodes.first;
    if (child is! dom.Element) return null;
    if (child.localName != 'span') return null;
    if (child.className != 'katex-mathml') return null;

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

  static final _userMentionClassNameRegexp = () {
    // This matches a class `user-mention` or `user-group-mention`,
    // plus an optional class `silent`, appearing in either order.
    const mentionClass = r"user(?:-group)?-mention";
    return RegExp("^(?:$mentionClass(?: silent)?|silent $mentionClass)\$");
  }();

  static final _emojiClassNameRegexp = () {
    const specificEmoji = r"emoji(?:-[0-9a-f]+)+";
    return RegExp("^(?:emoji $specificEmoji|$specificEmoji emoji)\$");
  }();
  static final _emojiCodeFromClassNameRegexp = RegExp(r"emoji-([^ ]+)");

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
    final className = element.className;
    List<InlineContentNode> nodes() => parseInlineContentList(element.nodes);

    if (localName == 'br' && className.isEmpty) {
      return LineBreakInlineNode(debugHtmlNode: debugHtmlNode);
    }
    if (localName == 'strong' && className.isEmpty) {
      return StrongNode(nodes: nodes(), debugHtmlNode: debugHtmlNode);
    }
    if (localName == 'del' && className.isEmpty) {
      return DeletedNode(nodes: nodes(), debugHtmlNode: debugHtmlNode);
    }
    if (localName == 'em' && className.isEmpty) {
      return EmphasisNode(nodes: nodes(), debugHtmlNode: debugHtmlNode);
    }
    if (localName == 'code' && className.isEmpty) {
      return InlineCodeNode(nodes: nodes(), debugHtmlNode: debugHtmlNode);
    }

    if (localName == 'a'
        && (className.isEmpty
            || (className == 'stream-topic' || className == 'stream'))) {
      final href = element.attributes['href'];
      if (href == null) return unimplemented();
      final link = LinkNode(nodes: nodes(), url: href, debugHtmlNode: debugHtmlNode);
      (_linkNodes ??= []).add(link);
      return link;
    }

    if (localName == 'span'
        && _userMentionClassNameRegexp.hasMatch(className)) {
      // TODO assert UserMentionNode can't contain LinkNode;
      //   either a debug-mode check, or perhaps we can make expectations much
      //   tighter on a UserMentionNode's contents overall.
      return UserMentionNode(nodes: nodes(), debugHtmlNode: debugHtmlNode);
    }

    if (localName == 'span'
        && _emojiClassNameRegexp.hasMatch(className)) {
      final emojiCode = _emojiCodeFromClassNameRegexp.firstMatch(className)!
        .group(1)!;
      final unicode = tryParseEmojiCodeToUnicode(emojiCode);
      if (unicode == null) return unimplemented();
      return UnicodeEmojiNode(emojiUnicode: unicode, debugHtmlNode: debugHtmlNode);
    }

    if (localName == 'img' && className == 'emoji') {
      final alt = element.attributes['alt'];
      if (alt == null) return unimplemented();
      final src = element.attributes['src'];
      if (src == null) return unimplemented();
      return ImageEmojiNode(src: src, alt: alt, debugHtmlNode: debugHtmlNode);
    }

    if (localName == 'time' && className.isEmpty) {
      final dateTimeAttr = element.attributes['datetime'];
      if (dateTimeAttr == null) return unimplemented();

      // This attribute is always in ISO 8601 format with a Z suffix;
      // see `Timestamp` in zulip:zerver/lib/markdown/__init__.py .
      final datetime = DateTime.tryParse(dateTimeAttr);
      if (datetime == null) return unimplemented();
      if (!datetime.isUtc) return unimplemented();

      return GlobalTimeNode(datetime: datetime, debugHtmlNode: debugHtmlNode);
    }

    if (localName == 'span' && className == 'katex') {
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
    assert(element.className.isEmpty);

    final debugHtmlNode = kDebugMode ? element : null;
    final List<List<BlockContentNode>> items = [];
    for (final item in element.nodes) {
      if (item is dom.Text && item.text == '\n') continue;
      if (item is! dom.Element || item.localName != 'li' || item.className.isNotEmpty) {
        items.add([UnimplementedBlockContentNode(htmlNode: item)]);
      }
      items.add(parseImplicitParagraphBlockContentList(item.nodes));
    }

    return ListNode(listStyle!, items, debugHtmlNode: debugHtmlNode);
  }

  BlockContentNode parseSpoilerNode(dom.Element divElement) {
    assert(_debugParserContext == _ParserContext.block);
    assert(divElement.localName == 'div'
        && divElement.className == 'spoiler-block');

    if (divElement.nodes case [
      dom.Element(
        localName: 'div', className: 'spoiler-header', nodes: var headerNodes),
      dom.Element(
        localName: 'div', className: 'spoiler-content', nodes: var contentNodes),
    ]) {
      return SpoilerNode(
        header: parseBlockContentList(headerNodes),
        content: parseBlockContentList(contentNodes),
      );
    } else {
      return UnimplementedBlockContentNode(htmlNode: divElement);
    }
  }

  BlockContentNode parseCodeBlock(dom.Element divElement) {
    assert(_debugParserContext == _ParserContext.block);
    final mainElement = () {
      assert(divElement.localName == 'div'
          && divElement.className == "codehilite");

      if (divElement.nodes.length != 1) return null;
      final child = divElement.nodes.single;
      if (child is! dom.Element) return null;
      if (child.localName != 'pre') return null;

      if (child.nodes.length > 2 || child.nodes.isEmpty) return null;
      if (child.nodes.length == 2) {
        final first = child.nodes[0];
        if (first is! dom.Element
            || first.localName != 'span'
            || first.nodes.isNotEmpty) {
          return null;
        }
      }
      final grandchild = child.nodes.last;
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

        case dom.Element(localName: 'span', :final text, :final className):
          final CodeBlockSpanType type = codeBlockSpanTypeFromClassName(className);
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

  static final _imageDimensionsRegExp = RegExp(r'^(\d+)x(\d+)$');

  BlockContentNode parseImageNode(dom.Element divElement) {
    assert(_debugParserContext == _ParserContext.block);
    final elements = () {
      assert(divElement.localName == 'div'
          && divElement.className == 'message_inline_image');

      if (divElement.nodes.length != 1) return null;
      final child = divElement.nodes[0];
      if (child is! dom.Element) return null;
      if (child.localName != 'a') return null;
      if (child.className.isNotEmpty) return null;

      if (child.nodes.length != 1) return null;
      final grandchild = child.nodes[0];
      if (grandchild is! dom.Element) return null;
      if (grandchild.localName != 'img') return null;
      return (child, grandchild);
    }();

    final debugHtmlNode = kDebugMode ? divElement : null;
    if (elements == null) {
      return UnimplementedBlockContentNode(htmlNode: divElement);
    }

    final (linkElement, imgElement) = elements;
    final href = linkElement.attributes['href'];
    if (href == null) {
      return UnimplementedBlockContentNode(htmlNode: divElement);
    }
    if (imgElement.className == 'image-loading-placeholder') {
      return ImageNode(
        srcUrl: href,
        thumbnailUrl: null,
        loading: true,
        originalWidth: null,
        originalHeight: null,
        debugHtmlNode: debugHtmlNode);
    }
    final src = imgElement.attributes['src'];
    if (src == null) {
      return UnimplementedBlockContentNode(htmlNode: divElement);
    }

    final String srcUrl;
    final String? thumbnailUrl;
    if (src.startsWith('/user_uploads/thumbnail/')) {
      srcUrl = href;
      thumbnailUrl = src;
    } else if (src.startsWith('/external_content/')
        || src.startsWith('https://uploads.zulipusercontent.net/')) {
      srcUrl = src;
      thumbnailUrl = null;
    } else if (href == src)  {
      srcUrl = src;
      thumbnailUrl = null;
    } else {
      return UnimplementedBlockContentNode(htmlNode: divElement);
    }

    double? originalWidth, originalHeight;
    final originalDimensions = imgElement.attributes['data-original-dimensions'];
    if (originalDimensions != null) {
      // Server encodes this string as "{width}x{height}" (eg. "300x400")
      final match = _imageDimensionsRegExp.firstMatch(originalDimensions);
      if (match != null) {
        final width = int.tryParse(match.group(1)!, radix: 10);
        final height = int.tryParse(match.group(2)!, radix: 10);
        if (width != null && height != null) {
          originalWidth = width.toDouble();
          originalHeight = height.toDouble();
        }
      }

      if (originalWidth == null || originalHeight == null) {
        return UnimplementedBlockContentNode(htmlNode: divElement);
      }
    }

    return ImageNode(
      srcUrl: srcUrl,
      thumbnailUrl: thumbnailUrl,
      loading: false,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      debugHtmlNode: debugHtmlNode);
  }

  static final _videoClassNameRegexp = () {
    const sourceType = r"(message_inline_video|youtube-video|embed-video)";
    return RegExp("^message_inline_image $sourceType|$sourceType message_inline_image\$");
  }();

  BlockContentNode parseInlineVideoNode(dom.Element divElement) {
    assert(_debugParserContext == _ParserContext.block);
    assert(divElement.localName == 'div'
      && _videoClassNameRegexp.hasMatch(divElement.className));

    final videoElement = () {
      if (divElement.nodes.length != 1) return null;
      final child = divElement.nodes[0];
      if (child is! dom.Element) return null;
      if (child.localName != 'a') return null;
      if (child.className.isNotEmpty) return null;

      if (child.nodes.length != 1) return null;
      final grandchild = child.nodes[0];
      if (grandchild is! dom.Element) return null;
      if (grandchild.localName != 'video') return null;
      if (grandchild.className.isNotEmpty) return null;
      return grandchild;
    }();

    final debugHtmlNode = kDebugMode ? divElement : null;
    if (videoElement == null) {
      return UnimplementedBlockContentNode(htmlNode: divElement);
    }

    final src = videoElement.attributes['src'];
    if (src == null) {
      return UnimplementedBlockContentNode(htmlNode: divElement);
    }

    return InlineVideoNode(srcUrl: src, debugHtmlNode: debugHtmlNode);
  }

  BlockContentNode parseEmbedVideoNode(dom.Element divElement) {
    assert(_debugParserContext == _ParserContext.block);
    assert(divElement.localName == 'div'
      && _videoClassNameRegexp.hasMatch(divElement.className));

    final pair = () {
      if (divElement.nodes.length != 1) return null;
      final child = divElement.nodes[0];
      if (child is! dom.Element) return null;
      if (child.localName != 'a') return null;
      if (child.className.isNotEmpty) return null;

      if (child.nodes.length != 1) return null;
      final grandchild = child.nodes[0];
      if (grandchild is! dom.Element) return null;
      if (grandchild.localName != 'img') return null;
      if (grandchild.className.isNotEmpty) return null;
      return (child, grandchild);
    }();

    final debugHtmlNode = kDebugMode ? divElement : null;
    if (pair == null) {
      return UnimplementedBlockContentNode(htmlNode: divElement);
    }
    final (anchorElement, imgElement) = pair;

    final imgSrc = imgElement.attributes['src'];
    if (imgSrc == null) {
      return UnimplementedBlockContentNode(htmlNode: divElement);
    }

    final href = anchorElement.attributes['href'];
    if (href == null) {
      return UnimplementedBlockContentNode(htmlNode: divElement);
    }

    return EmbedVideoNode(hrefUrl: href, previewImageSrcUrl: imgSrc, debugHtmlNode: debugHtmlNode);
  }

  BlockContentNode parseBlockContent(dom.Node node) {
    assert(_debugParserContext == _ParserContext.block);
    final debugHtmlNode = kDebugMode ? node : null;
    if (node is! dom.Element) {
      return UnimplementedBlockContentNode(htmlNode: node);
    }
    final element = node;
    final localName = element.localName;
    final className = element.className;

    if (localName == 'br' && className.isEmpty) {
      return LineBreakNode(debugHtmlNode: debugHtmlNode);
    }

    if (localName == 'hr' && className.isEmpty) {
      return ThematicBreakNode(debugHtmlNode: debugHtmlNode);
    }

    if (localName == 'p' && className.isEmpty) {
      // Oddly, the way a math block gets encoded in Zulip HTML is inside a <p>.
      if (element.nodes case [dom.Element(localName: 'span') && var child, ...]) {
        if (child.className == 'katex-display') {
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
    if (headingLevel != null && className.isEmpty) {
      final parsed = parseBlockInline(element.nodes);
      return HeadingNode(debugHtmlNode: debugHtmlNode,
        level: headingLevel,
        links: parsed.links,
        nodes: parsed.nodes);
    }

    if ((localName == 'ol' || localName == 'ul') && className.isEmpty) {
      return parseListNode(element);
    }

    if (localName == 'blockquote' && className.isEmpty) {
      return QuotationNode(debugHtmlNode: debugHtmlNode,
        parseBlockContentList(element.nodes));
    }

    if (localName == 'div' && className == 'spoiler-block') {
      return parseSpoilerNode(element);
    }

    if (localName == 'div' && className == 'codehilite') {
      return parseCodeBlock(element);
    }

    if (localName == 'div' && className == 'message_inline_image') {
      return parseImageNode(element);
    }

    if (localName == 'div') {
      final match = _videoClassNameRegexp.firstMatch(className);
      if (match != null) {
        final videoClass = match.group(1) ?? match.group(2)!;
        switch (videoClass) {
          case 'message_inline_video':
            return parseInlineVideoNode(element);
          case 'youtube-video' || 'embed-video':
            return parseEmbedVideoNode(element);
        }
      }
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
    List<ImageNode> imageNodes = [];
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
        if (imageNodes.isNotEmpty) {
          result.add(ImageNodeList(imageNodes));
          imageNodes = [];
          // In a context where paragraphs are implicit it should be impossible
          // to have more paragraph content after image previews.
          result.add(UnimplementedBlockContentNode(htmlNode: node));
          continue;
        }
        currentParagraph.add(node);
        continue;
      }
      if (currentParagraph.isNotEmpty) consumeParagraph();
      final block = parseBlockContent(node);
      if (block is ImageNode) {
        imageNodes.add(block);
        continue;
      }
      if (imageNodes.isNotEmpty) {
        result.add(ImageNodeList(imageNodes));
        imageNodes = [];
      }
      result.add(block);
    }
    if (currentParagraph.isNotEmpty) consumeParagraph();
    if (imageNodes.isNotEmpty) result.add(ImageNodeList(imageNodes));

    return result;
  }

  static final _redundantLineBreaksRegexp = RegExp(r'^\n+$');

  List<BlockContentNode> parseBlockContentList(dom.NodeList nodes) {
    assert(_debugParserContext == _ParserContext.block);
    final List<BlockContentNode> result = [];
    List<ImageNode> imageNodes = [];
    for (final node in nodes) {
      // We get a bunch of newline Text nodes between paragraphs.
      // A browser seems to ignore these; let's do the same.
      if (node is dom.Text && _redundantLineBreaksRegexp.hasMatch(node.text)) {
        continue;
      }

      final block = parseBlockContent(node);
      if (block is ImageNode) {
        imageNodes.add(block);
        continue;
      }
      if (imageNodes.isNotEmpty) {
        result.add(ImageNodeList(imageNodes));
        imageNodes = [];
      }
      result.add(block);
    }
    if (imageNodes.isNotEmpty) result.add(ImageNodeList(imageNodes));
    return result;
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
