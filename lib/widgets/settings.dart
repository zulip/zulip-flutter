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
        _SettingsHeader(title: ZulipLocalizations.of(context).themeSettingTitle),
        const _ThemeSetting(),
        _BrowserPreferenceSetting(),
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

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Material(
    color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16,8),
        child: Text(title,
          style: TextStyle(fontSize: 17).merge(weightVariableTextStyle(context, wght: 600)),
        )));
  }}

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
    return Material(
      color: Colors.transparent,
      child: ListTile(
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
          color: designVariables.contextMenuItemIcon),
      ));}
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
    final themeSetting = globalSettings.themeSetting;
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          for (final themeSettingOption in [ThemeSetting.dark, ThemeSetting.light, null])
            CustomRadioTile<ThemeSetting?>(
              value: themeSettingOption,
              groupValue: themeSetting,
              label: ThemeSetting.displayName(
                themeSetting: themeSettingOption,
                zulipLocalizations: zulipLocalizations),
              onChanged: (v) => _handleChange(context, v)),
        ]));
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
    final designVariables = DesignVariables.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    final openLinksWithInAppBrowser =
      globalSettings.effectiveBrowserPreference == BrowserPreference.inApp;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        title: Text(zulipLocalizations.openLinksWithInAppBrowser,
          style: TextStyle(
            color: designVariables.contextMenuItemText, fontSize: 20).merge(weightVariableTextStyle(context, wght: 600))),
        trailing: _CustomSwitch(
          value: openLinksWithInAppBrowser,
          onChanged: (newValue) => _handleChange(context, newValue))));
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
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(zulipLocalizations.initialAnchorSettingDescription,
            style: TextStyle(fontSize: 17).merge(weightVariableTextStyle(context, wght: 400)))),
        for (final value in VisitFirstUnreadSetting.values)
          CustomRadioTile(
            value: value,
            groupValue: globalSettings.visitFirstUnread,
            label: _valueDisplayName(value, zulipLocalizations: zulipLocalizations),
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
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(16.0),
          child: Text(zulipLocalizations.markReadOnScrollSettingDescription,
            style: TextStyle(fontSize: 17).merge(weightVariableTextStyle(context, wght: 400)))),
        for (final value in MarkReadOnScrollSetting.values)
          CustomRadioTile(
            value: value,
            groupValue: globalSettings.markReadOnScroll,
            label: _valueDisplayName(value, zulipLocalizations: zulipLocalizations),
            onChanged: (newValue) => _handleChange(context, newValue),
            description: _valueDescription(value, zulipLocalizations: zulipLocalizations))
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
    final designVariables = DesignVariables.of(context);
    assert(flags.isNotEmpty);
    return Scaffold(
      appBar: AppBar(
        title: Text(zulipLocalizations.experimentalFeatureSettingsPageTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(zulipLocalizations.experimentalFeatureSettingsWarning,
              style: TextStyle(fontSize: 17).merge(weightVariableTextStyle(context, wght: 400)))),
          for (final flag in flags)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [Expanded(
                    child: Text(flag.name,
                      style: TextStyle(fontSize: 20, color: designVariables.contextMenuItemText).merge(weightVariableTextStyle(context, wght: 600)))),
                  _CustomSwitch(
                    value: globalSettings.getBool(flag),
                    onChanged: (value) => globalSettings.setBool(flag, value)),
                ])),
        ]));
  }
}

class CustomRadioTile<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String label;
  final ValueChanged<T?> onChanged;
  final String? description;

  const CustomRadioTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final size = 20.0;
    final colr = const Color(0xff4370f0);

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(top: 4),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: selected ? colr : Colors.transparent,
                border: Border.all(color: selected ? colr : Colors.grey.shade400, width: 2),
                borderRadius: BorderRadius.circular(size / 2)),
              child: selected? const Icon(ZulipIcons.check, size: 16, color: Colors.white): null),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,style: TextStyle(fontSize: 18).merge(weightVariableTextStyle(context, wght: 500))),
                  if (description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(description!,
                        style: TextStyle(fontSize: 17).merge(weightVariableTextStyle(context, wght: 400)),),
                    )])),
          ])));
  }
}
class _CustomSwitch extends StatelessWidget {
  const _CustomSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => onChanged(!value),
      child: Toggle(value: value, onChanged: onChanged ));
  }
}


