import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/dom.dart' as dom;

import '../api/core.dart';
import '../api/model/model.dart';
import '../model/binding.dart';
import '../model/content.dart';
import '../model/internal_link.dart';
import '../model/store.dart';
import 'code_block.dart';
import 'dialog.dart';
import 'lightbox.dart';
import 'message_list.dart';
import 'store.dart';
import 'text.dart';

/// The font size for message content in a plain unstyled paragraph.
const double kBaseFontSize = 14;

/// The entire content of a message, aka its body.
///
/// This does not include metadata like the sender's name and avatar, the time,
/// or the message's status as starred or edited.
class MessageContent extends StatelessWidget {
  const MessageContent({super.key, required this.message, required this.content});

  final Message message;
  final ZulipContent content;

  @override
  Widget build(BuildContext context) {
    return InheritedMessage(message: message,
      child: BlockContentList(nodes: content.nodes));
  }
}

class InheritedMessage extends InheritedWidget {
  const InheritedMessage({super.key, required this.message, required super.child});

  final Message message;

  @override
  bool updateShouldNotify(covariant InheritedMessage oldWidget) =>
    !identical(oldWidget.message, message);

  static Message of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<InheritedMessage>();
    assert(widget != null, 'No InheritedMessage ancestor');
    return widget!.message;
  }
}

//
// Block layout.
//

/// A list of DOM nodes to display in block layout.
class BlockContentList extends StatelessWidget {
  const BlockContentList({super.key, required this.nodes});

  final List<BlockContentNode> nodes;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ...nodes.map((node) {
        if (node is LineBreakNode) {
          // This goes in a Column.  So to get the effect of a newline,
          // just use an empty Text.
          return const Text('');
        } else if (node is ParagraphNode) {
          return Paragraph(node: node);
        } else if (node is HeadingNode) {
          return Heading(node: node);
        } else if (node is QuotationNode) {
          return Quotation(node: node);
        } else if (node is ListNode) {
          return ListNodeWidget(node: node);
        } else if (node is CodeBlockNode) {
          return CodeBlock(node: node);
        } else if (node is MathBlockNode) {
          return MathBlock(node: node);
        } else if (node is ImageNode) {
          return MessageImage(node: node);
        } else if (node is UnimplementedBlockContentNode) {
          return Text.rich(_errorUnimplemented(node));
        } else {
          // TODO(dart-3): Use a sealed class / pattern-matching to exclude this.
          throw Exception("impossible BlockContentNode: ${node.debugHtmlText}");
        }
      }),
    ]);
  }
}

class Paragraph extends StatelessWidget {
  const Paragraph({super.key, required this.node});

  final ParagraphNode node;

  static TextStyle getTextStyle(BuildContext context) => const TextStyle(
    fontFamily: 'Source Sans 3',
    fontSize: 14,
    height: (17 / 14),
  ).merge(weightVariableTextStyle(context));

  @override
  Widget build(BuildContext context) {
    // Empty paragraph winds up with zero height.
    // The paragraph has vertical CSS margins, but those have no effect.
    if (node.nodes.isEmpty) return const SizedBox();

    final text = _buildBlockInlineContainer(
      node: node,
      style: getTextStyle(context),
    );

    // If the paragraph didn't actually have a `p` element in the HTML,
    // then apply no margins.  (For example, these are seen in list items.)
    if (node.wasImplicit) return text;

    // For a non-empty paragraph, though — and where there was a `p` element
    // for the Zulip CSS to apply to — the margins are real.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: text);
  }
}

class Heading extends StatelessWidget {
  const Heading({super.key, required this.node});

  final HeadingNode node;

