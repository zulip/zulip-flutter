import 'dart:math' as math;

import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/sticky_header.dart';

void main() {
  testWidgets('sticky headers: scroll up, headers bounded by items, semi-explicit version', (tester) async {
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
      child: StickyHeaderListView(
        reverse: true,
        children: List.generate(100, (i) => StickyHeaderItem(
          header: _Header(i, height: 20),
          content: _Item(i, height: 80))))));

    void checkState(int index, {required double item, required double header}) =>
      _checkHeader(tester, index, first: false,
        item: Offset(0, item), header: Offset(0, header));

    checkState(5, item:  20, header:   0);

    await _drag(tester, const Offset(0, 5));
    checkState(6, item: -75, header: -15);

    await _drag(tester, const Offset(0, 75));
    checkState(6, item:   0, header:   0);

    await _drag(tester, const Offset(0, 20));
    checkState(6, item:  20, header:   0);
  });

  for (final reverse in [true, false]) {
    for (final reverseHeader in [true, false]) {
      final name = 'sticky headers: '
        'scroll ${reverse ? 'up' : 'down'}, '
        'header at ${reverseHeader ? 'bottom' : 'top'}';
      testWidgets(name, (tester) =>
        _checkSequence(tester,
          Axis.vertical,
          reverse: reverse,
          reverseHeader: reverseHeader,
        ));
    }
  }

  for (final reverse in [true, false]) {
    for (final reverseHeader in [true, false]) {
      for (final textDirection in TextDirection.values) {
        final name = 'sticky headers: '
          '${textDirection.name.toUpperCase()} '
          'scroll ${reverse ? 'backward' : 'forward'}, '
          'header at ${reverseHeader ? 'end' : 'start'}';
        testWidgets(name, (tester) =>
          _checkSequence(tester,
            Axis.horizontal, textDirection: textDirection,
            reverse: reverse,
            reverseHeader: reverseHeader,
          ));
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
      children: List.generate(100, (i) => StickyHeaderItem(
        direction: switch ((axis, headerAtCoordinateEnd)) {
          (Axis.horizontal, true ) => AxisDirection.left,
          (Axis.horizontal, false) => AxisDirection.right,
          (Axis.vertical,   true ) => AxisDirection.up,
          (Axis.vertical,   false) => AxisDirection.down,
        },
        header: _Header(i, height: 20),
        content: _Item(i, height: 80))))));

  final extent = tester.getSize(find.byType(StickyHeaderListView)).onAxis(axis);
  assert(extent % 100 == 0);

  final first = !(reverse ^ reverseHeader);

  final itemFinder = first ? find.byType(_Item).first : find.byType(_Item).last;
  final headerFinder = first ? find.byType(_Header).first : find.byType(_Header).last;

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
    check(tester.widget<_Header>(headerFinder).index).equals(expectedHeaderIndex);

    final expectedItemInsetExtent =
      100 - (first ? scrollOffset % 100 : (-scrollOffset) % 100);
    check(insetExtent(itemFinder)).equals(expectedItemInsetExtent);
    check(insetExtent(headerFinder)).equals(
      math.min(20, expectedItemInsetExtent));
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
  final headerFinder = first ? find.byType(_Header).first : find.byType(_Header).last;
  check(tester.widget<_Item>(itemFinder).index).equals(index);
  check(tester.widget<_Header>(headerFinder).index).equals(index);
  check(tester.getTopLeft(itemFinder)).equals(item);
  check(tester.getTopLeft(headerFinder)).equals(header);
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
