import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A [SingleChildScrollView] that always shows a Material [Scrollbar].
///
/// This differs from the behavior provided by [MaterialScrollBehavior] in that
/// (a) the scrollbar appears even when [scrollDirection] is [Axis.horizontal],
/// and (b) the scrollbar appears on all platforms, rather than only on
/// desktop platforms.
// TODO(upstream): SingleChildScrollView should have a scrollBehavior field
//   and pass it on to Scrollable, just like ScrollView does; then this would
//   be covered by using that.
// TODO: Maybe show scrollbar only on mobile platforms, like MaterialScrollBehavior
//   and the base ScrollBehavior do?
class SingleChildScrollViewWithScrollbar extends StatefulWidget {
  const SingleChildScrollViewWithScrollbar(
    {super.key, required this.scrollDirection, required this.child});

  final Axis scrollDirection;
  final Widget child;

  @override
  State<SingleChildScrollViewWithScrollbar> createState() =>
    _SingleChildScrollViewWithScrollbarState();
}

class _SingleChildScrollViewWithScrollbarState
    extends State<SingleChildScrollViewWithScrollbar> {
  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: controller,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: widget.scrollDirection,
        child: widget.child));
  }
}

/// Specifies an order in which to paint the slivers of a [CustomScrollView].
///
/// Whichever order the slivers are painted in,
/// they will be hit-tested in the opposite order.
///
/// This can also be thought of as an ordering in the z-direction:
/// whichever sliver is painted last (and hit-tested first) is on top,
/// because it will paint over other slivers if there is overlap.
/// Similarly, whichever sliver is painted first (and hit-tested last)
/// is on the bottom.
enum SliverPaintOrder {
  /// The first sliver paints on top, and the last sliver on bottom.
  ///
  /// The slivers are painted in the reverse order of [CustomScrollView.slivers],
  /// and hit-tested in the same order as [CustomScrollView.slivers].
  firstIsTop,

  /// The last sliver paints on top, and the first sliver on bottom.
  ///
  /// The slivers are painted in the same order as [CustomScrollView.slivers],
  /// and hit-tested in the reverse order.
  lastIsTop,

  /// The default order for [CustomScrollView]: the center sliver paints on top,
  /// and the first sliver paints on bottom.
  ///
  /// If [CustomScrollView.center] is null or corresponds to the first sliver
  /// in [CustomScrollView.slivers], this order is equivalent to [firstIsTop].
  /// Otherwise, the [CustomScrollView.center] sliver paints on top;
  /// it's followed in the z-order by the slivers after it to the end
  /// of the list, then the slivers before the center in reverse order,
  /// with the first sliver in the list at the bottom in the z-direction.
  centerTopFirstBottom,
}

