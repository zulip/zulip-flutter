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

    Widget? subtitle;
    final language = GlobalStoreWidget.settingsOf(context).language;
    if (language != null && kSelfnamesByLocale.containsKey(language)) {
      subtitle = Text(kSelfnamesByLocale[language]!);
    }

    return Scaffold(
      appBar: ZulipAppBar(
        title: Text(zulipLocalizations.settingsPageTitle)),
      body: Column(children: [
        const _ThemeSetting(),
        const _BrowserPreferenceSetting(),
        ListTile(
          title: Text(zulipLocalizations.languageSettingTitle),
          subtitle: subtitle,
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
          for (final MapEntry(:key, :value) in kSelfnamesByLocale.entries)
            _LanguageItem(locale: key, selfname: value),
        ])));
  }
}

class _LanguageItem extends StatelessWidget {
  const _LanguageItem({required this.locale, required this.selfname});

  final Locale locale;
  final String selfname;

  @override
  Widget build(BuildContext context) {
    final globalSettings = GlobalStoreWidget.settingsOf(context);

    final Widget subtitle;
    final Widget? trailing;
    if (locale == globalSettings.language) {
      assert(Localizations.localeOf(context) == locale);
      // For `subtitle`, the ambient locale is the same as selfname's
      // corresponding locale — there is no need to override [Localization].
      subtitle = Text(selfname);
      trailing = Icon(ZulipIcons.check);
    } else {
      final zulipLocalizations = ZulipLocalizations.of(context);
      subtitle = Text(zulipLocalizations.localeDisplayName(locale));
      trailing = null;
    }

    return ListTile(
      title: Localizations.override(
        context: context,
        // Different from other text in the app, `selfname` is localized with
        // its corresponding locale, which is not always the ambient one.
        locale: locale,
        child: Text(selfname)),
      subtitle: subtitle,
      trailing: trailing,
      onTap: () {
        globalSettings.setLanguage(locale);
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
