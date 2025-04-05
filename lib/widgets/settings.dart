// import 'package:flutter/material.dart';

// import '../generated/l10n/zulip_localizations.dart';
// import '../model/settings.dart';
// import 'app_bar.dart';
// import 'page.dart';
// import 'store.dart';

// class SettingsPage extends StatelessWidget {
//   const SettingsPage({super.key});

//   static AccountRoute<void> buildRoute({required BuildContext context}) {
//     return MaterialAccountWidgetRoute(
//       context: context, page: const SettingsPage());
//   }

//   @override
//   Widget build(BuildContext context) {
//     final zulipLocalizations = ZulipLocalizations.of(context);
//     final colorScheme = Theme.of(context).colorScheme;
    
//     return Scaffold(
//       backgroundColor: colorScheme.background.withOpacity(0.95),
//       appBar: ZulipAppBar(
//         centerTitle: true,
//         title: Text(
//           zulipLocalizations.settingsPageTitle,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             letterSpacing: 0.5,
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 8),
//               Text(
//                 'Personalize Your Experience',
//                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.w600,
//                   color: colorScheme.primary,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Customize how Zulip works for you',
//                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                   color: colorScheme.onSurface.withOpacity(0.7),
//                 ),
//               ),
//               const SizedBox(height: 24),
              
//               _buildSettingsSection(
//                 context: context,
//                 icon: Icons.palette_outlined,
//                 title: 'Appearance',
//                 child: const _ThemeSetting(),
//               ),
              
//               const SizedBox(height: 16),
              
//               _buildSettingsSection(
//                 context: context,
//                 icon: Icons.open_in_browser,
//                 title: 'Browser Preferences',
//                 child: const _BrowserPreferenceSetting(),
//               ),
              
//               if (GlobalSettingsStore.experimentalFeatureFlags.isNotEmpty) 
//                 Padding(
//                   padding: const EdgeInsets.only(top: 16.0),
//                   child: _buildSettingsSection(
//                     context: context,
//                     icon: Icons.science_outlined,
//                     title: 'Experimental Features',
//                     onTap: () => Navigator.push(context,
//                       ExperimentalFeaturesPage.buildRoute()),
//                     showArrow: true,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
  
//   Widget _buildSettingsSection({
//     required BuildContext context, 
//     required IconData icon, 
//     required String title, 
//     Widget? child,
//     VoidCallback? onTap,
//     bool showArrow = false,
//   }) {
//     final colorScheme = Theme.of(context).colorScheme;
    
