import 'package:flutter/material.dart';

import '../../../../get/services/store_service.dart';
import '../../../../model/content.dart';
import '../../../values/constants.dart';
import '../../../widgets/image.dart';

class MessageImageEmoji extends StatelessWidget {
  const MessageImageEmoji({super.key, required this.node});

  final ImageEmojiNode node;

  @override
  Widget build(BuildContext context) {
    final store = requirePerAccountStore();
    final resolvedSrc = store.tryResolveUrl(node.src);

    const size = 20.0;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        const SizedBox(width: size, height: kBaseFontSize),
        Positioned(
          // Web's css makes this seem like it should be -0.5, but that looks
          // too low.
          top: -1.5,
          child: resolvedSrc == null
              ? const SizedBox.shrink() // TODO(log)
              : RealmContentNetworkImage(
                  resolvedSrc,
                  filterQuality: FilterQuality.medium,
                  width: size,
                  height: size,
                ),
        ),
      ],
    );
  }
}