/// A [CustomScrollView] with control over the paint order, or z-order,
/// between slivers.
///
/// This is just like [CustomScrollView] except it adds the [paintOrder_] field.
///
/// (Actually there's one [CustomScrollView] feature this doesn't implement:
/// [shrinkWrap] always has its default value of false.  That feature would be
/// easy to add if desired.)
// TODO(upstream): Pending PR: https://github.com/flutter/flutter/pull/164818
//   Notes from before sending that PR:
//   Add an option [ScrollView.zOrder]?  (An enum, or possibly
//   a delegate.)  Or at minimum document on [ScrollView.center] the
//   existing behavior, which is counterintuitive.
//   Nearest related upstream feature requests I find are for a "z-index",
//   for CustomScrollView, Column, Row, and Stack respectively:
//     https://github.com/flutter/flutter/issues/121173#issuecomment-1712825747
//     https://github.com/flutter/flutter/issues/121173
//     https://github.com/flutter/flutter/issues/121173#issuecomment-1914959184
//     https://github.com/flutter/flutter/issues/70836
//   A delegate would give enough flexibility for that and much else,
//   but I'm not sure how many use cases wouldn't be covered by a small enum.
//
//   Ah, and here's a more on-point issue (more recently):
//     https://github.com/flutter/flutter/issues/145592
//
// TODO: perhaps sticky_header should configure a CustomPaintOrderScrollView automatically?
class CustomPaintOrderScrollView extends CustomScrollView {
  const CustomPaintOrderScrollView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.scrollBehavior,
    // super.shrinkWrap, // omitted, always false
    super.center,
    super.anchor,
    super.cacheExtent,
    super.slivers,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    super.hitTestBehavior,
    SliverPaintOrder paintOrder = SliverPaintOrder.centerTopFirstBottom,
  }) : paintOrder_ = paintOrder;

  /// The order in which to paint the slivers;
  /// equivalently, the order in which to arrange them in the z-direction.
  ///
  /// Whichever order the slivers are painted in,
  /// they will be hit-tested in the opposite order.
  ///
  /// To think of this as an ordering in the z-direction:
  /// whichever sliver is painted last (and hit-tested first) is on top,
  /// because it will paint over other slivers if there is overlap.
  /// Similarly, whichever sliver is painted first (and hit-tested last)
  /// is on the bottom.
  ///
  /// This defaults to [SliverPaintOrder.centerTopFirstBottom],
  /// the behavior of the [CustomScrollView] base class.
  final SliverPaintOrder paintOrder_;

  @override
  Widget buildViewport(BuildContext context, ViewportOffset offset,
      AxisDirection axisDirection, List<Widget> slivers) {
    return CustomPaintOrderViewport(
      axisDirection: axisDirection,
      offset: offset,
      slivers: slivers,
      cacheExtent: cacheExtent,
      center: center,
      anchor: anchor,
      clipBehavior: clipBehavior,
      paintOrder_: paintOrder_,
    );
  }
}

/// The viewport configured by a [CustomPaintOrderScrollView].
class CustomPaintOrderViewport extends Viewport {
  CustomPaintOrderViewport({
    super.key,
    super.axisDirection,
    super.crossAxisDirection,
    super.anchor,
    required super.offset,
    super.center,
    super.cacheExtent,
    super.cacheExtentStyle,
    super.slivers,
    super.clipBehavior,
    required this.paintOrder_,
  });

  final SliverPaintOrder paintOrder_;

  @override
  RenderViewport createRenderObject(BuildContext context) {
    return RenderCustomPaintOrderViewport(
      axisDirection: axisDirection,
      crossAxisDirection: crossAxisDirection
        ?? Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      anchor: anchor,
      offset: offset,
      cacheExtent: cacheExtent,
      cacheExtentStyle: cacheExtentStyle,
      clipBehavior: clipBehavior,
      paintOrder_: paintOrder_,
    );
  }
}

/// The render object configured by a [CustomPaintOrderViewport].
class RenderCustomPaintOrderViewport extends RenderViewport {
  RenderCustomPaintOrderViewport({
    super.axisDirection,
    required super.crossAxisDirection,
    required super.offset,
    super.anchor,
    super.children,
    super.center,
    super.cacheExtent,
    super.cacheExtentStyle,
    super.clipBehavior,
    required this.paintOrder_,
  });

  final SliverPaintOrder paintOrder_;

  Iterable<RenderSliver> get _lastToFirst {
    final List<RenderSliver> children = <RenderSliver>[];
    RenderSliver? child = lastChild;
    while (child != null) {
      children.add(child);
      child = childBefore(child);
    }
    return children;
  }

  Iterable<RenderSliver> get _firstToLast {
    final List<RenderSliver> children = <RenderSliver>[];
    RenderSliver? child = firstChild;
    while (child != null) {
      children.add(child);
      child = childAfter(child);
    }
    return children;
  }

  @override
  Iterable<RenderSliver> get childrenInPaintOrder {
    return switch (paintOrder_) {
      SliverPaintOrder.firstIsTop => _lastToFirst,
      SliverPaintOrder.lastIsTop => _firstToLast,
      SliverPaintOrder.centerTopFirstBottom => super.childrenInPaintOrder,
    };
  }

