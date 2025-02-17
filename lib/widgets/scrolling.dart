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
