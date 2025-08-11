import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:csslib/parser.dart' as css_parser;
import 'package:csslib/visitor.dart' as css_visitor;
import 'package:flutter/foundation.dart';
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
    required this.message,
    required this.stackTrace,
  });

  final String? message;
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
    final flagForceRenderKatex =
      globalSettings.getBool(BoolGlobalSetting.forceRenderKatex);

    KatexParserHardFailReason? hardFailReason;
    KatexParserSoftFailReason? softFailReason;
    List<KatexNode>? nodes;
    final parser = _KatexParser();
    try {
      nodes = parser.parseKatexHtml(katexHtmlElement);
    } on _KatexHtmlParseError catch (e, st) {
      assert(debugLog('$e\n$st'));
      hardFailReason = KatexParserHardFailReason(
        message: e.message,
        stackTrace: st);
    }

    if (parser.hasError && !flagForceRenderKatex) {
      nodes = null;
      softFailReason = KatexParserSoftFailReason(
        unsupportedCssClasses: parser.unsupportedCssClasses,
        unsupportedInlineCssProperties: parser.unsupportedInlineCssProperties);
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
    var resultSpans = QueueList<KatexNode>();
    for (final node in nodes.reversed) {
      if (node is! dom.Element || node.localName != 'span') {
        throw _KatexHtmlParseError(
          node is dom.Element
            ? 'unsupported html node: ${node.localName}'
            : 'unsupported html node');
      }

      var span = _parseSpan(node);
      final negativeRightMarginEm = switch (span) {
        KatexSpanNode(styles: KatexSpanStyles(:final marginRightEm?))
          when marginRightEm.isNegative => marginRightEm,
        _ => null,
      };
      final negativeLeftMarginEm = switch (span) {
        KatexSpanNode(styles: KatexSpanStyles(:final marginLeftEm?))
          when marginLeftEm.isNegative => marginLeftEm,
        _ => null,
      };
      if (span is KatexSpanNode) {
        if (negativeRightMarginEm != null || negativeLeftMarginEm != null) {
          span = KatexSpanNode(
            styles: span.styles.filter(
              marginRightEm: negativeRightMarginEm == null,
              marginLeftEm: negativeLeftMarginEm == null),
            text: span.text,
            nodes: span.nodes);
        }
      }

      if (negativeRightMarginEm != null) {
        final previousSpans = resultSpans;
        resultSpans = QueueList<KatexNode>();
        resultSpans.addFirst(KatexNegativeMarginNode(
          leftOffsetEm: negativeRightMarginEm,
          nodes: previousSpans));
      }

      resultSpans.addFirst(span);

      if (negativeLeftMarginEm != null) {
        final previousSpans = resultSpans;
        resultSpans = QueueList<KatexNode>();
        resultSpans.addFirst(KatexNegativeMarginNode(
          leftOffsetEm: negativeLeftMarginEm,
          nodes: previousSpans));
      }
    }
    return resultSpans;
  }

  KatexNode _parseSpan(dom.Element element) {
    assert(element.localName == 'span');
    // TODO maybe check if the sequence of ancestors matter for spans.

    if (element.className == 'strut') {
      return _parseStrut(element);
    }

    if (element.className == 'vlist-t'
        || element.className == 'vlist-t vlist-t2') {
      return _parseVlist(element);
    }

    return _parseGenericSpan(element);
  }

  KatexNode _parseStrut(dom.Element element) {
    assert(element.localName == 'span');
    assert(element.className == 'strut');
    if (element.nodes.isNotEmpty) throw _KatexHtmlParseError();

    final styles = _parseInlineStyles(element);
    if (styles == null) throw _KatexHtmlParseError();
    final heightEm = _takeStyleEm(styles, 'height');
    if (heightEm == null) throw _KatexHtmlParseError();
    final verticalAlignEm = _takeStyleEm(styles, 'vertical-align');
    if (styles.isNotEmpty) throw _KatexHtmlParseError();

    return KatexStrutNode(
      heightEm: heightEm,
      verticalAlignEm: verticalAlignEm,
      debugHtmlNode: kDebugMode ? element : null);
  }

  KatexNode _parseVlist(dom.Element element) {
    assert(element.localName == 'span');
    assert(element.className == 'vlist-t'
      || element.className == 'vlist-t vlist-t2');
    final vlistT = element;
    if (vlistT.nodes.isEmpty) throw _KatexHtmlParseError();
    if (vlistT.attributes.containsKey('style')) throw _KatexHtmlParseError();

    final hasTwoVlistR = vlistT.className == 'vlist-t vlist-t2';
    if (!hasTwoVlistR && vlistT.nodes.length != 1) throw _KatexHtmlParseError();

    if (hasTwoVlistR) {
      if (vlistT.nodes case [
        _,
        dom.Element(localName: 'span', className: 'vlist-r', nodes: [
          dom.Element(localName: 'span', className: 'vlist', nodes: [
            dom.Element(localName: 'span', className: '', nodes: []),
          ]) && final vlist,
        ]),
      ]) {
        // In the generated HTML the .vlist in second .vlist-r span will have
        // a "height" inline style which we ignore, because it doesn't seem
        // to have any effect in rendering on the web.
        // But also make sure there aren't any other inline styles present.
        final vlistStyles = _parseInlineStyles(vlist);
        if (vlistStyles != null && vlistStyles.keys.any((p) => p != 'height')) {
          throw _KatexHtmlParseError();
        }
      } else {
        throw _KatexHtmlParseError();
      }
    }

    if (vlistT.nodes.first
        case dom.Element(localName: 'span', className: 'vlist-r') &&
            final vlistR) {
      if (vlistR.attributes.containsKey('style')) throw _KatexHtmlParseError();

      if (vlistR.nodes.first
          case dom.Element(localName: 'span', className: 'vlist') &&
              final vlist) {
        // Same as above for the second .vlist-r span, .vlist span in first
        // .vlist-r span will have "height" inline style which we ignore,
        // because it doesn't seem to have any effect in rendering on
        // the web.
        // But also make sure there aren't any other inline styles present.
        final vlistStyles = _parseInlineStyles(vlist);
        if (vlistStyles != null && vlistStyles.keys.any((p) => p != 'height')) {
          throw _KatexHtmlParseError();
        }

        final rows = <KatexVlistRowNode>[];

        for (final innerSpan in vlist.nodes) {
          if (innerSpan case dom.Element(
            localName: 'span',
            nodes: [
              dom.Element(localName: 'span', className: 'pstrut') &&
                  final pstrutSpan,
              ...final otherSpans,
            ],
          )) {
            if (innerSpan.className != '') {
              throw _KatexHtmlParseError('unexpected CSS class for '
                'vlist inner span: ${innerSpan.className}');
            }

            final inlineStyles = _parseInlineStyles(innerSpan);
            if (inlineStyles == null) throw _KatexHtmlParseError();
            final marginLeftEm = _takeStyleEm(inlineStyles, 'margin-left');
            final marginLeftIsNegative = marginLeftEm?.isNegative ?? false;
            final marginRightEm = _takeStyleEm(inlineStyles, 'margin-right');
            if (marginRightEm?.isNegative ?? false) throw _KatexHtmlParseError();
            final styles = KatexSpanStyles(
              marginLeftEm: marginLeftIsNegative ? null : marginLeftEm,
              marginRightEm: marginRightEm,
            );
            final topEm = _takeStyleEm(inlineStyles, 'top');
            if (inlineStyles.isNotEmpty) throw _KatexHtmlParseError();

            final pstrutStyles = _parseInlineStyles(pstrutSpan);
            if (pstrutStyles == null) throw _KatexHtmlParseError();
            final pstrutHeightEm = _takeStyleEm(pstrutStyles, 'height');
            if (pstrutHeightEm == null) throw _KatexHtmlParseError();
            if (pstrutStyles.isNotEmpty) throw _KatexHtmlParseError();

            KatexSpanNode child = KatexSpanNode(
              styles: styles,
              nodes: _parseChildSpans(otherSpans));

            if (marginLeftIsNegative) {
              child = KatexSpanNode(
                nodes: [KatexNegativeMarginNode(
                  leftOffsetEm: marginLeftEm!,
                  nodes: [child])]);
            }

            rows.add(KatexVlistRowNode(
              verticalOffsetEm: (topEm ?? 0) + pstrutHeightEm,
              debugHtmlNode: kDebugMode ? innerSpan : null,
              node: child));
          } else {
            throw _KatexHtmlParseError();
          }
        }

        // TODO(#1716) Handle styling for .vlist-t2 spans
        return KatexVlistNode(
          rows: rows,
          debugHtmlNode: kDebugMode ? element : null,
        );
      } else {
        throw _KatexHtmlParseError();
      }
    } else {
      throw _KatexHtmlParseError();
    }
  }

  static final _resetSizeClassRegExp = RegExp(r'^reset-size(\d\d?)$');
  static final _sizeClassRegExp = RegExp(r'^size(\d\d?)$');

  KatexNode _parseGenericSpan(dom.Element element) {
    assert(element.localName == 'span');

    // Aggregate the CSS styles that apply, in the same order as the CSS
    // classes specified for this span, mimicking the behaviour on web.
    //
    // Each case in the switch block below is a separate CSS class definition
    // in the same order as in katex.scss :
    //   https://github.com/KaTeX/KaTeX/blob/2fe1941b/src/styles/katex.scss
    // A copy of class definition (where possible) is accompanied in a comment
    // with each case statement to keep track of updates.
    final spanClasses = element.className != ''
      ? List<String>.unmodifiable(element.className.split(' '))
      : const <String>[];
    double? widthEm;
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
          // We expect the 'strut' class to be the only class in a span,
          // in which case we handle it separately and emit `KatexStrutNode`.
          throw _KatexHtmlParseError();

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
              throw _KatexHtmlParseError('unimplemented CSS class pair: .delimsizing.mult'),
            _ => throw _KatexHtmlParseError(),
          };

        case 'nulldelimiter':
          // .nulldelimiter { display: inline-block; width: 0.12em; }
          widthEm = 0.12;

        // TODO .delimcenter .

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

    final inlineStyles = _parseInlineStyles(element);
    final styles = KatexSpanStyles(
      widthEm: widthEm,
      fontFamily: fontFamily,
      fontSizeEm: fontSizeEm,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      textAlign: textAlign,
      heightEm: _takeStyleEm(inlineStyles, 'height'),
      topEm: _takeStyleEm(inlineStyles, 'top'),
      marginLeftEm: _takeStyleEm(inlineStyles, 'margin-left'),
      marginRightEm: _takeStyleEm(inlineStyles, 'margin-right'),
      color: _takeStyleColor(inlineStyles, 'color'),
      // TODO handle more CSS properties
    );
    if (inlineStyles != null && inlineStyles.isNotEmpty) {
      for (final property in inlineStyles.keys) {
        assert(debugLog('KaTeX: Unexpected inline CSS property: $property'));
        unsupportedInlineCssProperties.add(property);
        _hasError = true;
      }
    }
    // Currently, we expect `top` to only be inside a vlist, and
    // we handle that case separately above.
    if (styles.topEm != null) {
      throw _KatexHtmlParseError('unsupported inline CSS property: top');
    }

    String? text;
    List<KatexNode>? spans;
    if (element.nodes case [dom.Text(:final data)]) {
      text = data;
    } else {
      spans = _parseChildSpans(element.nodes);
    }
    if (text == null && spans == null) throw _KatexHtmlParseError();

    return KatexSpanNode(
      styles: styles,
      text: text,
      nodes: spans,
      debugHtmlNode: kDebugMode ? element : null);
  }

  /// Parse the inline CSS styles from the given element.
  ///
  /// To interpret the resulting map, consider [_takeStyleEm].
  static Map<String, css_visitor.Expression>? _parseInlineStyles(dom.Element element) {
    final styleStr = element.attributes['style'];
    if (styleStr == null) return null;

    // `package:csslib` doesn't seem to have a way to parse inline styles:
    //   https://github.com/dart-lang/tools/issues/1173
    // So, work around that by wrapping it in a universal declaration.
    final stylesheet = css_parser.parse('*{$styleStr}');
    if (stylesheet.topLevels case [css_visitor.RuleSet() && final ruleSet]) {
      final result = <String, css_visitor.Expression>{};
      for (final declaration in ruleSet.declarationGroup.declarations) {
        if (declaration case css_visitor.Declaration(
          :final property,
          expression: css_visitor.Expressions(
            expressions: [css_visitor.Expression() && final expression]),
        )) {
          result.update(property, ifAbsent: () => expression,
            (_) => throw _KatexHtmlParseError(
              'duplicate inline CSS property: $property'));
        } else {
          throw _KatexHtmlParseError('unexpected shape of inline CSS');
        }
      }
      return result;
    } else {
      throw _KatexHtmlParseError();
    }
  }

  /// Remove the given property from the given style map,
  /// and parse as a length in ems.
  ///
  /// If the property is present but is not a length in ems,
  /// record an error and return null.
  ///
  /// If the property is absent, return null with no error.
  ///
  /// If the map is null, treat it as empty.
  ///
  /// To produce the map this method expects, see [_parseInlineStyles].
  double? _takeStyleEm(Map<String, css_visitor.Expression>? styles, String property) {
    final expression = styles?.remove(property);
    if (expression == null) return null;
    if (expression is css_visitor.EmTerm && expression.value is num) {
      return (expression.value as num).toDouble();
    }
    assert(debugLog('KaTeX: Unsupported value for CSS property $property,'
      ' expected a length in em: ${expression.toDebugString()}'));
    unsupportedInlineCssProperties.add(property);
    _hasError = true;
    return null;
  }

  /// Remove the given property from the given style map,
  /// and parse as a color value.
  ///
  /// If the property is present but is not a valid CSS Hex color,
  /// or is not one of the CSS named color, record an error
  /// and return null.
  ///
  /// If the property is absent, return null with no error.
  ///
  /// If the map is null, treat it as empty.
  ///
  /// To produce the map this method expects, see [_parseInlineStyles].
  KatexSpanColor? _takeStyleColor(Map<String, css_visitor.Expression>? styles, String property) {
    final expression = styles?.remove(property);
    if (expression == null) return null;

    // `package:csslib` parser emits a HexColorTerm for the `color`
    // attribute. It automatically resolves the named CSS colors to
    // their hex values. The `HexColorTerm.value` is the hex
    // encoded in an integer in the same sequence as the input hex
    // string. But it also allows some non-conformant CSS hex color
    // notations, like #f, #ff, #fffff, #fffffff.
    // See:
    //   https://drafts.csswg.org/css-color/#hex-notation.
    //   https://github.com/dart-lang/tools/blob/2a2a2d611/pkgs/csslib/lib/parser.dart#L2714-L2743
    //
    // So, we try to parse the value of `color` attribute ourselves
    // only allowing conformant CSS hex color notations, mapping
    // named CSS colors to their corresponding values, generating a
    // typed result (KatexSpanColor(r, g, b, a)) to be used later
    // while rendering.
    final valueStr = expression.span?.text;
    if (valueStr != null) {
      if (valueStr.startsWith('#')) {
        final color = parseCssHexColor(valueStr);
        if (color != null) return color;
      } else {
        final color = _cssNamedColorsMap[valueStr];
        if (color != null) return color;
      }
    }
    assert(debugLog('KaTeX: Unsupported value for CSS property $property,'
      ' expected a color: ${expression.toDebugString()}'));
    unsupportedInlineCssProperties.add(property);
    _hasError = true;
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

class KatexSpanColor {
  const KatexSpanColor(this.r, this.g, this.b, this.a);

  final int r;
  final int g;
  final int b;
  final int a;

  @override
  bool operator ==(Object other) {
    return other is KatexSpanColor &&
      other.r == r &&
      other.g == g &&
      other.b == b &&
      other.a == a;
  }

  @override
  int get hashCode => Object.hash('KatexSpanColor', r, g, b, a);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'KatexSpanColor')}($r, $g, $b, $a)';
  }
}