  @override
  Widget build(BuildContext context) {
    // Em-heights taken from zulip:web/styles/rendered_markdown.css .
    final emHeight = switch(node.level) {
      HeadingLevel.h1 => 1.4,
      HeadingLevel.h2 => 1.3,
      HeadingLevel.h3 => 1.2,
      HeadingLevel.h4 => 1.1,
      HeadingLevel.h5 => 1.05,
      HeadingLevel.h6 => 1.0,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 5),
      child: _buildBlockInlineContainer(
        style: TextStyle(
          fontSize: kBaseFontSize * emHeight,
          fontWeight: FontWeight.w600,
          height: 1.4),
        node: node));
  }
}

class Quotation extends StatelessWidget {
  const Quotation({super.key, required this.node});

  final QuotationNode node;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Container(
        padding: const EdgeInsets.only(left: 5),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 5,
              color: const HSLColor.fromAHSL(1, 0, 0, 0.87).toColor()))),
        child: BlockContentList(nodes: node.nodes)));
  }
}

class ListNodeWidget extends StatelessWidget {
  const ListNodeWidget({super.key, required this.node});

  final ListNode node;

  @override
  Widget build(BuildContext context) {
    // TODO(#162): p+ul and p+ol interactions
    final items = List.generate(node.items.length, (index) {
      final item = node.items[index];
      String marker;
      switch (node.style) {
        // TODO(#161): different unordered marker styles at different levels of nesting
        //   see:
        //     https://html.spec.whatwg.org/multipage/rendering.html#lists
        //     https://www.w3.org/TR/css-counter-styles-3/#simple-symbolic
        // TODO proper alignment of unordered marker; should be "• ", one space,
        //   but that comes out too close to item; not sure what's fixing that
        //   in a browser
        case ListStyle.unordered: marker = "•   "; break;
        // TODO(#59) ordered lists starting not at 1
        case ListStyle.ordered: marker = "${index+1}. "; break;
      }
      return ListItemWidget(marker: marker, nodes: item);
    });
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 5),
      child: Column(children: items));
  }
}

class ListItemWidget extends StatelessWidget {
  const ListItemWidget({super.key, required this.marker, required this.nodes});

  final String marker;
  final List<BlockContentNode> nodes;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 20, // TODO handle long numbers in <ol>, like https://github.com/zulip/zulip/pull/25063
          child: Align(
            alignment: AlignmentDirectional.topEnd, child: Text(marker))),
        Expanded(child: BlockContentList(nodes: nodes)),
      ]);
  }
}

class MessageImage extends StatelessWidget {
  const MessageImage({super.key, required this.node});

  final ImageNode node;

  @override
  Widget build(BuildContext context) {
    final message = InheritedMessage.of(context);

    // TODO(#193) multiple images in a row
    // TODO image hover animation
    final src = node.srcUrl;

    final store = PerAccountStoreWidget.of(context);
    final resolvedSrc = resolveUrl(src, store.account);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(getLightboxRoute(
          context: context, message: message, src: resolvedSrc));
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          // TODO clean up this padding by imitating web less precisely;
          //   in particular, avoid adding loose whitespace at end of message.
          // The corresponding element on web has a 5px two-sided margin…
          // and then a 1px transparent border all around.
          padding: const EdgeInsets.fromLTRB(1, 1, 6, 6),
          child: Container(
            height: 100,
            width: 150,
            alignment: Alignment.center,
            color: const Color.fromRGBO(0, 0, 0, 0.03),
            child: LightboxHero(
              message: message,
              src: resolvedSrc,
              child: RealmContentNetworkImage(
                resolvedSrc,
                filterQuality: FilterQuality.medium))))));
  }
}

class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.node});

  final CodeBlockNode node;

  static final _borderColor = const HSLColor.fromAHSL(0.15, 0, 0, 0).toColor();

  @override
  Widget build(BuildContext context) {
    return _CodeBlockContainer(
      borderColor: _borderColor,
      child: Text.rich(_buildNodes(node.spans)));
  }

  InlineSpan _buildNodes(List<CodeBlockSpanNode> nodes) {
    return TextSpan(
      style: _kCodeBlockStyle,
      children: nodes.map(_buildNode).toList(growable: false));
  }

  InlineSpan _buildNode(CodeBlockSpanNode node) {
    return TextSpan(text: node.text, style: codeBlockTextStyle(node.type));
  }
}

