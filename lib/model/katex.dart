import 'package:csslib/visitor.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:csslib/parser.dart' as css;

import 'content.dart';

class KatexHtmlParseError extends Error {
  KatexHtmlParseError([this.message]);
  final String? message;

  @override
  String toString() {
    if (message != null) {
      return 'Katex HTML parse error: $message';
    }
    return 'Katex HTML parse error';
  }
}

// enum KatexSpanClass {
//   accent,
//   base,
//   mathnormal,
//   mclose,
//   minner,
//   mop,
//   mopen,
//   mord,
//   mrel,
//   mspace,
//   newline,
//   nulldelimiter,
//   sqrt,
//   strut,
//   mfrac,
//   opSymbol,
//   opLimits,
//   vlistT,
//   delimcenter,
//   vlistT2,
//   largeOp,
//   vlistR,
//   delimsizing,
//   vlist,
//   msupsub,
//   size4,
//   svgAlign,
//   pstrut,
//   mtable,
//   size2,
//   sizing,
//   hideTail,
//   accentBody,
//   colAlignL,
//   vlistS,
//   resetSize6,
//   overlay,
//   mbin,
//   size3,
//   mtight,
//   arraycolsep,
//   resetSize3,
//   vbox,
//   text,
//   size6,
//   size1,
//   thinbox,
//   fracLine,
//   clap,
//   resetSize1,
//   inner,
//   fix,
//   size11,
//   size10,
//   size9,
//   size8,
//   size7,
//   textrm
// }

class KatexSpanStyle {
  KatexSpanStyle({
    this.borderBottomWidth,
    this.height,
    this.left,
    this.marginLeft,
    this.marginRight,
    this.minWidth,
    this.paddingLeft,
    this.top,
    this.verticalAlign,
    this.width,
  });

  final double? borderBottomWidth;
  final double? height;
  final double? left;
  final double? marginLeft;
  final double? marginRight;
  final double? minWidth;
  final double? paddingLeft;
  final double? top;
  final double? verticalAlign;
  final double? width;

  @override
  bool operator ==(Object other) {
    return other is KatexSpanStyle &&
      other.borderBottomWidth == borderBottomWidth &&
      other.height == height &&
      other.left == left &&
      other.marginLeft == marginLeft &&
      other.marginRight == marginRight &&
      other.minWidth == minWidth &&
      other.paddingLeft == paddingLeft &&
      other.top == top &&
      other.verticalAlign == verticalAlign &&
      other.width == width;
  }

  @override
  int get hashCode => Object.hash(
    'KatexSpanStyle',
    borderBottomWidth,
    height,
    left,
    marginLeft,
    marginRight,
    minWidth,
    paddingLeft,
    top,
    verticalAlign,
    width,
  );

  @override
  String toString() {
    return '${objectRuntimeType(this, 'KatexSpanStyle')}('
      'borderBottomWidth: $borderBottomWidth, '
      'height: $height, '
      'left: $left, '
      'marginLeft: $marginLeft, '
      'marginRight: $marginRight, '
      'minWidth: $minWidth, '
      'paddingLeft: $paddingLeft, '
      'top: $top, '
      'verticalAlign: $verticalAlign, '
      'width: $width'
      ')';
  }
}

class KatexSpanStyleProperty extends DiagnosticsProperty<KatexSpanStyle> {
  KatexSpanStyleProperty(super.name, super.value);
}

// List<KatexSpanClass> _parseSpanClasses(String className) {
//   return List.unmodifiable(
//     className
//       .split(' ')
//       .map((cls) => switch (cls) {
//         '' => null,
//         'accent' => KatexSpanClass.accent,
//         'base' => KatexSpanClass.base,
//         'mathnormal' => KatexSpanClass.mathnormal,
//         'mclose' => KatexSpanClass.mclose,
//         'minner' => KatexSpanClass.minner,
//         'mop' => KatexSpanClass.mop,
//         'mopen' => KatexSpanClass.mopen,
//         'mord' => KatexSpanClass.mord,
//         'mrel' => KatexSpanClass.mrel,
//         'mspace' => KatexSpanClass.mspace,
//         'newline' => KatexSpanClass.newline,
//         'nulldelimiter' => KatexSpanClass.nulldelimiter,
//         'sqrt' => KatexSpanClass.sqrt,
//         'strut' => KatexSpanClass.strut,
//         'mfrac' => KatexSpanClass.mfrac,
//         'op-symbol' => KatexSpanClass.opSymbol,
//         'op-limits' => KatexSpanClass.opLimits,
//         'vlist-t' => KatexSpanClass.vlistT,
//         'delimcenter' => KatexSpanClass.delimcenter,
//         'vlist-t2' => KatexSpanClass.vlistT2,
//         'large-op' => KatexSpanClass.largeOp,
//         'vlist-r' => KatexSpanClass.vlistR,
//         'delimsizing' => KatexSpanClass.delimsizing,
//         'vlist' => KatexSpanClass.vlist,
//         'msupsub' => KatexSpanClass.msupsub,
//         'size4' => KatexSpanClass.size4,
//         'svg-align' => KatexSpanClass.svgAlign,
//         'pstrut' => KatexSpanClass.pstrut,
//         'mtable' => KatexSpanClass.mtable,
//         'size2' => KatexSpanClass.size2,
//         'sizing' => KatexSpanClass.sizing,
//         'hide-tail' => KatexSpanClass.hideTail,
//         'accent-body' => KatexSpanClass.accentBody,
//         'col-align-l' => KatexSpanClass.colAlignL,
//         'vlist-s' => KatexSpanClass.vlistS,
//         'reset-size6' => KatexSpanClass.resetSize6,
//         'overlay' => KatexSpanClass.overlay,
//         'mbin' => KatexSpanClass.mbin,
//         'size3' => KatexSpanClass.size3,
//         'mtight' => KatexSpanClass.mtight,
//         'arraycolsep' => KatexSpanClass.arraycolsep,
//         'reset-size3' => KatexSpanClass.resetSize3,
//         'vbox' => KatexSpanClass.vbox,
//         'text' => KatexSpanClass.text,
//         'size6' => KatexSpanClass.size6,
//         'size1' => KatexSpanClass.size1,
//         'thinbox' => KatexSpanClass.thinbox,
//         'frac-line' => KatexSpanClass.fracLine,
//         'clap' => KatexSpanClass.clap,
//         'reset-size1' => KatexSpanClass.resetSize1,
//         'inner' => KatexSpanClass.inner,
//         'fix' => KatexSpanClass.fix,
//         'size10' => KatexSpanClass.size10,
//         'size11' => KatexSpanClass.size11,
//         'size9' => KatexSpanClass.size9,
//         'size8' => KatexSpanClass.size8,
//         'size7' => KatexSpanClass.size7,
//         'textrm' => KatexSpanClass.textrm,
//         _ => throw KatexHtmlParseError('Unknown span class \'$cls\''),
//       })
//       .nonNulls,
//   );
// }

