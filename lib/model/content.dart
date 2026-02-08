import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';

import '../api/model/model.dart';
import '../api/model/submessage.dart';
import '../widgets/image.dart';
import 'code_block.dart';
import 'katex.dart';

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

sealed class ListNode extends BlockContentNode {
  const ListNode(this.items, {super.debugHtmlNode});

  final List<List<BlockContentNode>> items;

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return items
      .mapIndexed((i, nodes) =>
        _BlockContentListNode(nodes).toDiagnosticsNode(name: 'item $i'))
      .toList();
  }
}

class UnorderedListNode extends ListNode {
  const UnorderedListNode(super.items, {super.debugHtmlNode});
}

class OrderedListNode extends ListNode {
  const OrderedListNode(super.items, {required this.start, super.debugHtmlNode});

  final int start;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('start', start));
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

/// A complete KaTeX math expression within Zulip content,
/// whether block or inline.
///
/// The content nodes that are descendants of this node
/// will all be of KaTeX-specific types, such as [KatexNode].
sealed class MathNode extends ContentNode {
  const MathNode({
    super.debugHtmlNode,
    required this.texSource,
    required this.nodes,
    this.debugHardFailReason,
    this.debugSoftFailReason,
  });

  final String texSource;

  /// Parsed KaTeX node tree to be used for rendering the KaTeX content.
  ///
  /// It will be null if the parser encounters an unsupported HTML element or
  /// CSS style, indicating that the widget should render the [texSource] as a
  /// fallback instead.
  final List<KatexNode>? nodes;

  final KatexParserHardFailReason? debugHardFailReason;
  final KatexParserSoftFailReason? debugSoftFailReason;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('texSource', texSource));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return nodes?.map((node) => node.toDiagnosticsNode()).toList() ?? const [];
  }
}

/// A content node that expects a generic KaTeX context from its parent.
///
/// Each of these will have a [MathNode] as an ancestor.
sealed class KatexNode extends ContentNode {
  const KatexNode({super.debugHtmlNode});
}

/// A generic KaTeX content node, corresponding to any span in KaTeX HTML
/// that we don't otherwise specially handle.
class KatexSpanNode extends KatexNode {
  const KatexSpanNode({
    this.styles = const KatexSpanStyles(),
    this.text,
    this.nodes,
    super.debugHtmlNode,
  }) : assert((text != null) ^ (nodes != null));

  final KatexSpanStyles styles;

  /// The text this KaTeX node contains.
  ///
  /// It will be null if [nodes] is non-null.
  final String? text;

  /// The child nodes of this node in the KaTeX HTML tree.
  ///
  /// It will be null if [text] is non-null.
  final List<KatexNode>? nodes;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<KatexSpanStyles>('styles', styles));
    properties.add(StringProperty('text', text));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return nodes?.map((node) => node.toDiagnosticsNode()).toList() ?? const [];
  }
}

/// A KaTeX strut, corresponding to a `span.strut` node in KaTeX HTML.
class KatexStrutNode extends KatexNode {
  const KatexStrutNode({
    required this.heightEm,
    required this.verticalAlignEm,
    super.debugHtmlNode,
  });

  final double heightEm;
  final double? verticalAlignEm;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('heightEm', heightEm));
    properties.add(DoubleProperty('verticalAlignEm', verticalAlignEm));
  }
}

/// A KaTeX "vertical list", corresponding to a `span.vlist-t` in KaTeX HTML.
///
/// These nodes in KaTeX HTML have a very specific structure.
/// The children of these nodes in our tree correspond in the HTML to
/// certain great-grandchildren (certain `> .vlist-r > .vlist > span`)
/// of the `.vlist-t` node.
class KatexVlistNode extends KatexNode {
  const KatexVlistNode({
    required this.rows,
    super.debugHtmlNode,
  });

  final List<KatexVlistRowNode> rows;

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return rows.map((row) => row.toDiagnosticsNode()).toList();
  }
}

/// An element of a KaTeX "vertical list"; a child of a [KatexVlistNode].
///
/// These correspond to certain `.vlist-t > .vlist-r > .vlist > span` nodes
/// in KaTeX HTML.  The [KatexVlistNode] parent in our tree
/// corresponds to the `.vlist-t` great-grandparent in the HTML.
class KatexVlistRowNode extends ContentNode {
  const KatexVlistRowNode({
    required this.verticalOffsetEm,
    required this.node,
    super.debugHtmlNode,
  });

  final double verticalOffsetEm;
  final KatexSpanNode node;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('verticalOffsetEm', verticalOffsetEm));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return [node.toDiagnosticsNode()];
  }
}

/// A KaTeX node corresponding to negative values for `margin-left`
/// or `margin-right` in the inline CSS style of a KaTeX HTML node.
///
/// The parser synthesizes these as additional nodes, not corresponding
/// directly to any node in the HTML.
class KatexNegativeMarginNode extends KatexNode {
  const KatexNegativeMarginNode({
    required this.leftOffsetEm,
    required this.nodes,
    super.debugHtmlNode,
  }) : assert(leftOffsetEm < 0);

  final double leftOffsetEm;
  final List<KatexNode> nodes;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('leftOffsetEm', leftOffsetEm));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return nodes.map((node) => node.toDiagnosticsNode()).toList();
  }
}

class MathBlockNode extends MathNode implements BlockContentNode {
  const MathBlockNode({
    super.debugHtmlNode,
    required super.texSource,
    required super.nodes,
    super.debugHardFailReason,
    super.debugSoftFailReason,
  });
}

