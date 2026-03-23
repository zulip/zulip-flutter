import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../model/settings.dart';
import '../../../utils/store.dart';

class ThemeSettingWidget extends StatelessWidget {
  const ThemeSettingWidget({super.key});

  void _handleChange(BuildContext context, ThemeSetting? newThemeSetting) {
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    globalSettings.setThemeSetting(newThemeSetting);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    return RadioGroup<ThemeSetting?>(
      groupValue: globalSettings.themeSetting,
      onChanged: (newValue) => _handleChange(context, newValue),
      child: Column(
        children: [
          ListTile(title: Text(zulipLocalizations.themeSettingTitle)),
          for (final themeSettingOption in [null, ...ThemeSetting.values])
            RadioListTile<ThemeSetting?>.adaptive(
              title: Text(
                ThemeSetting.displayName(
                  themeSetting: themeSettingOption,
                  zulipLocalizations: zulipLocalizations,
                ),
              ),
              value: themeSettingOption,
            ),
        ],
      ),
    );
  }
}
