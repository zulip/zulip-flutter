import 'package:flutter/material.dart';

/// A widget that adds bottom padding when keyboard is visible
/// to prevent UI elements from being hidden behind the keyboard.
///
/// This addresses issue #2235 with minimal UI changes.
class KeyboardPaddingFix extends StatelessWidget {
  const KeyboardPaddingFix({
    super.key,
    required this.child,
    this.additionalPadding = 16.0,
  });

  final Widget child;
  final double additionalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + additionalPadding,
      ),
      child: child,
    );
  }
}

/// Extension to easily add keyboard padding to any widget.
extension KeyboardPaddingExtension on Widget {
  /// Wrap this widget with keyboard-aware padding.
  Widget withKeyboardPadding({double additionalPadding = 16.0}) {
    return KeyboardPaddingFix(
      additionalPadding: additionalPadding,
      child: this,
    );
  }
}
