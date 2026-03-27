import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../get/app_pages.dart';
import '../../../../get/services/global_service.dart';
import '../../../../model/settings.dart';

class MarkReadOnScrollSettingWidget extends StatelessWidget {
  const MarkReadOnScrollSettingWidget({super.key});

  void _navigateToPage() {
    Get.toNamed<dynamic>(AppRoutes.markReadOnScrollSetting);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Obx(() {
      GlobalService.to.settingsChanged.value;
      final globalSettings = GlobalService.to.currentSettingsStore.value;
      return ListTile(
        title: Text(zulipLocalizations.markReadOnScrollSettingTitle),
        subtitle: Text(
          MarkReadOnScrollSettingPage._valueDisplayName(
            globalSettings?.markReadOnScroll ?? MarkReadOnScrollSetting.always,
            zulipLocalizations: zulipLocalizations,
          ),
        ),
        onTap: _navigateToPage,
      );
    });
  }
}

class MarkReadOnScrollSettingPage extends StatelessWidget {
  const MarkReadOnScrollSettingPage({super.key});

  static String _valueDisplayName(
    MarkReadOnScrollSetting value, {
    required ZulipLocalizations zulipLocalizations,
  }) {
    return switch (value) {
      MarkReadOnScrollSetting.always =>
        zulipLocalizations.markReadOnScrollSettingAlways,
      MarkReadOnScrollSetting.conversations =>
        zulipLocalizations.markReadOnScrollSettingConversations,
      MarkReadOnScrollSetting.never =>
        zulipLocalizations.markReadOnScrollSettingNever,
    };
  }

  static String? _valueDescription(
    MarkReadOnScrollSetting value, {
    required ZulipLocalizations zulipLocalizations,
  }) {
    return switch (value) {
      MarkReadOnScrollSetting.always => null,
      MarkReadOnScrollSetting.conversations =>
        zulipLocalizations.markReadOnScrollSettingConversationsDescription,
      MarkReadOnScrollSetting.never => null,
    };
  }

  void _handleChange(BuildContext context, MarkReadOnScrollSetting? value) {
    if (value == null) return;
    final globalSettings = GlobalService.to.currentSettingsStore.value;
    globalSettings?.setMarkReadOnScroll(value);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Obx(() {
      GlobalService.to.settingsChanged.value;
      final globalSettings = GlobalService.to.currentSettingsStore.value;
      return Scaffold(
        appBar: AppBar(
          title: Text(zulipLocalizations.markReadOnScrollSettingTitle),
        ),
        body: RadioGroup<MarkReadOnScrollSetting>(
          groupValue:
              globalSettings?.markReadOnScroll ??
              MarkReadOnScrollSetting.always,
          onChanged: (newValue) => _handleChange(context, newValue),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  zulipLocalizations.markReadOnScrollSettingDescription,
                ),
              ),
              for (final value in MarkReadOnScrollSetting.values)
                RadioListTile<MarkReadOnScrollSetting>.adaptive(
                  title: Text(
                    _valueDisplayName(
                      value,
                      zulipLocalizations: zulipLocalizations,
                    ),
                  ),
                  subtitle: () {
                    final result = _valueDescription(
                      value,
                      zulipLocalizations: zulipLocalizations,
                    );
                    return result == null ? null : Text(result);
                  }(),
                  value: value,
                ),
            ],
          ),
        ),
      );
    });
  }
}
