import 'package:html/dom.dart' as dom;

import 'content.dart';

class KatexParser {
  List<KatexNode> parseKatexHTML(dom.Element element) {
    assert(element.localName == 'span');
    assert(element.className == 'katex-html');
    return _parseChildSpans(element);
  }

  List<KatexNode> _parseChildSpans(dom.Element element) {
    return List.unmodifiable(element.nodes.map((node) {
      if (node case dom.Element(localName: 'span')) {
        return _parseSpan(node);
      } else {
        throw KatexHtmlParseError();
      }
    }));
  }

  KatexNode _parseSpan(dom.Element element) {
    String? text;
    List<KatexNode>? spans;
    if (element.nodes case [dom.Text(data: final data)]) {
      text = data;
    } else {
      spans = _parseChildSpans(element);
    }
    if (text == null && spans == null) throw KatexHtmlParseError();

    return KatexNode(
      text: text,
      nodes: spans);
  }
}

class KatexHtmlParseError extends Error {
  final String? message;
  KatexHtmlParseError([this.message]);

  @override
  String toString() {
    if (message != null) {
      return 'Katex HTML parse error: $message';
    }
    return 'Katex HTML parse error';
  }
}
