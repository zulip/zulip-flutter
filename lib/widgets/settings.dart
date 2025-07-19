import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/settings.dart';
import 'app_bar.dart';
import 'page.dart';
import 'store.dart';

/// A custom toggle widget that matches Figma specifications exactly.
///
/// This widget provides precise control over dimensions and styling
/// to match the design requirements that Flutter's built-in Switch
/// widget cannot currently accommodate.
class FigmaToggle extends StatelessWidget {
  const FigmaToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.activeThumbColor,
    this.inactiveThumbColor,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? activeThumbColor;
  final Color? inactiveThumbColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Exact Figma-specified dimensions
    final trackWidth = value ? 48.0 : 46.0;
    final trackHeight = value ? 28.0 : 26.0;
    final thumbRadius = value ? 10.0 : 7.0;

    // Colors with fallbacks to theme defaults
    final effectiveActiveColor = activeColor ?? colorScheme.primary;
    final effectiveInactiveColor = inactiveColor ?? colorScheme.outline;
    final effectiveActiveThumbColor = activeThumbColor ?? colorScheme.onPrimary;
    final effectiveInactiveThumbColor = inactiveThumbColor ?? colorScheme.outline;

    final trackColor = value ? effectiveActiveColor : effectiveInactiveColor;
    final thumbColor = value ? effectiveActiveThumbColor : effectiveInactiveThumbColor;

    // Calculate thumb positioning with proper padding
    final thumbDiameter = thumbRadius * 2;
    final horizontalPadding = 4.0;
    final thumbLeftPosition = value
        ? trackWidth - thumbDiameter - horizontalPadding
        : horizontalPadding;

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: trackWidth,
        height: trackHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(trackHeight / 2),
          color: trackColor,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: thumbLeftPosition,
              top: (trackHeight - thumbDiameter) / 2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: thumbDiameter,
                height: thumbDiameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: thumbColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: value
                  ? Icon(
                      Icons.check,
                      size: thumbRadius * 1.2,
                      color: effectiveActiveColor,
                    )
                  : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      appBar: ZulipAppBar(
        title: Text(zulipLocalizations.settingsPageTitle),
      ),
      body: Column(
        children: [
          const _ThemeSetting(),
          const _BrowserPreferenceSetting(),
          const _VisitFirstUnreadSetting(),
          const _MarkReadOnScrollSetting(),
          if (GlobalSettingsStore.experimentalFeatureFlags.isNotEmpty)
            ListTile(
              title: Text(zulipLocalizations.experimentalFeatureSettingsPageTitle),
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

class _ThemeSetting extends StatefulWidget {
  const _ThemeSetting();

  @override
  State<_ThemeSetting> createState() => _ThemeSettingState();
}

class _ThemeSettingState extends State<_ThemeSetting> {
  void _handleChange(BuildContext context, ThemeSetting? newThemeSetting) {
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    globalSettings.setThemeSetting(newThemeSetting);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    return Column(
      children: [
        ListTile(title: Text(zulipLocalizations.themeSettingTitle)),
        RadioGroup<ThemeSetting?>(
          groupValue: globalSettings.themeSetting,
          onChanged: (newValue) => _handleChange(context, newValue),
          child: Column(
            children: [
              for (final themeSettingOption in [null, ...ThemeSetting.values])
                RadioListTile<ThemeSetting?>(
                  title: Text(ThemeSetting.displayName(
                    themeSetting: themeSettingOption,
                    zulipLocalizations: zulipLocalizations,
                  )),
                  value: themeSettingOption,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrowserPreferenceSetting extends StatelessWidget {
  const _BrowserPreferenceSetting();

  void _handleChange(BuildContext context, bool newOpenLinksWithInAppBrowser) {
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    globalSettings.setBrowserPreference(
      newOpenLinksWithInAppBrowser ? BrowserPreference.inApp
                                   : BrowserPreference.external,
    );
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    final openLinksWithInAppBrowser =
      globalSettings.effectiveBrowserPreference == BrowserPreference.inApp;
    return ListTile(
      title: Text(zulipLocalizations.openLinksWithInAppBrowser),
      trailing: FigmaToggle(
        value: openLinksWithInAppBrowser,
        onChanged: (newValue) => _handleChange(context, newValue),
      ),
    );
  }
}

class _VisitFirstUnreadSetting extends StatelessWidget {
  const _VisitFirstUnreadSetting();

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    return ListTile(
      title: Text(zulipLocalizations.initialAnchorSettingTitle),
      subtitle: Text(VisitFirstUnreadSettingPage._valueDisplayName(
        globalSettings.visitFirstUnread,
        zulipLocalizations: zulipLocalizations,
      )),
      onTap: () => Navigator.push(
        context,
        VisitFirstUnreadSettingPage.buildRoute(),
      ),
    );
  }
}

class VisitFirstUnreadSettingPage extends StatelessWidget {
  const VisitFirstUnreadSettingPage({super.key});

  static WidgetRoute<void> buildRoute() {
    return MaterialWidgetRoute(page: const VisitFirstUnreadSettingPage());
  }

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
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    globalSettings.setVisitFirstUnread(value);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(zulipLocalizations.initialAnchorSettingTitle)),
      body: Column(
        children: [
          ListTile(title: Text(zulipLocalizations.initialAnchorSettingDescription)),
          RadioGroup<VisitFirstUnreadSetting>(
            groupValue: globalSettings.visitFirstUnread,
            onChanged: (newValue) => _handleChange(context, newValue),
            child: Column(
              children: [
                for (final value in VisitFirstUnreadSetting.values)
                  RadioListTile.adaptive(
                    title: Text(_valueDisplayName(
                      value,
                      zulipLocalizations: zulipLocalizations,
                    )),
                    value: value,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkReadOnScrollSetting extends StatelessWidget {
  const _MarkReadOnScrollSetting();

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    return ListTile(
      title: Text(zulipLocalizations.markReadOnScrollSettingTitle),
      subtitle: Text(MarkReadOnScrollSettingPage._valueDisplayName(
        globalSettings.markReadOnScroll,
        zulipLocalizations: zulipLocalizations,
      )),
      onTap: () => Navigator.push(
        context,
        MarkReadOnScrollSettingPage.buildRoute(),
      ),
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
    if (value == null) return;
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    globalSettings.setMarkReadOnScroll(value);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(zulipLocalizations.markReadOnScrollSettingTitle)),
      body: Column(
        children: [
          ListTile(title: Text(zulipLocalizations.markReadOnScrollSettingDescription)),
          RadioGroup<MarkReadOnScrollSetting>(
            groupValue: globalSettings.markReadOnScroll,
            onChanged: (newValue) => _handleChange(context, newValue),
            child: Column(
              children: [
                for (final value in MarkReadOnScrollSetting.values)
                  RadioListTile.adaptive(
                    title: Text(_valueDisplayName(
                      value,
                      zulipLocalizations: zulipLocalizations,
                    )),
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
        ],
      ),
    );
  }
}

class ExperimentalFeaturesPage extends StatelessWidget {
  const ExperimentalFeaturesPage({super.key});

  static WidgetRoute<void> buildRoute() {
    return MaterialWidgetRoute(page: const ExperimentalFeaturesPage());
  }

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
            ListTile(
              title: Text(flag.name), // no i18n; these are developer-facing settings
              trailing: FigmaToggle(
                value: globalSettings.getBool(flag),
                onChanged: (value) => globalSettings.setBool(flag, value),
              ),
            ),
        ],
      ),
    );
  }
}