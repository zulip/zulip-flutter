import 'package:flutter/material.dart';

class _DraggableScrollableLayer extends StatelessWidget {
  const _DraggableScrollableLayer({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      // Match `initial…` to `min…` so that a slight drag downward dismisses
      // the sheet instead of just resizing it. Making them equal gives a
      // buggy experience for some reason
      //   ( https://github.com/zulip/zulip-flutter/pull/12#discussion_r1116423455 )
      // so we work around by make `initial…` a bit bigger.
      minChildSize: 0.25,
      initialChildSize: 0.26,

      // With `expand: true`, the bottom sheet would then start out occupying
      // the whole screen, as if `initialChildSize` was 1.0. That doesn't seem
      // like what the docs call for. Maybe a bug. Or maybe it's somehow
      // related to the `Stack`?
      expand: false,

      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
          // Prevent overscroll animation on swipe down; it looks
          // sloppy when you're swiping to dismiss the sheet.
          physics: const ClampingScrollPhysics(),

          controller: scrollController,

          child: Padding(
            // Avoid the drag handle. See comment on
            // _DragHandleLayer's SizedBox.height.
            padding: const EdgeInsets.only(top: kMinInteractiveDimension),

            // Extend DraggableScrollableSheet to full width so the whole
            // sheet responds to drag/scroll uniformly.
            child: FractionallySizedBox(
              widthFactor: 1.0,
              child: Builder(builder: builder))));
      });
  }
}

class _DragHandleLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      // In the spec, this is expressed as 22 logical pixels of top/bottom
      // padding on the drag handle:
      //   https://m3.material.io/components/bottom-sheets/specs#e69f3dfb-e443-46ba-b4a8-aabc718cf335
      // The drag handle is specified with height 4 logical pixels, so we can
      // get the same result by vertically centering the handle in a box with
      // height 22 + 4 + 22 = 48. We have another way to say 48 --
      // kMinInteractiveDimension -- which is actually not a bad way to
      // express it, since the feature was announced as "an optional drag
      // handle with an accessible 48dp hit target":
      //   https://m3.material.io/components/bottom-sheets/overview#2cce5bae-eb83-40b0-8e52-5d0cfaa9b795
      // As a bonus, that constant is easy to use at the other layer in the
      // Stack where we set the starting position of the sheet's content to
      // avoid the drag handle.
      height: kMinInteractiveDimension,

      child: Center(
        child: ClipRRect(
          clipBehavior: Clip.hardEdge,
          borderRadius: const BorderRadius.all(Radius.circular(2)),
          child: SizedBox(
            // height / width / color (including opacity) from this table:
            //   https://m3.material.io/components/bottom-sheets/specs#7c093473-d9e1-48f3-9659-b75519c2a29d
            height: 4,
            width: 32,
            child: ColoredBox(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.40))))));
  }
}

/// Show a modal bottom sheet that drags and scrolls to present lots of content.
///
/// Aims to follow Material 3's "bottom sheet" with a drag handle:
///   https://m3.material.io/components/bottom-sheets/overview
Future<T?> showDraggableScrollableModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,

    // Clip.hardEdge looks bad; Clip.antiAliasWithSaveLayer looks pixel-perfect
    // on my iPhone 13 Pro but is marked as "much slower":
    //   https://api.flutter.dev/flutter/dart-ui/Clip.html
    clipBehavior: Clip.antiAlias,

    // The spec:
    //   https://m3.material.io/components/bottom-sheets/specs
    // defines the container's shape with the design token
    // `md.sys.shape.corner.extra-large.top`, which in the table at
    //   https://m3.material.io/styles/shape/shape-scale-tokens#6f668ba1-b671-4ea2-bcf3-c1cff4f4099e
    // maps to:
    //   28dp,28dp,0dp,0dp
    //   SHAPE_FAMILY_ROUNDED_CORNERS
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28.0))),

    useSafeArea: true,
    isScrollControlled: true,
    builder: (BuildContext context) {
      // Make the content start below the drag handle in the y-direction, but
      // when the content is scrollable, let it scroll under the drag handle in
      // the z-direction.
      return Stack(
        children: [
          _DraggableScrollableLayer(builder: builder),
          _DragHandleLayer(),
        ]);
    });
}
