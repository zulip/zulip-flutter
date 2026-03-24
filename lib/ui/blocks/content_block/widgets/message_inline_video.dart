import 'package:flutter/material.dart';

import '../../../../model/content.dart';
import '../../../utils/store.dart';
import '../../../widgets/lightbox.dart';
import '../content.dart';
import 'message_media_container.dart';

class MessageInlineVideo extends StatelessWidget {
  const MessageInlineVideo({super.key, required this.node});

  final InlineVideoNode node;

  @override
  Widget build(BuildContext context) {
    final message = InheritedMessage.of(context);
    final store = PerAccountStoreWidget.of(context);
    final resolvedSrc = store.tryResolveUrl(node.srcUrl);

    return MessageMediaContainer(
      onTap: resolvedSrc == null
          ? null
          : () {
              // TODO(log)
              Navigator.of(context).push(
                getVideoLightboxRoute(
                  context: context,
                  message: message,
                  src: resolvedSrc,
                ),
              );
            },
      child: Container(
        color: Colors.black, // Web has the same color in light and dark mode.
        alignment: Alignment.center,
        // To avoid potentially confusing UX, do not show play icon as
        // we also disable onTap above.
        child: resolvedSrc == null
            ? null
            : const Icon(
                // TODO(log)
                Icons.play_arrow_rounded,
                color: Colors
                    .white, // Web has the same color in light and dark mode.
                size: 32,
              ),
      ),
    );
  }
}
