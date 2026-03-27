import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../get/app_pages.dart';
import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../get/services/global_service.dart';
import '../../../../model/settings.dart';

class VisitFirstUnreadSettingWidget extends StatelessWidget {
  const VisitFirstUnreadSettingWidget({super.key});

  void _navigateToPage() {
    Get.toNamed<dynamic>(AppRoutes.visitFirstUnreadSetting);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Obx(() {
      GlobalService.to.settingsChanged.value;
      final globalSettings = GlobalService.to.currentSettingsStore.value;
      return ListTile(
        title: Text(zulipLocalizations.initialAnchorSettingTitle),
        subtitle: Text(
          VisitFirstUnreadSettingPage._valueDisplayName(
            globalSettings?.visitFirstUnread ?? VisitFirstUnreadSetting.always,
            zulipLocalizations: zulipLocalizations,
          ),
        ),
        onTap: _navigateToPage,
      );
    });
  }
}

class VisitFirstUnreadSettingPage extends StatelessWidget {
  const VisitFirstUnreadSettingPage({super.key});

  static String _valueDisplayName(
    VisitFirstUnreadSetting value, {
    required ZulipLocalizations zulipLocalizations,
  }) {
    return switch (value) {
      VisitFirstUnreadSetting.always =>
        zulipLocalizations.initialAnchorSettingFirstUnreadAlways,
      VisitFirstUnreadSetting.conversations =>
        zulipLocalizations.initialAnchorSettingFirstUnreadConversations,
      VisitFirstUnreadSetting.never =>
        zulipLocalizations.initialAnchorSettingNewestAlways,
    };
  }

  void _handleChange(BuildContext context, VisitFirstUnreadSetting? value) {
    if (value == null) return;
    final globalSettings = GlobalService.to.currentSettingsStore.value;
    globalSettings?.setVisitFirstUnread(value);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Obx(() {
      GlobalService.to.settingsChanged.value;
      final globalSettings = GlobalService.to.currentSettingsStore.value;
      return Scaffold(
        appBar: AppBar(
          title: Text(zulipLocalizations.initialAnchorSettingTitle),
        ),
        body: RadioGroup<VisitFirstUnreadSetting>(
          groupValue:
              globalSettings?.visitFirstUnread ??
              VisitFirstUnreadSetting.always,
          onChanged: (newValue) => _handleChange(context, newValue),
          child: Column(
            children: [
              ListTile(
                title: Text(zulipLocalizations.initialAnchorSettingDescription),
              ),
              for (final value in VisitFirstUnreadSetting.values)
                RadioListTile<VisitFirstUnreadSetting>.adaptive(
                  title: Text(
                    _valueDisplayName(
                      value,
                      zulipLocalizations: zulipLocalizations,
                    ),
                  ),
                  value: value,
                ),
            ],
          ),
        ),
      );
    });
  }
}