//     return Container(
//       decoration: BoxDecoration(
//         color: colorScheme.surface,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: colorScheme.shadow.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: Material(
//         color: Colors.transparent,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (onTap != null)
//               InkWell(
//                 onTap: onTap,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: colorScheme.primaryContainer.withOpacity(0.7),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Icon(
//                           icon,
//                           color: colorScheme.primary,
//                           size: 20,
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Text(
//                           title,
//                           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                       if (showArrow)
//                         Icon(
//                           Icons.chevron_right,
//                           color: colorScheme.onSurface.withOpacity(0.5),
//                         ),
//                     ],
//                   ),
//                 ),
//               )
//             else
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: colorScheme.primaryContainer.withOpacity(0.7),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(
//                         icon,
//                         color: colorScheme.primary,
//                         size: 20,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Text(
//                         title,
//                         style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             if (child != null) child,
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ThemeSetting extends StatelessWidget {
//   const _ThemeSetting();

//   void _handleChange(BuildContext context, ThemeSetting? newThemeSetting) {
//     final globalSettings = GlobalStoreWidget.settingsOf(context);
//     globalSettings.setThemeSetting(newThemeSetting);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final zulipLocalizations = ZulipLocalizations.of(context);
//     final globalSettings = GlobalStoreWidget.settingsOf(context);
//     final colorScheme = Theme.of(context).colorScheme;
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Divider(height: 1),
//         const SizedBox(height: 8),
//         for (final themeSettingOption in [null, ...ThemeSetting.values])
//           Theme(
//             data: Theme.of(context).copyWith(
//               // Create custom radio button colors
//               radioTheme: RadioThemeData(
//                 fillColor: MaterialStateProperty.resolveWith<Color>((states) {
//                   if (states.contains(MaterialState.selected)) {
//                     return colorScheme.primary;
//                   }
//                   return colorScheme.onSurface.withOpacity(0.5);
//                 }),
//               ),
//             ),
//             child: RadioListTile<ThemeSetting?>.adaptive(
//               title: Text(ThemeSetting.displayName(
//                 themeSetting: themeSettingOption,
//                 zulipLocalizations: zulipLocalizations),
//                 style: TextStyle(
//                   fontWeight: globalSettings.themeSetting == themeSettingOption 
//                     ? FontWeight.w500 
//                     : FontWeight.normal,
//                 ),
//               ),
//               secondary: _buildThemeIcon(context, themeSettingOption),
//               value: themeSettingOption,
//               groupValue: globalSettings.themeSetting,
//               onChanged: (newValue) => _handleChange(context, newValue),
//               activeColor: colorScheme.primary,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16),
//             ),
//           ),
//         const SizedBox(height: 8),
//       ],
//     );
//   }
  
//   Widget _buildThemeIcon(BuildContext context, ThemeSetting? themeSetting) {
//     final colorScheme = Theme.of(context).colorScheme;
    
//     IconData icon;
//     Color containerColor;
//     Color iconColor;
    
//     switch (themeSetting) {
//       case ThemeSetting.light:
//         icon = Icons.light_mode;
//         containerColor = Colors.amber.withOpacity(0.2);
//         iconColor = Colors.amber.shade700;
//         break;
//       case ThemeSetting.dark:
//         icon = Icons.dark_mode;
//         containerColor = Colors.indigo.withOpacity(0.2);
//         iconColor = Colors.indigo;
//         break;
//       default: // system or null
//         icon = Icons.settings_suggest;
//         containerColor = colorScheme.surfaceVariant.withOpacity(0.5);
//         iconColor = colorScheme.onSurfaceVariant;
//         break;
//     }
    
//     return Container(
//       width: 36,
//       height: 36,
//       decoration: BoxDecoration(
//         color: containerColor,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Icon(
//         icon,
//         color: iconColor,
//         size: 20,
//       ),
//     );
//   }
// }

// class _BrowserPreferenceSetting extends StatelessWidget {
//   const _BrowserPreferenceSetting();

//   void _handleChange(BuildContext context, bool newOpenLinksWithInAppBrowser) {
//     final globalSettings = GlobalStoreWidget.settingsOf(context);
//     globalSettings.setBrowserPreference(
//       newOpenLinksWithInAppBrowser ? BrowserPreference.inApp
//                                    : BrowserPreference.external);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final zulipLocalizations = ZulipLocalizations.of(context);
//     final globalSettings = GlobalStoreWidget.settingsOf(context);
//     final colorScheme = Theme.of(context).colorScheme;
//     final openLinksWithInAppBrowser =
//       globalSettings.effectiveBrowserPreference == BrowserPreference.inApp;
      
//     return Column(
//       children: [
//         const Divider(height: 1),
//         SwitchListTile.adaptive(
//           title: Text(
//             zulipLocalizations.openLinksWithInAppBrowser,
//             style: TextStyle(
//               fontWeight: FontWeight.w400,
//             ),
//           ),
//           subtitle: Text(
//             openLinksWithInAppBrowser 
//               ? 'Open links within the app'
//               : 'Open links in your default browser',
//             style: TextStyle(
//               fontSize: 12,
//               color: colorScheme.onSurface.withOpacity(0.6),
//             ),
//           ),
//           secondary: Container(
//             width: 36,
//             height: 36,
//             decoration: BoxDecoration(
//               color: openLinksWithInAppBrowser 
//                 ? colorScheme.primaryContainer.withOpacity(0.7) 
//                 : colorScheme.surfaceVariant.withOpacity(0.5),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               openLinksWithInAppBrowser ? Icons.open_in_new : Icons.launch,
//               size: 20,
//               color: openLinksWithInAppBrowser 
//                 ? colorScheme.primary
//                 : colorScheme.onSurfaceVariant,
//             ),
//           ),
//           value: openLinksWithInAppBrowser,
//           onChanged: (newValue) => _handleChange(context, newValue),
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         ),
//       ],
//     );
//   }
// }

// class ExperimentalFeaturesPage extends StatelessWidget {
//   const ExperimentalFeaturesPage({super.key});

//   static WidgetRoute<void> buildRoute() {
//     return MaterialWidgetRoute(page: const ExperimentalFeaturesPage());
//   }

//   @override
//   Widget build(BuildContext context) {
//     final zulipLocalizations = ZulipLocalizations.of(context);
//     final globalSettings = GlobalStoreWidget.settingsOf(context);
//     final flags = GlobalSettingsStore.experimentalFeatureFlags;
//     final colorScheme = Theme.of(context).colorScheme;
    
//     assert(flags.isNotEmpty);
    
//     return Scaffold(
//       backgroundColor: colorScheme.background.withOpacity(0.95),
//       appBar: AppBar(
//         centerTitle: true,
//         backgroundColor: colorScheme.surface,
//         title: Text(
//           zulipLocalizations.experimentalFeatureSettingsPageTitle,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             letterSpacing: 0.5,
//           ),
//         ),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.amber.withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: Colors.amber.withOpacity(0.5),
//                     width: 1,
//                   ),
//                 ),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Icon(
//                       Icons.warning_amber_rounded,
//                       color: Colors.amber.shade800,
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         zulipLocalizations.experimentalFeatureSettingsWarning,
//                         style: TextStyle(
//                           color: Colors.amber.shade800,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//               const SizedBox(height: 24),
              
//               Text(
//                 'Available Features',
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                   fontWeight: FontWeight.w600,
//                   color: colorScheme.primary,
//                 ),
//               ),
              
//               const SizedBox(height: 16),
              
//               Container(
//                 decoration: BoxDecoration(
//                   color: colorScheme.surface,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: colorScheme.shadow.withOpacity(0.1),
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 clipBehavior: Clip.antiAlias,
//                 child: Column(
//                   children: [
//                     for (int i = 0; i < flags.length; i++) ...[
//                       _buildExperimentalFeatureItem(
//                         context: context,
//                         flag: flags[i],
//                         globalSettings: globalSettings,
//                         isLast: i == flags.length - 1,
//                       ),
//                       if (i < flags.length - 1)
//                         const Divider(height: 1, indent: 16, endIndent: 16),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
  
//   Widget _buildExperimentalFeatureItem({
//     required BuildContext context,
//     required dynamic flag,
//     required dynamic globalSettings,
//     bool isLast = false,
//   }) {
//     final colorScheme = Theme.of(context).colorScheme;
//     final isEnabled = globalSettings.getBool(flag);
    
//     return SwitchListTile.adaptive(
//       title: Text(
//         flag.name,
//         style: TextStyle(
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       subtitle: Text(
//         'Experimental feature', // Generic description since these are developer-facing
//         style: TextStyle(
//           fontSize: 12,
//           color: colorScheme.onSurface.withOpacity(0.6),
//         ),
//       ),
//       secondary: Container(
//         width: 36,
//         height: 36,
//         decoration: BoxDecoration(
//           color: isEnabled 
//             ? colorScheme.primaryContainer.withOpacity(0.7) 
//             : colorScheme.surfaceVariant.withOpacity(0.5),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Icon(
//           Icons.science_outlined,
//           size: 20,
//           color: isEnabled 
//             ? colorScheme.primary
//             : colorScheme.onSurfaceVariant,
//         ),
//       ),
//       value: isEnabled,
//       onChanged: (value) => globalSettings.setBool(flag, value),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//     );
//   }
// }
import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/settings.dart';
import 'app_bar.dart';
import 'page.dart';
import 'store.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static AccountRoute<void> buildRoute({required BuildContext context}) {
    return MaterialAccountWidgetRoute(
      context: context, page: const SettingsPage());
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface, // Changed from background to surface
      appBar: ZulipAppBar(
        centerTitle: true,
        title: Text(
          zulipLocalizations.settingsPageTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Personalize Your Experience',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Customize how Zulip works for you',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withAlpha(179), // Changed withOpacity to withAlpha
                ),
              ),
              const SizedBox(height: 24),
              
              _buildSettingsSection(
                context: context,
                icon: Icons.palette_outlined,
                title: 'Appearance',
                child: const _ThemeSetting(),
              ),
              
              const SizedBox(height: 16),
              
              _buildSettingsSection(
                context: context,
                icon: Icons.open_in_browser,
                title: 'Browser Preferences',
                child: const _BrowserPreferenceSetting(),
              ),
              
              if (GlobalSettingsStore.experimentalFeatureFlags.isNotEmpty) 
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: _buildSettingsSection(
                    context: context,
                    icon: Icons.science_outlined,
                    title: 'Experimental Features',
                    onTap: () => Navigator.push(context,
                      ExperimentalFeaturesPage.buildRoute()),
                    showArrow: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSettingsSection({
    required BuildContext context, 
    required IconData icon, 
    required String title, 
    Widget? child,
    VoidCallback? onTap,
    bool showArrow = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(26), // Changed withOpacity to withAlpha
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onTap != null)
              InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withAlpha(179), // Changed withOpacity to withAlpha
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (showArrow)
                        Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurface.withAlpha(128), // Changed withOpacity to withAlpha
                        ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withAlpha(179), // Changed withOpacity to withAlpha
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (child != null) child,
          ],
        ),
      ),
    );
  }
}

