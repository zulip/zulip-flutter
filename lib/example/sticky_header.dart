/// Example app for exercising the sticky_header library.
///
/// This is useful when developing changes to [StickyHeaderListView],
/// [SliverStickyHeaderList], and [StickyHeaderItem],
/// for experimenting visually with changes.
///
/// To use this example app, run the command:
///     flutter run lib/example/sticky_header.dart
/// or run this file from your IDE.
///
/// One inconvenience: this means the example app will use the same app ID
/// as the actual Zulip app.  The app's data remains untouched, though, so
/// a normal `flutter run` will put things back as they were.
/// This inconvenience could be fixed with a bit more work: we'd use
/// `flutter run --flavor`, and define an Android flavor in build.gradle
/// and an Xcode scheme in the iOS build config
/// so as to set the app ID differently.
library;

import 'package:flutter/material.dart';

import '../widgets/sticky_header.dart';

/// Example page using [StickyHeaderListView] and [StickyHeaderItem] in a
/// vertically-scrolling list.
class ExampleVertical extends StatelessWidget {
  ExampleVertical({
    super.key,
    required this.title,
    this.reverse = false,
    this.headerDirection = AxisDirection.down,
  }) : assert(axisDirectionToAxis(headerDirection) == Axis.vertical);

  final String title;
  final bool reverse;
  final AxisDirection headerDirection;

  @override
  Widget build(BuildContext context) {
    final headerAtBottom = axisDirectionIsReversed(headerDirection);

    const numSections = 100;
    const numPerSection = 10;
    return Scaffold(
      appBar: AppBar(title: Text(title)),

      // Invoke StickyHeaderListView the same way you'd invoke ListView.
      // The constructor takes the same arguments.
      body: StickyHeaderListView.separated(
        reverse: reverse,
        reverseHeader: headerAtBottom,
        itemCount: numSections,
        separatorBuilder: (context, i) => const SizedBox.shrink(),

        // Use StickyHeaderItem as an item widget in the ListView.
        // A header will float over the item as needed in order to
        // "stick" at the edge of the viewport.
        //
        // You can also include non-StickyHeaderItem items in the list.
        // They'll behave just like in a plain ListView.
        //
        // Each StickyHeaderItem needs to be an item directly in the list, not
        // wrapped inside other widgets that affect layout, in order to get
        // the sticky-header behavior.
        itemBuilder: (context, i) => StickyHeaderItem(
          header: WideHeader(i: i),
          child: Column(
            verticalDirection: headerAtBottom
              ? VerticalDirection.up : VerticalDirection.down,
            children: List.generate(
              numPerSection + 1, (j) {
                if (j == 0) return WideHeader(i: i);
                return WideItem(i: i, j: j-1);
              })))));
  }
}

/// Example page using [StickyHeaderListView] and [StickyHeaderItem] in a
/// horizontally-scrolling list.
class ExampleHorizontal extends StatelessWidget {
  ExampleHorizontal({
    super.key,
    required this.title,
    this.reverse = false,
    required this.headerDirection,
  }) : assert(axisDirectionToAxis(headerDirection) == Axis.horizontal);

  final String title;
  final bool reverse;
  final AxisDirection headerDirection;

  @override
  Widget build(BuildContext context) {
    final headerAtRight = axisDirectionIsReversed(headerDirection);
    const numSections = 100;
    const numPerSection = 10;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StickyHeaderListView.separated(

        // StickyHeaderListView and StickyHeaderItem also work for horizontal
        // scrolling.  Pass `scrollDirection: Axis.horizontal` to the
        // StickyHeaderListView constructor, just like for ListView.
        scrollDirection: Axis.horizontal,
        reverse: reverse,
        reverseHeader: headerAtRight,
        itemCount: numSections,
        separatorBuilder: (context, i) => const SizedBox.shrink(),
        itemBuilder: (context, i) => StickyHeaderItem(
          header: TallHeader(i: i),
          child: Row(
            textDirection: headerAtRight ? TextDirection.rtl : TextDirection.ltr,
            children: List.generate(
              numPerSection + 1,
              (j) {
                if (j == 0) return TallHeader(i: i);
                return TallItem(i: i, j: j-1, numPerSection: numPerSection);
              })))));
  }
}

/// An experimental example approximating the Zulip message list.
class ExampleVerticalDouble extends StatelessWidget {
  const ExampleVerticalDouble({
    super.key,
    required this.title,
    // this.reverse = false,
    required this.headerPlacement,
    required this.topSliverGrowsUpward,
  });

