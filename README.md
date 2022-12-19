# Zulip Flutter

A Zulip client for Android and iOS, using Flutter.

## Developing

### Flutter help

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


### Editing API types

When editing the files in `lib/api/model/`, use the following command
to keep the generated files up to date:
```
$ flutter pub run build_runner watch --delete-conflicting-outputs
```
