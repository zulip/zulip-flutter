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

  BoxDecoration _shadowFrom(AlignmentGeometry begin) {
    return BoxDecoration(gradient: LinearGradient(
      begin: begin, end: -begin,
      colors: [color, color.withValues(alpha: 0)]));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      // This is necessary to pass the constraints as-is,
      // so that the [Stack] is transparent during layout.
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned(top: 0, height: top, left: 0, right: 0,
          child: DecoratedBox(decoration: _shadowFrom(Alignment.topCenter))),
        Positioned(bottom: 0, height: bottom, left: 0, right: 0,
          child: DecoratedBox(decoration: _shadowFrom(Alignment.bottomCenter))),
        PositionedDirectional(start: 0, width: start, top: 0, bottom: 0,
          child: DecoratedBox(decoration: _shadowFrom(AlignmentDirectional.centerStart))),
        PositionedDirectional(end: 0, width: end, top: 0, bottom: 0,
          child: DecoratedBox(decoration: _shadowFrom(AlignmentDirectional.centerEnd))),
      ]);
  }
}
