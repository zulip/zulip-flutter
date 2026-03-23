import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../api/model/model.dart';
import '../model/emoji.dart';
import 'image.dart';

/// A widget showing an emoji.
class EmojiWidget extends StatelessWidget {
  const EmojiWidget({
    super.key,
    required this.emojiDisplay,
    required this.squareDimension,
    this.squareDimensionScaler = TextScaler.noScaling,
    this.imagePlaceholderStyle = EmojiImagePlaceholderStyle.square,
    this.imageAnimationMode = ImageAnimationMode.animateConditionally,
    this.buildCustomTextEmoji,
  });

  final EmojiDisplay emojiDisplay;

  /// The base width and height to use for the emoji square.
  ///
  /// This will be scaled by [squareDimensionScaler].
  ///
  /// This is ignored when using the plain-text emoji style.
  final double squareDimension;

  /// A [TextScaler] to apply to [squareDimension].
  ///
  /// Defaults to [TextScaler.noScaling].
  ///
  /// This is ignored when using the plain-text emoji style.
  final TextScaler squareDimensionScaler;

  final EmojiImagePlaceholderStyle imagePlaceholderStyle;

  /// Whether to show an animated emoji in its still or animated version.
  ///
  /// Ignored except for animated image emoji.
  ///
  /// Defaults to [ImageAnimationMode.animateConditionally].
  final ImageAnimationMode imageAnimationMode;

  /// An optional callback to specify a custom plain-text emoji style.
  ///
  /// If this is not passed, a simple [Text] widget with no added styling
  /// is used.
  final Widget Function()? buildCustomTextEmoji;

  Widget _buildTextEmoji() {
    return buildCustomTextEmoji?.call()
      ?? Text(textEmojiForEmojiName(emojiDisplay.emojiName));
  }

  @override
  Widget build(BuildContext context) {
    final emojiDisplay = this.emojiDisplay;
    return switch (emojiDisplay) {
      ImageEmojiDisplay() => ImageEmojiWidget(
        emojiDisplay: emojiDisplay,
        size: squareDimension,
        textScaler: squareDimensionScaler,
        errorBuilder: (_, _, _) => switch (imagePlaceholderStyle) {
          EmojiImagePlaceholderStyle.square =>
            SizedBox.square(dimension: squareDimensionScaler.scale(squareDimension)),
          EmojiImagePlaceholderStyle.nothing => SizedBox.shrink(),
          EmojiImagePlaceholderStyle.text => _buildTextEmoji(),
        },
        animationMode: imageAnimationMode),
      UnicodeEmojiDisplay() => UnicodeEmojiWidget(
        emojiDisplay: emojiDisplay,
        size: squareDimension,
        textScaler: squareDimensionScaler),
      TextEmojiDisplay() => _buildTextEmoji(),
    };
  }
}

/// In [EmojiWidget], how to present an image emoji when we don't have the image.
enum EmojiImagePlaceholderStyle {
  /// A square of [EmojiWidget.squareDimension]
  /// scaled by [EmojiWidget.squareDimensionScaler].
  square,

  /// A [SizedBox.shrink].
  nothing,

  /// A plain-text emoji.
  ///
  /// See [EmojiWidget.buildCustomTextEmoji] for how plain-text emojis are
  /// styled.
  text,
}

class UnicodeEmojiWidget extends StatelessWidget {
  const UnicodeEmojiWidget({
    super.key,
    required this.emojiDisplay,
    required this.size,
    this.textScaler = TextScaler.noScaling,
  });

  final UnicodeEmojiDisplay emojiDisplay;

  /// The base width and height to use for the emoji.
  ///
  /// This will be scaled by [textScaler].
  final double size;

  /// The text scaler to apply to [size].
  ///
  /// Defaults to [TextScaler.noScaling].
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        // A font size that, with Noto Color Emoji and our line-height
        // config (the use of `forceStrutHeight: true`), causes a Unicode emoji
        // to occupy a square of size [size] in the layout.
        //
        // Determined experimentally:
        //   <https://github.com/zulip/zulip-flutter/pull/410#discussion_r1402808701>
        //   <https://github.com/zulip/zulip-flutter/pull/1629#discussion_r2188037245>
        final double notoColorEmojiTextSize = size * (14.5 / 17);

        return Text(
          textScaler: textScaler,
          style: TextStyle(
            fontFamily: 'Noto Color Emoji',
            fontSize: notoColorEmojiTextSize,
          ),
          strutStyle: StrutStyle(
            fontSize: notoColorEmojiTextSize,
            // Responsible for keeping the line height constant, even
            // with ambient DefaultTextStyle.
            forceStrutHeight: true),
          emojiDisplay.emojiUnicode);

      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // We use the font "Apple Color Emoji". There are some surprises in how
        // Flutter ends up rendering emojis in this font:
        // - With a font size of 17px, the emoji visually seems to be about 17px
        //   square. (Unlike on Android, with Noto Color Emoji, where a 14.5px font
        //   size gives an emoji that looks 17px square.) See:
        //     <https://github.com/flutter/flutter/issues/28894>
        // - The emoji doesn't fill the space taken by the [Text] in the layout.
        //   There's whitespace above, below, and on the right. See:
        //     <https://github.com/flutter/flutter/issues/119623>
        //
        // That extra space would be problematic, except we've used a [Stack] to
        // make the [Text] "positioned" so the space doesn't add margins around the
        // visible part. Key points that enable the [Stack] workaround:
        // - The emoji seems approximately vertically centered (this is
        //   accomplished with help from a [StrutStyle]; see below).
        // - There seems to be approximately no space on its left.
        final boxSize = textScaler.scale(size);
        return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
          SizedBox(height: boxSize, width: boxSize),
          PositionedDirectional(start: 0, child: Text(
            textScaler: textScaler,
            style: TextStyle(
              fontFamily: 'Apple Color Emoji',
              fontSize: size),
            strutStyle: StrutStyle(
              fontSize: size,
              // Responsible for keeping the line height constant, even
              // with ambient DefaultTextStyle.
              forceStrutHeight: true),
            emojiDisplay.emojiUnicode)),
        ]);
    }
  }
}

class ImageEmojiWidget extends StatelessWidget {
  const ImageEmojiWidget({
    super.key,
    required this.emojiDisplay,
    required this.size,
    this.textScaler = TextScaler.noScaling,
    this.errorBuilder,
    this.animationMode = ImageAnimationMode.animateConditionally,
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

  /// Whether to show an animated emoji in its still or animated version.
  ///
  /// Ignored for non-animated emoji.
  ///
  /// Defaults to [ImageAnimationMode.animateConditionally].
  final ImageAnimationMode animationMode;

  @override
  Widget build(BuildContext context) {
    final size = textScaler.scale(this.size);

    final resolvedUrl = animationMode.shouldAnimate(context)
      ? emojiDisplay.resolvedUrl
      : (emojiDisplay.resolvedStillUrl ?? emojiDisplay.resolvedUrl);

    return RealmContentNetworkImage(
      width: size, height: size,
      errorBuilder: errorBuilder,
      resolvedUrl);
  }
}

/// The text to display for an emoji in the "Plain text" emoji theme.
///
/// See [Emojiset.text].
String textEmojiForEmojiName(String emojiName) {
  // Encourage line breaks before "_" (common in these), but try not
  // to leave a colon alone on a line. See:
  //   <https://github.com/flutter/flutter/issues/61081#issuecomment-1103330522>
  return ':\ufeff${emojiName.replaceAll('_', '\u200b_')}\ufeff:';
}
