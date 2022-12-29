import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;

import '../model/content.dart';
import '../model/store.dart';
import 'app.dart';

/// The font size for message content in a plain unstyled paragraph.
const double kBaseFontSize = 14;

/// The entire content of a message, aka its body.
///
/// This does not include metadata like the sender's name and avatar, the time,
/// or the message's status as starred or edited.
class MessageContent extends StatelessWidget {
  const MessageContent({super.key, required this.content});

  final ZulipContent content;

  @override
  Widget build(BuildContext context) {
    return BlockContentList(nodes: content.nodes);
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
      ...nodes.map((node) => BlockContentNodeWidget(node: node)),
      // Text(nodes.map((n) => n.debugHtmlText ?? "").join())
    ]);
  }
}

/// A single DOM node to display in block layout.
class BlockContentNodeWidget extends StatelessWidget {
  const BlockContentNodeWidget({super.key, required this.node});

  final BlockContentNode node;

  @override
  Widget build(BuildContext context) {
    final node = this.node;
    if (node is LineBreakNode) {
      // In block context, the widget we return is going into a Column.
      // So to get the effect of a newline, just use an empty Text.
      return const Text('');
    } else if (node is ParagraphNode) {
      return Paragraph(node: node);
    } else if (node is ListNode) {
      return ListNodeWidget(node: node);
    } else if (node is HeadingNode) {
      // TODO h1, h2, h3, h4, h5 -- same as h6 except font size
      assert(node.level == HeadingLevel.h6);
      return Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 5),
          child: Text.rich(TextSpan(
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
              children: _buildInlineList(node.nodes))));
    } else if (node is QuotationNode) {
      return Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Container(
              padding: const EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(
                          width: 5,
                          color: const HSLColor.fromAHSL(1, 0, 0, 0.87)
                              .toColor()))),
              child: BlockContentList(nodes: node.nodes)));
    } else if (node is CodeBlockNode) {
      return CodeBlock(node: node);
    } else if (node is ImageNode) {
      return MessageImage(node: node);
    } else if (node is UnimplementedBlockContentNode) {
      return Text.rich(_errorUnimplemented(node));
    } else {
      // TODO(dart-3): Use a sealed class / pattern-matching to exclude this.
      throw Exception("impossible BlockContentNode: ${node.debugHtmlText}");
    }
  }
}

class Paragraph extends StatelessWidget {
  const Paragraph({super.key, required this.node});

  final ParagraphNode node;

  @override
  Widget build(BuildContext context) {
    // Empty paragraph winds up with zero height.
    // The paragraph has vertical CSS margins, but those have no effect.
    if (node.nodes.isEmpty) return const SizedBox();

    final text = Text.rich(TextSpan(children: _buildInlineList(node.nodes)));

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

class ListNodeWidget extends StatelessWidget {
  const ListNodeWidget({super.key, required this.node});

  final ListNode node;

  @override
  Widget build(BuildContext context) {
    // TODO p+ul and p+ol interactions
    final items = List.generate(node.items.length, (index) {
      final item = node.items[index];
      String marker;
      switch (node.style) {
        // TODO different unordered marker styles at different levels of nesting
        //   see:
        //     https://html.spec.whatwg.org/multipage/rendering.html#lists
        //     https://www.w3.org/TR/css-counter-styles-3/#simple-symbolic
        // TODO proper alignment of unordered marker; should be "• ", one space,
        //   but that comes out too close to item; not sure what's fixing that
        //   in a browser
        case ListStyle.unordered: marker = "•   "; break;
        // TODO ordered lists starting not at 1
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
              width: 20,
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
    // TODO multiple images in a row
    // TODO image hover animation
    final src = node.srcUrl;

    final store = PerAccountStoreWidget.of(context);
    final adjustedSrc = rewriteImageUrl(src, store.account);

    return Align(
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
                child: Image.network(
                  adjustedSrc,
                  filterQuality: FilterQuality.medium,
                ))));
  }
}

class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.node});

  final CodeBlockNode node;

  @override
  Widget build(BuildContext context) {
    final text = node.text;

    return Container(
        padding: const EdgeInsets.fromLTRB(7, 5, 7, 3),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
                width: 1,
                color: const HSLColor.fromAHSL(0.15, 0, 0, 0).toColor())),
        child: SingleChildScrollViewWithScrollbar(
            scrollDirection: Axis.horizontal,
            child: Text(text, style: _kCodeStyle)));
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
            scrollDirection: widget.scrollDirection, child: widget.child));
  }
}

//
// Inline layout.
//

List<InlineSpan> _buildInlineList(List<InlineContentNode> nodes) =>
    List.of(nodes.map(_buildInlineNode));

