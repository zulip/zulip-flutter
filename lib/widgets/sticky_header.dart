import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A list item that provides a sticky header for an enclosing [StickyHeaderListView].
///
/// This widget wraps its [child] with no effect on the latter's layout.
///
/// When this widget is a list item in a [StickyHeaderListView],
/// and is the item that the list selects for obtaining a sticky header,
/// then this widget's [header] widget is built and used as the sticky header.
class StickyHeaderItem extends SingleChildRenderObjectWidget {
  const StickyHeaderItem({
    super.key,
    this.allowOverflow = false,
    required this.header,
    super.child,
  });

  /// Whether to allow the sticky header to overflow the item's own bounds.
  ///
  /// When [allowOverflow] is false (the default) and an enclosing
  /// [StickyHeaderListView] displays a sticky header based on this item,
  /// the header will be scrolled partially out of the viewport if necessary
  /// in order to keep it within the bounds that were laid out for [child].
  ///
  /// When [allowOverflow] is true, such a header will be shown in full,
  /// adjoining the edge of the viewport, even if the underlying [child] would
  /// have been visible for a smaller extent than the extent of the header.
  final bool allowOverflow;

  /// The widget to use as the sticky header corresponding to this item.
  ///
  /// When this [StickyHeaderItem] is the list item at the applicable edge
  /// of the list in an enclosing [StickyHeaderListView], this [header] widget
  /// will be built and laid out to display as the sticky header.
  final Widget header;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderStickyHeaderItem(
      allowOverflow: allowOverflow,
      header: header,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderStickyHeaderItem renderObject) {
    renderObject
      ..allowOverflow = allowOverflow
      ..header = header;
  }
}

/// The render object configured by a [StickyHeaderItem].
class RenderStickyHeaderItem extends RenderProxyBox {
  RenderStickyHeaderItem({
    required bool allowOverflow,
    required Widget header,
  }) : _allowOverflow = allowOverflow,
       _header = header;

  bool get allowOverflow => _allowOverflow;
  bool _allowOverflow;
  set allowOverflow(bool value) {
    if (allowOverflow == value) return;
    _allowOverflow = value;
    markNeedsLayout();
  }

  Widget get header => _header;
  Widget _header;
  set header(Widget value) {
    if (header == value) return;
    _header = value;
    // Mark for layout, to cause the enclosing list to lay out
    // so that [_RenderSliverStickyListInner.performLayout] runs.
    markNeedsLayout();
  }
}

