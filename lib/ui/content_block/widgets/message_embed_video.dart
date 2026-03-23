import 'package:flutter/material.dart';

import '../../../model/content.dart';
import '../../utils/store.dart';
import '../../widgets/image.dart';
import 'helpers.dart';
import 'message_media_container.dart';

class MessageEmbedVideo extends StatelessWidget {
  const MessageEmbedVideo({super.key, required this.node});

  final EmbedVideoNode node;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final previewImageSrcUrl = store.tryResolveUrl(node.previewImageSrcUrl);

    return MessageMediaContainer(
      onTap: () => contentLaunchUrl(context, node.hrefUrl),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (previewImageSrcUrl != null) // TODO(log)
            RealmContentNetworkImage(
              previewImageSrcUrl,
              filterQuality: FilterQuality.medium,
            ),
          // Show the "play" icon even when previewImageSrcUrl didn't resolve;
          // the action uses hrefUrl, which might still work.
          const Icon(
            Icons.play_arrow_rounded,
            color:
                Colors.white, // Web has the same color in light and dark mode.
            size: 32,
          ),
        ],
      ),
    );
  }
}
