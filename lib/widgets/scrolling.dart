import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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

/// A simulation of motion at a constant velocity.
///
/// Models a particle that follows Newton's law of inertia,
/// with no forces acting on the particle, and no end to the motion.
///
/// See also [GravitySimulation], which adds a constant acceleration
/// and a stopping point.
class InertialSimulation extends Simulation { // TODO(upstream)
  InertialSimulation(double initialPosition, double velocity)
   : _x0 = initialPosition, _v = velocity;

  final double _x0;
  final double _v;

  @override
  double x(double time) => _x0 + _v * time;

  @override
  double dx(double time) => _v;

  @override
  bool isDone(double time) => false;

  @override
  String toString() => '${objectRuntimeType(this, 'InertialSimulation')}('
    'x₀: ${_x0.toStringAsFixed(1)}, dx₀: ${_v.toStringAsFixed(1)})';
}

/// A simulation of the user impatiently scrolling to the end of a list.
///
/// The position [x] is in logical pixels, and time is in seconds.
///
/// The motion is meant to resemble the user scrolling the list down
/// (by dragging up and flinging), and if the list is long then
/// fling-scrolling again and again to keep it moving quickly.
///
/// In that scenario taken literally, the motion would repeatedly slow down,
/// then speed up again with a fresh drag and fling.  But doing that in
/// response to a simulated drag, as opposed to when the user is actually
/// dragging with their own finger, would feel jerky and not a good UX.
/// Instead this takes a smoothed-out approximation of such a trajectory.
class ScrollToEndSimulation extends InertialSimulation {
  factory ScrollToEndSimulation(ScrollPosition position) {
    final tolerance = position.physics.toleranceFor(position);
    final startPosition = position.pixels;
    final estimatedEndPosition = position.maxScrollExtent;
    final velocityForMinDuration = (estimatedEndPosition - startPosition)
      / (minDuration.inMilliseconds / 1000.0);
    final velocity = clampDouble(velocityForMinDuration,
      // If the starting position is beyond the estimated end
      // (i.e. `velocityForMinDuration < 0`), or very close to it,
      // then move forward at a small positive velocity.
      // Let the overscroll handling bring the position to exactly the end.
      2 * tolerance.velocity,
      topSpeed);
    return ScrollToEndSimulation._(startPosition, velocity);
  }

  ScrollToEndSimulation._(super.initialPosition, super.velocity);

  /// The top speed to move at, in logical pixels per second.
  ///
  /// This will be the speed whenever the estimated distance to be traveled
  /// is long enough to take at least [minDuration] at this speed.
  ///
  /// This is chosen to equal the top speed that can be produced
  /// by a fling gesture in a Flutter [ScrollView],
  /// which in turn was chosen to equal the top speed of
  /// an (initial) fling gesture in a native Android scroll view.
  static const double topSpeed = 8000;

  /// The desired duration of the animation when traveling short distances.
  ///
  /// The speed will be chosen so that traveling the estimated distance
  /// will take this long, whenever that distance is short enough
  /// that that means a speed of at most [topSpeed].
  static const minDuration = Duration(milliseconds: 300);
}

/// An activity that animates a scroll view smoothly to its end.
///
/// In particular this drives the "scroll to bottom" button
/// in the Zulip message list.
class ScrollToEndActivity extends DrivenScrollActivity {
  /// Create an activity that animates a scroll view smoothly to its end.
  ///
  /// The [delegate] is required to also implement [ScrollPosition].
  ScrollToEndActivity(ScrollActivityDelegate delegate)
    : super.simulation(delegate,
        vsync: (delegate as ScrollPosition).context.vsync,
        ScrollToEndSimulation(delegate as ScrollPosition));

  ScrollPosition get _position => delegate as ScrollPosition;

  @override
  bool applyMoveTo(double value) {
    bool done = false;
    if (value > _position.maxScrollExtent) {
      // The activity has reached the end.
      // Stop at exactly the end, rather than causing overscroll.
      // Possibly some overscroll would actually be desirable, but:
      // TODO(upstream) stretch-overscroll seems busted, inverted:
      //   Is this formula (from [_StretchController.absorbImpact] really right?
      //     _stretchSizeTween.end =
      //       math.min(_stretchIntensity + (_flingFriction / velocity), 1.0);
      //   Seems to take low velocity to the largest stretch, and high velocity
      //   to the smallest stretch.
      //   Specifically, a very slow fling produces a very large stretch,
      //   while other flings produce small stretches that vary little
      //   between modest speed (~300 px/s) and top speed (8000 px/s).
      value = _position.maxScrollExtent;
      done = true;
    }
    if (!super.applyMoveTo(value)) return false;
    return !done;
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

  // TODO(upstream): is the lack of [absorb] a bug in [_TabBarScrollPosition]?
  @override
  void absorb(ScrollPosition other) {
    super.absorb(other);
    if (other is! MessageListScrollPosition) return;
    _hasEverCompletedLayout = other._hasEverCompletedLayout;
  }

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
    // The origin point of these scroll coordinates, scroll extent 0.0,
    // is that the boundary between slivers is the bottom edge of the viewport.
    // (That's expressed by setting `anchor` to 1.0, consulted in
    // `_attemptLayout` below.)

    // The farthest the list can scroll down (moving the content up)
    // is to the point where the bottom end of the list
    // touches the bottom edge of the viewport.
    final effectiveMax = wholeMaxScrollExtent;

    // The farthest the list can scroll up (moving the content down)
    // is either:
    //   * the same as the farthest it can scroll down,
    //   * or the point where the top end of the list
    //     touches the top edge of the viewport,
    // whichever is farther up.
    final effectiveMin = math.min(effectiveMax,
      wholeMinScrollExtent + viewportDimension);

    // The first point comes into effect when the list is short,
    // so the whole thing fits into the viewport.  In that case,
    // the only scroll position allowed is with the bottom end of the list
    // at the bottom edge of the viewport.

    // The upstream answer (with no `applyContentDimensionsRaw`) would
    // effectively say:
    //   final effectiveMin = math.min(0.0,
    //     wholeMinScrollExtent + viewportDimension);
    //
    // In other words, the farthest the list can scroll up might be farther up
    // than the answer here: it could always scroll up to 0.0, meaning that the
    // boundary between slivers is at the bottom edge of the viewport.
    // Whenever the top sliver is shorter than the viewport (and the bottom
    // sliver isn't empty), this would mean one can scroll up past
    // the top of the list, even though that scrolls other content offscreen.

    return applyContentDimensions(effectiveMin, effectiveMax);
  }

