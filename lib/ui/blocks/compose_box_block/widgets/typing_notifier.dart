import 'package:flutter/material.dart';

import '../../../../get/services/store_service.dart';
import '../../../../model/narrow.dart';
import '../compose_box.dart';

class TypingNotifier extends StatefulWidget {
  const TypingNotifier({
    super.key,
    required this.destination,
    required this.controller,
    required this.child,
  });

  final SendableNarrow destination;
  final ComposeBoxController controller;
  final Widget child;

  @override
  State<TypingNotifier> createState() => _TypingNotifierState();
}

class _TypingNotifierState extends State<TypingNotifier>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    widget.controller.content.addListener(_contentChanged);
    widget.controller.contentFocusNode.addListener(_focusChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant TypingNotifier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.content.removeListener(_contentChanged);
      widget.controller.content.addListener(_contentChanged);
      oldWidget.controller.contentFocusNode.removeListener(_focusChanged);
      widget.controller.contentFocusNode.addListener(_focusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.content.removeListener(_contentChanged);
    widget.controller.contentFocusNode.removeListener(_focusChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _contentChanged() {
    final store = requirePerAccountStore();
    (widget.controller.content.text.isEmpty)
        ? store.typingNotifier.stoppedComposing()
        : store.typingNotifier.keystroke(widget.destination);
  }

  void _focusChanged() {
    if (widget.controller.contentFocusNode.hasFocus) {
      // Content input getting focus doesn't necessarily mean that
      // the user started typing, so do nothing.
      return;
    }
    final store = requirePerAccountStore();
    store.typingNotifier.stoppedComposing();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Transition to either [hidden] or [paused] signals that
        // > [the] application is not currently visible to the user, and not
        // > responding to user input.
        //
        // When transitioning to [detached], the compose box can't exist:
        // > The application defaults to this state before it initializes, and
        // > can be in this state (applicable on Android, iOS, and web) after
        // > all views have been detached.
        //
        // For all these states, we can conclude that the user is not
        // composing a message.
        final store = requirePerAccountStore();
        store.typingNotifier.stoppedComposing();
      case AppLifecycleState.inactive:
      // > At least one view of the application is visible, but none have
      // > input focus. The application is otherwise running normally.
      // For example, we expect this state when the user is selecting a file
      // to upload.
      case AppLifecycleState.resumed:
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
