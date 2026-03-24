import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../model/settings.dart';
import '../../../utils/page.dart';
import '../../../utils/store.dart';

class MarkReadOnScrollSettingWidget extends StatelessWidget {
  const MarkReadOnScrollSettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    return ListTile(
      title: Text(zulipLocalizations.markReadOnScrollSettingTitle),
      subtitle: Text(
        MarkReadOnScrollSettingPage._valueDisplayName(
          globalSettings.markReadOnScroll,
          zulipLocalizations: zulipLocalizations,
        ),
      ),
      onTap: () =>
          Navigator.push(context, MarkReadOnScrollSettingPage.buildRoute()),
    );
  }
}

class MarkReadOnScrollSettingPage extends StatelessWidget {
  const MarkReadOnScrollSettingPage({super.key});

  static WidgetRoute<void> buildRoute() {
    return MaterialWidgetRoute(page: const MarkReadOnScrollSettingPage());
  }

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
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    globalSettings.setMarkReadOnScroll(value);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(zulipLocalizations.markReadOnScrollSettingTitle),
      ),
      body: RadioGroup<MarkReadOnScrollSetting>(
        groupValue: globalSettings.markReadOnScroll,
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