class ImagePreviewNodeList extends BlockContentNode {
  const ImagePreviewNodeList(this.imagePreviews, {super.debugHtmlNode});

  final List<ImagePreviewNode> imagePreviews;

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return imagePreviews.map((node) => node.toDiagnosticsNode()).toList();
  }
}

sealed class ImageNode extends ContentNode {
  const ImageNode({
    super.debugHtmlNode,
    required this.loading,
    required this.alt,
    required this.src,
    required this.originalSrc,
    required this.originalWidth,
    required this.originalHeight,
  });

  /// Whether the img has the "image-loading-placeholder" classname.
  ///
  /// This is expected to be true (as of 2026-01)
  /// while an uploaded image is being thumbnailed.
  ///
  /// When this is true, [src] will point to a "spinner" image.
  /// Clients are invited to show a custom loading indicator instead; we do.
  final bool loading;

  final String? alt;

  /// A URL for the image intended to be shown here in Zulip content.
  ///
  /// If [loading] is true, this will point to a "spinner" image.
  /// Clients are invited to show a custom loading indicator instead; we do.
  ///
  /// Except for images processed in modern thumbnailing (as of 2026-01),
  /// this is also meant for viewing the image by itself, in a lightbox.
  /// For how to recognize that case, see [originalSrc].
  final ImageNodeSrc src;

  /// The canonical source URL of the image.
  ///
  /// This may be a relative URL string. It also may not work without adding
  /// authentication credentials to the request.
  ///
  /// Clients are expected to use this URL when saving the image to the device.
  ///
  /// For images processed in modern thumbnailing (as of 2026-01),
  /// this is also meant for viewing the image by itself, in a lightbox
  /// (but if `data-transcoded-image` is present, it's better to use that [1]).
  /// The modern-thumbnailing case is recognized when [loading] is true
  /// or when [src] is an [ImageNodeSrcThumbnail].
  /// From discussion:
  ///   https://chat.zulip.org/#narrow/channel/412-api-documentation/topic/documenting.20inline.20images/near/2279483
  ///
  /// [1] The "transcoded image" feature is meant to keep the lightbox working
  ///     when the original image is in an uncommon format, like TIFF.
  ///     This isn't implemented yet; it's #1268.
  // TODO(#1268) implement transcoded-image feature; update dartdoc
  final String? originalSrc;

  /// The width part of data-original-dimensions, if that attribute is present.
  final double? originalWidth;

  /// The height part of data-original-dimensions, if that attribute is present.
  final double? originalHeight;

  @override
  bool operator ==(Object other) {
    return other is ImageNode
      && other.loading == loading
      && other.alt == alt
      && other.src == src
      && other.originalSrc == originalSrc
      && other.originalWidth == originalWidth
      && other.originalHeight == originalHeight;
  }

  @override
  int get hashCode => Object.hash('ImageNode',
    loading,
    alt,
    src,
    originalSrc,
    originalWidth,
    originalHeight);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('loading', value: loading, ifTrue: "is loading"));
    properties.add(StringProperty('alt', alt));
    properties.add(DiagnosticsProperty<ImageNodeSrc>('src', src));
    properties.add(StringProperty('originalSrc', originalSrc));
    properties.add(DoubleProperty('originalWidth', originalWidth));
    properties.add(DoubleProperty('originalHeight', originalHeight));
  }
}

class ImagePreviewNode extends ImageNode implements BlockContentNode {
  const ImagePreviewNode({
    super.debugHtmlNode,
    required super.loading,
    required super.src,
    required super.originalSrc,
    required super.originalWidth,
    required super.originalHeight,
  }) : super(alt: null);

  @override
  bool operator ==(Object other) {
    return other is ImagePreviewNode
      && super == other;
  }

  @override
  int get hashCode => Object.hash('ImagePreviewNode', super.hashCode);
}

/// A value of [ImagePreviewNode.src].
sealed class ImageNodeSrc extends DiagnosticableTree {
  const ImageNodeSrc();
}

/// A thumbnail URL, starting with [ImageThumbnailLocator.srcPrefix].
class ImageNodeSrcThumbnail extends ImageNodeSrc {
  const ImageNodeSrcThumbnail(this.value);

  final ImageThumbnailLocator value;

  @override
  bool operator ==(Object other) {
    return other is ImageNodeSrcThumbnail && other.value == value;
  }

  @override
  int get hashCode => Object.hash('ImageNodeSrcThumbnail', value);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ImageThumbnailLocator>('value', value));
  }
}

/// A `src` that does not start with [ImageThumbnailLocator.srcPrefix].
///
/// This may be a relative URL string. It also may not work without adding
/// authentication credentials to the request.
// In 2026-01, this class covers these known cases:
// - This may be a hard-coded "spinner" image,
//   when thumbnailing of an uploaded image is in progress.
// - This may match `href`, e.g. from pre-thumbnailing servers.
// - This may start with CAMO_URI, a server variable (e.g. on Zulip Cloud
//   it's "https://uploads.zulipusercontent.net/" in 2025-10).
class ImageNodeSrcOther extends ImageNodeSrc {
  const ImageNodeSrcOther(this.value);

  final String value;

  @override
  bool operator ==(Object other) {
    return other is ImageNodeSrcOther && other.value == value;
  }

  @override
  int get hashCode => Object.hash('ImageNodeSrcOther', value);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('value', value));
  }
}

