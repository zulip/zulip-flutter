import 'package:flutter/material.dart';

/// A [SingleChildScrollView] that always shows a Material [Scrollbar].
///
/// This differs from the behavior provided by [MaterialScrollBehavior] in that
/// (a) the scrollbar appears even when [scrollDirection] is [Axis.horizontal],
/// and (b) the scrollbar appears on all platforms, rather than only on
/// desktop platforms.
// TODO(upstream): SingleChildScrollView should have a scrollBehavior field
//   and pass it on to Scrollable, just like ScrollView does; then this would
//   be covered by using that.
// TODO: Maybe show scrollbar only on mobile platforms, like MaterialScrollBehavior
//   and the base ScrollBehavior do?
class SingleChildScrollViewWithScrollbar extends StatefulWidget {
  const SingleChildScrollViewWithScrollbar(
    {super.key, required this.scrollDirection, required this.child});

  final Axis scrollDirection;
  final Widget child;

  @override
  State<SingleChildScrollViewWithScrollbar> createState() =>
    _SingleChildScrollViewWithScrollbarState();
}

class _SingleChildScrollViewWithScrollbarState
    extends State<SingleChildScrollViewWithScrollbar> {
  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: controller,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: widget.scrollDirection,
        child: widget.child));
  }
}
