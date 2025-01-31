import 'dart:math' as math;

import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
        for (final allowOverflow in [true, false]) {
          final name = 'sticky headers: '
            'scroll ${reverse ? 'up' : 'down'}, '
            'header at ${reverseHeader ? 'bottom' : 'top'}, '
            '$growthDirection, '
            'headers ${allowOverflow ? 'overflow' : 'bounded'}';
          testWidgets(name, (tester) =>
            _checkSequence(tester,
              Axis.vertical,
              reverse: reverse,
              reverseHeader: reverseHeader,
              growthDirection: growthDirection,
              allowOverflow: allowOverflow,
            ));

          for (final textDirection in TextDirection.values) {
            final name = 'sticky headers: '
              '${textDirection.name.toUpperCase()} '
              'scroll ${reverse ? 'backward' : 'forward'}, '
              'header at ${reverseHeader ? 'end' : 'start'}, '
              '$growthDirection, '
              'headers ${allowOverflow ? 'overflow' : 'bounded'}';
            testWidgets(name, (tester) =>
              _checkSequence(tester,
                Axis.horizontal, textDirection: textDirection,
                reverse: reverse,
                reverseHeader: reverseHeader,
                growthDirection: growthDirection,
                allowOverflow: allowOverflow,
              ));
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
          cacheExtent: 0,
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
}

Future<void> _checkSequence(
  WidgetTester tester,
  Axis axis, {
  TextDirection? textDirection,
  bool reverse = false,
  bool reverseHeader = false,
  GrowthDirection growthDirection = GrowthDirection.forward,
  required bool allowOverflow,
}) async {
  assert(textDirection != null || axis == Axis.vertical);
  final headerAtCoordinateEnd = switch (axis) {
    Axis.horizontal => reverseHeader ^ (textDirection == TextDirection.rtl),
    Axis.vertical   => reverseHeader,
  };
  final reverseGrowth = (growthDirection == GrowthDirection.reverse);

  final controller = ScrollController();
  const listKey = ValueKey("list");
  const emptyKey = ValueKey("empty");
  await tester.pumpWidget(Directionality(
    textDirection: textDirection ?? TextDirection.rtl,
    child: CustomScrollView(
      controller: controller,
      scrollDirection: axis,
      reverse: reverse,
      anchor: reverseGrowth ? 1.0 : 0.0,
      center: reverseGrowth ? emptyKey : listKey,
      slivers: [
        SliverStickyHeaderList(
          key: listKey,
          headerPlacement: (reverseHeader ^ reverse)
            ? HeaderPlacement.scrollingEnd : HeaderPlacement.scrollingStart,
          delegate: SliverChildListDelegate(
            List.generate(100, (i) => StickyHeaderItem(
              allowOverflow: allowOverflow,
              header: _Header(i, height: 20),
              child: _Item(i, height: 100))))),
        const SliverPadding(
          key: emptyKey,
          padding: EdgeInsets.zero),
      ])));

  final overallSize = tester.getSize(find.byType(CustomScrollView));
  final extent = overallSize.onAxis(axis);
  assert(extent % 100 == 0);

  // A position `inset` from the center of the edge the header is found on.
  Offset headerInset(double inset) {
    return overallSize.center(Offset.zero)
      + offsetInDirection(axis.coordinateDirection,
          (extent / 2 - inset) * (headerAtCoordinateEnd ? 1 : -1));
  }

  final first = !(reverse ^ reverseHeader ^ reverseGrowth);

  final itemFinder = first ? find.byType(_Item).first : find.byType(_Item).last;

  double insetExtent(Finder finder) {
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
    check(insetExtent(itemFinder)).equals(expectedItemInsetExtent);
    check(insetExtent(find.byType(_Header))).equals(expectedHeaderInsetExtent);

    // Check the header gets hit when it should, and not when it shouldn't.
    await tester.tapAt(headerInset(1));
    await tester.tapAt(headerInset(expectedHeaderInsetExtent - 1));
    check(_TapLogged.takeTapLog())..length.equals(2)
      ..every((it) => it.isA<_Header>());
    await tester.tapAt(headerInset(extent - 1));
    await tester.tapAt(headerInset(extent - (expectedHeaderInsetExtent - 1)));
    check(_TapLogged.takeTapLog()).isEmpty();
  }

  Future<void> jumpAndCheck(double position) async {
    controller.jumpTo(position * (reverseGrowth ? -1 : 1));
    await tester.pump();
    await checkState();
  }

  await checkState();
  await jumpAndCheck(5);
  await jumpAndCheck(10);
  await jumpAndCheck(20);
  await jumpAndCheck(50);
  await jumpAndCheck(80);
  await jumpAndCheck(90);
  await jumpAndCheck(95);
  await jumpAndCheck(100);
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

class _Item extends StatelessWidget {
  const _Item(this.index, {required this.height});

  final int index;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height,
      child: Text("Item $index"));
  }
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