class _CodeBlockContainer extends StatelessWidget {
  const _CodeBlockContainer({required this.borderColor, required this.child});

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          width: 1,
          color: borderColor),
        borderRadius: BorderRadius.circular(4)),
      child: SingleChildScrollViewWithScrollbar(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(7, 5, 7, 3),
          child: child)));
  }
}

class SingleChildScrollViewWithScrollbar extends StatefulWidget {
  const SingleChildScrollViewWithScrollbar(
    {super.key, required this.scrollDirection, required this.child});

  final Axis scrollDirection;
  final Widget child;

  @override
  State<SingleChildScrollViewWithScrollbar> createState() =>
    _SingleChildScrollViewWithScrollbarState();
}

class _SingleChildScrollViewWithScrollbarState
    extends State<SingleChildScrollViewWithScrollbar> {
  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: controller,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: widget.scrollDirection,
        child: widget.child));
  }
}

class MathBlock extends StatelessWidget {
  const MathBlock({super.key, required this.node});

  final MathBlockNode node;

  static final _borderColor = const HSLColor.fromAHSL(0.15, 240, 0.8, 0.5).toColor();

  @override
  Widget build(BuildContext context) {
    return _CodeBlockContainer(
      borderColor: _borderColor,
      child: Text.rich(TextSpan(
        style: _kCodeBlockStyle,
        children: [TextSpan(text: node.texSource)])));
  }
}

//
// Inline layout.
//

Widget _buildBlockInlineContainer({
  required TextStyle? style,
  required BlockInlineContainerNode node,
}) {
  if (node.links == null) {
    return InlineContent(recognizer: null, linkRecognizers: null,
      style: style, nodes: node.nodes);
  }
  return _BlockInlineContainer(links: node.links!,
    style: style, nodes: node.nodes);
}

class _BlockInlineContainer extends StatefulWidget {
  const _BlockInlineContainer(
    {required this.links, required this.style, required this.nodes});

  final List<LinkNode> links;
  final TextStyle? style;
  final List<InlineContentNode> nodes;

  @override
  State<_BlockInlineContainer> createState() => _BlockInlineContainerState();
}

class _BlockInlineContainerState extends State<_BlockInlineContainer> {
  final Map<LinkNode, GestureRecognizer> _recognizers = {};

  void _prepareRecognizers() {
    _recognizers.addEntries(widget.links.map((node) => MapEntry(node,
      TapGestureRecognizer()..onTap = () => _launchUrl(context, node.url))));
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void initState() {
    super.initState();
    _prepareRecognizers();
  }

  @override
  void didUpdateWidget(covariant _BlockInlineContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.links, oldWidget.links)) {
      _disposeRecognizers();
      _prepareRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InlineContent(recognizer: null, linkRecognizers: _recognizers,
      style: widget.style, nodes: widget.nodes);
  }
}

class InlineContent extends StatelessWidget {
  InlineContent({
    super.key,
    required this.recognizer,
    required this.linkRecognizers,
    required this.style,
    required this.nodes,
  }) {
    _builder = _InlineContentBuilder(this);
  }

  final GestureRecognizer? recognizer;
  final Map<LinkNode, GestureRecognizer>? linkRecognizers;
  final TextStyle? style;
  final List<InlineContentNode> nodes;

  late final _InlineContentBuilder _builder;

  @override
  Widget build(BuildContext context) {
    return Text.rich(_builder.build());
  }
}

class _InlineContentBuilder {
  _InlineContentBuilder(this.widget) : _recognizer = widget.recognizer;

  final InlineContent widget;

