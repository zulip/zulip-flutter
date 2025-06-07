import 'dart:async';

import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/localizations.dart';
import '../model/settings.dart';
import 'app_bar.dart';
import 'icons.dart';
import 'page.dart';
import 'store.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static AccountRoute<void> buildRoute({required BuildContext context}) {
    return MaterialAccountWidgetRoute(
      context: context, page: const SettingsPage());
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);

    Widget? languageSettingSubtitle;
    final language = GlobalStoreWidget.settingsOf(context).language;
    if (language != null && kSelfnamesByLocale.containsKey(language)) {
      languageSettingSubtitle = Text(kSelfnamesByLocale[language]!);
    }

    return Scaffold(
      appBar: ZulipAppBar(
        title: Text(zulipLocalizations.settingsPageTitle)),
      body: Column(children: [
        const _ThemeSetting(),
        const _BrowserPreferenceSetting(),
        ListTile(
          title: Text(zulipLocalizations.languageSettingTitle),
          subtitle: languageSettingSubtitle,
          onTap: () => Navigator.push(context, _LanguagePage.buildRoute())),
        if (GlobalSettingsStore.experimentalFeatureFlags.isNotEmpty)
          ListTile(
            title: Text(zulipLocalizations.experimentalFeatureSettingsPageTitle),
            onTap: () => Navigator.push(context,
              ExperimentalFeaturesPage.buildRoute())),
      ]));
  }
}

class _ThemeSetting extends StatelessWidget {
  const _ThemeSetting();

  void _handleChange(BuildContext context, ThemeSetting? newThemeSetting) {
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    globalSettings.setThemeSetting(newThemeSetting);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    return Column(
      children: [
        ListTile(title: Text(zulipLocalizations.themeSettingTitle)),
        for (final themeSettingOption in [null, ...ThemeSetting.values])
          RadioListTile<ThemeSetting?>.adaptive(
            title: Text(ThemeSetting.displayName(
              themeSetting: themeSettingOption,
              zulipLocalizations: zulipLocalizations)),
            value: themeSettingOption,
            groupValue: globalSettings.themeSetting,
            onChanged: (newValue) => _handleChange(context, newValue)),
      ]);
  }
}

class _BrowserPreferenceSetting extends StatelessWidget {
  const _BrowserPreferenceSetting();

  void _handleChange(BuildContext context, bool newOpenLinksWithInAppBrowser) {
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    globalSettings.setBrowserPreference(
      newOpenLinksWithInAppBrowser ? BrowserPreference.inApp
                                   : BrowserPreference.external);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    final openLinksWithInAppBrowser =
      globalSettings.effectiveBrowserPreference == BrowserPreference.inApp;
    return SwitchListTile.adaptive(
      title: Text(zulipLocalizations.openLinksWithInAppBrowser),
      value: openLinksWithInAppBrowser,
      onChanged: (newValue) => _handleChange(context, newValue));
  }
}

class _LanguagePage extends StatelessWidget {
  const _LanguagePage();

  static WidgetRoute<void> buildRoute() {
    return MaterialWidgetRoute(page: const _LanguagePage());
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(zulipLocalizations.languageSettingTitle)),
      body: SingleChildScrollView(
        child: Column(children: [
          for (final language in zulipLocalizations.languages())
            _LanguageItem(language: language),
        ])));
  }
}

class _LanguageItem extends StatelessWidget {
  const _LanguageItem({required this.language});

  /// The [Language] this corresponds to, from [ZulipLocalizations.languages].
  final Language language;

  @override
  Widget build(BuildContext context) {
    final (locale, selfname, displayName) = language;
    final isCurrentLanguageInSettings =
      locale == GlobalStoreWidget.settingsOf(context).language;

    return ListTile(
      title: Text(selfname),
      subtitle: Text(
        isCurrentLanguageInSettings
        ? // Make sure the subtitle text is consistent to the title — since
          // displayName (decided by translators) can be different from our
          // hard-coded selfname when isCurrentLanguage is true.
          selfname
        : displayName),
      trailing: isCurrentLanguageInSettings ? Icon(ZulipIcons.check) : null,
      onTap: () {
        unawaited(GlobalStoreWidget.settingsOf(context).setLanguage(locale));
      });
  }
}

class ExperimentalFeaturesPage extends StatelessWidget {
  const ExperimentalFeaturesPage({super.key});

  static WidgetRoute<void> buildRoute() {
    return MaterialWidgetRoute(page: const ExperimentalFeaturesPage());
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    final flags = GlobalSettingsStore.experimentalFeatureFlags;
    assert(flags.isNotEmpty);
    return Scaffold(
      appBar: AppBar(
        title: Text(zulipLocalizations.experimentalFeatureSettingsPageTitle)),
      body: Column(children: [
        ListTile(
          title: Text(zulipLocalizations.experimentalFeatureSettingsWarning)),
        for (final flag in flags)
          SwitchListTile.adaptive(
            title: Text(flag.name), // no i18n; these are developer-facing settings
            value: globalSettings.getBool(flag),
            onChanged: (value) => globalSettings.setBool(flag, value)),
      ]));
  }
}
