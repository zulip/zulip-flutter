import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';

import 'api/model/model.dart';
import 'main.dart';
import 'store.dart';

/// The font size for message content in a plain unstyled paragraph.
const kBaseFontSize = 14;

/// The entire content of a message, aka its body.
///
/// This does not include metadata like the sender's name and avatar, the time,
/// or the message's status as starred or edited.
class MessageContent extends StatelessWidget {
  const MessageContent({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final fragment =
        HtmlParser(message.content, parseMeta: false).parseFragment();
    return BlockContentList(nodes: fragment.nodes);
  }
}

//
// Block layout.
//

/// A list of DOM nodes to display in block layout.
class BlockContentList extends StatelessWidget {
  const BlockContentList({super.key, required this.nodes});

  final dom.NodeList nodes;

  @override
  Widget build(BuildContext context) {
    final nodes = this.nodes.where(_acceptNode);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ...nodes.map((node) => BlockContentNode(node: node)),
    ]);
  }

  static bool _acceptNode(dom.Node node) {
    if (node is dom.Element) return true;
    // We get a bunch of newline Text nodes between paragraphs.
    // A browser seems to ignore these; let's do the same.
    if (node is dom.Text && (node.text == "\n")) return false;
    // Does any other kind of node occur?  Well, we'd see it below.
    return true;
  }
}

/// A single DOM node to display in block layout.
class BlockContentNode extends StatelessWidget {
  const BlockContentNode({super.key, required this.node});

  final dom.Node node;

  @override
  Widget build(BuildContext context) {
    switch (node.nodeType) {
      case dom.Node.ELEMENT_NODE:
        return _buildElement(node as dom.Element);
      case dom.Node.TEXT_NODE:
        final text = (node as dom.Text).text;
        return _errorText("text: «$text»"); // TODO can this happen?
      default:
        return _errorText(
            "(node of type ${node.nodeType})"); // TODO can this happen?
    }
  }

  Widget _buildElement(dom.Element element) {
    final localName = element.localName;
    final classes = element.classes;

    if (localName == 'p' && classes.isEmpty) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child:
              Text.rich(TextSpan(children: _buildInlineList(element.nodes))));
    }

    if (localName == 'h6' && classes.isEmpty) {
      // TODO h1, h2, h3, h4, h5 -- same except font size
      return Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 5),
          child: Text.rich(TextSpan(
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
              children: _buildInlineList(element.nodes))));
    }

    // TODO ul and ol
    // TODO p+ul and p+ol interactions
    // TODO different item indicators at different levels of nesting

    if (localName == 'blockquote' && classes.isEmpty) {
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
              child: BlockContentList(nodes: element.nodes)));
    }

    if (localName == 'div' &&
        classes.length == 1 &&
        classes.contains('codehilite')) {
      return CodeBlock(divElement: element);
    }

    if (localName == 'div' &&
        classes.length == 1 &&
        classes.contains('message_inline_image')) {
      return MessageImage(divElement: element);
    }

    // TODO handle more types of elements
    return Text.rich(_errorUnimplemented(element));
  }
}

class MessageImage extends StatelessWidget {
  MessageImage({super.key, required this.divElement})
      : assert(divElement.localName == 'div' &&
            divElement.classes.length == 1 &&
            divElement.classes.contains('message_inline_image'));

  final dom.Element divElement;

  @override
  Widget build(BuildContext context) {
    // TODO multiple images in a row
    // TODO image hover animation
    final imgElement = _imgElement();
    if (imgElement == null) return Text.rich(_errorUnimplemented(divElement));

    final src = imgElement.attributes['src'];
    if (src == null) return Text.rich(_errorUnimplemented(divElement));

    final store = PerAccountStoreWidget.of(context);
    final adjustedSrc = rewriteImageUrl(src, store.account);

    return Align(
        alignment: Alignment.centerLeft,
        child: Container(
            height: 100,
            width: 150,
            alignment: Alignment.center,
            color: const Color.fromRGBO(0, 0, 0, 0.03),
            child: Image.network(
              adjustedSrc,
              filterQuality: FilterQuality.medium,
            )));
  }

  dom.Element? _imgElement() {
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
  }
}

class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.divElement});

  final dom.Element divElement;

  @override
  Widget build(BuildContext context) {
    final element = _mainElement();
    if (element == null) return _error();

    final buffer = StringBuffer();
    for (int i = 0; i < element.nodes.length; i++) {
      final child = element.nodes[i];
      if (child is dom.Text) {
        String text = child.text;
        if (i == element.nodes.length - 1) {
          // The HTML tends to have a final newline here.  If included in the
          // [Text], that would make a trailing blank line.  So cut it out.
          text = text.replaceFirst(RegExp(r'\n$'), '');
        }
        buffer.write(text);
      } else if (child is dom.Element && child.localName == 'span') {
        // TODO style the code-highlighting spans
        buffer.write(child.text);
      } else {
        return _error();
      }
    }
    final text = buffer.toString();

    return Container(
        padding: const EdgeInsets.fromLTRB(7, 5, 7, 3),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
                width: 1,
                color: const HSLColor.fromAHSL(0.15, 0, 0, 0).toColor())),
        child: Scrollbar(
            child: SingleChildScrollView(
                primary: true,
                scrollDirection: Axis.horizontal,
                child: Text(text, style: _kCodeStyle))));
  }

  dom.Element? _mainElement() {
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
  }

  Widget _error() => Text.rich(_errorUnimplemented(divElement));
}