/// Data to locate an image thumbnail,
/// and whether the image has an animated version.
///
/// Use [ImageThumbnailLocatorExtension.resolve] to obtain a suitable URL
/// for the current UI need.
@immutable
class ImageThumbnailLocator extends DiagnosticableTree {
  ImageThumbnailLocator({
    required this.defaultFormatSrc,
    required this.animated,
  }) : assert(!defaultFormatSrc.hasScheme
           && !defaultFormatSrc.hasAuthority
           && defaultFormatSrc.path.startsWith(srcPrefix));

  /// A relative URL for the default format, starting with [srcPrefix].
  ///
  /// It may not work without adding authentication credentials to the request.
  final Uri defaultFormatSrc;

  final bool animated;

  static const srcPrefix = '/user_uploads/thumbnail/';

  @override
  bool operator ==(Object other) {
    if (other is! ImageThumbnailLocator) return false;
    return defaultFormatSrc == other.defaultFormatSrc
      && animated == other.animated;
  }

  @override
  int get hashCode => Object.hash('ImageThumbnailLocator', defaultFormatSrc, animated);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('defaultFormatSrc', defaultFormatSrc.toString()));
    properties.add(FlagProperty('animated', value: animated,
      ifTrue: 'animated',
      ifFalse: 'not animated'));
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

// See:
//  https://ogp.me/
//  https://oembed.com/
//  https://zulip.com/help/image-video-and-website-previews#configure-whether-website-previews-are-shown
class WebsitePreviewNode extends BlockContentNode {
  const WebsitePreviewNode({
    super.debugHtmlNode,
    required this.hrefUrl,
    required this.imageSrcUrl,
    required this.title,
    required this.description,
  });

  /// The URL from which this preview data was retrieved.
  final String hrefUrl;

  /// The image URL representing the webpage, content value
  /// of `og:image` HTML meta property.
  final String imageSrcUrl;

  /// Represents the webpage title, derived from either
  /// the content of the `og:title` HTML meta property or
  /// the <title> HTML element.
  final String? title;

  /// Description about the webpage, content value of
  /// `og:description` HTML meta property.
  final String? description;

  @override
  bool operator ==(Object other) {
    return other is WebsitePreviewNode
      && other.hrefUrl == hrefUrl
      && other.imageSrcUrl == imageSrcUrl
      && other.title == title
      && other.description == description;
  }

  @override
  int get hashCode =>
    Object.hash('WebsitePreviewNode', hrefUrl, imageSrcUrl, title, description);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('hrefUrl', hrefUrl));
    properties.add(StringProperty('imageSrcUrl', imageSrcUrl));
    properties.add(StringProperty('title', title));
    properties.add(StringProperty('description', description));
  }
}

class TableNode extends BlockContentNode {
  const TableNode({super.debugHtmlNode, required this.rows});

  final List<TableRowNode> rows;

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return rows
      .mapIndexed((i, row) => row.toDiagnosticsNode(name: 'row $i'))
      .toList();
  }
}

class TableRowNode extends BlockContentNode {
  const TableRowNode({
    super.debugHtmlNode,
    required this.cells,
    required this.isHeader,
  });

  final List<TableCellNode> cells;

  /// Indicates whether this row is the header row.
  final bool isHeader;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('isHeader', value: isHeader, ifTrue: "is header"));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return cells
      .mapIndexed((i, cell) => cell.toDiagnosticsNode(name: 'cell $i'))
      .toList();
  }
}

// The text-alignment setting that applies to a cell's column, from the delimiter row.
//
// See GitHub-flavored Markdown:
//   https://github.github.com/gfm/#tables-extension-
enum TableColumnTextAlignment {
  /// All cells' text left-aligned, represented in Markdown as `|: --- |`.
  left, // TODO(i18n) RTL issues? https://github.com/zulip/zulip/issues/32265
  /// All cells' text center-aligned, represented in Markdown as `|: --- :|`.
  center,
  /// All cells' text right-aligned, represented in Markdown as `| --- :|`.
  right, // TODO(i18n) RTL issues? https://github.com/zulip/zulip/issues/32265
  /// Cells' text aligned the default way, represented in Markdown as `| --- |`.
  defaults
}

class TableCellNode extends BlockInlineContainerNode {
  const TableCellNode({
    super.debugHtmlNode,
    required super.nodes,
    required super.links,
    required this.textAlignment,
  });

  /// The table column text-alignment to be used for this cell.
  // In Markdown, alignment is defined per column using the delimiter row.
  // However, the generated HTML specifies alignment for each cell in a row
  // individually, that matches the UI widget implementation which is also
  // row based and needs alignment information to be per cell.
  final TableColumnTextAlignment textAlignment;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty('textAlignment', textAlignment,
      defaultValue: TableColumnTextAlignment.defaults));
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

sealed class MentionNode extends InlineContainerNode {
  const MentionNode({
    super.debugHtmlNode,
    required super.nodes,
    required this.isSilent,
  });

  final bool isSilent; // TODO(#647)

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('isSilent', value: isSilent, ifTrue: "is silent"));
  }
}

class UserMentionNode extends MentionNode {
  const UserMentionNode({
    super.debugHtmlNode,
    required super.nodes,
    required super.isSilent,
    required this.userId,
  });

  /// The ID of the user being mentioned.
  ///
  /// This is null for wildcard mentions, user group mentions,
  /// or when the user ID is unavailable in the HTML (e.g., legacy mentions).
  final int? userId;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('userId', userId));
  }
}

