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
        _ThemeSetting(),
      ]));
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
