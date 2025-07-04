import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import '../model/content.dart';
import '../model/katex.dart';
import 'content.dart';

/// Creates a base text style for rendering KaTeX content.
///
/// This applies the CSS styles defined in .katex class in katex.scss :
///   https://github.com/KaTeX/KaTeX/blob/613c3da8/src/styles/katex.scss#L13-L15
///
/// Requires the [style.fontSize] to be non-null.
TextStyle mkBaseKatexTextStyle(TextStyle style) {
  return style.copyWith(
    fontSize: style.fontSize! * 1.21,
    fontFamily: 'KaTeX_Main',
    height: 1.2,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    textBaseline: TextBaseline.alphabetic,
    leadingDistribution: TextLeadingDistribution.even,
    decoration: TextDecoration.none,
    fontFamilyFallback: const []);
}

@visibleForTesting
class KatexWidget extends StatelessWidget {
  const KatexWidget({
    super.key,
    required this.textStyle,
    required this.nodes,
  });

  final TextStyle textStyle;
  final List<KatexNode> nodes;

  @override
  Widget build(BuildContext context) {
    Widget widget = _KatexNodeList(nodes: nodes);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: mkBaseKatexTextStyle(textStyle).copyWith(
          color: ContentTheme.of(context).textStylePlainParagraph.color),
        child: widget));
  }
}

class _KatexNodeList extends StatelessWidget {
  const _KatexNodeList({required this.nodes});

  final List<KatexNode> nodes;

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(
      children: List.unmodifiable(nodes.map((e) {
        return WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          // Work around a bug where text inside a WidgetSpan could be scaled
          // multiple times incorrectly, if the system font scale is larger
          // than 1x.
          // See: https://github.com/flutter/flutter/issues/126962
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.noScaling),
            child: switch (e) {
              KatexSpanNode() => _KatexSpan(e),
              KatexStrutNode() => _KatexStrut(e),
              KatexVlistNode() => _KatexVlist(e),
              KatexNegativeMarginNode() => _KatexNegativeMargin(e),
            }));
      }))));
  }
}

class _KatexSpan extends StatelessWidget {
  const _KatexSpan(this.node);

  final KatexSpanNode node;

  @override
  Widget build(BuildContext context) {
    var em = DefaultTextStyle.of(context).style.fontSize!;

    Widget widget = const SizedBox.shrink();
    if (node.text != null) {
      widget = Text(node.text!);
    } else if (node.nodes != null && node.nodes!.isNotEmpty) {
      widget = _KatexNodeList(nodes: node.nodes!);
    }

    final styles = node.styles;

    // Currently, we expect `top` to be only present with the
    // vlist inner row span, and parser handles that explicitly.
    assert(styles.topEm == null);

    final fontFamily = styles.fontFamily;
    final fontSize = switch (styles.fontSizeEm) {
      double fontSizeEm => fontSizeEm * em,
      null => null,
    };
    if (fontSize != null) em = fontSize;

    final fontWeight = switch (styles.fontWeight) {
      KatexSpanFontWeight.bold => FontWeight.bold,
      null => null,
    };
    var fontStyle = switch (styles.fontStyle) {
      KatexSpanFontStyle.normal => FontStyle.normal,
      KatexSpanFontStyle.italic => FontStyle.italic,
      null => null,
    };
    final color = switch (styles.color) {
      KatexSpanColor katexColor =>
        Color.fromARGB(katexColor.a, katexColor.r, katexColor.g, katexColor.b),
      null => null,
    };

    TextStyle? textStyle;
    if (fontFamily != null ||
        fontSize != null ||
        fontWeight != null ||
        fontStyle != null ||
        color != null) {
      // TODO(upstream) remove this workaround when upstream fixes the broken
      //   rendering of KaTeX_Math font with italic font style on Android:
      //     https://github.com/flutter/flutter/issues/167474
      if (defaultTargetPlatform == TargetPlatform.android &&
          fontFamily == 'KaTeX_Math') {
        fontStyle = FontStyle.normal;
      }

      textStyle = TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
      );
    }
    final textAlign = switch (styles.textAlign) {
      KatexSpanTextAlign.left => TextAlign.left,
      KatexSpanTextAlign.center => TextAlign.center,
      KatexSpanTextAlign.right => TextAlign.right,
      null => null,
    };

    if (textStyle != null || textAlign != null) {
      widget = DefaultTextStyle.merge(
        style: textStyle,
        textAlign: textAlign,
        child: widget);
    }

    widget = SizedBox(
      height: styles.heightEm != null
        ? styles.heightEm! * em
        : null,
      child: widget);

    final margin = switch ((styles.marginLeftEm, styles.marginRightEm)) {
      (null, null) => null,
      (null, final marginRightEm?) =>
        EdgeInsets.only(right: marginRightEm * em),
      (final marginLeftEm?, null) =>
        EdgeInsets.only(left: marginLeftEm * em),
      (final marginLeftEm?, final marginRightEm?) =>
        EdgeInsets.only(left: marginLeftEm * em, right: marginRightEm * em),
    };

    if (margin != null) {
      assert(margin.isNonNegative);
      widget = Padding(padding: margin, child: widget);
    }

    return widget;
  }
}

class _KatexStrut extends StatelessWidget {
  const _KatexStrut(this.node);

  final KatexStrutNode node;

  @override
  Widget build(BuildContext context) {
    final em = DefaultTextStyle.of(context).style.fontSize!;

    final verticalAlignEm = node.verticalAlignEm;
    if (verticalAlignEm == null) {
      return SizedBox(height: node.heightEm * em);
    }

    return SizedBox(
      height: node.heightEm * em,
      child: Baseline(
        baseline: (verticalAlignEm + node.heightEm) * em,
        baselineType: TextBaseline.alphabetic,
        child: const Text('')),
    );
  }
}

