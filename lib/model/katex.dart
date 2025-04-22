import 'package:flutter/foundation.dart';
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
    final flagForceRenderKatex =
      globalSettings.getBool(BoolGlobalSetting.forceRenderKatex);

    List<KatexNode>? nodes;
    if (flagRenderKatex) {
      final parser = _KatexParser();
      try {
        nodes = parser.parseKatexHtml(katexHtmlElement);
      } on KatexHtmlParseError catch (e, st) {
        assert(debugLog('$e\n$st'));
      }

      if (parser.hasError && !flagForceRenderKatex) {
        nodes = null;
      }
    }

    return MathParserResult(nodes: nodes, texSource: texSource);
  } else {
    return null;
  }
}

class _KatexParser {
  bool get hasError => _hasError;
  bool _hasError = false;

  void _logError(String message) {
    assert(debugLog(message));
    _hasError = true;
  }

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

  static final _resetSizeClassRegExp = RegExp(r'^reset-size(\d\d?)$');
  static final _sizeClassRegExp = RegExp(r'^size(\d\d?)$');

  KatexNode _parseSpan(dom.Element element) {
    // TODO maybe check if the sequence of ancestors matter for spans.

    final spanClasses = List<String>.unmodifiable(element.className.split(' '));

    // Aggregate the CSS styles that apply, in the same order as the CSS
    // classes specified for this span, mimicking the behaviour on web.
    //
    // Each case in the switch block below is a separate CSS class definition
    // in the same order as in katex.scss :
    //   https://github.com/KaTeX/KaTeX/blob/2fe1941b/src/styles/katex.scss
    // A copy of class definition (where possible) is accompanied in a comment
    // with each case statement to keep track of updates.
    var styles = KatexSpanStyles();
    var index = 0;
    while (index < spanClasses.length) {
      final spanClass = spanClasses[index++];
      switch (spanClass) {
        case 'base':
          // .base { ... }
          // Do nothing, it has properties that don't need special handling.
          break;

        case 'strut':
          // .strut { ... }
          // Do nothing, it has properties that don't need special handling.
          break;

        case 'textbf':
          // .textbf { font-weight: bold; }
          styles.fontWeight = KatexSpanFontWeight.bold;

        case 'textit':
          // .textit { font-style: italic; }
          styles.fontStyle = KatexSpanFontStyle.italic;

        case 'textrm':
          // .textrm { font-family: KaTeX_Main; }
          styles.fontFamily = 'KaTeX_Main';

        // case 'textsf':
        //   // .textsf { font-family: KaTeX_SansSerif; }
        // This CSS rule has no effect, because the other `.textsf` rule below
        // has the exact same list of declarations.  Handle it there instead.

        case 'texttt':
          // .texttt { font-family: KaTeX_Typewriter; }
          styles.fontFamily = 'KaTeX_Typewriter';

        case 'mathnormal':
          // .mathnormal { font-family: KaTeX_Math; font-style: italic; }
          styles.fontFamily = 'KaTeX_Math';
          styles.fontStyle = KatexSpanFontStyle.italic;

        case 'mathit':
          // .mathit { font-family: KaTeX_Main; font-style: italic; }
          styles.fontFamily = 'KaTeX_Main';
          styles.fontStyle = KatexSpanFontStyle.italic;

        case 'mathrm':
          // .mathrm { font-style: normal; }
          styles.fontStyle = KatexSpanFontStyle.normal;

        case 'mathbf':
          // .mathbf { font-family: KaTeX_Main; font-weight: bold; }
          styles.fontFamily = 'KaTeX_Main';
          styles.fontWeight = KatexSpanFontWeight.bold;

        case 'boldsymbol':
          // .boldsymbol { font-family: KaTeX_Math; font-weight: bold; font-style: italic; }
          styles.fontFamily = 'KaTeX_Math';
          styles.fontWeight = KatexSpanFontWeight.bold;
          styles.fontStyle = KatexSpanFontStyle.italic;

        case 'amsrm':
          // .amsrm { font-family: KaTeX_AMS; }
          styles.fontFamily = 'KaTeX_AMS';

        case 'mathbb':
        case 'textbb':
          // .mathbb,
          // .textbb { font-family: KaTeX_AMS; }
          styles.fontFamily = 'KaTeX_AMS';

        case 'mathcal':
          // .mathcal { font-family: KaTeX_Caligraphic; }
          styles.fontFamily = 'KaTeX_Caligraphic';

        case 'mathfrak':
        case 'textfrak':
          // .mathfrak,
          // .textfrak { font-family: KaTeX_Fraktur; }
          styles.fontFamily = 'KaTeX_Fraktur';

        case 'mathboldfrak':
        case 'textboldfrak':
          // .mathboldfrak,
          // .textboldfrak { font-family: KaTeX_Fraktur; font-weight: bold; }
          styles.fontFamily = 'KaTeX_Fraktur';
          styles.fontWeight = KatexSpanFontWeight.bold;

        case 'mathtt':
          // .mathtt { font-family: KaTeX_Typewriter; }
          styles.fontFamily = 'KaTeX_Typewriter';

        case 'mathscr':
        case 'textscr':
          // .mathscr,
          // .textscr { font-family: KaTeX_Script; }
          styles.fontFamily = 'KaTeX_Script';

        case 'mathsf':
        case 'textsf':
          // .mathsf,
          // .textsf { font-family: KaTeX_SansSerif; }
          styles.fontFamily = 'KaTeX_SansSerif';

        case 'mathboldsf':
        case 'textboldsf':
          // .mathboldsf,
          // .textboldsf { font-family: KaTeX_SansSerif; font-weight: bold; }
          styles.fontFamily = 'KaTeX_SansSerif';
          styles.fontWeight = KatexSpanFontWeight.bold;

        case 'mathsfit':
        case 'mathitsf':
        case 'textitsf':
          // .mathsfit,
          // .mathitsf,
          // .textitsf { font-family: KaTeX_SansSerif; font-style: italic; }
          styles.fontFamily = 'KaTeX_SansSerif';
          styles.fontStyle = KatexSpanFontStyle.italic;

        case 'mainrm':
          // .mainrm { font-family: KaTeX_Main; font-style: normal; }
          styles.fontFamily = 'KaTeX_Main';
          styles.fontStyle = KatexSpanFontStyle.normal;

        // TODO handle skipped class declarations between .mainrm and
        //   .sizing .

        case 'sizing':
        case 'fontsize-ensurer':
          // .sizing,
          // .fontsize-ensurer { ... }
          if (index + 2 > spanClasses.length) throw KatexHtmlParseError();
          final resetSizeClass = spanClasses[index++];
          final sizeClass = spanClasses[index++];

          final resetSizeClassSuffix = _resetSizeClassRegExp.firstMatch(resetSizeClass)?.group(1);
          if (resetSizeClassSuffix == null) throw KatexHtmlParseError();
          final sizeClassSuffix = _sizeClassRegExp.firstMatch(sizeClass)?.group(1);
          if (sizeClassSuffix == null) throw KatexHtmlParseError();

          const sizes = <double>[0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.2, 1.44, 1.728, 2.074, 2.488];

          final resetSizeIdx = int.parse(resetSizeClassSuffix, radix: 10);
          final sizeIdx = int.parse(sizeClassSuffix, radix: 10);

          // These indexes start at 1.
          if (resetSizeIdx > sizes.length) throw KatexHtmlParseError();
          if (sizeIdx > sizes.length) throw KatexHtmlParseError();
          styles.fontSizeEm = sizes[sizeIdx - 1] / sizes[resetSizeIdx - 1];

        case 'delimsizing':
          // .delimsizing { ... }
          if (index + 1 > spanClasses.length) throw KatexHtmlParseError();
          switch (spanClasses[index++]) {
            case 'size1':
              styles.fontFamily = 'KaTeX_Size1';
            case 'size2':
              styles.fontFamily = 'KaTeX_Size2';
            case 'size3':
              styles.fontFamily = 'KaTeX_Size3';
            case 'size4':
              styles.fontFamily = 'KaTeX_Size4';

            case 'mult':
              // TODO handle nested spans with `.delim-size{1,4}` class.
              throw KatexHtmlParseError();

            default:
              throw KatexHtmlParseError();
          }

        // TODO handle .nulldelimiter and .delimcenter .

        case 'op-symbol':
          // .op-symbol { ... }
          if (index + 1 > spanClasses.length) throw KatexHtmlParseError();
          switch (spanClasses[index++]) {
            case 'small-op':
              styles.fontFamily = 'KaTeX_Size1';
            case 'large-op':
              styles.fontFamily = 'KaTeX_Size2';
            default:
              throw KatexHtmlParseError();
          }

        // TODO handle more classes from katex.scss

        case 'mord':
        case 'mopen':
          // Ignore these classes because they don't have a CSS definition
          // in katex.scss, but we encounter them in the generated HTML.
          break;

        default:
          _logError('KaTeX: Unsupported CSS class: $spanClass');
      }
    }

    String? text;
    List<KatexNode>? spans;
    if (element.nodes case [dom.Text(:final data)]) {
      text = data;
    } else {
      spans = _parseChildSpans(element);
    }
    if (text == null && spans == null) throw KatexHtmlParseError();

    return KatexNode(
      styles: styles,
      text: text,
      nodes: spans);
  }
}