//
// Inline layout.
//

List<InlineSpan> _buildInlineList(dom.NodeList nodes) =>
    List.of(nodes.map(_buildInlineNode));

InlineSpan _buildInlineNode(dom.Node node) {
  if (node is dom.Text) {
    return TextSpan(text: node.text);
  }
  if (node is! dom.Element) {
    return TextSpan(
        text: "(unimplemented dom.Node type: ${node.nodeType})",
        style: errorStyle);
  }

  final localName = node.localName;
  final classes = node.classes;
  InlineSpan styled(TextStyle style) =>
      TextSpan(children: _buildInlineList(node.nodes), style: style);

  if (localName == "br" && classes.isEmpty) {
    // Each `<br/>` is followed by a newline, which browsers apparently ignore
    // and our parser doesn't.  So don't do anything here.
    return const TextSpan(text: "");
  }

  if (localName == "strong" && classes.isEmpty) {
    return styled(const TextStyle(fontWeight: FontWeight.w600));
  }
  if (localName == "em" && classes.isEmpty) {
    return styled(const TextStyle(fontStyle: FontStyle.italic));
  }
  if (localName == "code" && classes.isEmpty) {
    return inlineCode(node);
  }

  if (localName == "a" &&
      (classes.isEmpty ||
          (classes.length == 1 &&
              (classes.contains("stream-topic") ||
                  classes.contains("stream"))))) {
    // TODO make link touchable
    return styled(
        TextStyle(color: const HSLColor.fromAHSL(1, 200, 1, 0.4).toColor()));
  }

  if (localName == "span" &&
      (classes.contains("user-mention") ||
          classes.contains("user-group-mention")) &&
      (classes.length == 1 ||
          (classes.length == 2 && classes.contains("silent")))) {
    return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: UserMention(element: node));
  }

  if (localName == "span" &&
      classes.length == 2 &&
      classes.contains("emoji") &&
      classes.every(_emojiClassRegexp.hasMatch)) {
    return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: MessageUnicodeEmoji(element: node));
  }

  if (localName == "img" && classes.contains("emoji") && classes.length == 1) {
    return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: MessageRealmEmoji(element: node));
  }

  return _errorUnimplemented(node);
}

final _emojiClassRegexp = RegExp(r"^emoji(-[0-9a-f]+)?$");

InlineSpan inlineCode(dom.Element element) {
  assert(element.localName == 'code' && element.classes.isEmpty);

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

  return TextSpan(children: [
    // TODO(selection): exclude these brackets from text selection
    const TextSpan(text: _kInlineCodeLeftBracket),
    TextSpan(style: _kCodeStyle, children: _buildInlineList(element.nodes)),
    const TextSpan(text: _kInlineCodeRightBracket),
  ]);
}

const _kCodeStyle = TextStyle(
  backgroundColor: Color.fromRGBO(255, 255, 255, 1),
  fontSize: 0.825 * kBaseFontSize,
  fontFamily: "Source Code Pro", // TODO supply font
  fontFamilyFallback: ["monospace"],
);

const _kInlineCodeLeftBracket = '⸤';
const _kInlineCodeRightBracket = '⸣';
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
  const UserMention({super.key, required this.element});

  final dom.Element element;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: _kDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 0.2 * kBaseFontSize),
        child: Text.rich(TextSpan(children: _buildInlineList(element.nodes))));
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
  MessageUnicodeEmoji({super.key, required this.element})
      : assert(element.localName == 'span' &&
            element.classes.length == 2 &&
            element.classes.contains('emoji'));

  final dom.Element element;

  @override
  Widget build(BuildContext context) {
    // TODO get spritesheet and show actual emoji glyph
    final text = element.text;
    return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            color: Colors.white, border: Border.all(color: Colors.purple)),
        child: Text(text));
  }
}

class MessageRealmEmoji extends StatelessWidget {
  MessageRealmEmoji({super.key, required this.element})
      : assert(element.localName == 'img' &&
            element.classes.length == 1 &&
            element.classes.contains('emoji'));

  final dom.Element element;

  @override
  Widget build(BuildContext context) {
    // TODO show actual emoji image
    final alt = element.attributes['alt'];
    if (alt == null) return Text.rich(_errorUnimplemented(element));
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

Widget _errorText(String text) => Text(text, style: errorStyle);

InlineSpan _errorUnimplemented(dom.Element element) => TextSpan(children: [
      const TextSpan(text: "(unimplemented:", style: errorStyle),
      TextSpan(text: element.outerHtml, style: errorCodeStyle),
      const TextSpan(text: ")", style: errorStyle),
    ]);

const errorStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.red);

const errorCodeStyle = TextStyle(color: Colors.red, fontFamily: 'monospace');
