import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class StickyHeaderListView extends BoxScrollView {
  // Like ListView, but with sticky headers.
  StickyHeaderListView({
    super.key,
    super.scrollDirection,
    super.reverse,
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
  })  : childrenDelegate = SliverChildListDelegate(
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
  })  : assert(itemCount == null || itemCount >= 0),
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
  })  : assert(itemCount >= 0),
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

  final SliverChildDelegate childrenDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    return SliverStickyHeaderList(delegate: childrenDelegate);
  }
}

class SliverStickyHeaderList extends SliverMultiBoxAdaptorWidget {
  const SliverStickyHeaderList({super.key, required super.delegate});

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);

  @override
  RenderSliverStickyHeaderList createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverStickyHeaderList(childManager: element);
  }
}

class RenderSliverStickyHeaderList extends RenderSliverList {
  RenderSliverStickyHeaderList({required super.childManager});

  @override
  void performLayout() {
    super.performLayout();

    assert(constraints.growthDirection == GrowthDirection.forward); // TODO dir

    // debugPrint("our constraints: $constraints");
    // debugPrint("our geometry: $geometry");
    final scrollOffset = constraints.scrollOffset;
    // debugPrint("our scroll offset: $scrollOffset");

    RenderBox? child;
    for (child = firstChild; child != null; child = childAfter(child)) {
      final parentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(parentData.layoutOffset != null);

      RenderBox? innerChild = child;
      while (innerChild is RenderProxyBox) {
        innerChild = innerChild.child;
      }
      if (innerChild is! RenderStickyHeader) {
        continue;
      }
      assert(axisDirectionToAxis(innerChild.direction) == constraints.axis);

      double childScrollOffset;
      if (innerChild.direction == constraints.axisDirection) {
        childScrollOffset =
            math.max(0.0, scrollOffset - parentData.layoutOffset!);
      } else {
        final childEndOffset =
            parentData.layoutOffset! + child.size.onAxis(constraints.axis);
        // TODO should this be our layoutExtent or paintExtent, or what?
        childScrollOffset = math.max(
            0.0, childEndOffset - (scrollOffset + geometry!.layoutExtent));
      }
      innerChild.provideScrollPosition(childScrollOffset);
    }
  }
}

enum StickyHeaderSlot { header, content }

class StickyHeader extends SlottedMultiChildRenderObjectWidget<StickyHeaderSlot, RenderBox> {
  const StickyHeader(
      {super.key,
      this.direction = AxisDirection.down,
      this.header,
      this.content});

  final AxisDirection direction;
  final Widget? header;
  final Widget? content;

  @override
  Iterable<StickyHeaderSlot> get slots => StickyHeaderSlot.values;

  @override
  Widget? childForSlot(StickyHeaderSlot slot) {
    switch (slot) {
      case StickyHeaderSlot.header:
        return header;
      case StickyHeaderSlot.content:
        return content;
    }
  }

  @override
  SlottedContainerRenderObjectMixin<StickyHeaderSlot, RenderBox> createRenderObject(
      BuildContext context) {
    return RenderStickyHeader(direction: direction);
  }
}

class RenderStickyHeader extends RenderBox
    with SlottedContainerRenderObjectMixin<StickyHeaderSlot, RenderBox> {
  RenderStickyHeader({required AxisDirection direction})
      : _direction = direction;

  RenderBox? get _header => childForSlot(StickyHeaderSlot.header);

  RenderBox? get _content => childForSlot(StickyHeaderSlot.content);

  AxisDirection get direction => _direction;
  AxisDirection _direction;

  set direction(AxisDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  @override
  Iterable<RenderBox> get children =>
      [if (_header != null) _header!, if (_content != null) _content!];

  double? _slackSize;

  void provideScrollPosition(double scrollPosition) {
    assert(hasSize);
    final header = _header;
    if (header == null) return;
    assert(header.hasSize);
    assert(_slackSize != null);

    assert(0.0 <= scrollPosition);
    final position = math.min(scrollPosition, _slackSize!);

    Offset offset;
    if (!axisDirectionIsReversed(direction)) {
      offset = offsetInDirection(direction, position);
    } else {
      // TODO simplify this one
      offset = offsetInDirection(direction, position - _slackSize!);
    }
    if (offset == _parentData(header).offset) {
      return;
    }
    _parentData(header).offset = offset;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    Axis axis = axisDirectionToAxis(direction);

    final constraints = this.constraints;
    assert(!constraints.hasBoundedAxis(axis));
    assert(constraints.hasTightAxis(flipAxis(axis)));

    final header = _header;
    if (header != null) header.layout(constraints, parentUsesSize: true);
    final headerSize = header?.size.onAxis(axis) ?? 0;

    final content = _content;
    if (content != null) content.layout(constraints, parentUsesSize: true);
    final contentSize = content?.size.onAxis(axis) ?? 0;

    if (!axisDirectionIsReversed(direction)) {
      if (header != null) _parentData(header).offset = Offset.zero;
      if (content != null) {
        _parentData(content).offset = offsetInDirection(direction, headerSize);
      }
    } else {
      if (header != null) {
        _parentData(header).offset = offsetInDirection(direction, -contentSize);
      }
      if (content != null) _parentData(content).offset = Offset.zero;
    }

    final totalSize = headerSize + contentSize;
    size = constraints.constrain(sizeOn(axis, main: totalSize));
    _slackSize = contentSize;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    void paintChild(RenderBox child, PaintingContext context, Offset offset) {
      context.paintChild(child, offset + _parentData(child).offset);
    }

    final content = _content;
    if (content != null) paintChild(content, context, offset);
    final header = _header;
    if (header != null) paintChild(header, context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children) {
      final parentData = _parentData(child);
      if (result.addWithPaintOffset(
          offset: parentData.offset,
          position: position,
          hitTest: (result, transformed) {
            assert(transformed == position - parentData.offset);
            return child.hitTest(result, position: transformed);
          })) {
        return true;
      }
    }
    return false;
  }

  BoxParentData _parentData(RenderBox child) =>
      child.parentData! as BoxParentData;
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