@immutable
class KatexSpanStyles {
  final double? widthEm;

  // TODO(#1674) does height actually appear on generic spans?
  //   In a corpus, the only occurrences that we don't already handle separately
  //   (i.e. occurrences other than on struts, vlists, etc) seem to be within
  //   accents; so after #1674 we might be handling those separately too.
  final double? heightEm;

  // We expect `vertical-align` inline style to be only present on a
  // `strut` span, for which we emit `KatexStrutNode` separately.
  // final double? verticalAlignEm;

  final double? topEm;

  final double? marginRightEm;
  final double? marginLeftEm;

  final String? fontFamily;
  final double? fontSizeEm;
  final KatexSpanFontWeight? fontWeight;
  final KatexSpanFontStyle? fontStyle;
  final KatexSpanTextAlign? textAlign;

  final KatexSpanColor? color;

  const KatexSpanStyles({
    this.widthEm,
    this.heightEm,
    this.topEm,
    this.marginRightEm,
    this.marginLeftEm,
    this.fontFamily,
    this.fontSizeEm,
    this.fontWeight,
    this.fontStyle,
    this.textAlign,
    this.color,
  });

  @override
  int get hashCode => Object.hash(
    'KatexSpanStyles',
    widthEm,
    heightEm,
    topEm,
    marginRightEm,
    marginLeftEm,
    fontFamily,
    fontSizeEm,
    fontWeight,
    fontStyle,
    textAlign,
    color,
  );