/// A list view with sticky headers.
///
/// This widget takes most of its behavior from [ListView].
/// It adds a mechanism for each list item to provide an additional widget
/// to be shown as a header at the start or end of the list's viewport,
/// remaining there unmoving even as the item scrolls underneath it,
/// as if "stuck" in place at the viewport's edge.
///
/// Specifically, after laying out the list for a given frame,
/// [StickyHeaderListView] examines the list item that spans the "header edge"
/// of the viewport (by default, the top edge).
/// If that item is a [StickyHeaderItem], then its [StickyHeaderItem.header]
/// widget will be built and laid out to show at the header edge of the
/// viewport, painting over the list items.
///
/// The header edge defaults to the top of the viewport,
/// or if [scrollDirection] is horizontal then to the start in the
/// reading direction of the ambient [Directionality].
/// It can be controlled with [reverseHeader].
class StickyHeaderListView extends BoxScrollView {
  // Like ListView, but with sticky headers.
  StickyHeaderListView({
    super.key,
    super.scrollDirection,
    super.reverse,
    this.reverseHeader = false,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    super.cacheExtent,
    List<Widget> children = const <Widget>[],
    int? semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : childrenDelegate = SliverChildListDelegate(
         children,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
         addSemanticIndexes: addSemanticIndexes,
       ),
       super(
         semanticChildCount: semanticChildCount ?? children.length,
       );

  // Like ListView.builder, but with sticky headers.
  StickyHeaderListView.builder({
    super.key,
    super.scrollDirection,
    super.reverse,
    this.reverseHeader = false,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required NullableIndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
    int? itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    super.cacheExtent,
    int? semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : assert(itemCount == null || itemCount >= 0),
       assert(semanticChildCount == null || semanticChildCount <= itemCount!),
       childrenDelegate = SliverChildBuilderDelegate(
         itemBuilder,
         findChildIndexCallback: findChildIndexCallback,
         childCount: itemCount,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
         addSemanticIndexes: addSemanticIndexes,
       ),
       super(
         semanticChildCount: semanticChildCount ?? itemCount,
       );

  // Like ListView.separated, but with sticky headers.
  StickyHeaderListView.separated({
    super.key,
    super.scrollDirection,
    super.reverse,
    this.reverseHeader = false,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required NullableIndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
    required IndexedWidgetBuilder separatorBuilder,
    required int itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    super.cacheExtent,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : assert(itemCount >= 0),
       childrenDelegate = SliverChildBuilderDelegate(
         (BuildContext context, int index) {
           final int itemIndex = index ~/ 2;
           final Widget? widget;
           if (index.isEven) {
             widget = itemBuilder(context, itemIndex);
           } else {
             widget = separatorBuilder(context, itemIndex);
             assert(() {
               if (widget == null) {
                 throw FlutterError('separatorBuilder cannot return null.');
               }
               return true;
             }());
           }
           return widget;
         },
         findChildIndexCallback: findChildIndexCallback,
         childCount: math.max(0, itemCount * 2 - 1),
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
         addSemanticIndexes: addSemanticIndexes,
         semanticIndexCallback: (Widget _, int index) {
           return index.isEven ? index ~/ 2 : null;
         },
       ),
       super(
         semanticChildCount: itemCount,
       );

  // Like ListView.custom, but with sticky headers.
  const StickyHeaderListView.custom({
    super.key,
    super.scrollDirection,
    super.reverse,
    this.reverseHeader = false,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required this.childrenDelegate,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  });

  /// Whether the sticky header appears at the end, instead of the start,
  /// in the reading direction.
  ///
  /// If [reverseHeader] is false (the default), then
  /// the header will appear at the reading start of the list.
  /// This is the top when [scrollDirection] is [Axis.vertical].
  /// For a horizontal-scrolling list, this is the left when the
  /// ambient [Directionality] has [TextDirection.ltr],
  /// and the right for [TextDirection.rtl].
  ///
  /// If [reverseHeader] is true, then the header will appear at the
  /// reading end of the list, which is the opposite side from the reading start.
  final bool reverseHeader;

  final SliverChildDelegate childrenDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    return SliverStickyHeaderList(
      headerPlacement: (reverseHeader ^ reverse)
        ? HeaderPlacement.scrollingEnd : HeaderPlacement.scrollingStart,
      delegate: childrenDelegate);
  }
}

/// Where a header goes, in terms of the list's scrolling direction.
///
/// For example if the list scrolls to the left, then
/// [scrollingStart] means the right edge of the list, regardless of whether
/// the ambient [Directionality] is RTL or LTR.
enum HeaderPlacement {
  scrollingStart,
  scrollingEnd;

  _HeaderGrowthPlacement _byGrowth(GrowthDirection growthDirection) {
    return switch ((growthDirection, this)) {
      (GrowthDirection.forward, scrollingStart) => _HeaderGrowthPlacement.growthStart,
      (GrowthDirection.forward, scrollingEnd)   => _HeaderGrowthPlacement.growthEnd,
      (GrowthDirection.reverse, scrollingStart) => _HeaderGrowthPlacement.growthEnd,
      (GrowthDirection.reverse, scrollingEnd)   => _HeaderGrowthPlacement.growthStart,
    };
  }
}

/// Where a header goes, in terms of the list sliver's growth direction.
///
/// This will agree with the [HeaderPlacement] value if the growth direction
/// is [GrowthDirection.forward], but contrast with it if the growth direction
/// is [GrowthDirection.reverse].  See [HeaderPlacement._byGrowth].
enum _HeaderGrowthPlacement {
  growthStart,
  growthEnd
}

class SliverStickyHeaderList extends RenderObjectWidget {
  SliverStickyHeaderList({
    super.key,
    required this.headerPlacement,
    required SliverChildDelegate delegate,
  }) : _child = _SliverStickyHeaderListInner(
    headerPlacement: headerPlacement,
    delegate: delegate,
  );

  final HeaderPlacement headerPlacement;
  final _SliverStickyHeaderListInner _child;

  @override
  RenderObjectElement createElement() => _SliverStickyHeaderListElement(this);

  @override
  RenderSliver createRenderObject(BuildContext context) {
    final element = context as _SliverStickyHeaderListElement;
    return _RenderSliverStickyHeaderList(element: element);
  }
}

enum _SliverStickyHeaderListSlot { header, list }

class _SliverStickyHeaderListElement extends RenderObjectElement {
  _SliverStickyHeaderListElement(SliverStickyHeaderList super.widget);

  @override
  SliverStickyHeaderList get widget => super.widget as SliverStickyHeaderList;

  @override
  _RenderSliverStickyHeaderList get renderObject => super.renderObject as _RenderSliverStickyHeaderList;

  //
  // Compare SingleChildRenderObjectElement.
  //

  Element? _header;
  Element? _child;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_header != null) visitor(_header!);
    if (_child != null) visitor(_child!);
  }

  @override
  void forgetChild(Element child) {
    if (child == _header) {
      assert(child != _child);
      _header = null;
    } else if (child == _child) {
      _child = null;
    }
    super.forgetChild(child);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _child = updateChild(_child, widget._child, _SliverStickyHeaderListSlot.list);
  }

  @override
  void update(SliverStickyHeaderList newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _child = updateChild(_child, widget._child, _SliverStickyHeaderListSlot.list);
    renderObject.child!.markHeaderNeedsRebuild();
  }

  @override
  void performRebuild() {
    renderObject.child!.markHeaderNeedsRebuild();
    super.performRebuild();
  }

  void _rebuildHeader(RenderStickyHeaderItem? item) {
    owner!.buildScope(this, () {
      _header = updateChild(_header, item?.header, _SliverStickyHeaderListSlot.header);
    });
  }

  @override
  void insertRenderObjectChild(RenderObject child, _SliverStickyHeaderListSlot slot) {
    final renderObject = this.renderObject;
    switch (slot) {
      case _SliverStickyHeaderListSlot.header:
        assert(child is RenderBox);
        renderObject.header = child as RenderBox;
      case _SliverStickyHeaderListSlot.list:
        assert(child is _RenderSliverStickyHeaderListInner);
        renderObject.child = child as _RenderSliverStickyHeaderListInner;
    }
    assert(renderObject == this.renderObject);
  }

  @override
  void moveRenderObjectChild(covariant RenderObject child, covariant Object? oldSlot, covariant Object? newSlot) {
    assert(false);
  }

  @override
  void removeRenderObjectChild(RenderObject child, _SliverStickyHeaderListSlot slot) {
    final renderObject = this.renderObject;
    switch (slot) {
      case _SliverStickyHeaderListSlot.header:
        assert(renderObject.header == child);
        renderObject.header = null;
      case _SliverStickyHeaderListSlot.list:
        assert(renderObject.child == child);
        renderObject.child = null;
    }
    assert(renderObject == this.renderObject);
  }
}

class _RenderSliverStickyHeaderList extends RenderSliver with RenderSliverHelpers {
  _RenderSliverStickyHeaderList({
    required _SliverStickyHeaderListElement element,
  }) : _element = element;

  final _SliverStickyHeaderListElement _element;

  SliverStickyHeaderList get _widget => _element.widget;

  Widget? _headerWidget;

  /// The limiting edge (if any) of the header's item,
  /// in the list's internal coordinates.
  ///
  /// This is null if there is no header, or if the header's item has
  /// [StickyHeaderItem.allowOverflow] true.
  double? _headerEndBound;

  void _rebuildHeader(RenderBox? listChild) {
    final item = _findStickyHeaderItem(listChild);

    if (item?.header != _headerWidget) {
      _headerWidget = item?.header;

      // The invokeLayoutCallback needs to happen on the same(?) RenderObject
      // that will end up getting mutated.  Attempting it on the child RenderObject
      // would trip an assertion.
      invokeLayoutCallback((constraints) {
        _element._rebuildHeader(item);
      });
    }

    double? endBound;
    if (item != null && !item.allowOverflow) {
      final childParentData = listChild!.parentData! as SliverMultiBoxAdaptorParentData;
      endBound = switch (_widget.headerPlacement._byGrowth(constraints.growthDirection)) {
        _HeaderGrowthPlacement.growthStart =>
          childParentData.layoutOffset! + listChild.size.onAxis(constraints.axis),
        _HeaderGrowthPlacement.growthEnd =>
          childParentData.layoutOffset!,
      };
    }
    if (endBound != _headerEndBound) {
      _headerEndBound = endBound;
      assert(debugDoingThisLayout);
      // This will affect the result of layout... but this method is only called
      // when we're already in the middle of our own performLayout,
      // laying out our child.  So we haven't yet used this information,
      // and will use the updated version after the child's layout returns.
      markNeedsPaint();
    }
  }

  RenderStickyHeaderItem? _findStickyHeaderItem(RenderBox? child) {
    RenderBox? node = child;
    do {
      if (node is RenderStickyHeaderItem) return node;
      if (node is! RenderProxyBox) return null;
      node = node.child;
    } while (true);
  }

  //
  // Managing the two children [header] and [child].
  // This is modeled on [RenderObjectWithChildMixin].
  //

  RenderBox? get header => _header;
  RenderBox? _header;
  set header(RenderBox? value) {
    if (_header != null) dropChild(_header!);
    _header = value;
    if (_header != null) adoptChild(_header!);
  }

  _RenderSliverStickyHeaderListInner? get child => _child;
  _RenderSliverStickyHeaderListInner? _child;
  set child(_RenderSliverStickyHeaderListInner? value) {
    if (_child != null) dropChild(_child!);
    _child = value;
    if (_child != null) adoptChild(_child!);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _header?.attach(owner);
    _child?.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    _header?.detach();
    _child?.detach();
  }

  @override
  void redepthChildren() {
    if (_header != null) redepthChild(_header!);
    if (_child != null) redepthChild(_child!);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (_header != null) visitor(_header!);
    if (_child != null) visitor(_child!);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return [
      if (_header != null) _header!.toDiagnosticsNode(name: 'header'),
      if (_child != null) _child!.toDiagnosticsNode(name: 'child'),
    ];
  }

  //
  // The sliver protocol.
  // Modeled on [RenderProxySliver] as to [child],
  // and [RenderSliverToBoxAdapter] (along with [RenderSliverSingleBoxAdapter],
  // its base class) as to [header].
  //

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData) {
      child.parentData = SliverPhysicalParentData();
    }
  }

  bool _headerAtCoordinateEnd() {
    return axisDirectionIsReversed(constraints.axisDirection)
      ^ (_widget.headerPlacement == HeaderPlacement.scrollingEnd);
  }

  @override
  void performLayout() {
    assert(child != null);
    child!.layout(constraints, parentUsesSize: true);
    SliverGeometry geometry = child!.geometry!;

    if (header != null) {
      header!.layout(constraints.asBoxConstraints(), parentUsesSize: true);

      final headerExtent = header!.size.onAxis(constraints.axis);
      final double headerOffset;
      if (_headerEndBound == null) {
        final paintedHeaderSize = calculatePaintOffset(constraints, from: 0, to: headerExtent);
        final cacheExtent = calculateCacheOffset(constraints, from: 0, to: headerExtent);

        assert(0 <= paintedHeaderSize && paintedHeaderSize.isFinite);

        geometry = SliverGeometry( // TODO review interaction with other slivers
          scrollExtent: geometry.scrollExtent,
          layoutExtent: geometry.layoutExtent,
          paintExtent: math.max(geometry.paintExtent, paintedHeaderSize),
          cacheExtent: math.max(geometry.cacheExtent, cacheExtent),
          maxPaintExtent: math.max(geometry.maxPaintExtent, headerExtent),
          hitTestExtent: math.max(geometry.hitTestExtent, paintedHeaderSize),
          hasVisualOverflow: geometry.hasVisualOverflow
            || headerExtent > constraints.remainingPaintExtent,
        );

        headerOffset = _headerAtCoordinateEnd()
          ? geometry.layoutExtent - headerExtent
          : 0.0;
      } else {
        // The limiting edge of the header's item,
        // in the outer, non-scrolling coordinates.
        final endBoundAbsolute = axisDirectionIsReversed(constraints.growthAxisDirection)
          ? geometry.layoutExtent - (_headerEndBound! - constraints.scrollOffset)
          : _headerEndBound! - constraints.scrollOffset;

        headerOffset = _headerAtCoordinateEnd()
          ? math.max(geometry.layoutExtent - headerExtent, endBoundAbsolute)
          : math.min(0.0, endBoundAbsolute - headerExtent);
      }

      final headerParentData = (header!.parentData as SliverPhysicalParentData);
      headerParentData.paintOffset = offsetInDirection(
        constraints.axis.coordinateDirection, headerOffset);
    }

    this.geometry = geometry;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      context.paintChild(child!, offset);
    }
    if (header != null && geometry!.visible) {
      final headerParentData = (header!.parentData as SliverPhysicalParentData);
      context.paintChild(header!, offset + headerParentData.paintOffset);
    }
  }

