# Translations

Our goal is for this app to be localized and offered in many
languages, just like zulip-mobile and Zulip web.


## Current state

We have a framework set up that makes it possible for UI strings
to be translated.  (This was issue #275.)  This means that when
adding new strings to the UI, instead of using a constant string
in English we'll add the string to that framework.
For details, see below.

At present not all of the codebase has been migrated to use the framework,
so you'll see some existing code that uses constant strings.
Fixing that is issue #277.

At present we don't have the strings wired up to a platform for
people to contribute translations.  That's issue #276.
Until then, we have only a handful of strings actually translated,
just to make it possible to demonstrate the framework
is working correctly.


## Adding new UI strings

### Adding a string to the translation database

To add a new string in the UI, start by
adding an entry in the ARB file `assets/l10n/app_en.arb`.
This includes a name that you choose for the string,
its value in English,
and a "resource attribute" describing the string in context.
The name will become an identifier in our Dart code.
The description will provide context for people contributing translations.

For example, this entry describes a UI string
named `profileButtonSendDirectMessage`
which appears in English as "Send direct message":
```
  "profileButtonSendDirectMessage": "Send direct message",
  "@profileButtonSendDirectMessage": {
    "description": "Label for button in profile screen to navigate to DMs with the shown user."
  },
```

Then run the app (with `flutter run` or in your IDE),
or perform a hot reload,
to cause the Dart bindings to be updated based on your
changes to the ARB file.
(You can also trigger an update directly, with `flutter gen-l10n`.)


### Using a translated string in the code

To use in your widget code, pull the localizations object
off of the Flutter build context:
```
Widget build(BuildContext context) {
  final zulipLocalizations = ZulipLocalizations.of(context);
```

Finally, on the localizations object use the getter
that was generated for the new string:
`Text(zulipLocalizations.profileButtonSendDirectMessage)`.


### Strings with placeholders

When a UI string is a constant per language, with no placeholders,
the generated Dart code provides a simple getter, as seen above.

When the string takes a placeholder,
the generated Dart binding for it will instead be a function,
taking arguments corresponding to the placeholders.

For example:
`zulipLocalizations.subscribedToNChannels(store.subscriptions.length)`.


## Hack to enforce locale (for testing, etc.)

For testing the app's behavior in different locales,
you can use your device's system settings to
change the preferred language.

Alternatively, you may find it helpful to
pass a `localeResolutionCallback` to the `MaterialApp` in `app.dart`
to enforce a particular locale:

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

(When using this hack, returning a locale not in `supportedLocales` will
cause a crash.
The default behavior without `localeResolutionCallback` ensures
a fallback is always selected.)


## Tests

Widgets that access localizations will fail if
the ambient `MaterialApp` isn't set up for localizations.
For the `MaterialApp` used in the app, we do this in `app.dart`.
In tests, this typically requires a test's setup code to provide
arguments `localizationDelegates` and `supportedLocales`.
For example:

```
  await tester.pumpWidget(
    GlobalStoreWidget(
      child: MaterialApp(
        navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
        localizationsDelegates: ZulipLocalizations.localizationsDelegates,
        supportedLocales: ZulipLocalizations.supportedLocales,
        home: PerAccountStoreWidget(
```


## Other notes

Our approach uses the `flutter_localizations` package.
We use the `gen_l10n` way, where we write ARB files
and the tool generates the Dart bindings.

As discussed in issue #275, the other way around was
also an option.  But this way seems most straightforward
when connecting with a translation management system,
as they output ARB files that we consume.
This also parallels how zulip-mobile works with `.json` files
(and Zulip web, and the Zulip server with `.po` files?)

A file `build/untranslated_messages.json` is emitted
whenever the Dart bindings are generated from the ARB files.
This output awaits #276.
