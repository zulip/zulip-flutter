import 'package:flutter/foundation.dart';

import '../generated/l10n/zulip_localizations.dart';
import 'binding.dart';
import 'database.dart';
import 'narrow.dart';
import 'store.dart';

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

/// The user's choice of when to open a message list at their first unread,
/// rather than at the newest message.
///
/// This setting has no effect when navigating to a specific message:
/// in that case the message list opens at that message,
/// regardless of this setting.
enum VisitFirstUnreadSetting {
  /// Always go to the first unread, rather than the newest message.
  always,

  /// Go to the first unread in conversations,
  /// and the newest in interleaved views.
  conversations,

  /// Always go to the newest message, rather than the first unread.
  never;

  /// The effective value of this setting if the user hasn't set it.
  static VisitFirstUnreadSetting _default = conversations;
}

/// The user's choice of which message-list views should
/// automatically mark messages as read when scrolling through them.
///
/// This can be overridden by local state: for example, if you've just tapped
/// "Mark as unread from here" the view will stop marking as read automatically,
/// regardless of this setting.
enum MarkReadOnScrollSetting {
  /// All views.
  always,

  /// Only conversation views.
  conversations,

  /// No views.
  never;

  /// The effective value of this setting if the user hasn't set it.
  static MarkReadOnScrollSetting _default = conversations;
}

/// The outcome, or in-progress status, of migrating data from the legacy app.
enum LegacyUpgradeState {
  /// It's not yet known whether there was data from the legacy app.
  unknown,

  /// No legacy data was found.
  noLegacy,

  /// Legacy data was found, but not yet migrated into this app's database.
  found,

  /// Legacy data was found and migrated.
  migrated,
  ;

  static LegacyUpgradeState _default = unknown;
}

/// A general category of account-independent setting the user might set.
///
/// Different kinds of settings call for different treatment in the UI,
/// and different expected lifecycles as the app evolves.
enum GlobalSettingType {
  /// Describes a non-setting which exists to avoid an empty enum.
  ///
  /// A Dart enum must have at least one value.
  /// But in steady state we expect to have no experimental feature flags.
  /// To allow [BoolGlobalSetting] to continue to exist in that situation
  /// (so that it stands ready to accept a future feature flag),
  /// we give it a placeholder value which isn't a real setting.
  placeholder,

  /// Describes a pseudo-setting not directly exposed in the UI.
  internal,

  /// Describes a setting which enables an in-progress feature of the app.
  ///
  /// Sometimes when building a complex feature it's useful to merge PRs that
  /// make partial progress, and then to have the feature's logic gated behind
  /// a setting that serves as a "feature flag".
  /// This enables those working on the feature to enable the flag in order to
  /// see the current incomplete behavior, while for everyone else it remains
  /// disabled and so (barring bugs in the use of the flag itself) has no effect.
  ///
  /// These settings are primarily meant for people developing Zulip to use,
  /// and so appear in an out-of-the-way part of the settings UI.
  ///
  /// Settings of this kind are costly to the health of the codebase if
  /// allowed to accumulate.  Most features don't need one, even features that
  /// take two or three PRs to implement.  See discussion at:
  ///   https://github.com/zulip/zulip-flutter/issues/1409#issuecomment-2725793787
  /// When a feature flag is introduced, take care to drive the project to
  /// completion, either by merge or removal, so that the flag can be retired
  /// within a period of a few weeks or months.
  experimentalFeatureFlag,
  ;
}

/// A bool-valued, account-independent setting the user might set.
///
/// These are recorded in the table [BoolGlobalSettings].
/// To read the value of one of these settings, use [GlobalSettingsStore.getBool];
/// to set the value, use [GlobalSettingsStore.setBool].
///
/// To introduce a new setting, add a value to this enum.
/// Avoid re-using any old names found in the "former settings" list.
///
/// To remove a setting, comment it out and move to the "former settings" list.
/// Tracking the names of settings that formerly existed is important because
/// they may still appear in users' databases, which means that if we were to
/// accidentally reuse one for an unrelated new setting then users would
/// unwittingly get those values applied to the new setting,
/// which could cause very confusing buggy behavior.
///
/// (If the list of former settings gets long, we could do a migration to clear
/// them from existing installs, and then drop the list.  We don't do that
/// eagerly each time, to avoid creating a new schema version each time we
/// finish an experimental feature.)
enum BoolGlobalSetting {
  /// A non-setting to ensure this enum has at least one value.
  ///
  /// Leave this in place even when there are experimental feature flags too.
  /// That way when we remove those, this is already here.
  /// (Having one stable value in this enum is also handy for tests.)
  placeholderIgnore(GlobalSettingType.placeholder, false),