  @override
  bool hitTestChildren(SliverHitTestResult result, {required double mainAxisPosition, required double crossAxisPosition}) {
    assert(child != null);
    assert(geometry!.hitTestExtent > 0.0);
    if (header != null) {
      if (hitTestBoxChild(BoxHitTestResult.wrap(result), header!,
            mainAxisPosition: mainAxisPosition,
            crossAxisPosition: crossAxisPosition)) {
        return true;
      }
    }
    return child!.hitTest(result,
      mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition);
  }

  @override
  double childMainAxisPosition(RenderObject child) {
    if (child == this.child) return 0.0;
    assert(child == header);
    // We use Sliver*Physical*ParentData, so the header's position is stored in
    // physical coordinates.  To meet the spec of `childMainAxisPosition`, we
    // need to convert to the sliver's coordinate system.
    final headerParentData = (header!.parentData as SliverPhysicalParentData);
    final paintOffset = headerParentData.paintOffset;
    return switch (constraints.growthAxisDirection) {
      AxisDirection.right => paintOffset.dx,
      AxisDirection.left  => geometry!.layoutExtent - header!.size.width  - paintOffset.dx,
      AxisDirection.down  => paintOffset.dy,
      AxisDirection.up    => geometry!.layoutExtent - header!.size.height - paintOffset.dy,
    };
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child == this.child || child == header);
    final childParentData = child.parentData! as SliverPhysicalParentData;
    childParentData.applyPaintTransform(transform);
  }
}

