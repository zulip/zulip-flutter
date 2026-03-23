import 'package:flutter/material.dart';

import '../../../model/content.dart';
import '../content.dart';
import 'message_image_preview.dart';
import 'message_media_container.dart';

class InlineImage extends StatelessWidget {
  const InlineImage({
    super.key,
    required this.node,
    required this.ambientTextStyle,
  });

  final InlineImageNode node;
  final TextStyle ambientTextStyle;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    // Follow web's max-height behavior (10em);
    // see image_box_em in web/src/postprocess_content.ts.
    final maxHeight = ambientTextStyle.fontSize! * 10;

    final imageSize =
        (node.originalWidth != null && node.originalHeight != null)
        ? Size(node.originalWidth!, node.originalHeight!) / devicePixelRatio
        // Layout plan when original dimensions are unknown:
        // a [MessageMediaContainer]-sized and -colored rectangle.
        : MessageMediaContainer.size;

    // (a) Don't let tall, thin images take up too much vertical space,
    //     which could be annoying to scroll through. And:
    // (b) Don't let small images grow to occupy more physical pixels
    //     than they have data for.
    //     It looks like web has code for this in web/src/postprocess_content.ts
    //     but it doesn't account for the device pixel ratio, in 2026-01.
    //     So in web, small images do get blown up and blurry on modern devices:
    //       https://chat.zulip.org/#narrow/channel/101-design/topic/Inline.20images.20blown.20up.20and.20blurry/near/2346831
    final size = BoxConstraints(
      maxHeight: maxHeight,
    ).constrainSizeAndAttemptToPreserveAspectRatio(imageSize);

    Widget child = ContentImage(
      node: node,
      size: size,
      buildContainer: (onTap, child) {
        if (onTap == null) return child;
        return GestureDetector(onTap: onTap, child: child);
      },
    );

    return Padding(
      // Separate images vertically when they flow onto separate lines.
      // (3px follows web; see web/styles/rendered_markdown.css.)
      padding: const EdgeInsets.only(top: 3),
      child: ConstrainedBox(
        constraints: BoxConstraints.loose(size),
        child: AspectRatio(
          aspectRatio: size.aspectRatio,
          child: ColoredBox(
            color: ContentTheme.of(
              context,
            ).colorMessageMediaContainerBackground,
            child: child,
          ),
        ),
      ),
    );
  }
}
