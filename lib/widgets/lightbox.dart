import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../api/model/model.dart';
import 'content.dart';
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
  final String src;

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
  final String src;
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

  final String url;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Copy link',
      icon: const Icon(Icons.copy),
      onPressed: () async {
        // TODO(i18n)
        copyWithPopup(context: context, successContent: const Text('Link copied'),
          data: ClipboardData(text: url));
      });
  }
}

@visibleForTesting
class LightboxPage extends StatefulWidget {
  const LightboxPage({
    required this.routeEntranceAnimation,
    required this.message,
    required this.src,
  });

  final Animation routeEntranceAnimation;
  final Message message;
  final String src;

  @override
  State<LightboxPage> createState() => _LightboxPageState();
}

class _LightboxPageState extends State<LightboxPage> {
  // TODO(#38): Animate entrance/exit of header and footer
  bool _headerFooterVisible = false;

  @override
  void initState() {
    super.initState();
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

    // TODO(#45): Format with e.g. "Yesterday at 4:47 PM"
    final timestampText = DateFormat
      .yMMMd(/* TODO(i18n): Pass selected language here, I think? */)
      .add_Hms()
      .format(DateTime.fromMillisecondsSinceEpoch(widget.message.timestamp * 1000));

    final appBar = PreferredSize(
      preferredSize: Size(MediaQuery.of(context).size.width, kToolbarHeight),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeIn,
        height: _headerFooterVisible ? AppBar.preferredHeightFor(
                                        context, 
                                        Size(0, MediaQuery.of(context).padding.top + kToolbarHeight)
                                      ) 
                                      : 0,
        child: AppBar(
          centerTitle: false,
          foregroundColor: appBarForegroundColor,
          backgroundColor: appBarBackgroundColor,
          
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
          ])))));
    
    final bottomAppBar = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeIn,
      // 80 is the default in M3, we need to set a value for the animation
      // to work
      height: _headerFooterVisible
          ? BottomAppBarTheme.of(context).height ?? 80
          : 0,
      child: BottomAppBar(
        color: appBarBackgroundColor,
        child: Row(children: [
            _CopyLinkButton(url: widget.src),
            // TODO(#43): Share image
            // TODO(#42): Download image
          ])));

    return Theme(
      data: themeData.copyWith(
        iconTheme: themeData.iconTheme.copyWith(color: appBarForegroundColor)),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true, // For the BottomAppBar
        extendBodyBehindAppBar: true, // For the AppBar
        appBar: appBar,
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
            child: SizedBox.expand(
              child: InteractiveViewer(
                child: SafeArea(
                  child: LightboxHero(
                    message: widget.message,
                    src: widget.src,
                    child: RealmContentNetworkImage(widget.src, filterQuality: FilterQuality.medium))))))),
        bottomNavigationBar: bottomAppBar));
  }
}

Route getLightboxRoute({
  required BuildContext context,
  required Message message,
  required String src
}) {
  return AccountPageRouteBuilder(
    context: context,
    fullscreenDialog: true,
    pageBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      // TODO(#40): Drag down to close?
      return LightboxPage(routeEntranceAnimation: animation, message: message, src: src);
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
