import 'package:flutter/foundation.dart';

import '../generated/l10n/zulip_localizations.dart';
import 'binding.dart';
import 'database.dart';

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
  ///
  /// For other types of links (e.g. mailto) where a browser won't work,
  /// this falls back to [UrlLaunchMode.platformDefault].
  inApp,

  /// Use the user's default browser app.
  external,
}

/// Store for the user's account-independent settings.
///
/// From UI code, use [GlobalStoreWidget.settingsOf] to get hold of
/// an appropriate instance of this class.
class GlobalSettingsStore extends ChangeNotifier {
  GlobalSettingsStore({required GlobalSettingsData data}) : _data = data;

  /// A cache of the [GlobalSettingsData] singleton in the underlying data store.
  GlobalSettingsData _data;

  /// The user's choice of [ThemeSetting];
  /// null means the device-level choice of theme.
  ThemeSetting? get themeSetting => _data.themeSetting;

  /// The user's choice of [BrowserPreference];
  /// null means use our default choice.
  ///
  /// Consider using [effectiveBrowserPreference] or [getUrlLaunchMode].
  BrowserPreference? get browserPreference => _data.browserPreference;

  /// The value of [BrowserPreference] to use:
  /// the user's choice [browserPreference] if any, else our default.
  ///
  /// See also [getUrlLaunchMode].
  BrowserPreference get effectiveBrowserPreference {
    if (browserPreference != null) return browserPreference!;
    return switch (defaultTargetPlatform) {
      // On iOS we prefer UrlLaunchMode.externalApplication because (for
      // HTTP URLs) UrlLaunchMode.platformDefault uses SFSafariViewController,
      // which gives an awkward UX as described here:
      //  https://chat.zulip.org/#narrow/stream/48-mobile/topic/in-app.20browser/near/1169118
      TargetPlatform.iOS => BrowserPreference.external,

      // On Android we prefer an in-app browser.  See discussion from 2021:
      //   https://chat.zulip.org/#narrow/channel/48-mobile/topic/in-app.20browser/near/1169095
      // That's also the `url_launcher` default (at least as of 2025).
      _ => BrowserPreference.inApp,
    };
  }

  /// The launch mode to use with `url_launcher`,
  /// based on the user's choice in [browserPreference].
  UrlLaunchMode getUrlLaunchMode(Uri url) {
    switch (effectiveBrowserPreference) {
      case BrowserPreference.inApp:
        if (!(url.scheme == 'https' || url.scheme == 'http')) {
          // For URLs on non-HTTP schemes such as `mailto`,
          // `url_launcher.launchUrl` rejects `inAppBrowserView` with an error:
          //   https://github.com/flutter/packages/blob/9cc6f370/packages/url_launcher/url_launcher/lib/src/url_launcher_uri.dart#L46-L51
          // TODO(upstream/url_launcher): should fall back in this case instead
          //   (as the `launchUrl` doc already says it may do).
          return UrlLaunchMode.platformDefault;
        }
        return UrlLaunchMode.inAppBrowserView;

      case BrowserPreference.external:
        return UrlLaunchMode.externalApplication;
    }
  }

  /// (Should only be called by [GlobalStore].)
  void update(GlobalSettingsCompanion data) {
    // TODO move responsibility for updating the DB to this class too
    _data = _data.copyWithCompanion(data);
    notifyListeners();
  }
}
