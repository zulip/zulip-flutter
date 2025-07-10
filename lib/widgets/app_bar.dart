import 'package:flutter/material.dart';

import 'store.dart';

/// A custom [AppBar] with a loading indicator.
///
/// This should be used for most of the pages with access to [PerAccountStore].
class ZulipAppBar extends AppBar {
  /// Creates our Zulip custom app bar based on [AppBar].
  ///
  /// [buildTitle] is passed a boolean `willCenterTitle` that answers
  /// whether the underlying [AppBar] will decide to center [title]
  /// based on [centerTitle], the theme, the platform, and [actions].
  /// Useful if [title] is a container whose children should align the same way,
  /// such as a [Column] with multiple lines of text.
  // TODO(upstream) send a PR to replace our `willCenterTitle` code
  ZulipAppBar({
    super.key,
    super.titleSpacing,
    Widget? title,
    Widget Function(bool willCenterTitle)? buildTitle,
    super.centerTitle,
    super.backgroundColor,
    super.shape,
    super.actions,
  }) :
    assert((title == null) != (buildTitle == null)),
    super(
      bottom: _ZulipAppBarBottom(backgroundColor: backgroundColor),
      title: title ?? _Title(centerTitle: centerTitle, actions: actions, buildTitle: buildTitle!)
    );
}

class _Title extends StatelessWidget {
  const _Title({
    required this.centerTitle,
    required this.actions,
    required this.buildTitle,
  });

  final bool? centerTitle;
  final List<Widget>? actions;
  final Widget Function(bool centerTitle) buildTitle;

  // A copy of [AppBar._getEffectiveCenterTitle].
  bool _getEffectiveCenterTitle(ThemeData theme) {
    bool platformCenter() {
      switch (theme.platform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          return false;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return actions == null || actions!.length < 2;
      }
    }

    return centerTitle ?? theme.appBarTheme.centerTitle ?? platformCenter();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final willCenterTitle = _getEffectiveCenterTitle(theme);
    return buildTitle(willCenterTitle);
  }
}

class _ZulipAppBarBottom extends StatelessWidget implements PreferredSizeWidget {
  const _ZulipAppBarBottom({this.backgroundColor});

  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(4.0);

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    if (!store.isRecoveringEventStream) return const SizedBox.shrink();
    return LinearProgressIndicator(minHeight: 4.0, backgroundColor: backgroundColor);
  }
}
