import 'package:flutter/foundation.dart';

import '../generated/l10n/zulip_localizations.dart';

/// The user's choice of visual theme for the app
///
/// See [zulipThemeData] for how themes are determined.
///
/// Renaming existing enum values will invalidate the database.
/// Write a migration if such a change is necessary.
enum ThemeSetting {
  /// Corresponds to [Brightness.light].
  light,

  /// Corresponds to [Brightness.dark].
  dark;

  static String displayName({
    required ThemeSetting? themeSetting,
    required ZulipLocalizations zulipLocalizations,
  }) {
    switch (themeSetting) {
      case null:
        return zulipLocalizations.themeSettingSystem;
      case ThemeSetting.light:
        return zulipLocalizations.themeSettingLight;
      case ThemeSetting.dark:
        return zulipLocalizations.themeSettingDark;
    }
  }
}

/// What browser the user has set to use for opening links in messages.
///
/// See https://chat.zulip.org/#narrow/stream/48-mobile/topic/in-app.20browser
/// for the reasoning behind these options.
///
/// Renaming existing enum values will invalidate the database.
/// Write a migration if such a change is necessary.
enum BrowserPreference {
  /// Use the in-app browser.
  embedded,

  /// Use the user's default browser app.
  external,
}
