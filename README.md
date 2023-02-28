# Zulip Flutter (prototype)

A Zulip client for Android and iOS, using Flutter.

This is an early prototype for development.


## Using Zulip

To use Zulip on iOS or Android, install the [official mobile Zulip client][].

[official mobile Zulip client]: https://github.com/zulip/zulip-mobile#readme


## Getting started in developing this prototype

### Flutter help

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


### Dependencies

While in the prototype phase, we use the latest Flutter from Flutter's
main branch.  Use `flutter channel main` and `flutter upgrade`.

We don't pin a specific version, because Flutter itself doesn't offer
a way to do so.  So far that hasn't been a problem.  When it becomes one,
we'll figure it out; there are several tools for this in the Flutter
community.  See [issue #15][].

[issue #15]: https://github.com/zulip/zulip-flutter/issues/15


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


### Upgrading Flutter

We regularly increment our lower bounds on Flutter and Dart versions,
to make sure there's not too much divergence in the versions people
are using.

When there's a new beta (which happens a couple of times per month),
that's a good prompt to do this.  We also do this when there's a
new PR merged that we particularly want to take.

To update the version bounds:
* Use `flutter upgrade` to upgrade your local Flutter and Dart.
* Update the lower bounds at `environment` in `pubspec.yaml`
  to the new versions, as seen in `flutter --version`.
* Run `flutter pub get`, which will update `pubspec.lock`.
* Make a quick check that things work: `flutter analyze`,
  and do a quick smoke-test of the app.
* Commit and push the changes in `pubspec.yaml` and `pubspec.lock`.


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
  - List item indicators according to nesting level
  - Layout interactions like `p+ul`
  - Lightbox for image attachments
  - TeX

- Font

- Polls

- Survey lots of messages to find unhandled types of elements
- Survey all public messages on chat.zulip.org
- Survey all public messages on [listed open communities][]

[listed open communities]: https://zulip.com/communities/


### Message list, other than content

- Show more/better message metadata:
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


## License

Copyright (c) 2022 Kandra Labs, Inc., and contributors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

The software includes some works released by third parties under other
free and open source licenses. Those works are redistributed under the
license terms under which the works were received.
