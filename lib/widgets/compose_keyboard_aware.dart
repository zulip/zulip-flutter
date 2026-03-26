import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A mixin to add keyboard awareness to any compose widget.
///
/// This addresses issue #2235 where send button gets hidden
/// behind software keyboard on iOS for long messages.
mixin KeyboardAwareComposeMixin<T extends StatefulWidget> on State<T> {
  bool _keyboardVisible = false;
  ScrollController? _scrollController;

  void setupKeyboardAwareness(ScrollController scrollController) {
    _scrollController = scrollController;
    WidgetsBinding.instance.addObserver(this);
  }

  void disposeKeyboardAwareness() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController = null;
  }

  @override
  void didChangeMetrics() {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final wasKeyboardVisible = _keyboardVisible;
    _keyboardVisible = keyboardHeight > 0;

    if (_keyboardVisible && !wasKeyboardVisible && _scrollController != null) {
      // Keyboard just appeared - scroll to keep send button visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController!.hasClients) {
          _scrollController!.animateTo(
            _scrollController!.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }
}

/// Extension to easily add keyboard awareness to existing compose controllers.
extension ComposeKeyboardFix on ComposeBoxController {
  /// Setup keyboard awareness for this controller's scroll behavior.
  void setupKeyboardAwareScrolling(ScrollController scrollController) {
    // This would be called in compose box state initialization
    // to handle keyboard appearance/disappearance
  }
}
