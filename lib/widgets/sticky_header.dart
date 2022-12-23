import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class StickyHeaderListView extends BoxScrollView {
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
        // TODO axis
        assert(scrollDirection == Axis.vertical),
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
    assert(constraints.axis == Axis.vertical); // TODO axis

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

      double childScrollOffset;
      if (innerChild.direction == constraints.axisDirection) {
        childScrollOffset =
            math.max(0.0, scrollOffset - parentData.layoutOffset!);
      } else {
        // TODO axis
        final childEndOffset = parentData.layoutOffset! + child.size.height;
        // TODO should this be our layoutExtent or paintExtent, or what?
        childScrollOffset = math.max(
            0.0, childEndOffset - (scrollOffset + geometry!.layoutExtent));
      }
      innerChild.provideScrollPosition(childScrollOffset);
    }
  }
}

enum StickyHeaderSlot { header, content }

class StickyHeader extends RenderObjectWidget
    with SlottedMultiChildRenderObjectWidgetMixin<StickyHeaderSlot> {
  StickyHeader({super.key, this.header, this.content});

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
  SlottedContainerRenderObjectMixin<StickyHeaderSlot> createRenderObject(
      BuildContext context) {
    return RenderStickyHeader();
  }
}

class RenderStickyHeader extends RenderBox
    with SlottedContainerRenderObjectMixin<StickyHeaderSlot> {
  RenderStickyHeader();

  AxisDirection get direction => AxisDirection.down; // TODO dir, TODO axis

  RenderBox? get _header => childForSlot(StickyHeaderSlot.header);

  RenderBox? get _content => childForSlot(StickyHeaderSlot.content);

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

    if (position == _parentData(header).offset.dy) {
      // TODO axis
      return;
    }
    _parentData(header).offset = Offset(0.0, position); // TODO axis
    markNeedsPaint();
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    assert(!constraints.hasBoundedHeight); // TODO axis
    assert(constraints.hasTightWidth); // TODO axis

    double totalSize = 0;

    final header = _header;
    if (header != null) {
      header.layout(constraints, parentUsesSize: true);
      _parentData(header).offset = Offset.zero;
      totalSize += header.size.height; // TODO axis
    }
    final headerSize = totalSize;

    final content = _content;
    if (content != null) {
      content.layout(constraints, parentUsesSize: true);
      _parentData(content).offset = Offset(0, totalSize); // TODO axis
      totalSize += content.size.height; // TODO axis
    }

    size = constraints.constrain(Size(0, totalSize)); // TODO axis
    _slackSize = totalSize - headerSize;
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
