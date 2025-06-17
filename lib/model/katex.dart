import 'package:csslib/parser.dart' as css_parser;
import 'package:csslib/visitor.dart' as css_visitor;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:html/dom.dart' as dom;

import '../log.dart';
import 'binding.dart';
import 'content.dart';
import 'settings.dart';

/// The failure reason in case the KaTeX parser encountered a
/// `_KatexHtmlParseError` exception.
///
/// Generally this means that parser encountered an unexpected HTML structure,
/// an unsupported HTML node, or an unexpected inline CSS style or CSS class on
/// a specific node.
class KatexParserHardFailReason {
  const KatexParserHardFailReason({
    required this.error,
    required this.stackTrace,
  });

  final String error;
  final StackTrace stackTrace;
}

/// The failure reason in case the KaTeX parser found an unsupported
/// CSS class or unsupported inline CSS style property.
class KatexParserSoftFailReason {
  const KatexParserSoftFailReason({
    this.unsupportedCssClasses = const [],
    this.unsupportedInlineCssProperties = const [],
  });

  final List<String> unsupportedCssClasses;
  final List<String> unsupportedInlineCssProperties;
}

class MathParserResult {
  const MathParserResult({
    required this.texSource,
    required this.nodes,
    this.hardFailReason,
    this.softFailReason,
  });

  final String texSource;

  /// Parsed KaTeX node tree to be used for rendering the KaTeX content.
  ///
  /// It will be null if the parser encounters an unsupported HTML element or
  /// CSS style, indicating that the widget should render the [texSource] as a
  /// fallback instead.
  final List<KatexNode>? nodes;

  final KatexParserHardFailReason? hardFailReason;
  final KatexParserSoftFailReason? softFailReason;
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

    KatexParserHardFailReason? hardFailReason;
    KatexParserSoftFailReason? softFailReason;
    List<KatexNode>? nodes;
    if (flagRenderKatex) {
      final parser = _KatexParser();
      try {
        nodes = parser.parseKatexHtml(katexHtmlElement);
      } on _KatexHtmlParseError catch (e, st) {
        assert(debugLog('$e\n$st'));
        hardFailReason = KatexParserHardFailReason(
          error: e.message ?? 'unknown',
          stackTrace: st);
      }

      if (parser.hasError && !flagForceRenderKatex) {
        nodes = null;
        softFailReason = KatexParserSoftFailReason(
          unsupportedCssClasses: parser.unsupportedCssClasses,
          unsupportedInlineCssProperties: parser.unsupportedInlineCssProperties);
      }
    }

    return MathParserResult(
      nodes: nodes,
      texSource: texSource,
      hardFailReason: hardFailReason,
      softFailReason: softFailReason);
  } else {
    return null;
  }
}

class _KatexParser {
  bool get hasError => _hasError;
  bool _hasError = false;

  final unsupportedCssClasses = <String>[];
  final unsupportedInlineCssProperties = <String>[];

  List<KatexNode> parseKatexHtml(dom.Element element) {
    assert(element.localName == 'span');
    assert(element.className == 'katex-html');
    return _parseChildSpans(element.nodes);
  }

  List<KatexNode> _parseChildSpans(List<dom.Node> nodes) {
    return List.unmodifiable(nodes.map((node) {
      if (node case dom.Element(localName: 'span')) {
        return _parseSpan(node);
      } else {
        throw _KatexHtmlParseError(
          node is dom.Element
            ? 'unsupported html node: ${node.localName}'
            : 'unsupported html node');
      }
    }));
  }

  static final _resetSizeClassRegExp = RegExp(r'^reset-size(\d\d?)$');
  static final _sizeClassRegExp = RegExp(r'^size(\d\d?)$');

