import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';

import 'api/model/model.dart';

/// The entire content of a message, aka its body.
///
/// This does not include metadata like the sender's name and avatar, the time,
/// or the message's status as starred or edited.
class MessageContent extends StatelessWidget {
  const MessageContent({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    // if (kDebugMode && message.content.contains("Git smudge")) {
    //   // TODO debug mojibake: we get UTF-8 code units interpreted as code points.
    //   //   E.g., U+2019 has UTF-8 encoding b'\xe2\x80\x99', and it becomes
    //   //   U+00E2, U+0080, U+0099.  Example message:
    //   //     https://chat.zulip.org/#narrow/near/1481289
    //   //   It's already wrong at this point, though -- it's not the parser's fault.
    //   print(message.content);
    //   print(message.content.codeUnits);
    // }
    final fragment =
        HtmlParser(message.content, parseMeta: false).parseFragment();
    return BlockContentList(nodes: fragment.nodes);
    // Text(message.content),
  }
}

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

    // TODO handle more types of elements
    return Text.rich(_errorUnimplemented(element));
  }
}

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
    // TODO `code` elements: border, padding; shrink font size; set bidi
    return styled(const TextStyle(
        backgroundColor: Color.fromRGBO(255, 255, 255, 1),
        fontFamily: "Source Code Pro", // TODO supply font
        fontFamilyFallback: ["monospace"]));
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
  return _errorUnimplemented(node);
}

class UserMention extends StatelessWidget {
  const UserMention({super.key, required this.element});

  final dom.Element element;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: _kDecoration,
        padding: const EdgeInsets.all(2),
        child: Text.rich(TextSpan(children: _buildInlineList(element.nodes))));
  }

  static get _kDecoration => BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color.fromRGBO(0, 0, 0, 0.1), Color.fromRGBO(0, 0, 0, 0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter),
      border: Border.all(
          color: const Color.fromRGBO(0xcc, 0xcc, 0xcc, 1), width: 1.1),
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

class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.divElement});

  final dom.Element divElement;

  @override
  Widget build(BuildContext context) {
    final element = _mainElement();
    if (element == null) return _error();

    final buffer = StringBuffer();
    for (final child in element.nodes) {
      if (child is dom.Text) {
        buffer.write(child.text);
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
        child: Text(text,
            style: const TextStyle(
                fontFamily: 'Source Code Pro',
                fontFamilyFallback: ['monospace'])));
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

Widget _errorText(String text) => Text(text, style: errorStyle);

InlineSpan _errorUnimplemented(dom.Element element) => TextSpan(children: [
      const TextSpan(text: "(unimplemented:", style: errorStyle),
      TextSpan(text: element.outerHtml, style: errorCodeStyle),
      const TextSpan(text: ")", style: errorStyle),
    ]);

const errorStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.red);

const errorCodeStyle = TextStyle(color: Colors.red, fontFamily: 'monospace');