  InlineSpan build() {
    assert(_recognizer == widget.recognizer);
    assert(_recognizerStack == null || _recognizerStack!.isEmpty);
    final result = _buildNodes(widget.nodes, style: widget.style);
    assert(_recognizer == widget.recognizer);
    assert(_recognizerStack == null || _recognizerStack!.isEmpty);
    return result;
  }

  // Why do we have to track `recognizer` here, rather than apply it
  // once at the top of the affected span?  Because the events don't bubble
  // within a paragraph:
  //   https://github.com/flutter/flutter/issues/10623
  //   https://github.com/flutter/flutter/issues/10623#issuecomment-308030170
  GestureRecognizer? _recognizer;

  List<GestureRecognizer?>? _recognizerStack;

  void _pushRecognizer(GestureRecognizer? newRecognizer) {
    (_recognizerStack ??= []).add(_recognizer);
    _recognizer = newRecognizer;
  }

  void _popRecognizer() {
    _recognizer = _recognizerStack!.removeLast();
  }

  InlineSpan _buildNodes(List<InlineContentNode> nodes, {required TextStyle? style}) {
    return TextSpan(
      style: style,
      children: nodes.map(_buildNode).toList(growable: false));
  }

  InlineSpan _buildNode(InlineContentNode node) {
    if (node is TextNode) {
      return TextSpan(text: node.text, recognizer: _recognizer);
    } else if (node is LineBreakInlineNode) {
      // Each `<br/>` is followed by a newline, which browsers apparently ignore
      // and our parser doesn't.  So don't do anything here.
      return const TextSpan(text: "");
    } else if (node is StrongNode) {
      return _buildStrong(node);
    } else if (node is EmphasisNode) {
      return _buildEmphasis(node);
    } else if (node is LinkNode) {
      return _buildLink(node);
    } else if (node is InlineCodeNode) {
      return _buildInlineCode(node);
    } else if (node is UserMentionNode) {
      return WidgetSpan(alignment: PlaceholderAlignment.middle,
        child: UserMention(node: node));
    } else if (node is UnicodeEmojiNode) {
      return TextSpan(text: node.emojiUnicode, recognizer: _recognizer);
    } else if (node is ImageEmojiNode) {
      return WidgetSpan(alignment: PlaceholderAlignment.middle,
        child: MessageImageEmoji(node: node));
    } else if (node is MathInlineNode) {
      return TextSpan(style: _kInlineMathStyle,
        children: [TextSpan(text: node.texSource)]);
    } else if (node is UnimplementedInlineContentNode) {
      return _errorUnimplemented(node);
    } else {
      // TODO(dart-3): Use a sealed class / pattern matching to eliminate this case.
      throw Exception("impossible InlineContentNode: ${node.debugHtmlText}");
    }
  }

  InlineSpan _buildStrong(StrongNode node) => _buildNodes(node.nodes,
    style: const TextStyle(fontWeight: FontWeight.w600));

  InlineSpan _buildEmphasis(EmphasisNode node) => _buildNodes(node.nodes,
    style: const TextStyle(fontStyle: FontStyle.italic));

  InlineSpan _buildLink(LinkNode node) {
    final recognizer = widget.linkRecognizers?[node];
    assert(recognizer != null);
    _pushRecognizer(recognizer);
    final result = _buildNodes(node.nodes,
      style: TextStyle(color: const HSLColor.fromAHSL(1, 200, 1, 0.4).toColor()));
    _popRecognizer();
    return result;
  }