class _SliverStickyHeaderListInner extends SliverMultiBoxAdaptorWidget {
  const _SliverStickyHeaderListInner({
    required this.headerPlacement,
    required super.delegate,
  });

  final HeaderPlacement headerPlacement;

  @override
  SliverMultiBoxAdaptorElement createElement() =>
    SliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);

  @override
  _RenderSliverStickyHeaderListInner createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return _RenderSliverStickyHeaderListInner(childManager: element);
  }
}

class _RenderSliverStickyHeaderListInner extends RenderSliverList {
  _RenderSliverStickyHeaderListInner({required super.childManager});

  _SliverStickyHeaderListInner get widget => (childManager as SliverMultiBoxAdaptorElement).widget as _SliverStickyHeaderListInner;

  /// The unique child, if any, that spans the start of the visible portion
  /// of the list.
  ///
  /// This means (child start) <= (viewport start) < (child end).
  RenderBox? _findChildAtStart() {
    final scrollOffset = constraints.scrollOffset;

    RenderBox? child;
    for (child = firstChild; ; child = childAfter(child)) {
      if (child == null) {
        // Ran out of children.
        return null;
      }
      final parentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(parentData.layoutOffset != null);
      if (scrollOffset < parentData.layoutOffset!) {
        // This child is already past the start of the sliver's viewport.
        return null;
      }
      if (scrollOffset < parentData.layoutOffset! + child.size.onAxis(constraints.axis)) {
        return child;
      }
    }
  }

