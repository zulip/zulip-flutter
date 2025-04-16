import 'package:csslib/parser.dart' as css_parser;
import 'package:csslib/visitor.dart' as css_visitor;
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;

import '../log.dart';
import 'binding.dart';
import 'content.dart';
import 'settings.dart';

class MathParserResult {
  const MathParserResult({
    required this.nodes,
    required this.texSource,
  });

  /// Parsed KaTeX node tree to be used for rendering the KaTeX content.
  ///
  /// It will be null if the parser encounters an unsupported HTML element or
  /// CSS style, indicating that the widget should render the [texSource] as a
  /// fallback instead.
  final List<KatexNode>? nodes;

  final String texSource;
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
        nodes = parser.parseKatexHTML(katexHtmlElement);
      } on KatexHtmlParseError catch (e, st) {
        assert(debugLog('$e\n$st'));
      }

      if (parser.debugHasError && !flagForceRenderKatex) {
        nodes = null;
      }
    }

    return MathParserResult(nodes: nodes, texSource: texSource);
  } else {
    return null;
  }
}

class _KatexParser {
  bool get debugHasError => _debugHasError;
  bool _debugHasError = false;

  void _logError(String message) {
    assert(debugLog(message));
    _debugHasError = true;
  }

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

  static final _resetSizeClassRegExp = RegExp(r'^reset-size(\d\d?)$');
  static final _sizeClassRegExp = RegExp(r'^size(\d\d?)$');