// TODO(#646) add WildcardMentionNode

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

/// An "inline image" / "Markdown-style image" node,
/// from the ![alt text](url) syntax.
///
/// See `api_docs/message-formatting.md` in the web PR for this feature:
///   https://github.com/zulip/zulip/pull/36226
///
/// This class accommodates forms not expected from servers in 2026-01,
/// to avoid being a landmine for possible future servers that send such forms.
/// Notably, in 2026-01, servers are expected to produce this content
/// just for uploaded images, which means the images' dimensions are available.
/// UI code should nevertheless do something reasonable when the dimensions
/// are not available. Discussion:
///   https://chat.zulip.org/#narrow/channel/378-api-design/topic/HTML.20pattern.20for.20truly.20inline.20images/near/2348085
// TODO: Link to the merged API doc when it lands.
class InlineImageNode extends ImageNode implements InlineContentNode {
  const InlineImageNode({
    super.debugHtmlNode,
    required super.loading,
    required super.alt,
    required super.src,
    required super.originalSrc,
    required super.originalWidth,
    required super.originalHeight,
  });

  @override
  bool operator ==(Object other) {
    return other is InlineImageNode
      && super == other;
  }

  @override
  int get hashCode => Object.hash('InlineImageNode', super.hashCode);
}

class MathInlineNode extends MathNode implements InlineContentNode {
  const MathInlineNode({
    super.debugHtmlNode,
    required super.texSource,
    required super.nodes,
    super.debugHardFailReason,
    super.debugSoftFailReason,
  });
}

class GlobalTimeNode extends InlineContentNode {
  const GlobalTimeNode({super.debugHtmlNode, required this.datetime});

  /// Always in UTC, enforced in [_ZulipInlineContentParser.parseInlineContent].
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

ImageNodeSrc? _tryParseImgSrc(dom.Element imgElement) {
  final src = imgElement.attributes['src'];
  if (src == null) return null;

  if (src.startsWith(ImageThumbnailLocator.srcPrefix)) {
    // For why we recognize this as the thumbnail form, see discussion:
    //   https://chat.zulip.org/#narrow/channel/412-api-documentation/topic/documenting.20inline.20images/near/2279872
    final srcUrl = Uri.tryParse(src);
    if (srcUrl == null) return null;
    final animated = imgElement.attributes['data-animated'] == 'true';
    return ImageNodeSrcThumbnail(ImageThumbnailLocator(
      defaultFormatSrc: srcUrl,
      animated: animated));
  }

  return ImageNodeSrcOther(src);
}

final _imageDimensionsRegExp = RegExp(r'^(\d+)x(\d+)$');

/// Parse an `img`'s `data-original-dimensions` attribute,
/// which servers encode as "{width}x{height}" (e.g., "300x400").
({double originalWidth, double originalHeight})? _tryParseOriginalDimensions(dom.Element imgElement) {
  final attribute = imgElement.attributes['data-original-dimensions'];
  if (attribute == null) return null;
  final match = _imageDimensionsRegExp.firstMatch(attribute);
  if (match == null) return null;
  final width = int.tryParse(match.group(1)!, radix: 10);
  final height = int.tryParse(match.group(2)!, radix: 10);
  if (width == null || height == null) return null;
  return (originalWidth: width.toDouble(), originalHeight: height.toDouble());
}

//|//////////////////////////////////////////////////////////////

/// Parser for the inline-content subtrees within Zulip content HTML.
///
/// The only entry point to this class is [parseBlockInline].
///
/// After a call to [parseBlockInline] returns, the [_ZulipInlineContentParser]
/// instance has been reset to its starting state, and can be re-used for
/// parsing other subtrees.
class _ZulipInlineContentParser {
  InlineContentNode? parseInlineImage(dom.Element imgElement, {required bool loading}) {
    assert(imgElement.localName == 'img');
    assert(imgElement.className.contains('inline-image'));
    assert(loading == imgElement.className.contains('image-loading-placeholder'));

    final src = _tryParseImgSrc(imgElement);
    if (src == null) return null;
    final originalSrc = imgElement.attributes['data-original-src'];
    final originalDimensions = _tryParseOriginalDimensions(imgElement);

    final alt = imgElement.attributes['alt'];

    return InlineImageNode(
      loading: loading,
      src: src,
      alt: alt,
      originalSrc: originalSrc,
      originalWidth: originalDimensions?.originalWidth,
      originalHeight: originalDimensions?.originalHeight,
    );
  }

  InlineContentNode? parseInlineMath(dom.Element element) {
    final debugHtmlNode = kDebugMode ? element : null;
    final parsed = parseMath(element, block: false);
    if (parsed == null) return null;
    return MathInlineNode(
      texSource: parsed.texSource,
      nodes: parsed.nodes,
      debugHtmlNode: debugHtmlNode,
      debugHardFailReason: kDebugMode ? parsed.hardFailReason : null,
      debugSoftFailReason: kDebugMode ? parsed.softFailReason : null);
  }