  @override
  bool operator ==(Object other) {
    return other is KatexSpanStyles &&
      other.widthEm == widthEm &&
      other.heightEm == heightEm &&
      other.topEm == topEm &&
      other.marginRightEm == marginRightEm &&
      other.marginLeftEm == marginLeftEm &&
      other.fontFamily == fontFamily &&
      other.fontSizeEm == fontSizeEm &&
      other.fontWeight == fontWeight &&
      other.fontStyle == fontStyle &&
      other.textAlign == textAlign &&
      other.color == color;
  }

  @override
  String toString() {
    final args = <String>[];
    if (widthEm != null) args.add('widthEm: $widthEm');
    if (heightEm != null) args.add('heightEm: $heightEm');
    if (topEm != null) args.add('topEm: $topEm');
    if (marginRightEm != null) args.add('marginRightEm: $marginRightEm');
    if (marginLeftEm != null) args.add('marginLeftEm: $marginLeftEm');
    if (fontFamily != null) args.add('fontFamily: $fontFamily');
    if (fontSizeEm != null) args.add('fontSizeEm: $fontSizeEm');
    if (fontWeight != null) args.add('fontWeight: $fontWeight');
    if (fontStyle != null) args.add('fontStyle: $fontStyle');
    if (textAlign != null) args.add('textAlign: $textAlign');
    if (color != null) args.add('color: $color');
    return '${objectRuntimeType(this, 'KatexSpanStyles')}(${args.join(', ')})';
  }