  @override
  Iterable<RenderSliver> get childrenInHitTestOrder {
    return switch (paintOrder_) {
      SliverPaintOrder.firstIsTop => _firstToLast,
      SliverPaintOrder.lastIsTop => _lastToFirst,
      SliverPaintOrder.centerTopFirstBottom => super.childrenInHitTestOrder,
    };
  }
}

/// A version of [ScrollPosition] adapted for the Zulip message list,
/// used by [MessageListScrollController].
class MessageListScrollPosition extends ScrollPositionWithSingleContext {
  MessageListScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  /// Like [applyContentDimensions], but called without adjusting
  /// the arguments to subtract the viewport dimension.
  ///
  /// For instance, if there is 100.0 pixels of scrollable content
  /// of which 40.0 pixels is in the reverse-growing slivers and
  /// 60.0 pixels in the forward-growing slivers, then the arguments
  /// will be -40.0 and 60.0, regardless of the viewport dimension.
  ///
  /// By contrast in a call to [applyContentDimensions], in this example and
  /// if the viewport dimension is 80.0, then the arguments might be
  /// 0.0 and 60.0, or -10.0 and 10.0, or -40.0 and 0.0, or other values,
  /// depending on the value of [Viewport.anchor].
  bool applyContentDimensionsRaw(double wholeMinScrollExtent, double wholeMaxScrollExtent) {
    // This makes the simplifying assumption that `anchor` is 1.0.
    final effectiveMin = math.min(0.0, wholeMinScrollExtent + viewportDimension);
    final effectiveMax = wholeMaxScrollExtent;
    return applyContentDimensions(effectiveMin, effectiveMax);
  }
}

/// A version of [ScrollController] adapted for the Zulip message list.
class MessageListScrollController extends ScrollController {
  MessageListScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
  });

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
      ScrollContext context, ScrollPosition? oldPosition) {
    return MessageListScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

/// A version of [CustomScrollView] adapted for the Zulip message list.
///
/// This lets us customize behavior in ways that aren't currently supported
/// by the fields of [CustomScrollView] itself.
class MessageListScrollView extends CustomPaintOrderScrollView {
  const MessageListScrollView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.scrollBehavior,
    // super.shrinkWrap, // omitted, always false
    super.center,
    super.cacheExtent,
    super.slivers,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    super.hitTestBehavior,
    super.paintOrder,
  });

  @override
  Widget buildViewport(BuildContext context, ViewportOffset offset,
      AxisDirection axisDirection, List<Widget> slivers) {
    return MessageListViewport(
      axisDirection: axisDirection,
      offset: offset,
      slivers: slivers,
      cacheExtent: cacheExtent,
      center: center,
      clipBehavior: clipBehavior,
      paintOrder_: paintOrder_,
    );
  }
}

/// The version of [Viewport] that underlies [MessageListScrollView].
class MessageListViewport extends CustomPaintOrderViewport {
  MessageListViewport({
    super.key,
    super.axisDirection,
    super.crossAxisDirection,
    required super.offset,
    super.center,
    super.cacheExtent,
    super.cacheExtentStyle,
    super.slivers,
    super.clipBehavior,
    required super.paintOrder_,
  });

  @override
  RenderViewport createRenderObject(BuildContext context) {
    return RenderMessageListViewport(
      axisDirection: axisDirection,
      crossAxisDirection: crossAxisDirection
        ?? Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      offset: offset,
      cacheExtent: cacheExtent,
      cacheExtentStyle: cacheExtentStyle,
      clipBehavior: clipBehavior,
      paintOrder_: paintOrder_,
    );
  }
}

/// The version of [RenderViewport] that underlies [MessageListViewport]
/// and [MessageListScrollView].
// TODO(upstream): Devise upstream APIs to obviate the duplicated code here;
//   use `git log -L` to see what edits we've made locally.
class RenderMessageListViewport extends RenderCustomPaintOrderViewport {
  RenderMessageListViewport({
    super.axisDirection,
    required super.crossAxisDirection,
    required super.offset,
    super.children,
    super.center,
    super.cacheExtent,
    super.cacheExtentStyle,
    super.clipBehavior,
    required super.paintOrder_,
  });