  MentionNode? parseMention(dom.Element element) {
    assert(element.localName == 'span');
    final debugHtmlNode = kDebugMode ? element : null;

    final classes = element.className.split(' ')..sort();
    assert(classes.contains('topic-mention')
      || classes.contains('user-mention')
      || classes.contains('user-group-mention'));
    int i = 0;

    if (i >= classes.length) return null;
    bool hasChannelWildcardClass = false;
    if (classes[i] == 'channel-wildcard-mention') {
      // Newer channel wildcard mentions have this class; older ones don't.
      i++;
      hasChannelWildcardClass = true;
    }

    if (i >= classes.length) return null;
    bool isSilent = false;
    if (classes[i] == 'silent') {
      // A silent @-mention.
      isSilent = true;
      i++;
    }

    if (i >= classes.length) return null;
    if ((classes[i] == 'topic-mention' && !hasChannelWildcardClass)
        || classes[i] == 'user-mention'
        || (classes[i] == 'user-group-mention' && !hasChannelWildcardClass)) {
      // The class we already knew we'd find before we called this function.
      // We ignore the distinction between these; see [UserMentionNode].
      // Also, we don't expect "user-group-mention" and "channel-wildcard-mention"
      // to be in the list at the same time and neither we expect "topic-mention"
      // and "channel-wildcard-mention" to be in the list at the same time.
      i++;
    }

    if (i != classes.length) {
      // There was some class we didn't expect.
      return null;
    }

    final userId = switch (element.attributes['data-user-id']) {
      // For legacy, user group or wildcard mentions.
      null || '*' => null,
      final userIdString => int.tryParse(userIdString),
    };

    // TODO assert MentionNode can't contain LinkNode;
    //   either a debug-mode check, or perhaps we can make expectations much
    //   tighter on a MentionNode's contents overall.
    final nodes = parseInlineContentList(element.nodes);
    return UserMentionNode(
      nodes: nodes,
      userId: userId,
      isSilent: isSilent,
      debugHtmlNode: debugHtmlNode);
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

  /// Matches all className values that could be a subclass of MentionNode,
  /// and no className values that could be any other type of node.
  // Specifically, checks for `user-mention` or `user-group-mention`
  // or `topic-mention` as a member of the list.
  static final _mentionClassNameRegexp = RegExp(
    r"(^| )" r"(?:user(?:-group)?|topic)-mention" r"( |$)");

  static final _emojiClassNameRegexp = () {
    const specificEmoji = r"emoji(?:-[0-9a-f]+)+";
    return RegExp("^(?:emoji $specificEmoji|$specificEmoji emoji)\$");
  }();
  static final _emojiCodeFromClassNameRegexp = RegExp(r"emoji-([^ ]+)");

  InlineContentNode parseInlineContent(dom.Node node) {
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
            || className == 'stream-topic'
            || className == 'stream'
            || className == 'message-link')) {
      final href = element.attributes['href'];
      if (href == null) return unimplemented();
      final link = LinkNode(nodes: nodes(), url: href, debugHtmlNode: debugHtmlNode);
      (_linkNodes ??= []).add(link);
      return link;
    }

    if (localName == 'span'
        && _mentionClassNameRegexp.hasMatch(className)) {
      return parseMention(element) ?? unimplemented();
    }

    if (localName == 'span'
        && _emojiClassNameRegexp.hasMatch(className)) {
      final emojiCode = _emojiCodeFromClassNameRegexp.firstMatch(className)!
        .group(1)!;
      final unicode = tryParseEmojiCodeToUnicode(emojiCode);
      if (unicode == null) return unimplemented();
      return UnicodeEmojiNode(emojiUnicode: unicode, debugHtmlNode: debugHtmlNode);
    }

    if (localName == 'img') {
      if (className == 'emoji') {
        final alt = element.attributes['alt'];
        if (alt == null) return unimplemented();
        final src = element.attributes['src'];
        if (src == null) return unimplemented();
        return ImageEmojiNode(src: src, alt: alt, debugHtmlNode: debugHtmlNode);
      }

      if (className == 'inline-image') {
        return parseInlineImage(element, loading: false) ?? unimplemented();
      } else if (
        className == 'inline-image image-loading-placeholder'
        || className == 'image-loading-placeholder inline-image'
      ) {
        return parseInlineImage(element, loading: true) ?? unimplemented();
      }
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

    if (localName == 'audio' && className.isEmpty) {
      final srcAttr = element.attributes['src'];
      if (srcAttr == null) return unimplemented();

      final String title = switch (element.attributes) {
        {'title': final titleAttr} => titleAttr,
        _ => Uri.tryParse(srcAttr)?.pathSegments.lastOrNull ?? srcAttr,
      };

      final link = LinkNode(
        url: srcAttr,
        nodes: [TextNode(title)]);
      (_linkNodes ??= []).add(link);
      return link;
    }

    if (localName == 'span' && className == 'katex') {
      return parseInlineMath(element) ?? unimplemented();
    }

    // TODO more types of node
    return unimplemented();
  }

  List<InlineContentNode> parseInlineContentList(List<dom.Node> nodes) {
    return nodes.map(parseInlineContent).toList(growable: false);
  }

  /// Parse the children of a [BlockInlineContainerNode], making up a
  /// complete subtree of inline content with no further inline ancestors.
  ({List<InlineContentNode> nodes, List<LinkNode>? links}) parseBlockInline(List<dom.Node> nodes) {
    final resultNodes = parseInlineContentList(nodes);
    return (nodes: resultNodes, links: _takeLinkNodes());
  }
}

/// Parser for a complete piece of Zulip HTML content, a [ZulipContent].
///
/// The only entry point to this class is [parse].
class _ZulipContentParser {
  /// The single inline-content parser used and re-used throughout parsing of
  /// a complete piece of Zulip HTML content.
  ///
  /// Because block content can never appear nested inside inline content,
  /// there's never a need for more than one of these at a time,
  /// so we can allocate just one up front.
  final inlineParser = _ZulipInlineContentParser();