  KatexSpanStyles filter({
    bool widthEm = true,
    bool heightEm = true,
    bool verticalAlignEm = true,
    bool topEm = true,
    bool marginRightEm = true,
    bool marginLeftEm = true,
    bool fontFamily = true,
    bool fontSizeEm = true,
    bool fontWeight = true,
    bool fontStyle = true,
    bool textAlign = true,
    bool color = true,
  }) {
    return KatexSpanStyles(
      widthEm: widthEm ? this.widthEm : null,
      heightEm: heightEm ? this.heightEm : null,
      topEm: topEm ? this.topEm : null,
      marginRightEm: marginRightEm ? this.marginRightEm : null,
      marginLeftEm: marginLeftEm ? this.marginLeftEm : null,
      fontFamily: fontFamily ? this.fontFamily : null,
      fontSizeEm: fontSizeEm ? this.fontSizeEm : null,
      fontWeight: fontWeight ? this.fontWeight : null,
      fontStyle: fontStyle ? this.fontStyle : null,
      textAlign: textAlign ? this.textAlign : null,
      color: color ? this.color : null,
    );
  }
}

final _hexColorRegExp =
  RegExp(r'^#([0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');

/// Parses the CSS hex color notation.
///
/// See: https://drafts.csswg.org/css-color/#hex-notation
@visibleForTesting
KatexSpanColor? parseCssHexColor(String hexStr) {
  final match = _hexColorRegExp.firstMatch(hexStr);
  if (match == null) return null;

  String hexValue = match.group(1)!;
  switch (hexValue.length) {
    case 3:
      hexValue = '${hexValue[0]}${hexValue[0]}'
        '${hexValue[1]}${hexValue[1]}'
        '${hexValue[2]}${hexValue[2]}'
        'ff';
    case 4:
      hexValue = '${hexValue[0]}${hexValue[0]}'
        '${hexValue[1]}${hexValue[1]}'
        '${hexValue[2]}${hexValue[2]}'
        '${hexValue[3]}${hexValue[3]}';
    case 6:
      hexValue += 'ff';
  }

  try {
    final [r, g, b, a] = hex.decode(hexValue);
    return KatexSpanColor(r, g, b, a);
  } catch (_) {
    return null; // TODO(log)
  }
}

