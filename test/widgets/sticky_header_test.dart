import 'dart:math' as math;

import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/sticky_header.dart';

void main() {
  testWidgets('sticky headers: scroll up, headers overflow items, explicit version', (tester) async {
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
      child: TouchSlop(touchSlop: 1,
        child: StickyHeaderListView(
          dragStartBehavior: DragStartBehavior.down,
          reverse: true,
          children: List.generate(100, (i) => StickyHeaderItem(
            allowOverflow: true,
            header: _Header(i, height: 20),
            child: _Item(i, height: 100)))))));
    check(_itemIndexes(tester)).deepEquals([0, 1, 2, 3, 4, 5]);
    check(_headerIndex(tester)).equals(5);
    check(tester.getTopLeft(find.byType(_Item).last)).equals(const Offset(0, 0));
    check(tester.getTopLeft(find.byType(_Header))).equals(const Offset(0, 0));

    await tester.drag(find.byType(StickyHeaderListView), const Offset(0, 5));
    await tester.pump();
    check(_itemIndexes(tester)).deepEquals([0, 1, 2, 3, 4, 5, 6]);
    check(_headerIndex(tester)).equals(6);
    check(tester.getTopLeft(find.byType(_Item).last)).equals(const Offset(0, -95));
    check(tester.getTopLeft(find.byType(_Header))).equals(const Offset(0, 0));

    await tester.drag(find.byType(StickyHeaderListView), const Offset(0, 75));
    await tester.pump();
    check(_itemIndexes(tester)).deepEquals([0, 1, 2, 3, 4, 5, 6]);
    check(_headerIndex(tester)).equals(6);
    check(tester.getTopLeft(find.byType(_Item).last)).equals(const Offset(0, -20));
    check(tester.getTopLeft(find.byType(_Header))).equals(const Offset(0, 0));

    await tester.drag(find.byType(StickyHeaderListView), const Offset(0, 20));
    await tester.pump();
    check(_itemIndexes(tester)).deepEquals([1, 2, 3, 4, 5, 6]);
    check(_headerIndex(tester)).equals(6);
    check(tester.getTopLeft(find.byType(_Item).last)).equals(const Offset(0, 0));
    check(tester.getTopLeft(find.byType(_Header))).equals(const Offset(0, 0));
  });

  testWidgets('sticky headers: scroll up, headers bounded by items, semi-explicit version', (tester) async {
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
      child: TouchSlop(touchSlop: 1,
        child: StickyHeaderListView(
          dragStartBehavior: DragStartBehavior.down,
          reverse: true,
          children: List.generate(100, (i) => StickyHeaderItem(
            header: _Header(i, height: 20),
            child: _Item(i, height: 100)))))));

    void checkState(int index, {required double item, required double header}) =>
      _checkHeader(tester, index, first: false,
        item: Offset(0, item), header: Offset(0, header));

    checkState(5, item:   0, header:   0);

    await _drag(tester, const Offset(0, 5));
    checkState(6, item: -95, header: -15);

    await _drag(tester, const Offset(0, 75));
    checkState(6, item: -20, header:   0);

    await _drag(tester, const Offset(0, 20));
    checkState(6, item:   0, header:   0);
  });

  for (final reverse in [true, false]) {
    for (final reverseHeader in [true, false]) {
      for (final growthDirection in GrowthDirection.values) {
        for (final sliverConfig in _SliverConfig.values) {
          for (final allowOverflow in [true, false]) {
            final name = 'sticky headers: '
              'scroll ${reverse ? 'up' : 'down'}, '
              'header at ${reverseHeader ? 'bottom' : 'top'}, '
              '$growthDirection, '
              'headers ${allowOverflow ? 'overflow' : 'bounded'}, '
              'slivers ${sliverConfig.name}';
            testWidgets(name, (tester) =>
              _checkSequence(tester,
                Axis.vertical,
                reverse: reverse,
                reverseHeader: reverseHeader,
                growthDirection: growthDirection,
                allowOverflow: allowOverflow,
                sliverConfig: sliverConfig,
              ));

            for (final textDirection in TextDirection.values) {
              final name = 'sticky headers: '
                '${textDirection.name.toUpperCase()} '
                'scroll ${reverse ? 'backward' : 'forward'}, '
                'header at ${reverseHeader ? 'end' : 'start'}, '
                '$growthDirection, '
                'headers ${allowOverflow ? 'overflow' : 'bounded'}, '
                'slivers ${sliverConfig.name}';
              testWidgets(name, (tester) =>
                _checkSequence(tester,
                  Axis.horizontal, textDirection: textDirection,
                  reverse: reverse,
                  reverseHeader: reverseHeader,
                  growthDirection: growthDirection,
                  allowOverflow: allowOverflow,
                  sliverConfig: sliverConfig,
                ));
            }
          }
        }
      }
    }
  }

  testWidgets('sticky headers: propagate scrollOffsetCorrection properly', (tester) async {
    Widget page(Widget Function(BuildContext, int) itemBuilder) {
      return Directionality(textDirection: TextDirection.ltr,
        child: StickyHeaderListView.builder(
          dragStartBehavior: DragStartBehavior.down,
          scrollCacheExtent: const ScrollCacheExtent.pixels(0),
          itemCount: 10, itemBuilder: itemBuilder));
    }

    await tester.pumpWidget(page((context, i) =>
      StickyHeaderItem(
        allowOverflow: true,
        header: _Header(i, height: 40),
        child: _Item(i, height: 200))));
    check(tester.getTopLeft(find.text("Item 2"))).equals(Offset(0, 400));

    // Scroll down (dragging up) to get item 0 off screen.
    await tester.drag(find.text("Item 2"), Offset(0, -300));
    await tester.pump();
    check(tester.getTopLeft(find.text("Item 2"))).equals(Offset(0, 100));

    // Make the off-screen item 0 taller, so scrolling back up will underflow.
    await tester.pumpWidget(page((context, i) =>
      StickyHeaderItem(
        allowOverflow: true,
        header: _Header(i, height: 40),
        child: _Item(i, height: i == 0 ? 400 : 200))));
    // Confirm the change in item 0's height hasn't already been applied,
    // as it would if the item were within the viewport or its cache area.
    check(tester.getTopLeft(find.text("Item 2"))).equals(Offset(0, 100));

    // Scroll back up (dragging down).  This will cause a correction as the list
    // discovers that moving 300px up doesn't reach the start anymore.
    await tester.drag(find.text("Item 2"), Offset(0, 300));

    // As a bonus, mark one of the already-visible items as needing layout.
    // (In a real app, this would typically happen because some state changed.)
    tester.firstElement(find.widgetWithText(SizedBox, "Item 2"))
      .renderObject!.markNeedsLayout();

    // If scrollOffsetCorrection doesn't get propagated to the viewport, this
    // pump will record an exception (causing the test to fail at the end)
    // because the marked item won't get laid out.
    await tester.pump();
    check(tester.getTopLeft(find.text("Item 2"))).equals(Offset(0, 400));

    // Moreover if scrollOffsetCorrection doesn't get propagated, this item
    // will get placed at zero rather than properly extend up off screen.
    check(tester.getTopLeft(find.text("Item 0"))).equals(Offset(0, -200));
  });

  testWidgets('sliver only part of viewport, header at end', (tester) async {
    const centerKey = ValueKey('center');
    final controller = ScrollController();
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
      child: CustomScrollView(
        controller: controller,
        anchor: 0.5,
        center: centerKey,
        slivers: [
          SliverStickyHeaderList(
            headerPlacement: HeaderPlacement.scrollingStart,
            delegate: SliverChildListDelegate(
              List.generate(100, (i) => StickyHeaderItem(
                header: _Header(99 - i, height: 20),
                child: _Item(99 - i, height: 100))))),
          SliverStickyHeaderList(
            key: centerKey,
            headerPlacement: HeaderPlacement.scrollingStart,
            delegate: SliverChildListDelegate(
              List.generate(100, (i) => StickyHeaderItem(
                header: _Header(100 + i, height: 20),
                child: _Item(100 + i, height: 100))))),
        ])));

    final overallSize = tester.getSize(find.byType(CustomScrollView));
    final extent = overallSize.onAxis(Axis.vertical);
    assert(extent == 600);

    void checkState(int index, {required double item, required double header}) {
      final itemElement = tester.firstElement(find.byElementPredicate((element) {
        if (element.widget is! _Item) return false;
        final renderObject = element.renderObject as RenderBox;
        return (renderObject.size.contains(renderObject.globalToLocal(
            Offset(overallSize.width / 2, 1)
        )));
      }));
      final itemWidget = itemElement.widget as _Item;
      check(itemWidget.index).equals(index);
      check(_headerIndex(tester)).equals(index);
      check((itemElement.renderObject as RenderBox).localToGlobal(Offset(0, 0)))
        .equals(Offset(0, item));
      check(tester.getTopLeft(find.byType(_Header))).equals(Offset(0, header));
    }

    check(controller.offset).equals(0);
    checkState( 97, item:   0, header:   0);

    controller.jumpTo(-5);
    await tester.pump();
    checkState( 96, item: -95, header: -15);

    controller.jumpTo(-600);
    await tester.pump();
    checkState( 91, item:   0, header:   0);

    controller.jumpTo(600);
    await tester.pump();
    checkState(103, item:   0, header:   0);
  });

  testWidgets('hit-testing for header overflowing sliver', (tester) async {
    const centerKey = ValueKey('center');
    final controller = ScrollController();
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
      child: CustomScrollView(
        controller: controller,
        anchor: 0.0,
        center: centerKey,
        paintOrder: SliverPaintOrder.firstIsTop,
        slivers: [
          SliverStickyHeaderList(
            headerPlacement: HeaderPlacement.scrollingStart,
            delegate: SliverChildListDelegate(
              List.generate(100, (i) => StickyHeaderItem(
                allowOverflow: true,
                header: _Header(99 - i, height: 20),
                child: _Item(99 - i, height: 100))))),
          SliverStickyHeaderList(
            key: centerKey,
            headerPlacement: HeaderPlacement.scrollingStart,
            delegate: SliverChildListDelegate(
              List.generate(100, (i) => StickyHeaderItem(
                allowOverflow: true,
                header: _Header(100 + i, height: 20),
                child: _Item(100 + i, height: 100))))),
        ])));

    for (double topHeight in [5, 10, 15, 20]) {
      controller.jumpTo(-topHeight);
      await tester.pump();
      // The top sliver occupies height [topHeight].
      // Its header overhangs by `20 - topHeight`.

      final expected = <Condition<Object?>>[];
      for (int y = 1; y < 20; y++) {
        await tester.tapAt(Offset(400, y.toDouble()));
        expected.add((it) => it.isA<_Header>().index.equals(99));
      }
      for (int y = 21; y < 40; y += 2) {
        await tester.tapAt(Offset(400, y.toDouble()));
        expected.add((it) => it.isA<_Item>().index.equals(100));
      }
      check(_TapLogged.takeTapLog()).deepEquals(expected);
    }
  });
}

