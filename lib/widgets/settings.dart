import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/settings.dart';
import 'app_bar.dart';
import 'button.dart';
import 'icons.dart';
import 'page.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';

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
      appBar: ZulipAppBar(title: Text(zulipLocalizations.settingsPageTitle),centerTitle: true),
      body: ListView(children: [
        const _ThemeSetting(),
        const _BrowserPreferenceSetting(),
        _SettingsNavitem(
          title: 'Notifications',
          onTap: () {
            // TODO: Implement notifications settings page
        }),
        _SettingsNavitem(
          title: 'Open message feeds at',
          subtitle: VisitFirstUnreadSettingPage._valueDisplayName(
            GlobalStoreWidget.settingsOf(context).visitFirstUnread,
            zulipLocalizations: zulipLocalizations),
          onTap: () => Navigator.push(context,
            VisitFirstUnreadSettingPage.buildRoute()),
        ),
        _SettingsNavitem(
          title: 'Mark messages as read on scroll',
          subtitle: MarkReadOnScrollSettingPage._valueDisplayName(
            GlobalStoreWidget.settingsOf(context).markReadOnScroll,
            zulipLocalizations: zulipLocalizations),
          onTap: () => Navigator.push(context,
            MarkReadOnScrollSettingPage.buildRoute()),
        ),
        if (GlobalSettingsStore.experimentalFeatureFlags.isNotEmpty)
           _SettingsNavitem(
            title: zulipLocalizations.experimentalFeatureSettingsPageTitle,
            onTap: () => Navigator.push(context,
              ExperimentalFeaturesPage.buildRoute()))
      ]));
  }
}

class _SettingsNavitem extends StatelessWidget {
  const _SettingsNavitem({
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    return ListTile(
      title:  Text(title,
        style: TextStyle(
          color: designVariables.contextMenuItemText,
          fontSize: 20).merge(weightVariableTextStyle(context, wght: 600))),
      subtitle: subtitle != null ? Text(
          subtitle!,
          style: TextStyle(fontSize: 17).merge(weightVariableTextStyle(context, wght: 400))) : null,
      onTap: onTap,
      trailing: Icon(
          ZulipIcons.chevron_right,
          color: designVariables.contextMenuItemIcon,),
    );}
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16,8),
          child: Text(zulipLocalizations.themeSettingTitle,
            style: TextStyle(fontSize: 17).merge(weightVariableTextStyle(context, wght: 600)),
          )),
        for (final themeSettingOption in [null, ...ThemeSetting.values])
          RadioTile<ThemeSetting?>(
            value: themeSettingOption,
            groupValue: globalSettings.themeSetting,
            title: ThemeSetting.displayName(
              themeSetting: themeSettingOption,
              zulipLocalizations: zulipLocalizations),
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
    final designVariables = DesignVariables.of(context);
    final openLinksWithInAppBrowser =
      globalSettings.effectiveBrowserPreference == BrowserPreference.inApp;
    return ListTile(
      title: Text(zulipLocalizations.openLinksWithInAppBrowser,
        style: TextStyle(
          color: designVariables.contextMenuItemText, fontSize: 20).merge(weightVariableTextStyle(context, wght: 600))),
      trailing: Toggle(
        value: openLinksWithInAppBrowser,
        onChanged: (newValue) => _handleChange(context, newValue)));
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.all(16.0),
            child: Text(zulipLocalizations.initialAnchorSettingDescription,
              style: TextStyle(fontSize: 17).merge(weightVariableTextStyle(context, wght: 400)))),
          for (final value in VisitFirstUnreadSetting.values)
            RadioTile(
              value: value,
              groupValue: globalSettings.visitFirstUnread,
              title: _valueDisplayName(value, zulipLocalizations: zulipLocalizations),
              onChanged:(newValue) => _handleChange(context, newValue))
        ]));
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.all(16.0),
            child: Text(zulipLocalizations.markReadOnScrollSettingDescription,
              style: TextStyle(fontSize: 17).merge(weightVariableTextStyle(context, wght: 400)))),
          for (final value in MarkReadOnScrollSetting.values)
            RadioTile(
              value: value,
              groupValue: globalSettings.markReadOnScroll,
              title: _valueDisplayName(value, zulipLocalizations: zulipLocalizations),
              onChanged: (newValue) => _handleChange(context, newValue),
              subtitle: _valueDescription(value, zulipLocalizations: zulipLocalizations))
        ]));
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


class RadioTile<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String title;
  final ValueChanged<T?> onChanged;
  final String? subtitle;

  const RadioTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.title,
    required this.onChanged,
    this.subtitle
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final designVariables = DesignVariables.of(context);

    return Semantics(
      label: subtitle == null ? title : '$title\n$subtitle',
      checked: isSelected,
      inMutuallyExclusiveGroup: true,
      onTap: () => onChanged(value),
      child: InkWell(
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              isSelected
              ? Icon(size: 24,
                  color: designVariables.radioFillSelected,
                  ZulipIcons.check_circle_checked)
              : Icon(size: 24,
                  color: designVariables.radioBorder,
                  ZulipIcons.check_circle_unchecked),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,style: TextStyle(fontSize: 18).merge(weightVariableTextStyle(context, wght: 500))),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!,
                          style: TextStyle(fontSize: 17).merge(weightVariableTextStyle(context, wght: 400)),),
                      )])),
            ]))),
    );
  }
}