  KatexNode _parseSpan(dom.Element element) {
    // TODO maybe check if the sequence of ancestors matter for spans.

    final spanClasses = List<String>.unmodifiable(element.className.split(' '));

    // Aggregate the CSS styles that apply, in the same order as the CSS
    // classes specified for this span, mimicking the behaviour on web.
    //
    // Each case in the switch blocks below is a separate CSS class definition
    // in the same order as in katex.scss :
    //   https://github.com/KaTeX/KaTeX/blob/2fe1941b/src/styles/katex.scss
    // A copy of class definition (where possible) is accompanied in a comment
    // with each case statement to keep track of updates.
    var styles = KatexSpanStyles();
    var index = 0;
    while (index < spanClasses.length) {
      var classFound = false;

      final spanClass = spanClasses[index];
      switch (spanClass) {
        case 'base':
          // .base { ... }
          // Do nothing, it has properties that don't need special handling.
          classFound = true;

        case 'strut':
          // .strut { ... }
          // Do nothing, it has properties that don't need special handling.
          classFound = true;

        case 'textbf':
          // .textbf { font-weight: bold; }
          styles.fontWeight = KatexSpanFontWeight.bold;
          classFound = true;

        case 'textit':
          // .textit { font-style: italic; }
          styles.fontStyle = KatexSpanFontStyle.italic;
          classFound = true;

        case 'textrm':
          // .textrm { font-family: KaTeX_Main; }
          styles.fontFamily = 'KaTeX_Main';
          classFound = true;

        case 'textsf':
          // .textsf { font-family: KaTeX_SansSerif; }
          styles.fontFamily = 'KaTeX_SansSerif';
          classFound = true;

        case 'texttt':
          // .texttt { font-family: KaTeX_Typewriter; }
          styles.fontFamily = 'KaTeX_Typewriter';
          classFound = true;

        case 'mathnormal':
          // .mathnormal { font-family: KaTeX_Math; font-style: italic; }
          styles.fontFamily = 'KaTeX_Math';
          styles.fontStyle = KatexSpanFontStyle.italic;
          classFound = true;

        case 'mathit':
          // .mathit { font-family: KaTeX_Main; font-style: italic; }
          styles.fontFamily = 'KaTeX_Main';
          styles.fontStyle = KatexSpanFontStyle.italic;
          classFound = true;

        case 'mathrm':
          // .mathrm { font-style: normal; }
          styles.fontStyle = KatexSpanFontStyle.normal;
          classFound = true;

        case 'mathbf':
          // .mathbf { font-family: KaTeX_Main; font-weight: bold; }
          styles.fontFamily = 'KaTeX_Main';
          styles.fontWeight = KatexSpanFontWeight.bold;
          classFound = true;

        case 'boldsymbol':
          // .boldsymbol { font-family: KaTeX_Math; font-weight: bold; font-style: italic; }
          styles.fontFamily = 'KaTeX_Math';
          styles.fontWeight = KatexSpanFontWeight.bold;
          styles.fontStyle = KatexSpanFontStyle.italic;
          classFound = true;

        case 'amsrm':
          // .amsrm { font-family: KaTeX_AMS; }
          styles.fontFamily = 'KaTeX_AMS';
          classFound = true;

        case 'mathbb':
        case 'textbb':
          // .mathbb,
          // .textbb { font-family: KaTeX_AMS; }
          styles.fontFamily = 'KaTeX_AMS';
          classFound = true;

        case 'mathcal':
          // .mathcal { font-family: KaTeX_Caligraphic; }
          styles.fontFamily = 'KaTeX_Caligraphic';
          classFound = true;

        case 'mathfrak':
        case 'textfrak':
          // .mathfrak,
          // .textfrak { font-family: KaTeX_Fraktur; }
          styles.fontFamily = 'KaTeX_Fraktur';
          classFound = true;

        case 'mathboldfrak':
        case 'textboldfrak':
          // .mathboldfrak,
          // .textboldfrak { font-family: KaTeX_Fraktur; font-weight: bold; }
          styles.fontFamily = 'KaTeX_Fraktur';
          styles.fontWeight = KatexSpanFontWeight.bold;
          classFound = true;

        case 'mathtt':
          // .mathtt { font-family: KaTeX_Typewriter; }
          styles.fontFamily = 'KaTeX_Typewriter';
          classFound = true;

        case 'mathscr':
        case 'textscr':
          // .mathscr,
          // .textscr { font-family: KaTeX_Script; }
          styles.fontFamily = 'KaTeX_Script';
          classFound = true;
      }

      // Workaround the duplicated case statement with a new switch block,
      // to preserve the same order and to keep the cases mirroring the CSS
      // definitions in katex.scss .
      switch (spanClass) {
        case 'mathsf':
        case 'textsf':
          // .mathsf,
          // .textsf { font-family: KaTeX_SansSerif; }
          styles.fontFamily = 'KaTeX_SansSerif';
          classFound = true;

        case 'mathboldsf':
        case 'textboldsf':
          // .mathboldsf,
          // .textboldsf { font-family: KaTeX_SansSerif; font-weight: bold; }
          styles.fontFamily = 'KaTeX_SansSerif';
          styles.fontWeight = KatexSpanFontWeight.bold;
          classFound = true;

        case 'mathsfit':
        case 'mathitsf':
        case 'textitsf':
          // .mathsfit,
          // .mathitsf,
          // .textitsf { font-family: KaTeX_SansSerif; font-style: italic; }
          styles.fontFamily = 'KaTeX_SansSerif';
          styles.fontStyle = KatexSpanFontStyle.italic;
          classFound = true;

        case 'mainrm':
          // .mainrm { font-family: KaTeX_Main; font-style: normal; }
          styles.fontFamily = 'KaTeX_Main';
          styles.fontStyle = KatexSpanFontStyle.normal;
          classFound = true;

        // TODO handle skipped class declarations between .mainrm and
        //   .sizing .

        case 'sizing':
        case 'fontsize-ensurer':
          // .sizing,
          // .fontsize-ensurer { ... }
          if (index + 2 < spanClass.length) {
            final resetSizeClass = spanClasses[index + 1];
            final sizeClass = spanClasses[index + 2];

            final resetSizeClassSuffix =_resetSizeClassRegExp.firstMatch(resetSizeClass)?.group(1);
            final sizeClassSuffix = _sizeClassRegExp.firstMatch(sizeClass)?.group(1);

            if (resetSizeClassSuffix != null && sizeClassSuffix != null) {
              const sizes = <double>[0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.2, 1.44, 1.728, 2.074, 2.488];

              final resetSizeIdx = int.parse(resetSizeClassSuffix, radix: 10);
              final sizeIdx = int.parse(sizeClassSuffix, radix: 10);

              // These indexes start at 1.
              if (resetSizeIdx <= sizes.length && sizeIdx <= sizes.length) {
                styles.fontSizeEm = sizes[sizeIdx - 1] / sizes[resetSizeIdx - 1];
                index += 3;
                continue;
              }
            }
          }

          // Should be unreachable.
          throw KatexHtmlParseError();

        case 'delimsizing':
          // .delimsizing { ... }
          if (index + 1 < spanClasses.length) {
            final nextClass = spanClasses[index + 1];
            switch (nextClass) {
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
                break;
            }

            if (styles.fontFamily == null) throw KatexHtmlParseError();

            index += 2;
            continue;
          }

          // Should be unreachable.
          throw KatexHtmlParseError();

        // TODO handle .nulldelimiter and .delimcenter .

        case 'op-symbol':
          // .op-symbol { ... }
          if (index + 1 < spanClasses.length) {
           final nextClass = spanClasses[index + 1];
            switch (nextClass) {
              case 'small-op':
                styles.fontFamily = 'KaTeX_Size1';
              case 'large-op':
                styles.fontFamily = 'KaTeX_Size2';
            }
            if (styles.fontFamily == null) throw KatexHtmlParseError();

            index += 2;
            continue;
          }

          // Should be unreachable.
          throw KatexHtmlParseError();

        // TODO handle more classes from katex.scss
      }

      // Ignore these classes because they don't have a CSS definition
      // in katex.scss, but we encounter them in the generated HTML.
      switch (spanClass) {
        case 'mord':
        case 'mopen':
          classFound = true;
      }

      if (!classFound) _logError('KaTeX: Unsupported CSS class: $spanClass');

      index++;
    }

    String? text;
    List<KatexNode>? spans;
    if (element.nodes case [dom.Text(:final data)]) {
      text = data;
    } else {
      spans = _parseChildSpans(element);
    }
    if (text == null && spans == null) throw KatexHtmlParseError();

    final inlineStyles = _parseSpanInlineStyles(element);

    return KatexNode(
      styles: inlineStyles != null
        ? styles.merge(inlineStyles)
        : styles,
      text: text,
      nodes: spans);
  }