enum KatexSpanFontWeight {
  bold,
}

enum KatexSpanFontStyle {
  normal,
  italic,
}

enum KatexSpanTextAlign {
  left,
  center,
  right,
}

class KatexSpanStyles {
  String? fontFamily;
  double? fontSizeEm;
  KatexSpanFontWeight? fontWeight;
  KatexSpanFontStyle? fontStyle;
  KatexSpanTextAlign? textAlign;

  KatexSpanStyles({
    this.fontFamily,
    this.fontSizeEm,
    this.fontWeight,
    this.fontStyle,
    this.textAlign,
  });

  @override
  int get hashCode => Object.hash(
    'KatexSpanStyles',
    fontFamily,
    fontSizeEm,
    fontWeight,
    fontStyle,
    textAlign,
  );

  @override
  bool operator ==(Object other) {
    return other is KatexSpanStyles &&
      other.fontFamily == fontFamily &&
      other.fontSizeEm == fontSizeEm &&
      other.fontWeight == fontWeight &&
      other.fontStyle == fontStyle &&
      other.textAlign == textAlign;
  }

  @override
  String toString() {
    final args = <String>[];
    if (fontFamily != null) args.add('fontFamily: $fontFamily');
    if (fontSizeEm != null) args.add('fontSizeEm: $fontSizeEm');
    if (fontWeight != null) args.add('fontWeight: $fontWeight');
    if (fontStyle != null) args.add('fontStyle: $fontStyle');
    if (textAlign != null) args.add('textAlign: $textAlign');
    return '${objectRuntimeType(this, 'KatexSpanStyles')}(${args.join(', ')})';
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