  /// The unique child, if any, that spans the end of the visible portion
  /// of the list.
  ///
  /// This means (child start) < (viewport end) <= (child end).
  RenderBox? _findChildAtEnd() {
    final endOffset = constraints.scrollOffset + constraints.viewportMainAxisExtent;

    RenderBox? child;
    for (child = lastChild; ; child = childBefore(child)) {
      if (child == null) {
        // Ran out of children.
        return null;
      }
      final parentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(parentData.layoutOffset != null);
      if (endOffset > parentData.layoutOffset! + child.size.onAxis(constraints.axis)) {
        // This child already stops before the end of the sliver's viewport.
        return null;
      }
      if (endOffset > parentData.layoutOffset!) {
        return child;
      }
    }
  }

  void markHeaderNeedsRebuild() {
    markNeedsLayout();
  }

  @override
  void performLayout() {
    super.performLayout();

    final RenderBox? child;
    switch (widget.headerPlacement._byGrowth(constraints.growthDirection)) {
      case _HeaderGrowthPlacement.growthEnd:
        child = _findChildAtEnd();
      case _HeaderGrowthPlacement.growthStart:
        child = _findChildAtStart();
    }

    (parent! as _RenderSliverStickyHeaderList)._rebuildHeader(child);
  }
}

extension SliverConstraintsGrowthAxisDirection on SliverConstraints {
  AxisDirection get growthAxisDirection => switch (growthDirection) {
    GrowthDirection.forward => axisDirection,
    GrowthDirection.reverse => axisDirection.reversed,
  };
}

