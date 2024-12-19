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
        const _ThemeSetting(),
      ]));
  }
}

class _ThemeSetting extends StatelessWidget {
  const _ThemeSetting();

  void _handleChange(BuildContext context, ThemeSetting? newThemeSetting) {
    GlobalStoreWidget.of(context).updateGlobalSettings(
      GlobalSettingsCompanion(themeSetting: Value(newThemeSetting)));
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalStore = GlobalStoreWidget.of(context);
    return Column(
      children: [
        ListTile(title: Text(zulipLocalizations.themeSettingTitle)),
        for (final themeSettingOption in [null, ...ThemeSetting.values])
          RadioListTile<ThemeSetting?>.adaptive(
            title: Text(ThemeSetting.displayName(
              themeSetting: themeSettingOption,
              zulipLocalizations: zulipLocalizations)),
            value: themeSettingOption,
            groupValue: globalStore.globalSettings.themeSetting,
            onChanged: (newValue) => _handleChange(context, newValue)),
      ]);
  }
}
