import 'package:flutter/foundation.dart';

import '../generated/l10n/zulip_localizations.dart';
import 'database.dart';

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

extension GlobalSettingsHelpers on GlobalSettingsData {
  BrowserPreference get effectiveBrowserPreference {
    if (browserPreference != null) {
      return browserPreference!;
    }
    return switch (defaultTargetPlatform) {
      // On iOS we prefer LaunchMode.externalApplication because (for
      // HTTP URLs) LaunchMode.platformDefault uses SFSafariViewController,
      // which gives an awkward UX as described here:
      //  https://chat.zulip.org/#narrow/stream/48-mobile/topic/in-app.20browser/near/1169118
      TargetPlatform.iOS => BrowserPreference.external,
      _ => BrowserPreference.embedded,
    };
  }
}
