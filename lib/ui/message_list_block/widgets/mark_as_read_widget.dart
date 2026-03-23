import 'package:flutter/material.dart';

import '../../../generated/l10n/zulip_localizations.dart';
import '../../../model/narrow.dart';
import '../../../model/unreads.dart';
import '../../some_features/actions.dart';
import '../../values/icons.dart';
import '../message_list.dart';
import '../../some_features/store.dart';
import '../../values/text.dart';

class MarkAsReadWidget extends StatefulWidget {
  const MarkAsReadWidget({super.key, required this.narrow});

  final Narrow narrow;

  @override
  State<MarkAsReadWidget> createState() => _MarkAsReadWidgetState();
}

class _MarkAsReadWidgetState extends State<MarkAsReadWidget>
    with PerAccountStoreAwareStateMixin {
  Unreads? unreadsModel;

  bool _loading = false;

  void _unreadsModelChanged() {
    setState(() {
      // The actual state lives in [unreadsModel].
    });
  }

  @override
  void onNewStore() {
    final newStore = PerAccountStoreWidget.of(context);
    unreadsModel?.removeListener(_unreadsModelChanged);
    unreadsModel = newStore.unreads..addListener(_unreadsModelChanged);
  }

  @override
  void dispose() {
    unreadsModel?.removeListener(_unreadsModelChanged);
    super.dispose();
  }

  void _handlePress(BuildContext context) async {
    if (!context.mounted) return;
    setState(() => _loading = true);
    await ZulipAction.markNarrowAsRead(context, widget.narrow);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final unreadCount = unreadsModel!.countInNarrow(widget.narrow);
    final shouldHide = unreadCount == 0;

    final messageListTheme = MessageListTheme.of(context);

    return IgnorePointer(
      ignoring: shouldHide,
      child: MarkAsReadAnimation(
        loading: _loading,
        hidden: shouldHide,
        child: SizedBox(
          width: double.infinity,
          // Design referenced from:
          //   https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?type=design&node-id=132-9684&mode=design&t=jJwHzloKJ0TMOG4M-0
          child: Padding(
            // vertical padding adjusted for tap target height (48px) of button
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10 - ((48 - 38) / 2),
            ),
            child: FilledButton.icon(
              style:
                  FilledButton.styleFrom(
                    splashFactory: NoSplash.splashFactory,
                    minimumSize: const Size.fromHeight(38),
                    textStyle:
                        // Restate [FilledButton]'s default, which inherits from
                        // [zulipTypography]…
                        Theme.of(context).textTheme.labelLarge!
                        // …then clobber some attributes to follow Figma:
                        .merge(
                          TextStyle(
                            fontSize: 18,
                            letterSpacing: proportionalLetterSpacing(
                              context,
                              kButtonTextLetterSpacingProportion,
                              baseFontSize: 18,
                            ),
                            height: (23 / 18),
                          ).merge(weightVariableTextStyle(context, wght: 400)),
                        ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ).copyWith(
                    // Give the buttons a constant color regardless of whether their
                    // state is disabled, pressed, etc.  We handle those states
                    // separately, via MarkAsReadAnimation.
                    foregroundColor: const WidgetStatePropertyAll(Colors.white),
                    iconColor: const WidgetStatePropertyAll(Colors.white),
                    backgroundColor: WidgetStatePropertyAll(
                      messageListTheme.unreadMarker,
                    ),
                  ),
              onPressed: _loading ? null : () => _handlePress(context),
              icon: const Icon(ZulipIcons.message_checked),
              label: Text(zulipLocalizations.markAllAsReadLabel),
            ),
          ),
        ),
      ),
    );
  }
}

class MarkAsReadAnimation extends StatefulWidget {
  final bool loading;
  final bool hidden;
  final Widget child;

  const MarkAsReadAnimation({
    super.key,
    required this.loading,
    required this.hidden,
    required this.child,
  });

  @override
  State<MarkAsReadAnimation> createState() => _MarkAsReadAnimationState();
}

class _MarkAsReadAnimationState extends State<MarkAsReadAnimation> {
  bool _isPressed = false;

  void _setIsPressed(bool isPressed) {
    setState(() {
      _isPressed = isPressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setIsPressed(true),
      onTapUp: (_) => _setIsPressed(false),
      onTapCancel: () => _setIsPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: widget.hidden
              ? 0
              : widget.loading
              ? 0.5
              : 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
