# Zulip Flutter

A Zulip client for Android and iOS, using Flutter.

This is an early prototype for development.


## Getting started

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


## Notes

### Editing API types

We support Zulip Server 4.0 and later.  For API features added in
newer versions, use `TODO(server-N)` comments (like those you see
in the existing code.)

When editing the files in `lib/api/model/`, use the following command
to keep the generated files up to date:
```
$ flutter pub run build_runner watch --delete-conflicting-outputs
```


## TODO

### Server API

Much more to write.


### State and storage

Much more to design and write.


### Message content

If necessary we could put the message list in a webview, like we do
in React Native.  But the current plan is to handle it with Flutter
widgets.

- Lots of specific types of elements; see TODO comments

- Specific types of elements that may inform architecture:
  - Lists, with item indicators according to nesting level
  - Layout interactions like `p+ul`
  - Lightbox for image attachments
  - TeX

- Font

- Polls

- Separate processing HTML from building widgets (for testability,
  and ultimately for performance by memoizing the former)

- Survey lots of messages to find unhandled types of elements
- Survey all public messages on chat.zulip.org
- Survey all public messages on [listed open communities][]

[listed open communities]: https://zulip.com/communities/


### Message list, other than content

- Show more/better message metadata:
  - Sender avatars
  - Formatted times
  - Recipient headers
  - Starred
  - Edited/moved

- Handle layout/UI interactions between messages:
  - Sender names/avatars
  - Recipient headers
  - Date separators

- UI to interact with messages

- Scroll position at first unread, or via link (vs. latest)

- Dark theme (and in content too)


### Other UI

- Compose box

- Attach to message: take photo, pick image, pick file

- Navigation


### Notifications

Not started.
