import 'package:flutter/material.dart';

/// A custom [AppBar] with a loading indicator.
///
/// This should be used for most of the pages with access to [PerAccountStore].
// However, there are some exceptions (add more if necessary):
// - `lib/widgets/lightbox.dart`
class ZulipAppBar extends AppBar {
  ZulipAppBar({
    super.key,
    required super.title,
    super.backgroundColor,
    super.shape,
    super.actions,
    required bool isLoading,
  }) : super(
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(4.0),
      child: (isLoading)
        ? LinearProgressIndicator(backgroundColor: backgroundColor, minHeight: 4.0)
        : const SizedBox.shrink()));
}
