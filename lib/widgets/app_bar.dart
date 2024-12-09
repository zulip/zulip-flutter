import 'package:flutter/material.dart';

import 'store.dart';

/// A custom [AppBar] with a loading indicator.
///
/// This should be used for most of the pages with access to [PerAccountStore].
class ZulipAppBar extends AppBar {
  ZulipAppBar({
    super.key,
    super.titleSpacing,
    required super.title,
    super.backgroundColor,
    super.shape,
    super.actions,
  }) : super(bottom: _ZulipAppBarBottom(backgroundColor: backgroundColor));
}

class _ZulipAppBarBottom extends StatelessWidget implements PreferredSizeWidget {
  const _ZulipAppBarBottom({this.backgroundColor});

  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(4.0);

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    if (!store.isLoading) return const SizedBox.shrink();
    return LinearProgressIndicator(minHeight: 4.0, backgroundColor: backgroundColor);
  }
}
