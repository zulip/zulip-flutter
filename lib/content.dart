import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';

import 'api/model/model.dart';

class MessageContent extends StatelessWidget {
  const MessageContent({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final fragment =
        HtmlParser(message.content, parseMeta: false).parseFragment();
    return BlockContent(nodes: fragment.nodes);
    // Text(message.content),
  }
}

class BlockContent extends StatelessWidget {
  const BlockContent({super.key, required this.nodes});

  final dom.NodeList nodes;

  @override
  Widget build(BuildContext context) {
    final nodes = this.nodes.where(_acceptNode);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...nodes.map(_buildDirectChildNode),
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

  Widget _buildDirectChildNode(dom.Node node) {
    switch (node.nodeType) {
      case dom.Node.ELEMENT_NODE:
        return _buildDirectChildElement(node as dom.Element);
      case dom.Node.TEXT_NODE:
        final text = (node as dom.Text).text;
        return _errorText("text: «$text»"); // TODO can this happen?
      default:
        return _errorText(
            "(node of type ${node.nodeType})"); // TODO can this happen?
    }
  }

  Widget _buildDirectChildElement(dom.Element element) {
    if (element.localName == 'p' && element.classes.isEmpty) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child:
              Text.rich(TextSpan(children: _buildInlineList(element.nodes))));
    }

    if (element.localName == 'blockquote' && element.classes.isEmpty) {
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
              child: BlockContent(nodes: element.nodes)));
    }

    // TODO handle more types of elements
    return Text.rich(_errorUnimplemented(element));
  }
}

List<InlineSpan> _buildInlineList(dom.NodeList nodes) =>
    List.of(nodes.map(_buildInlineNode));

InlineSpan _buildInlineNode(dom.Node node) {
  if (node is dom.Text) return TextSpan(text: node.text);
  if (node is! dom.Element) {
    return TextSpan(
        text: "(unimplemented dom.Node type: ${node.nodeType})",
        style: errorStyle);
  }

  InlineSpan styled(TextStyle style) =>
      TextSpan(children: _buildInlineList(node.nodes), style: style);

  if (node.localName == "br" && node.classes.isEmpty) {
    // Each `<br/>` is followed by a newline, which browsers apparently ignore
    // and our parser doesn't.  So don't do anything here.
    return const TextSpan(text: "");
  }
  if (node.localName == "strong" && node.classes.isEmpty) {
    return styled(const TextStyle(fontWeight: FontWeight.w600));
  }
  if (node.localName == "code" && node.classes.isEmpty) {
    // TODO `code` elements: border, padding; shrink font size; set bidi
    return styled(const TextStyle(
        backgroundColor: Color.fromRGBO(255, 255, 255, 1),
        fontFamily: "Source Code Pro", // TODO supply font
        fontFamilyFallback: ["monospace"]));
  }
  if (node.localName == "a" && node.classes.isEmpty) {
    // TODO make link touchable
    return styled(
        TextStyle(color: const HSLColor.fromAHSL(1, 200, 1, 0.4).toColor()));
  }
  if (node.localName == "span" &&
      ((node.classes.length == 1 && node.classes.contains("user-mention")) ||
          (node.classes.length == 2 &&
              node.classes.containsAll(["user-mention", "silent"])))) {
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

Widget _errorText(String text) => Text(text, style: errorStyle);

InlineSpan _errorUnimplemented(dom.Element element) => TextSpan(children: [
      const TextSpan(text: "(unimplemented:", style: errorStyle),
      TextSpan(text: element.outerHtml, style: errorCodeStyle),
      const TextSpan(text: ")", style: errorStyle),
    ]);

const errorStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.red);

const errorCodeStyle = TextStyle(color: Colors.red, fontFamily: 'monospace');
