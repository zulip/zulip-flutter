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
  dark,
}