  InlineSpan _buildInlineCode(InlineCodeNode node) {
    // TODO `code` elements: border, padding -- seems hard
    //
    // Hard because this is an inline span, which we want to be able to break
    // between lines when wrapping paragraphs.  That means we can't just make it a
    // widget; it needs to be a [TextSpan].  And in that inline setting, Flutter
    // does not appear to have an equivalent for CSS's `border` or `padding`:
    //   https://api.flutter.dev/flutter/painting/TextStyle-class.html
    //
    // One attempt was to use [TextDecoration] for the top and bottom,
    // passing this to the [TextStyle] constructor:
    //   decoration: TextDecoration.combine([TextDecoration.overline, TextDecoration.underline]),
    // (Then we could handle the left and right borders with 1px-wide [WidgetSpan]s.)
    // The overline comes out OK, but sadly the underline is, well, where a normal
    // text underline should go: it cuts right through descenders.
    //
    // Another option would be to break the text up on whitespace ourselves, and
    // make a [WidgetSpan] for each word and space.
    //
    // Or we could find a different design for displaying inline code.
    // One such alternative is implemented below.

    // TODO `code`: find equivalent of web's `unicode-bidi: embed; direction: ltr`

    // Use a light gray background, instead of a border.
    return _buildNodes(style: _kInlineCodeStyle, node.nodes);

    // Another fun solution -- we can in fact have a border!  Like so:
    //   TextStyle(
    //     background: Paint()..color = Color(0xff000000)
    //                        ..style = PaintingStyle.stroke,
    //     // … fontSize, fontFamily, …
    // The trouble is that this border hugs the text tightly -- no padding.
    // That doesn't come out looking good.

    // Here's a more different solution: add delimiters.
    // return TextSpan(children: [
    //   // TO.DO(selection): exclude these brackets from text selection
    //   const TextSpan(text: _kInlineCodeLeftBracket),
    //   TextSpan(style: _kCodeStyle, children: _buildInlineList(element.nodes)),
    //   const TextSpan(text: _kInlineCodeRightBracket),
    // ]);
  }
}

final _kInlineMathStyle = _kInlineCodeStyle.merge(TextStyle(
  backgroundColor: const HSLColor.fromAHSL(1, 240, 0.4, 0.93).toColor()));

final _kInlineCodeStyle = kMonospaceTextStyle
  .merge(const TextStyle(
    backgroundColor: Color(0xffeeeeee),
    fontSize: 0.825 * kBaseFontSize))
  .merge(
    // TODO(a11y) pass a BuildContext, to handle platform request for bold text.
    //   To get one, the result of this whole computation (to the TextStyle
    //   we get at the end) could live on one [InheritedWidget], at the
    //   MessageList or higher, so the computation doesn't get repeated
    //   frequently. Then consumers can just look it up on the InheritedWidget.
    weightVariableTextStyle(null));

final _kCodeBlockStyle = kMonospaceTextStyle
  .merge(const TextStyle(
    backgroundColor: Color.fromRGBO(255, 255, 255, 1),
    fontSize: 0.825 * kBaseFontSize))
  .merge(
    // TODO(a11y) pass a BuildContext; see comment in _kInlineCodeStyle above.
    weightVariableTextStyle(null));

// const _kInlineCodeLeftBracket = '⸤';
// const _kInlineCodeRightBracket = '⸣';
// Some alternatives:
// const _kInlineCodeLeftBracket = '⸢'; // end-bracket looks a lot like comma
// const _kInlineCodeRightBracket = '⸥';
// const _kInlineCodeLeftBracket = '｢'; // a bit bigger
// const _kInlineCodeRightBracket = '｣';
// const _kInlineCodeLeftBracket = '「'; // too much space
// const _kInlineCodeRightBracket = '」';
// const _kInlineCodeLeftBracket = '﹝'; // neat but too much space
// const _kInlineCodeRightBracket = '﹞';
// const _kInlineCodeLeftBracket = '❲'; // different shape, could work
// const _kInlineCodeRightBracket = '❳';
// const _kInlineCodeLeftBracket = '⟨'; // probably too visually similar to paren
// const _kInlineCodeRightBracket = '⟩';

class UserMention extends StatelessWidget {
  const UserMention({super.key, required this.node});