  ({List<InlineContentNode> nodes, List<LinkNode>? links}) parseBlockInline(List<dom.Node> nodes) {
    return inlineParser.parseBlockInline(nodes);
  }

  BlockContentNode parseListNode(dom.Element element) {
    assert(element.localName == 'ol' || element.localName == 'ul');
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

    if (element.localName == 'ol') {
      final startAttr = element.attributes['start'];
      final start = startAttr == null ? 1
        : int.tryParse(startAttr, radix: 10);
      if (start == null) return UnimplementedBlockContentNode(htmlNode: element);
      return OrderedListNode(items, start: start, debugHtmlNode: debugHtmlNode);
    } else {
      return UnorderedListNode(items, debugHtmlNode: debugHtmlNode);
    }
  }

  BlockContentNode parseSpoilerNode(dom.Element divElement) {
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
          // Empirically, when a Pygments node has multiple classes, the first
          // class names a standard token type and the rest are for non-standard
          // token types specific to the language.  Zulip web only styles the
          // standard token classes and ignores the others, so we do the same.
          // See: https://github.com/zulip/zulip-flutter/issues/933
          final spanType = className.split(' ')
            .map(codeBlockSpanTypeFromClassName)
            .firstWhereOrNull((e) => e != CodeBlockSpanType.unknown);

          switch (spanType) {
            case null:
              // TODO(#194): Show these as un-syntax-highlighted code, in production.
              return UnimplementedBlockContentNode(htmlNode: divElement);
            case CodeBlockSpanType.highlightedLines:
              // TODO: Implement nesting in CodeBlockSpanNode to support hierarchically
              //       inherited styles for `span.hll` nodes.
              return UnimplementedBlockContentNode(htmlNode: divElement);
            default:
              span = CodeBlockSpanNode(text: text, type: spanType);
          }

        default:
          return UnimplementedBlockContentNode(htmlNode: divElement);
      }

      spans.add(span);
    }

