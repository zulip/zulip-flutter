import 'dart:math' as math;

import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/sticky_header.dart';

void main() {
  testWidgets('sticky headers: scroll up, headers overflow items, explicit version', (tester) async {
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
      child: StickyHeaderListView(
        reverse: true,
        children: List.generate(100, (i) => StickyHeaderItem(
          allowOverflow: true,
          header: _Header(i, height: 20),
          child: _Item(i, height: 100))))));
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
      child: StickyHeaderListView(
        reverse: true,
        children: List.generate(100, (i) => StickyHeaderItem(
          header: _Header(i, height: 20),
          child: _Item(i, height: 100))))));

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
      for (final allowOverflow in [true, false]) {
        final name = 'sticky headers: '
          'scroll ${reverse ? 'up' : 'down'}, '
          'header at ${reverseHeader ? 'bottom' : 'top'}, '
          'headers ${allowOverflow ? 'overflow' : 'bounded'}';
        testWidgets(name, (tester) =>
          _checkSequence(tester,
            Axis.vertical,
            reverse: reverse,
            reverseHeader: reverseHeader,
            allowOverflow: allowOverflow,
          ));
      }
    }
  }

  for (final reverse in [true, false]) {
    for (final reverseHeader in [true, false]) {
      for (final allowOverflow in [true, false]) {
        for (final textDirection in TextDirection.values) {
          final name = 'sticky headers: '
            '${textDirection.name.toUpperCase()} '
            'scroll ${reverse ? 'backward' : 'forward'}, '
            'header at ${reverseHeader ? 'end' : 'start'}, '
            'headers ${allowOverflow ? 'overflow' : 'bounded'}';
          testWidgets(name, (tester) =>
            _checkSequence(tester,
              Axis.horizontal, textDirection: textDirection,
              reverse: reverse,
              reverseHeader: reverseHeader,
              allowOverflow: allowOverflow,
            ));
        }
      }
    }
  }
}

Future<void> _checkSequence(
  WidgetTester tester,
  Axis axis, {
  TextDirection? textDirection,
  bool reverse = false,
  bool reverseHeader = false,
  required bool allowOverflow,
}) async {
  assert(textDirection != null || axis == Axis.vertical);
  final headerAtCoordinateEnd = switch (axis) {
    Axis.horizontal => reverseHeader ^ (textDirection == TextDirection.rtl),
    Axis.vertical   => reverseHeader,
  };

  final controller = ScrollController();
  await tester.pumpWidget(Directionality(
    textDirection: textDirection ?? TextDirection.rtl,
    child: StickyHeaderListView(
      controller: controller,
      scrollDirection: axis,
      reverse: reverse,
      reverseHeader: reverseHeader,
      children: List.generate(100, (i) => StickyHeaderItem(
        allowOverflow: allowOverflow,
        header: _Header(i, height: 20),
        child: _Item(i, height: 100))))));

  final extent = tester.getSize(find.byType(StickyHeaderListView)).onAxis(axis);
  assert(extent % 100 == 0);

  final first = !(reverse ^ reverseHeader);

  final itemFinder = first ? find.byType(_Item).first : find.byType(_Item).last;

  double insetExtent(Finder finder) {
    return headerAtCoordinateEnd
      ? extent - tester.getTopLeft(finder).inDirection(axis.coordinateDirection)
      : tester.getBottomRight(finder).inDirection(axis.coordinateDirection);
  }

  void checkState() {
    final scrollOffset = controller.position.pixels;
    final expectedHeaderIndex = first
      ? (scrollOffset / 100).floor()
      : (extent ~/ 100 - 1) + (scrollOffset / 100).ceil();
    check(tester.widget<_Item>(itemFinder).index).equals(expectedHeaderIndex);
    check(_headerIndex(tester)).equals(expectedHeaderIndex);

    final expectedItemInsetExtent =
      100 - (first ? scrollOffset % 100 : (-scrollOffset) % 100);
    check(insetExtent(itemFinder)).equals(expectedItemInsetExtent);
    check(insetExtent(find.byType(_Header))).equals(
      allowOverflow ? 20 : math.min(20, expectedItemInsetExtent));
  }

  Future<void> jumpAndCheck(double position) async {
    controller.jumpTo(position);
    await tester.pump();
    checkState();
  }

  checkState();
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

class _Header extends StatelessWidget {
  const _Header(this.index, {required this.height});

  final int index;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height, // TODO clean up
      child: Text("Header $index"));
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
