import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../get/services/global_service.dart';
import '../../../../model/settings.dart';

class BrowserPreferenceSetting extends StatelessWidget {
  const BrowserPreferenceSetting({super.key});

  void _handleChange(BuildContext context, bool newOpenLinksWithInAppBrowser) {
    final globalSettings = GlobalService.to.currentSettingsStore.value;
    globalSettings?.setBrowserPreference(
      newOpenLinksWithInAppBrowser
          ? BrowserPreference.inApp
          : BrowserPreference.external,
    );
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Obx(() {
      GlobalService.to.settingsChanged.value;
      final globalSettings = GlobalService.to.currentSettingsStore.value;
      final openLinksWithInAppBrowser =
          globalSettings?.effectiveBrowserPreference == BrowserPreference.inApp;
      return SwitchListTile.adaptive(
        title: Text(zulipLocalizations.openLinksWithInAppBrowser),
        value: openLinksWithInAppBrowser,
        onChanged: (newValue) => _handleChange(context, newValue),
      );
    });
  }
}
