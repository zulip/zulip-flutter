import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../api/core.dart';
import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../log.dart';
import '../model/binding.dart';
import 'actions.dart';
import 'content.dart';
import 'dialog.dart';
import 'message_list.dart';
import 'page.dart';
import 'store.dart';
import 'user.dart';

/// Identifies which [LightboxHero]s should match up with each other
/// to produce a hero animation.
///
/// See [Hero.tag], the field where we use instances of this class.
///
/// The intended behavior is that when the user acts on an image
/// in the message list to have the app expand it in the lightbox,
/// a hero animation goes from the original view of the image
/// to the version in the lightbox,
/// and back to the original upon exiting the lightbox.
class _LightboxHeroTag {
  _LightboxHeroTag({
    required this.messageImageContext,
    required this.src,
  });

  /// The [BuildContext] for the [MessageImage] being expanded into the lightbox.
  ///
  /// In particular this prevents hero animations between
  /// different message lists that happen to have the same message.
  /// It also distinguishes different copies of the same image
  /// in a given message list.
  // TODO: write a regression test for #44, duplicate images within a message
  final BuildContext messageImageContext;

  /// The image source URL.
  ///
  /// This ensures the animation only occurs between matching images, even if
  /// the message was edited before navigating back to the message list
  /// so that the original [MessageImage] has been replaced in the tree
  /// by a different image.
  final Uri src;

  @override
  bool operator ==(Object other) {
    return other is _LightboxHeroTag &&
      other.messageImageContext == messageImageContext &&
      other.src == src;
  }

  @override
  int get hashCode => Object.hash('_LightboxHeroTag', messageImageContext, src);
}

/// Builds a [Hero] from an image in the message list to the lightbox page.
class LightboxHero extends StatelessWidget {
  const LightboxHero({
    super.key,
    required this.messageImageContext,
    required this.src,
    required this.child,
  });

  final BuildContext messageImageContext;
  final Uri src;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: _LightboxHeroTag(messageImageContext: messageImageContext, src: src),
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        final accountId = PerAccountStoreWidget.accountIdOf(fromHeroContext);

        // For a RealmContentNetworkImage shown during flight.
        return PerAccountStoreWidget(accountId: accountId, child: child);
      },
      child: child);
  }
}

class _CopyLinkButton extends StatelessWidget {
  const _CopyLinkButton({required this.url});

  final Uri url;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return IconButton(
      tooltip: zulipLocalizations.lightboxCopyLinkTooltip,
      icon: const Icon(Icons.copy),
      onPressed: () async {
        PlatformActions.copyWithPopup(context: context,
          successContent: Text(zulipLocalizations.successLinkCopied),
          data: ClipboardData(text: url.toString()));
      });
  }
}

class _LightboxPageLayout extends StatefulWidget {
  const _LightboxPageLayout({
    required this.routeEntranceAnimation,
    required this.message,
    required this.buildAppBarBottom,
    required this.buildBottomAppBar,
    required this.child,
  });

  final Animation<double> routeEntranceAnimation;
  final Message message;

  /// For [AppBar.bottom].
  final PreferredSizeWidget? Function(BuildContext context) buildAppBarBottom;

  final Widget? Function(
    BuildContext context, Color color, double elevation) buildBottomAppBar;
  final Widget child;

  @override
  State<_LightboxPageLayout> createState() => _LightboxPageLayoutState();
}

class _LightboxPageLayoutState extends State<_LightboxPageLayout> {
  // TODO(#38): Animate entrance/exit of header and footer
  bool _headerFooterVisible = false;

  @override
  void initState() {
    super.initState();
    _handleRouteEntranceAnimationStatusChange(widget.routeEntranceAnimation.status);
    widget.routeEntranceAnimation.addStatusListener(_handleRouteEntranceAnimationStatusChange);
  }

  @override
  void dispose() {
    widget.routeEntranceAnimation.removeStatusListener(_handleRouteEntranceAnimationStatusChange);
    super.dispose();
  }

  void _handleRouteEntranceAnimationStatusChange(AnimationStatus status) {
    final entranceAnimationComplete = status == AnimationStatus.completed;
    setState(() {
      _headerFooterVisible = entranceAnimationComplete;
    });
  }

