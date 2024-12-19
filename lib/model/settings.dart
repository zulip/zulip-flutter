import 'package:flutter/foundation.dart';

import '../generated/l10n/zulip_localizations.dart';

/// The visual theme of the app.
///
/// See [zulipThemeData] for how themes are determined.
///
/// Renaming existing enum values will invalidate the database.
/// Write a migration if such a change is necessary.
enum ThemeSetting {
  /// Corresponds to the default platform setting.
  unset,

  /// Corresponds to [Brightness.light].
  light,

  /// Corresponds to [Brightness.dark].
  dark;

  String displayName(ZulipLocalizations zulipLocalizations) {
    switch (this) {
      case ThemeSetting.unset:
        return zulipLocalizations.themeSettingSystem;
      case ThemeSetting.light:
        return zulipLocalizations.themeSettingLight;
      case ThemeSetting.dark:
        return zulipLocalizations.themeSettingDark;
    }
  }
}