  KatexNode _parseSpan(dom.Element element) {
    // TODO maybe check if the sequence of ancestors matter for spans.

    final debugHtmlNode = kDebugMode ? element : null;

    final inlineStyles = _parseSpanInlineStyles(element);

    // Aggregate the CSS styles that apply, in the same order as the CSS
    // classes specified for this span, mimicking the behaviour on web.
    //
    // Each case in the switch block below is a separate CSS class definition
    // in the same order as in katex.scss :
    //   https://github.com/KaTeX/KaTeX/blob/2fe1941b/src/styles/katex.scss
    // A copy of class definition (where possible) is accompanied in a comment
    // with each case statement to keep track of updates.
    final spanClasses = List<String>.unmodifiable(element.className.split(' '));
    String? fontFamily;
    double? fontSizeEm;
    KatexSpanFontWeight? fontWeight;
    KatexSpanFontStyle? fontStyle;
    KatexSpanTextAlign? textAlign;
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
          fontWeight = KatexSpanFontWeight.bold;

        case 'textit':
          // .textit { font-style: italic; }
          fontStyle = KatexSpanFontStyle.italic;

        case 'textrm':
          // .textrm { font-family: KaTeX_Main; }
          fontFamily = 'KaTeX_Main';

        // case 'textsf':
        //   // .textsf { font-family: KaTeX_SansSerif; }
        // This CSS rule has no effect, because the other `.textsf` rule below
        // has the exact same list of declarations.  Handle it there instead.

        case 'texttt':
          // .texttt { font-family: KaTeX_Typewriter; }
          fontFamily = 'KaTeX_Typewriter';

        case 'mathnormal':
          // .mathnormal { font-family: KaTeX_Math; font-style: italic; }
          fontFamily = 'KaTeX_Math';
          fontStyle = KatexSpanFontStyle.italic;

        case 'mathit':
          // .mathit { font-family: KaTeX_Main; font-style: italic; }
          fontFamily = 'KaTeX_Main';
          fontStyle = KatexSpanFontStyle.italic;

        case 'mathrm':
          // .mathrm { font-style: normal; }
          fontStyle = KatexSpanFontStyle.normal;

        case 'mathbf':
          // .mathbf { font-family: KaTeX_Main; font-weight: bold; }
          fontFamily = 'KaTeX_Main';
          fontWeight = KatexSpanFontWeight.bold;

        case 'boldsymbol':
          // .boldsymbol { font-family: KaTeX_Math; font-weight: bold; font-style: italic; }
          fontFamily = 'KaTeX_Math';
          fontWeight = KatexSpanFontWeight.bold;
          fontStyle = KatexSpanFontStyle.italic;

        case 'amsrm':
          // .amsrm { font-family: KaTeX_AMS; }
          fontFamily = 'KaTeX_AMS';

        case 'mathbb':
        case 'textbb':
          // .mathbb,
          // .textbb { font-family: KaTeX_AMS; }
          fontFamily = 'KaTeX_AMS';

        case 'mathcal':
          // .mathcal { font-family: KaTeX_Caligraphic; }
          fontFamily = 'KaTeX_Caligraphic';

        case 'mathfrak':
        case 'textfrak':
          // .mathfrak,
          // .textfrak { font-family: KaTeX_Fraktur; }
          fontFamily = 'KaTeX_Fraktur';

        case 'mathboldfrak':
        case 'textboldfrak':
          // .mathboldfrak,
          // .textboldfrak { font-family: KaTeX_Fraktur; font-weight: bold; }
          fontFamily = 'KaTeX_Fraktur';
          fontWeight = KatexSpanFontWeight.bold;

        case 'mathtt':
          // .mathtt { font-family: KaTeX_Typewriter; }
          fontFamily = 'KaTeX_Typewriter';

        case 'mathscr':
        case 'textscr':
          // .mathscr,
          // .textscr { font-family: KaTeX_Script; }
          fontFamily = 'KaTeX_Script';

        case 'mathsf':
        case 'textsf':
          // .mathsf,
          // .textsf { font-family: KaTeX_SansSerif; }
          fontFamily = 'KaTeX_SansSerif';

        case 'mathboldsf':
        case 'textboldsf':
          // .mathboldsf,
          // .textboldsf { font-family: KaTeX_SansSerif; font-weight: bold; }
          fontFamily = 'KaTeX_SansSerif';
          fontWeight = KatexSpanFontWeight.bold;

        case 'mathsfit':
        case 'mathitsf':
        case 'textitsf':
          // .mathsfit,
          // .mathitsf,
          // .textitsf { font-family: KaTeX_SansSerif; font-style: italic; }
          fontFamily = 'KaTeX_SansSerif';
          fontStyle = KatexSpanFontStyle.italic;

        case 'mainrm':
          // .mainrm { font-family: KaTeX_Main; font-style: normal; }
          fontFamily = 'KaTeX_Main';
          fontStyle = KatexSpanFontStyle.normal;

        // TODO handle skipped class declarations between .mainrm and
        //   .mspace .

        case 'mspace':
          // .mspace { display: inline-block; }
          // A .mspace span's children are always either empty,
          // a no-break space " " (== "\xa0"),
          // or one span.mtight containing a no-break space.
          // TODO enforce that constraint on .mspace spans in parsing
          // So `display: inline-block` has no effect compared to
          // the initial `display: inline`.
          break;

        // TODO handle skipped class declarations between .mspace and
        //   .msupsub .

        case 'msupsub':
          // .msupsub { text-align: left; }
          textAlign = KatexSpanTextAlign.left;

        // TODO handle skipped class declarations between .msupsub and
        //   .sizing .

        case 'sizing':
        case 'fontsize-ensurer':
          // .sizing,
          // .fontsize-ensurer { ... }
          if (index + 2 > spanClasses.length) throw _KatexHtmlParseError();
          final resetSizeClass = spanClasses[index++];
          final sizeClass = spanClasses[index++];

          final resetSizeClassSuffix = _resetSizeClassRegExp.firstMatch(resetSizeClass)?.group(1);
          if (resetSizeClassSuffix == null) throw _KatexHtmlParseError();
          final sizeClassSuffix = _sizeClassRegExp.firstMatch(sizeClass)?.group(1);
          if (sizeClassSuffix == null) throw _KatexHtmlParseError();

          const sizes = <double>[0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.2, 1.44, 1.728, 2.074, 2.488];

          final resetSizeIdx = int.parse(resetSizeClassSuffix, radix: 10);
          final sizeIdx = int.parse(sizeClassSuffix, radix: 10);

          // These indexes start at 1.
          if (resetSizeIdx > sizes.length) throw _KatexHtmlParseError();
          if (sizeIdx > sizes.length) throw _KatexHtmlParseError();
          fontSizeEm = sizes[sizeIdx - 1] / sizes[resetSizeIdx - 1];

        case 'delimsizing':
          // .delimsizing { ... }
          if (index + 1 > spanClasses.length) throw _KatexHtmlParseError();
          fontFamily = switch (spanClasses[index++]) {
            'size1' => 'KaTeX_Size1',
            'size2' => 'KaTeX_Size2',
            'size3' => 'KaTeX_Size3',
            'size4' => 'KaTeX_Size4',
            'mult' =>
              // TODO handle nested spans with `.delim-size{1,4}` class.
              throw _KatexHtmlParseError(),
            _ => throw _KatexHtmlParseError(),
          };

        // TODO handle .nulldelimiter and .delimcenter .

        case 'op-symbol':
          // .op-symbol { ... }
          if (index + 1 > spanClasses.length) throw _KatexHtmlParseError();
          fontFamily = switch (spanClasses[index++]) {
            'small-op' => 'KaTeX_Size1',
            'large-op' => 'KaTeX_Size2',
            _ => throw _KatexHtmlParseError(),
          };

        // TODO handle more classes from katex.scss

        case 'mord':
        case 'mopen':
        case 'mtight':
        case 'text':
        case 'mrel':
        case 'mop':
        case 'mclose':
        case 'minner':
        case 'mbin':
        case 'mpunct':
        case 'nobreak':
        case 'allowbreak':
        case 'mathdefault':
          // Ignore these classes because they don't have a CSS definition
          // in katex.scss, but we encounter them in the generated HTML.
          // (Why are they there if they're not used?  The story seems to be:
          // they were used in KaTeX's CSS in the past, before 2020 or so; and
          // they're still used internally by KaTeX in producing the HTML.
          //   https://github.com/KaTeX/KaTeX/issues/2194#issuecomment-584703052
          //   https://github.com/KaTeX/KaTeX/issues/3344
          // )
          break;

        default:
          assert(debugLog('KaTeX: Unsupported CSS class: $spanClass'));
          unsupportedCssClasses.add(spanClass);
          _hasError = true;
      }
    }
    final styles = KatexSpanStyles(
      fontFamily: fontFamily,
      fontSizeEm: fontSizeEm,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      textAlign: textAlign,
    );

    String? text;
    List<KatexNode>? spans;
    if (element.nodes case [dom.Text(:final data)]) {
      text = data;
    } else {
      spans = _parseChildSpans(element.nodes);
    }
    if (text == null && spans == null) throw _KatexHtmlParseError();

    return KatexSpanNode(
      styles: inlineStyles != null
        ? styles.merge(inlineStyles)
        : styles,
      text: text,
      nodes: spans,
      debugHtmlNode: debugHtmlNode);
  }

  KatexSpanStyles? _parseSpanInlineStyles(dom.Element element) {
    if (element.attributes case {'style': final styleStr}) {
      // `package:csslib` doesn't seem to have a way to parse inline styles:
      //   https://github.com/dart-lang/tools/issues/1173
      // So, work around that by wrapping it in a universal declaration.
      final stylesheet = css_parser.parse('*{$styleStr}');
      if (stylesheet.topLevels case [css_visitor.RuleSet() && final rule]) {
        double? heightEm;

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
            }

            // TODO handle more CSS properties
            assert(debugLog('KaTeX: Unsupported CSS expression:'
              ' ${expression.toDebugString()}'));
            unsupportedInlineCssProperties.add(property);
            _hasError = true;
          } else {
            throw _KatexHtmlParseError();
          }
        }

        return KatexSpanStyles(
          heightEm: heightEm,
        );
      } else {
        throw _KatexHtmlParseError();
      }
    }
    return null;
  }

  /// Returns the CSS `em` unit value if the given [expression] is actually an
  /// `em` unit expression, else returns null.
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

