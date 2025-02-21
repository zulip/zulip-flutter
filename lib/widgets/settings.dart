import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/database.dart';
import '../model/settings.dart';
import 'app_bar.dart';
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
      body: Column(children: [
        _BrowserPreferenceSetting(),
        _ThemeSetting(),
      ]));
  }
}

class _BrowserPreferenceSetting extends StatefulWidget {
  const _BrowserPreferenceSetting();

  @override
  State<_BrowserPreferenceSetting> createState() => _BrowserPreferenceSettingState();
}

class _BrowserPreferenceSettingState extends State<_BrowserPreferenceSetting> {
  late bool useExternalBrowser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    useExternalBrowser =
      GlobalStoreWidget.of(context).globalSettings.effectiveBrowserPreference
      == BrowserPreference.external;
  }

  void _handleChange(bool useExternalBrowser) {
    GlobalStoreWidget.of(context).updateGlobalSettings(
      GlobalSettingsCompanion(browserPreference: Value(
        useExternalBrowser ? BrowserPreference.external
                           : BrowserPreference.embedded)));
    setState(() {
      this.useExternalBrowser = useExternalBrowser;
    });
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return SwitchListTile.adaptive(
      title: Text(zulipLocalizations.settingsUseExternalBrowser),
      value: useExternalBrowser,
      onChanged: _handleChange);
  }
}

class _ThemeSetting extends StatefulWidget {
  const _ThemeSetting();

  @override
  State<_ThemeSetting> createState() => _ThemeSettingState();
}

class _ThemeSettingState extends State<_ThemeSetting> {
  late ThemeSetting value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    value = GlobalStoreWidget.of(context).globalSettings.themeSetting;
  }

  void _handleChange(ThemeSetting? newValue) {
    GlobalStoreWidget.of(context).updateGlobalSettings(
      GlobalSettingsCompanion(themeSetting: Value(newValue!)));
    setState(() {
      value = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Column(
      children: [
        ListTile(title: Text(zulipLocalizations.themeSettingTitle)),
        for (final themeSettingOption in ThemeSetting.values)
          RadioListTile<ThemeSetting>(
            title: Text(themeSettingOption.displayName(zulipLocalizations)),
            value: themeSettingOption,
            groupValue: value,
            onChanged: _handleChange),
      ]);
  }
}