extension AxisDirectionReversed on AxisDirection {
  AxisDirection get reversed => switch (this) {
    AxisDirection.down => AxisDirection.up,
    AxisDirection.up => AxisDirection.down,
    AxisDirection.right => AxisDirection.left,
    AxisDirection.left => AxisDirection.right,
  };
}

extension AxisCoordinateDirection on Axis {
  AxisDirection get coordinateDirection => switch (this) {
    Axis.horizontal => AxisDirection.right,
    Axis.vertical => AxisDirection.down,
  };
}

Size sizeOn(Axis axis, {double main = 0, double cross = 0}) {
  switch (axis) {
    case Axis.horizontal:
      return Size(main, cross);
    case Axis.vertical:
      return Size(cross, main);
  }
}

Offset offsetInDirection(AxisDirection direction, double extent) {
  switch (direction) {
    case AxisDirection.right:
      return Offset(extent, 0);
    case AxisDirection.left:
      return Offset(-extent, 0);
    case AxisDirection.down:
      return Offset(0, extent);
    case AxisDirection.up:
      return Offset(0, -extent);
  }
}

extension SizeOnAxis on Size {
  double onAxis(Axis axis) {
    switch (axis) {
      case Axis.horizontal:
        return width;
      case Axis.vertical:
        return height;
    }
  }
}

extension OffsetInDirection on Offset {
  double inDirection(AxisDirection direction) {
    return switch (direction) {
      AxisDirection.right =>  dx,
      AxisDirection.left  => -dx,
      AxisDirection.down  =>  dy,
      AxisDirection.up    => -dy,
    };
  }
}

extension BoxConstraintsOnAxis on BoxConstraints {
  bool hasBoundedAxis(Axis axis) {
    switch (axis) {
      case Axis.horizontal:
        return hasBoundedWidth;
      case Axis.vertical:
        return hasBoundedHeight;
    }
  }

  bool hasTightAxis(Axis axis) {
    switch (axis) {
      case Axis.horizontal:
        return hasTightWidth;
      case Axis.vertical:
        return hasTightHeight;
    }
  }
}