    return CodeBlockNode(spans, debugHtmlNode: debugHtmlNode);
  }

  BlockContentNode? parseImagePreviewNode(dom.Element divElement) {
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
    if (elements == null) return null;

    final (linkElement, imgElement) = elements;
    final loading = imgElement.className == 'image-loading-placeholder';
    final src = _tryParseImgSrc(imgElement);
    if (src == null) return null;
    final originalSrc = linkElement.attributes['href'];
    final originalDimensions = _tryParseOriginalDimensions(imgElement);

    return ImagePreviewNode(
      loading: loading,
      src: src,
      originalSrc: originalSrc,
      originalWidth: originalDimensions?.originalWidth,
      originalHeight: originalDimensions?.originalHeight,
      debugHtmlNode: debugHtmlNode);
  }

  static final _videoClassNameRegexp = () {
    const sourceType = r"(message_inline_video|youtube-video|embed-video)";
    return RegExp("^message_inline_image $sourceType|$sourceType message_inline_image\$");
  }();

  BlockContentNode parseInlineVideoNode(dom.Element divElement) {
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

  static final _websitePreviewImageSrcRegexp = RegExp(r'background-image: url\(("?)(.+?)\1\)');

  BlockContentNode parseWebsitePreviewNode(dom.Element divElement) {
    assert(divElement.localName == 'div'
      && divElement.className == 'message_embed');

    final debugHtmlNode = kDebugMode ? divElement : null;
    final result = () {
      if (divElement.nodes case [
        dom.Element(
          localName: 'a',
          className: 'message_embed_image',
          attributes: {
            'href': final String imageHref,
            'style': final String imageStyleAttr,
          },
          nodes: []),
        dom.Element(
          localName: 'div',
          className: 'data-container',
          nodes: [...]) && final dataContainer,
      ]) {
        final match = _websitePreviewImageSrcRegexp.firstMatch(imageStyleAttr);
        if (match == null) return null;
        final imageSrcUrl = match.group(2);
        if (imageSrcUrl == null) return null;

        String? parseTitle(dom.Element element) {
          assert(element.localName == 'div' &&
            element.className == 'message_embed_title');
          if (element.nodes case [
            dom.Element(localName: 'a', className: '') && final child,
          ]) {
            final titleHref = child.attributes['href'];
            // Make sure both image hyperlink and title hyperlink are same.
            if (imageHref != titleHref) return null;

            if (child.nodes case [dom.Text(text: final title)]) {
              return title;
            }
          }
          return null;
        }

        String? parseDescription(dom.Element element) {
          assert(element.localName == 'div' &&
            element.className == 'message_embed_description');
          if (element.nodes case [dom.Text(text: final description)]) {
            return description;
          }
          return null;
        }

        String? title, description;
        switch (dataContainer.nodes) {
          case [
            dom.Element(
              localName: 'div',
              className: 'message_embed_title') && final first,
            dom.Element(
              localName: 'div',
              className: 'message_embed_description') && final second,
          ]:
            title = parseTitle(first);
            if (title == null) return null;
            description = parseDescription(second);
            if (description == null) return null;

          case [dom.Element(localName: 'div') && final single]:
            switch (single.className) {
              case 'message_embed_title':
                title = parseTitle(single);
                if (title == null) return null;

              case 'message_embed_description':
                description = parseDescription(single);
                if (description == null) return null;

              default:
                return null;
            }

          case []:
            // Server generates an empty `<div class="data-container"></div>`
            // if website HTML has neither title (derived from
            // `og:title` or `<title>…</title>`) nor description (derived from
            // `og:description`).
            break;

          default:
            return null;
        }

        return WebsitePreviewNode(
          hrefUrl: imageHref,
          imageSrcUrl: imageSrcUrl,
          title: title,
          description: description,
          debugHtmlNode: debugHtmlNode);
      } else {
        return null;
      }
    }();

    return result ?? UnimplementedBlockContentNode(htmlNode: divElement);
  }

  BlockContentNode parseTableContent(dom.Element tableElement) {
    assert(tableElement.localName == 'table'
        && tableElement.className.isEmpty);

    TableCellNode? parseTableCell(dom.Element node, bool isHeader) {
      assert(node.localName == (isHeader ? 'th' : 'td'));
      assert(node.className.isEmpty);

      final cellStyle = node.attributes['style'];
      final TableColumnTextAlignment? textAlignment;
      switch (cellStyle) {
        case null:
          textAlignment = TableColumnTextAlignment.defaults;
        case 'text-align: left;':
          textAlignment = TableColumnTextAlignment.left;
        case 'text-align: center;':
          textAlignment = TableColumnTextAlignment.center;
        case 'text-align: right;':
          textAlignment = TableColumnTextAlignment.right;
        default:
          return null;
      }
      final parsed = parseBlockInline(node.nodes);
      return TableCellNode(
        nodes: parsed.nodes,
        links: parsed.links,
        textAlignment: textAlignment);
    }

    List<TableCellNode>? parseTableCells(dom.NodeList cellNodes, bool isHeader) {
      final cells = <TableCellNode>[];
      for (final node in cellNodes) {
        if (node is dom.Text && node.text == '\n') continue;

        if (node is! dom.Element) return null;
        if (node.localName != (isHeader ? 'th' : 'td')) return null;
        if (node.className.isNotEmpty) return null;

        final cell = parseTableCell(node, isHeader);
        if (cell == null) return null;
        cells.add(cell);
      }
      return cells;
    }

    final TableNode? tableNode = (() {
      if (tableElement.nodes case [
        dom.Text(data: '\n'),
        dom.Element(localName: 'thead') && final theadElement,
        dom.Text(data: '\n'),
        dom.Element(localName: 'tbody') && final tbodyElement,
        dom.Text(data: '\n'),
      ]) {
        if (theadElement.className.isNotEmpty) return null;
        if (theadElement.nodes.isEmpty) return null;
        if (tbodyElement.className.isNotEmpty) return null;
        if (tbodyElement.nodes.isEmpty) return null;

        final int headerColumnCount;
        final parsedRows = <TableRowNode>[];

        // Parse header row element.
        if (theadElement.nodes case [
          dom.Text(data: '\n'),
          dom.Element(localName: 'tr') && final rowElement,
          dom.Text(data: '\n'),
        ]) {
          if (rowElement.className.isNotEmpty) return null;
          if (rowElement.nodes.isEmpty) return null;

          final cells = parseTableCells(rowElement.nodes, true);
          if (cells == null) return null;
          headerColumnCount = cells.length;
          parsedRows.add(TableRowNode(cells: cells, isHeader: true));
        } else {
          // TODO(dart): simplify after https://github.com/dart-lang/language/issues/2537
          return null;
        }

        // Parse body row elements.
        for (final node in tbodyElement.nodes) {
          if (node is dom.Text && node.text == '\n') continue;

          if (node is! dom.Element) return null;
          if (node.localName != 'tr') return null;
          if (node.className.isNotEmpty) return null;
          if (node.nodes.isEmpty) return null;

          final cells = parseTableCells(node.nodes, false);
          if (cells == null) return null;

          // Ensure that the number of columns in this row matches
          // the header row.
          if (cells.length != headerColumnCount) return null;
          parsedRows.add(TableRowNode(cells: cells, isHeader: false));
        }

        return TableNode(rows: parsedRows);
      } else {
        // TODO(dart): simplify after https://github.com/dart-lang/language/issues/2537
        return null;
      }
    })();

    return tableNode ?? UnimplementedBlockContentNode(htmlNode: tableElement);
  }

  void parseMathBlocks(dom.NodeList nodes, List<BlockContentNode> result) {
    assert(nodes.isNotEmpty);
    assert((() {
      final first = nodes.first;
      return first is dom.Element
        && first.localName == 'span'
        && first.className == 'katex-display';
    })());

    final firstChild = nodes.first as dom.Element;
    final parsed = parseMath(firstChild, block: true);
    if (parsed != null) {
      result.add(MathBlockNode(
        texSource: parsed.texSource,
        nodes: parsed.nodes,
        debugHtmlNode: kDebugMode ? firstChild : null,
        debugHardFailReason: kDebugMode ? parsed.hardFailReason : null,
        debugSoftFailReason: kDebugMode ? parsed.softFailReason : null));
    } else {
      result.add(UnimplementedBlockContentNode(htmlNode: firstChild));
    }

    // Skip further checks if there was only a single child.
    if (nodes.length == 1) return;

    // The case with the `<br>\n` can happen when at the end of a quote;
    // it seems like a glitch in the server's Markdown processing,
    // so hopefully there just aren't any further such glitches.
    bool hasTrailingBreakNewline = false;
    if (nodes case [..., dom.Element(localName: 'br'), dom.Text(text: '\n')]) {
      hasTrailingBreakNewline = true;
    }

    final length = hasTrailingBreakNewline
      ? nodes.length - 2
      : nodes.length;
    for (int i = 1; i < length; i++) {
      final child = nodes[i];
      final debugHtmlNode = kDebugMode ? child : null;

      // If there are multiple <span class="katex-display"> nodes in a <p>
      // each node is interleaved by '\n\n'. Whitespaces are ignored in HTML
      // on web but each node has `display: block`, which renders each node
      // on a new line. Since the emitted MathBlockNode are BlockContentNode,
      // we skip these newlines here to replicate the same behavior as on web.
      if (child case dom.Text(text: '\n\n')) continue;

      if (child case dom.Element(localName: 'span', className: 'katex-display')) {
        final parsed = parseMath(child, block: true);
        if (parsed != null) {
          result.add(MathBlockNode(
            texSource: parsed.texSource,
            nodes: parsed.nodes,
            debugHtmlNode: debugHtmlNode,
            debugHardFailReason: kDebugMode ? parsed.hardFailReason : null,
            debugSoftFailReason: kDebugMode ? parsed.softFailReason : null));
          continue;
        }
      }

      result.add(UnimplementedBlockContentNode(htmlNode: child));
    }
  }

  BlockContentNode parseBlockContent(dom.Node node) {
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

    if (localName == 'table' && className.isEmpty) {
      return parseTableContent(element);
    }

    if (localName == 'div' && className == 'spoiler-block') {
      return parseSpoilerNode(element);
    }

    if (localName == 'div' && className == 'codehilite') {
      return parseCodeBlock(element);
    }

    if (localName == 'div' && className == 'message_inline_image') {
      return parseImagePreviewNode(element)
        ?? UnimplementedBlockContentNode(htmlNode: element);
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

    if (localName == 'div' && className == 'message_embed') {
      return parseWebsitePreviewNode(element);
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
      case 'table':
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

    List<ImagePreviewNode> imagePreviewNodes = [];
    void consumeImagePreviewNodes() {
      result.add(ImagePreviewNodeList(imagePreviewNodes));
      imagePreviewNodes = [];
    }

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

      // Oddly, the way math blocks get encoded in Zulip HTML is inside a <p>.
      // And there can be multiple math blocks inside the paragraph node, so
      // handle it explicitly here.
      if (node case dom.Element(localName: 'p', className: '', nodes: [
            dom.Element(localName: 'span', className: 'katex-display'), ...])) {
        if (currentParagraph.isNotEmpty) consumeParagraph();
        if (imagePreviewNodes.isNotEmpty) consumeImagePreviewNodes();
        parseMathBlocks(node.nodes, result);
        continue;
      }

      if (_isPossibleInlineNode(node)) {
        if (imagePreviewNodes.isNotEmpty) {
          consumeImagePreviewNodes();
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
      if (block is ImagePreviewNode) {
        imagePreviewNodes.add(block);
        continue;
      }
      if (imagePreviewNodes.isNotEmpty) consumeImagePreviewNodes();
      result.add(block);
    }
    if (currentParagraph.isNotEmpty) consumeParagraph();
    if (imagePreviewNodes.isNotEmpty) consumeImagePreviewNodes();
    return result;
  }

  static final _redundantLineBreaksRegexp = RegExp(r'^\n+$');

  List<BlockContentNode> parseBlockContentList(dom.NodeList nodes) {
    final List<BlockContentNode> result = [];

    List<ImagePreviewNode> imagePreviewNodes = [];
    void consumeImagePreviewNodes() {
      result.add(ImagePreviewNodeList(imagePreviewNodes));
      imagePreviewNodes = [];
    }

    for (final node in nodes) {
      // We get a bunch of newline Text nodes between paragraphs.
      // A browser seems to ignore these; let's do the same.
      if (node is dom.Text && _redundantLineBreaksRegexp.hasMatch(node.text)) {
        continue;
      }

      // Oddly, the way math blocks get encoded in Zulip HTML is inside a <p>.
      // And there can be multiple math blocks inside the paragraph node, so
      // handle it explicitly here.
      if (node case dom.Element(localName: 'p', className: '', nodes: [
            dom.Element(localName: 'span', className: 'katex-display'), ...])) {
        if (imagePreviewNodes.isNotEmpty) consumeImagePreviewNodes();
        parseMathBlocks(node.nodes, result);
        continue;
      }

      final block = parseBlockContent(node);
      if (block is ImagePreviewNode) {
        imagePreviewNodes.add(block);
        continue;
      }
      if (imagePreviewNodes.isNotEmpty) consumeImagePreviewNodes();
      result.add(block);
    }
    if (imagePreviewNodes.isNotEmpty) consumeImagePreviewNodes();
    return result;
  }

  ZulipContent parse(String html) {
    final fragment = HtmlParser(html, parseMeta: false).parseFragment();
    final nodes = parseBlockContentList(fragment.nodes);
    return ZulipContent(nodes: nodes, debugHtmlNode: kDebugMode ? fragment : null);
  }
}

/// Parse a complete piece of Zulip HTML content,
/// such as an entire value of [Message.content].
ZulipContent parseContent(String html) {
  return _ZulipContentParser().parse(html);
}

ZulipMessageContent parseMessageContent(Message message) {
  final poll = message.poll;
  if (poll != null) return PollContent(poll);
  return parseContent(message.content);
}
