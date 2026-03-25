import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../get/app_pages.dart';
import '../../../../model/settings.dart';
import '../../../utils/store.dart';

class ExperimentalFeaturesController extends GetxController {
  void navigateToPage() {
    Get.toNamed<dynamic>(AppRoutes.experimentalFeatures);
  }
}

class ExperimentalFeaturesPage extends StatelessWidget {
  const ExperimentalFeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    final flags = GlobalSettingsStore.experimentalFeatureFlags;
    assert(flags.isNotEmpty);
    return Scaffold(
      appBar: AppBar(
        title: Text(zulipLocalizations.experimentalFeatureSettingsPageTitle),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text(zulipLocalizations.experimentalFeatureSettingsWarning),
          ),
          for (final flag in flags)
            SwitchListTile.adaptive(
              title: Text(
                flag.name,
              ), // no i18n; these are developer-facing settings
              value: globalSettings.getBool(flag),
              onChanged: (value) => globalSettings.setBool(flag, value),
            ),
        ],
      ),
    );
  }
}
