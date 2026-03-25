import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../get/app_pages.dart';
import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../model/settings.dart';
import '../../../utils/store.dart';

class VisitFirstUnreadSettingController extends GetxController {
  void navigateToPage() {
    Get.toNamed<dynamic>(AppRoutes.visitFirstUnreadSetting);
  }
}

class VisitFirstUnreadSettingWidget extends StatelessWidget {
  const VisitFirstUnreadSettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    final controller = VisitFirstUnreadSettingController();
    return ListTile(
      title: Text(zulipLocalizations.initialAnchorSettingTitle),
      subtitle: Text(
        VisitFirstUnreadSettingPage._valueDisplayName(
          globalSettings.visitFirstUnread,
          zulipLocalizations: zulipLocalizations,
        ),
      ),
      onTap: () => controller.navigateToPage(),
    );
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
    if (value == null) return; // TODO(log); can this actually happen? how?
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    globalSettings.setVisitFirstUnread(value);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(zulipLocalizations.initialAnchorSettingTitle)),
      body: RadioGroup<VisitFirstUnreadSetting>(
        groupValue: globalSettings.visitFirstUnread,
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
  }
}
