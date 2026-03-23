import 'package:flutter/material.dart';

import '../../../generated/l10n/zulip_localizations.dart';
import '../../../model/settings.dart';
import '../../widgets/app_bar.dart';
import '../../utils/page.dart';
import 'widgets/browser_preference_setting.dart';
import 'widgets/experimental_features_page.dart';
import 'widgets/mark_read_on_scroll_setting.dart';
import 'widgets/theme_settings.dart';
import 'widgets/visit_first_unread_setting.dart';

// Нуууу, это настройки. А ты чего ждал?
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static AccountRoute<void> buildRoute({required BuildContext context}) {
    return MaterialAccountWidgetRoute(
      context: context,
      page: const SettingsPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Scaffold(
      appBar: ZulipAppBar(title: Text(zulipLocalizations.settingsPageTitle)),
      body: ListView(
        children: [
          const ThemeSettingWidget(),
          const BrowserPreferenceSetting(),
          const VisitFirstUnreadSettingWidget(),
          const MarkReadOnScrollSettingWidget(),
          if (GlobalSettingsStore.experimentalFeatureFlags.isNotEmpty)
            ListTile(
              title: Text(
                zulipLocalizations.experimentalFeatureSettingsPageTitle,
              ),
              onTap: () => Navigator.push(
                context,
                ExperimentalFeaturesPage.buildRoute(),
              ),
            ),
        ],
      ),
    );
  }
}
