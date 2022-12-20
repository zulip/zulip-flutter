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


### Server credentials

In this early prototype, we don't yet have a UI for logging into
a Zulip server.  Instead, you supply Zulip credentials at build time.

To do this, log into the Zulip web app for the test account you want
to use, and [download a `.zuliprc` file][download-zuliprc].  Then
create a file `lib/credential_fixture.dart` in this worktree with the
following form:
```dart
// ignore_for_file: constant_identifier_names
const String realm_url = '…';
const String email = '…';
const String api_key = '…';
```

Now build and run the app (see "Flutter help" above), and things
should work.

Note this means the account's API key gets incorporated into the
build output.  Consider using a low-value test account, or else
deleting the build output (`flutter clean`, and then delete the app
from any mobile devices you ran it on) when done.

[download-zuliprc]: https://zulip.com/api/api-keys


### Editing API types

We support Zulip Server 4.0 and later.  For API features added in
newer versions, use `TODO(server-N)` comments (like those you see
in the existing code.)

When editing the files in `lib/api/model/`, use the following command
to keep the generated files up to date:
```
$ flutter pub run build_runner watch --delete-conflicting-outputs
```