InlineSpan _buildInlineNode(InlineContentNode node) {
  InlineSpan styled(List<InlineContentNode> nodes, TextStyle style) =>
      TextSpan(children: _buildInlineList(nodes), style: style);

  if (node is TextNode) {
    return TextSpan(text: node.text);
  } else if (node is LineBreakInlineNode) {
    // Each `<br/>` is followed by a newline, which browsers apparently ignore
    // and our parser doesn't.  So don't do anything here.
    return const TextSpan(text: "");
  } else if (node is StrongNode) {
    return styled(node.nodes, const TextStyle(fontWeight: FontWeight.w600));
  } else if (node is EmphasisNode) {
    return styled(node.nodes, const TextStyle(fontStyle: FontStyle.italic));
  } else if (node is InlineCodeNode) {
    return inlineCode(node);
  } else if (node is LinkNode) {
    // TODO make link touchable
    return styled(node.nodes,
        TextStyle(color: const HSLColor.fromAHSL(1, 200, 1, 0.4).toColor()));
  } else if (node is UserMentionNode) {
    return WidgetSpan(
        alignment: PlaceholderAlignment.middle, child: UserMention(node: node));
  } else if (node is UnicodeEmojiNode) {
    return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: MessageUnicodeEmoji(node: node));
  } else if (node is ImageEmojiNode) {
    return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: MessageImageEmoji(node: node));
  } else if (node is UnimplementedInlineContentNode) {
    return _errorUnimplemented(node);
  } else {
    // TODO(dart-3): Use a sealed class / pattern matching to eliminate this case.
    throw Exception("impossible InlineContentNode: ${node.debugHtmlText}");
  }
}

InlineSpan inlineCode(InlineCodeNode node) {
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
  return TextSpan(
      style: const TextStyle(
        backgroundColor: Color(0xffeeeeee),
        fontSize: 0.825 * kBaseFontSize,
        fontFamily: "Source Code Pro", // TODO supply font
        fontFamilyFallback: ["monospace"],
      ),
      children: _buildInlineList(node.nodes));

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

const _kCodeStyle = TextStyle(
  backgroundColor: Color.fromRGBO(255, 255, 255, 1),
  fontSize: 0.825 * kBaseFontSize,
  fontFamily: "Source Code Pro", // TODO supply font
  fontFamilyFallback: ["monospace"],
);

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
        child: Text.rich(TextSpan(children: _buildInlineList(node.nodes))));
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
//     gradient: LinearGradient(
//         colors: [Color.fromRGBO(0, 0, 0, 0.1), Color.fromRGBO(0, 0, 0, 0)],
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter),
//     shadows: [
//       BoxShadow(
//           spreadRadius: 1,
//           blurStyle: BlurStyle.outer,
//           color: Color.fromRGBO(0xcc, 0xcc, 0xcc, 1))
//     ],
//     shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.all(Radius.circular(3))));
}

class MessageUnicodeEmoji extends StatelessWidget {
  const MessageUnicodeEmoji({super.key, required this.node});

  final UnicodeEmojiNode node;

  @override
  Widget build(BuildContext context) {
    // TODO get spritesheet and show actual emoji glyph
    final text = node.text;
    return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            color: Colors.white, border: Border.all(color: Colors.purple)),
        child: Text(text));
  }
}

class MessageImageEmoji extends StatelessWidget {
  const MessageImageEmoji({super.key, required this.node});

  final ImageEmojiNode node;

  @override
  Widget build(BuildContext context) {
    // TODO show actual emoji image
    final alt = node.alt;
    return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            color: Colors.white, border: Border.all(color: Colors.purple)),
        child: Text(alt));
  }
}

//
// Small helpers.
//

/// Resolve URL if relative; add the user's API key if appropriate.
///
/// The API key is added if the URL is on the realm, and is an endpoint
/// known to require authentication (and to accept it in this form.)
String rewriteImageUrl(String src, Account account) {
  final realmUrl = Uri.parse(account.realmUrl); // TODO clean this up
  final resolved = realmUrl.resolve(src); // TODO handle if fails to parse

  Uri adjustedSrc = resolved;
  if (_sameOrigin(resolved, realmUrl)) {
    if (_kInlineApiRoutes.any((regexp) => regexp.hasMatch(resolved.path))) {
      final delimiter = resolved.query.isNotEmpty ? '&' : '';
      adjustedSrc = resolved
          .resolve('?${resolved.query}${delimiter}api_key=${account.apiKey}');
    }
  }

  return adjustedSrc.toString();
}

/// List of routes which accept the API key appended as a GET parameter.
final List<RegExp> _kInlineApiRoutes = [
  RegExp(r'^/user_uploads/'),
  RegExp(r'^/thumbnail$'),
  RegExp(r'^/avatar/')
];

bool _sameOrigin(Uri x, Uri y) => // TODO factor better; fact-check
    x.scheme == y.scheme &&
    x.userInfo == y.userInfo &&
    x.host == y.host &&
    x.port == y.port;

InlineSpan _errorUnimplemented(UnimplementedNode node) {
  // For now this shows error-styled HTML code even in release mode,
  // because release mode isn't yet about general users but developer demos,
  // and we want to keep the demos honest.
  // TODO think through UX for general release
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

const errorCodeStyle = TextStyle(color: Colors.red, fontFamily: 'monospace');
