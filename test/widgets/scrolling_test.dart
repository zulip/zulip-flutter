import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/scrolling.dart';

import '../flutter_checks.dart';

void main() {
  group('MessageListScrollView', () {
    Widget buildList({
      required MessageListScrollController controller,
      required double topHeight,
      required double bottomHeight,
    }) {
      return MessageListScrollView(
        controller: controller,
        center: const ValueKey('center'),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: topHeight, child: Text('top'))),
          SliverToBoxAdapter(key: const ValueKey('center'),
            child: SizedBox(height: bottomHeight, child: Text('bottom'))),
        ]);
    }

    late MessageListScrollController controller;
    late MessageListScrollPosition position;

    Future<void> prepare(WidgetTester tester, {
      bool reuseController = false,
      required double topHeight,
      required double bottomHeight,
    }) async {
      if (!reuseController) {
        controller = MessageListScrollController();
      }
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
        child: buildList(controller: controller,
          topHeight: topHeight, bottomHeight: bottomHeight)));
      await tester.pump();
      position = controller.position;
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
          // The tiny scrollCacheExtent causes each layout round to only reach
          // the first item it expects will go beyond the viewport.
          scrollCacheExtent: const ScrollCacheExtent.pixels(1.0),
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
      check(controller.position).pixels.equals(450);
      // … even though it has more height than that.
      check(tester.getRect(find.text('item 6'))).bottom.isGreaterThan(600);
      // (And even though on the first round of layout, it would have looked
      // much shorter so that the view would have tried to scroll to its end.)
    });

    testWidgets('stick to end of list when it grows', (tester) async {
      await prepare(tester,
        topHeight: 400, bottomHeight: 400);
      check(tester.getRect(findBottom))..top.equals(200)..bottom.equals(600);

      // Bottom sliver grows; remain scrolled to (new) bottom.
      await prepare(tester, reuseController: true,
        topHeight: 400, bottomHeight: 500);
      check(tester.getRect(findBottom))..top.equals(100)..bottom.equals(600);
    });

    testWidgets('when not at end, let it grow without following', (tester) async {
      await prepare(tester,
        topHeight: 400, bottomHeight: 400);
      check(tester.getRect(findBottom))..top.equals(200)..bottom.equals(600);

      // Scroll up (by dragging down) to detach from end of list.
      await tester.drag(findBottom, Offset(0, 100));
      await tester.pump();
      check(tester.getRect(findBottom))..top.equals(300)..bottom.equals(700);

      // Bottom sliver grows; remain at existing position, now farther from end.
      await prepare(tester, reuseController: true,
        topHeight: 400, bottomHeight: 500);
      check(tester.getRect(findBottom))..top.equals(300)..bottom.equals(800);
    });

    testWidgets('position preserved when scrollable rebuilds', (tester) async {
      // Tests that [MessageListScrollPosition.absorb] does its job.
      //
      // In the app, this situation can be triggered by changing the device's
      // theme between light and dark.  For this simplified example for a test,
      // go for devicePixelRatio (which ScrollableState directly depends on).

      final controller = MessageListScrollController();
      final widget = Directionality(textDirection: TextDirection.ltr,
        child: buildList(controller: controller,
          topHeight: 400, bottomHeight: 400));
      await tester.pumpWidget(
        MediaQuery(data: MediaQueryData(devicePixelRatio: 1.0),
          child: widget));
      check(tester.getRect(findTop)).bottom.equals(200);
      final position = controller.position;
      check(position).isA<MessageListScrollPosition>();

      // Drag away from the initial scroll position.
      await tester.drag(findBottom, Offset(0, 200));
      await tester.pump();
      check(tester.getRect(findTop)).bottom.equals(400);
      check(controller.position).identicalTo(position);

      // Then cause the ScrollableState to have didChangeDependencies called…
      await tester.pumpWidget(
        MediaQuery(data: MediaQueryData(devicePixelRatio: 2.0),
          child: widget));
      // … so that it constructs a new MessageListScrollPosition…
      check(controller.position)
        ..not((it) => it.identicalTo(position))
        ..isA<MessageListScrollPosition>();
      // … and check the scroll position is preserved, not reset to initial.
      check(tester.getRect(findTop)).bottom.equals(400);
    });

    group('scrollToEnd', () {
      testWidgets('short -> slow', (tester) async {
        await prepare(tester, topHeight: 300, bottomHeight: 600);
        await tester.drag(findBottom, Offset(0, 300));
        await tester.pump();
        check(position).extentAfter.equals(300);

        // Start scrolling to end, from just a short distance up.
        position.scrollToEnd();
        await tester.pump();
        check(position).extentAfter.equals(300);
        check(position).activity.isA<ScrollToEndActivity>();

        // The scrolling moves at a stately pace; …
        await tester.pump(Duration(milliseconds: 100));
        check(position).extentAfter.equals(200);

        await tester.pump(Duration(milliseconds: 100));
        check(position).extentAfter.equals(100);

        // … then upon reaching the end, …
        await tester.pump(Duration(milliseconds: 100));
        check(position).extentAfter.equals(0);

        // … goes idle on the next frame, …
        await tester.pump(Duration(milliseconds: 1));
        check(position).activity.isA<IdleScrollActivity>();
        // … without moving any farther.
        check(position).extentAfter.equals(0);
      });

      testWidgets('long -> bounded speed', (tester) async {
        const referenceSpeed = 8000.0;
        const seconds = 10;
        const distance = seconds * referenceSpeed;
        await prepare(tester, topHeight: distance + 1000, bottomHeight: 300);
        await tester.drag(findBottom, Offset(0, distance));
        await tester.pump();
        check(position).extentAfter.equals(distance);

        // Start scrolling to end.
        position.scrollToEnd();
        await tester.pump();
        check(position).activity.isA<ScrollToEndActivity>();

        // Let it scroll, plotting the trajectory.
        final log = <double>[];
        for (int i = 0; i < seconds; i++) {
          log.add(position.extentAfter);
          await tester.pump(const Duration(seconds: 1));
        }
        log.add(position.extentAfter);
        check(log).deepEquals(List.generate(seconds + 1,
          (i) => distance - referenceSpeed * i));

        // Having reached the end, …
        check(position).extentAfter.equals(0);
        // … it goes idle on the next frame, …
        await tester.pump(Duration(milliseconds: 1));
        check(position).activity.isA<IdleScrollActivity>();
        // … without moving any farther.
        check(position).extentAfter.equals(0);
      });

      testWidgets('starting from overscroll, just drift', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        await prepare(tester, topHeight: 400, bottomHeight: 400);

        // Drag into overscroll.
        await tester.drag(findBottom, Offset(0, -100));
        await tester.pump();
        final offset1 = position.pixels - position.maxScrollExtent;
        check(offset1).isGreaterThan(100 / 2);
        check(position).activity.isA<BallisticScrollActivity>();

        // Start drifting back into range.
        await tester.pump(Duration(milliseconds: 10));
        final offset2 = position.pixels - position.maxScrollExtent;
        check(offset2)..isGreaterThan(0.0)..isLessThan(offset1);
        check(position).activity.isA<BallisticScrollActivity>()
          .velocity.isLessThan(0);

        // Invoke `scrollToEnd`.  The motion should stop…
        position.scrollToEnd();
        await tester.pump();
        check(position.pixels - position.maxScrollExtent).equals(offset2);
        check(position).activity.isA<BallisticScrollActivity>()
          .velocity.equals(0);

        // … and resume drifting from there…
        await tester.pump(Duration(milliseconds: 10));
        final offset3 = position.pixels - position.maxScrollExtent;
        check(offset3)..isGreaterThan(0.0)..isLessThan(offset2);
        check(position).activity.isA<BallisticScrollActivity>()
          .velocity.isLessThan(0);

        // … to eventually return to being in range.
        await tester.pump(Duration(seconds: 1));
        check(position.pixels - position.maxScrollExtent).equals(0);
        check(position).activity.isA<IdleScrollActivity>();

        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('starting very near end, apply min speed', (tester) async {
        await prepare(tester, topHeight: 400, bottomHeight: 400);
        // Verify the assumption used for constructing the example numbers below.
        check(position.physics.toleranceFor(position).velocity)
          .isCloseTo(20/3, .01);

        position.jumpTo(398);
        await tester.pump();
        check(position).extentAfter.equals(2);

        position.scrollToEnd();
        await tester.pump();
        check(position).extentAfter.equals(2);

        // Reach the end in just 150ms, not 300ms.
        await tester.pump(Duration(milliseconds: 75));
        check(position).extentAfter.equals(1);
        await tester.pump(Duration(milliseconds: 75));
        check(position).extentAfter.equals(0);
      });

      testWidgets('on overscroll, stop', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        await prepare(tester, topHeight: 400, bottomHeight: 1000);

        // Scroll up…
        position.jumpTo(400);
        await tester.pump();
        check(position).extentAfter.equals(600);

        // … then invoke `scrollToEnd`…
        position.scrollToEnd();
        await tester.pump();

        // … but have the bottom sliver turn out to be shorter than it was.
        await prepare(tester, topHeight: 400, bottomHeight: 600,
          reuseController: true);
        check(position).extentAfter.equals(200);

        // Let the scrolling animation proceed until it hits the end.
        int steps = 0;
        while (position.extentAfter > 0) {
          check(++steps).isLessThan(100);
          await tester.pump(Duration(milliseconds: 11));
        }

        // This is the very first frame where the position reached the end.
        // It's at exactly the end, no farther…
        check(position.pixels - position.maxScrollExtent).equals(0);

        // … and the animation is done.  Nothing further happens.
        check(position).activity.isA<IdleScrollActivity>();
        await tester.pump(Duration(milliseconds: 11));
        check(position.pixels - position.maxScrollExtent).equals(0);
        check(position).activity.isA<IdleScrollActivity>();

        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('keep going even if content turns out longer', (tester) async {
        await prepare(tester, topHeight: 1000, bottomHeight: 3000);

        // Scroll up…
        position.jumpTo(0);
        await tester.pump();
        check(position).extentAfter.equals(3000);

        // … then invoke `scrollToEnd`…
        position.scrollToEnd();
        await tester.pump();

        // … but have the bottom sliver turn out to be longer than it was.
        await prepare(tester, topHeight: 1000, bottomHeight: 6000,
          reuseController: true);
        check(position).extentAfter.equals(6000);

        // Let the scrolling animation go until it stops.
        int steps = 0;
        double prevRemaining;
        double remaining = position.extentAfter;
        do {
          prevRemaining = remaining;
          check(++steps).isLessThan(100);
          await tester.pump(Duration(milliseconds: 10));
          remaining = position.extentAfter;
        } while (remaining < prevRemaining);

        // The scroll position should be all the way at the end.
        check(remaining).equals(0);
      });
    });
  });
}
