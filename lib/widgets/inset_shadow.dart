import 'package:flutter/widgets.dart';

/// A widget that overlays rectangular inset shadows on a child.
///
/// The use case of this is casting shadows on scrollable UI elements.
/// For example, when there is a list of items, the shadows could be
/// visual indicators for over scrolled areas.
///
/// Note that this is a bit different from the CSS `box-shadow: inset`,
/// because it only supports rectangular shadows.
///
/// See also:
///  * https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3860-11890&node-type=frame&t=oOVTdwGZgtvKv9i8-0
///  * https://developer.mozilla.org/en-US/docs/Web/CSS/box-shadow#inset
class InsetShadowBox extends StatelessWidget {
  const InsetShadowBox({
    super.key,
    this.top = 0,
    this.bottom = 0,
    this.start = 0,
    this.end = 0,
    required this.color,
    required this.child,
  });

  /// The distance that the shadow from the child's top edge grows downwards.
  ///
  /// This does not pad the child widget.
  final double top;

  /// The distance that the shadow from the child's bottom edge grows upwards.
  ///
  /// This does not pad the child widget.
  final double bottom;

  /// The distance that the shadow from the child's start edge grows endwards.
  ///
  /// This does not pad the child widget.
  final double start;

  /// The distance that the shadow from the child's end edge grows startwards.
  ///
  /// This does not pad the child widget.
  final double end;

  /// The shadow color to fade into transparency from the edges, inward.
  final Color color;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      // This is necessary to pass the constraints as-is,
      // so that the [Stack] is transparent during layout.
      fit: StackFit.passthrough,
      children: [
        child,
        if (top != 0) Positioned(top: 0, height: top, left: 0, right: 0,
          child: DecoratedBox(
            decoration: fadeToTransparencyDecoration(FadeToTransparencyDirection.down, color))),
        if (bottom != 0) Positioned(bottom: 0, height: bottom, left: 0, right: 0,
          child: DecoratedBox(
            decoration: fadeToTransparencyDecoration(FadeToTransparencyDirection.up, color))),
        if (start != 0) PositionedDirectional(start: 0, width: start, top: 0, bottom: 0,
          child: DecoratedBox(
            decoration: fadeToTransparencyDecoration(FadeToTransparencyDirection.end, color))),
        if (end != 0) PositionedDirectional(end: 0, width: end, top: 0, bottom: 0,
          child: DecoratedBox(
            decoration: fadeToTransparencyDecoration(FadeToTransparencyDirection.start, color))),
      ]);
  }
}

enum FadeToTransparencyDirection { down, up, end, start }

BoxDecoration fadeToTransparencyDecoration(FadeToTransparencyDirection direction, Color color) {
  final begin = switch (direction) {
    FadeToTransparencyDirection.down => Alignment.topCenter,
    FadeToTransparencyDirection.up => Alignment.bottomCenter,
    FadeToTransparencyDirection.end => AlignmentDirectional.centerStart,
    FadeToTransparencyDirection.start => AlignmentDirectional.centerEnd,
  };

  return BoxDecoration(gradient: LinearGradient(
    begin: begin, end: -begin,
    colors: [color, color.withValues(alpha: 0)]));
}