  final UserMentionNode node;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _kDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 0.2 * kBaseFontSize),
      child: InlineContent(
        // If an @-mention is inside a link, let the @-mention override it.
        recognizer: null,  // TODO make @-mentions tappable, for info on user
        // One hopes an @-mention can't contain an embedded link.
        // (The parser on creating a UserMentionNode has a TODO to check that.)
        linkRecognizers: null,
        style: Paragraph.getTextStyle(context),
        nodes: node.nodes));
  }

  static get _kDecoration => BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color.fromRGBO(0, 0, 0, 0.1), Color.fromRGBO(0, 0, 0, 0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter),
    border: Border.all(
      color: const Color.fromRGBO(0xcc, 0xcc, 0xcc, 1), width: 1),
    borderRadius: const BorderRadius.all(Radius.circular(3)));

// This is a more literal translation of Zulip web's CSS.
// But it turns out CSS `box-shadow` has a quirk we rely on there:
// it doesn't apply under the element itself, even if the element's
// own background is transparent.  Flutter's BoxShadow does apply,
// which is after all more logical from the "shadow" metaphor.
//
// static const _kDecoration = ShapeDecoration(
//   gradient: LinearGradient(
//     colors: [Color.fromRGBO(0, 0, 0, 0.1), Color.fromRGBO(0, 0, 0, 0)],
//     begin: Alignment.topCenter,
//     end: Alignment.bottomCenter),
//   shadows: [
//     BoxShadow(
//       spreadRadius: 1,
//       blurStyle: BlurStyle.outer,
//       color: Color.fromRGBO(0xcc, 0xcc, 0xcc, 1)),
//   ],
//   shape: RoundedRectangleBorder(
//     borderRadius: BorderRadius.all(Radius.circular(3))));
}

class MessageImageEmoji extends StatelessWidget {
  const MessageImageEmoji({super.key, required this.node});

  final ImageEmojiNode node;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final resolvedSrc = resolveUrl(node.src, store.account);

    const size = 20.0;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        const SizedBox(width: size, height: kBaseFontSize),
        Positioned(
          // Web's css makes this seem like it should be -0.5, but that looks
          // too low.
          top: -1.5,
          child: RealmContentNetworkImage(
            resolvedSrc,
            filterQuality: FilterQuality.medium,
            width: size,
            height: size,
          )),
      ]);
  }
}

void _launchUrl(BuildContext context, String urlString) async {
  Future<void> showError(BuildContext context, String? message) {
    return showErrorDialog(context: context,
      title: 'Unable to open link',
      message: [
        'Link could not be opened: $urlString',
        if (message != null) message,
      ].join("\n\n"));
  }

  final store = PerAccountStoreWidget.of(context);
  final url = tryResolveOnRealmUrl(urlString, store.account.realmUrl);
  if (url == null) { // TODO(log)
    await showError(context, null);
    return;
  }

  final internalNarrow = parseInternalLink(url, store);
  if (internalNarrow != null) {
    Navigator.push(context,
      MessageListPage.buildRoute(context: context,
        narrow: internalNarrow));
    return;
  }

  bool launched = false;
  String? errorMessage;
  try {
    launched = await ZulipBinding.instance.launchUrl(url);
  } on PlatformException catch (e) {
    errorMessage = e.message;
  }
  if (!launched) { // TODO(log)
    if (!context.mounted) return;
    await showError(context, errorMessage);
  }
}

/// Like [Image.network], but includes [authHeader] if [src] is on-realm.
///
/// Use this to present image content in the ambient realm: avatars, images in
/// messages, etc. Must have a [PerAccountStoreWidget] ancestor.
///
/// If [src] is an on-realm URL (it has the same origin as the ambient
/// [Auth.realmUrl]), then an HTTP request to fetch the image will include the
/// user's [authHeader].
///
/// If [src] is off-realm (e.g., a Gravatar URL), no auth header will be sent.
///
/// The image will be cached according to the cache behavior of [Image.network],
/// which may mean the cache is shared between realms.
class RealmContentNetworkImage extends StatelessWidget {
  const RealmContentNetworkImage(
    this.src, {
    super.key,
    this.scale = 1.0,
    this.frameBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.opacity,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    // `headers` skipped
    this.cacheWidth,
    this.cacheHeight,
  });

