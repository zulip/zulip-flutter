import 'package:flutter/material.dart';

/// A blank loading placeholder widget.
class BlankLoadingPlaceholder extends StatelessWidget {
  const BlankLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// A loading indicator widget.
class LoadingPlaceholder extends StatelessWidget {
  const LoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
