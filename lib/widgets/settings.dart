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
    return Scaffold(
      appBar: ZulipAppBar(
        title: Text(zulipLocalizations.settingsPageTitle)),
      body: SingleChildScrollView(child: Column(children: [
        const _ThemeSetting(),
        const _BrowserPreferenceSetting(),
        const _VisitFirstUnreadSetting(),
        const _MarkReadOnScrollSetting(),
        const _LanguageSetting(),
        if (GlobalSettingsStore.experimentalFeatureFlags.isNotEmpty)
          ListTile(
            title: Text(zulipLocalizations.experimentalFeatureSettingsPageTitle),
            onTap: () => Navigator.push(context,
              ExperimentalFeaturesPage.buildRoute()))
      ])));
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
            // TODO(#1545) stop using the deprecated members
            // ignore: deprecated_member_use
            groupValue: globalSettings.themeSetting,
            // ignore: deprecated_member_use
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

class _VisitFirstUnreadSetting extends StatelessWidget {
  const _VisitFirstUnreadSetting();

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    return ListTile(
      title: Text(zulipLocalizations.initialAnchorSettingTitle),
      subtitle: Text(VisitFirstUnreadSettingPage._valueDisplayName(
        globalSettings.visitFirstUnread, zulipLocalizations: zulipLocalizations)),
      onTap: () => Navigator.push(context,
        VisitFirstUnreadSettingPage.buildRoute()));
  }
}

class VisitFirstUnreadSettingPage extends StatelessWidget {
  const VisitFirstUnreadSettingPage({super.key});

  static WidgetRoute<void> buildRoute() {
    return MaterialWidgetRoute(page: const VisitFirstUnreadSettingPage());
  }

  static String _valueDisplayName(VisitFirstUnreadSetting value, {
    required ZulipLocalizations zulipLocalizations,
  }) {
    return switch (value) {
      VisitFirstUnreadSetting.always =>
        zulipLocalizations.initialAnchorSettingFirstUnreadAlways,
      VisitFirstUnreadSetting.conversations =>
        zulipLocalizations.initialAnchorSettingFirstUnreadConversations,
      VisitFirstUnreadSetting.never =>
        zulipLocalizations.initialAnchorSettingNewestAlways,
    };
  }

  void _handleChange(BuildContext context, VisitFirstUnreadSetting? value) {
    if (value == null) return; // TODO(log); can this actually happen? how?
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    globalSettings.setVisitFirstUnread(value);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(zulipLocalizations.initialAnchorSettingTitle)),
      body: Column(children: [
        ListTile(title: Text(zulipLocalizations.initialAnchorSettingDescription)),
        for (final value in VisitFirstUnreadSetting.values)
          RadioListTile.adaptive(
            title: Text(_valueDisplayName(value,
              zulipLocalizations: zulipLocalizations)),
            value: value,
            // TODO(#1545) stop using the deprecated members
            // ignore: deprecated_member_use
            groupValue: globalSettings.visitFirstUnread,
            // ignore: deprecated_member_use
            onChanged: (newValue) => _handleChange(context, newValue)),
      ]));
  }
}

class _MarkReadOnScrollSetting extends StatelessWidget {
  const _MarkReadOnScrollSetting();

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    return ListTile(
      title: Text(zulipLocalizations.markReadOnScrollSettingTitle),
      subtitle: Text(MarkReadOnScrollSettingPage._valueDisplayName(
        globalSettings.markReadOnScroll, zulipLocalizations: zulipLocalizations)),
      onTap: () => Navigator.push(context,
        MarkReadOnScrollSettingPage.buildRoute()));
  }
}

class MarkReadOnScrollSettingPage extends StatelessWidget {
  const MarkReadOnScrollSettingPage({super.key});

  static WidgetRoute<void> buildRoute() {
    return MaterialWidgetRoute(page: const MarkReadOnScrollSettingPage());
  }

  static String _valueDisplayName(MarkReadOnScrollSetting value, {
    required ZulipLocalizations zulipLocalizations,
  }) {
    return switch (value) {
      MarkReadOnScrollSetting.always =>
        zulipLocalizations.markReadOnScrollSettingAlways,
      MarkReadOnScrollSetting.conversations =>
        zulipLocalizations.markReadOnScrollSettingConversations,
      MarkReadOnScrollSetting.never =>
        zulipLocalizations.markReadOnScrollSettingNever,
    };
  }

  static String? _valueDescription(MarkReadOnScrollSetting value, {
    required ZulipLocalizations zulipLocalizations,
  }) {
    return switch (value) {
      MarkReadOnScrollSetting.always => null,
      MarkReadOnScrollSetting.conversations =>
        zulipLocalizations.markReadOnScrollSettingConversationsDescription,
      MarkReadOnScrollSetting.never => null,
    };
  }

  void _handleChange(BuildContext context, MarkReadOnScrollSetting? value) {
    if (value == null) return; // TODO(log); can this actually happen? how?
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    globalSettings.setMarkReadOnScroll(value);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(zulipLocalizations.markReadOnScrollSettingTitle)),
      body: Column(children: [
        ListTile(title: Text(zulipLocalizations.markReadOnScrollSettingDescription)),
        for (final value in MarkReadOnScrollSetting.values)
          RadioListTile.adaptive(
            title: Text(_valueDisplayName(value,
              zulipLocalizations: zulipLocalizations)),
            subtitle: () {
              final result = _valueDescription(value,
                zulipLocalizations: zulipLocalizations);
              return result == null ? null : Text(result);
            }(),
            value: value,
            // TODO(#1545) stop using the deprecated members
            // ignore: deprecated_member_use
            groupValue: globalSettings.markReadOnScroll,
            // ignore: deprecated_member_use
            onChanged: (newValue) => _handleChange(context, newValue)),
      ]));
  }
}

class _LanguageSetting extends StatelessWidget {
  const _LanguageSetting();

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);

    Widget? subtitle;
    final currentLanguageSelfname = kSelfnamesByLocale[
      GlobalStoreWidget.settingsOf(context).language];
    if (currentLanguageSelfname != null) {
      subtitle = Text(currentLanguageSelfname);
    }

    return ListTile(
      title: Text(zulipLocalizations.languageSettingTitle),
      subtitle: subtitle,
      onTap: () => Navigator.push(context, _LanguagePage.buildRoute()));
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
