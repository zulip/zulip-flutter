import 'package:flutter/material.dart';

import '../values/theme.dart';

/// Compose-box styles that differ between light and dark theme.
///
/// These styles will animate on theme changes (with help from [lerp]).
class ComposeBoxTheme extends ThemeExtension<ComposeBoxTheme> {
  static final light = ComposeBoxTheme._(boxShadow: null);

  static final dark = ComposeBoxTheme._(
    boxShadow: [
      BoxShadow(
        color: DesignVariables.dark.bgTopBar,
        offset: const Offset(0, -4),
        blurRadius: 16,
        spreadRadius: 0,
      ),
    ],
  );

  ComposeBoxTheme._({required this.boxShadow});

  /// The [ComposeBoxTheme] from the context's active theme.
  ///
  /// The [ThemeData] must include [ComposeBoxTheme] in [ThemeData.extensions].
  static ComposeBoxTheme of(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<ComposeBoxTheme>();
    assert(extension != null);
    return extension!;
  }

  final List<BoxShadow>? boxShadow;

  @override
  ComposeBoxTheme copyWith({List<BoxShadow>? boxShadow}) {
    return ComposeBoxTheme._(boxShadow: boxShadow ?? this.boxShadow);
  }

  @override
  ComposeBoxTheme lerp(ComposeBoxTheme other, double t) {
    if (identical(this, other)) {
      return this;
    }
    return ComposeBoxTheme._(
      boxShadow: BoxShadow.lerpList(boxShadow, other.boxShadow, t)!,
    );
  }
}