class _ThemeSetting extends StatelessWidget {
  const _ThemeSetting();

  void _handleChange(BuildContext context, ThemeSetting? newThemeSetting) {
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    globalSettings.setThemeSetting(newThemeSetting);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 8),
        for (final themeSettingOption in [null, ...ThemeSetting.values])
          Theme(
            data: Theme.of(context).copyWith(
              // Create custom radio button colors
              radioTheme: RadioThemeData(
                fillColor: WidgetStateProperty.resolveWith<Color>((states) { // Changed MaterialStateProperty to WidgetStateProperty
                  if (states.contains(WidgetState.selected)) { // Changed MaterialState to WidgetState
                    return colorScheme.primary;
                  }
                  return colorScheme.onSurface.withAlpha(128); // Changed withOpacity to withAlpha
                }),
              ),
            ),
            child: RadioListTile<ThemeSetting?>.adaptive(
              title: Text(ThemeSetting.displayName(
                themeSetting: themeSettingOption,
                zulipLocalizations: zulipLocalizations),
                style: TextStyle(
                  fontWeight: globalSettings.themeSetting == themeSettingOption 
                    ? FontWeight.w500 
                    : FontWeight.normal,
                ),
              ),
              secondary: _buildThemeIcon(context, themeSettingOption),
              value: themeSettingOption,
              groupValue: globalSettings.themeSetting,
              onChanged: (newValue) => _handleChange(context, newValue),
              activeColor: colorScheme.primary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
  
  Widget _buildThemeIcon(BuildContext context, ThemeSetting? themeSetting) {
    final colorScheme = Theme.of(context).colorScheme;
    
    IconData icon;
    Color containerColor;
    Color iconColor;
    
    switch (themeSetting) {
      case ThemeSetting.light:
        icon = Icons.light_mode;
        containerColor = Colors.amber.withAlpha(51); // Changed withOpacity to withAlpha
        iconColor = Colors.amber.shade700;
        break;
      case ThemeSetting.dark:
        icon = Icons.dark_mode;
        containerColor = Colors.indigo.withAlpha(51); // Changed withOpacity to withAlpha
        iconColor = Colors.indigo;
        break;
      default: // system or null
        icon = Icons.settings_suggest;
        containerColor = colorScheme.surfaceContainerHighest.withAlpha(128); // Changed surfaceVariant to surfaceContainerHighest and withOpacity to withAlpha
        iconColor = colorScheme.onSurfaceVariant;
        break;
    }
    
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 20,
      ),
    );
  }
}

