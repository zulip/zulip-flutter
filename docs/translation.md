# Translations

Our goal is for this app to be localized and offered in many
languages, just like zulip-mobile and zulip web.

## Current state

Currently in place is integration with `flutter_localizations`
package, allowing all flutter UI elements to be localized

Per the discussion in #275 the approach here is to start with
ARB files and have dart autogenerate the bindings. I believe
this is the most straightforward way when connecting with a
translation management system, as they output ARB files that
we consume (this is also the same way web and mobile works
but with .po or .json files, I believe).

## Adding new strings

Add the appropriate entry in `assets/l10n/app_en.arb` ensuring
you add a corresponding resource attribute describing the
string in context. Example:

```
  "profileButtonSendDirectMessage": "Send direct message",
  "@profileButtonSendDirectMessage": {
    "description": "Label for button in profile screen to navigate to DMs with the shown user."
  },
```

The bindings are automatically generated when you execute
`flutter run` although you can also manually trigger it
using `flutter gen-l10n`.

Untranslated strings will be included in a generated
`build/untranslated_messages.json` file. This output
awaits #276.

## Using in code

To utilize in our widgets you need to import the generated
bindings:
```
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
```

And in your widget code pull the localizations out of the context:
```
Widget build(BuildContext context) {
  final zulipLocalizations = ZulipLocalizations.of(context);
```

And finally access one of the generated properties:
`Text(zulipLocalizations.chooseAccountButtonAddAnAccount)`.

String that take placeholders are generated as functions
that take arguments: `zulipLocalizations.subscribedToNStreams(store.subscriptions.length)`

## Hack to enforce locale (for testing, etc)

To manually trigger a locale change for testing I've found
it helpful to add the `localeResolutionCallback` in
`app.dart` to enforce a particular locale:

```
return GlobalStoreWidget(
  child: MaterialApp(
    title: 'Zulip',
    localizationsDelegates: ZulipLocalizations.localizationsDelegates,
    supportedLocales: ZulipLocalizations.supportedLocales,
    localeResolutionCallback: (locale, supportedLocales) {
      return const Locale("ja");
    },
    theme: theme,
    home: const ChooseAccountPage()));
```

(careful that returning a locale not in `supportedLocales`
will crash, the default behavior ensures a fallback is
always selected)

## Tests

Widgets that access localization will fail if the root
`MaterialApp` given in the setup isn't also set up with
localizations. Make sure to add the right
`localizationDelegates` and `supportedLocales`:

```
  await tester.pumpWidget(
    GlobalStoreWidget(
      child: MaterialApp(
        navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
        localizationsDelegates: ZulipLocalizations.localizationsDelegates,
        supportedLocales: ZulipLocalizations.supportedLocales,
        home: PerAccountStoreWidget(
```
