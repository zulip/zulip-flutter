import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../model/emoji.dart';
import 'content.dart';

class ImageEmojiWidget extends StatelessWidget {
  const ImageEmojiWidget({
    super.key,
    required this.emojiDisplay,
    required this.size,
    this.textScaler = TextScaler.noScaling,
    this.errorBuilder,
  });

  final ImageEmojiDisplay emojiDisplay;

  /// The base width and height to use for the emoji.
  ///
  /// This will be scaled by [textScaler].
  final double size;

  /// The text scaler to apply to [size].
  ///
  /// Defaults to [TextScaler.noScaling].
  final TextScaler textScaler;

  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    // Some people really dislike animated emoji.
    final doNotAnimate =
      // From reading code, this doesn't actually get set on iOS:
      //   https://github.com/zulip/zulip-flutter/pull/410#discussion_r1408522293
      MediaQuery.disableAnimationsOf(context)
      || (defaultTargetPlatform == TargetPlatform.iOS
        // TODO(upstream) On iOS 17+ (new in 2023), there's a more closely
        //   relevant setting than "reduce motion". It's called "auto-play
        //   animated images", and we should file an issue to expose it.
        //   See GitHub comment linked above.
        && WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.reduceMotion);

    final size = textScaler.scale(this.size);

    final resolvedUrl = doNotAnimate
      ? (emojiDisplay.resolvedStillUrl ?? emojiDisplay.resolvedUrl)
      : emojiDisplay.resolvedUrl;

    return RealmContentNetworkImage(
      width: size, height: size,
      errorBuilder: errorBuilder,
      resolvedUrl);
  }
}
