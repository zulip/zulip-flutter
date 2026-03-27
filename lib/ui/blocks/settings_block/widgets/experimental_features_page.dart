import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../get/app_pages.dart';
import '../../../../get/services/global_service.dart';
import '../../../../model/settings.dart';

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
    return Obx(() {
      GlobalService.to.settingsChanged.value;
      final globalSettings = GlobalService.to.currentSettingsStore.value;
      final flags = GlobalSettingsStore.experimentalFeatureFlags;
      assert(flags.isNotEmpty);
      return Scaffold(
        appBar: AppBar(
          title: Text(zulipLocalizations.experimentalFeatureSettingsPageTitle),
        ),
        body: globalSettings == null
            ? const SizedBox.shrink()
            : Column(
                children: [
                  ListTile(
                    title: Text(
                      zulipLocalizations.experimentalFeatureSettingsWarning,
                    ),
                  ),
                  for (final flag in flags)
                    SwitchListTile.adaptive(
                      title: Text(flag.name),
                      value: globalSettings.getBool(flag),
                      onChanged: (value) {
                        globalSettings.setBool(flag, value);
                      },
                    ),
                ],
              ),
      );
    });
  }
}