enum _SliverConfig {
  single,
  backToBack,
  followed,
}

Future<void> _checkSequence(
  WidgetTester tester,
  Axis axis, {
  TextDirection? textDirection,
  bool reverse = false,
  bool reverseHeader = false,
  GrowthDirection growthDirection = GrowthDirection.forward,
  required bool allowOverflow,
  _SliverConfig sliverConfig = _SliverConfig.single,
}) async {
  assert(textDirection != null || axis == Axis.vertical);
  final headerAtCoordinateEnd = switch (axis) {
    Axis.horizontal => reverseHeader ^ (textDirection == TextDirection.rtl),
    Axis.vertical   => reverseHeader,
  };
  final reverseGrowth = (growthDirection == GrowthDirection.reverse);
  final headerPlacement = reverseHeader ^ reverse
    ? HeaderPlacement.scrollingEnd : HeaderPlacement.scrollingStart;

  Widget buildItem(int i) {
    return StickyHeaderItem(
      allowOverflow: allowOverflow,
      header: _Header(i, height: 20),
      child: _Item(i, height: 100));
  }

  const sliverScrollExtent = 1000;
  const center = ValueKey("center");
  final slivers = <Widget>[
    if (sliverConfig == _SliverConfig.backToBack)
      SliverStickyHeaderList(
        headerPlacement: headerPlacement,
        delegate: SliverChildListDelegate(
          List.generate(10, (i) => buildItem(-i - 1)))),
    const SliverPadding(
      key: center,
      padding: EdgeInsets.zero),
    SliverStickyHeaderList(
      headerPlacement: headerPlacement,
      delegate: SliverChildListDelegate(
        List.generate(10, (i) => buildItem(i)))),
    if (sliverConfig == _SliverConfig.followed)
      SliverStickyHeaderList(
        headerPlacement: headerPlacement,
        delegate: SliverChildListDelegate(
          List.generate(10, (i) => buildItem(i + 10)))),
  ];

  final double anchor;
  if (reverseGrowth) {
    slivers.reverseRange(0, slivers.length);
    anchor = 1.0;
  } else {
    anchor = 0.0;
  }

  SliverPaintOrder paintOrder = SliverPaintOrder.firstIsTop;
  if (!allowOverflow || (sliverConfig == _SliverConfig.single)) {
    // The paint order doesn't matter.
  } else {
    paintOrder = headerPlacement == HeaderPlacement.scrollingStart
      ? SliverPaintOrder.firstIsTop : SliverPaintOrder.lastIsTop;
  }

  final controller = ScrollController();
  await tester.pumpWidget(Directionality(
    textDirection: textDirection ?? TextDirection.rtl,
    child: CustomScrollView(
      controller: controller,
      scrollDirection: axis,
      reverse: reverse,
      anchor: anchor,
      center: center,
      paintOrder: paintOrder,
      slivers: slivers)));

  final overallSize = tester.getSize(find.bySubtype<CustomScrollView>());
  final extent = overallSize.onAxis(axis);
  assert(extent % 100 == 0);
  assert(sliverScrollExtent - extent > 100);

  // A position `inset` from the center of the edge the header is found on.
  Offset headerInset(double inset) {
    return overallSize.center(Offset.zero)
      + offsetInDirection(axis.coordinateDirection,
          (extent / 2 - inset) * (headerAtCoordinateEnd ? 1 : -1));
  }

  final first = !(reverse ^ reverseHeader ^ reverseGrowth);

  final itemFinder = first ? _LeastItemFinder(find.byType(_Item))
                           : _GreatestItemFinder(find.byType(_Item));

  double insetExtent(FinderBase<Element> finder) {
    return headerAtCoordinateEnd
      ? extent - tester.getTopLeft(finder).inDirection(axis.coordinateDirection)
      : tester.getBottomRight(finder).inDirection(axis.coordinateDirection);
  }

  Future<void> checkState() async {
    // Check the header comes from the expected item.
    final scrollOffset = controller.position.pixels * (reverseGrowth ? -1 : 1);
    final expectedHeaderIndex = first
      ? (scrollOffset / 100).floor()
      : (extent ~/ 100 - 1) + (scrollOffset / 100).ceil();
    check(tester.widget<_Item>(itemFinder).index).equals(expectedHeaderIndex);
    check(_headerIndex(tester)).equals(expectedHeaderIndex);

    // Check the layout of the header and item.
    final expectedItemInsetExtent =
      100 - (first ? scrollOffset % 100 : (-scrollOffset) % 100);
    final double expectedHeaderInsetExtent =
      allowOverflow ? 20 : math.min(20, expectedItemInsetExtent);
    if (expectedItemInsetExtent < expectedHeaderInsetExtent) {
      // TODO there's a bug here if the header isn't opaque;
      //   this check would exercise the bug:
      // check(insetExtent(itemFinder)).equals(expectedItemInsetExtent);
      // Instead, check that things will be fine if the header is opaque.
      check(insetExtent(itemFinder)).isLessOrEqual(expectedHeaderInsetExtent);
    } else {
      check(insetExtent(itemFinder)).equals(expectedItemInsetExtent);
    }
    check(insetExtent(find.byType(_Header))).equals(expectedHeaderInsetExtent);

    // Check the header gets hit when it should, and not when it shouldn't.
    await tester.tapAt(headerInset(1));
    await tester.tapAt(headerInset(expectedHeaderInsetExtent - 1));
    check(_TapLogged.takeTapLog())..length.equals(2)
      ..every((it) => it.isA<_Header>());
    await tester.tapAt(headerInset(extent - 1));
    await tester.tapAt(headerInset(extent - (expectedHeaderInsetExtent - 1)));
    check(_TapLogged.takeTapLog())..length.equals(2)
      ..every((it) => it.isA<_Item>());
  }

  Future<void> jumpAndCheck(double position) async {
    final scrollPosition = position * (reverseGrowth ? -1 : 1);
    controller.jumpTo(scrollPosition);
    await tester.pump();
    await checkState();
  }

  Future<void> checkLocally() async {
    final scrollOffset = controller.position.pixels * (reverseGrowth ? -1 : 1);
    await checkState();
    await jumpAndCheck(scrollOffset + 5);
    await jumpAndCheck(scrollOffset + 10);
    await jumpAndCheck(scrollOffset + 20);
    await jumpAndCheck(scrollOffset + 50);
    await jumpAndCheck(scrollOffset + 80);
    await jumpAndCheck(scrollOffset + 90);
    await jumpAndCheck(scrollOffset + 95);
    await jumpAndCheck(scrollOffset + 100);
  }

  Iterable<double> listExtents() {
    final result = tester.renderObjectList(find.byType(SliverStickyHeaderList, skipOffstage: false))
      .map((renderObject) => (renderObject as RenderSliver)
        .geometry!.layoutExtent);
    return reverseGrowth ? result.toList().reversed : result;
  }

  switch (sliverConfig) {
    case _SliverConfig.single:
      // Just check the first header, at a variety of offsets,
      // and check it hands off to the next header.
      await checkLocally();

    case _SliverConfig.followed:
      // Check behavior as the next sliver scrolls into view.
      await jumpAndCheck(sliverScrollExtent - extent);
      check(listExtents()).deepEquals([extent, 0]);
      await checkLocally();
      check(listExtents()).deepEquals([extent - 100, 100]);

      // Check behavior as the original sliver scrolls out of view.
      await jumpAndCheck(sliverScrollExtent - 100);
      check(listExtents()).deepEquals([100, extent - 100]);
      await checkLocally();
      check(listExtents()).deepEquals([0, extent]);

    case _SliverConfig.backToBack:
      // Scroll the other sliver into view;
      // check behavior as it scrolls back out.
      await jumpAndCheck(-100);
      check(listExtents()).deepEquals([100, extent - 100]);
      await checkLocally();
      check(listExtents()).deepEquals([0, extent]);

      // Scroll the original sliver out of view;
      // check behavior as it scrolls back in.
      await jumpAndCheck(-extent);
      check(listExtents()).deepEquals([extent, 0]);
      await checkLocally();
      check(listExtents()).deepEquals([extent - 100, 100]);
  }
}

