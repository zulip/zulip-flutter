import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/database.dart';
import '../model/settings.dart';
import 'page.dart';
import 'store.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static Route<void> buildRoute() {
    return MaterialWidgetRoute(page: const SettingsPage());
  }

  @override
  Widget build(BuildContext context) {
    final globalStore = GlobalStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(zulipLocalizations.settingsPageTitle)),
      body: Column(children: [
        _Select(initialValue: globalStore.globalSettings.themeSetting),
      ]));
  }
}

class _Select extends StatefulWidget {
  const _Select({required this.initialValue});

  final ThemeSetting initialValue;

  @override
  State<_Select> createState() => _SelectState();
}

class _SelectState extends State<_Select> {
  late ThemeSetting value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final globalStore = GlobalStoreWidget.of(context);
    return Column(
      children: [
        const ListTile(title: Text('Theme')),
        for (final option in ThemeSetting.values)
          ListTile(
            title: Text(option.name),
            leading: Radio.adaptive(
              value: option,
              groupValue: value,
              onChanged: (newValue) {
                setState(() {
                  value = newValue!;
                });
                globalStore.updateGlobalSettings(GlobalSettingsCompanion(
                  themeSetting: Value(value)));
              })),
      ]);
  }
}
