import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import 'app.dart';
import 'home.dart';
import 'icons.dart';
import 'image.dart';
import 'page.dart';
import 'store.dart';
import 'theme.dart';
import 'user.dart';

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
    bool? centerTitle,
    super.backgroundColor,
    super.shape,
    super.actions,
    required bool showRealmIcon,
  }) :
    assert((title == null) != (buildTitle == null)),
    super(
      leading: showRealmIcon ? const _RealmIcon() : null,
      leadingWidth: showRealmIcon ? _realmIconWidth : null,
      centerTitle: showRealmIcon ? true : centerTitle,
      bottom: _ZulipAppBarBottom(backgroundColor: backgroundColor),
      title: title ?? _Title(
        centerTitle: centerTitle,
        actions: actions,
        buildTitle: buildTitle!,
        showRealmIcon: showRealmIcon)
    );
     static const _realmIconWidth = 50.0;
}

class _Title extends StatelessWidget {
  const _Title({
    required this.centerTitle,
    required this.actions,
    required this.buildTitle,
    required this.showRealmIcon,
  });

  final bool? centerTitle;
  final List<Widget>? actions;
  final Widget Function(bool centerTitle) buildTitle;
  final bool showRealmIcon;

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
    if (!showRealmIcon) return buildTitle(willCenterTitle);

    return buildTitle(true);
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

class _RealmIcon extends StatefulWidget {
  const _RealmIcon();

  @override
  State<_RealmIcon> createState() => _RealmIconState();
}

class _RealmIconState extends State<_RealmIcon> {
  void _handleSwitchAccount(BuildContext context) {
    Navigator.push(context,
      MaterialWidgetRoute(page: const ChooseAccountPage()));
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Tooltip(
          message: zulipLocalizations.switchAccountButtonTooltip,
          child: PressableOpacity(
            onTap: () => _handleSwitchAccount(context),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: AvatarShape(
                size: 28,
                borderRadius: 4,
                child: RealmContentNetworkImage(
                  store.resolvedRealmIcon,
                  filterQuality: FilterQuality.medium,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _RealmIconPlaceholder())))))));
  }
}

class _RealmIconPlaceholder extends StatelessWidget {
  const _RealmIconPlaceholder();

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: designVariables.avatarPlaceholderBg),
      child: Icon(ZulipIcons.globe,
        size: 28 * 20 / 32,
        color: designVariables.avatarPlaceholderIcon));
  }
}
