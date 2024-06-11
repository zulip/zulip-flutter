import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../api/core.dart';
import '../api/model/model.dart';
import '../log.dart';
import 'content.dart';
import 'dialog.dart';
import 'page.dart';
import 'clipboard.dart';
import 'store.dart';

// TODO(#44): Add index of the image preview in the message, to not break if
//   there are multiple image previews with the same URL in the same
//   message. Maybe keep `src`, so that on exit the lightbox image doesn't
//   fly to an image preview with a different URL, following a message edit
//   while the lightbox was open.
class _LightboxHeroTag {
  _LightboxHeroTag({required this.messageId, required this.src});

  final int messageId;
  final Uri src;

  @override
  bool operator ==(Object other) {
    return other is _LightboxHeroTag &&
      other.messageId == messageId &&
      other.src == src;
  }

  @override
  int get hashCode => Object.hash('_LightboxHeroTag', messageId, src);
}

/// Builds a [Hero] from an image in the message list to the lightbox page.
class LightboxHero extends StatelessWidget {
  const LightboxHero({
    super.key,
    required this.message,
    required this.src,
    required this.child,
  });

  final Message message;
  final Uri src;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: _LightboxHeroTag(messageId: message.id, src: src),
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
        copyWithPopup(context: context,
          successContent: Text(zulipLocalizations.successLinkCopied),
          data: ClipboardData(text: url.toString()));
      });
  }
}

class _LightboxPageLayout extends StatefulWidget {
  const _LightboxPageLayout({
    required this.routeEntranceAnimation,
    required this.message,
    required this.buildBottomAppBar,
    required this.child,
  });

  final Animation<double> routeEntranceAnimation;
  final Message message;
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
    final themeData = Theme.of(context);

    final appBarBackgroundColor = Colors.grey.shade900.withOpacity(0.87);
    const appBarForegroundColor = Colors.white;
    const appBarElevation = 0.0;

    PreferredSizeWidget? appBar;
    if (_headerFooterVisible) {
      // TODO(#45): Format with e.g. "Yesterday at 4:47 PM"
      final timestampText = DateFormat
        .yMMMd(/* TODO(#278): Pass selected language here, I think? */)
        .add_Hms()
        .format(DateTime.fromMillisecondsSinceEpoch(widget.message.timestamp * 1000));

      appBar = AppBar(
        centerTitle: false,
        foregroundColor: appBarForegroundColor,
        backgroundColor: appBarBackgroundColor,
        shape: const Border(), // Remove bottom border from [AppBarTheme]
        elevation: appBarElevation,

        // TODO(#41): Show message author's avatar
        title: RichText(
          text: TextSpan(children: [
            TextSpan(
              text: '${widget.message.senderFullName}\n',

              // Restate default
              style: themeData.textTheme.titleLarge!.copyWith(color: appBarForegroundColor)),
            TextSpan(
              text: timestampText,

              // Make smaller, like a subtitle
              style: themeData.textTheme.titleSmall!.copyWith(color: appBarForegroundColor)),
          ])));
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
    required this.src,
  });

  final Animation<double> routeEntranceAnimation;
  final Message message;
  final Uri src;

  @override
  State<_ImageLightboxPage> createState() => _ImageLightboxPageState();
}

class _ImageLightboxPageState extends State<_ImageLightboxPage> {
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

  @override
  Widget build(BuildContext context) {
    return _LightboxPageLayout(
      routeEntranceAnimation: widget.routeEntranceAnimation,
      message: widget.message,
      buildBottomAppBar: _buildBottomAppBar,
      child: SizedBox.expand(
        child: InteractiveViewer(
          child: SafeArea(
            child: LightboxHero(
              message: widget.message,
              src: widget.src,
              child: RealmContentNetworkImage(widget.src, filterQuality: FilterQuality.medium))))));
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

  static String _formatDuration(Duration value) {
    final hours = value.inHours.toString().padLeft(2, '0');
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${hours == '00' ? '' : '$hours:'}$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final currentPosition = _isSliderDragging
      ? _sliderValue
      : widget.controller.value.position;

    return Row(children: [
      Text(_formatDuration(currentPosition),
        style: const TextStyle(color: Colors.white)),
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
      Text(_formatDuration(widget.controller.value.duration),
        style: const TextStyle(color: Colors.white)),
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
      if (mounted) {
        final zulipLocalizations = ZulipLocalizations.of(context);
        await showErrorDialog(
          context: context,
          title: zulipLocalizations.errorDialogTitle,
          message: zulipLocalizations.errorVideoPlayerFailed,
          onDismiss: () {
            Navigator.pop(context); // Pops the dialog
            Navigator.pop(context); // Pops the lightbox
          });
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleVideoControllerUpdate);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  void _handleVideoControllerUpdate() {
    setState(() {});
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

enum MediaType {
  video,
  image
}

Route<void> getLightboxRoute({
  int? accountId,
  BuildContext? context,
  required Message message,
  required Uri src,
  required MediaType mediaType,
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
      return switch (mediaType) {
        MediaType.image => _ImageLightboxPage(
          routeEntranceAnimation: animation,
          message: message,
          src: src),
        MediaType.video => VideoLightboxPage(
          routeEntranceAnimation: animation,
          message: message,
          src: src),
      };
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
