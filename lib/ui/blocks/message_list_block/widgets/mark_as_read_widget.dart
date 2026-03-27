import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../model/narrow.dart';
import '../../../themes/message_list_theme.dart';
import '../../../utils/actions.dart';
import '../../../values/icons.dart';

import '../../../values/text.dart';
import 'mark_as_read_controller.dart';

class MarkAsReadWidget extends StatelessWidget {
  const MarkAsReadWidget({super.key, required this.narrow});

  final Narrow narrow;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MarkAsReadController>(
      init: MarkAsReadController(narrow: narrow),
      tag: narrow.toString(),
      builder: (controller) {
        return Obx(() {
          final zulipLocalizations = ZulipLocalizations.of(context);
          final shouldHide = controller.shouldHide;
          final loading = controller.loading.value;

          final messageListTheme = MessageListTheme.of(context);

          return IgnorePointer(
            ignoring: shouldHide,
            child: MarkAsReadAnimation(
              loading: loading,
              hidden: shouldHide,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10 - ((48 - 38) / 2),
                  ),
                  child: FilledButton.icon(
                    style:
                        FilledButton.styleFrom(
                          splashFactory: NoSplash.splashFactory,
                          minimumSize: const Size.fromHeight(38),
                          textStyle: Theme.of(context).textTheme.labelLarge!
                              .merge(
                                TextStyle(
                                  fontSize: 18,
                                  letterSpacing: proportionalLetterSpacing(
                                    context,
                                    kButtonTextLetterSpacingProportion,
                                    baseFontSize: 18,
                                  ),
                                  height: (23 / 18),
                                ).merge(
                                  weightVariableTextStyle(context, wght: 400),
                                ),
                              ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ).copyWith(
                          foregroundColor: const WidgetStatePropertyAll(
                            Colors.white,
                          ),
                          iconColor: const WidgetStatePropertyAll(Colors.white),
                          backgroundColor: WidgetStatePropertyAll(
                            messageListTheme.unreadMarker,
                          ),
                        ),
                    onPressed: loading
                        ? null
                        : () async {
                            controller.loading.value = true;
                            await ZulipAction.markNarrowAsRead(context, narrow);
                            controller.loading.value = false;
                          },
                    icon: const Icon(ZulipIcons.message_checked),
                    label: Text(zulipLocalizations.markAllAsReadLabel),
                  ),
                ),
              ),
            ),
          );
        });
      },
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