  bool _nearEqual(double a, double b) =>
    nearEqual(a, b, Tolerance.defaultTolerance.distance);

  bool _hasEverCompletedLayout = false;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    // Inspired by _TabBarScrollPosition.applyContentDimensions upstream.
    bool changed = false;

    if (!_hasEverCompletedLayout) {
      // The list is being laid out for the first time (its first performLayout).
      // Start out scrolled down so the bottom sliver (the new messages)
      // occupies 75% of the viewport,
      // or at the in-range scroll position closest to that.
      // This also brings [pixels] within bounds, which
      // the initial value of 0.0 might not have been.
      final target = clampDouble(0.75 * viewportDimension,
        minScrollExtent, maxScrollExtent);
      if (!hasPixels || pixels != target) {
        correctPixels(target);
        changed = true;
      }
    } else if (_nearEqual(pixels, this.maxScrollExtent)
        && !_nearEqual(pixels, maxScrollExtent)) {
      // The list was scrolled to the end before this layout round.
      // Make sure it stays at the end.
      // (For example, show the new message that just arrived.)
      correctPixels(maxScrollExtent);
      changed = true;
    }

    // This step must come after the first-time correction above.
    // Otherwise, if the initial [pixels] value of 0.0 was out of bounds
    // (which happens if the top slivers are shorter than the viewport),
    // then the base implementation of [applyContentDimensions] would
    // bring it in bounds via a scrolling animation, which isn't right when
    // starting from the meaningless initial 0.0 value.
    //
    // For the "stays at the end" correction, it's not clear if the order
    // matters in practice.  But the doc on [applyNewDimensions], called by
    // the base [applyContentDimensions], says it should come after any
    // calls to [correctPixels]; so OK, do this after the [correctPixels].
    if (!super.applyContentDimensions(minScrollExtent, maxScrollExtent)) {
      changed = true;
    }

    if (!changed) {
      // Because this method is about to return true,
      // this will be the last round of this layout.
      _hasEverCompletedLayout = true;
    }

    return !changed;
  }

  /// Scroll the position smoothly to the end of the scrollable content.
  ///
  /// This is similar to calling [animateTo] with a target of [maxScrollExtent],
  /// except that if [maxScrollExtent] changes over the course of the animation
  /// (for example due to more content being added at the end,
  /// or due to the estimated length of the content changing as
  /// different items scroll into the viewport),
  /// this animation will carry on until it reaches the updated value
  /// of [maxScrollExtent], not the value it had at the start of the animation.
  ///
  /// The animation is typically handled by a [ScrollToEndActivity].
  void scrollToEnd() {
    final tolerance = physics.toleranceFor(this);
    if (nearEqual(pixels, maxScrollExtent, tolerance.distance)) {
      // Skip the animation; jump right to the target, which is already close.
      jumpTo(maxScrollExtent);
      return;
    }

    if (pixels > maxScrollExtent) {
      // The position is already scrolled past the end.  Let overscroll handle it.
      // (This situation shouldn't even arise; the UI only offers this option
      // when `pixels < maxScrollExtent`.)
      goBallistic(0.0);
      return;
    }

    beginActivity(ScrollToEndActivity(this));
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
  MessageListScrollPosition get position => super.position as MessageListScrollPosition;

  @override
  MessageListScrollPosition createScrollPosition(ScrollPhysics physics,
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
class MessageListScrollView extends CustomScrollView {
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
      paintOrder: paintOrder,
    );
  }
}

/// The version of [Viewport] that underlies [MessageListScrollView].
class MessageListViewport extends Viewport {
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
    required super.paintOrder,
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
      paintOrder: paintOrder,
    );
  }
}

/// The version of [RenderViewport] that underlies [MessageListViewport]
/// and [MessageListScrollView].
// TODO(upstream): Devise upstream APIs to obviate the duplicated code here;
//   use `git log -L` to see what edits we've made locally.
class RenderMessageListViewport extends RenderViewport {
  RenderMessageListViewport({
    super.axisDirection,
    required super.crossAxisDirection,
    required super.offset,
    super.children,
    super.center,
    super.cacheExtent,
    super.cacheExtentStyle,
    super.clipBehavior,
    required super.paintOrder,
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
