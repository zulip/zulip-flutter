import 'package:html/dom.dart' as dom;

import 'content.dart';

class KatexParser {
  List<KatexSpanNode> parseKatexHTML(dom.Element element) {
    assert(element.localName == 'span');
    assert(element.className == 'katex-html');
    return _parseChildSpans(element);
  }

  List<KatexSpanNode> _parseChildSpans(dom.Element element) {
    return List.unmodifiable(element.nodes.map((node) {
      if (node is! dom.Element) throw KatexHtmlParseError();
      return _parseSpan(node);
    }));
  }

  KatexSpanNode _parseSpan(dom.Element element) {
    String? text;
    List<KatexSpanNode>? spans;
    if (element.nodes case [dom.Text(data: final data)]) {
      text = data;
    } else {
      spans = _parseChildSpans(element);
    }
    if (text == null && spans == null) throw KatexHtmlParseError();

    return KatexSpanNode(
      text: text,
      nodes: spans ?? const []);
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
