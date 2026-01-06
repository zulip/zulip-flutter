import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../api/core.dart';
import '../api/model/initial_snapshot.dart';
import '../model/content.dart';
import 'store.dart';

/// Like [Image.network], but includes [authHeader] if [src] is on-realm.
///
/// Use this to present image content in the ambient realm: avatars, images in
/// messages, etc. Must have a [PerAccountStoreWidget] ancestor.
///
/// If [src] is an on-realm URL (it has the same origin as the ambient
/// [Auth.realmUrl]), then an HTTP request to fetch the image will include the
/// user's [authHeader].
///
/// If [src] is off-realm (e.g., a Gravatar URL), no auth header will be sent.
///
/// The image will be cached according to the cache behavior of [Image.network],
/// which may mean the cache is shared between realms.
class RealmContentNetworkImage extends StatelessWidget {
  const RealmContentNetworkImage(
    this.src, {
    super.key,
    this.scale = 1.0,
    this.frameBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.opacity,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    // `headers` skipped
    this.cacheWidth,
    this.cacheHeight,
  });

  final Uri src;

  final double scale;
  final ImageFrameBuilder? frameBuilder;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final double? width;
  final double? height;
  final Color? color;
  final Animation<double>? opacity;
  final BlendMode? colorBlendMode;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final Rect? centerSlice;
  final bool matchTextDirection;
  final bool gaplessPlayback;
  final FilterQuality filterQuality;
  final bool isAntiAlias;
  // `headers` skipped
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    final account = PerAccountStoreWidget.of(context).account;

    return Image.network(
      src.toString(),

      scale: scale,
      frameBuilder: frameBuilder,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      filterQuality: filterQuality,
      isAntiAlias: isAntiAlias,
      headers: {
        // Only send the auth header to the server `auth` belongs to.
        if (src.origin == account.realmUrl.origin) ...authHeader(
          email: account.email, apiKey: account.apiKey,
        ),
        ...userAgentHeader(),
      },
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }
}

/// Whether to show an animated image in its still or animated version.
///
/// Use [shouldAnimate] to evaluate this for the given [BuildContext],
/// which reads device-setting data for [animateConditionally].
enum ImageAnimationMode {
  /// Always show the animated version.
  animateAlways,

  /// Always show the still version.
  animateNever,

  /// Show the animated version
  /// just if animations aren't disabled in device settings.
  animateConditionally,
  ;

  /// True if the image should be animated, false if it should be still.
  bool shouldAnimate(BuildContext context) {
    switch (this) {
      case animateAlways: return true;
      case animateNever: return false;
      case animateConditionally:
        // From reading code, this doesn't actually get set on iOS:
        //   https://github.com/zulip/zulip-flutter/pull/410#discussion_r1408522293
        if (MediaQuery.disableAnimationsOf(context)) return false;

        if (
          defaultTargetPlatform == TargetPlatform.iOS
          // TODO(#1924) On iOS 17+ (new in 2023), there's a more closely
          //   relevant setting than "reduce motion". It's called "auto-play
          //   animated images"; we should use that once Flutter exposes it.
          && WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.reduceMotion
        ) {
          return false;
        }

        return true;
    }
  }
}

extension ImageThumbnailLocatorExtension on ImageThumbnailLocator {
  /// Chooses an appropriate format from [PerAccountStore.serverThumbnailFormats],
  /// represented as an absolute URL.
  ///
  /// [height] and [width] are in logical pixels.
  ///
  /// Requires an ancestor [PerAccountStoreWidget].
  ///
  /// The returned URL may not work
  /// without adding authentication credentials to the request.
  Uri resolve(
    BuildContext context, {
    required double width,
    required double height,
    required ImageAnimationMode animationMode,
  }) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final widthPhysicalPx = (width * devicePixelRatio).ceil();
    final heightPhysicalPx = (height * devicePixelRatio).ceil();

    final store = PerAccountStoreWidget.of(context);

    ThumbnailFormat? bestCandidate;
    if (animated && animationMode.shouldAnimate(context)) {
      bestCandidate ??= _bestFormatOf(store.sortedAnimatedThumbnailFormats,
                          width: widthPhysicalPx, height: heightPhysicalPx);
    }
    bestCandidate ??= _bestFormatOf(store.sortedStillThumbnailFormats,
                        width: widthPhysicalPx, height: heightPhysicalPx);

    if (bestCandidate == null) {
      // There are no known thumbnail formats applicable; and yet we have this
      // thumbnail locator, indicating this image has a thumbnail.
      // Unlikely but seems theoretically possible:
      // maybe thumbnailing isn't used now, for new uploads,
      // but it was used in the past, including for this image.
      // Anyway, fall back to the format encoded in this locator's path.
      return store.realmUrl.resolveUri(defaultFormatSrc);
    }

    final defaultFormatPath = defaultFormatSrc.path;
    final lastSlashIndexInPath = defaultFormatPath.lastIndexOf('/');
    final adjustedPath =
      '${defaultFormatPath.substring(0, lastSlashIndexInPath)}/${bestCandidate.name}';

    return store.realmUrl.resolveUri(defaultFormatSrc.replace(path: adjustedPath));
  }

  ThumbnailFormat? _bestFormatOf(
    List<ThumbnailFormat> sortedCandidates, {
    required int width,
    required int height,
  }) {
    ThumbnailFormat? result;
    for (final candidate in sortedCandidates) {
      result = candidate;
      if (candidate.maxWidth >= width && candidate.maxHeight >= height) break;
    }
    return result;
  }
}
