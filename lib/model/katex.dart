import 'package:csslib/parser.dart' as css_parser;
import 'package:csslib/visitor.dart' as css_visitor;
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;

import '../log.dart';
import 'content.dart';

class KatexParser {
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
    //   https://github.com/KaTeX/KaTeX/blob/2fe1941b7e6c0603680ef6edd799bd8a8b46871a/src/styles/katex.scss
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

      // Work around the duplicated case statement with a new switch block,
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
                styles.fontSizeEm = sizes[resetSizeIdx - 1] * sizes[sizeIdx - 1];
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
            }
            if (styles.fontFamily == null) throw KatexHtmlParseError();

            index += 2;
            continue;
          }

          // Should be unreachable.
          throw KatexHtmlParseError();

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
      // in katex.scss .
      switch (spanClass) {
        case 'mord':
          classFound = true;
      }

      if (!classFound) _logError('KaTeX: Unsupported CSS class: $spanClass');

      index++;
    }

    String? text;
    List<KatexNode>? spans;
    if (element.nodes case [dom.Text(data: final data)]) {
      text = data;
    } else {
      spans = _parseChildSpans(element);
    }
    if (text == null && spans == null) throw KatexHtmlParseError();

    final inlineStyles = _parseSpanInlineStyles(element);

    return KatexNode(
      text: text,
      styles: inlineStyles != null
        ? styles.merge(inlineStyles)
        : styles,
      nodes: spans);
  }

  KatexSpanStyles? _parseSpanInlineStyles(dom.Element element) {
    if (element.attributes case {'style': final styleStr}) {
      final stylesheet = css_parser.parse('*{$styleStr}');
      final topLevels = stylesheet.topLevels;
      if (topLevels.length != 1) throw KatexHtmlParseError();
      final topLevel = topLevels.single;
      if (topLevel is! css_visitor.RuleSet) throw KatexHtmlParseError();
      final rule = topLevel;

      double? marginLeftEm;
      double? marginRightEm;
      double? paddingLeftEm;

      for (final declaration in rule.declarationGroup.declarations) {
        if (declaration is! css_visitor.Declaration) throw KatexHtmlParseError();
        final property = declaration.property;

        final expressions = declaration.expression;
        if (expressions is! css_visitor.Expressions) throw KatexHtmlParseError();
        if (expressions.expressions.length != 1) throw KatexHtmlParseError();
        final expression = expressions.expressions.single;

        switch (property) {
          case 'margin-left':
            marginLeftEm = _getEm(expression);
            if (marginLeftEm != null) continue;

          case 'margin-right':
            marginRightEm = _getEm(expression);
            if (marginRightEm != null) continue;

          case 'padding-left':
            paddingLeftEm = _getEm(expression);
            if (paddingLeftEm != null) continue;

          default:
            // TODO handle more CSS properties
            assert(debugLog('Unsupported CSS property: $property of type ${expression.runtimeType}'));
        }
      }

      return KatexSpanStyles(
        marginLeftEm: marginLeftEm,
        marginRightEm: marginRightEm,
        paddingLeftEm: paddingLeftEm,
      );
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
  double? marginLeftEm;
  double? marginRightEm;
  double? paddingLeftEm;

  String? fontFamily;
  double? fontSizeEm;
  KatexSpanFontStyle? fontStyle;
  KatexSpanFontWeight? fontWeight;
  KatexSpanTextAlign? textAlign;

  KatexSpanStyles({
    this.heightEm,
    this.marginLeftEm,
    this.marginRightEm,
    this.paddingLeftEm,
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
    marginLeftEm,
    marginRightEm,
    paddingLeftEm,
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
      other.marginLeftEm == marginLeftEm &&
      other.marginRightEm == marginRightEm &&
      other.paddingLeftEm == paddingLeftEm &&
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
    if (marginLeftEm != null) args.add('marginLeftEm: $marginLeftEm');
    if (marginRightEm != null) args.add('marginRightEm: $marginRightEm');
    if (paddingLeftEm != null) args.add('paddingLeftEm: $paddingLeftEm');
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
      marginLeftEm: other.marginLeftEm ?? marginLeftEm,
      marginRightEm: other.marginRightEm ?? marginRightEm,
      paddingLeftEm: other.paddingLeftEm ?? paddingLeftEm,
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