  final Uri src;

  final double scale;
  final ImageFrameBuilder? frameBuilder;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final double? width;
  final double? height;
  final Color? color;
  final Animation<double>? opacity;
  final BlendMode? colorBlendMode;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final Rect? centerSlice;
  final bool matchTextDirection;
  final bool gaplessPlayback;
  final FilterQuality filterQuality;
  final bool isAntiAlias;
  // `headers` skipped
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    final account = PerAccountStoreWidget.of(context).account;

    return Image.network(
      src.toString(),

      scale: scale,
      frameBuilder: frameBuilder,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      filterQuality: filterQuality,
      isAntiAlias: isAntiAlias,

      // Only send the auth header to the server `auth` belongs to.
      headers: src.origin == account.realmUrl.origin
        ? authHeader(email: account.email, apiKey: account.apiKey)
        : null,

      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }
}

/// A rounded square with size [size] showing a user's avatar.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.userId,
    required this.size,
    required this.borderRadius,
  });

  final int userId;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AvatarShape(
      size: size,
      borderRadius: borderRadius,
      child: AvatarImage(userId: userId));
  }
}

/// The appropriate avatar image for a user ID.
///
/// If the user isn't found, gives a [SizedBox.shrink].
///
/// Wrap this with [AvatarShape].
class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    required this.userId,
  });

  final int userId;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final user = store.users[userId];

    if (user == null) { // TODO(log)
      return const SizedBox.shrink();
    }

    final resolvedUrl = switch (user.avatarUrl) {
      null          => null, // TODO(#255): handle computing gravatars
      var avatarUrl => resolveUrl(avatarUrl, store.account),
    };
    return (resolvedUrl == null)
      ? const SizedBox.shrink()
      : RealmContentNetworkImage(resolvedUrl, filterQuality: FilterQuality.medium, fit: BoxFit.cover);
  }
}

/// A rounded square shape, to wrap an [AvatarImage] or similar.
class AvatarShape extends StatelessWidget {
  const AvatarShape({
    super.key,
    required this.size,
    required this.borderRadius,
    required this.child,
  });

  final double size;
  final double borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        clipBehavior: Clip.antiAlias,
        child: child));
  }
}

//
// Small helpers.
//

/// Resolve `url` to `account`'s realm, if relative
// This may dissolve when we start passing around URLs as [Uri] objects instead
// of strings.
Uri resolveUrl(String url, Account account) {
  final realmUrl = account.realmUrl;
  return realmUrl.resolve(url); // TODO handle if fails to parse
}

InlineSpan _errorUnimplemented(UnimplementedNode node) {
  // For now this shows error-styled HTML code even in release mode,
  // because release mode isn't yet about general users but developer demos,
  // and we want to keep the demos honest.
  // TODO(#194) think through UX for general release
  final htmlNode = node.htmlNode;
  if (htmlNode is dom.Element) {
    return TextSpan(children: [
      const TextSpan(text: "(unimplemented:", style: errorStyle),
      TextSpan(text: htmlNode.outerHtml, style: errorCodeStyle),
      const TextSpan(text: ")", style: errorStyle),
    ]);
  } else if (htmlNode is dom.Text) {
    return TextSpan(children: [
      const TextSpan(text: "(unimplemented: text «", style: errorStyle),
      TextSpan(text: htmlNode.text, style: errorCodeStyle),
      const TextSpan(text: "»)", style: errorStyle),
    ]);
  } else {
    return TextSpan(
      text: "(unimplemented: DOM node type ${htmlNode.nodeType})",
      style: errorStyle);
  }
}

const errorStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.red);

final errorCodeStyle = kMonospaceTextStyle
  .merge(const TextStyle(color: Colors.red))
  .merge(weightVariableTextStyle(null)); // TODO(a11y) pass a BuildContext