  final String title;
  // final bool reverse;
  final HeaderPlacement headerPlacement;
  final bool topSliverGrowsUpward;

  @override
  Widget build(BuildContext context) {
    const numSections = 4;
    const numBottomSections = 2;
    const numTopSections = numSections - numBottomSections;
    const numPerSection = 10;

    final headerAtBottom = switch (headerPlacement) {
      HeaderPlacement.scrollingStart => false,
      HeaderPlacement.scrollingEnd   => true,
    };

    final centerKey = topSliverGrowsUpward ?
      const ValueKey('bottom') : const ValueKey('top');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: CustomScrollView(
        semanticChildCount: numSections,
        center: centerKey,
        paintOrder: headerAtBottom ?
          SliverPaintOrder.lastIsTop : SliverPaintOrder.firstIsTop,
        slivers: [
          SliverStickyHeaderList(
            key: const ValueKey('top'),
            headerPlacement: headerPlacement,
            delegate: SliverChildBuilderDelegate(
              childCount: numSections - numBottomSections,
              (context, i) {
                final ii = numBottomSections
                  + (topSliverGrowsUpward ? i : numTopSections - 1 - i);
                return StickyHeaderItem(
                  allowOverflow: true,
                  header: WideHeader(i: ii),
                  child: Column(
                    verticalDirection: headerAtBottom
                      ? VerticalDirection.up : VerticalDirection.down,
                    children: List.generate(numPerSection + 1, (j) {
                      if (j == 0) return WideHeader(i: ii);
                      return WideItem(i: ii, j: j-1);
                    })));
              })),
          SliverStickyHeaderList(
            key: const ValueKey('bottom'),
            headerPlacement: headerPlacement,
            delegate: SliverChildBuilderDelegate(
              childCount: numBottomSections,
              (context, i) {
                final ii = numBottomSections - 1 - i;
                return StickyHeaderItem(
                  allowOverflow: true,
                  header: WideHeader(i: ii),
                  child: Column(
                    verticalDirection: headerAtBottom
                      ? VerticalDirection.up : VerticalDirection.down,
                    children: List.generate(numPerSection + 1, (j) {
                      if (j == 0) return WideHeader(i: ii);
                      return WideItem(i: ii, j: j-1);
                    })));
              })),
        ]));
  }
}

//|//////////////////////////////////////////////////////////////////////////
//
// That's it!
//
// The rest of this file is boring infrastructure for navigating to the
// different examples, and for having some content to put inside them.
//
//|//////////////////////////////////////////////////////////////////////////

class WideHeader extends StatelessWidget {
  const WideHeader({super.key, required this.i});

  final int i;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        onTap: () {}, // nop, but non-null so the ink splash appears
        title: Text("Section ${i + 1}",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer))));
  }
}

class WideItem extends StatelessWidget {
  const WideItem({super.key, required this.i, required this.j});

  final int i;
  final int j;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {}, // nop, but non-null so the ink splash appears
      title: Text("Item ${i + 1}.${j + 1}"));
  }
}

class TallHeader extends StatelessWidget {
  const TallHeader({super.key, required this.i});

  final int i;

  @override
  Widget build(BuildContext context) {
    final contents = Column(children: [
      Text("Section ${i + 1}",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer)),
      const SizedBox(height: 8),
      const Expanded(child: SizedBox.shrink()),
      const SizedBox(height: 8),
      const Text("end"),
    ]);

    return Container(
      alignment: Alignment.center,
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(padding: const EdgeInsets.all(8), child: contents)));
  }
}

class TallItem extends StatelessWidget {
  const TallItem({super.key,
    required this.i,
    required this.j,
    required this.numPerSection,
  });

  final int i;
  final int j;
  final int numPerSection;

  @override
  Widget build(BuildContext context) {
    final heightFactor = (1 + j) / numPerSection;

    final contents = Column(children: [
      Text("Item ${i + 1}.${j + 1}"),
      const SizedBox(height: 8),
      Expanded(
        child: FractionallySizedBox(
          heightFactor: heightFactor,
          child: ColoredBox(
            color: Theme.of(context).colorScheme.secondary,
            child: const SizedBox(width: 4)))),
      const SizedBox(height: 8),
      const Text("end"),
    ]);

    return Container(
      alignment: Alignment.center,
      child: Card(
        child: Padding(padding: const EdgeInsets.all(8), child: contents)));
  }
}

