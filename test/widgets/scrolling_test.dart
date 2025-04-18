import 'package:checks/checks.dart';
// ignore: undefined_hidden_name // anticipates https://github.com/flutter/flutter/pull/164818
import 'package:flutter/rendering.dart' hide SliverPaintOrder;
// ignore: undefined_hidden_name // anticipates https://github.com/flutter/flutter/pull/164818
import 'package:flutter/widgets.dart' hide SliverPaintOrder;
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/scrolling.dart';

import '../flutter_checks.dart';

void main() {
  group('CustomPaintOrderScrollView paint order', () {
    final paintLog = <int>[];

    Widget makeSliver(int i) {
      return SliverToBoxAdapter(
        key: ValueKey(i),
        child: CustomPaint(
          painter: TestCustomPainter()
            ..onPaint = (_, _) => paintLog.add(i),
          child: Text('Item $i')));
    }

    testWidgets('firstIsTop', (tester) async {
      addTearDown(paintLog.clear);
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
        child: CustomPaintOrderScrollView(
          paintOrder: SliverPaintOrder.firstIsTop,
          center: ValueKey(2), anchor: 0.5,
          slivers: List.generate(5, makeSliver))));

      // First sliver paints last, over other slivers; last sliver paints first.
      check(paintLog).deepEquals([4, 3, 2, 1, 0]);
    });

    testWidgets('lastIsTop', (tester) async {
      addTearDown(paintLog.clear);
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
        child: CustomPaintOrderScrollView(
          paintOrder: SliverPaintOrder.lastIsTop,
          center: ValueKey(2), anchor: 0.5,
          slivers: List.generate(5, makeSliver))));

      // Last sliver paints last, over other slivers; first sliver paints first.
      check(paintLog).deepEquals([0, 1, 2, 3, 4]);
    });

    // This test will fail if a corresponding upstream PR lands:
    //   https://github.com/flutter/flutter/pull/164818
    // because that eliminates the quirky centerTopFirstBottom behavior.
    // In that case, skip this test for a quick fix; or go ahead and
    // rip out CustomPaintOrderScrollView in favor of CustomScrollView.
    // (Greg has a draft commit ready which does the latter.)
    testWidgets('centerTopFirstBottom', (tester) async {
      addTearDown(paintLog.clear);
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
        child: CustomPaintOrderScrollView(
          paintOrder: SliverPaintOrder.centerTopFirstBottom,
          center: ValueKey(2), anchor: 0.5,
          slivers: List.generate(5, makeSliver))));

      // The particular order CustomScrollView paints in.
      check(paintLog).deepEquals([0, 1, 4, 3, 2]);

      // Check that CustomScrollView indeed paints in the same order.
      final result = paintLog.toList();
      paintLog.clear();
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
        child: CustomScrollView(
          center: ValueKey(2), anchor: 0.5,
          slivers: List.generate(5, makeSliver))));
      check(paintLog).deepEquals(result);
    });
  });

  group('CustomPaintOrderScrollView hit-test order', () {
    Widget makeSliver(int i) {
      return _AllOverlapSliver(key: ValueKey<int>(i), id: i);
    }

    List<int> sliverIds(Iterable<HitTestEntry> path) => [
        for (final e in path)
          if (e.target case _RenderAllOverlapSliver(:final id))
            id,
      ];

    testWidgets('firstIsTop', (WidgetTester tester) async {
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
        child: CustomPaintOrderScrollView(
          paintOrder: SliverPaintOrder.firstIsTop,
          center: const ValueKey(2), anchor: 0.5,
          slivers: List.generate(5, makeSliver))));

      final result = tester.hitTestOnBinding(const Offset(400, 300));
      check(sliverIds(result.path)).deepEquals([0, 1, 2, 3, 4]);
    });

    testWidgets('lastIsTop', (WidgetTester tester) async {
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
        child: CustomPaintOrderScrollView(
          paintOrder: SliverPaintOrder.lastIsTop,
          center: const ValueKey(2), anchor: 0.5,
          slivers: List.generate(5, makeSliver))));

      final result = tester.hitTestOnBinding(const Offset(400, 300));
      check(sliverIds(result.path)).deepEquals([4, 3, 2, 1, 0]);
    });

    // This test will fail if the upstream PR 164818 lands.
    // In that case the test is no longer needed and we'll take it out;
    // see comment on other centerTopFirstBottom test above.
    testWidgets('centerTopFirstBottom', (tester) async {
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
        child: CustomPaintOrderScrollView(
          paintOrder: SliverPaintOrder.centerTopFirstBottom,
          center: const ValueKey(2), anchor: 0.5,
          slivers: List.generate(5, makeSliver))));

      final result = tester.hitTestOnBinding(const Offset(400, 300));
      // The particular order CustomScrollView hit-tests in.
      check(sliverIds(result.path)).deepEquals([2, 3, 4, 1, 0]);

      // Check that CustomScrollView indeed hit-tests in the same order.
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
        child: CustomScrollView(
          center: const ValueKey(2), anchor: 0.5,
          slivers: List.generate(5, makeSliver))));
      check(sliverIds(tester.hitTestOnBinding(const Offset(400, 300)).path))
        .deepEquals(sliverIds(result.path));
    });
  });

  group('MessageListScrollView', () {
    Future<void> prepare(WidgetTester tester, {
      MessageListScrollController? controller,
      required double topHeight,
      required double bottomHeight,
    }) async {
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
        child: MessageListScrollView(
          controller: controller ?? MessageListScrollController(),
          center: const ValueKey('center'),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: topHeight, child: Text('top'))),
            SliverToBoxAdapter(key: const ValueKey('center'),
              child: SizedBox(height: bottomHeight, child: Text('bottom'))),
          ])));
      await tester.pump();
    }

    // The `skipOffstage: false` produces more informative output
    // when a test fails because one of the slivers is just offscreen.
    final findTop = find.text('top', skipOffstage: false);
    final findBottom = find.text('bottom', skipOffstage: false);

    testWidgets('short/short -> pinned at bottom', (tester) async {
      // Starts out with items at bottom of viewport.
      await prepare(tester, topHeight: 100, bottomHeight: 100);
      check(tester.getRect(findBottom)).bottom.equals(600);

      // Try scrolling down (by dragging up); doesn't move.
      await tester.drag(findTop, Offset(0, -100));
      await tester.pump();
      check(tester.getRect(findBottom)).bottom.equals(600);

      // Try scrolling up (by dragging down); doesn't move.
      await tester.drag(findTop, Offset(0, 100));
      await tester.pump();
      check(tester.getRect(findBottom)).bottom.equals(600);
    });

    testWidgets('short/long -> scrolls to ends and no farther', (tester) async {
      // Starts out scrolled to top (to show top of the bottom sliver).
      await prepare(tester, topHeight: 100, bottomHeight: 800);
      check(tester.getRect(findTop)).top.equals(0);
      check(tester.getRect(findBottom)).bottom.equals(900);

      // Try scrolling up (by dragging down); doesn't move.
      await tester.drag(findBottom, Offset(0, 100));
      await tester.pump();
      check(tester.getRect(findBottom)).bottom.equals(900);

      // Try scrolling down (by dragging up); moves only as far as bottom of list.
      await tester.drag(findBottom, Offset(0, -400));
      await tester.pump();
      check(tester.getRect(findBottom)).bottom.equals(600);
    });

    testWidgets('starts by showing top of bottom sliver, long/long', (tester) async {
      // Both slivers are long; the bottom sliver gets 75% of the viewport.
      await prepare(tester, topHeight: 1000, bottomHeight: 3000);
      check(tester.getRect(findBottom)).top.equals(150);
    });

    testWidgets('starts by showing top of bottom sliver, short/long', (tester) async {
      // The top sliver is shorter than 25% of the viewport.
      // It's shown in full, and the bottom sliver gets the rest (so >75%).
      await prepare(tester, topHeight: 50, bottomHeight: 3000);
      check(tester.getRect(findTop)).top.equals(0);
      check(tester.getRect(findBottom)).top.equals(50);
    });

    testWidgets('starts by showing top of bottom sliver, short/medium', (tester) async {
      // The whole list fits in the viewport.  It's pinned to the bottom,
      // even when that gives the bottom sliver more than 75%.
      await prepare(tester, topHeight: 50, bottomHeight: 500);
      check(tester.getRect(findTop))..top.equals(50)..bottom.equals(100);
      check(tester.getRect(findBottom)).bottom.equals(600);
    });

    testWidgets('starts by showing top of bottom sliver, medium/short', (tester) async {
      // The whole list fits in the viewport.  It's pinned to the bottom,
      // even when that gives the top sliver more than 25%.
      await prepare(tester, topHeight: 300, bottomHeight: 100);
      check(tester.getRect(findTop))..top.equals(200)..bottom.equals(500);
      check(tester.getRect(findBottom)).bottom.equals(600);
    });

    testWidgets('starts by showing top of bottom sliver, long/short', (tester) async {
      // The bottom sliver is shorter than 75% of the viewport.
      // It's shown in full, and the top sliver gets the rest (so >25%).
      await prepare(tester, topHeight: 1000, bottomHeight: 300);
      check(tester.getRect(findTop)).bottom.equals(300);
      check(tester.getRect(findBottom)).bottom.equals(600);
    });

    testWidgets('short/short -> starts at bottom, immediately without animation', (tester) async {
      await prepare(tester, topHeight: 100, bottomHeight: 100);

      final ys = <double>[];
      for (int i = 0; i < 10; i++) {
        ys.add(tester.getRect(findBottom).bottom - 600);
        await tester.pump(Duration(milliseconds: 15));
      }
      check(ys).deepEquals(List.generate(10, (_) => 0.0));
    });

    testWidgets('short/long -> starts at desired start, immediately without animation', (tester) async {
      await prepare(tester, topHeight: 100, bottomHeight: 800);

      final ys = <double>[];
      for (int i = 0; i < 10; i++) {
        ys.add(tester.getRect(findTop).top);
        await tester.pump(Duration(milliseconds: 15));
      }
      check(ys).deepEquals(List.generate(10, (_) => 0.0));
    });

    testWidgets('starts at desired start, even when bottom underestimated at first', (tester) async {
      const numItems = 10;
      const itemHeight = 20.0;

      // A list where the bottom sliver takes several rounds of layout
      // to see how long it really is.
      final controller = MessageListScrollController();
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
        child: MessageListScrollView(
          controller: controller,
          // The tiny cacheExtent causes each layout round to only reach
          // the first item it expects will go beyond the viewport.
          cacheExtent: 1.0, // in (logical) pixels!
          center: const ValueKey('center'),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: 300, child: Text('top'))),
            SliverList.list(key: const ValueKey('center'),
              children: List.generate(numItems, (i) =>
                SizedBox(height: (i+1) * itemHeight, child: Text('item $i')))),
          ])));
      await tester.pump();

      // Starts out with the bottom sliver occupying 75% of the viewport…
      check(controller.position.pixels).equals(450);
      // … even though it has more height than that.
      check(tester.getRect(find.text('item 6'))).bottom.isGreaterThan(600);
      // (And even though on the first round of layout, it would have looked
      // much shorter so that the view would have tried to scroll to its end.)
    });

    testWidgets('stick to end of list when it grows', (tester) async {
      final controller = MessageListScrollController();
      await prepare(tester, controller: controller,
        topHeight: 400, bottomHeight: 400);
      check(tester.getRect(findBottom))..top.equals(200)..bottom.equals(600);

      // Bottom sliver grows; remain scrolled to (new) bottom.
      await prepare(tester, controller: controller,
        topHeight: 400, bottomHeight: 500);
      check(tester.getRect(findBottom))..top.equals(100)..bottom.equals(600);
    });

    testWidgets('when not at end, let it grow without following', (tester) async {
      final controller = MessageListScrollController();
      await prepare(tester, controller: controller,
        topHeight: 400, bottomHeight: 400);
      check(tester.getRect(findBottom))..top.equals(200)..bottom.equals(600);

      // Scroll up (by dragging down) to detach from end of list.
      await tester.drag(findBottom, Offset(0, 100));
      await tester.pump();
      check(tester.getRect(findBottom))..top.equals(300)..bottom.equals(700);

      // Bottom sliver grows; remain at existing position, now farther from end.
      await prepare(tester, controller: controller,
        topHeight: 400, bottomHeight: 500);
      check(tester.getRect(findBottom))..top.equals(300)..bottom.equals(800);
    });
  });
}

class TestCustomPainter extends CustomPainter {
  void Function(Canvas canvas, Size size)? onPaint;

  @override
  void paint(Canvas canvas, Size size) {
    if (onPaint != null) onPaint!(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// A sliver that overlaps with other slivers as far as possible,
/// and does nothing else.
class _AllOverlapSliver extends LeafRenderObjectWidget {
  const _AllOverlapSliver({super.key, required this.id});

  final int id;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderAllOverlapSliver(id);
}

class _RenderAllOverlapSliver extends RenderSliver {
  _RenderAllOverlapSliver(this.id);

  final int id;

  @override
  void performLayout() {
    geometry = SliverGeometry(
      paintExtent: constraints.remainingPaintExtent,
      maxPaintExtent: constraints.remainingPaintExtent,
      layoutExtent: 0.0,
    );
  }

  @override
  bool hitTest(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    if (mainAxisPosition >= 0.0 &&
        mainAxisPosition < geometry!.hitTestExtent &&
        crossAxisPosition >= 0.0 &&
        crossAxisPosition < constraints.crossAxisExtent) {
      result.add(
        SliverHitTestEntry(
          this,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition,
        ),
      );
    }
    return false;
  }
}