class _KatexVlist extends StatelessWidget {
  const _KatexVlist(this.node);

  final KatexVlistNode node;

  @override
  Widget build(BuildContext context) {
    final em = DefaultTextStyle.of(context).style.fontSize!;

    return Stack(children: List.unmodifiable(node.rows.map((row) {
      return Transform.translate(
        offset: Offset(0, row.verticalOffsetEm * em),
        child: _KatexSpan(row.node));
    })));
  }
}

class _KatexNegativeMargin extends StatelessWidget {
  const _KatexNegativeMargin(this.node);

  final KatexNegativeMarginNode node;

  @override
  Widget build(BuildContext context) {
    final em = DefaultTextStyle.of(context).style.fontSize!;

    return NegativeLeftOffset(
      leftOffset: node.leftOffsetEm * em,
      child: _KatexNodeList(nodes: node.nodes));
  }
}

class NegativeLeftOffset extends SingleChildRenderObjectWidget {
  NegativeLeftOffset({super.key, required this.leftOffset, super.child})
    : assert(leftOffset.isNegative),
      _padding = EdgeInsets.only(left: leftOffset);

  final double leftOffset;
  final EdgeInsetsGeometry _padding;

  @override
  RenderNegativePadding createRenderObject(BuildContext context) {
    return RenderNegativePadding(
      padding: _padding,
      textDirection: Directionality.maybeOf(context));
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderNegativePadding renderObject,
  ) {
    renderObject
      ..padding = _padding
      ..textDirection = Directionality.maybeOf(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', _padding));
  }
}

// Like [RenderPadding] but only supports negative values.
// TODO(upstream): give Padding an option to accept negative padding (at cost of hit-testing not working)
class RenderNegativePadding extends RenderShiftedBox {
  RenderNegativePadding({
    required EdgeInsetsGeometry padding,
    TextDirection? textDirection,
    RenderBox? child,
  }) : assert(!padding.isNonNegative),
       _textDirection = textDirection,
       _padding = padding,
       super(child);

  EdgeInsets? _resolvedPaddingCache;
  EdgeInsets get _resolvedPadding {
    final EdgeInsets returnValue = _resolvedPaddingCache ??= padding.resolve(textDirection);
    return returnValue;
  }

  void _markNeedResolution() {
    _resolvedPaddingCache = null;
    markNeedsLayout();
  }

  /// The amount to pad the child in each dimension.
  ///
  /// If this is set to an [EdgeInsetsDirectional] object, then [textDirection]
  /// must not be null.
  EdgeInsetsGeometry get padding => _padding;
  EdgeInsetsGeometry _padding;
  set padding(EdgeInsetsGeometry value) {
    assert(!value.isNonNegative);
    if (_padding == value) {
      return;
    }
    _padding = value;
    _markNeedResolution();
  }

  /// The text direction with which to resolve [padding].
  ///
  /// This may be changed to null, but only after the [padding] has been changed
  /// to a value that does not depend on the direction.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _markNeedResolution();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final EdgeInsets padding = _resolvedPadding;
    if (child != null) {
      // Relies on double.infinity absorption.
      return child!.getMinIntrinsicWidth(math.max(0.0, height - padding.vertical)) +
          padding.horizontal;
    }
    return padding.horizontal;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final EdgeInsets padding = _resolvedPadding;
    if (child != null) {
      // Relies on double.infinity absorption.
      return child!.getMaxIntrinsicWidth(math.max(0.0, height - padding.vertical)) +
          padding.horizontal;
    }
    return padding.horizontal;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final EdgeInsets padding = _resolvedPadding;
    if (child != null) {
      // Relies on double.infinity absorption.
      return child!.getMinIntrinsicHeight(math.max(0.0, width - padding.horizontal)) +
          padding.vertical;
    }
    return padding.vertical;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final EdgeInsets padding = _resolvedPadding;
    if (child != null) {
      // Relies on double.infinity absorption.
      return child!.getMaxIntrinsicHeight(math.max(0.0, width - padding.horizontal)) +
          padding.vertical;
    }
    return padding.vertical;
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final EdgeInsets padding = _resolvedPadding;
    if (child == null) {
      return constraints.constrain(Size(padding.horizontal, padding.vertical));
    }
    final BoxConstraints innerConstraints = constraints.deflate(padding);
    final Size childSize = child!.getDryLayout(innerConstraints);
    return constraints.constrain(
      Size(padding.horizontal + childSize.width, padding.vertical + childSize.height),
    );
  }

  @override
  double? computeDryBaseline(covariant BoxConstraints constraints, TextBaseline baseline) {
    final RenderBox? child = this.child;
    if (child == null) {
      return null;
    }
    final EdgeInsets padding = _resolvedPadding;
    final BoxConstraints innerConstraints = constraints.deflate(padding);
    final BaselineOffset result =
        BaselineOffset(child.getDryBaseline(innerConstraints, baseline)) + padding.top;
    return result.offset;
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    final EdgeInsets padding = _resolvedPadding;
    if (child == null) {
      size = constraints.constrain(Size(padding.horizontal, padding.vertical));
      return;
    }
    final BoxConstraints innerConstraints = constraints.deflate(padding);
    child!.layout(innerConstraints, parentUsesSize: true);
    final BoxParentData childParentData = child!.parentData! as BoxParentData;
    childParentData.offset = Offset(padding.left, padding.top);
    size = constraints.constrain(
      Size(padding.horizontal + child!.size.width, padding.vertical + child!.size.height),
    );
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      final Rect outerRect = offset & size;
      debugPaintPadding(
        context.canvas,
        outerRect,
        child != null ? _resolvedPaddingCache!.deflateRect(outerRect) : null,
      );
      return true;
    }());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
  }
}
