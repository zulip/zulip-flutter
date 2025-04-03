import 'package:flutter/material.dart';
import 'app.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/settings.dart';
import 'app_bar.dart';
import 'page.dart';
import 'store.dart';

class LanguageOption {
  final String name;
  final String englishName;
  final Locale locale;

  const LanguageOption(this.name, this.englishName, this.locale);
}

final List<LanguageOption> _languageOptions = const [
  LanguageOption('English', 'English', Locale('en')),
  LanguageOption('English (UK)', 'English (UK)', Locale('en', 'GB')),
  LanguageOption('English (US)', 'English (US)', Locale('en', 'US')),
  LanguageOption('Afrikaans', 'Afrikaans', Locale('af')),
  LanguageOption('العربية', 'Arabic', Locale('ar')),
  LanguageOption('Հայերեն', 'Armenian', Locale('hy')),
  LanguageOption('Azərbaycanca', 'Azerbaijani', Locale('az')),
  LanguageOption('Беларуская', 'Belarusian', Locale('be')),
  LanguageOption('বাংলা', 'Bengali', Locale('bn')),
  LanguageOption('Bosanski', 'Bosnian', Locale('bs')),
  LanguageOption('Български', 'Bulgarian', Locale('bg')),
  LanguageOption('Català', 'Catalan', Locale('ca')),
  LanguageOption('中文 (简体)', 'Chinese (Simplified)', Locale('zh', 'CN')),
  LanguageOption('中文 (繁體)', 'Chinese (Traditional)', Locale('zh', 'TW')),
  LanguageOption('Hrvatski', 'Croatian', Locale('hr')),
  LanguageOption('Čeština', 'Czech', Locale('cs')),
  LanguageOption('Dansk', 'Danish', Locale('da')),
  LanguageOption('Nederlands', 'Dutch', Locale('nl')),
  LanguageOption('Eesti', 'Estonian', Locale('et')),
  LanguageOption('Filipino', 'Filipino', Locale('fil')),
  LanguageOption('Suomi', 'Finnish', Locale('fi')),
  LanguageOption('Français', 'French', Locale('fr')),
  LanguageOption('Français (Canada)', 'French (Canada)', Locale('fr', 'CA')),
  LanguageOption('Galego', 'Galician', Locale('gl')),
  LanguageOption('ქართული', 'Georgian', Locale('ka')),
  LanguageOption('Deutsch', 'German', Locale('de')),
  LanguageOption('Ελληνικά', 'Greek', Locale('el')),
  LanguageOption('ગુજરાતી', 'Gujarati', Locale('gu')),
  LanguageOption('עברית', 'Hebrew', Locale('he')),
  LanguageOption('हिन्दी', 'Hindi', Locale('hi')),
  LanguageOption('Magyar', 'Hungarian', Locale('hu')),
  LanguageOption('Íslenska', 'Icelandic', Locale('is')),
  LanguageOption('Bahasa Indonesia', 'Indonesian', Locale('id')),
  LanguageOption('Gaeilge', 'Irish', Locale('ga')),
  LanguageOption('Italiano', 'Italian', Locale('it')),
  LanguageOption('日本語', 'Japanese', Locale('ja')),
  LanguageOption('ಕನ್ನಡ', 'Kannada', Locale('kn')),
  LanguageOption('Қазақ', 'Kazakh', Locale('kk')),
  LanguageOption('ភាសាខ្មែរ', 'Khmer', Locale('km')),
  LanguageOption('한국어', 'Korean', Locale('ko')),
  LanguageOption('ລາວ', 'Lao', Locale('lo')),
  LanguageOption('Latviešu', 'Latvian', Locale('lv')),
  LanguageOption('Lietuvių', 'Lithuanian', Locale('lt')),
  LanguageOption('Македонски', 'Macedonian', Locale('mk')),
  LanguageOption('Malayalam', 'Malayalam', Locale('ml')),
  LanguageOption('Bahasa Melayu', 'Malay', Locale('ms')),
  LanguageOption('Монгол', 'Mongolian', Locale('mn')),
  LanguageOption('नेपाली', 'Nepali', Locale('ne')),
  LanguageOption('Norsk Bokmål', 'Norwegian (Bokmål)', Locale('nb')),
  LanguageOption('فارسی', 'Persian', Locale('fa')),
  LanguageOption('Polski', 'Polish', Locale('pl')),
  LanguageOption('Português (Brasil)', 'Portuguese (Brazil)', Locale('pt', 'BR')),
  LanguageOption('Português (Portugal)', 'Portuguese (Portugal)', Locale('pt', 'PT')),
  LanguageOption('ਪੰਜਾਬੀ', 'Punjabi', Locale('pa')),
  LanguageOption('Română', 'Romanian', Locale('ro')),
  LanguageOption('Русский', 'Russian', Locale('ru')),
  LanguageOption('Српски', 'Serbian', Locale('sr')),
  LanguageOption('Slovenčina', 'Slovak', Locale('sk')),
  LanguageOption('Slovenščina', 'Slovenian', Locale('sl')),
  LanguageOption('Español', 'Spanish', Locale('es')),
  LanguageOption('Español (Latinoamérica)', 'Spanish (Latin America)', Locale('es', '419')),
  LanguageOption('Svenska', 'Swedish', Locale('sv')),
  LanguageOption('தமிழ்', 'Tamil', Locale('ta')),
  LanguageOption('తెలుగు', 'Telugu', Locale('te')),
  LanguageOption('ไทย', 'Thai', Locale('th')),
  LanguageOption('Türkçe', 'Turkish', Locale('tr')),
  LanguageOption('Українська', 'Ukrainian', Locale('uk')),
  LanguageOption('اردو', 'Urdu', Locale('ur')),
  LanguageOption('Oʻzbek', 'Uzbek', Locale('uz')),
  LanguageOption('Tiếng Việt', 'Vietnamese', Locale('vi')),
  LanguageOption('Cymraeg', 'Welsh', Locale('cy')),
  LanguageOption('isiZulu', 'Zulu', Locale('zu')),
];

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static AccountRoute<void> buildRoute({required BuildContext context}) {
    return MaterialAccountWidgetRoute(
      context: context, page: const SettingsPage());
  }

  String _getCurrentLanguageName() {
    final currentLocale = ZulipApp.currentLocale;
    if (currentLocale == null) return 'System default';

    final option = _languageOptions.firstWhere(
          (opt) => opt.locale.languageCode == currentLocale.languageCode,
      orElse: () => const LanguageOption('English', 'English', Locale('en')),
    );

    return option.englishName;
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Scaffold(
      appBar: ZulipAppBar(
        title: Text(zulipLocalizations.settingsPageTitle)),
      body: Column(children: [
        const _ThemeSetting(),
        const _BrowserPreferenceSetting(),
        ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: Text(
              _getCurrentLanguageName(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            onTap: () => Navigator.push<void>(  // Explicitly specify return type
              context,
              MaterialPageRoute<void>(  // Explicit type parameter
                builder: (context) => const LanguageSelectionScreen(),
              ),
            ),
          ),
        if (GlobalSettingsStore.experimentalFeatureFlags.isNotEmpty)
          ListTile(
            title: Text(zulipLocalizations.experimentalFeatureSettingsPageTitle),
            onTap: () => Navigator.push(context,
              ExperimentalFeaturesPage.buildRoute()))
      ]));
  }
}

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<LanguageOption> _filteredLanguages = [];

  @override
  void initState() {
    super.initState();
    _filteredLanguages = _languageOptions;
    _searchController.addListener(_filterLanguages);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLanguages() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLanguages = _languageOptions.where((lang) {
        return lang.name.toLowerCase().contains(query) ||
            lang.englishName.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredLanguages.length,
              itemBuilder: (context, index) {
                final option = _filteredLanguages[index];
                final isSelected = ZulipApp.currentLocale?.languageCode ==
                    option.locale.languageCode;

                return ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.name),
                      Text(
                        option.englishName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    ZulipApp.setLocale(option.locale);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
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
    return Column(
      children: [
        ListTile(title: Text(zulipLocalizations.themeSettingTitle)),
        for (final themeSettingOption in [null, ...ThemeSetting.values])
          RadioListTile<ThemeSetting?>.adaptive(
            title: Text(ThemeSetting.displayName(
              themeSetting: themeSettingOption,
              zulipLocalizations: zulipLocalizations)),
            value: themeSettingOption,
            groupValue: globalSettings.themeSetting,
            onChanged: (newValue) => _handleChange(context, newValue)),
      ]);
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
    final openLinksWithInAppBrowser =
      globalSettings.effectiveBrowserPreference == BrowserPreference.inApp;
    return SwitchListTile.adaptive(
      title: Text(zulipLocalizations.openLinksWithInAppBrowser),
      value: openLinksWithInAppBrowser,
      onChanged: (newValue) => _handleChange(context, newValue));
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
        title: Text(zulipLocalizations.experimentalFeatureSettingsPageTitle)),
      body: Column(children: [
        ListTile(
          title: Text(zulipLocalizations.experimentalFeatureSettingsWarning)),
        for (final flag in flags)
          SwitchListTile.adaptive(
            title: Text(flag.name), // no i18n; these are developer-facing settings
            value: globalSettings.getBool(flag),
            onChanged: (value) => globalSettings.setBool(flag, value)),
      ]));
  }
}
