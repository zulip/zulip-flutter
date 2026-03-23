import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../model/content.dart';
import '../../../utils/store.dart';
import '../../../widgets/image.dart';
import '../../../widgets/lightbox.dart';
import '../content.dart';
import 'message_media_container.dart';

class MessageImagePreview extends StatelessWidget {
  const MessageImagePreview({super.key, required this.node});

  final ImagePreviewNode node;

  @override
  Widget build(BuildContext context) {
    return ContentImage(
      node: node,
      size: MessageMediaContainer.size,
      buildContainer: (onTap, child) {
        return MessageMediaContainer(onTap: onTap, child: child);
      },
    );
  }
}

typedef ImageContainerBuilder =
    Widget Function(VoidCallback? onTap, Widget child);

/// A helper widget to deduplicate much of the logic in common
/// between image previews and inline images.
class ContentImage extends StatelessWidget {
  const ContentImage({
    super.key,
    required this.node,
    required this.size,
    required this.buildContainer,
  });

  final ImageNode node;
  final Size size;
  final ImageContainerBuilder buildContainer;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final message = InheritedMessage.of(context);

    final resolvedSrc = switch (node.src) {
      ImageNodeSrcThumbnail(:final value) => value.resolve(
        context,
        width: size.width,
        height: size.height,
        animationMode: .animateConditionally,
      ),
      ImageNodeSrcOther(:final value) => store.tryResolveUrl(value),
    };
    final resolvedOriginalSrc = node.originalSrc == null
        ? null
        : store.tryResolveUrl(node.originalSrc!);

    Widget child = switch ((node.loading, resolvedSrc)) {
      // resolvedSrc would be a "spinner" image URL.
      // Use our own progress indicator instead.
      (true, _) => const CupertinoActivityIndicator(),

      // TODO(#265) use an error-case placeholder
      // TODO(log)
      (false, null) => SizedBox.shrink(),

      (false, Uri()) => RealmContentNetworkImage(
        // TODO(#265) use an error-case placeholder for `errorBuilder`
        filterQuality: FilterQuality.medium,
        semanticLabel: node.alt,
        resolvedSrc!,
      ),
    };

    if (node.alt != null) {
      child = Tooltip(
        message: node.alt,
        // (Instead of setting a semantics label here,
        // we give the alt text to [RealmContentNetworkImage].)
        excludeFromSemantics: true,
        child: child,
      );
    }

    final lightboxDisplayUrl =
        (node.loading || node.src is ImageNodeSrcThumbnail)
        ? resolvedOriginalSrc
        : resolvedSrc;
    if (lightboxDisplayUrl == null) {
      // TODO(log)
      return buildContainer(null, child);
    }

    return buildContainer(
      () {
        Navigator.of(context).push(
          getImageLightboxRoute(
            context: context,
            message: message,
            messageImageContext: context,
            src: lightboxDisplayUrl,
            thumbnailUrl: node.src is ImageNodeSrcThumbnail
                ? node.loading
                      // (Image thumbnail is loading; don't show hard-coded spinner image
                      // even if that happens to be a thumbnail URL.)
                      ? null
                      : resolvedSrc
                : null,
            originalWidth: node.originalWidth,
            originalHeight: node.originalHeight,
          ),
        );
      },
      LightboxHero(
        messageImageContext: context,
        src: lightboxDisplayUrl,
        child: child,
      ),
    );
  }
}