@immutable
class KatexSpanStyles {
  final double? heightEm;

  final String? fontFamily;
  final double? fontSizeEm;
  final KatexSpanFontWeight? fontWeight;
  final KatexSpanFontStyle? fontStyle;
  final KatexSpanTextAlign? textAlign;

  const KatexSpanStyles({
    this.heightEm,
    this.fontFamily,
    this.fontSizeEm,
    this.fontWeight,
    this.fontStyle,
    this.textAlign,
  });

  @override
  int get hashCode => Object.hash(
    'KatexSpanStyles',
    heightEm,
    fontFamily,
    fontSizeEm,
    fontWeight,
    fontStyle,
    textAlign,
  );

  @override
  bool operator ==(Object other) {
    return other is KatexSpanStyles &&
      other.heightEm == heightEm &&
      other.fontFamily == fontFamily &&
      other.fontSizeEm == fontSizeEm &&
      other.fontWeight == fontWeight &&
      other.fontStyle == fontStyle &&
      other.textAlign == textAlign;
  }

  @override
  String toString() {
    final args = <String>[];
    if (heightEm != null) args.add('heightEm: $heightEm');
    if (fontFamily != null) args.add('fontFamily: $fontFamily');
    if (fontSizeEm != null) args.add('fontSizeEm: $fontSizeEm');
    if (fontWeight != null) args.add('fontWeight: $fontWeight');
    if (fontStyle != null) args.add('fontStyle: $fontStyle');
    if (textAlign != null) args.add('textAlign: $textAlign');
    return '${objectRuntimeType(this, 'KatexSpanStyles')}(${args.join(', ')})';
  }

  /// Creates a new [KatexSpanStyles] with current and [other]'s styles merged.
  ///
  /// The styles in [other] take precedence and any missing styles in [other]
  /// are filled in with current styles, if present.
  ///
  /// This similar to the behaviour of [TextStyle.merge], if the given style
  /// had `inherit` set to true.
  KatexSpanStyles merge(KatexSpanStyles other) {
    return KatexSpanStyles(
      heightEm: other.heightEm ?? heightEm,
      fontFamily: other.fontFamily ?? fontFamily,
      fontSizeEm: other.fontSizeEm ?? fontSizeEm,
      fontStyle: other.fontStyle ?? fontStyle,
      fontWeight: other.fontWeight ?? fontWeight,
      textAlign: other.textAlign ?? textAlign,
    );
  }
}

class _KatexHtmlParseError extends Error {
  final String? message;

  _KatexHtmlParseError([this.message]);

  @override
  String toString() {
    if (message != null) {
      return 'Katex HTML parse error: $message';
    }
    return 'Katex HTML parse error';
  }
}
