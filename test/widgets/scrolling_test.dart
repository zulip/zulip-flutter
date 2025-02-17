import 'package:checks/checks.dart';
// ignore: undefined_hidden_name // anticipates https://github.com/flutter/flutter/pull/164818
import 'package:flutter/rendering.dart' hide SliverPaintOrder;
// ignore: undefined_hidden_name // anticipates https://github.com/flutter/flutter/pull/164818
import 'package:flutter/widgets.dart' hide SliverPaintOrder;
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/scrolling.dart';

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