  /// A pseudo-setting recording whether the user has been shown the
  /// welcome dialog for upgrading from the legacy app.
  upgradeWelcomeDialogShown(GlobalSettingType.internal, false),

  /// An experimental flag to enable rendering KaTeX even when some
  /// errors are encountered.
  forceRenderKatex(GlobalSettingType.experimentalFeatureFlag, false),

  // Former settings which might exist in the database,
  // whose names should therefore not be reused:
  //   openFirstUnread  // v0.0.30
  //   renderKatex      // v0.0.29 - v30.0.261
  ;

  const BoolGlobalSetting(this.type, this.default_);

  /// The general category of setting that this setting belongs to.
  final GlobalSettingType type;

  /// The value the setting effectively has if the user hasn't chosen a value.
  final bool default_;

  static BoolGlobalSetting? byName(String name) => _byName[name];

  static final Map<String, BoolGlobalSetting> _byName = {
    for (final v in values)
      v.name: v,
  };
}

/// An int-valued, account-independent setting the user might set.
///
/// These are recorded in the table [IntGlobalSettings].
/// To read the value of one of these settings, use [GlobalSettingsStore.getInt];
/// to set the value, use [GlobalSettingsStore.setInt].
///
/// To introduce a new setting, add a value to this enum.
/// Avoid re-using any old names found in the "former settings" list.
///
/// To remove a setting, comment it out and move to the "former settings" list.
/// Tracking the names of settings that formerly existed is important because
/// they may still appear in users' databases, which means that if we were to
/// accidentally reuse one for an unrelated new setting then users would
/// unwittingly get those values applied to the new setting,
/// which could cause very confusing buggy behavior.
///
/// (If the list of former settings gets long, we could do a migration to clear
/// them from existing installs, and then drop the list.  We don't do that
/// eagerly each time, to avoid creating a new schema version each time we
/// finish an experimental feature.)
enum IntGlobalSetting {
  /// A non-setting to ensure this enum has at least one value.
  ///
  /// (This is also handy to use in tests.)
  placeholderIgnore,

  // Former settings which might exist in the database,
  // whose names should therefore not be reused:
  // (this list is empty so far)
  ;

  static IntGlobalSetting? byName(String name) => _byName[name];

  static final Map<String, IntGlobalSetting> _byName = {
    for (final v in values)
      v.name: v,
  };
}

/// Store for the user's account-independent settings.
///
/// From UI code, use [GlobalStoreWidget.settingsOf] to get hold of
/// an appropriate instance of this class.
class GlobalSettingsStore extends ChangeNotifier {
  GlobalSettingsStore({
    required GlobalStoreBackend backend,
    required GlobalSettingsData data,
    required Map<BoolGlobalSetting, bool> boolData,
    required Map<IntGlobalSetting, int> intData,
  }) : _backend = backend, _data = data, _boolData = boolData, _intData = intData;

  static final List<BoolGlobalSetting> experimentalFeatureFlags =
    BoolGlobalSetting.values.where((setting) =>
      setting.type == GlobalSettingType.experimentalFeatureFlag).toList();

  final GlobalStoreBackend _backend;

  /// A cache of the [GlobalSettingsData] singleton in the underlying data store.
  GlobalSettingsData _data;

  Future<void> _update(GlobalSettingsCompanion data) async {
    await _backend.doUpdateGlobalSettings(data);
    _data = _data.copyWithCompanion(data);
    notifyListeners();
  }

  /// The user's choice of [ThemeSetting];
  /// null means the device-level choice of theme.
  ///
  /// See also [setThemeSetting].
  ThemeSetting? get themeSetting => _data.themeSetting;

  /// Set [themeSetting], persistently for future runs of the app.
  Future<void> setThemeSetting(ThemeSetting? value) async {
    await _update(GlobalSettingsCompanion(themeSetting: Value(value)));
  }

  /// The user's choice of [BrowserPreference];
  /// null means use our default choice.
  ///
  /// Consider using [effectiveBrowserPreference] or [getUrlLaunchMode].
  ///
  /// See also [setBrowserPreference].
  BrowserPreference? get browserPreference => _data.browserPreference;

  /// Set [browserPreference], persistently for future runs of the app.
  Future<void> setBrowserPreference(BrowserPreference? value) async {
    await _update(GlobalSettingsCompanion(browserPreference: Value(value)));
  }

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

