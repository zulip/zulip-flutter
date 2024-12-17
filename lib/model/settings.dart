import '../generated/l10n/zulip_localizations.dart';

/// The user's choice of visual theme for the app.
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
    return switch (themeSetting) {
      null => zulipLocalizations.themeSettingSystem,
      ThemeSetting.light => zulipLocalizations.themeSettingLight,
      ThemeSetting.dark => zulipLocalizations.themeSettingDark,
    };
  }
}

/// What browser the user has set to use for opening links in messages.
///
/// Renaming existing enum values will invalidate the database.
/// Write a migration if such a change is necessary.
enum BrowserPreference {
  /// Use the in-app browser for HTTP links.
  inApp,

  /// Use the user's default browser app.
  external,
}