enum _ExampleType { vertical, horizontal }

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final verticalItems = [
      _buildItem(context, _ExampleType.vertical,
        primary: true,
        title: 'Scroll down, headers at top (a standard list)',
        headerDirection: AxisDirection.down),
      _buildItem(context, _ExampleType.vertical,
        title: 'Scroll up, headers at top',
        reverse: true,
        headerDirection: AxisDirection.down),
      _buildItem(context, _ExampleType.vertical,
        title: 'Scroll down, headers at bottom',
        headerDirection: AxisDirection.up),
      _buildItem(context, _ExampleType.vertical,
        title: 'Scroll up, headers at bottom',
        reverse: true,
        headerDirection: AxisDirection.up),
    ];
    final horizontalItems = [
      _buildItem(context, _ExampleType.horizontal,
        title: 'Scroll right, headers at left',
        headerDirection: AxisDirection.right),
      _buildItem(context, _ExampleType.horizontal,
        title: 'Scroll left, headers at left',
        reverse: true,
        headerDirection: AxisDirection.right),
      _buildItem(context, _ExampleType.horizontal,
        title: 'Scroll right, headers at right',
        headerDirection: AxisDirection.left),
      _buildItem(context, _ExampleType.horizontal,
        title: 'Scroll left, headers at right',
        reverse: true,
        headerDirection: AxisDirection.left),
    ];
    final otherItems = [
      _buildButton(context,
        title: 'Double slivers, headers at top',
        page: ExampleVerticalDouble(
          title: 'Double slivers, headers at top',
          topSliverGrowsUpward: false,
          headerPlacement: HeaderPlacement.scrollingStart)),
      _buildButton(context,
        title: 'Split slivers, headers at top',
        page: ExampleVerticalDouble(
          title: 'Split slivers, headers at top',
          topSliverGrowsUpward: true,
          headerPlacement: HeaderPlacement.scrollingStart)),
      _buildButton(context,
        title: 'Split slivers, headers at bottom',
        page: ExampleVerticalDouble(
          title: 'Split slivers, headers at bottom',
          topSliverGrowsUpward: true,
          headerPlacement: HeaderPlacement.scrollingEnd)),
    ];
    return Scaffold(
        appBar: AppBar(title: const Text('Sticky Headers example')),
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text("Vertical lists",
                  style: Theme.of(context).textTheme.headlineMedium)))),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            sliver: SliverGrid.count(
              childAspectRatio: 2,
              crossAxisCount: 2,
              children: verticalItems)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text("Horizontal lists",
                  style: Theme.of(context).textTheme.headlineMedium)))),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            sliver: SliverGrid.count(
              childAspectRatio: 2,
              crossAxisCount: 2,
              children: horizontalItems)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text("Other examples",
                  style: Theme.of(context).textTheme.headlineMedium)))),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            sliver: SliverGrid.count(
              childAspectRatio: 2,
              crossAxisCount: 2,
              children: otherItems)),
        ]));
  }

  Widget _buildItem(BuildContext context, _ExampleType exampleType, {
    required String title,
    bool reverse = false,
    required AxisDirection headerDirection,
    bool primary = false,
  }) {
    Widget page;
    switch (exampleType) {
      case _ExampleType.vertical:
        page = ExampleVertical(
          title: title, reverse: reverse, headerDirection: headerDirection);
        break;
      case _ExampleType.horizontal:
        page = ExampleHorizontal(
          title: title, reverse: reverse, headerDirection: headerDirection);
        break;
    }
    return _buildButton(context, title: title, page: page);
  }

  Widget _buildButton(BuildContext context, {
    bool primary = false,
    required String title,
    required Widget page,
  }) {
    var label = Text(title,
      textAlign: TextAlign.center,
      style: TextStyle(
        inherit: true,
        fontSize: Theme.of(context).textTheme.titleMedium?.fontSize));
    var buttonStyle = primary
      ? null
      : ElevatedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          backgroundColor: Theme.of(context).colorScheme.secondary);
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: buttonStyle,
        onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => page)),
        child: label));
  }
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sticky Headers example',
      theme: ThemeData(
        colorScheme:
          ColorScheme.fromSeed(seedColor: const Color(0xff3366cc))),
      home: const MainPage(),
    );
  }
}

void main() {
  runApp(const ExampleApp());
}
