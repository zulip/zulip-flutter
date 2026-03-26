import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../get/app_pages.dart';
import '../../../../get/services/global_service.dart';
import '../../../../model/settings.dart';

class MarkReadOnScrollSettingController extends GetxController {
  void navigateToPage() {
    Get.toNamed<dynamic>(AppRoutes.markReadOnScrollSetting);
  }
}

class MarkReadOnScrollSettingWidget extends StatelessWidget {
  const MarkReadOnScrollSettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalService.to.settingsStore;
    final controller = MarkReadOnScrollSettingController();
    return ListTile(
      title: Text(zulipLocalizations.markReadOnScrollSettingTitle),
      subtitle: Text(
        MarkReadOnScrollSettingPage._valueDisplayName(
          globalSettings?.markReadOnScroll ?? MarkReadOnScrollSetting.always,
          zulipLocalizations: zulipLocalizations,
        ),
      ),
      onTap: () => controller.navigateToPage(),
    );
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
    if (value == null) return; // TODO(log); can this actually happen? how?
    final globalSettings = GlobalService.to.settingsStore;
    globalSettings?.setMarkReadOnScroll(value);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalService.to.settingsStore;
    return Scaffold(
      appBar: AppBar(
        title: Text(zulipLocalizations.markReadOnScrollSettingTitle),
      ),
      body: RadioGroup<MarkReadOnScrollSetting>(
        groupValue:
            globalSettings?.markReadOnScroll ?? MarkReadOnScrollSetting.always,
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
  }
}