abstract class _SelectItemFinder extends FinderBase<Element> with ChainedFinderMixin<Element> {
  bool shouldPrefer(_Item candidate, _Item previous);

  @override
  Iterable<Element> filter(Iterable<Element> parentCandidates) {
    Element? result;
    _Item? resultWidget;
    for (final candidate in parentCandidates) {
      if (candidate is! ComponentElement) continue;
      final widget = candidate.widget;
      if (widget is! _Item) continue;
      if (resultWidget == null || shouldPrefer(widget, resultWidget)) {
        result = candidate;
        resultWidget = widget;
      }
    }
    return [?result];
  }
}

/// Finds the [_Item] with least [_Item.index]
/// out of all elements found by the given parent finder.
class _LeastItemFinder extends _SelectItemFinder {
  _LeastItemFinder(this.parent);

  @override
  final FinderBase<Element> parent;

  @override
  String describeMatch(Plurality plurality) {
    return 'least-index _Item from ${parent.describeMatch(plurality)}';
  }

  @override
  bool shouldPrefer(_Item candidate, _Item previous) {
    return candidate.index < previous.index;
  }
}

/// Finds the [_Item] with greatest [_Item.index]
/// out of all elements found by the given parent finder.
class _GreatestItemFinder extends _SelectItemFinder {
  _GreatestItemFinder(this.parent);