  void _handleTap() {
    setState(() {
      _headerFooterVisible = !_headerFooterVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);
    final themeData = Theme.of(context);

    final appBarBackgroundColor = Colors.grey.shade900.withValues(alpha: 0.87);
    const appBarForegroundColor = Colors.white;
    const appBarElevation = 0.0;

    PreferredSizeWidget? appBar;
    if (_headerFooterVisible) {
      final timestampText = MessageTimestampStyle.lightbox
        .format(widget.message.timestamp,
          now: DateTime.now(),
          twentyFourHourTimeMode: store.userSettings.twentyFourHourTime,
          zulipLocalizations: zulipLocalizations);

      // We use plain [AppBar] instead of [ZulipAppBar], even though this page
      // has a [PerAccountStore], because:
      //  * There's already a progress indicator with a different meaning
      //    (loading the image).
      //  * The app bar can be hidden, so wouldn't always be visible anyway.
      //  * This is a page where the store loading indicator isn't especially
      //    necessary: https://github.com/zulip/zulip-flutter/pull/852#issuecomment-2264211917
      appBar = AppBar(
        centerTitle: false,
        foregroundColor: appBarForegroundColor,
        backgroundColor: appBarBackgroundColor,
        shape: const Border(), // Remove bottom border from [AppBarTheme]
        elevation: appBarElevation,
        title: Row(children: [
          Avatar(
            size: 36,
            borderRadius: 36 / 8,
            userId: widget.message.senderId,
            replaceIfMuted: false,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                  // TODO write a test where the sender is muted; check this and avatar
                  text: '${store.senderDisplayName(widget.message, replaceIfMuted: false)}\n',

                  // Restate default
                  style: themeData.textTheme.titleLarge!.copyWith(color: appBarForegroundColor)),
                TextSpan(
                  text: timestampText,

                  // Make smaller, like a subtitle
                  style: themeData.textTheme.titleSmall!.copyWith(color: appBarForegroundColor)),
              ]))),
        ]),
        bottom: widget.buildAppBarBottom(context));
    }

    Widget? bottomAppBar;
    if (_headerFooterVisible) {
      bottomAppBar = widget.buildBottomAppBar(
        context, appBarBackgroundColor, appBarElevation);
    }

    return Theme(
      data: themeData.copyWith(
        iconTheme: themeData.iconTheme.copyWith(color: appBarForegroundColor)),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true, // For the BottomAppBar
        extendBodyBehindAppBar: true, // For the AppBar
        appBar: appBar,
        bottomNavigationBar: bottomAppBar,
        body: MediaQuery(
          // Clobber the MediaQueryData prepared by Scaffold with one that's not
          // affected by the app bars. On this screen, the app bars are
          // translucent, dismissible overlays above the pan-zoom layer in the
          // Z direction, so the pan-zoom layer doesn't need avoid them in the Y
          // direction.
          data: MediaQuery.of(context),

          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _handleTap,
            child: widget.child))));
  }
}

class _ImageLightboxPage extends StatefulWidget {
  const _ImageLightboxPage({
    required this.routeEntranceAnimation,
    required this.message,
    required this.messageImageContext,
    required this.src,
    required this.thumbnailUrl,
    required this.originalWidth,
    required this.originalHeight,
  });

  final Animation<double> routeEntranceAnimation;
  final Message message;
  final BuildContext messageImageContext;
  final Uri src;
  final Uri? thumbnailUrl;
  final double? originalWidth;
  final double? originalHeight;

  @override
  State<_ImageLightboxPage> createState() => _ImageLightboxPageState();
}

class _ImageLightboxPageState extends State<_ImageLightboxPage> {
  double? _loadingProgress;

  PreferredSizeWidget? _buildAppBarBottom(BuildContext context) {
    if (_loadingProgress == null) {
      return null;
    }
    return PreferredSize(
      preferredSize: const Size.fromHeight(4.0),
      child: LinearProgressIndicator(minHeight: 4.0, value: _loadingProgress));
  }

  Widget _buildBottomAppBar(BuildContext context, Color color, double elevation) {
    return BottomAppBar(
      color: color,
      elevation: elevation,
      child: Row(children: [
        _CopyLinkButton(url: widget.src),
        // TODO(#43): Share image
        // TODO(#42): Download image
      ]),
    );
  }