// CSS named colors: https://drafts.csswg.org/css-color/#named-colors
// Map adapted from the following source file:
//   https://github.com/w3c/csswg-drafts/blob/1942d0918/css-color-4/Overview.bs#L1562-L1859
const _cssNamedColorsMap = {
  'transparent': KatexSpanColor(0, 0, 0, 0), // https://drafts.csswg.org/css-color/#transparent-color
  'aliceblue': KatexSpanColor(240, 248, 255, 255),
  'antiquewhite': KatexSpanColor(250, 235, 215, 255),
  'aqua': KatexSpanColor(0, 255, 255, 255),
  'aquamarine': KatexSpanColor(127, 255, 212, 255),
  'azure': KatexSpanColor(240, 255, 255, 255),
  'beige': KatexSpanColor(245, 245, 220, 255),
  'bisque': KatexSpanColor(255, 228, 196, 255),
  'black': KatexSpanColor(0, 0, 0, 255),
  'blanchedalmond': KatexSpanColor(255, 235, 205, 255),
  'blue': KatexSpanColor(0, 0, 255, 255),
  'blueviolet': KatexSpanColor(138, 43, 226, 255),
  'brown': KatexSpanColor(165, 42, 42, 255),
  'burlywood': KatexSpanColor(222, 184, 135, 255),
  'cadetblue': KatexSpanColor(95, 158, 160, 255),
  'chartreuse': KatexSpanColor(127, 255, 0, 255),
  'chocolate': KatexSpanColor(210, 105, 30, 255),
  'coral': KatexSpanColor(255, 127, 80, 255),
  'cornflowerblue': KatexSpanColor(100, 149, 237, 255),
  'cornsilk': KatexSpanColor(255, 248, 220, 255),
  'crimson': KatexSpanColor(220, 20, 60, 255),
  'cyan': KatexSpanColor(0, 255, 255, 255),
  'darkblue': KatexSpanColor(0, 0, 139, 255),
  'darkcyan': KatexSpanColor(0, 139, 139, 255),
  'darkgoldenrod': KatexSpanColor(184, 134, 11, 255),
  'darkgray': KatexSpanColor(169, 169, 169, 255),
  'darkgreen': KatexSpanColor(0, 100, 0, 255),
  'darkgrey': KatexSpanColor(169, 169, 169, 255),
  'darkkhaki': KatexSpanColor(189, 183, 107, 255),
  'darkmagenta': KatexSpanColor(139, 0, 139, 255),
  'darkolivegreen': KatexSpanColor(85, 107, 47, 255),
  'darkorange': KatexSpanColor(255, 140, 0, 255),
  'darkorchid': KatexSpanColor(153, 50, 204, 255),
  'darkred': KatexSpanColor(139, 0, 0, 255),
  'darksalmon': KatexSpanColor(233, 150, 122, 255),
  'darkseagreen': KatexSpanColor(143, 188, 143, 255),
  'darkslateblue': KatexSpanColor(72, 61, 139, 255),
  'darkslategray': KatexSpanColor(47, 79, 79, 255),
  'darkslategrey': KatexSpanColor(47, 79, 79, 255),
  'darkturquoise': KatexSpanColor(0, 206, 209, 255),
  'darkviolet': KatexSpanColor(148, 0, 211, 255),
  'deeppink': KatexSpanColor(255, 20, 147, 255),
  'deepskyblue': KatexSpanColor(0, 191, 255, 255),
  'dimgray': KatexSpanColor(105, 105, 105, 255),
  'dimgrey': KatexSpanColor(105, 105, 105, 255),
  'dodgerblue': KatexSpanColor(30, 144, 255, 255),
  'firebrick': KatexSpanColor(178, 34, 34, 255),
  'floralwhite': KatexSpanColor(255, 250, 240, 255),
  'forestgreen': KatexSpanColor(34, 139, 34, 255),
  'fuchsia': KatexSpanColor(255, 0, 255, 255),
  'gainsboro': KatexSpanColor(220, 220, 220, 255),
  'ghostwhite': KatexSpanColor(248, 248, 255, 255),
  'gold': KatexSpanColor(255, 215, 0, 255),
  'goldenrod': KatexSpanColor(218, 165, 32, 255),
  'gray': KatexSpanColor(128, 128, 128, 255),
  'green': KatexSpanColor(0, 128, 0, 255),
  'greenyellow': KatexSpanColor(173, 255, 47, 255),
  'grey': KatexSpanColor(128, 128, 128, 255),
  'honeydew': KatexSpanColor(240, 255, 240, 255),
  'hotpink': KatexSpanColor(255, 105, 180, 255),
  'indianred': KatexSpanColor(205, 92, 92, 255),
  'indigo': KatexSpanColor(75, 0, 130, 255),
  'ivory': KatexSpanColor(255, 255, 240, 255),
  'khaki': KatexSpanColor(240, 230, 140, 255),
  'lavender': KatexSpanColor(230, 230, 250, 255),
  'lavenderblush': KatexSpanColor(255, 240, 245, 255),
  'lawngreen': KatexSpanColor(124, 252, 0, 255),
  'lemonchiffon': KatexSpanColor(255, 250, 205, 255),
  'lightblue': KatexSpanColor(173, 216, 230, 255),
  'lightcoral': KatexSpanColor(240, 128, 128, 255),
  'lightcyan': KatexSpanColor(224, 255, 255, 255),
  'lightgoldenrodyellow': KatexSpanColor(250, 250, 210, 255),
  'lightgray': KatexSpanColor(211, 211, 211, 255),
  'lightgreen': KatexSpanColor(144, 238, 144, 255),
  'lightgrey': KatexSpanColor(211, 211, 211, 255),
  'lightpink': KatexSpanColor(255, 182, 193, 255),
  'lightsalmon': KatexSpanColor(255, 160, 122, 255),
  'lightseagreen': KatexSpanColor(32, 178, 170, 255),
  'lightskyblue': KatexSpanColor(135, 206, 250, 255),
  'lightslategray': KatexSpanColor(119, 136, 153, 255),
  'lightslategrey': KatexSpanColor(119, 136, 153, 255),
  'lightsteelblue': KatexSpanColor(176, 196, 222, 255),
  'lightyellow': KatexSpanColor(255, 255, 224, 255),
  'lime': KatexSpanColor(0, 255, 0, 255),
  'limegreen': KatexSpanColor(50, 205, 50, 255),
  'linen': KatexSpanColor(250, 240, 230, 255),
  'magenta': KatexSpanColor(255, 0, 255, 255),
  'maroon': KatexSpanColor(128, 0, 0, 255),
  'mediumaquamarine': KatexSpanColor(102, 205, 170, 255),
  'mediumblue': KatexSpanColor(0, 0, 205, 255),
  'mediumorchid': KatexSpanColor(186, 85, 211, 255),
  'mediumpurple': KatexSpanColor(147, 112, 219, 255),
  'mediumseagreen': KatexSpanColor(60, 179, 113, 255),
  'mediumslateblue': KatexSpanColor(123, 104, 238, 255),
  'mediumspringgreen': KatexSpanColor(0, 250, 154, 255),
  'mediumturquoise': KatexSpanColor(72, 209, 204, 255),
  'mediumvioletred': KatexSpanColor(199, 21, 133, 255),
  'midnightblue': KatexSpanColor(25, 25, 112, 255),
  'mintcream': KatexSpanColor(245, 255, 250, 255),
  'mistyrose': KatexSpanColor(255, 228, 225, 255),
  'moccasin': KatexSpanColor(255, 228, 181, 255),
  'navajowhite': KatexSpanColor(255, 222, 173, 255),
  'navy': KatexSpanColor(0, 0, 128, 255),
  'oldlace': KatexSpanColor(253, 245, 230, 255),
  'olive': KatexSpanColor(128, 128, 0, 255),
  'olivedrab': KatexSpanColor(107, 142, 35, 255),
  'orange': KatexSpanColor(255, 165, 0, 255),
  'orangered': KatexSpanColor(255, 69, 0, 255),
  'orchid': KatexSpanColor(218, 112, 214, 255),
  'palegoldenrod': KatexSpanColor(238, 232, 170, 255),
  'palegreen': KatexSpanColor(152, 251, 152, 255),
  'paleturquoise': KatexSpanColor(175, 238, 238, 255),
  'palevioletred': KatexSpanColor(219, 112, 147, 255),
  'papayawhip': KatexSpanColor(255, 239, 213, 255),
  'peachpuff': KatexSpanColor(255, 218, 185, 255),
  'peru': KatexSpanColor(205, 133, 63, 255),
  'pink': KatexSpanColor(255, 192, 203, 255),
  'plum': KatexSpanColor(221, 160, 221, 255),
  'powderblue': KatexSpanColor(176, 224, 230, 255),
  'purple': KatexSpanColor(128, 0, 128, 255),
  'rebeccapurple': KatexSpanColor(102, 51, 153, 255),
  'red': KatexSpanColor(255, 0, 0, 255),
  'rosybrown': KatexSpanColor(188, 143, 143, 255),
  'royalblue': KatexSpanColor(65, 105, 225, 255),
  'saddlebrown': KatexSpanColor(139, 69, 19, 255),
  'salmon': KatexSpanColor(250, 128, 114, 255),
  'sandybrown': KatexSpanColor(244, 164, 96, 255),
  'seagreen': KatexSpanColor(46, 139, 87, 255),
  'seashell': KatexSpanColor(255, 245, 238, 255),
  'sienna': KatexSpanColor(160, 82, 45, 255),
  'silver': KatexSpanColor(192, 192, 192, 255),
  'skyblue': KatexSpanColor(135, 206, 235, 255),
  'slateblue': KatexSpanColor(106, 90, 205, 255),
  'slategray': KatexSpanColor(112, 128, 144, 255),
  'slategrey': KatexSpanColor(112, 128, 144, 255),
  'snow': KatexSpanColor(255, 250, 250, 255),
  'springgreen': KatexSpanColor(0, 255, 127, 255),
  'steelblue': KatexSpanColor(70, 130, 180, 255),
  'tan': KatexSpanColor(210, 180, 140, 255),
  'teal': KatexSpanColor(0, 128, 128, 255),
  'thistle': KatexSpanColor(216, 191, 216, 255),
  'tomato': KatexSpanColor(255, 99, 71, 255),
  'turquoise': KatexSpanColor(64, 224, 208, 255),
  'violet': KatexSpanColor(238, 130, 238, 255),
  'wheat': KatexSpanColor(245, 222, 179, 255),
  'white': KatexSpanColor(255, 255, 255, 255),
  'whitesmoke': KatexSpanColor(245, 245, 245, 255),
  'yellow': KatexSpanColor(255, 255, 0, 255),
  'yellowgreen': KatexSpanColor(154, 205, 50, 255),
};

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
