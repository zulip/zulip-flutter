import 'package:flutter/material.dart';

import '../content.dart';

class MessageMediaContainer extends StatelessWidget {
  const MessageMediaContainer({
    super.key,
    required this.onTap,
    required this.child,
  });

  final void Function()? onTap;
  final Widget? child;

  /// The container's size, in logical pixels.
  static const size = Size(150, 100);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: UnconstrainedBox(
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          // TODO clean up this padding by imitating web less precisely;
          //   in particular, avoid adding loose whitespace at end of message.
          padding: const EdgeInsetsDirectional.only(end: 5, bottom: 5),
          child: ColoredBox(
            color: ContentTheme.of(
              context,
            ).colorMessageMediaContainerBackground,
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: SizedBox.fromSize(size: size, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