class _BrowserPreferenceSetting extends StatelessWidget {
  const _BrowserPreferenceSetting();

  void _handleChange(BuildContext context, bool newOpenLinksWithInAppBrowser) {
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    globalSettings.setBrowserPreference(
      newOpenLinksWithInAppBrowser ? BrowserPreference.inApp
                                   : BrowserPreference.external);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalStoreWidget.settingsOf(context);
    final colorScheme = Theme.of(context).colorScheme;
    final openLinksWithInAppBrowser =
      globalSettings.effectiveBrowserPreference == BrowserPreference.inApp;
      
    return Column(
      children: [
        const Divider(height: 1),
        SwitchListTile.adaptive(
          title: Text(
            zulipLocalizations.openLinksWithInAppBrowser,
            style: TextStyle(
              fontWeight: FontWeight.w400,
            ),
          ),
          subtitle: Text(
            openLinksWithInAppBrowser 
              ? 'Open links within the app'
              : 'Open links in your default browser',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withAlpha(153), // Changed withOpacity to withAlpha
            ),
          ),
          secondary: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: openLinksWithInAppBrowser 
                ? colorScheme.primaryContainer.withAlpha(179) // Changed withOpacity to withAlpha
                : colorScheme.surfaceContainerHighest.withAlpha(128), // Changed surfaceVariant to surfaceContainerHighest and withOpacity to withAlpha
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              openLinksWithInAppBrowser ? Icons.open_in_new : Icons.launch,
              size: 20,
              color: openLinksWithInAppBrowser 
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            ),
          ),
          value: openLinksWithInAppBrowser,
          onChanged: (newValue) => _handleChange(context, newValue),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ],
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
    final colorScheme = Theme.of(context).colorScheme;
    