  Widget _frameBuilder(BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
    if (widget.thumbnailUrl == null) return child;

    // The full image is available, so display it.
    if (frame != null) return child;

    // Display the thumbnail image while original image is downloading.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: widget.originalWidth,
        height: widget.originalHeight,
        child: RealmContentNetworkImage(widget.thumbnailUrl!,
          filterQuality: FilterQuality.medium,
          fit: BoxFit.contain)));
  }

  Widget _loadingBuilder(BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (widget.thumbnailUrl == null) return child;

    // `loadingProgress` becomes null when Image has finished downloading.
    final double? progress = loadingProgress?.expectedTotalBytes == null ? null
      : loadingProgress!.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!;

    if (progress != _loadingProgress) {
      _loadingProgress = progress;
      // The [Image.network] API lets us learn progress information only at
      // its build time.  That's too late for updating the progress indicator,
      // so delay that update to the next frame.  For discussion, see:
      //   https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/addPostFrameCallback/near/1893539
      //   https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/addPostFrameCallback/near/1894124
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
      });
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    return _LightboxPageLayout(
      routeEntranceAnimation: widget.routeEntranceAnimation,
      message: widget.message,
      buildAppBarBottom: _buildAppBarBottom,
      buildBottomAppBar: _buildBottomAppBar,
      child: SizedBox.expand(
        child: InteractiveViewer(
          maxScale: 10, // TODO adjust based on device and image size; see #1091
          child: SafeArea(
            child: LightboxHero(
              messageImageContext: widget.messageImageContext,
              src: widget.src,
              child: RealmContentNetworkImage(widget.src,
                filterQuality: FilterQuality.medium,
                frameBuilder: _frameBuilder,
                loadingBuilder: _loadingBuilder))))));
  }
}

class VideoDurationLabel extends StatelessWidget {
  const VideoDurationLabel(this.duration, {
    super.key,
    this.semanticsLabel,
  });

  final Duration duration;
  final String? semanticsLabel;

  @visibleForTesting
  static String formatDuration(Duration value) {
    final hours = value.inHours.toString().padLeft(2, '0');
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${hours == '00' ? '' : '$hours:'}$minutes:$seconds'; // TODO(i18n)
  }

  @override
  Widget build(BuildContext context) {
    return Text(formatDuration(duration),
      semanticsLabel: semanticsLabel,
      style: const TextStyle(color: Colors.white));
  }
}

class _VideoPositionSliderControl extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoPositionSliderControl({
    required this.controller,
  });

  @override
  State<_VideoPositionSliderControl> createState() => _VideoPositionSliderControlState();
}

class _VideoPositionSliderControlState extends State<_VideoPositionSliderControl> {
  Duration _sliderValue = Duration.zero;
  bool _isSliderDragging = false;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.controller.value.position;
    widget.controller.addListener(_handleVideoControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleVideoControllerUpdate);
    super.dispose();
  }

  void _handleVideoControllerUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final currentPosition = _isSliderDragging
      ? _sliderValue
      : widget.controller.value.position;

    return Row(children: [
      VideoDurationLabel(currentPosition,
        semanticsLabel: zulipLocalizations.lightboxVideoCurrentPosition),
      Expanded(
        child: Slider(
          value: currentPosition.inMilliseconds.toDouble(),
          max: widget.controller.value.duration.inMilliseconds.toDouble(),
          activeColor: Colors.white,
          onChangeStart: (value) {
            setState(() {
              _sliderValue = Duration(milliseconds: value.toInt());
              _isSliderDragging = true;
            });
          },
          onChanged: (value) {
            setState(() {
              _sliderValue = Duration(milliseconds: value.toInt());
            });
          },
          onChangeEnd: (value) async {
            final durationValue = Duration(milliseconds: value.toInt());
            await widget.controller.seekTo(durationValue);
            if (mounted) {
              setState(() {
                _sliderValue = durationValue;
                _isSliderDragging = false;
              });
            }
          },
        ),
      ),
      VideoDurationLabel(widget.controller.value.duration,
        semanticsLabel: zulipLocalizations.lightboxVideoDuration),
    ]);
  }
}

class VideoLightboxPage extends StatefulWidget {
  const VideoLightboxPage({
    super.key,
    required this.routeEntranceAnimation,
    required this.message,
    required this.src,
  });

  final Animation<double> routeEntranceAnimation;
  final Message message;
  final Uri src;

  @override
  State<VideoLightboxPage> createState() => _VideoLightboxPageState();
}

class _VideoLightboxPageState extends State<VideoLightboxPage> with PerAccountStoreAwareStateMixin<VideoLightboxPage> {
  VideoPlayerController? _controller;