  @override
  double get anchor => 1.0;

  double? _calculatedCacheExtent;

  @override
  Rect describeSemanticsClip(RenderSliver? child) {
    if (_calculatedCacheExtent == null) {
      return semanticBounds;
    }

    switch (axis) {
      case Axis.vertical:
        return Rect.fromLTRB(
          semanticBounds.left,
          semanticBounds.top - _calculatedCacheExtent!,
          semanticBounds.right,
          semanticBounds.bottom + _calculatedCacheExtent!,
        );
      case Axis.horizontal:
        return Rect.fromLTRB(
          semanticBounds.left - _calculatedCacheExtent!,
          semanticBounds.top,
          semanticBounds.right + _calculatedCacheExtent!,
          semanticBounds.bottom,
        );
    }
  }

  static const int _maxLayoutCyclesPerChild = 10;

  // Out-of-band data computed during layout.
  late double _minScrollExtent;
  late double _maxScrollExtent;
  bool _hasVisualOverflow = false;

  @override
  void performLayout() {
    // Ignore the return value of applyViewportDimension because we are
    // doing a layout regardless.
    switch (axis) {
      case Axis.vertical:
        offset.applyViewportDimension(size.height);
      case Axis.horizontal:
        offset.applyViewportDimension(size.width);
    }

    if (center == null) {
      assert(firstChild == null);
      _minScrollExtent = 0.0;
      _maxScrollExtent = 0.0;
      _hasVisualOverflow = false;
      offset.applyContentDimensions(0.0, 0.0);
      return;
    }
    assert(center!.parent == this);

    final (double mainAxisExtent, double crossAxisExtent) = switch (axis) {
      Axis.vertical => (size.height, size.width),
      Axis.horizontal => (size.width, size.height),
    };

    final double centerOffsetAdjustment = center!.centerOffsetAdjustment;
    final int maxLayoutCycles = _maxLayoutCyclesPerChild * childCount;

    double correction;
    int count = 0;
    do {
      correction = _attemptLayout(
        mainAxisExtent,
        crossAxisExtent,
        offset.pixels + centerOffsetAdjustment,
      );
      if (correction != 0.0) {
        offset.correctBy(correction);
      } else {
        // TODO(upstream): Move applyContentDimensionsRaw to ViewportOffset
        //   (possibly with an API change to tell it [anchor]?);
        //   give it a default implementation calling applyContentDimensions;
        //   have RenderViewport.performLayout call it.
        if ((offset as MessageListScrollPosition)
            .applyContentDimensionsRaw(_minScrollExtent, _maxScrollExtent)) {
          break;
        }
      }
      count += 1;
    } while (count < maxLayoutCycles);
    assert(() {
      if (count >= maxLayoutCycles) {
        assert(count != 1);
        throw FlutterError(
          'A RenderViewport exceeded its maximum number of layout cycles.\n'
          'RenderViewport render objects, during layout, can retry if either their '
          'slivers or their ViewportOffset decide that the offset should be corrected '
          'to take into account information collected during that layout.\n'
          'In the case of this RenderViewport object, however, this happened $count '
          'times and still there was no consensus on the scroll offset. This usually '
          'indicates a bug. Specifically, it means that one of the following three '
          'problems is being experienced by the RenderViewport object:\n'
          ' * One of the RenderSliver children or the ViewportOffset have a bug such'
          ' that they always think that they need to correct the offset regardless.\n'
          ' * Some combination of the RenderSliver children and the ViewportOffset'
          ' have a bad interaction such that one applies a correction then another'
          ' applies a reverse correction, leading to an infinite loop of corrections.\n'
          ' * There is a pathological case that would eventually resolve, but it is'
          ' so complicated that it cannot be resolved in any reasonable number of'
          ' layout passes.',
        );
      }
      return true;
    }());
  }