    assert(flags.isNotEmpty);
    
    return Scaffold(
      backgroundColor: colorScheme.surface, // Changed from background to surface
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        title: Text(
          zulipLocalizations.experimentalFeatureSettingsPageTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(38), // Changed withOpacity to withAlpha
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withAlpha(128), // Changed withOpacity to withAlpha
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        zulipLocalizations.experimentalFeatureSettingsWarning,
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Available Features',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withAlpha(26), // Changed withOpacity to withAlpha
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (int i = 0; i < flags.length; i++) ...[
                      _buildExperimentalFeatureItem(
                        context: context,
                        flag: flags[i],
                        globalSettings: globalSettings,
                        isLast: i == flags.length - 1,
                      ),
                      if (i < flags.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildExperimentalFeatureItem({
    required BuildContext context,
    required ExpFeatureFlag flag, // Changed from dynamic to ExpFeatureFlag (assuming this is the correct type)
    required GlobalSettingsStore globalSettings, // Changed from dynamic to GlobalSettingsStore
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = globalSettings.getBool(flag.name); // Changed from flag to flag.name as it needs a String
    
    return SwitchListTile.adaptive(
      title: Text(
        flag.name, // This assumes flag has a 'name' property
        style: TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Experimental feature', // Generic description since these are developer-facing
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withAlpha(153), // Changed withOpacity to withAlpha
        ),
      ),
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isEnabled == true // Explicitly check for boolean value
            ? colorScheme.primaryContainer.withAlpha(179) // Changed withOpacity to withAlpha
            : colorScheme.surfaceContainerHighest.withAlpha(128), // Changed surfaceVariant to surfaceContainerHighest and withOpacity to withAlpha
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.science_outlined,
          size: 20,
          color: isEnabled == true // Explicitly check for boolean value
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
        ),
      ),
      value: isEnabled ?? false, // Provide a default value in case isEnabled is null
      onChanged: (value) => globalSettings.setBool(flag.name, value), // Changed to flag.name
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

// Define this class if it doesn't exist in your codebase
class ExpFeatureFlag {
  final String name;
  
  const ExpFeatureFlag(this.name);
}