  /// The user's choice of [VisitFirstUnreadSetting], applying our default.
  ///
  /// See also [shouldVisitFirstUnread] and [setVisitFirstUnread].
  VisitFirstUnreadSetting get visitFirstUnread {
    return _data.visitFirstUnread ?? VisitFirstUnreadSetting._default;
  }

  /// Set [visitFirstUnread], persistently for future runs of the app.
  Future<void> setVisitFirstUnread(VisitFirstUnreadSetting value) async {
    await _update(GlobalSettingsCompanion(visitFirstUnread: Value(value)));
  }

  /// The value that [visitFirstUnread] works out to for the given narrow.
  bool shouldVisitFirstUnread({required Narrow narrow}) {
    return switch (visitFirstUnread) {
      VisitFirstUnreadSetting.always => true,
      VisitFirstUnreadSetting.never => false,
      VisitFirstUnreadSetting.conversations => switch (narrow) {
        TopicNarrow() || DmNarrow()
          => true,
        CombinedFeedNarrow() || ChannelNarrow()
        || MentionsNarrow() || StarredMessagesNarrow()
        || KeywordSearchNarrow()
          => false,
      },
    };
  }

  /// The user's choice of [MarkReadOnScrollSetting], applying our default.
  ///
  /// See also [markReadOnScrollForNarrow] and [setMarkReadOnScroll].
  MarkReadOnScrollSetting get markReadOnScroll {
    return _data.markReadOnScroll ?? MarkReadOnScrollSetting._default;
  }

  /// Set [markReadOnScroll], persistently for future runs of the app.
  Future<void> setMarkReadOnScroll(MarkReadOnScrollSetting value) async {
    await _update(GlobalSettingsCompanion(markReadOnScroll: Value(value)));
  }

  /// The value that [markReadOnScroll] works out to for the given narrow.
  bool markReadOnScrollForNarrow(Narrow narrow) {
    return switch (markReadOnScroll) {
      MarkReadOnScrollSetting.always => true,
      MarkReadOnScrollSetting.never => false,
      MarkReadOnScrollSetting.conversations => switch (narrow) {
        TopicNarrow() || DmNarrow()
          => true,
        CombinedFeedNarrow() || ChannelNarrow()
        || MentionsNarrow() || StarredMessagesNarrow()
        || KeywordSearchNarrow()
          => false,
      },
    };
  }

  /// The outcome, or in-progress status, of migrating data from the legacy app.
  LegacyUpgradeState get legacyUpgradeState {
    return _data.legacyUpgradeState ?? LegacyUpgradeState._default;
  }

  /// Set [legacyUpgradeState], persistently for future runs of the app.
  @visibleForTesting
  Future<void> debugSetLegacyUpgradeState(LegacyUpgradeState value) async {
    await _update(GlobalSettingsCompanion(legacyUpgradeState: Value(value)));
  }

  /// The user's choice of the given bool-valued setting, or our default for it.
  ///
  /// See also [setBool].
  bool getBool(BoolGlobalSetting setting) {
    return _boolData[setting] ?? setting.default_;
  }

  /// A cache of the [BoolGlobalSettings] table in the underlying data store.
  final Map<BoolGlobalSetting, bool> _boolData;

  /// Set or unset the given bool-valued setting,
  /// persistently for future runs of the app.
  ///
  /// A value of null means the setting will revert to following
  /// the app's default.
  ///
  /// If [value] equals the setting's current value, the database operation
  /// and [notifyListeners] are skipped.
  ///
  /// See also [getBool].
  Future<void> setBool(BoolGlobalSetting setting, bool? value) async {
    if (value == _boolData[setting]) return;

    await _backend.doSetBoolGlobalSetting(setting, value);
    if (value == null) {
      _boolData.remove(setting);
    } else {
      _boolData[setting] = value;
    }
    notifyListeners();
  }

  /// The user's choice of the given int-valued setting, or null if not set.
  ///
  /// See also [setInt].
  int? getInt(IntGlobalSetting setting) {
    return _intData[setting];
  }

  /// A cache of the [IntGlobalSettings] table in the underlying data store.
  final Map<IntGlobalSetting, int> _intData;

  /// Set or unset the given int-valued setting,
  /// persistently for future runs of the app.
  ///
  /// A value of null means the setting will be cleared out.
  ///
  /// If [value] equals the setting's current value, the database operation
  /// and [notifyListeners] are skipped.
  ///
  /// See also [getInt].
  Future<void> setInt(IntGlobalSetting setting, int? value) async {
    if (value == _intData[setting]) return;

    await _backend.doSetIntGlobalSetting(setting, value);
    if (value == null) {
      _intData.remove(setting);
    } else {
      _intData[setting] = value;
    }
    notifyListeners();
  }
}