  double _attemptLayout(double mainAxisExtent, double crossAxisExtent, double correctedOffset) {
    assert(!mainAxisExtent.isNaN);
    assert(mainAxisExtent >= 0.0);
    assert(crossAxisExtent.isFinite);
    assert(crossAxisExtent >= 0.0);
    assert(correctedOffset.isFinite);
    _minScrollExtent = 0.0;
    _maxScrollExtent = 0.0;
    _hasVisualOverflow = false;

    // centerOffset is the offset from the leading edge of the RenderViewport
    // to the zero scroll offset (the line between the forward slivers and the
    // reverse slivers).
    assert(anchor == 1.0);
    final double centerOffset = mainAxisExtent * anchor - correctedOffset;
    final double reverseDirectionRemainingPaintExtent = clampDouble(
      centerOffset,
      0.0,
      mainAxisExtent,
    );
    final double forwardDirectionRemainingPaintExtent = clampDouble(
      mainAxisExtent - centerOffset,
      0.0,
      mainAxisExtent,
    );

    _calculatedCacheExtent = switch (cacheExtentStyle) {
      CacheExtentStyle.pixel => cacheExtent,
      CacheExtentStyle.viewport => mainAxisExtent * cacheExtent!,
    };

    final double fullCacheExtent = mainAxisExtent + 2 * _calculatedCacheExtent!;
    final double centerCacheOffset = centerOffset + _calculatedCacheExtent!;
    final double reverseDirectionRemainingCacheExtent = clampDouble(
      centerCacheOffset,
      0.0,
      fullCacheExtent,
    );
    final double forwardDirectionRemainingCacheExtent = clampDouble(
      fullCacheExtent - centerCacheOffset,
      0.0,
      fullCacheExtent,
    );

    final RenderSliver? leadingNegativeChild = childBefore(center!);

    if (leadingNegativeChild != null) {
      // negative scroll offsets
      final double result = layoutChildSequence(
        child: leadingNegativeChild,
        scrollOffset: math.max(mainAxisExtent, centerOffset) - mainAxisExtent,
        overlap: 0.0,
        layoutOffset: forwardDirectionRemainingPaintExtent,
        remainingPaintExtent: reverseDirectionRemainingPaintExtent,
        mainAxisExtent: mainAxisExtent,
        crossAxisExtent: crossAxisExtent,
        growthDirection: GrowthDirection.reverse,
        advance: childBefore,
        remainingCacheExtent: reverseDirectionRemainingCacheExtent,
        cacheOrigin: clampDouble(mainAxisExtent - centerOffset, -_calculatedCacheExtent!, 0.0),
      );
      if (result != 0.0) {
        return -result;
      }
    }

    // positive scroll offsets
    return layoutChildSequence(
      child: center,
      scrollOffset: math.max(0.0, -centerOffset),
      overlap: leadingNegativeChild == null ? math.min(0.0, -centerOffset) : 0.0,
      layoutOffset:
          centerOffset >= mainAxisExtent ? centerOffset : reverseDirectionRemainingPaintExtent,
      remainingPaintExtent: forwardDirectionRemainingPaintExtent,
      mainAxisExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
      growthDirection: GrowthDirection.forward,
      advance: childAfter,
      remainingCacheExtent: forwardDirectionRemainingCacheExtent,
      cacheOrigin: clampDouble(centerOffset, -_calculatedCacheExtent!, 0.0),
    );
  }

  @override
  bool get hasVisualOverflow => _hasVisualOverflow;

  @override
  void updateOutOfBandData(GrowthDirection growthDirection, SliverGeometry childLayoutGeometry) {
    switch (growthDirection) {
      case GrowthDirection.forward:
        _maxScrollExtent += childLayoutGeometry.scrollExtent;
      case GrowthDirection.reverse:
        _minScrollExtent -= childLayoutGeometry.scrollExtent;
    }
    if (childLayoutGeometry.hasVisualOverflow) {
      _hasVisualOverflow = true;
    }
  }

}