double? _getEm(Expression expression) {
  if (expression is EmTerm && expression.value is num) {
    return (expression.value as num).toDouble();
  }
  return null;
}

String? _getLiteral(Expression expression) {
  if (expression is LiteralTerm && expression.value is Identifier) {
    return (expression.value as Identifier).name;
  }
  return null;
}

KatexSpanStyle? _parseSpanStyle(dom.Element element) {
  if (element.attributes case {'style': final styleStr}) {
    final stylesheet = css.parse('*{$styleStr}');
    final topLevels = stylesheet.topLevels;
    if (topLevels.length != 1) throw KatexHtmlParseError();
    final topLevel = topLevels.single;
    if (topLevel is! RuleSet) throw KatexHtmlParseError();
    final rule = topLevel;

    double? borderBottomWidth;
    double? height;
    double? left;
    double? marginLeft;
    double? marginRight;
    double? minWidth;
    double? paddingLeft;
    double? top;
    double? verticalAlign;
    double? width;

    for (final declaration in rule.declarationGroup.declarations) {
      if (declaration is! Declaration) throw KatexHtmlParseError();
      final property = declaration.property;

      final expressions = declaration.expression;
      if (expressions is! Expressions) throw KatexHtmlParseError();
      if (expressions.expressions.length != 1) throw KatexHtmlParseError();
      final expression = expressions.expressions.single;

      switch (property) {
        case 'border-bottom-width':
          borderBottomWidth = _getEm(expression);
          if (borderBottomWidth != null) continue;

        case 'height':
          height = _getEm(expression);
          if (height != null) continue;

        case 'left':
          left = _getEm(expression);
          if (left != null) continue;

        case 'margin-left':
          marginLeft = _getEm(expression);
          if (marginLeft != null) continue;

        case 'margin-right':
          marginRight = _getEm(expression);
          if (marginRight != null) continue;

        case 'min-width':
          minWidth = _getEm(expression);
          if (minWidth != null) continue;

        case 'padding-left':
          paddingLeft = _getEm(expression);
          if (paddingLeft != null) continue;

        case 'top':
          top = _getEm(expression);
          if (top != null) continue;

        case 'vertical-align':
          verticalAlign = _getEm(expression);
          if (verticalAlign != null) continue;

        case 'width':
          width = _getEm(expression);
          if (width != null) continue;

        case 'position':
          assert(_getLiteral(expression) == 'relative');
          continue;
      }

      throw KatexHtmlParseError('Unknown $property with expression of type ${expression.runtimeType}');
    }

    return KatexSpanStyle(
      borderBottomWidth: borderBottomWidth,
      height: height,
      left: left,
      marginLeft: marginLeft,
      marginRight: marginRight,
      minWidth: minWidth,
      paddingLeft: paddingLeft,
      top: top,
      verticalAlign: verticalAlign);
  }
  return null;
}

KatexSpan _parseSpan(dom.Element element) {
  // final spanClasses = _parseSpanClasses(element.className);
  final spanClasses = List<String>.unmodifiable(element.className.split(' '));
  final spanStyle = _parseSpanStyle(element);

  String? text;
  List<KatexSpan>? spans;
  if (element.nodes case [dom.Text(data: final data)]) {
    text = data;
  } else {
    spans = List.unmodifiable(
      element.nodes.map((node) {
        if (node is! dom.Element) throw KatexHtmlParseError();
        return _parseSpan(node);
      }));
  }

  if (text == null && spans == null) throw KatexHtmlParseError();

  return KatexSpan(
    spanClasses: spanClasses,
    spanStyle: spanStyle,
    text: text,
    spans: spans ?? const []);
}

List<KatexSpan> parseKatexSpans(dom.Element element) {
  assert(element.localName == 'span');
  assert(element.className == 'katex-html');

  final r = <KatexSpan>[];
  for (final node in element.nodes) {
    if (node is! dom.Element) throw KatexHtmlParseError();
    r.add(_parseSpan(node));
  }
  return r;
}