  @override
  void onNewStore() {
    if (_controller != null) {
      // The exclusion of reinitialization logic is deliberate here,
      // as initialization relies only on the initial values of the store's
      // realm URL and the user's credentials, which we assume remain unchanged
      // when the store is replaced.
      return;
    }

    _initialize();
  }

  Future<void> _initialize() async {
    final store = PerAccountStoreWidget.of(context);

    assert(debugLog('VideoPlayerController.networkUrl(${widget.src})'));
    _controller = VideoPlayerController.networkUrl(widget.src, httpHeaders: {
      if (widget.src.origin == store.account.realmUrl.origin) ...authHeader(
        email: store.account.email,
        apiKey: store.account.apiKey,
      ),
      ...userAgentHeader()
    });
    _controller!.addListener(_handleVideoControllerUpdate);

    try {
      await _controller!.initialize();
      if (_controller == null) return; // widget was disposed
      await _controller!.play();
    } catch (error) { // TODO(log)
      assert(debugLog("VideoPlayerController.initialize failed: $error"));
      if (!mounted) return;
      final zulipLocalizations = ZulipLocalizations.of(context);
      final dialog = showErrorDialog(
        context: context,
        title: zulipLocalizations.errorDialogTitle,
        message: zulipLocalizations.errorVideoPlayerFailed);
      await dialog.result;
      if (!mounted) return;
      Navigator.pop(context); // Pops the lightbox
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleVideoControllerUpdate);
    _controller?.dispose();
    _controller = null;
    // The VideoController doesn't emit a pause event
    // while disposing, so disable the wakelock here
    // explicitly.
    ZulipBinding.instance.toggleWakelock(enable: false);
    super.dispose();
  }

  void _handleVideoControllerUpdate() {
    setState(() {});
    _updateWakelock();
  }

  Future<void> _updateWakelock() async {
    if (_controller!.value.isPlaying) {
      await ZulipBinding.instance.toggleWakelock(enable: true);
    } else {
      await ZulipBinding.instance.toggleWakelock(enable: false);
    }
  }

  Widget? _buildBottomAppBar(BuildContext context, Color color, double elevation) {
    if (_controller == null) return null;
    return BottomAppBar(
      height: 150,
      color: color,
      elevation: elevation,
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        _VideoPositionSliderControl(controller: _controller!),
        IconButton(
          onPressed: () {
            if (_controller!.value.isPlaying) {
              _controller!.pause();
            } else {
              _controller!.play();
            }
          },
          icon: Icon(
            _controller!.value.isPlaying
              ? Icons.pause_circle_rounded
              : Icons.play_circle_rounded,
            size: 50,
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _LightboxPageLayout(
      routeEntranceAnimation: widget.routeEntranceAnimation,
      message: widget.message,
      buildAppBarBottom: (context) => null,
      buildBottomAppBar: _buildBottomAppBar,
      child: SafeArea(
        child: Center(
          child: Stack(alignment: Alignment.center, children: [
            if (_controller != null && _controller!.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!)),
            if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isBuffering)
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(color: Colors.white)),
            ]))));
  }
}

Route<void> _getLightboxRoute({
  required int? accountId,
  required BuildContext? context,
  required RoutePageBuilder pageBuilder,
}) {
  return AccountPageRouteBuilder(
    accountId: accountId,
    context: context,
    fullscreenDialog: true,
    pageBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      // TODO(#40): Drag down to close?
      return pageBuilder(context, animation, secondaryAnimation);
    },
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      return FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeIn)),
        child: child);
    },
  );
}

Route<void> getImageLightboxRoute({
  int? accountId,
  BuildContext? context,
  required Message message,
  required BuildContext messageImageContext,
  required Uri src,
  required Uri? thumbnailUrl,
  required double? originalWidth,
  required double? originalHeight,
}) {
  return _getLightboxRoute(
    accountId: accountId,
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) {
      return _ImageLightboxPage(
        routeEntranceAnimation: animation,
        message: message,
        messageImageContext: messageImageContext,
        src: src,
        thumbnailUrl: thumbnailUrl,
        originalWidth: originalWidth,
        originalHeight: originalHeight);
    });
}

Route<void> getVideoLightboxRoute({
  int? accountId,
  BuildContext? context,
  required Message message,
  required Uri src,
}) {
  return _getLightboxRoute(
    accountId: accountId,
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) {
      return VideoLightboxPage(
        routeEntranceAnimation: animation,
        message: message,
        src: src);
    });
}