  @override
  final FinderBase<Element> parent;

  @override
  String describeMatch(Plurality plurality) {
    return 'greatest-index _Item from ${parent.describeMatch(plurality)}';
  }

  @override
  bool shouldPrefer(_Item candidate, _Item previous) {
    return candidate.index > previous.index;
  }
}

Future<void> _drag(WidgetTester tester, Offset offset) async {
  await tester.drag(find.byType(StickyHeaderListView), offset);
  await tester.pump();
}

void _checkHeader(
  WidgetTester tester,
  int index, {
  required bool first,
  required Offset item,
  required Offset header,
}) {
  final itemFinder = first ? find.byType(_Item).first : find.byType(_Item).last;
  check(tester.widget<_Item>(itemFinder).index).equals(index);
  check(_headerIndex(tester)).equals(index);
  check(tester.getTopLeft(itemFinder)).equals(item);
  check(tester.getTopLeft(find.byType(_Header))).equals(header);
}

int _headerIndex(WidgetTester tester) {
  return tester.widget<_Header>(find.byType(_Header)).index;
}

Iterable<int> _itemIndexes(WidgetTester tester) {
  return tester.widgetList<_Item>(find.byType(_Item)).map((w) => w.index);
}

sealed class _TapLogged {
  static List<_TapLogged> takeTapLog() {
    final result = _tapLog;
    _tapLog = [];
    return result;
  }
  static List<_TapLogged> _tapLog = [];
}

