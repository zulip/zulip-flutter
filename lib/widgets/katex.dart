import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

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
