import 'package:html/dom.dart' as dom;

import '../log.dart';
import 'binding.dart';
import 'content.dart';
import 'settings.dart';

class MathParserResult {
  const MathParserResult({
    required this.texSource,
    required this.nodes,
  });

  final String texSource;

  /// Parsed KaTeX node tree to be used for rendering the KaTeX content.
  ///
  /// It will be null if the parser encounters an unsupported HTML element or
  /// CSS style, indicating that the widget should render the [texSource] as a
  /// fallback instead.
  final List<KatexNode>? nodes;
}

/// Parses the HTML spans containing KaTeX HTML tree.
///
/// The element should be either `<span class="katex">` if parsing
/// inline content, otherwise `<span class="katex-display">` when
/// parsing block content.
///
/// Returns null if it encounters an unexpected root KaTeX HTML element.
MathParserResult? parseMath(dom.Element element, { required bool block }) {
  final dom.Element katexElement;
  if (!block) {
    assert(element.localName == 'span' && element.className == 'katex');

    katexElement = element;
  } else {
    assert(element.localName == 'span' && element.className == 'katex-display');

    if (element.nodes case [
      dom.Element(localName: 'span', className: 'katex') && final child,
    ]) {
      katexElement = child;
    } else {
      return null;
    }
  }

  if (katexElement.nodes case [
    dom.Element(localName: 'span', className: 'katex-mathml', nodes: [
      dom.Element(
        localName: 'math',
        namespaceUri: 'http://www.w3.org/1998/Math/MathML')
          && final mathElement,
    ]),
    dom.Element(localName: 'span', className: 'katex-html', nodes: [...])
      && final katexHtmlElement,
  ]) {
    if (mathElement.attributes['display'] != (block ? 'block' : null)) {
      return null;
    }

    final String texSource;
    if (mathElement.nodes case [
      dom.Element(localName: 'semantics', nodes: [
        ...,
        dom.Element(
          localName: 'annotation',
          attributes: {'encoding': 'application/x-tex'},
          :final text),
      ]),
    ]) {
      texSource = text.trim();
    } else {
      return null;
    }

    // The GlobalStore should be ready well before we reach the
    // content parsing stage here, thus the `!` here.
    final globalStore = ZulipBinding.instance.getGlobalStoreSync()!;
    final globalSettings = globalStore.settings;
    final flagRenderKatex =
      globalSettings.getBool(BoolGlobalSetting.renderKatex);

    List<KatexNode>? nodes;
    if (flagRenderKatex) {
      try {
        nodes = _KatexParser().parseKatexHtml(katexHtmlElement);
      } on KatexHtmlParseError catch (e, st) {
        assert(debugLog('$e\n$st'));
      }
    }

    return MathParserResult(nodes: nodes, texSource: texSource);
  } else {
    return null;
  }
}

class _KatexParser {
  List<KatexNode> parseKatexHtml(dom.Element element) {
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
    if (element.nodes case [dom.Text(:final data)]) {
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