class _Header extends StatelessWidget implements _TapLogged {
  const _Header(this.index, {required this.height});

  final int index;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height, // TODO clean up
      child: GestureDetector(
        onTap: () => _TapLogged._tapLog.add(this),
        child: Text("Header $index")));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('index', index));
  }
}

extension _HeaderChecks on Subject<_Header> {
  Subject<int> get index => has((x) => x.index, 'index');
}

class _Item extends StatelessWidget implements _TapLogged {
  const _Item(this.index, {required this.height});

  final int index;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height,
      child: GestureDetector(
        onTap: () => _TapLogged._tapLog.add(this),
        child: Text("Item $index")));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('index', index));
  }
}

extension _ItemChecks on Subject<_Item> {
  Subject<int> get index => has((x) => x.index, 'index');
}

/// Sets [DeviceGestureSettings.touchSlop] for the child subtree
/// to the given value, by inserting a [MediaQuery].
///
/// For example `TouchSlop(touchSlop: 1, …)` means a touch that moves by even
/// a single pixel will be interpreted as a drag, even if a tap gesture handler
/// is competing for the gesture.  For human fingers that'd make it unreasonably
/// difficult to make a tap, but in a test carried out by software it can be
/// convenient for making small drag gestures straightforward.
class TouchSlop extends StatelessWidget {
  const TouchSlop({super.key, required this.touchSlop, required this.child});

  final double touchSlop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        gestureSettings: DeviceGestureSettings(touchSlop: touchSlop)),
      child: child);
  }
}