  KatexSpanStyles? _parseSpanInlineStyles(dom.Element element) {
    if (element.attributes case {'style': final styleStr}) {
      // `package:csslib` doesn't seem to have a way to parse inline styles:
      //   https://github.com/dart-lang/tools/issues/1173
      // So, workaround that by wrapping it in a universal declaration.
      final stylesheet = css_parser.parse('*{$styleStr}');
      if (stylesheet.topLevels case [css_visitor.RuleSet() && final rule]) {
        double? heightEm;
        double? verticalAlignEm;

        for (final declaration in rule.declarationGroup.declarations) {
          if (declaration case css_visitor.Declaration(
            :final property,
            expression: css_visitor.Expressions(
              expressions: [css_visitor.Expression() && final expression]),
          )) {
            switch (property) {
              case 'height':
                heightEm = _getEm(expression);
                if (heightEm != null) continue;

              case 'vertical-align':
                verticalAlignEm = _getEm(expression);
                if (verticalAlignEm != null) continue;
            }

            // TODO handle more CSS properties
            _logError('KaTeX: Unsupported CSS property: $property of '
              'type ${expression.runtimeType}');
          } else {
            throw KatexHtmlParseError();
          }
        }

        return KatexSpanStyles(
          heightEm: heightEm,
          verticalAlignEm: verticalAlignEm,
        );
      } else {
        throw KatexHtmlParseError();
      }
    }
    return null;
  }

  double? _getEm(css_visitor.Expression expression) {
    if (expression is css_visitor.EmTerm && expression.value is num) {
      return (expression.value as num).toDouble();
    }
    return null;
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
  double? heightEm;
  double? verticalAlignEm;

  String? fontFamily;
  double? fontSizeEm;
  KatexSpanFontStyle? fontStyle;
  KatexSpanFontWeight? fontWeight;
  KatexSpanTextAlign? textAlign;

  KatexSpanStyles({
    this.heightEm,
    this.verticalAlignEm,
    this.fontFamily,
    this.fontSizeEm,
    this.fontStyle,
    this.fontWeight,
    this.textAlign,
  });

  @override
  int get hashCode => Object.hash(
    'KatexSpanStyles',
    heightEm,
    verticalAlignEm,
    fontFamily,
    fontSizeEm,
    fontStyle,
    fontWeight,
    textAlign,
  );

  @override
  bool operator ==(Object other) {
    return other is KatexSpanStyles &&
      other.heightEm == heightEm &&
      other.verticalAlignEm == verticalAlignEm &&
      other.fontFamily == fontFamily &&
      other.fontSizeEm == fontSizeEm &&
      other.fontStyle == fontStyle &&
      other.fontWeight == fontWeight &&
      other.textAlign == textAlign;
  }

  static final _zero = KatexSpanStyles();

  @override
  String toString() {
    if (this == _zero) return '${objectRuntimeType(this, 'KatexSpanStyles')}()';

    final args = <String>[];
    if (heightEm != null) args.add('heightEm: $heightEm');
    if (verticalAlignEm != null) args.add('verticalAlignEm: $verticalAlignEm');
    if (fontFamily != null) args.add('fontFamily: $fontFamily');
    if (fontSizeEm != null) args.add('fontSizeEm: $fontSizeEm');
    if (fontStyle != null) args.add('fontStyle: $fontStyle');
    if (fontWeight != null) args.add('fontWeight: $fontWeight');
    if (textAlign != null) args.add('textAlign: $textAlign');
    return '${objectRuntimeType(this, 'KatexSpanStyles')}(${args.join(', ')})';
  }

  KatexSpanStyles merge(KatexSpanStyles other) {
    return KatexSpanStyles(
      heightEm: other.heightEm ?? heightEm,
      verticalAlignEm: other.verticalAlignEm ?? verticalAlignEm,
      fontFamily: other.fontFamily ?? fontFamily,
      fontSizeEm: other.fontSizeEm ?? fontSizeEm,
      fontStyle: other.fontStyle ?? fontStyle,
      fontWeight: other.fontWeight ?? fontWeight,
      textAlign: other.textAlign ?? textAlign,
    );
  }
}

class KatexSpanStylesProperty extends DiagnosticsProperty<KatexSpanStyles> {
  KatexSpanStylesProperty(super.name, super.value);
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
