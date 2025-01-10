import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/database.dart';
import '../model/settings.dart';
import 'page.dart';
import 'store.dart';
import 'text.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static Route<void> buildRoute() {
    return MaterialWidgetRoute(page: const SettingsPage());
  }

  @override
  Widget build(BuildContext context) {
    final globalStore = GlobalStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final themeData = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(zulipLocalizations.settingsPageTitle)),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: SafeArea(
            minimum: const EdgeInsets.only(bottom: 8),
            child: Column(children: [
              ListTileTheme(
                data: const ListTileThemeData(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  dense: true,
                  minVerticalPadding: 0,
                  minTileHeight: 38,

                  horizontalTitleGap: 0,
                  minLeadingWidth: 38,
                ),
                child: SwitchListTile(
                  title: Text(zulipLocalizations.settingsUseExternal,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 26 / 17,
                    ),
                  ),
                  value: globalStore.globalSettings.effectiveBrowserPreference == BrowserPreference.external,
                  onChanged: (useExternal) {
                    globalStore.updateGlobalSettings(GlobalSettingsCompanion(
                      browserPreference: Value(
                        useExternal ? BrowserPreference.external
                                    : BrowserPreference.embedded)));
                  }),
              ),
              Theme(
                data: themeData.copyWith(splashColor: Colors.transparent),
                child: _ThemeSetting(initialValue: globalStore.globalSettings.themeSetting)),
            ])))));
  }
}

class _ThemeSetting extends StatefulWidget {
  const _ThemeSetting({required this.initialValue});

  final ThemeSetting initialValue;

  @override
  State<_ThemeSetting> createState() => _ThemeSettingState();
}

class _ThemeSettingState extends State<_ThemeSetting> {
  late ThemeSetting currentThemeSetting = widget.initialValue;
  static const entryHeight = 38.0;

  @override
  Widget build(BuildContext context) {
    final globalStore = GlobalStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final themeSettingOptions = [
      ThemeSetting.dark,
      ThemeSetting.light,
      ThemeSetting.unset,
    ];
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    return ListTileTheme(
      data: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 8),
        dense: true,
        minVerticalPadding: 0,
        minTileHeight: 38,

        horizontalTitleGap: 0,
        minLeadingWidth: 38,
      ),
      child: Column(
        children: [
          Container(
            height: entryHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.bottomLeft,
            child: Text(zulipLocalizations.themeSettingLabel,
              style: const TextStyle(
                fontSize: 18,
                height: 19 / 18,
              ).merge(weightVariableTextStyle(context, wght: 600)))),
          for (final themeSettingOption in themeSettingOptions)
            RadioListTile(
              title: Text(themeSettingOption.displayName(zulipLocalizations),
                style: const TextStyle(
                  fontSize: 19,
                  height: 26 / 19)),
              groupValue: currentThemeSetting,
              value: themeSettingOption,
              // This hides the circular overlay over the Radio, and leaves
              // the overlay over the ListTile unaffected.
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              onChanged: (newValue) {
                setState(() {
                  currentThemeSetting = newValue!;
                });
                unawaited(globalStore.updateGlobalSettings(GlobalSettingsCompanion(
                  themeSetting: Value(currentThemeSetting))));
              }),
        ]));
  }
}
