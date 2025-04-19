import 'package:checks/checks.dart';
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
      // Starts out scrolled to bottom.
      await prepare(tester, topHeight: 100, bottomHeight: 800);
      check(tester.getRect(findBottom)).bottom.equals(600);

      // Try scrolling down (by dragging up); doesn't move.
      await tester.drag(findBottom, Offset(0, -100));
      await tester.pump();
      check(tester.getRect(findBottom)).bottom.equals(600);

      // Try scrolling up (by dragging down); moves only as far as top of list.
      await tester.drag(findBottom, Offset(0, 400));
      await tester.pump();
      check(tester.getRect(findBottom)).bottom.equals(900);
      check(tester.getRect(findTop)).top.equals(0);
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

    testWidgets('short/long -> starts at bottom, immediately without animation', (tester) async {
      await prepare(tester, topHeight: 100, bottomHeight: 800);

      final ys = <double>[];
      for (int i = 0; i < 10; i++) {
        ys.add(tester.getRect(findBottom).bottom - 600);
        await tester.pump(Duration(milliseconds: 15));
      }
      check(ys).deepEquals(List.generate(10, (_) => 0.0));
    });

    testWidgets('starts at bottom, even when bottom underestimated at first', (tester) async {
      const numItems = 10;
      const itemHeight = 300.0;

      // A list where the bottom sliver takes several rounds of layout
      // to see how long it really is.
      final controller = MessageListScrollController();
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
        child: MessageListScrollView(
          controller: controller,
          center: const ValueKey('center'),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: 100, child: Text('top'))),
            SliverList.list(key: const ValueKey('center'),
              children: List.generate(numItems, (i) =>
                SizedBox(height: (i+1) * itemHeight, child: Text('item $i')))),
          ])));
      await tester.pump();

      // Starts out scrolled all the way to the bottom,
      // even though it must have taken several rounds of layout to find that.
      check(controller.position.pixels)
        .equals(itemHeight * numItems * (numItems + 1)/2);
      check(tester.getRect(find.text('item ${numItems-1}', skipOffstage: false)))
        .bottom.equals(600);
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
  });
}
